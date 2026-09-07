#!/usr/bin/env bash
# Handoff — check a consumer repo is actually wired up.
#
# Run from inside the repo, or pass one:  scripts/doctor.sh OWNER/REPO
#
# Optional:
#   --machine-account LOGIN   also check that account has write access
#   --token                   also check the token in $BOT_TOKEN and report its expiry
#
# Exits non-zero if any required check fails. Every failure prints the exact
# command or click that fixes it — most of these cost an hour the first time
# you hit them, and all of them are invisible until something breaks.
#
# A ! warning means "we could not look", not "it is wrong". Reading secrets and
# the Actions policy needs admin; without it those two checks are undetermined,
# and saying "missing" would be a guess.
set -uo pipefail

# Where Handoff itself lives. The remedies below name files inside it, and you are
# standing in the consumer repo when you read them — a bare `templates/claude.yml`
# does not exist there. Derived from this script's own path, the way setup.sh does.
# Set HANDOFF_DIR yourself if you reached this script through a symlink.
HANDOFF_DIR="${HANDOFF_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

REPO=""; MACHINE=""; CHECK_TOKEN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --machine-account) MACHINE="${2:-}"; shift 2 ;;
    --token)           CHECK_TOKEN=1; shift ;;
    -h|--help)         sed -n '2,12p' "$0"; exit 0 ;;
    *)                 REPO="$1"; shift ;;
  esac
done

FAILED=0; WARNED=0
pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      → %s\n' "$2"; FAILED=$((FAILED+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      → %s\n' "$2"; WARNED=$((WARNED+1)); }
head_() { printf '\n%s\n' "$1"; }

command -v gh >/dev/null || { echo "gh CLI not found — https://cli.github.com"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh is not logged in — run: gh auth login"; exit 1; }

if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" \
    || { echo "Not in a git repo and no OWNER/REPO given."; exit 1; }
fi
# Read the default branch over REST, not GraphQL. `defaultBranchRef` resolves an actual ref,
# so it is empty on a repo that exists but has no commits yet — and reporting that as "no access"
# sends the reader off to debug the repo name and their auth, neither of which is wrong.
# REST's `default_branch` is populated from creation. Verified 2026-09-06 on a fresh org repo:
# REST said "main" while defaultBranchRef said "".
# Key off gh's exit status, not the output: on a 404 `gh api` still prints the error JSON to
# stdout, so testing for emptiness alone reports a missing repo as an empty one.
if ! BASE="$(gh api "repos/$REPO" --jq .default_branch 2>/dev/null)" || [ -z "$BASE" ]; then
  echo "Cannot read $REPO — wrong name, or no access."; exit 1
fi
if [ -z "$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)" ]; then
  echo "$REPO exists but has no commits yet."
  echo "  Push one to $BASE first — every check below reads files from that branch."
  echo "  Fix: gh repo create is not enough; use --add-readme, or push an initial commit."
  exit 1
fi

printf '\033[1mHandoff doctor\033[0m — %s (default branch: %s)\n' "$REPO" "$BASE"

head_ "Repository"
OWNER_TYPE="$(gh api "repos/$REPO" --jq .owner.type 2>/dev/null)"
if [ "$OWNER_TYPE" = "Organization" ]; then
  pass "owned by an organisation — also supports the D5 machine-account upgrade"
  # Detecting an org used to print only the reassuring line above, which is the one branch that
  # KNOWS a second gate exists and said nothing about it. GitHub keeps the same
  # "Actions may create pull requests" setting at organisation level; the endpoint below is
  # documented at
  # https://docs.github.com/rest/actions/permissions#get-default-workflow-permissions-for-an-organization
  # (named by GitHub's own 403 body, read 2026-09-07) and refuses anyone who is not an org admin.
  # This warns rather than fails: whether the org value overrides the repo value is UNVERIFIED
  # here, so the repo-level check below stays the one that decides the exit code.
  ORG="${REPO%%/*}"
  if ORG_PR="$(gh api "orgs/$ORG/actions/permissions/workflow" --jq .can_approve_pull_request_reviews 2>/dev/null)"; then
    if [ "$ORG_PR" = "true" ]; then
      pass "$ORG allows Actions to create pull requests"
    else
      warn "$ORG does NOT allow Actions to create pull requests (org-level setting)" \
           "An organisation OWNER must tick it at https://github.com/organizations/$ORG/settings/actions. Repository admin is not enough. On 2026-09-06 the repo-level PUT was refused with 409 Conflict on an org repo in this state; we have not re-reproduced that."
    fi
  else
    warn "could not read $ORG's Actions pull-request policy" \
         "Not a failure — we could not look. Reading it needs an organisation owner, or: gh auth refresh -h github.com -s admin:org"
  fi
else
  pass "owned by a personal account — you can create a fine-grained token for a repo you own (D5a)"
fi
if [ "$(gh api "repos/$REPO" --jq .private 2>/dev/null)" = "true" ]; then
  pass "private"
else
  warn "public" "Every comment on a thread reaches Claude. On a public repo that is anyone. See $HANDOFF_DIR/docs/05-security.md."
fi

head_ "Claude side"
# Key off gh's exit status, same lesson as the BASE read above. Piping straight into grep threw
# it away, so a 403 read as "the secret is missing" and sent the caller off to run `gh secret set`
# — which 403s too. Verified 2026-09-07: `gh secret list` exits 0 with NO output on a repo that
# simply has no secrets, and exits 1 when it cannot read them, so the two states are separable.
if SECRETS="$(gh secret list --repo "$REPO" 2>/dev/null)"; then
  if printf '%s\n' "$SECRETS" | grep -q '^CLAUDE_CODE_OAUTH_TOKEN'; then
    pass "CLAUDE_CODE_OAUTH_TOKEN secret is set"
  else
    fail "CLAUDE_CODE_OAUTH_TOKEN secret is missing" \
         "claude setup-token   then   gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo $REPO"
  fi
else
  warn "could not read the secrets on $REPO — this is NOT 'the secret is missing'" \
       "Reading secrets needs admin on $REPO. Re-run as someone who has it, or ask them to check. Setting the secret needs admin too, so do not follow the missing-secret advice yet."
fi

if gh api "repos/$REPO/contents/.github/workflows/claude.yml?ref=$BASE" >/dev/null 2>&1; then
  pass "claude.yml is on $BASE"
  # Existing is not the same as intact. A truncated or hand-edited copy passes a
  # file-exists check and then fails at run time, or silently drops a cost brake.
  # Read the installed copy and check the three brakes are still in it (D10).
  WF="$(gh api "repos/$REPO/contents/.github/workflows/claude.yml?ref=$BASE" --jq .content 2>/dev/null | base64 -d 2>/dev/null || true)"
  if [ -z "$WF" ]; then
    warn "could not read claude.yml to check it" "Network or permissions. The file is there; its contents were not verified."
  else
    # Ignore comment lines. A commented-out brake is a missing brake, and the
    # template mentions all three in its own comments — matching those would make
    # this check unable to fail. Found by commenting one out and watching it pass.
    UNCOMMENTED="$(printf '%s\n' "$WF" | grep -vE '^[[:space:]]*#')"
    MISSING=""
    printf '%s\n' "$UNCOMMENTED" | grep -qE '^[[:space:]]*concurrency:'     || MISSING="$MISSING concurrency-group"
    printf '%s\n' "$UNCOMMENTED" | grep -qE '^[[:space:]]*timeout-minutes:' || MISSING="$MISSING timeout-minutes"
    printf '%s\n' "$UNCOMMENTED" | grep -q -- '--max-turns'                 || MISSING="$MISSING --max-turns"
    printf '%s\n' "$UNCOMMENTED" | grep -q 'Open the pull request'          || MISSING="$MISSING pr-step"
    if [ -z "$MISSING" ]; then
      pass "claude.yml still has its three cost brakes and the PR step"
    else
      fail "the installed claude.yml is missing:$MISSING" \
           "This copy has been edited or truncated. Re-copy $HANDOFF_DIR/templates/claude.yml. Without the brakes a runaway run is unbounded; without the PR step no pull request is ever opened."
    fi
  fi
elif gh api "repos/$REPO/contents/.github/workflows/claude.yml" >/dev/null 2>&1; then
  fail "claude.yml exists but is NOT on $BASE" \
       "Actions only triggers issue events from the default branch. Merge it to $BASE."
else
  fail "claude.yml is missing" "cp \"$HANDOFF_DIR/templates/claude.yml\" .github/workflows/ then commit and push to $BASE"
fi

# The workflow can be perfect and the run still useless: Claude reads CLAUDE.md first on every
# run, so an unfilled template means it is briefed on a placeholder repository rather than this
# one. AGENTS.md already names this as the cause of "the agent edited files it was told not to",
# but nothing checked it until now. Match the literal placeholder tokens shipped in
# templates/CLAUDE.md.template — not "any <angle brackets>", which would hit ordinary prose.
if CM="$(gh api "repos/$REPO/contents/CLAUDE.md?ref=$BASE" --jq .content 2>/dev/null | base64 -d 2>/dev/null)" && [ -n "$CM" ]; then
  LEFT="$(printf '%s\n' "$CM" | grep -oE '<(REPO NAME|test command|\.\.\.|lint, formatting, naming|paths that must not change[^>]*)>' | sort -u | tr '\n' ' ')"
  if [ -z "$LEFT" ]; then
    pass "CLAUDE.md has no unfilled placeholders"
  else
    fail "CLAUDE.md still contains template placeholders: $LEFT" \
         "Claude reads this file first on every run, so it is currently briefed on the template rather than your repository. Fill them in — AGENTS.md step 4."
  fi
else
  warn "no CLAUDE.md on $BASE" "Claude will run without repository-specific instructions. Copy $HANDOFF_DIR/templates/CLAUDE.md.template and fill it in."
fi

head_ "Pull requests"
# Same fix as the secret check. This used to compare the raw response against "true", so a 403
# error body — which is not "true" — reported as "not enabled" and sent the caller to a Settings
# page they cannot open. Verified 2026-09-07 against a repo readable but not administered:
# `gh api …/actions/permissions/workflow --jq …` exits 1 and prints the error JSON to stdout.
if REPO_PR="$(gh api "repos/$REPO/actions/permissions/workflow" --jq .can_approve_pull_request_reviews 2>/dev/null)"; then
  if [ "$REPO_PR" = "true" ]; then
    pass "Actions may create pull requests"
  else
    fail "Actions may NOT create pull requests — off by default on every repo, and capped again by the organisation policy on org-owned repos" \
         "Settings → Actions → General → Workflow permissions → tick 'Allow GitHub Actions to create and approve pull requests'. Without it the PR step in claude.yml fails and no pull request is ever opened. On an org-owned repo see the org-level warning above — an organisation owner has to enable it there too."
  fi
else
  warn "could not read the pull-request setting on $REPO — this is NOT 'not enabled'" \
       "Reading it needs admin on $REPO. Re-run as someone who has it. Changing it needs admin too, so do not follow the not-enabled advice yet."
fi

head_ "Machine account"
if [ -n "$MACHINE" ]; then
  PERM="$(gh api "repos/$REPO/collaborators/$MACHINE/permission" --jq .permission 2>/dev/null)"
  case "$PERM" in
    admin|write) pass "$MACHINE has $PERM access" ;;
    "")          fail "$MACHINE is not a collaborator on $REPO" "Invite it as an organisation member, then grant Write on this repo." ;;
    *)           fail "$MACHINE has '$PERM', not write" "The action refuses to run for accounts without write access — the run goes red, it is not silently skipped." ;;
  esac
  TYPE="$(gh api "users/$MACHINE" --jq .type 2>/dev/null)"
  if [ "$TYPE" = "User" ]; then
    pass "$MACHINE is a User account, so the action will accept it"
  elif [ -n "$TYPE" ]; then
    fail "$MACHINE is type '$TYPE', not User" "The action rejects bot actors. Use an ordinary GitHub account."
  fi
else
  warn "skipped — pass --machine-account LOGIN to check it"
fi

head_ "Bot token"
if [ "$CHECK_TOKEN" = "1" ]; then
  if [ -z "${BOT_TOKEN:-}" ]; then
    fail "--token given but \$BOT_TOKEN is empty" "export BOT_TOKEN=github_pat_... then re-run"
  else
    EXP="$(curl -sI -H "Authorization: Bearer $BOT_TOKEN" https://api.github.com/user \
            | tr -d '\r' | awk -F': ' 'tolower($1)=="github-authentication-token-expiration"{print $2}')"
    CODE="$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $BOT_TOKEN" \
            "https://api.github.com/repos/$REPO/issues")"
    if [ "$CODE" = "200" ]; then
      pass "token can read issues on $REPO"
      warn "reach checked, scope NOT checked" \
           "This proves the token reaches $REPO. It does not prove it is limited to it — a token scoped to every repo passes this identically. Run the two-call check in $HANDOFF_DIR/docs/03-setup-guide.md against a control repo you own, and read the trap note there before choosing one."
    else fail "token cannot reach $REPO issues (HTTP $CODE)" "Check the resource owner is the ORG, and that an org owner approved the token."; fi
    if [ -n "$EXP" ]; then
      pass "token expires: $EXP"
      EXP_S="$(date -j -f '%Y-%m-%d %H:%M:%S %Z' "$EXP" '+%s' 2>/dev/null || date -d "$EXP" '+%s' 2>/dev/null || echo '')"
      if [ -n "$EXP_S" ]; then
        DAYS=$(( (EXP_S - $(date '+%s')) / 86400 ))
        [ "$DAYS" -lt 14 ] && warn "expires in $DAYS days" "Rotate it now — an expired token fails in a confusing way."
      fi
    else
      warn "no expiry reported" "Classic tokens do not report one. A classic token with 'repo' scope is far broader than this needs — see issue #46."
    fi
  fi
else
  warn "skipped — pass --token with \$BOT_TOKEN set to check reach and expiry"
fi

head_ "Cannot be checked from here — but check it FIRST"
warn "Claude GitHub App installed on $REPO" \
     "Listed last, but it is the first thing the run does. Until the app is installed a missing token cannot be diagnosed: the run dies at app-token exchange before the token is ever used (observed 2026-09-06). No API can confirm this without the app's own credentials. Check by eye: https://github.com/$REPO/settings/installations"

printf '\n'
if [ "$FAILED" -gt 0 ]; then
  printf '\033[31m%s check(s) failed\033[0m, %s warning(s). The bridge will not work until the failures are fixed.\n' "$FAILED" "$WARNED"
  exit 1
fi
printf '\033[32mAll required checks passed\033[0m'
[ "$WARNED" -gt 0 ] && printf ' (%s warning(s) — read them)' "$WARNED"
printf '\n'
exit 0

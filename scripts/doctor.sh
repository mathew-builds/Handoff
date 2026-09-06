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
set -uo pipefail

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
else
  pass "owned by a personal account — you can create a fine-grained token for a repo you own (D5a)"
fi
if [ "$(gh api "repos/$REPO" --jq .private 2>/dev/null)" = "true" ]; then
  pass "private"
else
  warn "public" "Every comment on a thread reaches Claude. On a public repo that is anyone. See docs/05-security.md."
fi

head_ "Claude side"
if gh secret list --repo "$REPO" 2>/dev/null | grep -q '^CLAUDE_CODE_OAUTH_TOKEN'; then
  pass "CLAUDE_CODE_OAUTH_TOKEN secret is set"
else
  fail "CLAUDE_CODE_OAUTH_TOKEN secret is missing" \
       "claude setup-token   then   gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo $REPO"
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
           "This copy has been edited or truncated. Re-copy templates/claude.yml. Without the brakes a runaway run is unbounded; without the PR step no pull request is ever opened."
    fi
  fi
elif gh api "repos/$REPO/contents/.github/workflows/claude.yml" >/dev/null 2>&1; then
  fail "claude.yml exists but is NOT on $BASE" \
       "Actions only triggers issue events from the default branch. Merge it to $BASE."
else
  fail "claude.yml is missing" "cp templates/claude.yml .github/workflows/ then commit and push to $BASE"
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
  warn "no CLAUDE.md on $BASE" "Claude will run without repository-specific instructions. Copy templates/CLAUDE.md.template and fill it in."
fi

head_ "Pull requests"
if [ "$(gh api "repos/$REPO/actions/permissions/workflow" --jq .can_approve_pull_request_reviews 2>/dev/null)" = "true" ]; then
  pass "Actions may create pull requests"
else
  fail "Actions may NOT create pull requests — off by default on every repo" \
       "Settings → Actions → General → Workflow permissions → tick 'Allow GitHub Actions to create and approve pull requests'. Without it the PR step in claude.yml fails and no pull request is ever opened."
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
           "This proves the token reaches $REPO. It does not prove it is limited to it — a token scoped to every repo passes this identically. Run the two-call check in docs/03-setup-guide.md against a control repo you own, and read the trap note there before choosing one."
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

head_ "Cannot be checked from here"
warn "Claude GitHub App installed on $REPO" \
     "No API can confirm this without the app's own credentials. Check by eye: https://github.com/$REPO/settings/installations"

printf '\n'
if [ "$FAILED" -gt 0 ]; then
  printf '\033[31m%s check(s) failed\033[0m, %s warning(s). The bridge will not work until the failures are fixed.\n' "$FAILED" "$WARNED"
  exit 1
fi
printf '\033[32mAll required checks passed\033[0m'
[ "$WARNED" -gt 0 ] && printf ' (%s warning(s) — read them)' "$WARNED"
printf '\n'
exit 0

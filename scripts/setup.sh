#!/usr/bin/env bash
# Handoff — Step 1 of the setup guide, automated.
#
# Run from inside the consumer repo. Requires `gh` (logged in, admin on the repo)
# and `claude` (logged in with your Pro/Max/Team/Enterprise subscription).
#
# What it deliberately does NOT do:
#   - Capture `claude setup-token`. That is an interactive browser flow; wrapping
#     it in $(...) swallows the authorisation prompt and leaks the token into
#     your shell history. You run it, you paste it. (issue #21)
#   - Overwrite an existing CLAUDE.md. That destroyed 73KB of a real repo's
#     instructions in testing. (issue #25)
set -euo pipefail

HANDOFF_DIR="${HANDOFF_DIR:-${BRIDGE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}}"
BLOCKED=0
fail()  { printf '\n  ✗ %s\n' "$*" >&2; exit 1; }
ok()    { printf '  ✓ %s\n' "$*"; }
warn()  { printf '  ! %s\n' "$*"; }
# A blocker is something that leaves the bridge NON-FUNCTIONAL. It prints like a
# warning but it decides the exit code, so `setup.sh && echo done` cannot lie.
block() { printf '  ✗ %s\n' "$*"; BLOCKED=$((BLOCKED + 1)); }

echo "→ Prerequisites"
command -v gh    >/dev/null || fail "gh CLI not found — https://cli.github.com"
command -v git   >/dev/null || fail "git not found"
gh auth status   >/dev/null 2>&1 || fail "gh is not logged in — run: gh auth login"
git rev-parse --git-dir >/dev/null 2>&1 || fail "not inside a git repository"
ok "gh, git, and a git repo"

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
# REST, not GraphQL — see the comment in doctor.sh. `defaultBranchRef` is empty on a repo with
# no commits, which printed "default branch: " with a hole in it and carried on regardless.
BASE="$(gh api "repos/$REPO" --jq .default_branch)"
OWNER_TYPE="$(gh api "repos/$REPO" --jq .owner.type)"
if [ -z "$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)" ]; then
  BASE_NOTE="$BASE, no commits yet"
else
  BASE_NOTE="$BASE"
fi
echo "→ Target: $REPO (default branch: $BASE_NOTE, owner type: $OWNER_TYPE)"

if [ "$OWNER_TYPE" = "Organization" ]; then
  ok "owned by an organisation — also supports the D5 machine-account upgrade"
else
  ok "owned by a personal account — you can create a fine-grained token for a repo you own (D5a)"
fi

# The token is a blocker, NOT an early exit. It used to `exit 1` here, before any
# file operation — which meant an agent setting this up while the human was away
# could do no local work at all, because only a human can produce the token. Now
# everything that does not need the token happens first, and this is reported at
# the end with the other blockers.
echo "→ Subscription token"
if gh secret list --repo "$REPO" 2>/dev/null | grep -q '^CLAUDE_CODE_OAUTH_TOKEN'; then
  ok "CLAUDE_CODE_OAUTH_TOKEN already set"
else
  block "CLAUDE_CODE_OAUTH_TOKEN is not set — Claude cannot authenticate, so no run will start."
  warn "  Only you can do this. Two commands, in this order:"
  warn "      claude setup-token"
  warn "      gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo $REPO"
  warn "  The first opens a browser; approve, then copy the token it prints."
  warn "  The second prompts you to paste it — nothing appears as you paste,"
  warn "  which is deliberate."
  warn "  If an agent is running this for you: it must NOT run these. The first"
  warn "  prints a secret, and running it would put that secret in the agent's"
  warn "  transcript."
fi

echo "→ Workflows"
mkdir -p .github/workflows
if [ -e ".github/workflows/claude.yml" ]; then
  ok "claude.yml already present, left alone"
else
  cp "$HANDOFF_DIR/templates/claude.yml" ".github/workflows/claude.yml"
  ok "claude.yml installed"
fi

echo "→ Repo instructions"
if [ -e CLAUDE.md ]; then
  warn "CLAUDE.md exists — NOT overwriting it."
  warn "Merge in what you need from $HANDOFF_DIR/templates/CLAUDE.md.template by hand."
else
  cp "$HANDOFF_DIR/templates/CLAUDE.md.template" CLAUDE.md
  ok "CLAUDE.md created"
fi
# Unfilled placeholders are a blocker, not advice, because scripts/doctor.sh fails on them and
# these two scripts must not disagree about the same repo — that was issue #36. This script
# CREATES the state doctor.sh rejects, so exiting 0 here is the specific case that matters:
# AGENTS.md tells the installing agent to read the exit code, not the output. Same literal
# tokens as the doctor.sh check, deliberately, so the two cannot drift apart.
LEFT="$(grep -oE '<(REPO NAME|test command|\.\.\.|lint, formatting, naming|paths that must not change[^>]*)>' CLAUDE.md 2>/dev/null | sort -u | tr '\n' ' ')"
if [ -n "$LEFT" ]; then
  block "CLAUDE.md still has template placeholders:$LEFT"
  warn "  Claude reads this file first on every run, so until you fill these in it is"
  warn "  briefed on the template rather than your repository."
else
  ok "CLAUDE.md has no unfilled placeholders"
fi

echo "→ Actions must be allowed to open pull requests"
# Off by default on every repo. Without it the PR step in claude.yml fails with
# "GitHub Actions is not permitted to create or approve pull requests". (D12)
if gh api "repos/$REPO/actions/permissions/workflow" --jq .can_approve_pull_request_reviews 2>/dev/null | grep -q true; then
  ok "already enabled"
else
  block "NOT enabled — the PR step will fail and no pull request will ever appear."
  warn "  Either run this (verified working 2026-09-06):"
  warn "    gh api -X PUT repos/$REPO/actions/permissions/workflow \\"
  warn "      -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true"
  warn "  or tick Settings → Actions → General → Workflow permissions →"
  warn "  'Allow GitHub Actions to create and approve pull requests'."
  warn "  Not done for you: that call also sets default_workflow_permissions,"
  warn "  which would silently narrow a repo where you had chosen 'write'."
fi

echo "→ Are the workflows on the default branch?"
if git diff --quiet HEAD -- .github/workflows CLAUDE.md 2>/dev/null \
   && git ls-tree -r --name-only "origin/$BASE" 2>/dev/null | grep -q '.github/workflows/claude.yml'; then
  ok "committed and pushed"
else
  block "not yet — Actions only triggers issue events from the default branch, so nothing will fire."
  warn "    git add -A && git commit -m 'add claude bridge' && git push"
fi

cat <<MSG

Remaining, and only you can do these:
  1. Install the Claude GitHub App on $REPO — https://github.com/apps/claude
     (or run 'claude', then type /install-github-app at the prompt)
  2. Edit the <placeholders> in CLAUDE.md. Claude reads that file first on
     every run, so testing before you fill it in tests the template, not
     your repo.
  3. Commit and push, if the check above said otherwise.
  4. Test it:
       gh issue create --title "Add a CONTRIBUTING.md" \\
         --body "@claude Add a short CONTRIBUTING.md describing how to run the tests.
       Done means: the file exists and the tests still pass."
  5. Confirm: a pull request appears, opened by github-actions (NOT by the
     Claude app — it has no such tool), and https://platform.claude.com/usage
     shows no API spend for the run.
MSG

# Exit code has to mean something. Warnings are advice; blockers leave the
# bridge non-functional, and this script used to exit 0 on a repo that
# scripts/doctor.sh exits 1 on. A check that reports instead of failing reads
# as a pass — that was issue #36.
if [ "$BLOCKED" -gt 0 ]; then
  printf '\n  ✗ %d blocker(s) above. The bridge will NOT work until they are fixed.\n' "$BLOCKED" >&2
  printf '    Fix them, then re-run this script or: scripts/doctor.sh %s\n\n' "$REPO" >&2
  exit 1
fi
printf '\n  ✓ Nothing blocking on the repo side.\n\n'

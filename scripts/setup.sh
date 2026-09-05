#!/usr/bin/env bash
# grokbot-claude-bridge — Step 1 of the setup guide, automated.
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

BRIDGE_DIR="${BRIDGE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
fail() { printf '\n  ✗ %s\n' "$*" >&2; exit 1; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }

echo "→ Prerequisites"
command -v gh    >/dev/null || fail "gh CLI not found — https://cli.github.com"
command -v git   >/dev/null || fail "git not found"
gh auth status   >/dev/null 2>&1 || fail "gh is not logged in — run: gh auth login"
git rev-parse --git-dir >/dev/null 2>&1 || fail "not inside a git repository"
ok "gh, git, and a git repo"

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
BASE="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"
OWNER_TYPE="$(gh api "repos/$REPO" --jq .owner.type)"
echo "→ Target: $REPO (default branch: $BASE, owner type: $OWNER_TYPE)"

if [ "$OWNER_TYPE" != "Organization" ]; then
  warn "This repo is owned by a personal account."
  warn "Steps 1 and 2 will work fine. But Phase 1's machine account will NOT:"
  warn "GitHub does not let a collaborator create a fine-grained token for a"
  warn "repo they do not own, and the classic-PAT fallback needs full 'repo'"
  warn "scope. Move this repo to an organisation before Phase 1. (issue #46)"
fi

echo "→ Subscription token"
if gh secret list --repo "$REPO" 2>/dev/null | grep -q '^CLAUDE_CODE_OAUTH_TOKEN'; then
  ok "CLAUDE_CODE_OAUTH_TOKEN already set"
else
  cat <<'MSG'
  Not set. Run these two commands yourself, in this order:

      claude setup-token
      gh secret set CLAUDE_CODE_OAUTH_TOKEN

  The first opens a browser; approve, then copy the token it prints.
  The second prompts you to paste it — nothing appears as you paste, which
  is deliberate. Then re-run this script.
MSG
  exit 1
fi

echo "→ Workflows"
mkdir -p .github/workflows
for f in claude.yml claude-open-pr.yml; do
  if [ -e ".github/workflows/$f" ]; then
    ok "$f already present, left alone"
  else
    cp "$BRIDGE_DIR/templates/$f" ".github/workflows/$f"
    ok "$f installed"
  fi
done

echo "→ Repo instructions"
if [ -e CLAUDE.md ]; then
  warn "CLAUDE.md exists — NOT overwriting it."
  warn "Merge in what you need from $BRIDGE_DIR/templates/CLAUDE.md.template by hand."
else
  cp "$BRIDGE_DIR/templates/CLAUDE.md.template" CLAUDE.md
  ok "CLAUDE.md created — edit the <placeholders> before your first task"
fi

echo "→ Actions must be allowed to open pull requests"
# Off by default on every repo. Without it claude-open-pr.yml fails with
# "GitHub Actions is not permitted to create or approve pull requests". (D12)
if gh api "repos/$REPO/actions/permissions/workflow" --jq .can_approve_pull_request_reviews 2>/dev/null | grep -q true; then
  ok "already enabled"
else
  warn "NOT enabled. Either run:"
  warn "    gh api -X PUT repos/$REPO/actions/permissions/workflow \\"
  warn "      -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true"
  warn "  or tick Settings → Actions → General → Workflow permissions →"
  warn "  'Allow GitHub Actions to create and approve pull requests'."
fi

echo "→ Are the workflows on the default branch?"
if git diff --quiet HEAD -- .github/workflows CLAUDE.md 2>/dev/null \
   && git ls-tree -r --name-only "origin/$BASE" 2>/dev/null | grep -q '.github/workflows/claude.yml'; then
  ok "committed and pushed"
else
  warn "not yet. Actions only triggers issue events from the default branch:"
  warn "    git add -A && git commit -m 'add claude bridge' && git push"
fi

cat <<MSG

Remaining, and only you can do these:
  1. Install the Claude GitHub App on $REPO — https://github.com/apps/claude
     (or run 'claude', then type /install-github-app at the prompt)
  2. Commit and push, if the check above said otherwise.
  3. Test it:
       gh issue create --title "Add a CONTRIBUTING.md" \\
         --body "@claude Add a short CONTRIBUTING.md describing how to run the tests.
       Done means: the file exists and the tests still pass."
  4. Confirm: a pull request appears, opened by github-actions (NOT by the
     Claude app — it has no such tool), and https://platform.claude.com/usage
     shows no API spend for the run.
MSG

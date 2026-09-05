#!/usr/bin/env bash
# grokbot-claude-bridge — Step 1 of the setup guide, automated.
# Run from inside the consumer repo. Requires: gh (logged in), claude (logged in with your subscription).
set -euo pipefail

BRIDGE_DIR="${BRIDGE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "→ Checking prerequisites"
command -v gh >/dev/null || { echo "gh CLI not found"; exit 1; }
command -v claude >/dev/null || { echo "claude CLI not found"; exit 1; }
gh auth status >/dev/null || { echo "gh not logged in"; exit 1; }

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "→ Target repo: $REPO"

if ! gh secret list | grep -q '^CLAUDE_CODE_OAUTH_TOKEN'; then
  echo "→ Generating a subscription OAuth token (claude setup-token)"
  TOKEN="$(claude setup-token 2>/dev/null | tail -n1)"
  [ -n "$TOKEN" ] || { echo "setup-token produced no output; run it manually"; exit 1; }
  printf '%s' "$TOKEN" | gh secret set CLAUDE_CODE_OAUTH_TOKEN
  echo "  secret CLAUDE_CODE_OAUTH_TOKEN set"
else
  echo "→ Secret CLAUDE_CODE_OAUTH_TOKEN already present"
fi

echo "→ Installing workflow and CLAUDE.md"
mkdir -p .github/workflows
cp -n "$BRIDGE_DIR/templates/claude.yml" .github/workflows/claude.yml && echo "  .github/workflows/claude.yml" || echo "  workflow exists, skipped"
cp -n "$BRIDGE_DIR/templates/CLAUDE.md.template" CLAUDE.md && echo "  CLAUDE.md (edit the placeholders)" || echo "  CLAUDE.md exists, skipped"

cat <<MSG

Next:
  1. Install the Claude GitHub App on $REPO: https://github.com/apps/claude
  2. Edit CLAUDE.md placeholders, commit, push to the default branch.
  3. Test:  gh issue create --title "Add CONTRIBUTING.md" --body "@claude Add a short CONTRIBUTING.md describing how to run the tests. Open a PR."
  4. Confirm: PR appears; no API spend in Anthropic Console.
MSG

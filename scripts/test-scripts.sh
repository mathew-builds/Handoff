#!/usr/bin/env bash
# Regression tests for scripts/*.sh.
#
# Why this exists. On 2026-09-06 a one-line change to setup.sh made a *correctly
# configured* repo exit 1 and silently skip three later checks. `bash -n` passed.
# `shellcheck` passed. `actionlint` does not read these files at all, and CI ran
# no check over scripts/ whatsoever. Only RUNNING the script — against the input
# where it is supposed to SUCCEED — showed it.
#
# Two rules follow from that, and they are the whole design of this file:
#   1. Syntax checks are necessary and not sufficient. Execute the thing.
#   2. Every case is tested in BOTH directions. A check exercised only against
#      the input it should reject shows a perfect pass while being broken — that
#      is issue #36, and it is how the bug above shipped.
#
# Exits non-zero if anything fails. Never add `|| true`.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0
ok()  { printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ syntax"
for f in "$ROOT"/scripts/*.sh; do
  if bash -n "$f" 2>/dev/null; then ok "bash -n $(basename "$f")"
  else bad "bash -n $(basename "$f")"; fi
done

echo "→ shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  for f in "$ROOT"/scripts/*.sh; do
    if shellcheck -S warning "$f" >/dev/null 2>&1; then ok "shellcheck $(basename "$f")"
    else bad "shellcheck $(basename "$f")"; shellcheck -S warning "$f" || true; fi
  done
else
  bad "shellcheck is not installed — install it rather than skipping this"
fi

# ---------------------------------------------------------------------------
# Execution: the CLAUDE.md placeholder guard in setup.sh, both directions.
#
# setup.sh runs under `set -e`. grep exits 1 when it matches nothing, and
# pipefail propagates that, so the FILLED-IN case — the success path — is the
# one that breaks. That asymmetry is the entire point of testing both ways.
# ---------------------------------------------------------------------------
echo "→ setup.sh placeholder guard, both directions"

GUARD="$(grep -m1 '^LEFT=' "$ROOT/scripts/setup.sh" || true)"
if [ -z "$GUARD" ]; then
  bad "no line starting 'LEFT=' in setup.sh — the guard moved; update this test"
else
  printf 'set -euo pipefail\n%s\nprintf "SURVIVED:[%%s]\\n" "$LEFT"\n' "$GUARD" > "$TMP/run.sh"

  # (a) correctly filled in → must survive set -e, and report nothing left
  sed -E 's|<REPO NAME>|acme/api|; s|<test command>|pytest -q|; s|<paths that must not change[^>]*>|infra/|; s|<\.\.\.>|a rule|g; s|<lint, formatting, naming>|black|' \
    "$ROOT/templates/CLAUDE.md.template" > "$TMP/CLAUDE.md"
  ( cd "$TMP" && bash run.sh ) > "$TMP/out-filled" 2>&1
  if grep -q 'SURVIVED:\[\]' "$TMP/out-filled"; then
    ok "filled CLAUDE.md — guard survives set -e and reports nothing outstanding"
  else
    bad "filled CLAUDE.md — guard did NOT survive. This is the 2026-09-06 regression."
    sed 's/^/       /' "$TMP/out-filled"
  fi

  # (b) raw template → must survive AND actually detect the placeholders
  cp "$ROOT/templates/CLAUDE.md.template" "$TMP/CLAUDE.md"
  ( cd "$TMP" && bash run.sh ) > "$TMP/out-raw" 2>&1
  if grep -q 'SURVIVED:\[.*<REPO NAME>.*\]' "$TMP/out-raw"; then
    ok "raw template — guard detects the unfilled placeholders"
  else
    bad "raw template — guard failed to detect placeholders (it can no longer fail)"
    sed 's/^/       /' "$TMP/out-raw"
  fi
fi

echo
if [ "$FAIL" -ne 0 ]; then
  echo "scripts/: FAILED" >&2
  exit 1
fi
echo "scripts/: all checks passed"

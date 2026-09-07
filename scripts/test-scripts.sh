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

# ---------------------------------------------------------------------------
# Execution: the misrouted-issue guard in templates/claude.yml (D14).
#
# This is product code that ships to consumers, it is shell, and it contains a
# `|| true` whose absence would break the COMMON case — no `Repo:` line at all.
# That is the same shape as the setup.sh bug of 2026-09-06. Tested here so a
# regression fails the build rather than a stranger's install.
# ---------------------------------------------------------------------------
echo "→ templates/claude.yml misrouted-issue guard"

GUARD="$TMP/guard.sh"
python3 - "$ROOT" "$GUARD" <<'PY' 2>/dev/null || true
import sys, yaml
root, out = sys.argv[1], sys.argv[2]
doc = yaml.safe_load(open(f"{root}/templates/claude.yml"))
for step in doc["jobs"]["claude"]["steps"]:
    if step.get("name") == "Refuse a misrouted issue":
        open(out, "w").write(step["run"])
PY

if [ ! -s "$GUARD" ]; then
  bad "could not extract the 'Refuse a misrouted issue' step — renamed or removed? (D14)"
else
  bash -n "$GUARD" && ok "guard: bash -n" || bad "guard: bash -n"

  mkdir -p "$TMP/gbin"
  printf '#!/usr/bin/env bash\necho "called" >> "$COMMENTS_LOG"\n' > "$TMP/gbin/gh"
  chmod +x "$TMP/gbin/gh"

  guard_case() {  # name  body  this_repo  is_new  want_rc  want_comment
    : > "$TMP/comments.log"
    ( PATH="$TMP/gbin:$PATH" COMMENTS_LOG="$TMP/comments.log" RUNNER_TEMP="$TMP" \
      BODY="$2" THIS_REPO="$3" ISSUE=1 IS_NEW_ISSUE="$4" \
      bash "$GUARD" >/dev/null 2>&1 )
    local rc=$? commented=no
    [ -s "$TMP/comments.log" ] && commented=yes
    if [ "$rc" = "$5" ] && [ "$commented" = "$6" ]; then
      ok "guard: $1"
    else
      bad "guard: $1 — got exit=$rc commented=$commented, wanted exit=$5 commented=$6"
    fi
  }

  # The success path first. If this breaks, every single-repo install breaks.
  guard_case "no Repo: line runs normally"        "@claude go"                    "o/r" true  0 no
  guard_case "matching Repo: runs normally"       "Repo: o/r"$'\n\n'"@claude go"  "o/r" true  0 no
  guard_case "case-insensitive match runs"        "repo: O/R"$'\n\n'"@claude go"  "o/r" true  0 no
  guard_case "prose 'repo:' is not a declaration" "the repo: is fine @claude"     "o/r" true  0 no
  guard_case "mismatch refuses and comments"      "Repo: o/x"$'\n\n'"@claude go"  "o/r" true  1 yes
  guard_case "mismatch on a comment cannot loop"  "Repo: o/x"$'\n\n'"@claude go"  "o/r" false 1 no

  # The refusal comment must never carry the trigger phrase: a comment
  # containing it restarts the workflow, and on issue_comment the body read is
  # the ISSUE's, so it would find the same bad line and comment forever.
  if grep -q '@claude' "$TMP/misrouted.md" 2>/dev/null; then
    bad "guard: the refusal comment contains the trigger phrase — this loops"
  else
    ok "guard: refusal comment carries no trigger phrase"
  fi
fi

# ---------------------------------------------------------------------------
# Execution: the cost-brake checker, against deliberately broken workflows.
#
# check-workflow-caps.py is the control behind CLAUDE.md's three mandatory
# brakes, and until 2026-09-07 nobody had ever run it against input it should
# reject. Two mutants survived. The worse one renamed the action and deleted
# --max-turns, and the checker printed "--max-turns present" and exited 0 — the
# string was chosen by the FILENAME, not by the check. That is not a check that
# cannot fail; it is a check that asserts the opposite of the truth.
#
# Same rule as everything above: both directions, and the passing direction
# first so a checker that has stopped working at all cannot look healthy.
# ---------------------------------------------------------------------------
echo "→ check-workflow-caps.py, against broken workflows"

caps_sandbox() {  # a clean tree to mutate; ROOT is derived from the script's path
  rm -rf "$TMP/caps"
  mkdir -p "$TMP/caps/scripts" "$TMP/caps/templates" "$TMP/caps/.github/workflows"
  cp "$ROOT/scripts/check-workflow-caps.py" "$TMP/caps/scripts/"
  cp "$ROOT"/templates/*.yml "$TMP/caps/templates/"
  cp "$ROOT"/.github/workflows/*.yml "$TMP/caps/.github/workflows/"
}

mut_none()          { :; }
mut_strip_turns()   { perl -pi -e 's/--max-turns 25//' templates/claude.yml; }
mut_rename_action() { perl -pi -e 's{anthropics/claude-code-action}{acme/claude-wrapper}' templates/claude.yml; }
mut_rename_strip()  { mut_rename_action; mut_strip_turns; }
mut_drop_group()    { perl -0pi -e 's/\nconcurrency:\n(?:  .*\n)+/\n/' templates/claude.yml; }
mut_drop_timeout()  { perl -pi -e 's/^\s*timeout-minutes:.*\n//' templates/claude.yml; }
mut_delete_needed() { rm -f templates/weekly-cost.yml; }
mut_new_template()  {   # the roadmap's own next idea: a scheduled agent run
  {
    echo 'name: Nightly'
    echo 'on:'
    echo '  schedule:'
    echo '    - cron: "0 3 * * *"'
    echo 'jobs:'
    echo '  maintain:'
    echo '    runs-on: ubuntu-latest'
    echo '    steps:'
    echo '      - uses: anthropics/claude-code-action@v1'
    echo '        with:'
    echo '          claude_args: --model sonnet'
  } > templates/nightly.yml
}

caps_case() {  # name  want_rc  mutation_fn  [string that must NOT appear]
  caps_sandbox
  ( cd "$TMP/caps" && "$3" ) >/dev/null 2>&1
  local out rc
  out="$( cd "$TMP/caps" && python3 scripts/check-workflow-caps.py 2>&1 )"
  rc=$?
  if [ "$rc" != "$2" ]; then
    bad "caps: $1 — exit $rc, wanted $2"
    printf '%s\n' "$out" | sed 's/^/       /'
  elif [ -n "${4:-}" ] && printf '%s\n' "$out" | grep -qF -- "$4"; then
    bad "caps: $1 — exit was right but the output still claims \"$4\""
    printf '%s\n' "$out" | sed 's/^/       /'
  else
    ok "caps: $1"
  fi
}

# The success path first: if this breaks, every case below is meaningless.
caps_case "unmutated tree passes"                0 mut_none
caps_case "stripped --max-turns fails"           1 mut_strip_turns   "--max-turns present"
caps_case "renamed action + stripped brake fails" 1 mut_rename_strip "--max-turns present"
caps_case "renamed action alone fails loudly"    1 mut_rename_action
caps_case "missing concurrency group fails"      1 mut_drop_group
caps_case "missing timeout-minutes fails"        1 mut_drop_timeout
caps_case "deleted required workflow fails"      1 mut_delete_needed
caps_case "new uncapped template is checked too" 1 mut_new_template

echo
if [ "$FAIL" -ne 0 ]; then
  echo "scripts/: FAILED" >&2
  exit 1
fi
echo "scripts/: all checks passed"

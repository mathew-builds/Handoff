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
GUARD_ENV="$TMP/guard.env"
python3 - "$ROOT" "$GUARD" "$GUARD_ENV" <<'PY' 2>/dev/null || true
import sys, yaml
root, out, envout = sys.argv[1], sys.argv[2], sys.argv[3]
doc = yaml.safe_load(open(f"{root}/templates/claude.yml"))
for step in doc["jobs"]["claude"]["steps"]:
    if step.get("name") == "Refuse a misrouted issue":
        open(out, "w").write(step["run"])
        # The names the workflow actually provides. Taken from the file so the
        # test reflects the workflow rather than the harness's own guesses.
        open(envout, "w").write("\n".join(sorted((step.get("env") or {}).keys())) + "\n")
PY

if [ ! -s "$GUARD" ]; then
  bad "could not extract the 'Refuse a misrouted issue' step — renamed or removed? (D14)"
else
  bash -n "$GUARD" && ok "guard: bash -n" || bad "guard: bash -n"

  # `gh` works out which repository to act on from the checked-out git remote,
  # and this step runs BEFORE actions/checkout on purpose. So the workflow must
  # name the repository itself. It shipped without doing so: the refusal comment
  # could never be posted in production, and six guard cases passed anyway
  # because the stub below used to ignore its arguments and always succeed.
  if grep -qx 'GH_REPO' "$GUARD_ENV"; then
    ok "guard: step declares GH_REPO, so gh can resolve the repo with no checkout"
    GUARD_GH_REPO=yes
  else
    bad "guard: step does not declare GH_REPO — the refusal comment cannot be posted"
    GUARD_GH_REPO=no
  fi

  mkdir -p "$TMP/gbin"
  cat > "$TMP/gbin/gh" <<'STUB'
#!/usr/bin/env bash
# Reproduce the one real-gh behaviour this guard depends on: with no git remote
# and neither --repo nor GH_REPO, gh cannot resolve a target and exits non-zero
# with "failed to run git: fatal: not a git repository". Verified against
# gh 2.97.0 on 2026-09-07. A stub that always succeeds hides the exact defect
# this test exists to catch, which is what happened before.
if [ -z "${GH_REPO:-}" ] && [[ " $* " != *" --repo "* ]]; then
  echo "failed to run git: fatal: not a git repository" >&2
  exit 1
fi
echo "called" >> "$COMMENTS_LOG"
STUB
  chmod +x "$TMP/gbin/gh"

  guard_case() {  # name  body  this_repo  is_new  want_rc  want_comment
    : > "$TMP/comments.log"
    local -a envargs=(
      "PATH=$TMP/gbin:$PATH" "COMMENTS_LOG=$TMP/comments.log" "RUNNER_TEMP=$TMP"
      "BODY=$2" "THIS_REPO=$3" "ISSUE=1" "IS_NEW_ISSUE=$4"
    )
    # Pass GH_REPO only when the workflow itself declares it. The test must fail
    # when the workflow stops providing it, not paper over the gap.
    [ "$GUARD_GH_REPO" = yes ] && envargs+=("GH_REPO=$3")
    ( env "${envargs[@]}" bash "$GUARD" >/dev/null 2>&1 )
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
  #
  # Assert the artefact EXISTS before concluding anything from it. `grep -q` on
  # a missing file exits 2, which makes the `if` false and prints ok — so if the
  # body's filename ever changed, this check would pass while testing nothing.
  # That is issue #36's shape: a check that reports instead of failing.
  if [ ! -s "$TMP/misrouted.md" ]; then
    bad "guard: no refusal body was written — the trigger-phrase check proves nothing"
  elif grep -q '@claude' "$TMP/misrouted.md"; then
    bad "guard: the refusal comment contains the trigger phrase — this loops"
  else
    ok "guard: refusal comment carries no trigger phrase"
  fi
fi

echo
if [ "$FAIL" -ne 0 ]; then
  echo "scripts/: FAILED" >&2
  exit 1
fi
echo "scripts/: all checks passed"

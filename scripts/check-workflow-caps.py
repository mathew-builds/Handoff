#!/usr/bin/env python3
"""Enforce the three cost brakes CLAUDE.md requires on every workflow here.

CLAUDE.md says: "Every workflow change must keep: `concurrency` group, a
`timeout-minutes`, and `--max-turns` in `claude_args`." That was a sentence in a
document, which is a hope rather than a control. This makes it exit non-zero.

Decision D10 is the reasoning; issue #24 is why it is enforced in CI.

Two defects of this script's own, both found by the 2026-09-07 pre-public audit
and fixed here. They are the same shape and worth knowing about, because it is
the shape this repository keeps producing:

  1. It printed ", --max-turns present" whenever the file happened to be named
     claude.yml — from the FILENAME, never from the result of the check. Rename
     the action and delete --max-turns and it printed "--max-turns present" and
     exited 0. Not merely a check that could not fail: a check that asserted the
     opposite of the truth.
  2. It read three hard-coded paths, so a fourth workflow added later would ship
     to consumers with no brakes and a green CI. A scheduled agent run is the
     first item in the roadmap's ideas backlog, so that was not hypothetical.
  3. Found 2026-09-07, fixed 2026-09-08 (issue #106, D15). It recognised an agent
     step only by the action's OWNER — `anthropics/`. A workflow running any
     other vendor's coding agent therefore had zero agent steps, so brake 3 was
     neither verified nor failed. It was skipped, and the run exited 0.
     Reproduced: a `templates/codex.yml` running `some-other-vendor/...` with no
     turn cap at all passed the build.

     Subtler than defect 1 and worth the distinction. Defect 1 ASSERTED a brake
     it had not checked. This one honestly listed only the brakes it verified
     and simply said nothing about the third — which still reads as a pass,
     because four green lines where one is quietly missing a term is not
     something anyone catches by eye.

Three rules follow, and they are the design of this file:

  * Every line printed is derived from what was actually checked. Nothing is
    derived from a filename.
  * When a brake cannot be VERIFIED, that is a failure, not a silent skip.
  * A workflow this file does not recognise FAILS. It does not pass quietly.
    Recognising by vendor made "unknown" mean "fine"; the default is inverted,
    so a new workflow is caught the day it is added rather than the day someone
    remembers to teach this script about it.
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent

# Discovered, not listed. A new template is checked the day it is added rather
# than the day someone remembers to add it here.
SEARCH = (
    "templates/*.yml",
    "templates/*.yaml",
    ".github/workflows/*.yml",
    ".github/workflows/*.yaml",
)

# Globbing cannot notice a DELETED workflow, so the ones we know must exist are
# still named. Removing weekly-cost.yml should fail, not quietly shrink the run.
REQUIRED = (
    Path("templates/claude.yml"),
    Path("templates/weekly-cost.yml"),
    Path(".github/workflows/ci.yml"),
)

# Workflows whose whole purpose is to run the agent. If one of these contains no
# agent step, brake 3 cannot be verified and that must be loud. This is what
# stops a rename from turning the brake off while the output still claims it on.
MUST_RUN_AGENT = (Path("templates/claude.yml"),)

# Workflows that deliberately use NO model turns, so brake 3 does not apply.
# This is an explicit declaration, not an inference: weekly-cost.yml is `gh` and
# `awk` by design (D-weekly-cost) and ci.yml lints. Demanding a turn cap of them
# would be wrong rather than stricter.
#
# Everything NOT listed here must demonstrate a turn cap. That is the inversion
# that fixes defect 3: "we don't recognise this workflow" now means "fail",
# where it used to mean "skip".
NO_AGENT = (
    Path("templates/weekly-cost.yml"),
    Path(".github/workflows/ci.yml"),
)

# A step runs the agent if it uses an action published by the vendor. Matching
# the exact repository name meant any rename, fork or wrapper silently disabled
# brake 3 — so match the owner, and fail loudly if a must-run-agent workflow has
# no such step at all.
#
# This stays vendor-specific ON PURPOSE, and only for MUST_RUN_AGENT: it is what
# catches `templates/claude.yml` having its action swapped for a wrapper. It is
# no longer how brake 3 is found — see CAP_FLAGS.
AGENT_PREFIX = "anthropics/"

# How a turn cap is recognised, whoever published the action. Brake 3 is a
# property of the workflow, not of the vendor — so look for the brake itself
# rather than for a brand. A second coding agent with its own flag name adds it
# here; that is the one line of maintenance, and forgetting it fails loudly
# instead of passing quietly.
CAP_FLAGS = ("--max-turns",)


def check(target: Path, rel: Path) -> tuple[list[str], list[str]]:
    """Return (failures, brakes actually verified) for one workflow file."""
    doc = yaml.safe_load(target.read_text(encoding="utf-8")) or {}
    failures: list[str] = []
    verified: list[str] = []

    # 1. concurrency group
    if (doc.get("concurrency") or {}).get("group"):
        verified.append("concurrency group")
    else:
        failures.append("no `concurrency.group` — parallel runs are uncapped")

    # 2. timeout-minutes on every job
    jobs = doc.get("jobs") or {}
    if not jobs:
        failures.append("no jobs — nothing to brake, which is not a workflow we understand")
    missing = [n for n, job in jobs.items() if not (job or {}).get("timeout-minutes")]
    for name in missing:
        failures.append(f"job `{name}` has no `timeout-minutes` — no wall-clock brake")
    if jobs and not missing:
        verified.append("timeout-minutes")

    # 3. --max-turns inside claude_args, but only where the agent actually runs.
    #    weekly-cost.yml and ci.yml deliberately use no model turns
    #    (D-weekly-cost), so demanding claude_args of them would be wrong, not
    #    stricter. Every agent step must be capped, not merely one of them.
    agent_steps = 0
    capped = 0
    cap_seen_anywhere = False
    for name, job in jobs.items():
        for step in (job or {}).get("steps") or []:
            step = step or {}
            with_block = step.get("with") or {}

            # Vendor-agnostic: does ANY input on this step carry a turn cap?
            # Scanning every value rather than the `claude_args` key alone is
            # what lets a second vendor's differently-named input be seen.
            for value in with_block.values():
                if isinstance(value, str) and any(f in value for f in CAP_FLAGS):
                    cap_seen_anywhere = True
                    break

            # Vendor-specific, and only to catch a swapped action in claude.yml.
            if not (step.get("uses") or "").startswith(AGENT_PREFIX):
                continue
            agent_steps += 1
            args = with_block.get("claude_args") or ""
            if any(f in args for f in CAP_FLAGS):
                capped += 1
            else:
                failures.append(
                    f"job `{name}` has no `--max-turns` in claude_args — loops are uncapped"
                )

    if rel in MUST_RUN_AGENT and agent_steps == 0:
        failures.append(
            f"no step uses an `{AGENT_PREFIX}...` action, so `--max-turns` could not be "
            "checked — if the action moved, update AGENT_PREFIX rather than lose the brake"
        )

    # The inversion. A workflow that is not declared turn-free must SHOW a cap.
    # Previously an unrecognised vendor meant brake 3 was skipped in silence;
    # now it is the failure it always should have been. See defect 3 above.
    if rel not in NO_AGENT and not cap_seen_anywhere:
        failures.append(
            "no turn cap found in any step — this workflow is not listed in NO_AGENT, "
            "so it must show one of " + ", ".join(f"`{f}`" for f in CAP_FLAGS) + ". "
            "If it genuinely uses no model turns, add it to NO_AGENT and say why; "
            "if it runs a coding agent, cap it. Do not leave it unclassified"
        )

    if cap_seen_anywhere and not failures:
        verified.append("--max-turns")

    return failures, verified


def targets() -> list[tuple[Path, Path]]:
    """Every workflow to check: globbed, plus the required ones so absence fails."""
    found = [p for pattern in SEARCH for p in ROOT.glob(pattern)]
    found += [ROOT / rel for rel in REQUIRED]

    out: list[tuple[Path, Path]] = []
    seen: set[Path] = set()
    for path in sorted(found, key=lambda p: str(p)):
        rel = path.relative_to(ROOT)
        if rel not in seen:
            seen.add(rel)
            out.append((path, rel))
    return out


def main() -> int:
    rc = 0
    for target, rel in targets():
        if not target.exists():
            print(f"FAIL: {rel} is missing", file=sys.stderr)
            rc = 1
            continue

        try:
            failures, verified = check(target, rel)
        except yaml.YAMLError as exc:
            print(f"FAIL: {rel} is not valid YAML: {exc}", file=sys.stderr)
            rc = 1
            continue

        if failures:
            print(f"{rel}: {len(failures)} missing cost brake(s):", file=sys.stderr)
            for failure in failures:
                print(f"  - {failure}", file=sys.stderr)
            rc = 1
        else:
            # Printed from what was verified, never from the filename.
            print(f"{rel}: {', '.join(verified)} present")

    if rc:
        print("\nSee docs/02-decisions.md D10.", file=sys.stderr)
    return rc


if __name__ == "__main__":
    sys.exit(main())

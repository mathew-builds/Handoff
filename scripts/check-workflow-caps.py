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

Two rules follow, and they are the design of this file:

  * Every line printed is derived from what was actually checked. Nothing is
    derived from a filename.
  * When a brake cannot be VERIFIED, that is a failure, not a silent skip.
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

# A step runs the agent if it uses an action published by the vendor. Matching
# the exact repository name meant any rename, fork or wrapper silently disabled
# brake 3 — so match the owner, and fail loudly if a must-run-agent workflow has
# no such step at all.
AGENT_PREFIX = "anthropics/"


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
    for name, job in jobs.items():
        for step in (job or {}).get("steps") or []:
            uses = (step or {}).get("uses") or ""
            if not uses.startswith(AGENT_PREFIX):
                continue
            agent_steps += 1
            args = ((step.get("with") or {}).get("claude_args")) or ""
            if "--max-turns" in args:
                capped += 1
            else:
                failures.append(
                    f"job `{name}` has no `--max-turns` in claude_args — loops are uncapped"
                )
    if agent_steps and capped == agent_steps:
        verified.append("--max-turns")

    if rel in MUST_RUN_AGENT and agent_steps == 0:
        failures.append(
            f"no step uses an `{AGENT_PREFIX}...` action, so `--max-turns` could not be "
            "checked — if the action moved, update AGENT_PREFIX rather than lose the brake"
        )

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

#!/usr/bin/env python3
"""Enforce the three cost brakes CLAUDE.md requires on the consumer workflow.

CLAUDE.md says: "Every workflow change must keep: `concurrency` group, a
`timeout-minutes`, and `--max-turns` in `claude_args`." That was a sentence in a
document, which is a hope rather than a control. This makes it exit non-zero.

Decision D10 is the reasoning; issue #24 is why it is enforced in CI.
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent

# Every workflow this repository owns, not just the product one. This checked only
# templates/claude.yml until 2026-09-06, which meant the brakes could be stripped from
# weekly-cost.yml or ci.yml and CI stayed green. weekly-cost.yml is the one that matters:
# it loops one HTTP call per run over last week's runs, which is exactly the shape
# timeout-minutes exists to bound.
TARGETS = [
    ROOT / "templates" / "claude.yml",
    ROOT / "templates" / "weekly-cost.yml",
    ROOT / ".github" / "workflows" / "ci.yml",
]


def check(target: Path) -> list[str]:
    """Return a list of missing brakes for one workflow file."""
    doc = yaml.safe_load(target.read_text(encoding="utf-8"))
    failures: list[str] = []

    # 1. concurrency group
    if not (doc.get("concurrency") or {}).get("group"):
        failures.append("no `concurrency.group` — parallel runs are uncapped")

    # 2. timeout-minutes on every job
    for name, job in (doc.get("jobs") or {}).items():
        if not job.get("timeout-minutes"):
            failures.append(f"job `{name}` has no `timeout-minutes` — no wall-clock brake")

    # 3. --max-turns inside claude_args, but only where the agent actually runs.
    #    weekly-cost.yml and ci.yml deliberately use no model turns (D-weekly-cost),
    #    so demanding claude_args of them would be wrong, not stricter.
    uses_action = False
    args_ok = False
    for name, job in (doc.get("jobs") or {}).items():
        for step in job.get("steps") or []:
            if "claude-code-action" not in (step.get("uses") or ""):
                continue
            uses_action = True
            args = (step.get("with") or {}).get("claude_args") or ""
            if "--max-turns" in args:
                args_ok = True
            else:
                failures.append(f"job `{name}` has no `--max-turns` in claude_args — loops are uncapped")
    if uses_action and not args_ok and not failures:
        failures.append("no `--max-turns` in claude_args")

    return failures


def main() -> int:
    rc = 0
    for target in TARGETS:
        rel = target.relative_to(ROOT)
        if not target.exists():
            print(f"FAIL: {rel} is missing", file=sys.stderr)
            rc = 1
            continue

        failures = check(target)
        if failures:
            print(f"{rel}: {len(failures)} missing cost brake(s):", file=sys.stderr)
            for f in failures:
                print(f"  - {f}", file=sys.stderr)
            rc = 1
        else:
            print(f"{rel}: concurrency group and timeout-minutes present"
                  + (", --max-turns present" if "claude.yml" == rel.name else ""))

    if rc:
        print("\nSee docs/02-decisions.md D10.", file=sys.stderr)
    return rc


if __name__ == "__main__":
    sys.exit(main())

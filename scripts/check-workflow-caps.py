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
TARGET = ROOT / "templates" / "claude.yml"


def main() -> int:
    if not TARGET.exists():
        print(f"FAIL: {TARGET.relative_to(ROOT)} is missing", file=sys.stderr)
        return 1

    doc = yaml.safe_load(TARGET.read_text(encoding="utf-8"))
    failures: list[str] = []

    # 1. concurrency group
    group = (doc.get("concurrency") or {}).get("group")
    if not group:
        failures.append("no `concurrency.group` — parallel runs are uncapped")

    # 2. timeout-minutes on every job
    for name, job in (doc.get("jobs") or {}).items():
        if not job.get("timeout-minutes"):
            failures.append(f"job `{name}` has no `timeout-minutes` — no wall-clock brake")

    # 3. --max-turns inside claude_args
    args_found = False
    for name, job in (doc.get("jobs") or {}).items():
        for step in job.get("steps") or []:
            uses = step.get("uses") or ""
            if "claude-code-action" not in uses:
                continue
            args = (step.get("with") or {}).get("claude_args") or ""
            args_found = True
            if "--max-turns" not in args:
                failures.append(f"job `{name}` has no `--max-turns` in claude_args — loops are uncapped")
    if not args_found:
        failures.append("no claude-code-action step found with `claude_args`")

    rel = TARGET.relative_to(ROOT)
    if failures:
        print(f"{rel}: {len(failures)} missing cost brake(s):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        print("\nSee docs/02-decisions.md D10.", file=sys.stderr)
        return 1

    print(f"{rel}: concurrency group, timeout-minutes and --max-turns all present")
    return 0


if __name__ == "__main__":
    sys.exit(main())

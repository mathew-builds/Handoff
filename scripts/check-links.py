#!/usr/bin/env python3
"""Check that every relative Markdown link in this repo points at a file that exists.

Deliberately does NOT check external URLs: they fail for reasons that have
nothing to do with this repo (rate limits, transient outages) and a check that
goes red for unrelated reasons gets ignored, which is worse than no check.

Exits non-zero on the first broken link. See docs/02-decisions.md D13.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# [text](target) — skip images, autolinks and reference definitions.
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#")


def main() -> int:
    broken: list[str] = []
    checked = 0

    for md in sorted(ROOT.rglob("*.md")):
        if "node_modules" in md.parts:
            continue
        rel_md = md.relative_to(ROOT)
        for lineno, line in enumerate(md.read_text(encoding="utf-8").splitlines(), 1):
            for target in LINK.findall(line):
                target = target.split()[0].strip()  # drop optional "title"
                if target.startswith(SKIP_PREFIXES) or not target:
                    continue
                path_part = target.split("#", 1)[0]
                if not path_part:
                    continue
                checked += 1
                resolved = (md.parent / path_part).resolve()
                if not resolved.exists():
                    broken.append(f"{rel_md}:{lineno}  ->  {target}")

    print(f"checked {checked} relative link(s) across the repo")
    if broken:
        print(f"\n{len(broken)} broken link(s):", file=sys.stderr)
        for b in broken:
            print(f"  {b}", file=sys.stderr)
        return 1

    print("all relative links resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main())

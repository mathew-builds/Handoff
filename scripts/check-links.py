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

# Images were unchecked until 2026-09-07. A broken <img src> does not fail anything: GitHub
# renders a silent placeholder, so it can sit on a front page for years. nektos/act has had a
# 404 hero image at 72k stars, which is the incident that justified adding this.
# Three shapes, because the repo uses all three:
#   ![alt](path)  ·  <img src="path">  ·  <source srcset="path"> inside <picture>
IMAGES = (
    re.compile(r"!\[[^\]]*\]\(([^)]+)\)"),
    re.compile(r"<img\b[^>]*?\bsrc=[\"']([^\"']+)[\"']"),
    re.compile(r"<source\b[^>]*?\bsrcset=[\"']([^\"']+)[\"']"),
)
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#", "data:")


def main() -> int:
    broken: list[str] = []
    checked = 0
    images = 0

    for md in sorted(ROOT.rglob("*.md")):
        if "node_modules" in md.parts:
            continue
        rel_md = md.relative_to(ROOT)
        for lineno, line in enumerate(md.read_text(encoding="utf-8").splitlines(), 1):
            targets = [(t, False) for t in LINK.findall(line)]
            for pattern in IMAGES:
                targets += [(t, True) for t in pattern.findall(line)]

            for target, is_image in targets:
                target = target.split()[0].strip()  # drop optional "title"
                if target.startswith(SKIP_PREFIXES) or not target:
                    continue
                path_part = target.split("#", 1)[0]
                if not path_part:
                    continue
                checked += 1
                if is_image:
                    images += 1
                resolved = (md.parent / path_part).resolve()

                # A target that escapes the repo root is not a file we can check — it is a
                # GitHub-resolved route. The CI badge is the case that matters:
                # `../../actions/workflows/ci.yml/badge.svg` resolves against the rendered blob
                # URL, which is what makes it work in ANY fork without hardcoding an owner or
                # repo name — required by the "no personal repo names anywhere" rule. Flagging
                # it would invite someone to "fix" it into an absolute URL and break every fork.
                if ROOT not in resolved.parents and resolved != ROOT:
                    checked -= 1
                    if is_image:
                        images -= 1
                    continue

                if not resolved.exists():
                    kind = "image" if is_image else "link"
                    broken.append(f"{rel_md}:{lineno}  ({kind})  ->  {target}")

    print(f"checked {checked} relative target(s) across the repo — {images} of them images")
    if broken:
        print(f"\n{len(broken)} broken target(s):", file=sys.stderr)
        for b in broken:
            print(f"  {b}", file=sys.stderr)
        return 1

    print("all relative links and images resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main())

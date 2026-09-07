# Contributing to Handoff

Thanks for looking. This is a small, opinionated project and the conventions below exist because each one was learned by getting it wrong first.

---

## The one rule that matters

**A claim is true only if something ran to produce it.**

This project shipped four load-bearing wrong statements about vendor behaviour before anyone checked — one of them repeated across seventeen places in the docs. Two separate "verifications" of the pull-request step were invalid, both times because the test exercised a human push instead of the automation's. A check was added that could not fail, and passed for exactly that reason.

So:

- **Don't state vendor behaviour you have not read in that vendor's live documentation or watched in a run.** Link the doc or cite the run.
- **When you cannot verify something, write "unverified".** That is an acceptable and useful thing for a document to say. Guessing is not.
- **Before trusting a new check, run it against deliberately broken input** and confirm it goes red. A check that has only ever passed has not been tested.
- **Never add `|| true`.** A check that reports instead of failing reads as a pass.

If you take nothing else from this file, take that.

---

## Two execution contexts. Don't confuse them.

Almost nothing in this repository runs in this repository.

| Lives here | Runs where | What it is |
|---|---|---|
| `.github/workflows/ci.yml` | **this** repo | Lints the templates and checks the docs and cost brakes |
| `templates/claude.yml` | a **consumer's** repo | The product |
| `templates/weekly-cost.yml` | a **consumer's** repo | Optional cost report |
| `templates/CLAUDE.md.template` | a **consumer's** repo | Tells the coding agent how to behave there |
| `templates/bots/*.md`, `templates/routines/*.md` | pasted into a **chat bot** | Prose, not code |
| `scripts/*` | your machine, against a consumer repo | Set up or diagnose |
| `AGENTS.md` | read by an **agent** installing Handoff | The install guide |

A change that is correct in one context is often wrong in the other. Most of the bugs found so far were exactly this mistake.

---

## Before you open a pull request

Run all three. They are what CI runs, so this reproduces it exactly.

```bash
pip install pyyaml    # once

actionlint -ignore 'unexpected key "queue" for "concurrency" section' .github/workflows/*.yml templates/*.yml
python3 scripts/check-links.py
python3 scripts/check-workflow-caps.py
```

Each exits non-zero on failure. The `-ignore` flag is dated and justified in `ci.yml`; drop it once actionlint learns the `queue` key.

**`actionlint` will not catch a bug in a `run:` block.** Shell inside a workflow is invisible to it — a heredoc broke on an apostrophe in this repo and linted clean. If you touch shell in a workflow, extract it and check it:

```bash
python3 -c "import yaml;d=yaml.safe_load(open('templates/weekly-cost.yml'));print(d['jobs']['report']['steps'][0]['run'])" > /tmp/s.sh
bash -n /tmp/s.sh
```

---

## Conventions

- **One pull request per change**, with a title that says what changed rather than which files moved.
- **If a decision changes, update `docs/02-decisions.md` in the same pull request.** That file is the load-bearing one: every non-obvious choice is there with what it beat and what would reverse it, including the entries where we were wrong. Several decisions look arbitrary until you read the constraint behind them.
- **Every workflow change keeps the three cost brakes** — a `concurrency` group, a `timeout-minutes`, and `--max-turns` in `claude_args`. `check-workflow-caps.py` enforces this and will fail your build.
- **Date anything that can go stale** — prices, limits, vendor behaviour.
- **Never commit secrets.** Tokens live in GitHub Secrets or on your own machine.
- **Keep it vendor-neutral where you can.** Grok Bot to Claude Code is the first supported pair, not the only intended one.

### Assets

`assets/*.svg` are hand-authored, not generated — editable, diffable, and free of any generation
watermark. Edit the SVG; there are no PNG copies checked in to drift out of sync.

One exception you will hit: **GitHub's social-preview uploader rejects SVG**, so the card in
Settings has to be a PNG. Render it rather than exporting by hand, because the size matters —
GitHub wants 1280×640 and caps the file at 1 MB:

```
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --hide-scrollbars --force-device-scale-factor=1 --window-size=1280,640 \
  --screenshot=handoff-social.png file://$PWD/assets/handoff-social.svg
```

Verified 2026-09-06: produces 1280×640, ~300 KB. macOS `qlmanage` is **not** a substitute — it
pads the image into a 1280×1280 square.

**Links in this repository cannot be made to open in a new tab.** GitHub sanitises rendered
markdown and strips the `target` attribute. Asked GitHub's own renderer on 2026-09-06:

```
in:  <a href="https://claude.com" target="_blank" rel="noopener noreferrer">Claude</a>
out: <a href="https://claude.com" rel="nofollow">Claude</a>
```

`target` is dropped and `rel` is replaced with `nofollow`. Do not spend time on it; readers use
cmd-click or middle-click. This is a platform limit, not an oversight.

## Style

Plain English, short sentences, no jargon without a one-line definition. Tables for comparisons, numbered steps for procedures. Mermaid diagrams live next to the text they explain — and avoid `#` inside sequence-diagram labels, because Mermaid reads it as an entity prefix and truncates the line. Write "issue 212".

**Never put `fill:` in a Mermaid diagram, and never use `%%{init: {'theme':...}}%%`.** GitHub picks
Mermaid's theme from the reader's colour mode — `theme: "dark" === data-color-mode ? "dark" : "default"`,
read out of its deployed bundle on 2026-09-07. A hard-coded fill is fixed paint in *both* modes, so
a light fill gets dark-mode's light text on top of it and becomes unreadable. `%%{init}%%` is worse:
`theme` is not in the config allowlist GitHub locks, so an author's directive **wins** and forces
one theme on every reader.

Colour-free Mermaid is theme-correct for free. Where a diagram needs meaning from colour, use
`stroke:` only — the outline is coloured, the node keeps the theme's own fill and text — or reach
for shapes, dashed edges and subgraphs instead. Sixteen `fill:` directives were removed on
2026-09-07 for exactly this reason.

**A diagram that must carry the argument belongs in `assets/` as a committed SVG, not in Mermaid.**
GitHub renders Mermaid client-side only; through the API, in mirrors, on npm and in email
notifications it is raw source text. Verified against GitHub's markdown API, which returns a
syntax-highlighted code block rather than a diagram.

---

## Reporting a bug

The most useful bug report here is one that names **what you ran and what you saw**, because that is the only kind this project can act on without re-deriving it.

Include: the command or the trigger, what you expected, what happened, and the run URL if there is one. If a workflow behaved oddly, `scripts/doctor.sh OWNER/REPO` output is usually the fastest thing to paste.

## Security

Don't open a public issue for a security problem. `docs/05-security.md` has the threat model and is honest about what this design does *not* protect against — prompt injection is reduced, not prevented, and anyone who can comment on a thread can put text in front of the coding agent.

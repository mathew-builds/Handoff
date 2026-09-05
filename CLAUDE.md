# CLAUDE.md — instructions for Claude Code working in THIS repository

This repo is the **grokbot-claude-bridge** project: a zero-server template that lets Grok Bot delegate all coding to Claude Code via GitHub. Read `README.md` first, then `docs/01-architecture.md`, then `TASKS.md`.

## What this repo is
- A **template** other people copy into their own repos. Keep everything generic; no personal tokens, repo names, or account names anywhere.
- Documentation-first. If a decision changes, update `docs/02-decisions.md` in the same PR.

## Ground rules
- Never commit secrets. `CLAUDE_CODE_OAUTH_TOKEN`, GitHub tokens and Grok Bot connector secrets live only in GitHub Secrets or the user's local machine.
- Keep `templates/claude.yml` aligned with the official `anthropics/claude-code-action@v1` inputs. Verify against https://code.claude.com/docs/en/github-actions before changing it.
- **Consumers need both workflows.** `claude.yml` does the work; `claude-open-pr.yml` opens the pull request, which the action cannot (D12). Any doc describing setup must mention both.
- **Do not claim a vendor behaviour you have not read in their docs or seen in a run.** Four claims in the original scaffold were confidently wrong. When you cannot verify, write "unverified" — it is an acceptable answer.
- Every workflow change must keep: `concurrency` group, a `timeout-minutes`, and `--max-turns` in `claude_args`.
- Prefer boring solutions. If a task can be done with a GitHub feature, do not add a service.
- Mermaid diagrams live in the docs next to the text they explain. Update the diagram when the flow changes.

## Working through TASKS.md
- Pick the first unchecked task in the current phase. Do not skip phases.
- Each task has an acceptance test. Do not mark done until it passes.
- One PR per task. Title: `phase-N: <task>`.

## Style
- Plain English, short sentences, no jargon without a one-line definition.
- Tables over prose for comparisons. Numbered steps for procedures.
- Dates on anything that can go stale (prices, limits, vendor behaviour).

## Verification commands

These are what CI runs. Every one exits non-zero on failure — **never add `|| true`**,
because a check that reports instead of failing reads as a pass (that was issue #36).

```bash
actionlint -ignore 'unexpected key "queue" for "concurrency" section' \
  .github/workflows/*.yml templates/*.yml   # lint workflows AND the templates
python3 scripts/check-links.py              # every relative doc link resolves
python3 scripts/check-workflow-caps.py      # the three cost brakes survive
```

Before trusting a new check, run it against **deliberately broken** input and confirm
it goes red. A check that has never failed has not been tested.

## Diagrams
Source of truth is the Mermaid in each doc; GitHub renders it natively, so there are
no checked-in PNG copies to keep in sync. Avoid `#` inside sequence-diagram labels —
Mermaid treats it as an entity prefix and truncates the text. Write "issue 212", not
"issue #212".

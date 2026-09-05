# CLAUDE.md — instructions for Claude Code working in THIS repository

This repo is the **grokbot-claude-bridge** project: a zero-server template that lets Grok Bot delegate all coding to Claude Code via GitHub. Read `README.md` first, then `docs/01-architecture.md`, then `TASKS.md`.

## What this repo is
- A **template** other people copy into their own repos. Keep everything generic; no personal tokens, repo names, or account names anywhere.
- Documentation-first. If a decision changes, update `docs/02-decisions.md` in the same PR.

## Ground rules
- Never commit secrets. `CLAUDE_CODE_OAUTH_TOKEN`, GitHub tokens and Grok Bot connector secrets live only in GitHub Secrets or the user's local machine.
- Keep `templates/claude.yml` aligned with the official `anthropics/claude-code-action@v1` inputs. Verify against https://code.claude.com/docs/en/github-actions before changing it.
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
```bash
# lint workflow files
actionlint .github/workflows/*.yml templates/claude.yml 2>/dev/null || echo "install actionlint"
# check mermaid blocks parse (optional)
npx -y @mermaid-js/mermaid-cli -i docs/01-architecture.md -o /tmp/out.md 2>/dev/null || true
# markdown links
npx -y markdown-link-check README.md docs/*.md 2>/dev/null || true
```

## Diagrams
Source of truth is the Mermaid in each doc. `docs/diagrams/*.png` are rendered copies for readers who can't render Mermaid; regenerate them when a diagram changes:
```bash
npx -y @mermaid-js/mermaid-cli -i docs/01-architecture.md -o docs/diagrams/01-architecture.md   # extracts + renders
```
Avoid `#` inside sequence-diagram labels — Mermaid treats it as an entity prefix and truncates the text. Write "issue 212", not "issue #212".

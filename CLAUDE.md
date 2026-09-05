# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This repo is the **grokbot-claude-bridge** project: a zero-server template that lets Grok Bot delegate all coding to Claude Code via GitHub. Read `README.md` first, then `docs/01-architecture.md`, then `TASKS.md`.

## What this repo is
- A **template** other people copy into their own repos. Keep everything generic; no personal tokens, repo names, or account names anywhere.
- Documentation-first. If a decision changes, update `docs/02-decisions.md` in the same PR.

## Architecture — two execution contexts, never confuse them

**Almost nothing in this repo runs in this repo.** `templates/` is the product: files a
consumer copies into *their* repo, where they do the actual work. That split is the one
thing you must hold in your head, because a change that is correct in one context is
often wrong in the other.

| Lives here | Runs where | Purpose |
|---|---|---|
| `.github/workflows/ci.yml` | **this** repo | Lints the templates, checks doc links and the cost brakes |
| `templates/claude.yml` | a **consumer's** repo | The product. Runs Claude on `@claude`, then opens the PR |
| `templates/CLAUDE.md.template` | a **consumer's** repo | Tells Claude how to work in *their* codebase |
| `templates/bots/*.md`, `templates/routines/*.md` | pasted into **Grok Bot** | Bot descriptions and routine text — prose, not code |
| `scripts/*` | your machine | Set up or diagnose a consumer repo |

**The end-to-end flow**, which takes three docs to reconstruct otherwise:

> issue containing `@claude` → `claude.yml` triggers → the action runs Claude → Claude
> edits, tests, and **pushes a branch** → a later step in **the same workflow** opens the
> pull request → the `pull_request` event reaches a Grok Bot routine → a human merges.

Two counter-intuitive facts in that chain, both learned the hard way and both load-bearing:
the action has **no tool to open a pull request**, and the PR step **cannot** be split into
a separate `on: push` workflow (see Ground rules).

**`docs/02-decisions.md` is the load-bearing document.** Every non-obvious choice is there
with what it beat and what would reverse it, including corrections where we were wrong.
Read the relevant entry before changing behaviour — several decisions look arbitrary until
you see the constraint behind them.

## Ground rules
- Never commit secrets. `CLAUDE_CODE_OAUTH_TOKEN`, GitHub tokens and Grok Bot connector secrets live only in GitHub Secrets or the user's local machine.
- Keep `templates/claude.yml` aligned with the official `anthropics/claude-code-action@v1` inputs. Verify against https://code.claude.com/docs/en/github-actions before changing it.
- **`claude.yml` both runs Claude and opens the pull request.** The action cannot open one itself (D12). Do not split the PR step into a separate `on: push` workflow — `actions/checkout` persists the workflow `GITHUB_TOKEN`, so Claude's push never triggers one. We shipped that bug; see #61.
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

## Commands

There is no build and no test suite — the deliverable is text. These three are what CI
runs, and running them locally reproduces CI exactly. Each exits non-zero on failure;
**never add `|| true`**, because a check that reports instead of failing reads as a pass
(that was issue #36).

```bash
pip install pyyaml    # once — check-workflow-caps.py needs it

actionlint -ignore 'unexpected key "queue" for "concurrency" section' \
  .github/workflows/*.yml templates/*.yml   # lint workflows AND the templates
python3 scripts/check-links.py              # every relative doc link resolves
python3 scripts/check-workflow-caps.py      # the three cost brakes survive
```

Run any one on its own — they are independent. The `-ignore` flag is dated and
justified in `ci.yml`; drop it once actionlint learns the `queue` key.

**Operator scripts**, run against a consumer repo rather than this one:

```bash
# from inside the consumer repo — BRIDGE_DIR is derived from the script's own path
bash ~/grokbot-claude-bridge/scripts/setup.sh

# from anywhere; both flags optional
scripts/doctor.sh OWNER/REPO --machine-account LOGIN --token   # --token reads $BOT_TOKEN
```

`doctor.sh` is the first thing to run when a consumer repo misbehaves. It reports what is
missing *and* the command or click that fixes it, and it is explicit about the one thing it
cannot check (whether the Claude GitHub App is installed).

Before trusting a new check, run it against **deliberately broken** input and confirm it
goes red. A check that has never failed has not been tested — that is how issue #61 shipped.

## Diagrams
Source of truth is the Mermaid in each doc; GitHub renders it natively, so there are
no checked-in PNG copies to keep in sync. Avoid `#` inside sequence-diagram labels —
Mermaid treats it as an entity prefix and truncates the text. Write "issue 212", not
"issue #212".

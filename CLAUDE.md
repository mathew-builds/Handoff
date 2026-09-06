# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This repo is **Handoff**: a zero-server template that lets a chat agent delegate coding to a subscription-billed coding agent, over GitHub. Grok Bot → Claude Code is the first supported pair, not the only intended one — keep naming vendor-neutral where you can. Read `README.md` first, then `docs/01-architecture.md`, then `TASKS.md`.

> **If you were pointed here to *install* Handoff into someone's repository, you are in the wrong file.** Read `AGENTS.md` instead. This file is about developing Handoff itself; `AGENTS.md` is about installing it. Confusing the two wastes a run.

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
| `templates/weekly-cost.yml` | a **consumer's** repo | Optional. Weekly cost report. Uses **no model turns** — `gh` and `awk`, not an agent |
| `templates/bots/*.md`, `templates/routines/*.md` | pasted into **Grok Bot** | Bot descriptions and routine text — prose, not code |
| `scripts/*` | your machine | Set up or diagnose a consumer repo |
| `AGENTS.md` | read by an **agent** installing Handoff | The install guide for the "hand your agent the URL" path. Organised around the three steps an agent *cannot* do |
| `CONTRIBUTING.md` | read by a **contributor** | Conventions, and why. Leads with: a claim is true only if something ran to produce it |
| `CHANGELOG.md` | read by an **adopter** | Release history, with an explicit "what is *not* proven" section |
| `assets/*.svg` | rendered on **GitHub** | Banner and social card. Hand-authored SVG, not generated — editable, diffable, owned outright |

**The end-to-end flow**, which takes three docs to reconstruct otherwise:

> issue containing `@claude` → `claude.yml` triggers → the action runs Claude → Claude
> edits, tests, and **pushes a branch** → a later step in **the same workflow** opens the
> pull request → the `pull_request` event reaches a Grok Bot routine → a human merges.

**The whole chain has been observed working** (2026-09-06, `docs/07-evidence.md`). Two
counter-intuitive facts in it, both learned the hard way and both load-bearing: the action has
**no tool to open a pull request**, and the PR step **cannot** be split into a separate
`on: push` workflow (see Ground rules).

The last hop has a caveat worth carrying: the routine was verified on Grok Bot's **built-in
GitHub connection**, and it reported without an approval tap. The **inbound-webhook** trigger
is untested, and it is the one Cursor staff flagged as not counting as user intent. Do not
generalise the result to it.

**`docs/02-decisions.md` is the load-bearing document.** Every non-obvious choice is there
with what it beat and what would reverse it, including corrections where we were wrong.
Read the relevant entry before changing behaviour — several decisions look arbitrary until
you see the constraint behind them.

## Ground rules
- Never commit secrets. `CLAUDE_CODE_OAUTH_TOKEN`, GitHub tokens and Grok Bot connector secrets live only in GitHub Secrets or the user's local machine.
- Keep `templates/claude.yml` aligned with the official `anthropics/claude-code-action@v1` inputs. Verify against https://code.claude.com/docs/en/github-actions before changing it.
- **`claude.yml` both runs Claude and opens the pull request.** The action cannot open one itself (D12). Do not split the PR step into a separate `on: push` workflow — `actions/checkout` persists the workflow `GITHUB_TOKEN`, so Claude's push never triggers one. We shipped that bug; see #61.
- **Do not claim a vendor behaviour you have not read in their docs or seen in a run.** Four load-bearing claims in the original scaffold were confidently wrong; one of them appeared in seventeen places before anyone checked. See the **Correction** entries in `docs/02-decisions.md`. When you cannot verify, write "unverified" — it is an acceptable answer.
- Every workflow change must keep: `concurrency` group, a `timeout-minutes`, and `--max-turns` in `claude_args`.
- Prefer boring solutions. If a task can be done with a GitHub feature, do not add a service.
- Mermaid diagrams live in the docs next to the text they explain. Update the diagram when the flow changes.

## Working through TASKS.md
- Each task has an acceptance test. **Do not tick it until that test has passed**, and record
  in the task what was verified and what was not. Several ticked tasks carry a "not covered"
  note; keep doing that.
- **Phases were meant to run in order, and no longer do.** Phase 2 measures operating Handoff
  over two weeks of real use; its target repo was dropped on 2026-09-06, so it is **parked**
  and the work moved to Phase 3. Each Phase 2 issue says so. It becomes actionable the moment
  a real repository is chosen — do not treat it as abandoned, and do not restart it without one.
- **One PR per change**, titled by what changed (`fix:`, `docs:`, `feat:`). The old
  `phase-N: <task>` convention is dead; nothing has used it since Phase 1.

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
# from inside the consumer repo — HANDOFF_DIR is derived from the script's own path
bash ~/handoff/scripts/setup.sh

# from anywhere; both flags optional
scripts/doctor.sh OWNER/REPO --machine-account LOGIN --token   # --token reads $BOT_TOKEN
```

`doctor.sh` is the first thing to run when a consumer repo misbehaves. It reports what is
missing *and* the command or click that fixes it, and it is explicit about the one thing it
cannot check (whether the Claude GitHub App is installed).

Before trusting a new check, run it against **deliberately broken** input and confirm it
goes red. A check that has never failed has not been tested — that is how issue #61 shipped.
This is not theoretical: a `doctor.sh` check added on 2026-09-06 could not fail, because its
`grep` matched the template's own comments. Found only by commenting a brake out and watching
it pass.

**`actionlint` does not check shell inside a `run:` block.** A heredoc in
`templates/weekly-cost.yml` broke on an apostrophe in the prose and linted clean. If you touch
shell in a workflow, extract it and check it:

```bash
python3 -c "import yaml;d=yaml.safe_load(open('templates/weekly-cost.yml'));print(d['jobs']['report']['steps'][0]['run'])" > /tmp/s.sh
bash -n /tmp/s.sh
```

## Diagrams
Source of truth is the Mermaid in each doc; GitHub renders it natively, so there are
no checked-in PNG copies to keep in sync. Avoid `#` inside sequence-diagram labels —
Mermaid treats it as an entity prefix and truncates the text. Write "issue 212", not
"issue #212".

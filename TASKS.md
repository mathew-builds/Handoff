# TASKS.md — the backlog Claude Code works through

Rules: one task per PR, in order, phases in order. Each task has an acceptance test; don't tick it until the test passes. Anything that touches a vendor behaviour gets a date in the doc it changes.

## Phase 0 — Prove the thesis

- [ ] **0.1 Validate `templates/claude.yml` against the official docs.** Confirm every input name exists on `anthropics/claude-code-action@v1` (`claude_code_oauth_token`, `claude_args`), that the `if:` expression is correct for each event type, and that `--allowedTools` syntax matches current Claude Code. *Accept:* `actionlint` passes; a note in `02-decisions.md` D10 records the verified date.
- [ ] **0.2 Run Step 1–2 of the setup guide on a real private repo.** *Accept:* a PR opened by the Claude app from an `@claude` issue; Anthropic Console shows no API spend; screenshot or run URL recorded in `docs/07-evidence.md` under a new "Our runs" heading.
- [ ] **0.3 Measure one run.** Wall-clock, turns used, Claude usage delta, Actions minutes. *Accept:* a row in a new `docs/08-measurements.md` table.

## Phase 1 — The bridge

- [ ] **1.1 Machine account + scoped token** per setup Step 3. *Accept:* the token can open an issue on the target repo and is rejected on any other repo (`curl` checks recorded).
- [ ] **1.2 Verify the trigger path from the machine account.** *Accept:* issue by the bot account → action runs (write-access check passes) → PR.
- [ ] **1.3 Coder bot** from `templates/bots/coder.md`, token via secure request. *Accept:* Coder opens a well-formed issue from a one-line ask; `/workspace` on its computer shows no code edits.
- [ ] **1.4 Investigate Grok Bot's native GitHub connector.** Can it open issues under an identity you control without a stored token? *Accept:* a paragraph in `02-decisions.md` D5 with a dated finding; if yes, update the Coder template with the preferred path.
- [ ] **1.5 PR-ready routine** from `templates/routines/pr-ready.md`. *Accept:* a hand-opened PR is reported in the channel within a few minutes.
- [ ] **1.6 Runbook R1–R7 dry run.** Deliberately trigger three of them (read-only account comment, cancel a run, expired token) and record what actually happened. *Accept:* `04-operations.md` runbooks corrected where reality differed.

## Phase 2 — The team

- [ ] **2.1 Chief of Staff** from template; pinned; one project channel. *Accept:* a two-step task with no routing hints is researched, delegated to Coder, and reported once.
- [ ] **2.2 Auto Review rules** from `templates/auto-review-rules.md`; Cursor on-demand limit set. *Accept:* "email the client" is stopped and asks; a screenshot in evidence.
- [ ] **2.3 Consumer `CLAUDE.md` tuned** for the target repo (tests command, never-touch paths). *Accept:* five real tasks merged; rejection rate recorded.
- [ ] **2.4 Meter check.** Track Grok Bot weekly % on Mon/Wed/Fri for two weeks with coordination-only work. *Accept:* table in `08-measurements.md`; under 50% by Wednesday, or a note on what drained it.
- [ ] **2.5 Brief quality loop.** For every rejected PR, write one line: what was wrong with the *brief*. Fold fixes into the Coder template. *Accept:* rejection rate trending down across two weeks.

## Phase 3 — Polish and publish

- [ ] **3.1 `scripts/setup.sh` end to end** on a fresh repo. *Accept:* Step 1 completes with no manual edits except CLAUDE.md placeholders.
- [ ] **3.2 `scripts/doctor.sh`.** Checks: secret present, workflow on default branch, Claude app installed, machine account has write, token expiry date. *Accept:* fails loudly on each missing item when tested.
- [ ] **3.3 Weekly cost report.** A second workflow in agent mode on a Monday schedule: reads last week's PRs and Actions minutes, posts a cost-per-merged-PR comment on a pinned issue. *Accept:* one real report posted.
- [ ] **3.4 Fresh-eyes setup test.** A new Claude Code session with only the README completes setup on a new repo. *Accept:* every point of confusion becomes a doc fix.
- [ ] **3.5 `CONTRIBUTING.md`, `CHANGELOG.md`, tag `v1.0.0`.** *Accept:* release published; README badges; `07-evidence.md` dated.

## Parked (do not start without a trigger from `06-roadmap.md`)

- Agent-mode maintenance workflow ("every Monday, update deps")
- Discord channel as second inbox
- Cross-model review step on PRs
- v3 server design (firstmate, channels, relay, two-node split)

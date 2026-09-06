# TASKS.md — the backlog Claude Code works through

Rules: one task per PR, in order, phases in order. Each task has an acceptance test; don't tick it until the test passes. Anything that touches a vendor behaviour gets a date in the doc it changes.

## Phase 0 — Prove the thesis

- [ ] **0.1 Validate `templates/claude.yml` against the official docs.** Confirm every input name exists on `anthropics/claude-code-action@v1` (`claude_code_oauth_token`, `claude_args`), that the `if:` expression is correct for each event type, and that `--allowedTools` syntax matches current Claude Code. *Accept:* `actionlint` passes; a note in `02-decisions.md` D10 records the verified date. **Partially done:** `actionlint` passes, and D10 now carries a dated, sourced verification — but only of the `concurrency` block. The action's own inputs (`claude_code_oauth_token`, `claude_args`, `--allowedTools` syntax) and the `if:` expression per event type have **not** been re-checked against the live docs. Stays unticked until they are.
- [x] **0.2 Run Step 1–2 of the setup guide on a real private repo.** *Accept:* a pull request exists from an `@claude` issue — opened by `github-actions` via the PR step in `claude.yml`, **not** by the Claude app, which has no such tool (#41); Anthropic Console shows no API spend; run URL recorded in `docs/07-evidence.md` under "Our runs". **Done 2026-09-05: $0.00 API spend.**
- [x] **0.3 Measure one run.** Wall-clock, turns used, Actions time. *Accept:* a row in `docs/08-measurements.md`. **Done 2026-09-05.** Actions cost is recorded as wall-clock, not money — GitHub's timing API reports `billable_ms: 0` on this repo and we do not publish figures we cannot substantiate.

## Phase 1 — The bridge

- [ ] **1.1 A scoped token the bot can use.** Start with a fine-grained token on **your own** account, `Issues: read and write`, one repo — see D5a. A machine account is an upgrade for attribution, not a prerequisite, and it needs an org-owned repo (#46). *Accept:* the token can open an issue on the target repo and is rejected on any other; both `curl` commands and their responses pasted into `docs/07-evidence.md` under "Our runs".
- [x] **1.2 Verify the trigger path from the account behind the token.** *Accept:* issue by that account → action runs (write-access check passes) → PR opened by `github-actions` from the step in `claude.yml`. Under D5a that account is your own, not a machine account. **Done 2026-09-05, evidenced 2026-09-06:** issues 5 and 6 on the trial repo return `login=mathew-builds`, `type=User`, `performed_via_github_app=none`; run 33983515065 succeeded; PR #7 opened. See `07-evidence.md`.
- [ ] **1.3 Coder bot** from `templates/bots/coder.md`. No token hand-off needed — it reaches GitHub through the connector configured in 1.1. *Accept:* Coder opens a well-formed issue from a one-line ask; `/workspace` on its computer shows no code edits.
- [ ] **1.4 Investigate Grok Bot's native GitHub connector.** Can it open issues under an identity you control without a stored token? *Accept:* a paragraph in `02-decisions.md` D5 with a dated finding; if yes, update the Coder template with the preferred path.
- [ ] **1.5 PR-ready routine** from `templates/routines/pr-ready.md`. *Accept:* **both passes** reported in the group chat within a few minutes — pass 1 a hand-opened PR, pass 2 a PR opened by `github-actions` through the bridge. Pass 1 alone does not count: it exercises a different actor from every real PR, which is the invalid control that let #61 ship twice.
- [ ] **1.6 Runbook R1–R7 dry run.** Deliberately trigger three of them (read-only account comment, cancel a run, expired token). *Accept:* for each, a line in `docs/07-evidence.md` giving the run URL and **what you actually saw**, then `04-operations.md` corrected where reality differed. R1, R2 and R3 have already been corrected from documentation — this is the execution check.

## Phase 2 — The team

- [ ] **2.1 Chief of Staff** from template; pinned; one project group chat. *Accept:* a two-step task with no routing hints is researched, delegated to Coder, and reported once.
- [ ] **2.2 Auto Review rules** from `templates/auto-review-rules.md`; Cursor on-demand limit set. *Accept:* "email the client" is stopped and asks; a screenshot in evidence.
- [ ] **2.3 Consumer `CLAUDE.md` tuned** for the target repo (tests command, never-touch paths). *Accept:* five real tasks merged; a `merged / rejected` row per task added to the table in `docs/08-measurements.md`.
- [ ] **2.4 Meter check.** Track Grok Bot weekly % on Mon/Wed/Fri for two weeks with coordination-only work. *Accept:* table in `08-measurements.md`; under 50% by Wednesday, or a note on what drained it.
- [ ] **2.5 Brief quality loop.** For every rejected PR, one line in `docs/08-measurements.md`: what was wrong with the *brief*. Fold fixes into the Coder template. *Accept:* week-two rejection rate lower than week-one, both computed from that table.

## Phase 3 — Polish and publish

- [ ] **3.1 `scripts/setup.sh` end to end** on a fresh repo. *Accept:* Step 1 completes with no manual edits except CLAUDE.md placeholders.
- [x] **3.2 `scripts/doctor.sh`.** Checks: secret present, `claude.yml` on the default branch (there is only one workflow — D12), the "Allow GitHub Actions to create and approve pull requests" setting enabled (#46 — off by default and easy to miss), Claude app installed, the token's account has write, token expiry date. *Accept:* exits non-zero on each missing item, demonstrated by removing each one in turn. **Done 2026-09-05 (PR #58), re-verified 2026-09-06:** exit 0 on the wired trial repo; exit 1 on an unwired repo with three real failures and their remedies. Built during Phase 1 rather than Phase 3 — an out-of-order exception, taken because it was needed to debug Phase 1.
- [ ] **3.3 Weekly cost report.** A second workflow in agent mode on a Monday schedule: reads last week's PRs and Actions minutes, posts a cost-per-merged-PR comment on a pinned issue. *Accept:* one real report posted.
- [ ] **3.4 Fresh-eyes setup test.** A new Claude Code session with only the README completes setup on a new repo. *Accept:* every point of confusion becomes a doc fix.
- [ ] **3.5 `CONTRIBUTING.md`, `CHANGELOG.md`, tag `v1.0.0`.** *Accept:* release published; README badges; `07-evidence.md` dated.

## Parked (do not start without a trigger from `06-roadmap.md`)

- Agent-mode maintenance workflow ("every Monday, update deps")
- Discord channel as second inbox
- Cross-model review step on PRs
- v3 server design (firstmate, channels, relay, two-node split)

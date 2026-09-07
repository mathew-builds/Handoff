# 06 — Roadmap

| Phase | Goal | Status | Still unticked |
|---|---|---|---|
| **0 · Prove** | A pull request billed to a subscription, triggered by an issue | **Done** — 2026-09-05 | — |
| **1 · Bridge** | A chat agent opens the issue; the finished PR reports itself back | **In progress** — 3 of 6 | 1.1 token scope · 1.4 native connector · 1.6 runbook rehearsal |
| **2 · Team** | You talk only to the Chief of Staff | **Parked** since 2026-09-06 | All five. Needs a real repository — the target was dropped. |
| **3 · Publish** | Someone else can set this up from the README | **In progress** — 3 of 5 | 3.4 fresh-eyes install · 3.5 the `v1.0.0` tag |

**Phase 2 is parked and Phase 3 was brought forward.** This was a Gantt chart until 2026-09-07.
It was removed rather than corrected: every real event happened inside 48 hours, so four bars on a
two-day axis conveyed nothing while implying a schedule that does not exist — and Gantt has no way
to draw "parked", so Phase 2 rendered in the same red normally reserved for *urgent*. A table can
say "parked", carries the unticked tasks the chart could not, and has no dates to be wrong about.

## Phase 0 — Prove the thesis (weekend)

Goal: a PR billed to Claude Max, triggered by an issue, with no Grok Bot involved.

**Acceptance:** a pull request exists from an `@claude` issue — opened by `github-actions` via the PR step inside `claude.yml`, **not** by the Claude app, which has no such tool; zero API spend in the Anthropic Console.

**Result, 2026-09-05: passed.** $0.00 metered spend, 63s, 10 of 25 turns. See `07-evidence.md`.

**Kill criterion:** the OAuth path won't work on your account after two attempts and the upstream issue has no fix. Then the project's economics change — pause and reassess (API billing may still beat Grok Bot overage, but measure it).

## Phase 1 — The bridge (week 1)

Goal: a Grok Bot Coder can open the issue; the Chief of Staff hears about the PR.

**Acceptance:**
- Issue authored by the token's owner → action runs → PR → routine reports in the group chat. (D5a: a separate machine account is an attribution upgrade, not a prerequisite.)
- Grok Bot meter moves by a handful of turns per task.
- Coder has never edited a file (check its computer's `/workspace`).

**Result, 2026-09-06: partly passed.** Criteria one and three are evidenced — issue → action → PR →
routine report, both passes, and `/workspace` checked clean (`07-evidence.md`, tasks 1.2, 1.3, 1.5).
**Criterion two is not met:** the Grok Bot meter has never been read, and `08-measurements.md`
records it as "not yet measured". Tasks 1.1, 1.4 and 1.6 remain unticked. **Phase 1 is not complete.**

## Phase 2 — The team (week 2) — **PARKED since 2026-09-06**

Goal: you talk only to the Chief of Staff.

**Parked, not abandoned.** Every acceptance test below needs two weeks of real use on a real repository, and the target repository was dropped on 2026-09-06. Phase 3 was brought forward. The trigger to unpark is a chosen repository — nothing else.

**Acceptance:**
- Two-step task with no routing hints is researched, delegated, reported once.
- Auto Review stops an email/spend/post/production action and asks you.
- Weekly Grok Bot allowance under 50% by Wednesday on coordination-only work.
- Five real tasks merged. Rejection rate under 30%.

## Phase 3 — Polish and publish (week 3)

Goal: someone else can set this up from the README in under two hours.

**Acceptance:**
- `scripts/setup.sh` does Step 1 of the setup guide end to end.
- A weekly scheduled run posts cost-per-merged-PR as an issue comment.
- `scripts/doctor.sh` exits non-zero on each missing prerequisite (task 3.2).
- A stranger (or a fresh Claude Code session with only the README) completes setup on a new repo.
- Tagged `v1.0.0`, MIT licence, `CONTRIBUTING.md`.

**Result, 2026-09-06: partly passed.** `setup.sh`, `doctor.sh` and the weekly cost report are done
and evidenced (tasks 3.1–3.3). **Not done:** nobody outside the project has installed Handoff from
the README (3.4), and `v1.0.0` is not yet tagged (3.5). The ownership question that held the tag
was settled on 2026-09-07 — the repository stays on its personal account — so the tag is now
waiting only on the decision to publish.

## What would make us add a server (the parked v3 design)

Only these triggers. Not "it would be nice."

| Trigger | What comes back |
|---|---|
| Tasks need memory across runs (multi-day features, a crew) | firstmate on a VPS; Claude Code Channels for push-in; permission relay |
| Tasks touch private infrastructure the hosted runner can't reach | self-hosted runner on a VPS behind Tailscale |
| A client wants the whole stack self-hosted | Gitea + Woodpecker, two-node brain/hands split, OTel + Grafana |
| Grok Bot ships a model picker, published allowances and a spend cap | possibly *less* — reconsider whether the bridge is needed at all |

The full v3 design (two Hetzner nodes, gateway, channels, relay, the eleven-gap scoreboard) is preserved as the answer to those triggers. It is not the plan.

## Ideas backlog (unscheduled)

- Second workflow in **agent mode** for scheduled maintenance ("every Monday: update dependencies, run tests, open PR").
- Discord as a second inbox via the official Claude Code Discord channel — a fallback if Grok Bot is down.
- Cross-model review: a read-only Grok review step on Claude's PRs, for a second opinion from a model with different blind spots.
- Cost report as a GitHub Pages dashboard, no server.

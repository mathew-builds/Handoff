# 08 — Measurements

Numbers we produced by running the thing. Every row links to the run it came from. Nothing here is estimated; where a figure is unavailable it says so rather than being filled in.

## Runs on the trial repo, 2026-09-05

Repo: the trial repo (private).

| Run | Trigger | Wall clock | Claude turns | Outcome |
|---|---|---:|---:|---|
| `33961149264` | issue opened, `@claude` in body | **63s** | **10 / 25** | `CONTRIBUTING.md` written, `npm test` 3/3 green, branch pushed |
| `33961161338` | issue comment | 47s | 0 | Skipped by the `if:` gate — no runner work, no spend |
| `33971250162` | issue assigned | 16s | **0** | `No trigger found` — runner minutes only, never subscription usage |
| `33970850969` | push to `claude/**` — **trigger since deleted** | 12s | 0 | Failed, then passed on re-run once the repo setting was enabled |
| `33974291123` | push to `claude/**` — **trigger since deleted** | 12s | 0 | Opened PR 3. **This run does not prove the shipped design** — the push came from a laptop, and the workflow it exercised never fired for Claude. See D12 and #61. |
| `33983515065` | issue opened, `@claude` in body | **64s** | **10 / 25** | **The run that proves the shipped design.** `docs/GOODBYE.md` written, branch pushed by `claude[bot]`, then the in-workflow step opened PR 7. No human push anywhere in the chain. |

## Runs on the trial repo, 2026-09-06

| Run | Trigger | Wall clock | Claude turns | Outcome |
|---|---|---:|---:|---|
| `34023564889` | issue opened by the **Coder bot**, `@claude` in body | **62s** | **9 / 25** | **First run with Grok Bot in the loop.** `docs/HELLO.md` added (`+1/-0`), branch pushed by `claude[bot]`, PR 9 opened by the in-workflow step. **61s from issue to pull request.** |

| `34025508553` | issue opened by the **Coder bot**, `@claude` in body | **67s** | **11 / 25** | Step 5 pass 2. `docs/GOODBYE-2.md` added (`+1/-0`), PR 12 opened by the workflow — **and reported back into the group chat unattended.** 66s issue to pull request. |

Turn counts so far, same shape of task each time: **10** briefed by hand, **9** and **11** briefed by the Coder bot. Three data points, no trend — recorded because a reader will otherwise read meaning into the difference.

**Not measured:** how long either step-5 report took to arrive. Both did, and neither needed approval; the delay was not timed and the account owner may have had the app open. Recorded as unmeasured rather than estimated.

## Notes on the older rows

The last two `push to claude/**` rows are kept deliberately. That trigger lived in `templates/claude-open-pr.yml`, which PR #62 deleted because **it never fired for Claude** — those runs passed only because a human pushed. They are here as the record of an invalid control, not as evidence. See D12.

## Cost of one complete task

One issue in, one reviewable pull request out:

| Meter | Measured | Notes |
|---|---|---|
| **Claude Max** | 10 turns, 63s | Well inside `--max-turns 25`. The cap is not the binding constraint on a task this size. |
| **Anthropic API (pay-as-you-go)** | **$0.00** | Confirmed on the [Console usage page](https://platform.claude.com/usage), 2026-09-05. This is the number the project exists to keep at zero. |
| **GitHub Actions** | 64s wall clock, one run | Measured on run `33983515065`, where a single run does the work *and* opens the pull request. The earlier 63s + 12s figure was for the two-workflow design that no longer exists. The Actions timing API reported `billable_ms: 0` for every run on this repo. Reported as-is rather than converted into a minutes figure we cannot substantiate. |
| **Grok Bot** | not yet measured | Nothing has gone through Grok Bot. Phase 1. |

### Where these numbers come from

Turn counts are the `num_turns` field in the action's `"type": "result"` block, read out of the run log with `gh run view <id> --log`. Wall clock is `run_started_at` → `updated_at` from the runs API, so it includes queue time. Step timings come from the jobs API. On run 33983515065 the split was: Claude 53s, the pull-request step **2s**.

### What a task costs in turns

10 turns for: read the issue, read `CLAUDE.md`, read `package.json` and the test directory, write one file, run the tests, commit, push, report. That is the floor for a trivial task, and it is the only data point we have. Do not extrapolate from it — a real task with a failing test and two iterations will look nothing like this.

## Ignore the dollar figure in the run log

The log prints `total_cost_usd: 0.157`. It is **not** a charge:

> The Session block in `/usage` shows API token usage and is intended for API users. Claude Max and Pro subscribers have usage included in their subscription, so the session cost figure isn't relevant for billing purposes.
> — <https://code.claude.com/docs/en/costs>

It is a notional list-price estimate, printed regardless of how you pay. The Console usage page is the authority, and it showed zero.

## Not measured yet

- **Grok Bot weekly allowance** under coordination-only load (task 2.4). Needs Phase 1 and 2 first, and two weeks of elapsed time.
- **Cost per merged PR** (`04-operations.md`, weekly review). Needs several real tasks, not one trivial one.
- **A task that fails.** Every measurement here is of a task that went right the first time. The interesting number is what a *rejected* PR costs, and we have none.
- **Actions minutes in money.** The timing API reports zero billable milliseconds on this repo; whether that is a free-tier allowance or an unpopulated field is unresolved.

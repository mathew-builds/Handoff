# 08 — Measurements

Numbers we produced by running the thing. Every row links to the run it came from. Nothing here is estimated; where a figure is unavailable it says so rather than being filled in.

## Runs on the trial repo, 2026-09-05

Repo: `mathew-builds/claude-bridge-trial` (private).

| Run | Trigger | Wall clock | Claude turns | Outcome |
|---|---|---:|---:|---|
| [33961149264](https://github.com/mathew-builds/claude-bridge-trial/actions/runs/33961149264) | issue opened, `@claude` in body | **63s** | **10 / 25** | `CONTRIBUTING.md` written, `npm test` 3/3 green, branch pushed |
| [33961161338](https://github.com/mathew-builds/claude-bridge-trial/actions/runs/33961161338) | issue comment | 47s | 0 | Skipped by the `if:` gate — no runner work, no spend |
| [33971250162](https://github.com/mathew-builds/claude-bridge-trial/actions/runs/33971250162) | issue assigned | 16s | **0** | `No trigger found` — runner minutes only, never subscription usage |
| [33970850969](https://github.com/mathew-builds/claude-bridge-trial/actions/runs/33970850969) | push to `claude/**` | 12s | 0 | Failed, then passed on re-run once the repo setting was enabled |
| [33974291123](https://github.com/mathew-builds/claude-bridge-trial/actions/runs/33974291123) | push to `claude/**` | 12s | 0 | Opened [PR #3](https://github.com/mathew-builds/claude-bridge-trial/pull/3) with the correct title |

## Cost of one complete task

One issue in, one reviewable pull request out:

| Meter | Measured | Notes |
|---|---|---|
| **Claude Max** | 10 turns, 63s | Well inside `--max-turns 25`. The cap is not the binding constraint on a task this size. |
| **Anthropic API (pay-as-you-go)** | **$0.00** | Confirmed on the [Console usage page](https://platform.claude.com/usage), 2026-09-05. This is the number the project exists to keep at zero. |
| **GitHub Actions** | 75s wall clock across two runs (63s + 12s) | The Actions timing API reported `billable_ms: 0` for every run on this repo. Reported as-is rather than converted into a minutes figure we cannot substantiate. |
| **Grok Bot** | not yet measured | Nothing has gone through Grok Bot. Phase 1. |

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

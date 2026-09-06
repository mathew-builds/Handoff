# 04 — Operations

## The three meters

| Meter | What burns it | Where to look | Brake |
|---|---|---|---|
| **Grok Bot weekly allowance** | Chief of Staff turns, Coder writing issues, routines, bot-to-bot chat, browser sessions | **Settings → Usage & Billing** in the app (rollout-dependent — *"for eligible accounts"*), otherwise <https://cursor.com/dashboard/usage> | Turn caps in **bot descriptions**; hourly routines not quarter-hourly; on-demand limit `$0` |
| **Claude Max** | Every action run; longer tasks and more turns cost more | Claude usage page; `/usage` in Claude Code | `--max-turns`, `timeout-minutes`, `concurrency` in the workflow |
| **GitHub Actions minutes** | Runner time per task | Repo → Settings → Billing | Same three workflow caps |

Rule of thumb from the research (Sep 2026): a chief-of-staff-only Grok Bot fleet should sit well under 50% of the weekly allowance by mid-week. If it doesn't, the drain is coordination chatter, not coding — fix the bot descriptions, not the bridge.

**There is still no Grok Bot-specific spend cap.** Once the weekly pool is exhausted, usage continues on the account's shared on-demand spend, and the dashboard *does not currently split Grok Bot usage from Cursor usage*. Your only brake is the account-wide on-demand limit.

## Daily (2 minutes)

- Grok Bot usage % — trending, not spiking?
- Claude usage — inside the rolling window?
- Open PRs from Claude — anything waiting on you?

## Weekly (10 minutes)

- Count: tasks delegated, PRs merged, PRs rejected. Rejection rate above ~30% means briefs are bad — fix `CLAUDE.md` or the Coder template, not the model.
- Cost per merged PR ≈ (Grok Bot turns × your effective rate) + (Max share) + (minutes). Write it down. This is the number that justifies the project.
- Rotate anything expiring within 30 days (see below).

## Expiry calendar

| Thing | Expires | Renew with |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | ~1 year | `claude setup-token` → `gh secret set` |
| Bot's fine-grained GitHub token | 90 days (your choice) | GitHub UI → paste into the **GitHub connector's** secure credential field (Settings → Plugins), not into a bot |
| Grok Bot routines after long inactivity | may auto-pause | Open the routine, re-enable |

## Check the wiring before you debug anything

```bash
scripts/doctor.sh OWNER/REPO --machine-account BOT-LOGIN --token   # $BOT_TOKEN set
```

Exits non-zero if anything required is missing, and prints the exact command or click that fixes it. Run this first when something stops working — most of what it checks is invisible until it breaks, and two of them (the workflows being on the default branch, and Actions being allowed to open pull requests) cost us an hour each to discover the hard way.

It cannot confirm the Claude GitHub App is installed — no API exposes that without the app's own credentials — so it tells you to check that one by eye rather than pretending.

## Failure modes and runbooks

> **How much of this has been watched happening, as of 2026-09-06.** These entries are not all the
> same kind of claim, and the difference matters when you are debugging at speed.
>
> | Entry | Basis |
> |---|---|
> | R1 "no run at all" — workflow not on the default branch | **Observed.** Cost us an hour; it is why `doctor.sh` checks it. |
> | R1 read-only account fails rather than being ignored | Read in the action's source and docs. **The deliberate trigger is task 1.6 and has not been run.** |
> | R2 expired credentials | Upstream issue reports, not our run. **Not reproduced here.** |
> | R3 both halves | **Observed.** Shipped as issue 61 and corrected after watching it. |
> | R4 allowance exhaustion | Vendor staff statement. Our own meter has **never been read** — see `08-measurements.md`. |
> | R5, R6 | **Neither has happened to us.** Written from the vendor's behaviour as documented. |
> | R7 runaway action | `gh run cancel` is standard; the *runaway* it responds to has never occurred here. |
>
> Task 1.6 exists to execute three of these deliberately and correct whatever reality disagrees
> with. Until it is ticked, treat the unobserved rows as the best available expectation rather
> than as fact.

### R1 — Action doesn't start

Two different causes with two different symptoms. Check which one you have **first**, or you will hunt the wrong thing:

| Symptom in the Actions tab | Cause |
|---|---|
| Run **skipped** | The text has no `@claude`, so the job's `if:` was false. Check it is `@claude` as a whole word, not `/claude` or `@claude-bot`. |
| Run **failed**, red X | The triggering account lacks **write** access, or is a bot. The action fails the run rather than ignoring it: *"the run fails when either check rejects it"* (<https://code.claude.com/docs/en/github-actions> §"Who can trigger runs", read 2026-09-06). |
| **No run at all** | The workflow is not on the **default branch**. Issue events only trigger workflows from there. |

Read-only accounts are **not** silently ignored — that used to be written here and it is wrong. You get a failed run and a red mark on the thread.

### R2 — "Could not resolve authentication credentials"
- Regenerate: `claude setup-token`, update the secret, re-run.
- **Do not stop debugging if you never changed plans.** This was written as a Pro→Max upgrade issue. Upstream (`anthropics/claude-code-action#1281`, still open as of 2026-08-19) includes reports from accounts that were **never on Pro**, so the trigger is broader than an upgrade.
- Temporary fallback: `anthropic_api_key` with a Console key. **This moves your CI off the subscription and onto metered spend** — the exact thing this project exists to avoid. Treat it as a stopgap and switch back.

### R3 — CI doesn't run on Claude's work

Check which half is failing before changing anything.

- **Claude's own commits do trigger CI.** The template deliberately does *not* pass `github_token`, so the action authenticates as the Claude GitHub App. This runbook used to say the opposite and sent you fixing a problem you don't have.
- **The pull request opened by the workflow does not trigger CI.** That step uses the default `GITHUB_TOKEN`, and GitHub does not start workflow runs from it. The API event *does* fire — watched on 2026-09-06. Whether it reaches a **webhook** subscriber is **unverified**: no webhook has ever been configured on our repos, so we have not seen one delivered. The return-path routine we tested used the bot's built-in GitHub connection instead. If you need CI on those pull requests specifically, pass a GitHub App token to that step — and accept that you are then storing another credential.
- **The same rule is why the PR step lives inside `claude.yml`.** `actions/checkout` writes the workflow `GITHUB_TOKEN` into git config, so Claude's own push is made with it and cannot trigger any `on: push` workflow. See #61.
- Claude runs your tests inside its own turn regardless (see `CLAUDE.md.template`).

### R4 — Grok Bot allowance at 100% mid-week
- Look for bot-to-bot loops (group chat history) and short-interval routines first. Staff-confirmed: every bot-to-bot message is a metered turn, and "please stay quiet" is only a hint.
- Consolidate to one command agent with subagents; delete idle specialist bots; make routines hourly.
- Confirm the on-demand limit is `$0` so it can't spill.

### R5 — Coder bot wrote code itself
- Its description drifted or was overridden. Re-paste `templates/bots/coder.md` into **Bot actions → Edit Profile**. There is no channel charter to also update — the description is the only durable instruction surface.

### R6 — Grok Bot shared computer stuck
- Whole roster is affected; this is a vendor-side single point of failure. Reset from the app; if that fails, forum thread with the bot name and time. Coding is unaffected — issues already opened keep flowing through GitHub.

### R7 — Runaway action
- `gh run cancel <id>`. Then lower `--max-turns` or `timeout-minutes`. Check the brief: vague stop conditions cause loops.

## Monitoring without a stack

You don't need Grafana for this. Three URLs, once a day:

- Grok Bot usage (in app)
- Claude usage (in app or `/usage`)
- `https://github.com/OWNER/REPO/actions`

If you later want a single view, a scheduled Claude Code routine can summarise all three into an issue comment weekly. That's a task in `TASKS.md`, phase 3.

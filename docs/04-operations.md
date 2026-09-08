# 04 — Operations

## The three meters

| Meter | What burns it | Where to look | Brake |
|---|---|---|---|
| **Grok Bot weekly allowance** | Chief of Staff turns, Coder writing issues, routines, bot-to-bot chat, browser sessions | **Settings → Usage & Billing** in the app (rollout-dependent — *"for eligible accounts"*), otherwise <https://cursor.com/dashboard/usage> | Turn caps in **bot descriptions**; hourly routines not quarter-hourly; on-demand limit `$0` |
| **Claude Max** | Every action run; longer tasks and more turns cost more | Claude usage page; `/usage` in Claude Code | `--max-turns`, `timeout-minutes`, `concurrency` in the workflow |
| **GitHub Actions minutes** | Runner time per task | Repo → Settings → Billing | Same three workflow caps |

Rule of thumb from the research (Sep 2026): a chief-of-staff-only Grok Bot fleet should sit well under 50% of the weekly allowance by mid-week. If it doesn't, the drain is coordination chatter, not coding — fix the bot descriptions, not the bridge.

**There is still no Grok Bot-specific spend cap.** Once the weekly pool is exhausted, usage continues on the account's shared on-demand spend. Your only brake is the account-wide on-demand limit, which is why the setup guide tells you to set it to `$0`.

> **Corrected 2026-09-07.** This paragraph previously said the dashboard *"does not currently split Grok Bot usage from Cursor usage"*. The vendor's own FAQ now says the opposite — *"the per-product split is on the dashboard usage page"* (<https://docs.x.ai/grok-bot/teams-and-enterprises>, read 2026-09-07). Either it shipped after this was written on 5 Sep, or we were wrong then. **We have not logged in to look**, so treat "there is a per-product split" as the vendor's claim rather than as something we have seen.

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
HANDOFF=~/handoff   # wherever you cloned Handoff itself
bash "$HANDOFF/scripts/doctor.sh" OWNER/REPO --machine-account BOT-LOGIN --token   # $BOT_TOKEN set
```

You are normally standing in the consumer repository when you run this, and a bare
`scripts/doctor.sh` does not exist there. Same form as `AGENTS.md` and the setup guide.

Exits non-zero if anything required is missing, and prints the exact command or click that fixes it. Run this first when something stops working — most of what it checks is invisible until it breaks, and two of them (the workflows being on the default branch, and Actions being allowed to open pull requests) cost us an hour each to discover the hard way.

It cannot confirm the Claude GitHub App is installed — no API exposes that without the app's own credentials — so it tells you to check that one by eye rather than pretending.

## Failure modes and runbooks

> **How much of this has been watched happening, as of 2026-09-06.** These entries are not all the
> same kind of claim, and the difference matters when you are debugging at speed.
>
> | Entry | Basis |
> |---|---|
> | R1 "no run at all" — workflow not on the default branch | **Observed.** Cost us an hour; it is why `doctor.sh` checks it. |
> | R1 read-only account fails rather than being ignored | Read in the action's source and docs. **Still not run** — the drill needs a second GitHub account, which we do not have. |
> | R2 expired credentials | **Observed 2026-09-08**, run `34155909253`, on a throwaway repo with a deliberately invalid token. Corrected below. |
> | R3 both halves | **Observed.** Shipped as issue 61 and corrected after watching it. |
> | R4 allowance exhaustion | Vendor staff statement. Our own meter has **never been read** — see `08-measurements.md`. |
> | R5, R6 | **Neither has happened to us.** Written from the vendor's behaviour as documented. |
> | R7 runaway action | **Cancellation observed 2026-09-08**, run `34156267717`. The *runaway* it responds to has still never occurred here — we cancelled a healthy run. |
>
> **Task 1.6 ran two of its three drills on 2026-09-08.** R2 and R7 were triggered deliberately and
> both entries below were corrected from what was actually seen. **R1 was not run**: it needs a
> second GitHub account with read-only access, and creating one is not something this project can do
> for itself. That row stays honest rather than quietly assumed.
>
> Note what R7 proved and what it did not. We cancelled a **healthy** run to see what cancelling
> looks like. Nothing here says a genuinely runaway agent is detectable or stoppable in time — only
> that `gh run cancel` does what it says, and what it leaves behind.

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
- **Observed 2026-09-08** (task 1.6, run `34155909253` on a throwaway repo with a deliberately invalid token). What you actually see:
  - The job fails at **`Run Claude Code`, after about two seconds.** Everything before it succeeds — the misrouted-issue guard and `actions/checkout` both pass — so a glance at the run list shows a failure that looks like it could be anywhere.
  - **`Open the pull request` is `skipped`, correctly.** The `if: steps.claude.outputs.branch_name != ''` guard holds, so a bad token produces no empty or broken pull request.
  - **You do get told, on the issue.** The Claude App comments *"Claude encountered an error after 2s"* with a link to the job. That is the fastest route to the cause — faster than the run list, which does not say what failed.
  - The failing step's log does **not** print a plain "invalid credentials" line; the credential is masked throughout as `***`. Do not go looking for one.
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
- **Observed 2026-09-08** (task 1.6, run `34156267717`). Cancelling is clean where it matters: the run ends `cancelled`, and **no branch and no pull request are left behind** — so there is nothing to tidy up in git.
- **But go back and close the issue comment yourself.** The Claude App's comment is left frozen mid-task — *"Working on it"* with a half-ticked todo list — and it is **never updated to say the run was cancelled**. Anyone returning to that issue, including you next week, sees what looks like a run still in progress. That is the whole visible trace of a cancellation, and it is misleading.

### R7a — you cancelled it, so nothing is wrong
Worth separating from R7, because the symptom is identical to a hung run. If an issue shows Claude *"Working on it"* and nothing has changed for a long time, check `gh run list` before debugging anything: a cancelled run leaves exactly that comment behind forever.

## Monitoring without a stack

You don't need Grafana for this. Three URLs, once a day:

- Grok Bot usage (in app)
- Claude usage (in app or `/usage`)
- `https://github.com/OWNER/REPO/actions`

If you want a single view, `templates/weekly-cost.yml` already exists — copy it in and it posts a weekly cost report as an issue comment. It is optional, and it is **deliberately not an agent**: reading merged pull requests and run durations is deterministic aggregation, so it uses `gh` and `awk` and **zero model turns**. A model would spend subscription turns, could hallucinate a figure, and would give a different answer each week from the same data. See `TASKS.md` task 3.3.

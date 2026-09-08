# 07 — Evidence

Why we believe the pain point is real and structural. Compiled 5 Sep 2026 from xAI/Cursor docs, the Cursor community forum (especially threads with staff replies), Reddit, X and hands-on reviews. Competitor-authored sources are noted; treat their framing with care and their dated facts as corroboration only.

## The structural facts (vendor docs)

| Fact | Source |
|---|---|
| Usage resets **weekly**; the allowance is published only as a ranking (Ultra > Pro+ > Pro), never as a number | <https://cursor.com/help/grok-bot/plans>, "How does Grok Bot usage work?" and the tier table, read 2026-09-07 |
| **"A separate Grok Bot spend cap is not available today. Account-level on-demand controls apply, and the per-product split is on the dashboard usage page."** | <https://docs.x.ai/grok-bot/teams-and-enterprises>, FAQ "Can I set a Grok Bot spend cap?", read 2026-09-07 |
| No customer-facing model picker; billing follows the serving model | <https://docs.x.ai/grok-bot/security>, "Models and data", read 2026-09-07 |
| When the weekly pool is exhausted, usage continues on shared on-demand spend if on-demand is enabled — and it is **on by default on the Teams plan** | <https://cursor.com/help/grok-bot/plans>, read 2026-09-07 |
| All of one user's bots share one computer; bots isolate personalities and workspaces, not compute | <https://docs.x.ai/grok-bot/teams-and-enterprises>, "How users are isolated", read 2026-09-07 |
| Routines: 50 per bot, last 20 runs kept, test run performs real work, may pause after long absence | <https://docs.x.ai/grok-bot/skills-routines-and-automations>, read 2026-09-07 (that page's own "Last updated" is 11 Aug 2026 — the oldest of the set) |

These are design choices, not bugs. None had shipped a change as of 5 Sep 2026, though xAI said efficiency improvements are coming.

> **Corrected 2026-09-07.** Before this date, exactly one of the six rows carried a URL or a read
> date, in a column headed "Source". Every row now names the page its supporting sentence was read
> on and the date it was read. Two attributions moved: the model-picker row was credited to a Cursor
> doc, but the sentence is on `docs.x.ai/grok-bot/security`; the isolation row was credited to the
> xAI FAQ, but the full statement is on the teams-and-enterprises page. Two wordings were tightened
> at the same time. The allowance row said the size "is not published per plan", which overstates
> the silence — a per-plan *ranking* is published, only the quantity is withheld. The isolation row
> said "separate bots are not a security boundary", which is our sentence rather than the vendor's;
> the vendor's own framing is used instead.
>
> **Read-dates on this table come from a re-verification pass run on 2026-09-07**, in which each
> page above was fetched and the supporting sentence copied out of the page body. Grok Bot's docs
> are split across two hosts — the product is documented on `docs.x.ai` and billed and hosted by
> Cursor — which is why these citations were hard to re-find in the first place.
>
> One boundary this table does **not** describe, and which matters if you redraw it: the missing
> isolation is *within* one user's bots. Between users the vendor documents a real boundary — a
> dedicated microVM per user, with its own kernel and memory. Same page, same date.

## What users measured (dated)

| Date | Report | Source type |
|---|---|---|
| 14 Aug | ~42% of the weekly allowance on day one, six agents | business user, relayed |
| 17 Aug | Bought Ultra for Grok Bot; reported it as close to unusable — overloaded providers, stuck agents | X |
| 22 Aug | ~100 chat completions + one 10-min script ≈ 5% of a week | r/grok |
| 23–24 Aug | One workload ≈ half a weekly allowance on Heavy; allowance reverse-engineered at ~16M tokens | r/cursor, relayed |
| 27 Aug | Pro user infers a ~$200/week pool from 35% = $69.94 | Cursor forum (primary); staff confirmed the meter is accurate, not the $ figure |
| 30 Aug – 3 Sep | $275 in credits drained; subagents used models billed outside the Grok Bot pool | Cursor forum (primary) |
| 1 Sep | Weekly usage hit 100% after bot-to-bot reviews the user asked to stop; 3-day lockout | Cursor forum (primary) |
| 2 Sep | **A staff reply.** Recovered, sourced and verified verbatim on 2026-09-08 — see [What drains fastest](#what-drains-fastest-community-consensus--staff) below for the exact wording and the thread URL. This row is no longer a paraphrase | Cursor forum (staff) — **checkable** |
| 4 Sep | Five agents talked to each other for seven hours unattended; on-demand usage burned | Cursor forum (primary) |

> **Sourcing note, added 2026-09-07 — read this before quoting anything from here.** Everything from
> the table above down to "Our runs" is our reading of forum threads, social posts and third-party
> write-ups whose URLs we did not keep. Several lines were written as quotations in earlier drafts,
> including two attributed to vendor staff — one to Cursor's, one to xAI's. They are paraphrases
> now. A quotation nobody can look up is worse than a plain statement of what we understood, and
> this project's own worst defect class is a sentence in quotation marks that the vendor never wrote.
>
> So: **nothing between here and "Our runs" is verbatim, and none of it is checkable by a reader.** The
> vendor-documented facts at the top of the file carry a URL and a read date; the "Our runs" section
> below is what we produced ourselves. This middle stretch is neither.
>
> **Amended 2026-09-08 — one exception, and it is a repair rather than a hole.** The 2 Sep staff
> reply has since been re-found, its thread URL recovered, and its wording verified against the live
> page. It now appears verbatim, with a link and a read date, under *What drains fastest*. So that
> one item **is** checkable, and the sentence above no longer applies to it.
>
> This is the direction the file is meant to move in: a paraphrase becomes a quotation only by
> someone going and re-reading the source, never by remembering it more confidently. **Everything
> else in this stretch remains unchecked**, and finding one URL does not make the neighbouring lines
> any more reliable than they were.

## What drains fastest (community consensus + staff)

1. Bot-to-bot loops in group chats
2. Short-interval routines (a 15-minute cron is ~100 runs a day)
3. Long coding / agent loops — the heaviest model tier gets routed in
4. Browser / computer-use sessions

Coding is not the *only* drain, but it is the one that (a) is the most token-hungry per task and (b) has a clean, flat-rate home elsewhere. That is why this project moves coding and leaves the rest.

**Number 1 is confirmed first-party, not inferred.** This ranking was originally assembled from community reports. The top item is now backed by the vendor's own staff. From the Cursor community forum thread *"Grok Bot: weekly usage hits 100% after bot-to-bot reviews the user asked to stop"* ([170271](https://forum.cursor.com/t/grok-bot-weekly-usage-hits-100-after-bot-to-bot-reviews-the-user-asked-to-stop/170271)), read 2026-09-08:

> each bot-to-bot message runs a turn that counts toward your weekly usage

> Asking them in chat to "stay quiet" is only a hint they can ignore

— Mohit, Cursor staff, 2026-09-02. The suggested remedies were to consolidate into one agent using subagents, or to delete unused specialist bots.

A user in the same thread on 2026-09-04:

> I just had 5 of my agents talking to each other for 7hours straight with NO Human interaction and burned through a lot of my on demand usage.

They asked where to appeal for a refund. **Staff did not answer that question in the thread**, and we do not know whether a refund was given — do not imply one either way.

**Why this is worth recording rather than celebrating.** It is evidence *against* the easiest version of this project's pitch. Drain 1 is the loudest complaint, staff have confirmed it is both real and not user-controllable, and **Handoff does not fix it.** Handoff moves drain 3. Anyone recruited on the strength of drain 1 will install this, watch their allowance keep draining, and be right to conclude it did not work. The README's drain diagram and the "Handoff will not fix that" sentence are the honest reading of this quote, and they should stay.

## The offload pattern already exists

- **Locum** — delegates Grok Bot coding to a local Claude Code/Codex over an MCP tunnel; its stated purpose is to stop the bot burning Grok Bot usage on its own agent loop.
- Setup prompts to install Claude Code / Codex / Cursor CLIs on the bot computer (fragile: installed packages are wiped on image updates).
- Posts describing Grok Bot as an orchestrator driving a remote box over SSH.
- Cursor's own path: Grok Bot delegating to **Cursor Cloud Agents**, which bill to the Cursor pool rather than the Grok Bot pool.
- xAI staff have described an engineering-manager bot that delegates rather than writing code itself.

Every one of these is a bridge. All of them need **a server, a tunnel, a second billing pool, or your coding credential on the bot's shared computer.** This project is the version that needs none of the four.

> **Corrected 2026-09-07, and the correction matters.** This paragraph previously said "a server, a
> tunnel, or a second metered pool" — three axes. The second bullet above falsifies that: installing
> the coding CLI on the bot's own computer needs no server you provision, no tunnel, and — signed in
> to your own subscription — no second pool. On the three axes as written it beat us.
>
> The fourth axis is what it actually costs, and this project already documents it as unacceptable:
> `05-security.md` says to assume that computer is compromised and lists a coding login under
> **Never on the bot computer**, the vendor states that all a user's bots share one computer and that
> any permitted connector is available to every bot they run, and the bullet above records that
> installed packages are wiped on image updates.
>
> "Second **billing** pool", not "metered pool": we can evidence that Cursor Cloud Agents bill to a
> *different* pool; we have not evidenced that that pool is metered per token.

### The same thing as a table

**Scored from our own notes on other people's products. We have run none of them.** Every
`unknown` below is a cell we could not substantiate, not one we lost interest in. `unknown` is
deliberately not written as "no". Corrections welcome — open an issue.

| Approach | A server you run | A tunnel or inbound endpoint | A second billing pool | Your coding login on the shared bot computer | Survives the bot computer's image updates | Run end to end by us |
|---|---|---|---|---|---|---|
| **Handoff** | No | No | No — `$0.00` measured | No — the bot holds an issues-only GitHub token | n/a — nothing is installed there | **Yes** — run `34023564889` |
| Coding CLI on the bot's own computer | No | No | No, if signed in to your own subscription | **Yes** | **No** — installed packages are wiped on image updates | No |
| Locum — MCP tunnel to a local agent | **Yes** — a machine you run | **Yes** — an MCP tunnel | No — its stated purpose is to stop burning Grok Bot usage | `unknown` | `unknown` | No |
| Cursor Cloud Agents | No — hosted by the vendor | No | **Yes** — they bill to the Cursor pool rather than the Grok Bot pool | No | n/a | No |
| A persistent session on a VPS | **Yes** — a VPS | `unknown` | `unknown` — probably the same subscription, but we cite no source | `unknown` | n/a | No |

Also named in our decision record: a Jenkins/webhook bridge, and driving a remote box over SSH.
**We hold too little on either to score them honestly**, so they are not in the table.

### What Handoff needs instead

A matrix with only the other side's costs in it is a sales sheet. These are ours:

| | |
|---|---|
| **GitHub Actions minutes** | About 62s per task. The timing API reported `billable_ms: 0` for every run on this repo, and whether that is a free-tier allowance or an unpopulated field is **unresolved**. Count it as a real, small, unpriced cost. |
| **A repository setting** | Settings → Actions → General → *"Allow GitHub Actions to create and approve pull requests"*. **Off by default on every repository**, and the single most common silent failure. |
| **Your own CI will not run on the pull request** | A PR opened with the default `GITHUB_TOKEN` starts no further workflow runs. Pass a GitHub App token if you need it — and then you are storing another credential. |
| **No memory across tasks** | Each task starts fresh. The repository and the issue thread are the memory. |
| **Proven once per link, not repeatedly** | *"One run each… nothing here speaks to reliability over time."* |

## What people like

- The chief-of-staff pattern works. One August write-up set up a researcher, a writer and a chief of staff expecting it to fall apart, and reported that it did not.
- Browser reach on sites without APIs; mobile take-over for logins; zero-setup persistence.
- The consensus of the reviews we read: worth trying, not yet worth reorganising a business around.

## What would change the conclusion

- xAI publishes numeric allowances **and** ships a Grok Bot spend cap **and** a model picker. Then Grok Bot alone may be enough for light coding.
- The Claude Code Action loses OAuth/subscription support. Then the economics of this bridge change; API billing might still beat Grok Bot overage, but it must be measured.
- Verified reports that a mid-tier plan absorbs several daily coding tasks without spillover.

## Our runs

Evidence we produced ourselves, rather than collected. Repo: a throwaway private repo built for this test — a dependency-free Node project with three real tests, so "the tests must pass" exercises something.

**Why the run IDs are not links.** These runs happened on **private** repositories, so the URLs would 404 for every reader — a link that cannot be followed is worse than an identifier that is honest about being one. The account and repository names are omitted deliberately: this is a template for other people, and it should not carry its author's GitHub handle. The run IDs are kept because they are what makes each claim traceable *by us*, and because inventing them would be the one thing this document exists to prevent.

### 2026-09-05 — the thesis test (task 0.2)

**run `33961149264`** — issue mentioning `@claude` → Claude Code on a GitHub-hosted runner.

| | |
|---|---|
| Trigger | issue opened, body containing `@claude` |
| Wall clock | **63s** (10:37:13Z → 10:38:16Z) |
| Claude's own time | 30s |
| Turns | **10 of 25** allowed |
| Output | `CONTRIBUTING.md`, 24 lines, accurate |
| Tests | `npm test` — 3 of 3 passed |
| Scope discipline | touched nothing it was told not to |
| Committed as | `claude[bot]` |
| **Anthropic Console API spend** | **zero** — confirmed by the account owner on the [Console usage page](https://platform.claude.com/usage). Anthropic's docs point there for authoritative billing: *"The figure is an estimate, so for authoritative billing see the Usage page in the Claude Console."* — <https://code.claude.com/docs/en/costs>, read 2026-09-07 |

**The thesis holds.** A coding task was executed and billed to a Claude Max subscription, triggered by a GitHub issue, with no Grok Bot involved and no pay-as-you-go charge.

Note the run log printed `total_cost_usd: 0.157`. That figure is **not** a charge. Anthropic's own documentation says so:

> "The Session block in `/usage` shows API token usage and is intended for API users. Claude Max and Pro subscribers have usage included in their subscription, so the session cost figure isn't relevant for billing purposes."
> — <https://code.claude.com/docs/en/costs>, read 2026-09-07

It is a notional list-price estimate printed regardless of how you pay.

### The acceptance test as originally written could not pass

`TASKS.md` 0.2 **originally** asked for "a PR opened by the Claude app". **That is impossible** — the action has no PR-creation tool in tag mode (see D12 and issue #41). What actually happens: Claude pushes a branch and posts a pre-filled "Create PR" link.

Recorded as passed on the substance — work delivered, billed to the subscription — with the PR clause corrected rather than quietly ignored. **That clause has since been corrected in place**, so `TASKS.md` 0.2 now names `github-actions` and the PR step; this section is the record of why it was changed, not a live disagreement between the two files.

### 2026-09-05 — the return path, first attempt, and why it did not count

**run `33974291123`** — a *separate* `claude-open-pr.yml`, triggered `on: push`, opening the pull request the action does not open. Produced PR 3.

**That workflow no longer exists.** It was deleted in PR #62 because **it never fired for Claude**: `actions/checkout` persists the workflow `GITHUB_TOKEN`, Claude's push from inside the runner uses it, and GitHub does not start workflow runs from that token. The run above passed only because the push came from a laptop. A control that does not exercise the property the conclusion rests on proves nothing — and this one was accepted twice. See D12 and issue #61.

Two things it cost us to learn, both still true of the current design:

1. It fails with `GitHub Actions is not permitted to create or approve pull requests` until you enable **Settings → Actions → General → Allow GitHub Actions to create and approve pull requests**. Off by default on every repository.
2. Taking the PR title from `git log -1` yields the merge commit's subject whenever the branch has been refreshed from base. Use the last non-merge commit.

### 2026-09-05 — the return path, proven on the path that matters

**run `33983515065`** — issue 6, "bridge test 2 — does the PR open now?", with the PR step now **inside `claude.yml`**.

| | |
|---|---|
| The push | commit `7070309`, author **and** committer `claude[bot]`, 18:16:42Z — **no human push anywhere in the chain** |
| The step | "Open the pull request" — `success`, in the same run |
| The result | PR 7, opened 18:16:59Z by `github-actions`, titled from Claude's commit, with `Closes #6` |

This is the case that failed twice before. It is the only run in this file that establishes the current design works.

**Verified 2026-09-06:** that PR generated a `pull_request` event — `actor=github-actions[bot]`, `action=opened` — observed directly on the repository's events API. So a PR opened with the default `GITHUB_TOKEN` does produce the event, even though GitHub suppresses *workflow runs* from that token.

**Still not verified:** whether that event is *delivered to a webhook subscriber*. This repository has never had a webhook configured, so nothing was delivered and nothing was observed. D12's "webhooks and API events do fire" is, on the webhook half, still an inference from GitHub's documentation rather than something we have watched happen. **Task 1.5 pass 2 ran on 2026-09-06 and did not settle it** — that run used the bot's built-in GitHub connection, not a webhook. The question is still open, and settling it needs a webhook actually configured on a repo.

### 2026-09-06 — the return path runs unattended (task 1.5, and the answer to #57)

**The last unproven link in the chain.** Everything else showed work going *out* to GitHub; this is the first evidence of anything coming *back* without a human going to look for it.

The routine was created by messaging the Coder bot with the block now in `templates/routines/pr-ready.md`. Coder confirmed the trigger as its **built-in GitHub connection** (`trigger.type: github`), not an inbound webhook — which matters, because the webhook path is the one Cursor staff flagged for approval-gating.

Two passes, deliberately using different senders:

| Pass | Pull request opened by | Reported line |
|---|---|---|
| 1 | the repo owner, a human account | `PR 10 ready — tests pending — …` |
| 2 | **`github-actions`** — the workflow token | `PR 12 ready — tests pending — …` |

**Pass 2 is the one that was never guaranteed.** A routine can watch for pull requests from a human and never see the ones the automation opens; that blind spot is exactly what let the first PR-opening design pass "verification" twice (#61). It sees both.

**No approval card appeared for either pass.** The line posted directly into the group chat. Both matched the requested format exactly.

**The transcript contains its own control, which is why this is worth trusting.** Earlier in the same conversation, *saving the routine* did raise an approval card — a distinct "Save the PR ready routine as described? / Save it" prompt that waited for a tap. So the chat demonstrably renders approval cards, and neither report had one. This is a visible contrast in a single screen rather than an inference from silence.

Two things Coder did unprompted, both worth recording because they bear on how much weight its self-reports carry:

- Asked the five confirmation questions, it replied *"Checking the saved routine file so these answers match what's actually stored"* before answering — it read its own configuration rather than recalling it.
- It raised the CI caveat itself: *"since it only fires when the PR opens, CI will often still be `pending` at that moment."* That is the same limitation recorded below, identified by the bot before we tested.

**#57 is answered: on the built-in GitHub connection trigger, the report-back is not gated.** The warning we are working from — our reading of a Cursor staff reply, to the effect that a webhook delivery does not count as user intent — appears to be specific to the *webhook* trigger. **We have not tested the webhook path** and make no claim about it.

**Unverified, and the caveat above rests on it.** That staff warning was written as a quotation here until 2026-09-07 and we hold no thread URL for it, so a reader cannot check it and neither can we. It is recorded as our paraphrase of something we read, not as the vendor's words. What *is* verified is the other half: on the built-in GitHub connection, both passes reported without an approval card.

Pass 2's underlying chain, for the record:

| Link | Evidence | Time (UTC) |
|---|---|---|
| Coder writes the brief | issue 11, `login=<owner>`, `type=User`, `app=none` | 09:44:45 |
| Action runs | run `34025508553`, `success`, 67s, **11 of 25** turns | 09:44:48 |
| Claude pushes | `1310225`, author **and** committer `claude[bot]` | 09:45:34 |
| PR step opens it | PR 12 by `github-actions`, diff `+1/-0` | 09:45:51 |
| Coder reports it | One line in the group chat | — |

**66 seconds from issue to pull request**, then the report.

**Three things this run does not show, recorded so nobody reads more into it than it proves:**

1. **Delivery latency was not measured.** We know both reports arrived and that neither required approval. We did not record how long either took, and the account owner may have had the app open when they landed — so "arrived promptly" is an impression, not a measurement.
2. **The routine has only ever emitted `tests pending`.** The trial repo had no CI, so the `green`/`red` branches of its output format were **never exercised**. Coder itself pointed out a second reason this keeps happening even on a repo that *does* have CI: the routine fires on `pull_request opened`, and checks are usually still queued at that instant. A routine that reports the moment a pull request opens will report `pending` most of the time by design. **Addressed 2026-09-08 — see below.**

### 2026-09-08 — a green/red verdict, observed on both branches (issue 108)

The gap above is closed, by a workflow rather than by changing the routine. `templates/pr-checks-report.yml` posts a second comment once the checks settle. It uses `gh` and shell and **no model turns**, and it assumes nothing about any chat vendor's connector.

CI was added to the trial repo — its absence was the root cause — and two pull requests were opened deliberately, one passing and one failing:

| Pull request | CI | Comment posted |
|---|---|---|
| 16 | success | `**Checks green** — 1 of 1 passed.` |
| 17 | failure | `**Checks red** — 1 of 1 failed.` |

Report runs `34156121781`, `34156121772`, `34156104908`. **Both branches of the verdict have now run, on real pull requests with real CI. Neither had ever run before, anywhere.**

**The first design was wrong, and the way it failed is the finding.** It triggered on `check_suite: completed`, which needs no configuration — and it produced **zero runs** while CI went green on one pull request and red on the other. GitHub documents why:

> To prevent recursive workflows, this event does not trigger workflows if the check suite was created by GitHub Actions or if the check suite's head SHA is associated with GitHub Actions.
>
> — <https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows>, read 2026-09-08

So `check_suite` can **never** report on CI that itself runs in Actions — which is every consumer of this template. The documented alternative, `workflow_run`, works, and it requires naming the upstream workflow by its `name:` field. That naming is a real cost: get it wrong and the workflow silently never runs, which is the same failure mode it exists to fix. It is flagged in the template's header rather than buried.

**Not covered:** one CI check on a small repository. Nothing here says how the aggregate behaves across several suites, on a fork pull request, or when a check is `neutral` or `skipped` — those paths are coded for and remain unobserved. The `workflow_run` trigger also runs in the default-branch context with access to secrets, so the job deliberately checks out nothing and runs nothing from the pull request.
3. **One run each.** Neither pass has been repeated, so nothing here speaks to reliability over time — only to whether the path works at all.

### 2026-09-06 — the whole bridge, with Grok Bot in the loop (task 1.3)

**The first run in which no part of the chain was simulated, stubbed or performed by hand.** Everything before this proved the GitHub half; this is the first evidence that the Grok Bot half works at all.

A one-line ask to the Coder bot — *"Open an issue asking @claude to add a docs/HELLO.md with one sentence in it"* — produced a reviewable pull request in **61 seconds**.

| Link | Evidence | Time (UTC) |
|---|---|---|
| Coder writes the brief | issue 8, `login=<owner>`, `type=User`, `performed_via_github_app=none` | 09:03:29 |
| The action accepts it | run `34023564889`, `success` | 09:03:32 |
| Claude pushes | `bf287af`, author **and** committer `claude[bot]` | 09:04:14 |
| The PR step opens it | PR 9 by `github-actions`, `Closes #8` | 09:04:30 |

**Run cost:** 62s wall clock, **9 of 25** turns.

**Coder's brief was well-formed without being told the format twice.** It emitted `@claude` on line one, the file path, a one-sentence why, a "Done means", and a "Do not" — the exact order `templates/bots/coder.md` specifies. It did **not** ask Claude to open a pull request, which the description forbids because Claude cannot and asking wastes a turn.

**Scope discipline held.** The diff is one file, `+1/-0`: `docs/HELLO.md`, containing `Hello from the [trial repo] repository.` — one sentence, as briefed, nothing else touched. (Square brackets mark a redacted repository name, per the note at the top of this file; the file itself said the real one.)

**And Coder wrote no code.** `/workspace` on its computer was checked by the account owner and contained no code changes. That is the half of task 1.3's acceptance test that cannot be seen from GitHub, and it is the half that actually matters: the test is whether Coder *briefs* rather than *builds*.

**Still not proven by this run:** the return path. Nothing reported the pull request back into the group chat — that is task 1.5, and it is the last unobserved link in the chain.

### 2026-09-06 — task 1.2, the identity check (recovered from the API)

The original terminal output from this check was not kept. It did not need to be: the fields the acceptance test asks for are durable on GitHub and were read back with `gh api` on 2026-09-06.

Both issues Grok Bot opened through its GitHub connector:

| Issue | `user.login` | `user.type` | `performed_via_github_app` |
|---|---|---|---|
| 5 — "bridge test" | `<owner>` | `User` | **none** |
| 6 — "bridge test 2" | `<owner>` | `User` | **none** |

`performed_via_github_app: none` is the load-bearing field. The action rejects bot actors, so a connector acting as a GitHub *App* would have been refused; this shows it acted as a real user account. Combined with run 33983515065 completing and PR 7 opening, **task 1.2's chain is complete**: issue by that account → action runs (write-access check passes) → pull request opened by `github-actions`.

**Task 1.1 is a different matter and is deliberately still unticked.** Its acceptance test asks for two `curl` calls proving the token reaches one repo (`200`) and not another (`404`). That output was not kept, and unlike the fields above it **cannot be recovered** — it depends on the token, which is not ours to replay. Re-running it takes about two minutes. Recorded as missing rather than assumed, because the whole point of the test is what the token *cannot* reach.

### 2026-09-05 — assignment costs runner time, not subscription usage

**run `33971250162`** — assigning an issue whose body contains `@claude` starts a runner but never starts Claude: `No trigger found, skipping remaining steps`, zero turns, 16s, exits green. The action only reads an issue body for the trigger phrase on `opened`.

## Caveats

- Allowance sizes are user-inferred; no vendor has confirmed them.
- Several reports reach us through third-party trackers; the forum threads marked "primary" were read directly.
- Both products change weekly. Re-verify before each build phase.

### 2026-09-08 — runbook drills R2 and R7 (task 1.6)

Two of the three drills in task 1.6, triggered deliberately. What follows is what was seen, not what was expected.

| Drill | Run | What actually happened |
|---|---|---|
| **R2 — expired credentials** | `34155909253`, throwaway repo `handoff-drill-r2` with a deliberately invalid `CLAUDE_CODE_OAUTH_TOKEN` | Job failed at **`Run Claude Code` after ~2s**. The misrouted-issue guard and `actions/checkout` both **succeeded** first, so the run list shows a failure without saying where. **`Open the pull request` was `skipped`** — the `branch_name` guard held, so a bad token produces no broken pull request. The Claude App commented on the issue: *"Claude encountered an error after 2s"* with a job link. **No plain "invalid credentials" line appears in the log** — the credential is masked as `***` throughout, so do not go looking for one |
| **R7 — cancel a run** | `34156267717`, trial repo | `gh run cancel` ended it `cancelled`. **No branch and no pull request left behind.** But the Claude App's comment is frozen mid-task — *"Working on it"* with a half-ticked todo list — and is **never updated to say it was cancelled**. The issue looks like a run still in progress, permanently |

**R1 was not run.** It needs a second GitHub account with read-only access to trigger the write-access rejection, and this project has no way to create one. The row stays marked unobserved in `04-operations.md` rather than assumed.

**What R7 does not prove.** We cancelled a *healthy* run to see what cancelling looks like. Nothing here shows that a genuinely runaway agent is detectable, or stoppable in time — only that `gh run cancel` behaves as documented and what it leaves behind afterwards. The runbook now separates those two things.

**The most useful finding is the smallest one.** Both drills leave a **stale, misleading comment on the issue** — R2's says an error occurred, which is fair; R7's says work is in progress, which is false and stays false. In both cases the issue thread is the first place a person looks, and in one of them it lies. `04-operations.md` gained an R7a entry for exactly that symptom, because it is indistinguishable from a hung run.

# 07 — Evidence

Why we believe the pain point is real and structural. Compiled 5 Sep 2026 from xAI/Cursor docs, the Cursor community forum (especially threads with staff replies), Reddit, X and hands-on reviews. Competitor-authored sources are noted; treat their framing with care and their dated facts as corroboration only.

## The structural facts (vendor docs)

| Fact | Source |
|---|---|
| Usage resets **weekly**; the allowance size is not published per plan | Cursor plans doc; xAI Grok Bot docs |
| "There is no Grok Bot-specific spend cap yet" | Cursor teams/billing doc |
| No model picker; billing follows the actual serving model | Cursor Grok Bot doc |
| When the weekly pool is exhausted, usage continues on shared on-demand spend if enabled | Cursor plans doc |
| All bots share one computer; separate bots are not a security boundary | xAI Grok Bot FAQ |
| Routines: 50 per bot, last 20 runs kept, test run performs real work, may pause after long absence | xAI skills/routines doc |

These are design choices, not bugs. None had shipped a change as of 5 Sep 2026, though xAI said efficiency improvements are coming.

## What users measured (dated)

| Date | Report | Source type |
|---|---|---|
| 14 Aug | ~42% of the weekly allowance on day one, six agents | business user, relayed |
| 17 Aug | Bought Ultra for Grok Bot; "nearly unusable" — overloaded providers, stuck agents | X |
| 22 Aug | ~100 chat completions + one 10-min script ≈ 5% of a week | r/grok |
| 23–24 Aug | One workload ≈ half a weekly allowance on Heavy; allowance reverse-engineered at ~16M tokens | r/cursor, relayed |
| 27 Aug | Pro user infers a ~$200/week pool from 35% = $69.94 | Cursor forum (primary); staff confirmed the meter is accurate, not the $ figure |
| 30 Aug – 3 Sep | $275 in credits drained; subagents used models billed outside the Grok Bot pool | Cursor forum (primary) |
| 1 Sep | Weekly usage hit 100% after bot-to-bot reviews the user asked to stop; 3-day lockout | Cursor forum (primary) |
| 2 Sep | **Staff:** "each bot-to-bot message runs a turn that counts toward your weekly usage… asking them to stay quiet is only a hint they can ignore" | Cursor forum (staff) |
| 4 Sep | Five agents talked to each other for seven hours unattended; on-demand usage burned | Cursor forum (primary) |

## What drains fastest (community consensus + staff)

1. Bot-to-bot loops in group chats
2. Short-interval routines (a 15-minute cron is ~100 runs a day)
3. Long coding / agent loops — the heaviest model tier gets routed in
4. Browser / computer-use sessions

Coding is not the *only* drain, but it is the one that (a) is the most token-hungry per task and (b) has a clean, flat-rate home elsewhere. That is why this project moves coding and leaves the rest.

## The offload pattern already exists

- **Locum** — delegates Grok Bot coding to a local Claude Code/Codex over an MCP tunnel; explicitly built to stop "burning Grok Bot usage on its own agent loop."
- Setup prompts to install Claude Code / Codex / Cursor CLIs on the bot computer (fragile: installed packages are wiped on image updates).
- "Grok Bot as orchestrator over SSH" posts.
- Cursor's own path: Grok Bot delegating to **Cursor Cloud Agents**, which bill to the Cursor pool rather than the Grok Bot pool.
- xAI's own staff describe an engineering-manager bot that "does not code" and delegates.

Every one of these is a bridge. All of them need a server, a tunnel, or a second metered pool. This project is the version that needs none.

## What people like

- The chief-of-staff pattern works: "I set up a researcher and a writer, then a chief of staff… I expected it to fall apart. It didn't." (Aug)
- Browser reach on sites without APIs; mobile take-over for logins; zero-setup persistence.
- Consensus review line: "Worth trying. Not yet worth reorganizing your business around."

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
| **Anthropic Console API spend** | **zero** — confirmed by the account owner on the [Console usage page](https://platform.claude.com/usage), the source Anthropic calls authoritative for billing |

**The thesis holds.** A coding task was executed and billed to a Claude Max subscription, triggered by a GitHub issue, with no Grok Bot involved and no pay-as-you-go charge.

Note the run log printed `total_cost_usd: 0.157`. That figure is **not** a charge — Anthropic's own docs say the session cost figure "is intended for API users… Max and Pro subscribers have usage included in their subscription, so the session cost figure isn't relevant for billing purposes". It is a notional list-price estimate printed regardless of how you pay.

### The acceptance test as written could not pass

`TASKS.md` 0.2 asked for "a PR opened by the Claude app". **That is impossible** — the action has no PR-creation tool in tag mode (see D12 and issue #41). What actually happens: Claude pushes a branch and posts a pre-filled "Create PR" link.

Recorded as passed on the substance — work delivered, billed to the subscription — with the PR clause corrected rather than quietly ignored.

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

**Still not verified:** whether that event is *delivered to a webhook subscriber*. This repository has never had a webhook configured, so nothing was delivered and nothing was observed. D12's "webhooks and API events do fire" is, on the webhook half, still an inference from GitHub's documentation rather than something we have watched happen. Task 1.5 pass 2 settles it.

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

**#57 is answered: on the built-in GitHub connection trigger, the report-back is not gated.** Cursor staff's warning that "a webhook delivery is not treated as user intent" appears to be specific to the *webhook* trigger. **We have not tested the webhook path** and make no claim about it.

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
2. **The routine has only ever emitted `tests pending`.** The trial repo has no CI, so the `green`/`red` branches of its output format have **never been exercised**. Coder itself pointed out a second reason this will keep happening even on a repo that *does* have CI: the routine fires on `pull_request opened`, and checks are usually still queued at that instant. A routine that reports the moment a pull request opens will report `pending` most of the time by design. If the CI status matters to you, trigger on check completion instead — untested, and a change to the template rather than a fix.
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

**Scope discipline held.** The diff is one file, `+1/-0`: `docs/HELLO.md`, containing `Hello from the claude-bridge-trial repository.` — one sentence, as briefed, nothing else touched.

**And Coder wrote no code.** `/workspace` on its computer was checked by the account owner and contained no code changes. That is the half of task 1.3's acceptance test that cannot be seen from GitHub, and it is the half that actually matters: the test is whether Coder *briefs* rather than *builds*.

**Still not proven by this run:** the return path. Nothing reported the pull request back into the group chat — that is task 1.5, and it is the last unobserved link in the chain.

### 2026-09-06 — task 1.2, the identity check (recovered from the API)

The original terminal output from this check was not kept. It did not need to be: the fields the acceptance test asks for are durable on GitHub and were read back with `gh api` on 2026-09-06.

Both issues Grok Bot opened through its GitHub connector:

| Issue | `user.login` | `user.type` | `performed_via_github_app` |
|---|---|---|---|
| 5 — "bridge test" | `<owner>` | `User` | **none** |
| 6 — "bridge test 2" | `<owner>` | `User` | **none** |

`performed_via_github_app: none` is the load-bearing field. The action rejects bot actors, so a connector acting as a GitHub *App* would have been refused; this shows it acted as a real user account. Combined with run 33983515065 completing and PR #7 opening, **task 1.2's chain is complete**: issue by that account → action runs (write-access check passes) → pull request opened by `github-actions`.

**Task 1.1 is a different matter and is deliberately still unticked.** Its acceptance test asks for two `curl` calls proving the token reaches one repo (`200`) and not another (`404`). That output was not kept, and unlike the fields above it **cannot be recovered** — it depends on the token, which is not ours to replay. Re-running it takes about two minutes. Recorded as missing rather than assumed, because the whole point of the test is what the token *cannot* reach.

### 2026-09-05 — assignment costs runner time, not subscription usage

**run `33971250162`** — assigning an issue whose body contains `@claude` starts a runner but never starts Claude: `No trigger found, skipping remaining steps`, zero turns, 16s, exits green. The action only reads an issue body for the trigger phrase on `opened`.

## Caveats

- Allowance sizes are user-inferred; no vendor has confirmed them.
- Several reports reach us through third-party trackers; the forum threads marked "primary" were read directly.
- Both products change weekly. Re-verify before each build phase.

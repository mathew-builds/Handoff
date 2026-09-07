# Routine — PR ready (attach to whichever bot owns reporting)

**Which bot owns it:** in Phase 1 the only bot that exists is **Coder**, so attach it there. From Phase 2, once a Chief of Staff exists, move it — reporting is its job, and Coder should not also announce what the routine announces.

**Trigger:** GitHub event → pull request opened (or ready for review) on `OWNER/REPO`.
**Schedule:** none (event-driven only). Do not add a polling schedule.

**Routines are created conversationally, not from a form** — Grok Bot has no routine-creation dialog, so you set one up by *messaging the bot that will own it*. That does **not** mean improvise. Send the message below verbatim. Creating and editing routines is **desktop-only**; the mobile app can review, pause and resume, nothing more.

## The message to send

Paste this to the bot that will own the routine — in Phase 1, **Coder**. Replace `OWNER/REPO`.

```text
Create a routine for yourself with these settings. Confirm them back to me
before you save it.

Name: PR ready

Trigger: a pull request is opened on the GitHub repository OWNER/REPO.
Use your built-in GitHub connection for this trigger, not an inbound
webhook. If you can only do it with a webhook, stop and tell me before
setting anything up.

Schedule: none. This is event-driven only. Do not add a polling schedule.

When it fires: read the pull request's title, the linked issue number if
there is one, and its CI status. Then post exactly one line in this group
chat, in this format:

PR <number> ready — tests <green|red|pending> — <link>

Never do these:
- Do not review the code.
- Do not comment on GitHub.
- Do not tag other bots.
- Do not post anything else. One line, once per pull request.

Before saving, tell me back: which bot owns this routine, what triggers
it, which repository it watches, exactly what it will post, and what it
is allowed to do without asking me first.
```

**Check the five things it reads back before you let it save.** If it names a different owner, a webhook trigger, the wrong repository, or claims it may do anything beyond posting that one line, correct it and make it confirm again. The read-back is the only point where a misconfigured routine is cheap to fix.

**Two triggers can carry a GitHub event, and they are different things:**

| | What it is | Caveat |
|---|---|---|
| **Cursor account integration** | A native GitHub trigger. *"can start a routine from an event, such as a Slack message or a GitHub notification"* — <https://docs.x.ai/grok-bot/skills-routines-and-automations>, read 2026-09-07. | As we read the same page, these integrations are separate from the Slack or GitHub plugins and may need their own connection flow. **Which GitHub events fire it is not documented** — the page says "a GitHub notification", not "pull_request opened". Verify yours does before relying on it. |
| **Inbound webhook** | The routine exposes a POST URL and a sender key; point a GitHub Actions step or repo webhook at it. | **Not in any vendor documentation** — confirmed only by Cursor staff on the forum, and desktop-only (the URL does not appear on iOS). Newest and roughest surface. |

**Instruction to the bot:**
> A pull request was opened on OWNER/REPO. Read the PR title, the linked issue number if present, and the CI status. Post exactly one line in the group chat:
> `PR <number> ready — tests <green|red|pending> — <link>`
> Do not review the code. Do not comment on GitHub. Do not tag other bots.

There is no channel to name — Grok Bot's primitive is a **group chat**, and the routine posts into the one its owning bot is in.

> **Expect `tests pending` almost every time, and that is not a fault.** The routine fires on `pull_request opened`; checks are still queued at that instant. Verified 2026-09-06 — both test passes reported `pending`, and the bot flagged the reason before we ran them: *"since it only fires when the PR opens, CI will often still be `pending` at that moment."*
>
> If the CI result is what you actually want, trigger on **check completion** rather than pull-request-opened. That is a different routine and we have **not** tested it. Reporting `pending` promptly and reporting `green` late are different products — pick deliberately.

## ⚠️ This may not run unattended — check before you trust it

Cursor staff have confirmed that **a webhook delivery is not treated as user intent**, so predeclared outbound actions from a webhook-triggered routine *still raise an approval card*. Standing routine instructions do not count as intent.

If that applies to posting into a group chat, this routine will **wait for you to tap approve** rather than reporting on its own — which defeats its purpose. Test it before building anything on top.

**That warning is about the webhook trigger.** On the **built-in GitHub connection** — the one the message block above tells you to use — this routine has been observed reporting unattended, with no approval card (2026-09-06; details below). The webhook path is untested and the result does not transfer to it. Run both passes on whichever trigger you actually chose.

**Run two passes. They answer different questions, and only the second one tests live operation.**

| Pass | How you open the PR | What it answers |
|---|---|---|
| 1 | **By hand**, from your own account | Does the report arrive without you tapping approve? Isolates the approval question. |
| 2 | **By the bridge** — open an issue starting with `@claude`, let the action run and let `github-actions` open the PR | Does the routine fire for the actor that will open every real PR? Isolates the trigger question. |

For each pass: set the routine up, open the PR, then watch **without touching the app** for five minutes. A report appearing unprompted is a pass; an approval card instead means the return path is not unattended.

> **Do not stop after pass 1.** A PR you open by hand comes from your own account; every PR in live operation is opened by `github-actions` using the workflow's `GITHUB_TOKEN`. Passing pass 1 and skipping pass 2 proves nothing about the path that matters — that is exactly the mistake that produced issue 61, where a hand-pushed branch made a broken workflow look like it worked, twice.

**What each pass settles, and what neither does.** Pass 1 isolates the approval question. Pass 2 isolates the trigger question — whether the routine fires for `github-actions`, the actor that opens every real pull request. **Neither pass tests webhook delivery.**

**What the Handoff project observed on its own trial repo, 2026-09-06.** A pull request opened by the workflow's `GITHUB_TOKEN` does generate a `pull_request opened` event — `actor=github-actions[bot]`, `action=opened`, read from the repository's events API. And on the bot's **built-in GitHub connection**, both passes reported into the group chat **unattended, with no approval card**. That is a contrast rather than an inference: earlier in the same conversation, *saving* the routine did raise an approval card and waited for a tap, so the chat demonstrably renders them.

**Still unverified by either pass:** whether a `pull_request` event is delivered to an **inbound webhook** subscriber, and whether a webhook-triggered report is approval-gated. No webhook has ever been configured on that repo, so nothing was delivered and nothing was observed. If your routine uses the webhook trigger, your own pass 2 answers it for your setup — ours does not, and the result above does not carry over to it.

If it is gated, the options are: an "Always allow" Auto Review rule scoped narrowly to posting in that one group chat (remembering an admin cannot enforce Auto Review and rules do not sync between your machines), or accept a tap per pull request, or use the native Cursor integration trigger instead of a webhook and re-test.

**Notes**
- A bot can own up to **50 routines**, and the app keeps the **20 most recent run records** for each. One routine per event type is enough.
- **A test run performs real work** — it navigates sites, changes files and calls connected tools. It is not a dry run.
- Routines may auto-pause after inactivity (*"a long period away"* — the threshold is not documented). If reports stop, check the routine is enabled before debugging anything else.
- Deleting a routine is immediate with no undo, and deleting a bot deletes the routines it owns.

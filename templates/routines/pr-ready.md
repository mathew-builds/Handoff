# Routine — PR ready (attach to the Chief of Staff bot)

**Trigger:** GitHub event → pull request opened (or ready for review) on `OWNER/REPO`.
**Schedule:** none (event-driven only). Do not add a polling schedule.

**Routines are created conversationally, not from a form.** Ask the bot that should own the job, in plain language, then confirm: owning bot, trigger, matching rule (repo), expected result, and the approval boundary. Creating and editing routines is **desktop-only** — the mobile app can review, pause and resume, nothing more.

**Two triggers can carry a GitHub event, and they are different things:**

| | What it is | Caveat |
|---|---|---|
| **Cursor account integration** | A native GitHub trigger. *"Cursor account integrations can start a routine from an event, such as a Slack message or a GitHub notification."* | *"They are separate from Slack or GitHub plugins and may require their own connection flow."* **Which GitHub events fire it is not documented** — the docs say "a GitHub notification", not "pull_request opened". Verify yours does before relying on it. |
| **Inbound webhook** | The routine exposes a POST URL and a sender key; point a GitHub Actions step or repo webhook at it. | **Not in any vendor documentation** — confirmed only by Cursor staff on the forum, and desktop-only (the URL does not appear on iOS). Newest and roughest surface. |

**Instruction to the bot:**
> A pull request was opened on OWNER/REPO. Read the PR title, the linked issue number if present, and the CI status. Post exactly one line in the `#<project>` channel:
> `PR #<number> ready — tests <green|red|pending> — <link>`
> Do not review the code. Do not comment on GitHub. Do not tag other bots.

**Test run:** open a throwaway PR by hand. The routine should post within a few minutes. Then close the PR.

## ⚠️ This may not run unattended — check before you trust it

Cursor staff have confirmed that **a webhook delivery is not treated as user intent**, so predeclared outbound actions from a webhook-triggered routine *still raise an approval card*. Standing routine instructions do not count as intent.

If that applies to posting into a group chat, this routine will **wait for you to tap approve** rather than reporting on its own — which defeats its purpose. Test it before building anything on top:

1. Set the routine up.
2. Open a throwaway pull request by hand.
3. Watch **without touching the app** for five minutes.
4. If a report appears unprompted, you are fine. If an approval card appears instead, the return path is not unattended.

If it is gated, the options are: an "Always allow" Auto Review rule scoped narrowly to posting in that one group chat (remembering an admin cannot enforce Auto Review and rules do not sync between your machines), or accept a tap per pull request, or use the native Cursor integration trigger instead of a webhook and re-test.

**Notes**
- A bot can own up to **50 routines**, and the app keeps the **20 most recent run records** for each. One routine per event type is enough.
- **A test run performs real work** — it navigates sites, changes files and calls connected tools. It is not a dry run.
- Routines may auto-pause after inactivity (*"a long period away"* — the threshold is not documented). If reports stop, check the routine is enabled before debugging anything else.
- Deleting a routine is immediate with no undo, and deleting a bot deletes the routines it owns.

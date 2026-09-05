# Routine — PR ready (attach to the Chief of Staff bot)

**Trigger:** GitHub event → pull request opened (or ready for review) on `OWNER/REPO`.
**Schedule:** none (event-driven only). Do not add a polling schedule.

**Instruction to the bot:**
> A pull request was opened on OWNER/REPO. Read the PR title, the linked issue number if present, and the CI status. Post exactly one line in the `#<project>` channel:
> `PR #<number> ready — tests <green|red|pending> — <link>`
> Do not review the code. Do not comment on GitHub. Do not tag other bots.

**Test run:** open a throwaway PR by hand. The routine should post within a few minutes. Then close the PR.

**Notes**
- Routines are capped per bot and the app keeps only recent run records; one routine per event type is enough.
- Routines may pause after long inactivity. If reports stop, check the routine is enabled before debugging anything else.

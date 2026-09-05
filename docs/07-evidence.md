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

1. Bot-to-bot loops in channels
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

## Caveats

- Allowance sizes are user-inferred; no vendor has confirmed them.
- Several reports reach us through third-party trackers; the forum threads marked "primary" were read directly.
- Both products change weekly. Re-verify before each build phase.

# 00 — Overview

## Why this exists

Grok Bot (xAI + Cursor) is a good command centre: a persistent cloud computer, a chief-of-staff pattern, group chats, routines, browser reach. It is a poor place to *do* engineering:

- Usage is a **weekly** allowance published only as a per-plan ranking — "Highest weekly usage", "Generous weekly usage, below Ultra", "Weekly usage, below Pro+" — and never as a number (Cursor's Grok Bot plans page, read 2026-09-07).
- There is **no model picker** — the router can serve expensive models for simple work.
- There is **no Grok Bot-specific spend cap**; when the pool empties, usage continues on shared on-demand spend *if you have that enabled*. The account-wide on-demand limit is the only brake, and you can set it to `$0`.
- Coding loops, bot-to-bot chatter and short-interval routines are the fastest drains (staff-confirmed on the Cursor forum, Sep 2026).

Claude Code on a Claude Max plan is the opposite where it counts: flat monthly price, your choice of
model, and it runs your tests. It is also missing most of what makes Grok Bot a good command
centre — which is the whole reason this is a bridge and not a replacement.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../assets/handoff-gaps-dark.svg">
  <img src="../assets/handoff-gaps-light.svg" width="660" alt="Grok Bot is good at group chats, a chief-of-staff pattern, unattended routines, a persistent cloud computer and browser reach, but for coding it lacks a published allowance size, a model picker and a product-specific spend cap, and gives all your bots one shared computer. Claude Code on the Action has a flat monthly price, your choice of model, generous rolling limits and runs your tests, but it has no chat or phone surface of its own, no memory across tasks, no mid-run decisions, is unattended-only, and needs a GitHub repository. Each column's missing row is the other column's good-at row.">
</picture>

**Neither product is being criticised here.** Every "Missing" entry above is sourced: Grok Bot's from
the vendor's own documentation (`07-evidence.md`, re-verified against the live pages 2026-09-07),
Claude Code's from this repository's own "what it is not" list. They are not defects — they are the
shape of two tools built for different jobs.

*(Three claims were removed from this section on 2026-09-07, all for the same reason. "The best
terminal coding agent available" and "generous rolling limits" are adjectives with nothing behind
them, and this project does not get to make those. "Public beta since 11 Aug 2026" was a specific
vendor date with no source anywhere in this repository; the vendor's own overview page does not
carry one either (read 2026-09-07), so the date is gone rather than guessed at. The gaps diagram
above still shows "Generous rolling limits" — that text has not been re-cut yet.)*

**This project moves coding — and only coding — from the first meter to the second.**

## The thesis

> The cheapest, most reliable bridge between two products that both speak GitHub is GitHub.

No VPS, no tunnel, no MCP connector, no message bus. An issue goes in; a pull request comes out.

## What it is

- A workflow file for the official Claude Code GitHub Action, authenticated with a subscription OAuth token.
- A `CLAUDE.md` template for consumer repos.
- Bot descriptions for Grok Bot (Chief of Staff, Coder) and a routine template for the return path.
- Auto Review rules that add a confirmation step before irreversible actions — written (`templates/auto-review-rules.md`), **not yet exercised** (task 2.2, parked).
- Docs, runbooks and a task backlog.

## What it is not

- Not a hosted service. Every user runs their own copy with their own tokens.
- Not a persistent agent session. Each task starts fresh; the repo and the issue thread are the memory.
- Not a replacement for using Claude Code interactively. You keep doing that. This handles the unattended work.
- Not a security product. It reduces blast radius by design (see `05-security.md`); it does not make Grok Bot's shared computer safe.

## Who it is for

Solo operators and small teams who already pay for Claude Max, want Grok Bot as their operations layer, and run several engineering tasks a day on scripts, integrations, data pipelines and internal tools.

## Non-goals (for v1)

- Persistent multi-agent crews (firstmate-style). Parked; see `06-roadmap.md`.
- Permission relay to chat. The PR is the gate.
- Self-hosted runners, VPS, Kubernetes, observability stacks. All parked until a concrete need appears.

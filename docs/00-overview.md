# 00 — Overview

## Why this exists

Grok Bot (xAI + Cursor, public beta since 11 Aug 2026) is a good command centre: a persistent cloud computer, a chief-of-staff pattern, group chats, routines, browser reach. It is a poor place to *do* engineering:

- Usage is a **weekly** allowance whose size is unpublished.
- There is **no model picker** — the router can serve expensive models for simple work.
- There is **no Grok Bot-specific spend cap**; when the pool empties it spills into paid on-demand and credits.
- Coding loops, bot-to-bot chatter and short-interval routines are the fastest drains (staff-confirmed on the Cursor forum, Sep 2026).

Claude Code on a Claude Max plan is the opposite: flat monthly price, your choice of model, generous rolling limits, and the best terminal coding agent available.

**This project moves coding — and only coding — from the first meter to the second.**

## The thesis

> The cheapest, most reliable bridge between two products that both speak GitHub is GitHub.

No VPS, no tunnel, no MCP connector, no message bus. An issue goes in; a pull request comes out.

## What it is

- A workflow file for the official Claude Code GitHub Action, authenticated with a subscription OAuth token.
- A `CLAUDE.md` template for consumer repos.
- Bot descriptions for Grok Bot (Chief of Staff, Coder) and a routine template for the return path.
- Auto Review rules so nothing irreversible happens without you.
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

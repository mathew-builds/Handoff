# Auto Review rules (Grok Bot → Settings → Auto Review)

Add these as **Require approval** rules. "Require approval" always wins over "Always allow", so these are safe to add alongside any allow rules.

| Rule | Matches | Why |
|---|---|---|
| Require approval before sending any email or message to an external address | send, email, reply-all, external | Irreversible, reputational |
| Require approval before any purchase, payment, or plan change | pay, buy, subscribe, checkout | Money |
| Require approval before posting publicly | post, publish, tweet, comment on public site | Reputational |
| Require approval before changing any production system or account setting | deploy, delete, rotate, settings, admin | Blast radius |
| Require approval before merging any pull request | merge | The PR is the human gate; keep it human |

Also set, outside Grok Bot:
- **Cursor account on-demand limit: $0** (or a small amount). This is the only brake on weekly-allowance spillover.
- **In every bot's description**: "At most three rounds of bot-to-bot discussion before reporting to me."

  Grok Bot has no "channel charter". The vendor primitive is a **group chat** of 2–6 bots with **no instructions field** — step four of creating one is just your first message. The only durable instruction surface is each bot's own description, which is exactly what it is for: *"Use the conversation for task-specific instructions. Use the description for rules that should remain true."*

**Two limits on Auto Review worth knowing before you rely on it.**

1. **An admin cannot force it on.** As we read it, each member's own Auto Review setting is the off switch, and there is no organisation-level lock. Personal rules are stored per desktop install and do not sync — verify them on every machine you use.
2. **It is model-based, and does not cover everything.** As we read it, Auto Review is model-based and is meant to complement least privilege rather than replace it, and it does not review every side effect — memory writes and most settings changes being the examples given.

> **Unverified, 2026-09-07.** The two points above were quotations in earlier drafts. We hold no
> URL for either, and searching the vendor pages we could fetch did not turn up the wording, so
> they are our reading of the documentation rather than the vendor's words. Treat them as a
> prompt to check the current settings yourself, not as a citation. A quotation nobody can look
> up is worse than a plain statement of what we understood.

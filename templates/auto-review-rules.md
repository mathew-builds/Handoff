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
- In every channel charter: "At most three rounds of bot-to-bot discussion before reporting to me."

<p align="center">
  <img src="assets/handoff-banner.svg" alt="Handoff — no server, no tunnel, no second meter" width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-2C6B4F.svg"></a>
  <a href="../../actions/workflows/ci.yml"><img alt="CI" src="../../actions/workflows/ci.yml/badge.svg"></a>
  <a href="AGENTS.md"><img alt="Agent-installable" src="https://img.shields.io/badge/setup-agent--installable-9A6614.svg"></a>
  <img alt="Servers required" src="https://img.shields.io/badge/servers%20required-0-2C6B4F.svg">
</p>

# Handoff

**Let your chat agent delegate coding to your coding agent — over GitHub, billed to a subscription instead of per token.**

**No server. No tunnel. No second billing pool. No coding login on a shared computer.** Every other way we found needs at least one of the four.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/handoff-chains-dark.svg">
  <img src="assets/handoff-chains-light.svg" width="660" alt="Five ways to delegate coding from a chat agent to a coding agent. Locum and MCP connectors need a tunnel to a machine of yours. SSH or a VPS session needs a server you maintain. Cursor Cloud Agents needs a second billing pool. Installing the coding CLI on the bot's own computer puts your login on a shared machine. Handoff needs only a GitHub issue.">
</picture>

Everybody builds the same chain. **The argument is only ever about the middle box.**

The fourth row is why this list says *four* and not three. Installing the coding CLI straight onto
the bot's computer needs no server, no tunnel and no second pool — it beats the other three on every
axis. What it costs is putting your coding credential on a machine [05-security.md](docs/05-security.md)
tells you to assume is compromised and shared with every other bot on the account, and packages
installed there are wiped on image updates. We would rather state the axis than quietly omit the
approach that dodges the other three.

Named alternatives, what each one actually requires, and the cost Handoff *does* add — GitHub
Actions minutes, which we cannot yet price — are in [07-evidence.md](docs/07-evidence.md). **Every
alternative there is scored from its documentation, not from running it.** Handoff is the only one
we have run end to end.

> **Status: the bridge works end to end. The project is not finished.** An issue becomes a reviewable pull request, and the result reports itself back into a group chat — both watched happening on 2026-09-06, not read out of vendor docs. What is still open is unticked in [TASKS.md](TASKS.md) — the token-scope control test, a fresh-eyes install, and, in the **Post-1.0** section, two defects found after the release. Every claim below links to the run that produced it — see [07-evidence.md](docs/07-evidence.md).

> **Setting this up with an AI agent?** Point it at **[AGENTS.md](AGENTS.md)** — the install guide written for agents rather than people. It covers what the agent can do on its own, the **two** steps it cannot do and must hand back to you, the **one** it must ask you about first, and how to check the result. Handing your agent this repository's URL and saying "set this up" is a supported way to install Handoff.

## Works with

Named in text, not logos — these are other companies' trademarks, and Handoff is not affiliated with or endorsed by any of them.

| | Chat side | Coding side |
|---|---|---|
| **Supported today** | Grok Bot (xAI / Cursor) | Claude Code |
| **Designed for, not yet built** | any chat agent that can open a GitHub issue | any coding agent with a GitHub Action |

Nothing in the bridge is vendor-specific: it is a GitHub issue in, a pull request out. Adding a coding agent means a different workflow file, not a different design.

## Two layers. The first one is the product.

**Layer 1 — the bridge.** Open a GitHub issue containing `@claude`. The official Claude Code Action runs on a GitHub-hosted runner, authenticated with your **Claude subscription token** rather than an API key. It reads the issue, edits, runs your tests, pushes a branch, and a later step in the same workflow opens the pull request. You review and merge.

**This needs no chat bot at all.** A Claude subscription, a GitHub repo, and one workflow file.

**Layer 2 — the command centre (optional).** Point [Grok Bot](https://x.ai/bot) at the same repo and a chat message becomes the issue, and the finished pull request reports itself back into your group chat. Useful if you already pay for Grok Bot and want to brief work from your phone. **Skip it and layer 1 still works.**

## Why layer 1 exists

Coding agents that bill per token get expensive in a way you cannot see until the invoice. Grok Bot in particular meters coding on a **weekly** allowance published only as a per-plan ranking and never as a number (Cursor's Grok Bot plans page, read 2026-09-07), with **no model picker** — billing follows whichever model the router serves — and **no Grok Bot-specific spend cap**. When the weekly pool is exhausted, usage continues on shared on-demand spend *if you have that enabled*; you can set the account-wide on-demand limit to `$0`, and [the setup guide](docs/03-setup-guide.md) tells you to. A Claude Pro/Max subscription bills at a flat rate on a model you choose.

Each of those is a vendor-documented fact with a source in [07-evidence.md](docs/07-evidence.md) — **not** a measurement. We have never measured a Grok Bot allowance, and this project does not claim to.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/handoff-drains-dark.svg">
  <img src="assets/handoff-drains-light.svg" width="660" alt="What drains a Grok Bot weekly allowance fastest, ranked: one, bots talking to each other in group chats; two, short-interval routines; three, long coding and agent loops; four, browser and computer-use sessions. Handoff moves only number three and does not fix the other three.">
</picture>

**Read that honestly: Handoff moves number three, and the thing people complain about most is number
one.** If your allowance is draining, the most likely cause is bots talking to each other in a group
chat — one forum report on 4 Sep 2026 describes five agents doing that unattended for seven hours.
**Handoff will not fix that.** That is a bot-configuration problem, and
[04-operations.md](docs/04-operations.md) R4 is the runbook for it.

What coding has that the other three do not is a clean flat-rate home elsewhere. That is the whole
reason this project moves coding and leaves the rest alone.

This moves exactly one category of work — code — across that billing boundary, and nothing else.

**Measured, not asserted:** one real task — issue in, reviewable pull request out — took **61 seconds** and **9 of 25** allowed turns, on 2026-09-06. **$0.00** of pay-as-you-go spend was confirmed on the Anthropic Console for a different run, on 2026-09-05; the Console has not been re-read since. Two runs, two dates — see [08-measurements.md](docs/08-measurements.md).

## What you need

| | Required? | Why |
|---|---|---|
| A **Claude** Pro, Max, Team or Enterprise subscription | **Yes** | Pays for the coding. Generate the token with `claude setup-token`. |
| A **GitHub** account and a repository | **Yes** | The bridge. Actions minutes are the only other cost, and one task above used ~60s. |
| A **Grok Bot** (Cursor) subscription | **No** | Layer 2 only. Everything in layer 1 works without it. |
| A server | **No** | There isn't one. That is the point. |

## How it works

```mermaid
flowchart LR
    subgraph GH["GitHub — layer 1, the bridge"]
        ISSUE[Issue 212<br/>@claude ...]
        ACTION[claude-code-action<br/>on a GitHub-hosted runner]
        BRANCH[branch claude/issue-212]
        PR[PR 213<br/><i>opened by a later step in the same workflow</i>]
        ISSUE --> ACTION --> BRANCH --> PR
    end

    subgraph CC["Claude Code"]
        MAX[(Claude subscription<br/>OAuth token)]
    end

    subgraph GB["Grok Bot — layer 2, optional"]
        YOU(["You — in chat"]) --> CODER[Coder<br/><i>never writes code</i>]
    end

    YOU2(["You — on GitHub"]) -- "or just open the issue yourself" --> ISSUE
    CODER -- "opens issue" --> ISSUE
    ACTION -. "authenticates with" .-> MAX
    PR -- "PR event, routine reports it" --> CODER
    YOU2 -- "review + merge" --> PR
```

Both `You` boxes are the same person — Mermaid puts a node in one subgraph only, so briefing from
chat and reviewing on GitHub have to be drawn separately.

<!-- Deliberately no classDef / style / %%{init}%% in this diagram. GitHub picks Mermaid's theme
     from the reader's colour mode; hard-coded hex is fixed paint in BOTH modes, so a light fill
     gets dark-mode's light text on top of it. Colour-free Mermaid is theme-correct for free.
     Verified 2026-09-07 against GitHub's deployed mermaidMarkdown bundle. -->



**Layer 1, which is all you need:**

1. Open an issue containing `@claude` and a clear brief. Yourself, from GitHub.
2. The official [Claude Code GitHub Action](https://code.claude.com/docs/en/github-actions) runs on a GitHub-hosted runner, authenticated with your **Claude subscription OAuth token** — not an API key.
3. Claude Code reads the issue, edits, runs tests, and **pushes a branch**. It does not open the pull request — the action has no tool for that. A later step in the *same* workflow opens it, which costs no model turns and makes the `pull_request opened` event fire.
4. You review and merge. **The merge is the approval.**

**Layer 2, if you want it:**

5. A **Coder** bot writes step 1's issue from a one-line ask, and never writes code itself.
6. A Grok Bot **routine** catches the pull-request event and reports it back into your group chat, unprompted.

Both layer 2 steps are proven — see the runs in [07-evidence.md](docs/07-evidence.md) — but they are additions, not prerequisites.

## What you get

| | |
|---|---|
| Servers to run | **0** |
| Who pays for the code | your Claude subscription — **$0.00** metered spend, confirmed on the Console on 2026-09-05 |
| Approval gate | your merge |
| Who can spend your Claude subscription | only accounts with repo write access — the action fails the run for anyone else. Anyone who can open an issue can still start a runner, so Actions minutes are not gated |
| Measured task time | **61s** issue to pull request, 9 of 25 turns (2026-09-06) |

**On prompt injection:** the write-access check is *not* an injection defence, and this project used to claim it was. It controls who can start a run; it does not control what text reaches Claude. A comment from someone with no write access is still in the prompt when someone with write access says `@claude`. See [05-security.md](docs/05-security.md) for what actually contains it.

## Your subscription, and Anthropic's terms

Handoff runs the **official, first-party** [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action) with a subscription OAuth token you generate yourself using `claude setup-token` — the path Anthropic documents for Pro and Max users. **There is no Handoff service, no Handoff app and no Handoff server.** Your token goes into your own repository's secrets and is read by Anthropic's own action inside your own repository. Nothing is routed through anything of ours, because there is nothing of ours to route it through.

That distinction is the one Anthropic's [legal and compliance page](https://code.claude.com/docs/en/legal-and-compliance) draws. Quoted verbatim, read **2026-09-07**:

> **OAuth authentication** is intended exclusively for purchasers of Claude Free, Pro, Max, Team, and Enterprise subscription plans and is designed to support ordinary use of Claude Code and other native Anthropic applications.

> Anthropic does not permit third-party developers to offer Claude.ai login into their own applications, or to route requests through Free, Pro, or Max plan credentials on behalf of their users.

The same page states that this does not "prevent an end user from signing in to the unmodified Claude Code binary with their own Claude subscription". Handoff is a workflow file you copy: you sign in, with your own credentials, in your own repository, and the usage is billed to you.

**Two caveats ship with that, and they are not footnotes.** Both verbatim from the same page:

> Advertised usage limits for Pro and Max plans assume ordinary, individual usage of Claude Code and the Agent SDK.

> Anthropic reserves the right to take measures to enforce these restrictions and may do so without prior notice.

So **do not point this at a 24/7 loop.** The three cost brakes exist for this reason as much as for cost — a `concurrency` group, a `timeout-minutes`, and `--max-turns`, with a check that fails the build if any of them is removed. They are there to keep usage ordinary.

**On the alternatives.** Some tools in this space put a subscription OAuth token into a server of their own. This project describes what each tool does and quotes the vendor; it does not draw legal conclusions about anyone else's product, and it has run none of them — every alternative in [07-evidence.md](docs/07-evidence.md) is scored from its documentation.

**On the name.** Anthropic's terms permit saying plainly that a product runs Claude Code, but not using the Claude or Anthropic names or logos as part of a product's own name or logo. That is why this is called Handoff.

None of the above is legal advice, and none of it is a statement on Anthropic's behalf. It is a description of what Handoff does, with the vendor's own words next to it and the date they were read. Check the page yourself — it can change, and this section carries a date so you can tell when it was last verified.

## Honest limits

This project's history is confident claims that turned out to be false — four load-bearing ones, one of them repeated across seventeen places in the docs, all rewritten rather than patched after being checked. The record is the **Correction** entries in [02-decisions.md](docs/02-decisions.md) and `git log --grep=correct`. So:

- **Never run against a large or complex codebase.** Every measurement here comes from a small trial repo. A real project will look different and we have not measured one.
- **The report-back in layer 2 usually says `tests pending`** — by design. It fires when the pull request opens, while checks are still queued.
- **One run per test.** Nothing here speaks to reliability over weeks.
- **Multi-repo routing is handled by refusing, not by guessing better.** Drive several projects from one bot and it has to pick which one a request belongs to. Every issue therefore declares `Repo: OWNER/NAME`, and the workflow **refuses to run if that names a different repository** — it comments and stops before Claude reads anything, so a wrong guess costs seconds rather than a review cycle on the wrong codebase. No `Repo:` line means no check, so single-repo installs are unaffected. Proven against six cases (D14); **not yet run live across two real repositories.** Cost reporting is still per-repo, so N projects give N reports and no total. See [01-architecture.md](docs/01-architecture.md#running-this-on-more-than-one-repository).
- Anything not verified by a run says so, in [07-evidence.md](docs/07-evidence.md).

## Quick start

> Doing this by hand? You are in the right place. Handing it to an agent? → **[AGENTS.md](AGENTS.md)**. Same install, two audiences.

See [docs/03-setup-guide.md](docs/03-setup-guide.md) — it has the checks at each step. Short version:

```bash
# 0. Get Handoff itself. The copies below read from it.
git clone <URL of this repository> ~/handoff

# 1. In the repo you want Claude to work on.
#    setup-token opens a browser; copy what it prints, then paste at the prompt.
#    Do NOT wrap it in $(...) — that swallows the browser flow.
claude setup-token
gh secret set CLAUDE_CODE_OAUTH_TOKEN

mkdir -p .github/workflows
cp ~/handoff/templates/claude.yml .github/workflows/claude.yml
# Only if the repo has no CLAUDE.md yet — this OVERWRITES:
cp ~/handoff/templates/CLAUDE.md.template CLAUDE.md

# …or skip the two copies and let the script do them:
bash ~/handoff/scripts/setup.sh

# 2. Install the Claude GitHub App: https://github.com/apps/claude
# 3. Settings -> Actions -> General -> tick
#    "Allow GitHub Actions to create and approve pull requests" (off by default)
# 4. Open an issue containing "@claude" from your own account. Get a PR back.
# 5. Only then: a fine-grained token on your own account, Issues-only, one repo
#    (setup guide Step 3), then the Coder bot. A dedicated machine account is a
#    later attribution upgrade, not a prerequisite — see D5a.
```

## Optional extras

| File | What it adds |
|---|---|
| [`templates/weekly-cost.yml`](templates/weekly-cost.yml) | A Monday report on a labelled issue: pull requests merged, how many runs it took, runner time per merged pull request. **Uses no model turns** — it is `gh` and `awk`, not an agent. Copy it next to `claude.yml` if you want it. |

## Documentation

| Doc | What it answers |
|---|---|
| [00-overview](docs/00-overview.md) | Why this exists, what it is not |
| [01-architecture](docs/01-architecture.md) | Components, flows, boundaries — with diagrams |
| [02-decisions](docs/02-decisions.md) | Every architectural choice and the alternative it beat |
| [03-setup-guide](docs/03-setup-guide.md) | Step-by-step, with verification at each step |
| [04-operations](docs/04-operations.md) | Meters, brakes, monitoring, runbooks |
| [05-security](docs/05-security.md) | Threat model, what lives where |
| [06-roadmap](docs/06-roadmap.md) | Phases, acceptance tests, when a server comes back |
| [07-evidence](docs/07-evidence.md) | The research behind the pain point, and our own runs |
| [08-measurements](docs/08-measurements.md) | What a real task actually cost |
| [09-second-agent-design](docs/09-second-agent-design.md) | What a second coding agent would take — designed, **not built** |

**Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md) · **Release history:** [CHANGELOG.md](CHANGELOG.md) · **Installing with an agent:** [AGENTS.md](AGENTS.md)

## Licence

MIT. This is a template: every user runs it with their own tokens in their own repos. Nothing here routes anyone else's requests through your subscription.

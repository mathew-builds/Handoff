# 01 — Architecture

## Components

| Component | Runs where | Pays with | Job |
|---|---|---|---|
| **Chief of Staff** bot | Grok Bot cloud | Grok Bot weekly allowance | Your single point of contact. Delegates. Reports. |
| **Coder** bot | Grok Bot cloud | Grok Bot weekly allowance (a few turns per task) | Turns a request into a well-formed GitHub issue containing `@claude`. **Never writes code.** |
| **GitHub issue / PR** | GitHub | free | The task ledger, the conversation, the approval gate. |
| **claude-code-action** | GitHub-hosted runner | GitHub Actions minutes | Runs Claude Code against the repo when `@claude` is mentioned. |
| **Claude Code** | inside the action | **Claude Max OAuth token** | Reads the issue, edits, tests, **pushes a branch**. It has no tool to open a pull request. |
| **the PR step in `claude.yml`** | the same runner, after Claude | seconds | Opens the pull request the action does not. No model turns. See D12. |
| **PR-ready routine** | Grok Bot cloud | Grok Bot allowance (one turn) | Catches the PR event, tells the Chief of Staff. |
| **You** | phone / laptop | — | Review, merge, approve anything irreversible. |

## System view

```mermaid
flowchart LR
    subgraph GB["Layer 2 · Command centre — Grok Bot (optional)"]
        direction TB
        YOU([You]):::you
        COS[Chief of Staff]:::grok
        CODER[Coder<br/><i>opens issues, never codes</i>]:::coder
        RT[PR-ready routine]:::grok
        YOU --> COS
        COS --> CODER
        RT --> COS
    end

    subgraph GH["Layer 1 · Bridge and gate — GitHub"]
        direction TB
        ISSUE[/"Issue with @claude"/]:::gh
        RUN[["claude-code-action<br/>GitHub-hosted runner"]]:::gh
        PR[/"Pull request"/]:::gh
        CI[["Tests / CI"]]:::gh
        BR[/"branch claude/issue-N"/]:::gh
        OPR[["PR step in claude.yml"]]:::gh
        ISSUE --> RUN --> BR --> OPR --> PR --> CI
    end

    subgraph CS["Pays for the work — your Claude subscription"]
        CLAUDE[("Claude subscription<br/>OAuth token")]:::claude
    end

    CODER -- "① opens" --> ISSUE
    RUN -. "② bills to" .-> CLAUDE
    PR -- "③ PR event" --> RT
    COS -- "④ 'PR ready'" --> YOU
    YOU -- "⑤ review + merge" --> PR

    classDef you stroke:#2C6B4F
    classDef grok stroke:#2C4A7C
    classDef coder stroke:#B85A36,stroke-width:2px
    classDef gh stroke:#5C626B
    classDef claude stroke:#B85A36
```

**The layer numbers match the README, and until 2026-09-07 they did not.** This diagram used to
label GitHub `L2` and Grok Bot `L5`, while `README.md` calls GitHub **layer 1** and Grok Bot
**layer 2** — so the number *2* meant the opposite thing in the two files a reader is told to read
in that order. There is one scheme now: **layer 1 is the bridge, layer 2 is the optional command
centre**, exactly as the README says.

The `Researcher · Ops` box was also removed: `templates/bots/` ships `chief-of-staff.md` and
`coder.md` and nothing else, so it drew a component that does not exist.

## Sequence: one task, end to end

```mermaid
sequenceDiagram
    autonumber
    actor You
    participant CoS as Chief of Staff (Grok Bot)
    participant Coder as Coder bot (Grok Bot)
    participant GH as GitHub
    participant CC as Claude Code (Action)
    participant RT as PR-ready routine (Grok Bot)

    You->>CoS: "Our HubSpot sync broke overnight. Sort it out."
    CoS->>Coder: delegate (repo task)
    Coder->>GH: open issue 212 — "@claude fix field mapping in sync.py, tests must pass"
    GH->>CC: issue event → workflow starts (write-access check passes)
    CC->>CC: read issue + CLAUDE.md, edit, run tests
    CC->>GH: push branch, comment on issue 212 with summary and a PR link
    GH->>GH: the same workflow's next step opens PR 213
    GH-->>RT: pull_request opened event
    RT->>CoS: "PR 213 ready — tests green"
    CoS->>You: one-line report + link
    You->>GH: review, merge
    Note over You,GH: Your merge is the approval. Nothing reaches main without you.
```

Typical wall-clock: 1–2 min runner start + task time. Grok Bot spends ~3–5 turns total. Claude Max absorbs the rest.

## Billing boundary

```mermaid
flowchart LR
    subgraph M1["Meter 1 — Grok Bot weekly allowance<br/>(size unpublished; no product-specific cap)"]
        direction TB
        A[Chief of Staff turns] --> B[Coder writes the issue]
        C[Routine reports the PR]
    end
    subgraph M2["Meter 2 — Claude Max (flat monthly)"]
        direction LR
        D[Read repo] --> E[Edit files] --> F[Run tests] --> G[Push branch]
    end
    subgraph M3["Meter 3 — GitHub Actions minutes"]
        H[Runner time]
    end
    B == "the one arrow this project adds" ==> D
    G -. "PR event" .-> C
    H -. "runs alongside" .-> D
    style M1 stroke:#2C4A7C
    style M2 stroke:#B85A36
    style M3 stroke:#5C626B
```

The whole project is the arrow from B to D. Everything to the right of it used to be on Meter 1.

**On "no second meter", which the README says and this diagram appears to contradict.** There are
three meters here, so the claim needs its qualifier stated rather than assumed: Handoff adds no
second *model* meter — no per-token pool, no second agent subscription. Meter 3 is GitHub Actions
minutes, which is time on a runner, not tokens. The honest state of Meter 3 is that we cannot price
it: the timing API reports `billable_ms: 0` for every run on this repo, and whether that is a
free-tier allowance or an unpopulated field is **unresolved** (`08-measurements.md`). One measured
task used about 60 seconds of runner time. Anyone comparing Handoff to alternatives should count
Meter 3 as a real, small, unpriced cost rather than as nothing.

## State and memory

| Kind of state | Lives in |
|---|---|
| Task list | GitHub Issues (canonical). Notion, if used, is a view. |
| Conversation about a task | The issue thread. `@claude` follow-ups go there. |
| Repo conventions, rules, "tests must pass" | `CLAUDE.md` in the consumer repo |
| What Claude did | A **single comment** on the issue, which Claude overwrites as it works, plus the action logs. There is no Claude-authored PR description. |
| Bot behaviour | Bot descriptions in Grok Bot (versioned here under `templates/bots/`) |

There is no session state. That is a feature: nothing to back up, nothing to get stuck.

## Trust boundaries

```mermaid
flowchart LR
    subgraph U["Untrusted / shared"]
        GBVM["Grok Bot shared computer<br/>holds: a GitHub token for ONE repo"]
    end
    subgraph G["GitHub"]
        ISSUES["Issues API<br/>(write-access accounts only trigger Claude)"]
        SECRETS["Repo Secrets<br/>CLAUDE_CODE_OAUTH_TOKEN"]
    end
    subgraph T["Ephemeral runner — destroyed after each run"]
        RUNNER["Repo checkout + Claude Code<br/>ALSO holds a GitHub token<br/>with contents:write"]
    end
    GBVM -- "opens / comments on issues" --> ISSUES
    ISSUES -- "triggers workflow" --> RUNNER
    SECRETS -. "injected at run time" .-> RUNNER
    style U stroke:#A02B20
    style G stroke:#5C626B
    style T stroke:#2C6B4F
```

- The Grok Bot computer is shared by every bot on the account. It holds a GitHub token for one repo. **That token is a spam control, not a privilege control** — the action checks the *account's* write access, not the *token's* scope, so anyone holding it can start a full run. See D5 and `05-security.md`.
- The Claude OAuth token exists only in GitHub Secrets and the ephemeral runner.
- **The runner holds more than the Claude token.** It also gets a GitHub App installation token and the workflow's own `GITHUB_TOKEN`, which this template grants `contents: write`, `pull-requests: write`, `issues: write`, `id-token: write` and `actions: read` (`templates/claude.yml`). So a successful injection can push code, not merely spend quota.
- The action runs **two** checks on the triggering actor and **fails the run** when either rejects it: the account must have **write access**, and it must not be a bot (<https://code.claude.com/docs/en/github-actions> §"Who can trigger runs", read 2026-09-06). That stops strangers *spending your quota*. It does **not** stop prompt injection: every comment on the thread reaches Claude regardless of who wrote it, so a read-only account can plant text that Claude reads the next time someone with write access says `@claude`. See `05-security.md`.

See `05-security.md` for the full threat model.

## What this deliberately leaves out (and why)

| Left out | Why | Comes back when |
|---|---|---|
| VPS / persistent session | Not needed to move billing; adds a server to maintain | You need memory across tasks or private-network access |
| Permission relay to chat | The PR already gates every change | Tasks need mid-run human decisions |
| MCP connector / tunnel (Locum) | An extra moving part, and it needs a machine of yours kept awake | Never, in this design |
| Observability stack | GitHub Actions logs + two usage dashboards are enough | A client asks for reports |
| Self-hosted runner | Hosted runners are free enough and safer | Tasks exceed included minutes or need local tools |

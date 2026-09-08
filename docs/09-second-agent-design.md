# A second coding agent — design, not build

**Written 2026-09-07.** This is a design note. **Nothing here is implemented**, and the draft
workflow below is deliberately not a file in `templates/` — see [Why the draft is not a
file](#why-the-draft-is-not-a-file).

## Why this exists

Handoff's README says the bridge is not vendor-specific: "a GitHub issue in, a pull request out.
Adding a coding agent means a different workflow file, not a different design." That claim has never
been tested. This note tests it on paper and reports what it found, which is that the claim is
**mostly true and specifically wrong in three places.**

The reason to care is a risk on somebody else's schedule. Layer 2 — the chat-bot wedge — exists
because Grok Bot meters coding on a weekly allowance with no model picker and no per-bot spend cap.
If xAI ships any of those, that argument disappears overnight. A second coding agent widens the
pitch from a wedge to a category: *any chat agent, any coding agent, over GitHub*.

**We are not building it now** (D15). This note is the cheap half, so that if the trigger fires the
build is already specified rather than started from scratch.

---

## What is actually generic, and what is not

Read out of `templates/claude.yml` line by line on 2026-09-07, not assumed.

### Genuinely portable — no change needed

| Part | Why it survives a vendor swap |
|---|---|
| The four event triggers | `issues`, `issue_comment`, `pull_request_review`, `pull_request_review_comment` are GitHub's, not Anthropic's |
| `concurrency` group with `queue: max` | Pure GitHub semantics. The `queue: max` subtlety — without it GitHub keeps only one pending run per group and silently cancels the second — applies identically to any agent |
| `timeout-minutes: 30` | GitHub's wall-clock brake |
| **The misrouted-issue guard** | Reads the issue body and compares a `Repo:` line to `github.repository`. It runs before checkout and before any agent. **Zero vendor coupling** — it would work unchanged in front of any agent, and it is the single most reusable thing in the file |
| `actions/checkout` | Generic |

### Vendor-coupled — must change

| Part | The coupling |
|---|---|
| The trigger phrase | `@claude` appears four times in the `if:` expression. A second agent needs its own phrase, or the two workflows fight over the same one |
| The action reference | `anthropics/claude-code-action@v1` |
| The auth input | `claude_code_oauth_token` and the secret name `CLAUDE_CODE_OAUTH_TOKEN` |
| The cap syntax | `--max-turns` and `--allowedTools` are passed as `claude_args`. Both the flag names and the fact that they are one packed string are Anthropic's |
| `id-token: write` | Commented in the file as "required for the action's default GitHub App authentication". That is Anthropic's app, not a GitHub requirement |
| **`steps.claude.outputs.branch_name`** | The pull-request step is gated on it and reads the branch from it. **This is the sharpest dependency in the file** — see below |

---

## The three things that actually break

### 1. Our own cost-brake checker is hardcoded to one vendor

`scripts/check-workflow-caps.py` line 63:

```python
AGENT_PREFIX = "anthropics/"
```

A step counts as "runs the agent" only if it uses an action published by that owner. The comment
above it explains the reasoning, which was sound at the time: matching the exact repository name
meant a rename or fork silently disabled the brake, so it matches the owner instead.

**With a second vendor, that protection inverts into a hole — and this was reproduced, not
reasoned about.** On 2026-09-07 the checker was run in a scratch copy of the repository against a
`templates/codex.yml` that runs `some-other-vendor/coding-agent-action@v1` **with no turn cap of any
kind**. Verbatim output:

```
.github/workflows/ci.yml: concurrency group, timeout-minutes present
templates/claude.yml: concurrency group, timeout-minutes, --max-turns present
templates/codex.yml: concurrency group, timeout-minutes present
templates/weekly-cost.yml: concurrency group, timeout-minutes present
EXIT=0
```

An uncapped coding agent passed the build.

**Read the third line carefully, because the failure is subtler than the one this checker shipped
before.** It does *not* claim `--max-turns present` — it honestly lists only the two brakes it
verified. The bug in its own header comment was worse: that one asserted a brake it had not
checked. This one merely stays silent about brake 3 and exits 0, and `MUST_RUN_AGENT` names only
`templates/claude.yml`, so nothing fails loudly either.

That silence is still a hole, for the reason `CLAUDE.md` gives: **a check that reports instead of
failing reads as a pass.** Anyone scanning four green lines for the word "present" would have to
notice that one line is missing a term the others have.

> **Fixed 2026-09-08 (issue #106), and not the way this section proposed.** The suggestion above was
> a per-workflow vendor mapping. That was the wrong fix: it needs extending for every new agent and
> fails **silently** whenever somebody forgets — the original defect wearing a longer list. What
> shipped inverts the default instead. The cap is found by looking for the **brake** (`CAP_FLAGS`)
> rather than the vendor, and any workflow not explicitly declared turn-free in `NO_AGENT` must show
> one; unrecognised now means fail. Proven in both directions, test first. **The blocker on this
> document is therefore cleared** — a second workflow can land without turning brake 3 off.
>
> Line numbers deliberately removed from this section: they moved when the fix landed, and citing
> them again would only go stale again. Read the file.

### 2. The pull-request step depends on an output only Anthropic's action publishes

`templates/claude.yml` opens the PR itself because the action cannot (D12), and it finds the branch
via `steps.claude.outputs.branch_name`. A second agent must be checked for three things, in order:

1. **Does it open the pull request itself?** If yes, the whole step is skipped for that workflow and
   D12 does not apply to it. Do not port the step blindly.
2. **If not, does it push a branch and expose the name as an output?** If it exposes it under a
   different name, that is a one-line change.
3. **If it pushes a branch and publishes no output at all**, the step has to discover the branch
   some other way — and every option there is worse. Do not guess from a naming convention.

The D12 trap is worth restating because it cost this project a shipped bug (#61): the PR step
**cannot** be split into a separate `on: push` workflow. `actions/checkout` persists the workflow's
`GITHUB_TOKEN`, the agent's push is authenticated with it, and GitHub does not start workflow runs
from that token. It fires for a human's push, which is exactly why the broken version looked like it
worked.

### 3. Subscription billing is the whole premise, and it may not port at all

This is the one that decides whether a second agent is worth building.

Handoff's entire argument (D2) is that coding is billed to a **flat subscription** rather than
per-token. If a candidate agent's GitHub Action authenticates only with an API key, then wiring it
up produces a workflow file that moves work onto a *metered* pool. That is not Handoff. It is a
generic CI-runs-an-agent pattern, and the README's cost argument does not apply to it.

**So the first question to ask about any candidate is not "does it have an Action?" but "can it run
on a subscription the user already pays for?"** If the answer is no, the honest options are to skip
that vendor or to document plainly that layer 1's billing claim covers Claude only.

---

## Candidates — and what is not yet known about them

**Nothing in this table has been verified.** No candidate's documentation has been read for this
note and none has been run. Listing them with confident properties is exactly the failure this
repository was built to catch, so the columns record *what to check*, not what is true.

| Candidate | Why it is a candidate | Must verify before any work |
|---|---|---|
| OpenAI Codex | Widely used; plausible GitHub integration | Does an official first-party Action exist? Subscription auth or API key only? Branch output? Turn cap equivalent? |
| Grok's own build agent | Closes the loop — same vendor as the chat side | Same four questions. Note that if the chat and coding sides share one meter, it defeats the entire purpose |
| Google Gemini | Has a published CLI | Same four questions |

**The four questions, in the order that kills a candidate fastest:**

1. Can it authenticate with a subscription the user already pays for? *(If no, stop.)*
2. Is there an official first-party Action, or would we be wrapping a CLI ourselves? *(Wrapping is
   a different, much larger project and D2's reasoning about first-party actions applies.)*
3. Does it open the PR, or push a branch and publish the name?
4. Does it have a turn or cost cap we can enforce, equivalent to `--max-turns`?

A candidate that fails 1 is not a Handoff target. A candidate that fails 4 cannot ship under this
repo's own rules, because the cost brakes are non-negotiable (D10) and a check that cannot verify
them must fail loudly rather than pass quietly.

---

## The draft

### Why the draft is not a file

It is a fenced block in this document rather than `templates/codex.yml` on purpose: `.github/workflows/ci.yml`
globs `templates/*.yml` into an `actionlint` run, and `scripts/check-workflow-caps.py` globs the same
directory for cost brakes. A draft sitting there would have to be lint-clean and carry all three brakes
before anyone knows whether the vendor exists — and a reader cannot tell a draft from a supported
template, so `AGENTS.md` and the setup guide would have to explain which `.yml` files are real.

> **Corrected 2026-09-08.** This paragraph used to add that `scripts/setup.sh` "copies `templates/*.yml`
> into a consumer's repository", so a draft "would be installed into somebody's repo by an unmodified
> `setup.sh`". **That is false.** `setup.sh` copies two named files — `templates/claude.yml` and
> `templates/CLAUDE.md.template` — and contains no glob. The same fabricated mechanism appeared in D15
> and is corrected there too. The conclusion was right; one of its two reasons was invented.

Placeholders are written in `ANGLE_BRACKETS` so the file cannot be copied and run by accident.

```yaml
# DRAFT — NOT A WORKING WORKFLOW. See docs/09-second-agent-design.md.
# Every <PLACEHOLDER> below is an unanswered question, not a value.
name: <AGENT> Code

on:
  issue_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]
  pull_request_review_comment:
    types: [created]

concurrency:
  # Distinct prefix, or the two agents share a queue and cancel each other.
  group: <agent>-${{ github.event.issue.number || github.event.pull_request.number }}
  cancel-in-progress: false
  queue: max

jobs:
  agent:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@<agent>')) ||
      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@<agent>')) ||
      (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@<agent>')) ||
      (github.event_name == 'issues' && (contains(github.event.issue.body, '@<agent>') || contains(github.event.issue.title, '@<agent>')))
    runs-on: ubuntu-latest
    timeout-minutes: 30
    permissions:
      contents: write
      pull-requests: write
      issues: write
      actions: read
      # id-token: write   # ONLY if this vendor's action needs it. Do not copy blindly.
    steps:
      # Lift the misrouted-issue guard from templates/claude.yml VERBATIM.
      # It has no vendor coupling. Do not rewrite it — it is tested in both
      # directions by scripts/test-scripts.sh and the tests are not decoration.
      # The refusal comment must never contain this workflow's trigger phrase,
      # or the workflow restarts itself forever.

      - uses: actions/checkout@v6
        with:
          fetch-depth: 1

      - name: Run <AGENT>
        id: agent
        uses: <VENDOR>/<ACTION>@<VERSION>
        with:
          <SUBSCRIPTION_TOKEN_INPUT>: ${{ secrets.<AGENT>_TOKEN }}
          # A turn cap is MANDATORY. If this vendor has no equivalent of
          # --max-turns, this workflow cannot ship (D10) until
          # check-workflow-caps.py knows how to verify whatever it does have.
          <ARGS_INPUT>: <TURN_CAP_FLAG>

      # Only if the vendor's action does NOT open the PR itself.
      # Reuse the body of the step in templates/claude.yml; the only change is
      # reading the branch from this action's output name.
      - name: Open the pull request
        if: steps.agent.outputs.<BRANCH_OUTPUT> != ''
```

---

## What the real build would cost

Assuming a candidate passes all four questions:

| Work | Size |
|---|---|
| Make `check-workflow-caps.py` vendor-aware, proven red first | **Do this first**, and it is the only part with no dependency on the vendor |
| The workflow file itself | Small — most of it is lifted verbatim |
| Consumer `CLAUDE.md` equivalent for the second agent | Unknown until the vendor is known |
| `setup.sh` learning to install one agent, the other, or both | Moderate. Currently it copies a fixed filename |
| `doctor.sh` learning to check the second secret and app | Moderate |
| `AGENTS.md` and the setup guide covering two paths | Moderate, and it is documentation work on the install path, which is where this project's defects have historically clustered |
| Evidence: at least one real end-to-end run | Non-negotiable |

**The workflow is the small part.** The install and diagnostic scripts, and the docs that keep two
paths straight, are the bulk — which matches this project's history, where the workflow was never
the thing that broke.

---

## What would trigger building it

Any one of these, per D15:

- xAI ships a per-bot meter, a spend cap, or a model picker for Grok Bot. The wedge dies and the
  category framing becomes the pitch.
- A second vendor ships a first-party Action with subscription auth, making question 1 a yes.
- Someone outside the project asks for a specific second agent — evidence of demand rather than a
  guess about it.

Until one of those happens, **leading with layer 1 is the hedge that actually protects the project**,
and it costs nothing. A subscription-billed, cost-braked, GitHub-native coding agent is valuable with
no chat bot involved at all. Correct positioning covers most of this risk for free; a second workflow
covers the rest expensively.

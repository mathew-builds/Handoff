# Changelog

Notable changes to Handoff. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because this project's whole discipline is not claiming what it has not run, entries say which parts are **proven by observation** and which are not.

## [Unreleased]

Nothing since 1.0.0 was assembled.

## [1.0.0] — not yet tagged

The tag and the GitHub release are deliberately held until the repository moves to an organisation
and goes public: the tag is the thing people link to, and it should not be cut twice
(`TASKS.md` 3.5). Everything below is in `main` today.

First release. The bridge has been watched working end to end — issue in, reviewable pull request out, reported back into a chat — on 2026-09-06. Claims below are split into what was observed and what was not; the front page carries the same split.

### Added

- **`templates/claude.yml`** — the product. An issue containing `@claude` runs the coding agent on a GitHub-hosted runner, authenticated with a **subscription** token rather than an API key. It edits, runs tests, pushes a branch, and a later step in the *same* workflow opens the pull request.
- **`AGENTS.md`** — an install guide written for an agent rather than a person, for the case where someone hands their coding agent this repository's URL and says "set this up". Organised around the three steps an agent **cannot** do, because that is where a confident agent invents something.
- **`scripts/setup.sh`** — installs the workflow and a starter `CLAUDE.md`, checks the repository settings, and exits non-zero when anything leaves the bridge non-functional.
- **`scripts/doctor.sh`** — diagnoses a consumer repository. Every failure prints the exact command or click that fixes it, and it reads the *installed* workflow rather than only checking the file exists.
- **`templates/weekly-cost.yml`** — optional. Posts a weekly report of pull requests merged, runs taken, and runner time per merged pull request. **Uses no model turns**: it is `gh` and `awk`, not an agent.
- **`templates/bots/*.md`, `templates/routines/*.md`** — prose to paste into a chat bot so it can write the issue and report the pull request back.
- Banner, social preview card, and badges.

### Proven by running it

- **An issue becomes a reviewable pull request in about a minute**, billed to a subscription with **$0.00** of pay-as-you-go spend confirmed on the provider's console.
- **The pull request opens itself** after the coding agent pushes — verified on the real path, with the branch authored *and* committed by the agent and no human push anywhere in the chain.
- **A chat bot can drive it end to end.** A one-line ask produced a well-formed issue, tested code, and a pull request, with the bot writing no code itself.
- **The result reports back unprompted**, with no approval tap, on the built-in GitHub trigger. Tested twice — once with a human-opened pull request and once with one opened by the automation, because those are different senders and only the second reflects live use.

### Not proven

- **Nothing has run against a real, substantial codebase.** Every measurement comes from practice repositories with toy tests.
- **One run per test.** Nothing here speaks to reliability over weeks.
- **The weekly report has only ever printed `tests pending`** — by design, since it fires when a pull request opens and checks are still queued.
- **The inbound-webhook trigger is untested.** The unattended result above is for the built-in GitHub connection only.
- **Nobody outside the project has installed it.** The fresh-eyes setup test (`TASKS.md` 3.4) has not been run. The install path has only ever been walked by the people who wrote it.
- **The saving has never been measured on the meter it is meant to save.** The Grok Bot weekly allowance has not been read before and after; `docs/08-measurements.md` records it as "not yet measured". The $0.00 figure proves the Claude side is not metered, not that the Grok Bot side got cheaper.
- **Two weeks of real operating use never happened.** That was Phase 2, and it is parked — its target repository was dropped on 2026-09-06.

### Decisions worth knowing

- **The pull request is opened by a step inside `claude.yml`**, not a separate workflow. The coding action has no tool for opening one, and a separate `on: push` workflow **never fires** — `actions/checkout` persists the workflow token and GitHub will not start runs from it. We shipped that bug and it passed "verification" twice, both times because a human had pushed the branch. See `docs/02-decisions.md` D12.
- **Start with a fine-grained token on your own account**, not a machine account. The machine account rested on a blast-radius argument we disproved ourselves: the action checks the *account's* write access, not the *token's* scope, so a narrow token is a spam control rather than a privilege control. A dedicated account is an attribution upgrade, not a prerequisite. See D5a.
- **Three cost brakes are mandatory** on every workflow change — a `concurrency` group, a `timeout-minutes`, and `--max-turns`. Enforced by a check that fails the build, because a sentence in a document is a hope rather than a control.

### Known gotchas that cost real time

- **"Allow GitHub Actions to create and approve pull requests" is off by default on every repository.** Without it the coding agent does the work, pushes a branch, and no pull request ever appears. This is the single most common silent failure.
- **The write-access check is not a prompt-injection defence.** It controls who can *start* a run, not what text reaches the agent. Anyone who can comment on a thread — including a read-only collaborator — can put text in front of it.

<!-- Link definitions for [Unreleased] and [1.0.0] belong here once v1.0.0 is actually tagged
     and the repository is public (TASKS.md 3.5). Until then they would both 404, so the two
     headings render as plain text on purpose. Restore them as the last step of cutting the tag:
       [Unreleased]: https://github.com/OWNER/Handoff/compare/v1.0.0...HEAD
       [1.0.0]: https://github.com/OWNER/Handoff/releases/tag/v1.0.0 -->

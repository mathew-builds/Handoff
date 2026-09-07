# Changelog

Notable changes to Handoff. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because this project's whole discipline is not claiming what it has not run, entries say which parts are **proven by observation** and which are not.

## [Unreleased]

Nothing shipped. Two defects have been found and reproduced since 1.0.0, both open:

- **The cost-brake checker is hardcoded to one vendor** ([#106](https://github.com/mathew-builds/Handoff/issues/106)). `scripts/check-workflow-caps.py` only recognises a step as running the agent if the action comes from `anthropics/`, so a second agent's turn cap would go unchecked while CI stayed green. Reproduced at exit 0 against an uncapped second-vendor workflow. It does not affect `templates/claude.yml`, which is still checked correctly — but it blocks the second-agent design in [09-second-agent-design.md](docs/09-second-agent-design.md) (D15).
- **The pull-request report-back only ever says `tests pending`** ([#108](https://github.com/mathew-builds/Handoff/issues/108)), and its `green`/`red` branches have never run anywhere, because the trial repo has no CI. Documented behaviour rather than a regression — but two of three output branches are unproven.

Neither is a regression in shipped behaviour, which is why 1.0.0 is not withdrawn.

## [1.0.0] — 2026-09-07

Owner settled 2026-09-07: the repository stays on its personal account rather than moving to an
organisation, so the tag is safe to cut — it will not need cutting twice. Everything below is in
`main`.

First release. The bridge has been watched working end to end — issue in, reviewable pull request out, reported back into a chat — on 2026-09-06. Claims below are split into what was observed and what was not; the front page carries the same split.

### Added

- **`templates/claude.yml`** — the product. An issue containing `@claude` runs the coding agent on a GitHub-hosted runner, authenticated with a **subscription** token rather than an API key. It edits, runs tests, pushes a branch, and a later step in the *same* workflow opens the pull request.
- **A misrouted-issue guard in `templates/claude.yml`** — for anyone driving several repositories from one chat bot. Each issue declares `Repo: OWNER/NAME`, and the workflow refuses to run, comments once and stops when that line names a different repository. **No `Repo:` line means no check**, so single-repo installs are unaffected; it can only refuse, never redirect; and its refusal comment omits the trigger phrase, or the workflow would restart itself forever. See `docs/02-decisions.md` D14.
- **`AGENTS.md`** — an install guide written for an agent rather than a person, for the case where someone hands their coding agent this repository's URL and says "set this up". Organised around the two steps an agent **cannot** do and the one it must ask about first, because that is where a confident agent invents something.
- **`scripts/setup.sh`** — installs the workflow and a starter `CLAUDE.md`, checks the repository settings, and exits non-zero when anything leaves the bridge non-functional.
- **`scripts/doctor.sh`** — diagnoses a consumer repository. Every failure prints the exact command or click that fixes it, and it reads the *installed* workflow rather than only checking the file exists.
- **`templates/weekly-cost.yml`** — optional. Posts a weekly report of pull requests merged, runs taken, and runner time per merged pull request. **Uses no model turns**: it is `gh` and `awk`, not an agent.
- **`templates/bots/*.md`, `templates/routines/*.md`** — prose to paste into a chat bot so it can write the issue and report the pull request back.
- Banner, social-preview card and badges. The card ships as `assets/handoff-social.svg`. GitHub's social-preview uploader rejects SVG, so the PNG is rendered by hand at release time (`CONTRIBUTING.md` has the command) and is not in version control. **Upload it before the repository URL is shared anywhere** — X, Slack, LinkedIn and Discord cache the preview image and title on first fetch, and those caches are not yours to purge.

### Proven by running it

- **An issue becomes a reviewable pull request in about a minute** — 61s on 2026-09-06 — billed to a subscription rather than per token. **$0.00** of pay-as-you-go spend was confirmed on the Anthropic Console on **2026-09-05**, for an earlier run. Two runs, two dates; nothing records a second Console read.
- **The pull request opens itself** after the coding agent pushes — verified on the real path, with the branch authored *and* committed by the agent and no human push anywhere in the chain.
- **A chat bot can drive it end to end.** A one-line ask produced a well-formed issue, tested code, and a pull request, with the bot writing no code itself.
- **The result reports back unprompted**, with no approval tap, on the built-in GitHub trigger. Tested twice — once with a human-opened pull request and once with one opened by the automation, because those are different senders and only the second reflects live use.

### Not proven

- **Nothing has run against a real, substantial codebase.** Every measurement comes from practice repositories with toy tests.
- **One run per test.** Nothing here speaks to reliability over weeks.
- **The PR-ready routine has only ever printed `tests pending`** — by design, since it fires when a pull request opens and checks are still queued. That is `templates/routines/pr-ready.md`, the layer-2 report-back; the weekly cost report is a different file and is unaffected.
- **The inbound-webhook trigger is untested.** The unattended result above is for the built-in GitHub connection only.
- **Nobody outside the project has installed it.** The fresh-eyes setup test (`TASKS.md` 3.4) has been run twice, both times by agents inside the project. Both runs stopped at the human-only steps, so no `@claude` run ever happened on the new repository — which is the half the task exists to test.
- **Multi-repo routing has never run live across two real repositories.** The misrouted-issue guard is proven by extracting the step and running it against six inputs on 2026-09-07 (D14), not in place.
- **The token-scope control test has never been re-run.** `TASKS.md` 1.1 asks for a `200` from the target repository and a `404` from a control repository outside the token's scope. That output was not kept and cannot be recovered, because it depends on a token that is not ours to replay. Recorded as missing rather than assumed.
- **The saving has never been measured on the meter it is meant to save.** The Grok Bot weekly allowance has not been read before and after; `docs/08-measurements.md` records it as "not yet measured". The $0.00 figure proves the Claude side is not metered, not that the Grok Bot side got cheaper.
- **Two weeks of real operating use never happened.** That was Phase 2, and it is parked — its target repository was dropped on 2026-09-06.

### Decisions worth knowing

- **The pull request is opened by a step inside `claude.yml`**, not a separate workflow. The coding action has no tool for opening one, and a separate `on: push` workflow **never fires** — `actions/checkout` persists the workflow token and GitHub will not start runs from it. We shipped that bug and it passed "verification" twice, both times because a human had pushed the branch. See `docs/02-decisions.md` D12.
- **Start with a fine-grained token on your own account**, not a machine account. The machine account rested on a blast-radius argument we disproved ourselves: the action checks the *account's* write access, not the *token's* scope, so a narrow token is a spam control rather than a privilege control. A dedicated account is an attribution upgrade, not a prerequisite. See D5a.
- **Three cost brakes are mandatory** on every workflow change — a `concurrency` group, a `timeout-minutes`, and `--max-turns`. Enforced by a check that fails the build, because a sentence in a document is a hope rather than a control.
- **Multi-repo routing refuses rather than guesses better.** The failure was never the wrong guess; it was that a wrong guess stayed invisible until the coding agent had already edited the wrong codebase and opened a pull request on it. Enforcement attacks the consequence instead, costs seconds of runner time and zero model turns, and fails closed. See D14.

### Known gotchas that cost real time

- **"Allow GitHub Actions to create and approve pull requests" is off by default on every repository.** Without it the coding agent does the work, pushes a branch, and no pull request ever appears. This is the single most common silent failure.
- **The write-access check is not a prompt-injection defence.** It controls who can *start* a run, not what text reaches the agent. Anyone who can comment on a thread — including a read-only collaborator — can put text in front of it.

**About the two links below.** They are absolute and they carry the owner's GitHub account name.
That is the one deliberate exception to this project's own "no account names anywhere" rule
(`CLAUDE.md`): a changelog has to point at real releases, and a release URL has no fork-relative
form. Everything else stays fork-relative — the README's CI badge is written as `../../actions/...`
precisely so a fork shows its own CI rather than ours. **If you fork this repository, rewrite these
two lines.** They also resolve only once `v1.0.0` is tagged, so **tag before making the repository
public**, or the first reader gets two 404s.

[Unreleased]: https://github.com/mathew-builds/Handoff/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/mathew-builds/Handoff/releases/tag/v1.0.0

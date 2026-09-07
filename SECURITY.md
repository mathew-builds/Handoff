# Security policy

## Reporting a vulnerability

**Do not open a public issue.** Use GitHub's private vulnerability reporting: the
[**Security** tab](https://github.com/mathew-builds/Handoff/security) → **Report a vulnerability**.
That channel is enabled on this repository, so the button is there.

If for any reason you cannot use it, open a public issue that says *only* that you have a security
report — no details, no reproduction — and you will be given somewhere private to send it.

**What to include:** what an attacker can do, the smallest reproduction you have, and which of the
two contexts it applies to (see below). A workflow run URL or a diff is worth more than prose.

**What to expect.** This is a one-person project, so no response-time guarantee would be honest.
You should get an acknowledgement within a few days. If a report is valid you will be credited in
the release notes unless you would rather not be.

## What is in scope

Handoff is a **template**. Almost nothing in this repository runs in this repository, and that
distinction decides whether something is a Handoff vulnerability or a configuration problem in
someone's own repo.

| In scope | Why |
|---|---|
| `templates/claude.yml` | The product. It runs in a consumer's repository with `contents: write` |
| `templates/weekly-cost.yml` | Ships to consumers and reads their Actions data |
| `templates/CLAUDE.md.template` | Instructions the agent reads first on every run |
| `templates/bots/*.md`, `templates/routines/*.md` | Prose pasted into a chat agent that can open issues |
| `scripts/*` | Run on an operator's machine, against their repository, sometimes with a token |
| `.github/workflows/ci.yml` | Runs here, and a compromise of it compromises what we publish |

Things that would be **in scope and serious**: a way to make the workflow run on a prompt from
someone without write access; a way to defeat the misrouted-issue guard so a run acts on the wrong
repository; anything that causes a token or OAuth credential to be written to logs, a comment, a
branch or an artifact; an injection through issue or comment text into the shell of any `run:`
block; a workflow change that removes a cost brake without failing CI.

## What is out of scope

- **Vulnerabilities in the dependencies themselves.** Report those upstream:
  `anthropics/claude-code-action`, `actions/checkout`, `actions/setup-python`, the `gh` CLI,
  Claude Code, or GitHub Actions. We will happily help you route a report, and we will pin or
  work around an upstream issue once it is public.
- **A consumer's own misconfiguration** — a public repository with loose collaborator permissions,
  a token scoped more broadly than the setup guide says, secrets committed to their own repo.
  If the *guide* leads someone into that state, though, that **is** in scope and worth reporting.
- **Anything requiring repository admin already.** If you can change the workflow, you can already
  do whatever the workflow can.
- **Findings from a scanner with no demonstrated impact.** Show what an attacker gets.

## Known and accepted risks

These are documented rather than fixed, and reporting them again is not a vulnerability report.
[`docs/05-security.md`](docs/05-security.md) has the full threat model and is blunt about the
limits.

- **Prompt injection is reduced, not prevented.** Anyone who can comment on a thread can put text
  in front of the agent, including a read-only collaborator, and it fires when someone *with*
  write access invokes it. The action's sanitisation is best-effort by its own documentation.
- **Running a repository's tests means executing that repository's code.** On pull-request runs
  that code comes from the pull request. No allow-list avoids it; the mitigation is to drop the
  pull-request triggers and run issue-only.
- **The runner holds real credentials while reading untrusted text.** That is inherent. What
  contains it is that the runner is ephemeral and holds nothing from production.
- **`@v1` is a mutable tag, not a pin.** Pin a commit SHA if you want supply-chain protection, and
  accept the upgrade burden.
- **Two action inputs switch off the write-access check** — `allowed_bots` and
  `allowed_non_write_users`. This template sets neither. Do not add them.

## What protects this repository

Stated so you can check it rather than take it on trust, and so you know what a bypass would mean:

- **Secret scanning and push protection** are enabled — a push containing a recognised credential
  is blocked before it lands.
- **A credential tripwire in CI** greps every file for token-shaped strings and fails the build.
  It is deliberately narrow: it catches `sk-ant-`, `github_pat_`, and `ghp_` shapes, not everything.
- **Three cost brakes** — a concurrency group, `timeout-minutes`, and `--max-turns` — are enforced
  by `scripts/check-workflow-caps.py`, which fails if any is missing from any workflow, and which
  is mutation-tested so it cannot report a brake it did not find.
- **The misrouted-issue guard** refuses to act when an issue names a different repository. It can
  only refuse, never redirect, and its refusal comment never contains the trigger phrase.
  `scripts/test-scripts.sh` exercises it in both directions.
- **Dependabot** watches the actions this repository uses. It does not watch `templates/`, because
  those run in a consumer's repository.

## Supported versions

| Version | Supported |
|---|---|
| `v1.0.0` and `main` | Yes |
| Anything earlier | There is nothing earlier |

Fixes land on `main` and are described in [`CHANGELOG.md`](CHANGELOG.md). Because this is a
template, **a fix only reaches you when you re-copy the changed file into your repository** — there
is no auto-update. Security-relevant changes will say so explicitly in the changelog.

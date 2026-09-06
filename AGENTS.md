# AGENTS.md — installing Handoff into a repository

**You are an AI coding agent and someone has pointed you at this repository.** This file tells you exactly what to do. Follow it in order.

It is written for any agent — Claude Code, Codex, Cursor, or anything else with a shell and the `gh` CLI. Nothing here is vendor-specific.

---

## First: which job are you here for?

| If the person asked you to… | Read | Stop reading this file? |
|---|---|---|
| **Set Handoff up in their repository** | this file | No — continue below |
| **Change Handoff itself** (fix a bug, add a doc) | `CLAUDE.md`, then `TASKS.md` | **Yes.** `CLAUDE.md` is about developing Handoff, not installing it. |

If you are unsure, ask. The two jobs touch different files and confusing them wastes a run.

---

## What Handoff does, in one paragraph

It makes a GitHub repository accept work by issue. Someone opens an issue containing `@claude`, a GitHub Actions workflow runs a coding agent on a GitHub-hosted runner, that agent edits code and runs tests and pushes a branch, and a later step in the same workflow opens the pull request. The coding is billed to a **subscription**, not per token. There is no server, no tunnel, and nothing to install on any machine.

Optionally, a chat bot writes the issue and reports the pull request back. That part is separate and not covered here — see `docs/03-setup-guide.md` step 4 onward.

---

## The rule that matters most

**Two steps in this setup cannot be done by you, and one you must not do without asking.** Do not attempt the first two, do not simulate them, and do not mark the setup complete without them.

| Step | You | Why |
|---|---|---|
| Getting the subscription token | **cannot** | `claude setup-token` opens a browser for the human to approve, and prints a secret. |
| Installing the coding agent's GitHub App | **cannot** | A GitHub permissions screen. |
| Allowing Actions to open pull requests | **can — ask first** | One `gh api` call, and you have admin. But it also narrows `default_workflow_permissions`, so it is the human's call. See step 5. |

> **Never run `claude setup-token` yourself.** It prints a secret. If you run it, that secret enters your context and your transcript, and it is the credential that pays for every future run. The human runs it in their own terminal and pipes it straight to `gh secret set`. Relay the commands; do not execute them.

---

## Step 0 — Get a working copy of the target repository

**Do this first.** Everything below runs from inside the repository you are configuring, and you may only have been given its URL.

```
git clone <the target repository URL> ~/target && cd ~/target
```

**If there is no repository yet** — the human asked for Handoff on a *new* repo — create it *with a first commit*:

```
gh repo create OWNER/NAME --private --add-readme
git clone https://github.com/OWNER/NAME ~/target && cd ~/target
```

`--add-readme` is not cosmetic. A repository with no commits has no default branch ref, every step below reads files from that branch, and `doctor.sh` cannot check anything without it.

If the human already has a checkout open, use that instead and skip the clone. Substitute your own path for `~/target` throughout — the paths in this file are examples, not requirements.

Then confirm all five from inside it. **Each one exits non-zero when it fails** — do not read the output and move on. If any fails, tell the human what is missing and stop.

```
gh auth status
git rev-parse --git-dir
gh repo view --json nameWithOwner
test -n "$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)" \
  || { echo "NO DEFAULT BRANCH — this repository has no commits. Push one first."; false; }
[ "$(gh api repos/OWNER/REPO --jq .permissions.admin)" = "true" ] \
  || { echo "NOT ADMIN — you cannot set secrets, so the setup cannot be completed."; false; }
```

You need: `gh` logged in, a git repository, **admin** on it, and a default branch that exists. Without admin you cannot set secrets, and the setup cannot be completed.

> The last two checks are written to *fail* rather than to report, deliberately, and the reason is the same both times: **the problem is in the output, not the exit code.** `gh repo view --json defaultBranchRef` on a commitless repository prints `{"name":""}` and exits 0. `gh api … --jq .permissions.admin` prints `false` and exits 0. A check that only prints either one reads as a pass — which is issue 36, the mistake this project keeps having to re-learn.

---

## Step 1 — Get Handoff onto the machine

Clone it somewhere outside the target repository. Do not clone it *into* the repository you are configuring.

```
HANDOFF=~/handoff
git clone <the Handoff repository URL you were given> "$HANDOFF"
```

**Set `HANDOFF` to wherever you actually cloned it and use `$HANDOFF` everywhere below.** The rest of this file assumes that variable, so if you clone elsewhere nothing breaks.

**If you were given a local path instead of a URL, use that path and do not clone.** A local checkout may be on a branch with work that is not published yet; cloning would silently give you different files. Observed in testing: an agent told to use a local checkout cloned from GitHub anyway and ended up with an older version, then followed instructions that were missing the step it needed.

Confirm you have the right thing before continuing — this file should exist in it:

```
ls "$HANDOFF/AGENTS.md"
```

If it does not, you have an older copy. Stop and tell the human.

---

## Step 2 — Ask the human for the subscription token

**Relay these two commands. Do not run them.** Say something close to:

> I can't do this step — it opens a browser and prints a secret that shouldn't pass through me. Please run these two in your own terminal, from inside your repository:
>
> ```
> claude setup-token
> gh secret set CLAUDE_CODE_OAUTH_TOKEN
> ```
>
> The first opens a browser; approve it, then copy the token it prints. The second prompts you to paste — nothing will appear as you type, which is deliberate. Tell me when it's done.

Then verify it landed, which you *can* do:

```
gh secret list --repo OWNER/REPO
```

`CLAUDE_CODE_OAUTH_TOKEN` must be listed. You cannot read its value, and you should not try.

**Do not wait here.** If the human is away, record the request and carry straight on to step 3. Everything from step 3 to step 4 works without the token; only steps 8 and 9 need it. Waiting produces the worst outcome — the human comes back to a setup where nothing happened.

---

## Step 3 — Run the setup script

From **inside the target repository**:

```
bash "$HANDOFF/scripts/setup.sh"
```

It copies the workflow in, creates a `CLAUDE.md` if there isn't one, and checks the repository settings.

**It does all of that even when the human has not given you the token yet.** The token is reported as a blocker at the end rather than stopping the script, precisely so an agent working while the human is away can still finish the mechanical work. Earlier versions exited before touching any file; if you meet one that does, you have an old copy.

**Read its exit code, not just its output.** It exits non-zero when something leaves the bridge non-functional. Warnings are advice; blockers are not.

It will not overwrite an existing `CLAUDE.md`. If the repository already has one, merge in what you need from `$HANDOFF/templates/CLAUDE.md.template` by hand — that file tells the coding agent how to behave in this repository, and it matters more than it looks.

---

## Step 4 — Fill in the placeholders

If the script created `CLAUDE.md`, it contains `<placeholders>`. **Fill them in before any test run.** The coding agent reads that file first on every run, so testing with placeholders still in it tests the template rather than the repository.

You can do this yourself: read the repository, work out its test command and its never-touch paths, and write them in. Then show the human what you wrote and ask them to correct it.

**If the repository has no tests, write that it has no tests.** Do not invent a plausible command. A `CLAUDE.md` claiming `npm test` in a repository with no `package.json` will make every future run fail in a confusing way, and the failure will look like the coding agent's fault rather than yours. "This repository has no test suite; verify changes by reading the diff" is a correct and useful thing to write. Say so in your report so the human can correct it if they are about to add tests.

---

## Step 5 — Allow Actions to open pull requests

**This is off by default on every GitHub repository, and it is the single most common way this setup silently fails.** Without it, the coding agent does the work, pushes a branch, and no pull request ever appears.

The command:

```
gh api -X PUT repos/OWNER/REPO/actions/permissions/workflow -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true
```

**Ask before running it.** It also sets `default_workflow_permissions=read`, which would narrow a repository where the human had deliberately chosen `write`. Say so, and let them choose between you running it and them ticking the box at **Settings → Actions → General → Workflow permissions**.

---

## Step 6 — Ask the human to install the GitHub App

You cannot do this one either.

> Please install the Claude GitHub App on this repository: https://github.com/apps/claude
> Or run `claude` and type `/install-github-app` at the prompt. Tell me when it's done.

**No API can confirm this happened** without the app's own credentials, so you cannot verify it. Take the human's word, and say that you are taking their word.

---

## Step 7 — Commit and push

Actions only triggers issue events from the **default branch**. Until the workflow is on it, nothing fires.

```
git add .github/workflows/claude.yml CLAUDE.md
git commit -m "Add Handoff"
git push
```

---

## Step 8 — Verify

```
bash "$HANDOFF/scripts/doctor.sh" OWNER/REPO
```

**Exit code 0 means the repository side is correctly wired.** Non-zero means it is not — read the failures, they each name the fix.

`doctor.sh` will always warn that it cannot confirm the GitHub App is installed. That warning is expected and is not a failure.

---

## Step 9 — The real test

Open an issue and watch what happens:

```
gh issue create --title "Add a CONTRIBUTING.md" --body "@claude Add a short CONTRIBUTING.md describing how to run the tests.

Done means: the file exists and the tests still pass.

Do not: change any other file."
```

Then wait about 90 seconds and check:

```
gh run list --limit 1
gh pr list --limit 1
```

**A correct result is a pull request opened by `github-actions`** — not by the coding agent's own app, which has no tool for opening pull requests. If a branch was pushed and no pull request appeared, step 5 was not completed.

---

## When you report back

Tell the human plainly:

- Which steps you completed.
- Which steps **they** completed, and that you could not verify the GitHub App one.
- What `doctor.sh` exited with.
- Whether the test issue produced a pull request, and who opened it.

**Do not report success on the basis of the setup script alone.** The setup script checks the repository is configured. Only step 9 shows the thing actually works.

---

## If it goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| Branch pushed, no pull request | Step 5 not done | Enable the setting, then re-run step 9 |
| Workflow never ran | Workflow not on the default branch, or the app is not installed | Steps 6 and 7 |
| `GitHub Actions is not permitted to create or approve pull requests` | Step 5 | As above |
| Run started, then `No trigger found` | The issue body does not contain `@claude`, or the issue was *assigned* rather than opened | Open a new issue with `@claude` in the body |
| The agent edited files it was told not to | `CLAUDE.md` placeholders were never filled in | Step 4 |

`docs/04-operations.md` has the full runbook.

---

## What this setup does not protect against

Say this to the human if they ask whether it is safe:

The write-access check controls **who can start a run**, not what text reaches the coding agent. A comment from someone without write access is still in the prompt when someone with write access says `@claude`. What actually limits the damage is that the runner is ephemeral and holds no production credentials, the tool allow-list is narrow, and **a human merges**. See `docs/05-security.md`.

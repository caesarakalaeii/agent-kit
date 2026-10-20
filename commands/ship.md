---
description: Commit the current change on a feature branch, push, open a PR, and auto-merge only with council approval and green CI.
---

Ship this change: $ARGUMENTS

**1. Inspect before touching anything.**

```bash
git status --short
git branch --show-current
git diff --stat
```

Know what is staged, unstaged, and untracked. If the tree contains unrelated
work in progress, say so and stage selectively rather than sweeping it in.

**2. Branch guard: never on `main`/`master`.**

If the current branch is `main` or `master`, stop and create a feature branch
first:

```bash
git switch -c <type>/<short-slug>
```

Use the same `<type>` as the commit message (`feat/`, `fix/`, `chore/`, ...).
Never commit directly onto `main`/`master`, even locally.

**3. Stage only what belongs to this change.**

Name the paths explicitly; `git add -A` drags in unrelated edits, build
output, and scratch files. Never stage a credential, a `.env`, or any key
material. If a secret entered the tree, stop and tell the operator; do not
commit it and do not try to rewrite history.

**4. Commit with Conventional Commits.**

Format: `<type>(<scope>): <description>`

Types: `feat` | `fix` | `refactor` | `chore` | `docs` | `test` | `build` | `ci` | `perf` | `style`

Rules, all mandatory:

- No emoji anywhere in the subject or body.
- No `Co-Authored-By:` trailer. No AI or assistant attribution of any kind.
- Imperative mood, lower-case description, no trailing period.
- Subject at most 72 chars. Body only when the why is not obvious from the
  diff; wrap at 72.

**5. Push the feature branch.**

```bash
git push -u origin <branch>
```

Feature branches only. Never push to `main`/`master`, never force-push.

**6. PR body: verification must be stated.**

```bash
gh pr create --base main --title "<type>(<scope>): <description>" --body "..."
```

Body: what changed, why, how it was verified (the prove lines: suites run,
exit codes, UI screenshots read), and the council verdict if it ran.

**7. CI must exist to be meaningful.**

Check for a CI workflow (`ls .github/workflows`). If the repo has none, add a
minimal `.github/workflows/ci.yml` in the same PR: trigger on push and
pull_request, run the project's test command, fail non-zero on red. Without
it, "CI green" is an empty phrase. The workflow ships with the change, not as
a follow-up.

**8. Merge, only fully approved.**

If and only if the council verdict is APPROVE:

```bash
gh pr merge --auto --squash --delete-branch
gh pr checks --watch
```

If CI fails, fix on the branch, commit, push again; the auto-merge holds until
checks go green. Never merge with red CI. If the council did not run, blocked,
or the change was shipped without it, open the PR without auto-merge and say
so plainly: the operator decides the merge.

Finish by printing the PR URL and, if applicable, the verdict that authorized
auto-merge. Under `/build`, the `retro` skill runs next.

## Hard boundaries

- **Never merge with red CI.** A green merge is the whole point of the
  pipeline; a red one is a broken main for everyone after you.
- **Never push to `main`/`master`, never force-push.**
- **Auto-merge requires both gates: council APPROVE and green CI.** Neither
  gate may be assumed, skipped, or inferred to have passed.

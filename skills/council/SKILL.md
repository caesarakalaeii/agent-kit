---
name: council
description: Use to review a finished change, or a plan before it is built, with several independent narrow-lens reviewers at once instead of one general reviewer. Convenes read-only subagents per lens, collects one typed verdict from each, and applies the rule that any single blocking objection sends the work back. Use before a handback or a PR, or when asked to review a diff, a branch, or a proposed plan.
---

# The review council

**Four reviewers, not one, and four DIFFERENT reviewers, not four runs of the
same prompt.** A single reviewer asked to consider everything reliably produces a
paragraph about naming and misses the off-by-one. Redundancy catches variance;
only diversity catches a failure mode a lens is blind to.

They are deliberately narrow. Each is told what it owns *and what it does not*,
because the most expensive council failure is not a missed bug, it is several
reviewers all objecting to the same stylistic preference and sending a correct
change back three times.

Ported from [Caterpillar](https://github.com/caesarakalaeii/Caterpillar) (`src/review/`, DESIGN.md §12.1), where it is the third
gate on an autonomous fleet. The port is not literal; the differences are in
[What is different here](#what-is-different-here) and they change what you have
to do yourself.

## The council is the THIRD gate, never the first

In Caterpillar a supervisor has already established, independently of any agent,
that the acceptance commands exit 0 and that CI is green. The council is the only
gate that reads the change rather than its outcome, and it is convened *after*
the other two.

**Here there is no supervisor. You are it.** So before you convene anything:

1. Run the project's tests and its linter. Read the output.
2. If they pass, say so in the shared prompt below; that is what lets the lenses
 skip re-litigating it.
3. **If they do not pass, or you did not run them, say THAT instead.** A council
 convened on a red suite is not a review, it is four opinions about code that
 does not work. Fix it first, or tell the reviewers plainly that the suite was
 not run and why.

Never tell the reviewers the tests pass because you expect them to. That sentence
exists to stop four agents each burning a session re-running the suite; a false
one buys you four reviews of an illusion.

## When to convene

Before a handback or a PR, once the change works, as its own step next to any doc
phase. Also whenever you are asked to review a diff, a branch, or someone else's
PR.

Convene on a **plan** before it is built when the work is about to be cut into
tasks, or when a plan is long enough that being wrong about it costs a day. Same
machinery, different lenses (below).

Do not convene for a typo, a version bump, or a one-line config change. Four
sessions is real money and the answer is already known.

## 1. Establish the change under review

```bash
git branch --show-current
git log --oneline @{upstream}..HEAD 2>/dev/null || git log --oneline -10
git diff --stat $(git merge-base HEAD @{upstream} 2>/dev/null || echo HEAD~1)...HEAD
```

You need a **base**. Without one there is no range, and an unbounded `git log`
presents the repository's whole history as this change's commits, which reads to
a reviewer as damning evidence about a change that did not write any of it. If
you cannot resolve a base, say so in the prompt and name the range you used
instead.

## 2. Write the shared prompt once

Every lens gets the **same** text. The lenses differ in what they are asked to
look for, never in what they are shown, so a finding one makes and another misses
is a difference of attention rather than of information.

```
# Review <branch or PR>

The diff under review is `git diff <base>...HEAD`. Your working directory is <path>.

## Commit order (test-first evidence)
<`git log --stat --oneline <base>..HEAD`, oldest first>

## What the change was asked to do
<the task, the issue, or the PR description, in full, not summarised>

## Test status
<"`npm test` and `npm run lint` exit 0, verified before convening" or the honest alternative>

Review the diff through your lens, then answer in the exact format your instructions give.
```

The commit order goes to **every** lens, not only to `tests`. It is the cheapest
possible statement of how the change was arrived at, and a correctness reviewer
reading "the fix landed three commits before anything tested it" is better
informed for it. Only one lens is asked to reach a verdict on it.

## 3. Dispatch the lenses concurrently

One `council-reviewer` subagent per lens, all dispatched in parallel so they
actually run concurrently, each with the shared prompt plus that lens's text
below. They share the worktree, which is safe because none of them can write.
(Mechanics per harness: in Claude Code, parallel Agent/Task calls in one message;
in omp, all lenses as entries of one `task` batch. Same shared task-list rules
apply where team execution is used.)

### PR lenses

**`correctness` Correctness.**
Does this code do what it claims, on every input it will actually see? Look for: off-by-one and boundary conditions; error paths that are swallowed, logged and continued past, or that leave state half-written; concurrency and ordering assumptions the surrounding system does not guarantee; resource leaks; a change that is right in the case it was written for and wrong in a case the codebase already produces.
Prefer a concrete failure to a category. "This throws when `repos` is empty, which intake permits" is worth a round trip. "Consider adding more error handling" is not.
*Not yours:* style, naming, structure, or whether the tests are thorough enough.

**`design` Design, simplicity and the record.**
Will the next person to read this understand it? That is one question about the code and one about the message attached to it, which is why they are one lens and not two.
Is this the smallest change that solves the problem, and does it fit what is already here? Look for: logic duplicated from something that already exists; a new abstraction with one caller; a special case bolted onto a general mechanism that could have absorbed it; state now stored in two places; an interface that leaks its implementation to every caller.
Weigh it against the code around it, not against an ideal. A change that reads like the code around it is right even when you would have written it differently.
Then read the commit messages and the PR description. They are the only part of this work a future reader gets without reconstructing it from the diff, and "fix stuff" over a body listing the files touched throws that away. Almost everything you find in the record is `blocking: false`; say it and let it land. The exception is a description that is **wrong** rather than thin: one that says the change does something it does not do. That misleads whoever merges it.
Grade against the standard the author was given, not against your own preferences: imperative commit messages that say *why*, Conventional Commit types, no gitmoji, no `Co-Authored-By`.
*Not yours:* whether it is correct, and whether it is tested.

**`tests` Test-first discipline.**
Was this written test-first, and would the tests catch it breaking? You are the only reviewer asked to reach a verdict on this; nothing here is covered by anybody else.
Start with the commit order in the prompt. The finished diff is identical whether the test came first or last, so the order is the only evidence there is. Then read the tests themselves. In the order they matter:
- **A test weakened, deleted, or loosened so the suite would go green.** An assertion removed, a case skipped, an expected value edited to match what the code now returns, a timeout raised, a strict comparison made loose. This is the worst thing that can be in a diff, because the earlier gate PASSES on it: the suite is green precisely because the test stopped asking. Block on this.
- **New behaviour with nothing that would fail if it regressed.** Not coverage as a number: a new branch, a new error path, a new boundary that no test exercises.
- **A fix with no reproducing test.** The bug is now unfixed-in-waiting.
- **Source committed before any test existed.** Weigh it: one commit carrying its test alongside the code is fine, and so is a spike covered before it landed. A whole change with tests appended at the end is the pattern worth naming.
- **Tests that cannot fail.** Asserting on a mock configured two lines earlier, asserting that no exception was thrown, snapshots regenerated without being read.
Against the carve-out: documentation, comments, formatting and pure configuration have no behaviour to test. A change that is only those is not a finding, and saying so is how this lens stays worth reading.
*Not yours:* correctness of the production code, its design, or whether it addresses the whole goal.

**`fit` Acceptance fit.**
Does this change actually do what it was asked to do? Read the goal first. Then: does the diff address the whole goal, or the part that was easiest? Is anything silently unimplemented? Was an acceptance criterion itself altered or weakened so the gate would pass, a command narrowed, a path excluded, a check removed?
Does the PR description describe the change that is actually in the diff? A description claiming more than the diff delivers is how a half-done change gets merged by a human who trusted it.
*Not yours:* internal design, unrelated bugs, or the quality of the tests. Weakened TESTS are the `tests` lens's; a weakened acceptance CRITERION is yours.

### Plan lenses

Three, for a plan that has not been built yet. Tell them: nothing has been
built; if this passes, each task gets its own session, **and the session
implementing a task sees only that task's goal text**, not the plan, not the
conversation, not its sibling tasks. A goal that only makes sense alongside the
others is the most common way a plan produces useless work. They may read the
repository; a plan that assumes files, commands or conventions that do not exist
is the second most common failure, and reading is the only way to catch it.

**`feasibility`** Can this be built, in this repository, as described? Files, modules, commands or services the plan assumes and that do not exist; steps needing a credential or an access nobody has; work depending on a decision nobody has made; a task that is really a research question wearing a task's clothes. Check the plan against the code: "add a migration to the schema module" is a defect if there is no schema module, and it is only findable by looking. *Not yours:* sizing, ordering, criteria.

**`decomposition`** Right set of tasks, right order? A task that is really three (its goal has "and then" in it, or it touches unrelated subsystems); a task too small to be worth a session; two tasks that will edit the same file at once because nothing orders them; a dependency that is a preference rather than a constraint, which turns a plan into a queue and throws away the parallelism; a **missing** dependency, which is worse. For each task ask what must exist before it can start, then look at whether the plan says so. *Not yours:* feasibility, criteria.

**`criteria`** Will each task's session know what to do, and will you be able to tell when it is done? Read every goal as if it is all you were given, because for that session it is. Then the criteria: each must be a command that exits 0, and it must actually FAIL if the task were done wrong. `npm test` on a repo whose suite does not cover the new code passes whatever happens, which makes the gate decorative. Block on a task whose goal cannot be turned into a failing test. *Not yours:* feasibility, decomposition.

## 4. Decide the rule, and it is not a vote

**ANY reviewer raising a blocking objection sends the work back.** Not a
majority.

A council votes on preferences; a defect is not a preference, and two reviewers
who did not look at the thing a third one found are not evidence against it. The
cost is paid on the other side: blocking is expensive, which is why the lenses
are told at length when not to do it.

**An abstention is never an approval.** A reviewer that errored, ran out of
context, returned something you cannot parse, or opened its summary with
`ABSTAIN` has agreed to nothing. Count abstentions separately and say so. On a
PR review, an abstention on any lens means the change is **not approved**.

**A council where every reviewer abstained is `changes`, not `pass`.** This is
the case that bites: abstentions are excluded from the blocker list by
construction, so a full set of them leaves zero blocking objections and reads as
unanimous approval. During a provider outage that is every reviewer, and that
would make "the model was unreachable" a way to land an unread change. An empty
council is not unanimous approval; it means nothing reviewed this.

```
decision = "changes" if (any blocking objection) or (every verdict abstained) or (any PR-lens abstention) else "pass"
```

## 5. Report the verdict

```
**Review council: PASS** no blocking objections.
**Review council: CHANGES REQUESTED** <n> blocking objection(s).

### Correctness pass | changes (non-blocking) | CHANGES (blocking) | ABSTAINED
<summary>
- `file:line` <finding>

### Design, simplicity and the record …
### Test-first discipline …
### Acceptance fit …

_<n> reviewer(s) could not complete a review. An abstention is not an approval._
```

Every lens appears, including the ones that passed; a council you only hear from
when it objects teaches the reader that silence means nothing was run. Blocking
lenses first in your prose summary, with their findings, because that is the part
that is actionable.

End the report with a machine-readable verdict line, because downstream
automation (the `build` and `ship` commands' pipeline) keys auto-merge off it:

```
COUNCIL: APPROVE # all four PR lenses returned pass, zero blocking objections, zero PR-lens abstentions
COUNCIL: BLOCK # one or more blocking objections, or one or more PR-lens abstentions
COUNCIL: RECONVENE # the diff changed after this verdict; re-dispatch before deciding
```

Prefer `COUNCIL: APPROVE` / `COUNCIL: BLOCK` exactly as written, on a line of its
own. An approval with any abstention on a PR lens is **not** an approval: it is
`COUNCIL: BLOCK` with the abstention named as the reason along with any blocking
findings. A plan review uses the prose verdict and never the pipeline line,
because there is no change to auto-merge.

Then **hand the verdict back and stop.** Do not fix what the council found in the
same breath: you are now the author again, and the change needs a fresh diff and
another convening if it was blocked. If the operator asks you to apply the
findings, that is a new change with its own commit.

## What is different here

| Caterpillar | Here | What it costs you |
|---|---|---|
| A supervisor proves the suite and CI green before convening | Nobody does | You run the tests yourself, or you say you did not |
| Reviewers call a typed `submit_verdict` tool; no call = abstention, mechanically | Reviewers return text you parse | An unparseable answer is an **abstention**, not a pass. You have to enforce that, and it is the easiest thing here to get wrong |
| Reviewers get read-only tools and structurally no write verbs | `council-reviewer`: read-only by instruction | Same outcome, enforced by the reviewer's own instructions rather than by tool config |
| A per-council deadline aborts a wedged reviewer | The harness's own task timeout | A reviewer that hangs is an abstention; do not wait on it forever |
| `decide()` is pure and unit-tested | A few lines of prose in step 4 | Re-read them before you write "APPROVE" |

## Failure modes worth naming

| Symptom | What actually happened |
|---|---|
| The council passed a change nobody read | Every reviewer abstained and the empty blocker list was read as unanimous approval |
| A correct change came back three times | The lenses were not kept narrow; four reviewers all objected to the same preference |
| A reviewer re-ran the whole test suite and timed out | The shared prompt did not say the suite had already passed, or said it when it had not |
| The verdict cites `foo.ts:41` and there is nothing there | A base was never resolved, so the reviewer read a range that was not the change |
| The council found the bug and the bug shipped | The convening session applied the fixes and never re-convened on the new diff |
| A reviewer opened a PR | A general subagent was dispatched instead of `council-reviewer` |

## Verification

You are done when: every lens you dispatched appears in the report with a
decision; every abstention is labelled as one and counted; the decision follows
the rule in step 4 and not from a headcount; no finding quotes a credential; and
the report ends in a `COUNCIL:` line when it was a PR review. If you convened on
a red or unrun suite, that sentence is in the report, not in your reasoning only.
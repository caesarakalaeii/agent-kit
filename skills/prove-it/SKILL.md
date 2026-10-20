---
name: prove-it
description: Use before ANY completion claim, "done", "fixed", "tests pass", "it works", and before every commit, PR, or handback. Forces fresh execution evidence: run the proving command, read the real output and exit code, and quote them. Red-green proof for bugfixes. Covers repos with no test suite at all. Route council and test-status disputes here.
---

# prove-it

**A completion claim is a report about an execution you did not see.** "The tests
pass" said over an unrun suite is not optimism, it is a fabricated observation:
the single most common way agent-written code ships broken. This skill is the
gate between "I wrote code" and "I claim it works", and it is deliberately the
cheapest gate in the kit: run the thing, read the output, quote the output.

Ported from
[obra/superpowers `verification-before-completion`](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md)
(MIT, (c) Jesse Vincent): the iron law and the claim/evidence table are
upstream's; what changed here is the no-suite fallback ladder and the red-green
rule for bugfixes, see
[What is different here](#what-is-different-here).

**The iron law:**

```
NO COMPLETION CLAIM WITHOUT FRESH EXECUTION EVIDENCE.
```

"Fresh" means in this session, on this tree, after the last edit. A green run
from before the final tweak is a stale observation being laundered as a current
one.

## The gate function

Before ANY of these, in any harness, in a subagent:

- "done", "fixed", "works", "passing", "green"
- a commit, a PR, a handback, a `/ship`
- "the migration is safe", "the script exits 0"

run this loop:

1. **IDENTIFY** what command proves the claim. If you cannot name one, you cannot
 make the claim, and you say what is unproven instead. This is not a loophole;
 it is the honest output. "I implemented it and did not prove it runs" is a
 valid handback. "It works" is not.
2. **RUN** it, for real, in this session. Not a dry-run of a plan to run it, not
 a remembered result, not "the same check ran earlier".
3. **READ** the full output and the exit code, printed on the next line if the
 harness does not show it. A passing exit code with an error in the output
 (`npm test` over a suite where a "watch" mode swallowed the failure) is the
 classic miss.
4. **QUOTE** them in your answer: the command, the exit code, the relevant tail.
 The quote is the deliverable, not decoration. It lets the operator audit the
 claim without re-running it, and it forces you past the step where "seemed
 fine" gets written down as fact.
5. **CLAIM** only what the evidence shows. 34/34 pass with one skipped is "34
 pass, 1 skipped", not "all tests pass".

Skipping step 2 and writing step 5 is not a shortcut, it is the failure mode this
skill exists to stop.

## What each claim costs

| Claim | Requires | Not sufficient |
|---|---|---|
| "Tests pass" | The suite's command, this session, 0 failures | Last session's run, "should pass now" |
| "Lint/typecheck clean" | The linter, run now, 0 errors | Tests passing, "looks clean" |
| "Build succeeds" | The build command, exit 0 | Lint passing, typecheck passing |
| "Bug fixed" | The original symptom reproduced and gone | Code changed + suite green, because the suite may not cover the bug |
| "Regression test works" | Red-green: it FAILED before the fix | A test that was never seen failing |
| "Agent/subagent finished" | Its diff, read | Its report "success" |
| "Requirements met" | The plan, re-read line by line | All tests green |

Two rows carry most of the discipline:

- **"Agent said success" is not evidence.** A delegated agent's report is a
 claim, and it is *your* gate that applies to it: read its diff and run the
 proving command yourself before you relay its success upward.
- **A green suite does not prove a bugfix.** The suite was green before the bug
 too, often. The only proof is the red-green cycle in the next section.

## The red-green rule for bugfixes

A bugfix without a test that failed first is a suspicion, not a fix. When the
change is a bugfix:

1. Reproduce the failure. Write a test (or a command) that fails on the current
 code and names the bug.
2. **Watch it fail.** If it does not, it does not test the bug; fix the test, not
 the code.
3. Fix the code.
4. Watch the same test pass, and the rest of the suite stay green.

Write -> fail -> fix -> pass is the whole rule. A test written after the fix that
was never seen failing proves nothing about the bug, and "tests that cannot
fail" (asserting on a mock configured two lines earlier, `expect(true)` with a
side effect, a snapshot regenerated unread) belong to the council's `tests`
lens, not a grey area.

**When red-green is genuinely impossible** (a rendering bug with no test
harness), the substitute is a before/after artifact: a screenshot before and
after (`ui-review`), the failing command's output before and after, the log line
before and after. Name what you could not do red-green and show the artifact.
That is a valid handback; silent downgrading is not.

## No test suite at all

For a repo with no suite the proving command is whatever the repo *can* run, and
this is the fallback ladder, in order, first hit wins:

1. **Does the thing parse?** `bash -n script.sh`, `yamllint` /
 `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))"` for each
 changed file, `tsc --noEmit` / the repo's own typecheck.
2. **Does the thing run?** The command itself, on a bounded input, in a way that
 leaves no state: `--help`, `--dry-run`, `--check`, a fixed argument against a
 scratch copy. A shell script gets a run against a temp directory with fake
 inputs.
3. **Is there a linter for the domain?** `shellcheck`, `hadolint`,
 `actionlint`. A linter is not execution, but it is evidence, and it catches
 the class of bug a smoke run misses.
4. **Nothing?** Then say so, in the handback, in this form: *"Changed X. Did not
 run it: no runnable artifact in this repo. Review as prose."* That sentence
 costs nothing and is honest in a way a fake green checkmark is not.

A claim made by running only rung 1 or 2 is a *narrower* claim and must be made
narrower: "parses and the help text runs" is honest; "works" is not.

## Self-review before the handback

The last edit of a session is the least-tested edit of the session. Before you
hand back:

- Re-run the proving command **after the final edit**, even if, especially if,
 the edit was cosmetic or came after everything already passed.
- A skipped case in the output is a finding, not background noise: say why it
 is skipped.
- If the gate turns red at the last minute: **report it.** A session that ends
 on "the final verify run failed with X, here is the tail" hands the operator
 the truth; a session that ends on "done" hands them a lie they will discover
 later.

## Output

Every handback ends with a **proof line**:

```
prove: <command(s) run> -> exit 0 [or the honest status]
```

For example: `prove: npm test -> exit 0, 41/41; npx tsc --noEmit -> exit 0`.
For a red gate: `prove: npm test -> exit 1, 2 failing, pasted above; not done.`
For no suite: `prove: nothing runnable, shellcheck clean, dry-run only.`

A handback without a prove line is incomplete, and the operator should read it
that way.

## What is different here

| superpowers | Here | What it costs you |
|---|---|---|
| Aimed at TDD'd feature work in suites | Adds the no-suite fallback ladder | You pick the rung yourself, the highest one the repo supports, and you name it |
| Red-green as a TDD step | Red-green as the *bugfix proof standard*, with an artifact substitute | With no harness you must produce a before/after artifact or say you didn't |
| "Agent delegation -> check VCS diff" | Same rule, plus subagent reports are claims under YOUR gate | Read subagent diffs before relaying success |
| Tabular claim/evidence mapping | Same, plus "quote the output" as an explicit step | The quote is load-bearing; a bare "exit 0" without the command is not a proof line |

## Failure modes worth naming

| Symptom | What actually happened |
|---|---|
| "It works" shipped broken | The claim was made from the code's shape, not an execution; step 2 skipped |
| Green suite, live bug | The bugfix never had a failing test; the suite was green before and after |
| The last edit broke it | The proving command was not re-run after the final tweak |
| "All tests pass" over 4 skipped | The skipped count was in the output and not reported |
| A subagent's "success" was relayed | Its diff was not read and its claim not re-verified under this gate |
| A claim made, gate failed, session ended anyway | The red gate was not reported, the worst row in this table |

## Verification

You are done when: the proving command ran in this session after the last edit;
its output and exit code are quoted in your answer; skipped or narrowed cases
are named; a bugfix carries red-green or its artifact substitute or a named
gap; and the handback ends in a `prove:` line the operator could re-run.
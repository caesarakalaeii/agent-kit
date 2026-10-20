---
description: End-to-end delivery pipeline, interview (if needed), wave-based plan, TDD implementation in waves, verification (prove-it + ui-review), docs, review council, then hand to /ship. Each phase gates the next; nothing ships on a red gate.
---

Build: $ARGUMENTS

**This is a pipeline, not a suggestion.** Move through the phases in order;
each phase ends in a gate. A gate is green when it carries fresh evidence
(the `prove-it` skill), never when it merely feels done. A red gate stops the
line: fix what it caught in the current phase, or report the stop honestly and
end the turn. Nothing advances on vibes, and the phases do not get reordered
because implementation got exciting.

Scope: one change, feature-branch sized, in this repository.

## Phase 0, What is the actual work order?

Read the request first, not the phases. If it is a question, answer it and
stop; `/build` is not the default response to prose. An imperative or an
explicit yes is the work order.

**Interview with the `brainstorming` skill: grill until the requirements are
unambiguous.** Ask about the genuine unknowns (acceptance criteria,
constraints, definition of done) in batched messages, each with a proposed
default so a lazy "ok to all" is a valid answer. Keep it to a few questions
unless the domain genuinely requires more; a twelve-question interrogation is
a failure mode, not diligence. If the work order is already unambiguous, skip
the interview and state the reason.

Record the outcome as a short spec with **acceptance criteria written as
commands that exit 0**. If a criterion cannot be phrased as a command, it is a
preference, and preferences get confirmed, not gated.

## Phase 1, Plan

Use the `writing-plans` skill to produce the plan file in the project, e.g.
`docs/plans/<date>-<slug>.md`. Structure it as **waves**: each wave is a set
of tasks with disjoint file ownership that can run in parallel; later waves
depend on earlier ones. Every task names its files, its test strategy, and its
handoff to the next wave.

Then a `ponytail` pass over the plan: cut speculative scope, kill YAGNI
items, prefer reuse before invention. Record what was cut and why, so the
operator can resurrect it.

Then convene the **plan lenses** of the `council` skill: feasibility,
decomposition, criteria. They must APPROVE. A blocked plan gets revised and
re-convened, not "improved during implementation". Say in the plan verdict
whether the interview was skipped and why.

## Phase 2, Implementation in waves

Create a feature branch (`<type>/<short-slug>`), or use the
`using-git-worktrees` skill if the working tree is busy.

Per wave, dispatch one worker per task:

- **Claude Code:** agent teams (the lead spawns teammates with a shared task
  list), or the `subagent-driven-development` skill.
- **omp:** one `task` batch per wave, with the shared contract (interfaces,
  file ownership, acceptance criteria) in every task's context.
- **Both:** workers follow the `test-driven-development` skill. Red test,
  minimum code, green, refactor. One test at a time; the plan's task order
  holds. `dispatching-parallel-agents` covers the dispatch mechanics.

**Lead integrates between waves.** After each wave lands, read the diff
yourself (delegated work is your work: a teammate's "success" is a claim
under your gate), run the full suite fresh, and quote the exit code. A red
suite stops the next wave: fix it before anything else ships on top of it.
Use the `systematic-debugging` skill for failures instead of patching
symptoms.

If parts of a wave finish while siblings still run, let them: coordination is
cheap because file ownership is disjoint. If two tasks genuinely collide on a
file, that was a planning error; fix the plan, not the dispatch.

Phase 2 ends at its gate: the full suite run fresh after the last wave, exit
code quoted, red-green evidence for every bugfix and new behaviour, in
`prove-it` format, including the honest "nothing runnable" line if that is
the truth.

## Phase 3, Verify

Two checks, both mandatory:

1. **Re-run the proving commands after the final edit.** The last edit of a
   session is the least-tested edit of the session. Quote output and exit
   code. Lines in the `verification-before-completion` and `prove-it` skills'
   format.
2. **If anything the user will SEE changed** (UI, HTML, styles, dashboards):
   run the `ui-review` skill fully, Playwright-driven: screenshot at both
   widths, read the PNGs, check the console, fix, re-shoot.

Re-read the Phase 0 acceptance criteria line by line. A green suite over
unmet criteria is a half-done change.

## Phase 4, Docs

Update README and any docs the change touches, in the same branch. A docs PR
"to follow" does not follow. If genuinely not doc-relevant, say so in one line
rather than skipping silently.

## Phase 5, Council

Convene the `council` skill on the full diff vs base: the PR lenses
(correctness, design, tests, fit). `simplify` may run on the diff before
council, to cut what it would flag. Follow the council rules exactly: run the
suite yourself first and say its status in the shared prompt; any BLOCK sends
the work back to Phase 2; abstentions are never approvals; hand the verdict
back. If the council blocks: fix in a new round, re-run the phase gates you
skipped past, re-convene on the new diff.

## Phase 6, Ship

Follow the `ship` command exactly: feature branch, Conventional Commits,
push, PR, auto-merge only on an APPROVE verdict with green CI. Never merge,
never push to main, never force-push. Say in the PR body how it was verified
(the prove lines) and the council verdict.

## Hard rules

- **No completion claim without fresh evidence.** Every phase gate carries
  its prove line; the handback carries the final one.
- **A red gate stops the line.** Reporting the stop is a success state;
  shipping past one is the failure.
- **One change at a time.** Scope creep discovered mid-build gets noted for
  the operator, not built.
- **Delegated work is your work.** You dispatched it; you read the diff.
- **The operator can stop or redirect at any phase boundary.** Gates are
  natural checkpoints, and `/build` pauses there when a decision is genuinely
  theirs.

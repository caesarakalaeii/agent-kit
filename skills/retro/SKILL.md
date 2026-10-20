---
name: retro
description: Use after /ship finishes, after a /build stops on a red gate, or when asked for a retrospective. Turns what happened in one task into at most three evidence-backed lessons in a persistent lessons file that later /build runs read before they plan.
---

# retro

One task's experience, distilled into lessons the next task can use. The idea
comes from the experience reflector in
[Harness²](https://github.com/google-research/harness2): after each task, keep
only the lessons the evidence supports, and feed them into the next round of
refinement. Here the "improvement harness" is a pair of markdown files and the
next round is the next `/build`.

## Where lessons live

`$AK_LESSONS_DIR` (set by `ak-omp` and `ak-claude`, default
`~/.local/state/agent-kit/lessons`):

- `<repo>.md`, where `<repo>` is the basename of `git rev-parse
  --show-toplevel`: lessons about this project (its build, its test quirks,
  its CI, its architecture traps).
- `_global.md`: lessons about how work goes in general (planning, wave sizing,
  review, tooling) that held in more than one project.

Neither file is committed anywhere. They can name local paths and half-formed
judgements without leaking into a public repo.

## Procedure

1. **Collect the evidence.** The plan file and its `ponytail` cut list, the
   council verdicts (every round, not only the last), red gates and how they
   were fixed, CI runs (`gh pr checks`, `gh run view --log-failed` on a red
   one), the number of fix rounds, anything the operator corrected. If the
   task stopped on a red gate, that stop is the most important evidence.
2. **Read both lessons files first.** A lesson that is already there gets its
   `seen` count raised and the new evidence appended, not a duplicate entry.
   A lesson this task contradicts gets corrected or deleted, with the
   contradicting evidence.
3. **Write at most three new lessons.** Each one must:
   - point at evidence a later session can check: a PR or commit URL, a CI
     run, a quoted error line, a council finding;
   - say when it applies, so a later `/build` can tell whether it is relevant;
   - be an instruction someone can act on, not a feeling ("CI here has no
     browser; ui-review screenshots must run locally before push", not "UI
     testing was hard").

   No evidence, no lesson. "Went fine" is a valid outcome and writes nothing.
4. **Choose the scope.** Project file by default. `_global.md` only when the
   same lesson already appears in another project's file (then move it, do not
   copy it) or when it is about the pipeline itself.
5. **Keep the files short.** Over 30 entries, merge overlapping lessons and
   drop the ones with `seen: 1` that are older than the rest and no longer
   match the code. A long lessons file stops being read.
6. **Propose, do not apply, pipeline changes.** If a lesson says a skill or
   command in agent-kit itself is wrong (a gate that keeps misfiring, a step
   every build skips), say so in the handback with the lesson and its
   evidence. Changing agent-kit is its own `/build` in the agent-kit repo.

## Entry format

```markdown
## <one-line lesson, imperative>
- applies when: <situation>
- evidence: <URL or quoted line>, <URL or quoted line>
- seen: <n>, last <YYYY-MM-DD>
```

## Verification

You are done when: both files were read before writing; every new or updated
entry has evidence a later session can open; no more than three new entries
were added; the handback lists what was added, raised, corrected or
dropped, plus any proposed agent-kit change, or says plainly that the task
produced no lesson.

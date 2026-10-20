---
name: simplify
description: Use after a change works but before the handback or PR, to review the diff for reuse, simplification, efficiency and altitude problems and then apply the cuts. Also use when the user says "simplify", "clean this up", "what can we delete", "is this over-engineered", or asks for a review that only targets complexity. Quality only; it does not hunt for correctness bugs, that is council.
---

# simplify

**A diff gets reviewed for whether it is right, almost never for whether it is
too much.** So the second kind of debt accumulates unopposed: the helper written
twice, the abstraction with one caller, the loop that the standard library
already ships. This is the pass that only looks for that, and unlike a review, it
fixes what it finds.

`ponytail` keeps code from being written. This runs after it was.

## When it runs

After the change works and its tests pass, before any doc phase and before the
handback. Scope is **the diff**, not the repo: `git diff` against the base
branch, or the files the session touched. Cleaning up code the change never
touched turns a reviewable diff into an unreviewable one; if you spot something
outside the diff, name it in one line at the end and leave it alone.

## The four lenses

Run all four over the diff. One line per finding: where it is, what comes out,
what replaces it.

**Reuse** the repo already has this. A helper, a type, a constant, a pattern a
few files over. Re-implementing what already exists is the single most common
finding, and the only one that gets worse the longer it sits, because now there
are two of them to keep in sync. Grep before you conclude the diff invented
something new.

**Simplification** same behaviour, less code. Hand-rolled stdlib, a class where
a function works, a wrapper that only delegates, a branch that cannot be reached,
a config value nobody sets, an interface with one implementation. Also flags: an
abstraction introduced for a second caller that does not exist yet.

**Efficiency** the obviously wasteful shape, not micro-optimisation. A query in
a loop, a full scan where a lookup exists, a file read twice, work done on every
call that could be done once. If judging it requires a profiler, it is out of
scope, and you say so and move on.

**Altitude** code at the wrong level. A low-level detail (a header name, a
retry count, an SQL fragment) leaking into a function that reads as business
logic, or one concern smeared across five call sites that should own it in one
place. Altitude problems are what make a diff feel fine line by line and wrong as
a whole, so this is the lens worth spending the most time in.

## Apply, then verify

This skill does not hand back a list. For each finding, either apply it or say in
one line why you did not. Then **re-run the tests and the linter**: a
simplification that changes behaviour is not a simplification, and this pass
edits working code, which makes it exactly the kind of change that quietly breaks
something at the end of a session when attention is lowest.

If a cut is a judgement call rather than an obvious win, apply the obvious ones
and ask about the rest in one line. Do not batch fifteen speculative rewrites
into one diff.

Finish with: `net: -<N> lines.` Nothing to cut: `Lean already. Ship.` say that
plainly rather than inventing a finding to justify the pass.

## Out of scope

- **Correctness, security and blast radius.** Route those to `council`, which reviews with several narrow lenses and can block. A bug found here still gets reported, just do not fix it under this skill and call the result a cleanup.
- **Behaviour changes, renames across the repo, dependency bumps, reformatting.** All of them bury the actual change in noise.
- **The harness's own checks and policy.** A check that looks duplicated is usually a second layer catching what the first one structurally cannot see. Nothing there gets simplified as part of a cleanup pass; that is its own change, with its own reasoning, in its own PR.
- **Vendored files.** The `ponytail` skill tracks an upstream repo. Editing it for style makes the next sync a manual merge.
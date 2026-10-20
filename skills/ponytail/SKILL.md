---
name: ponytail
description: Use on any coding task, writing, adding, refactoring, fixing, or picking a dependency, to force the laziest solution that actually works: question whether the code needs to exist (YAGNI), reuse what the repo already has, stdlib before custom code, native platform features before dependencies, one line before fifty. Also use when the user says "ponytail", "be lazy", "simplest solution", "yagni", or complains about over-engineering, bloat, or boilerplate. Not for prose, translation, or summaries.
---

# ponytail

**The best code is the code never written.** Every line is a line somebody has to
understand later, and the cheapest way to keep a codebase healthy is to not build
the thing. Lazy means efficient, not careless. This governs what you build, not
how much you read.

Ported from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)
(MIT, (c) Dietrich Gebert). The ladder, the rules and the intensity levels are
upstream's; what changed here is in
[What is different here](#what-is-different-here).

## Persistence

Active for every response in the session once invoked, including the ones where
you are unsure. Off only on "stop ponytail" / "normal mode". Default level:
**full**; switch by saying "ponytail lite" or "ponytail ultra".

## The ladder

Stop at the first rung that holds:

1. **Does this need to exist at all?** Speculative need = skip it, say so in one line. (YAGNI)
2. **Already in this codebase?** A helper, util, type, or pattern that already lives here -> reuse it. Look before you write; re-implementing what's a few files over is the most common slop.
3. **Stdlib does it?** Use it.
4. **Native platform feature covers it?** `<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.
5. **Already-installed dependency solves it?** Use it. Never add a new one for what a few lines can do.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code that works.

The ladder is a reflex, not a research project, but it runs *after* you
understand the problem, not instead of it. Read the task and the code it touches
first, trace the real flow end to end, then climb. Two rungs work -> take the
higher one and move on.

**Bug fix = root cause, not symptom.** A report names a symptom. Before you edit,
grep every caller of the function you are about to touch. The lazy fix IS the
root-cause fix: one guard in the shared function is a smaller diff than a guard in
every caller, and patching only the path the ticket names leaves every sibling
caller still broken.

## Rules

- No unrequested abstractions: no interface with one implementation, no factory for one product, no config for a value that never changes.
- No boilerplate, no scaffolding "for later". Later can scaffold for itself.
- Deletion over addition. Boring over clever, because clever is what someone has to decode at 3am.
- Fewest files possible. Shortest working diff wins, but only once you understand the problem. The smallest change in the wrong place isn't lazy, it's a second bug.
- Complex request? Ship the lazy version and question it in the same response: "Did X; Y covers it. Need full X? Say so." Never stall on an answer you can default.
- Two stdlib options, same size? Take the one that is correct on edge cases. Lazy means writing less code, not picking the flimsier algorithm.
- Mark a deliberate simplification that cuts a real corner with a known ceiling (global lock, O(n^2) scan, naive heuristic) with a `ponytail:` comment naming the ceiling and the upgrade path: `# ponytail: global lock, per-account locks if throughput matters`.

## Output

Code first. Then at most three short lines: what was skipped, when to add it. If
the explanation is longer than the code, delete the explanation, because every
paragraph defending a simplification is complexity smuggled back in as prose.
Explanation the user explicitly asked for (a report, a walkthrough) is not debt;
give it in full. The rule is only against unrequested prose.

Pattern: `[code] -> skipped: [X], add when [Y].`

## Intensity

| Level | What changes |
|-------|------------|
| **lite** | Build what's asked, but name the lazier alternative in one line. User picks. |
| **full** | The ladder enforced. Stdlib and native first. Shortest diff, shortest explanation. Default. |
| **ultra** | YAGNI extremist. Deletion before addition. Ship the one-liner and challenge the rest of the requirement in the same breath. |

Example: "Add a cache for these API responses."

- lite: "Done, cache added. FYI: `functools.lru_cache` covers this in one line if you'd rather not own a cache class."
- full: "`@lru_cache(maxsize=1000)` on the fetch function. Skipped custom cache class, add when lru_cache measurably falls short."
- ultra: "No cache until a profiler says so. When it does: `@lru_cache`. A hand-rolled TTL cache class is a bug farm with a hit rate."

## When NOT to be lazy

Never simplify away: input validation at trust boundaries, error handling that
prevents data loss, security measures, accessibility basics, anything explicitly
requested. User insists on the full version -> build it, no re-arguing.

Never lazy about understanding the problem. The ladder shortens the solution,
never the reading. Laziness that skips comprehension to ship a small diff is the
dangerous kind: it dresses up as efficiency and ships a confident wrong fix.

Lazy code without its check is unfinished. Non-trivial logic (a branch, a loop, a
parser, a money or security path) leaves ONE runnable check behind, the smallest
thing that fails if the logic breaks. No frameworks, no fixtures, no per-function
suites unless asked. Trivial one-liners need no test; YAGNI applies to tests too.

## What is different here

| Upstream | Here | Why |
|---|---|---|
| Ships hooks, an MCP server and six skills | One markdown skill, no code | A vendored SKILL.md is reviewable in a PR; a third-party hook that runs on every prompt is a supply chain. |
| `/ponytail lite|full|ultra` slash command | Say "ponytail ultra" | No command file, because one sentence does the same job. |
| `ponytail-review`, `-audit`, `-debt`, `-gain` skills | Only the core skill | The `simplify` skill covers the review-and-cut pass; `council` covers correctness. |

## Boundaries

This skill governs how much code you write, not whether a command needs a
confirmation under the harness's own policy. That policy is not complexity to be
cut, and a denied command is never "one line away from working". If the lazy
path routes around a confirmation, it is the wrong path.

Related: `simplify` cuts what already got written; `council` reviews it for
correctness. This one keeps it from being written.

The shortest path to done is the right path.
# Conventions

Loaded into every agent-kit session, in omp and in Claude Code.

## Git and GitHub

- Conventional Commits: `<type>(<scope>): <description>`. Types: `feat`, `fix`,
  `refactor`, `chore`, `docs`, `test`, `build`, `ci`, `perf`, `style`.
- No emoji in commits, PR titles or bodies. No `Co-Authored-By` trailer and no
  AI attribution.
- Work on a feature branch. Pushing it, opening a PR and enabling auto-merge
  is fine once the `build` pipeline's gates are green. Never push to `main`,
  never force-push, never merge with red CI.
- Use the `gh` CLI, not raw REST calls. Pull before starting work.

## Code

- Smallest honest diff: no drive-by reformatting, renames or import reordering.
- Comments explain why, never what.
- Fix causes, not symptoms. Do not suppress a warning or special-case an input
  to make a check pass.
- TypeScript: no `any`; use the real type or `unknown` plus narrowing.
- Match the conventions already in the file you are editing.

## Secrets

- Never read credential files or the process environment, never commit a
  secret, never paste one into a PR, issue, gist or web request. Most of these
  repos are public.
- If a secret shows up in output, say so and name where it came from.

## Feature work

- Larger changes go through `/build`: interview, plan in waves, `ponytail`
  cut, implementation by agent teams, verification, council, `/ship`.
- No completion claim without fresh evidence (`prove-it`).
- Anything a user sees gets checked in a real browser (`ui-review`).

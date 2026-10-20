# agent-kit

Personal agent setup for hobby projects, for both
[oh-my-pi](https://github.com/can1357/oh-my-pi) (`omp`) and
[Claude Code](https://code.claude.com) (`claude`). It does three things:

- **Custom UI with a design bar**: `frontend-design` sets the standard,
  `ui-review` checks the result in a real browser at desktop and mobile widths.
- **Chromium under agent control**: Playwright, as a CLI (`playwright-cli`) for
  scripted runs and as an MCP server (`playwright`) for exploratory sessions.
- **Features built end to end**: `/build` runs interview, wave-structured
  plan, `ponytail` cut, implementation by agent teams, verification, a review
  council, then `/ship` pushes, opens the PR and auto-merges once the council
  approves and CI is green. A closing `retro` records what the task taught.

## Lessons

After each `/build` (shipped or stopped on a red gate), the `retro` skill
writes at most three lessons, each tied to checkable evidence such as a PR,
CI run or quoted error, into `~/.local/state/agent-kit/lessons/`: one file per
project plus `_global.md`. The next `/build` reads both before it plans. The
files are never committed. Changes to agent-kit itself are proposed, not
applied. The idea is the experience reflector from
[Harness²](https://github.com/google-research/harness2), reduced to markdown.

## Isolation

Both harnesses run from their own config directories, so nothing installed for
another context (plugins, skills, rules, memory, MCP servers, logins) leaks
into these sessions, and nothing from here leaks out.

| | omp | Claude Code |
|---|---|---|
| Launcher | `ak-omp` | `ak-claude` |
| User base | `~/.omp-agent-kit` (`PI_CONFIG_DIR`) | `~/.claude-agent-kit` (`CLAUDE_CONFIG_DIR`) |
| Policy | overlay `omp/config.yml`: yolo plus a deny list | `claude/settings.json` via `--settings`: auto mode (classifier) plus deny rules |
| Memory | `local` backend | built-in auto memory |
| Teams | `task` batches per wave | agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) |

omp has no classifier mode, so yolo with deny patterns is the closest thing to
Claude Code's auto mode. A named `omp --profile` is not enough isolation: the
plugin root is shared across profiles.

### Personal deny list

`~/.config/agent-kit/deny-paths` (created on install, never committed) lists
paths these sessions must not touch, one per line, such as a work checkout.
Every launch turns it into omp bash deny patterns and into Claude Code
`Read`/`Edit` deny rules plus an auto mode `hard_deny` entry.

## Install

Needs `git`, `jq`, and either `nix` or Node (`npx`) for Playwright. On NixOS
the system `chromium` is used for `playwright-cli`, and `playwright-mcp` comes
from nixpkgs with its own browsers.

```bash
git clone https://github.com/caesarakalaeii/agent-kit ~/Hobby/agent-kit
~/Hobby/agent-kit/install.sh
```

The installer clones the pinned upstream skills, links skills, agents and
commands into both config directories, registers the Playwright MCP server,
and puts `ak-omp` and `ak-claude` into `~/.local/bin`. Re-run it after a pull.
`./install.sh --check` reports state without changing anything,
`./install.sh --uninstall` removes what it created and keeps logins and
sessions.

First launch of each harness needs a login (`/login`), since the config
directories are fresh.

## Contents

| Path | What |
|---|---|
| `skills/` | own skills: `ponytail`, `simplify`, `prove-it`, `council`, `ui-review`, `retro` |
| `agents/council-reviewer.md` | one lens of the review council |
| `commands/build.md`, `commands/ship.md` | the delivery pipeline |
| `rules/conventions.md` | always-loaded conventions (omp `RULES.md`, Claude Code `CLAUDE.md` import) |
| `upstream.lock` | third-party skills, pinned by commit |
| `libexec/` | `playwright-cli` and `playwright-mcp` shims, on `PATH` only inside sessions |

Third-party skills, linked from the pinned clones:

- [obra/superpowers](https://github.com/obra/superpowers) (MIT): brainstorming,
  writing-plans, executing-plans, subagent-driven-development,
  dispatching-parallel-agents, test-driven-development, systematic-debugging,
  verification-before-completion, using-git-worktrees,
  finishing-a-development-branch, receiving-code-review
- [anthropics/skills](https://github.com/anthropics/skills): frontend-design,
  skill-creator
- [microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)
  (Apache-2.0): playwright-cli

To bump a pin, edit the SHA in `upstream.lock`, read the upstream diff, and
re-run `./install.sh`. Own skills win name collisions.

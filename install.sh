#!/usr/bin/env bash
# agent-kit installer. Idempotent; re-run after pulling or bumping a pin.
#   ./install.sh             install or update
#   ./install.sh --check     report state, change nothing
#   ./install.sh --uninstall remove everything this script created
set -euo pipefail
REPO=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
. "$REPO/lib/common.sh"

BIN_DIR="$HOME/.local/bin"
UPSTREAM="$AK_DATA/upstream"
MARK="managed by agent-kit/install.sh"
failed=0

ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; failed=1; }

have() { command -v "$1" >/dev/null 2>&1; }

harness_dirs() {
  have omp && printf '%s\n' "$AK_OMP_AGENT"
  have claude && printf '%s\n' "$AK_CLAUDE_HOME"
  return 0
}

# Symlinks pointing into this repo or the upstream cache are ours.
is_ours() {
  [ -L "$1" ] || return 1
  case "$(readlink -- "$1")" in "$REPO"/* | "$AK_DATA"/*) return 0 ;; esac
  return 1
}

prune_links() {
  for base in "$AK_OMP_AGENT" "$AK_CLAUDE_HOME"; do
    for f in "$base"/skills/* "$base"/agents/* "$base"/commands/* "$base"/RULES.md; do
      is_ours "$f" && rm -f -- "$f"
    done
  done
  for f in "$BIN_DIR/ak-omp" "$BIN_DIR/ak-claude"; do
    is_ours "$f" && rm -f -- "$f"
  done
  return 0
}

link() { # <target> <link>
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] && ! is_ours "$2"; then
    fail "$2 exists and is not ours; not replacing it"
    return 0
  fi
  ln -sfn "$1" "$2"
}

lock_lines() { grep -E "^$1[[:space:]]" "$REPO/upstream.lock" || true; }

fetch_upstream() {
  mkdir -p "$UPSTREAM"
  while read -r _ name url sha; do
    dir="$UPSTREAM/$name"
    if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)" = "$sha" ]; then
      ok "upstream $name at ${sha:0:12}"
      continue
    fi
    [ -d "$dir/.git" ] || git init -q "$dir"
    git -C "$dir" remote remove origin 2>/dev/null || true
    git -C "$dir" remote add origin "$url"
    if git -C "$dir" fetch -q --depth 1 origin "$sha" && git -C "$dir" checkout -q --detach FETCH_HEAD; then
      ok "upstream $name pinned to ${sha:0:12}"
    else
      fail "could not fetch $url at $sha"
    fi
  done < <(lock_lines repo)
}

# name -> source directory, own skills first so upstream cannot shadow them.
skill_sources() {
  for d in "$REPO"/skills/*/; do
    printf '%s\t%s\n' "$(basename "$d")" "${d%/}"
  done
  lock_lines skill | while read -r _ repo path; do
    printf '%s\t%s\n' "$(basename "$path")" "$UPSTREAM/$repo/$path"
  done
}

install_links() {
  prune_links
  while IFS= read -r base; do
    while IFS=$'\t' read -r name src; do
      if [ -f "$src/SKILL.md" ]; then
        [ -e "$base/skills/$name" ] && is_ours "$base/skills/$name" && continue
        link "$src" "$base/skills/$name"
      else
        fail "skill $name: no SKILL.md at $src"
      fi
    done < <(skill_sources)
    for f in "$REPO"/agents/*.md "$REPO"/commands/*.md; do
      kind=$(basename "$(dirname "$f")")
      link "$f" "$base/$kind/$(basename "$f")"
    done
    ok "skills, agents, commands linked into $base"
  done < <(harness_dirs)
  if have omp; then
    link "$REPO/rules/conventions.md" "$AK_OMP_AGENT/RULES.md"
  fi
  if have claude; then
    claude_md="$AK_CLAUDE_HOME/CLAUDE.md"
    if [ -e "$claude_md" ] && ! grep -qF "$MARK" "$claude_md"; then
      fail "$claude_md exists and is not ours; add this line to it: @$REPO/rules/conventions.md"
    else
      printf '<!-- %s -->\n@%s\n' "$MARK" "$REPO/rules/conventions.md" >"$claude_md"
    fi
  fi
}

mcp_json() {
  jq -n --arg cmd "$REPO/libexec/playwright-mcp" \
    '{mcpServers: {playwright: {command: $cmd, args: []}}}'
}

install_mcp() {
  mkdir -p "$AK_DATA"
  mcp_json >"$AK_DATA/claude-mcp.json"
  if have omp; then
    f="$AK_OMP_AGENT/mcp.json"
    mkdir -p "$AK_OMP_AGENT"
    if [ -f "$f" ]; then
      jq --slurpfile ours <(mcp_json) '.mcpServers.playwright = $ours[0].mcpServers.playwright' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
    else
      mcp_json >"$f"
    fi
  fi
  ok "playwright MCP registered"
}

install_deny_template() {
  [ -f "$AK_DENY_FILE" ] && return 0
  mkdir -p "$AK_CONFIG"
  cat >"$AK_DENY_FILE" <<'EOF'
# Paths agent-kit sessions must never touch, one per line. Personal and
# untracked: put your work checkouts and work credentials here. Applied to
# omp (bash deny patterns) and Claude Code (Read/Edit deny + auto mode
# hard_deny) on every launch.
# ~/work
EOF
  ok "created $AK_DENY_FILE (edit it)"
}

install_bin() {
  link "$REPO/bin/ak-omp" "$BIN_DIR/ak-omp"
  link "$REPO/bin/ak-claude" "$BIN_DIR/ak-claude"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ok "ak-omp, ak-claude in $BIN_DIR" ;;
    *) warn "$BIN_DIR is not on PATH; add it, or call $REPO/bin/ak-omp directly" ;;
  esac
}

check() {
  have git || fail "git missing"
  have jq || fail "jq missing"
  have omp || warn "omp not found: skipping omp wiring"
  have claude || warn "claude not found: skipping Claude Code wiring"
  have nix || have npx || fail "neither nix nor npx: Playwright cannot start"
  while read -r _ name _ sha; do
    [ "$(git -C "$UPSTREAM/$name" rev-parse HEAD 2>/dev/null || true)" = "$sha" ] ||
      fail "upstream $name not at pinned ${sha:0:12}"
  done < <(lock_lines repo)
  while IFS= read -r base; do
    n=0
    for f in "$base"/skills/*; do [ -f "$f/SKILL.md" ] && n=$((n + 1)); done
    want=$(skill_sources | cut -f1 | sort -u | wc -l)
    [ "$n" -ge "$want" ] && ok "$base: $n skills" || fail "$base: $n of $want skills resolve"
    for f in "$base"/skills/* "$base"/agents/* "$base"/commands/*; do
      [ -L "$f" ] && [ ! -e "$f" ] && fail "dangling link $f"
    done
  done < <(harness_dirs)
  if have omp; then
    ov=$(ak_render_omp_overlay)
    want=$(grep -c 'approval: deny' "$ov")
    have_n=$(env -u OMP_PROFILE -u PI_PROFILE -u PI_CODING_AGENT_DIR \
      PI_CONFIG_DIR="$AK_OMP_DIRNAME" PI_CONFIG_FILES="$ov" \
      omp config get bash.patterns 2>/dev/null | jq length 2>/dev/null || echo 0)
    if [ "$have_n" = "$want" ]; then
      ok "omp overlay in force: $have_n deny patterns"
    else
      fail "omp overlay: $have_n of $want deny patterns resolve ($ov)"
    fi
  fi
  if have claude; then
    jq -e .permissions "$(ak_render_claude_settings)" >/dev/null && ok "claude settings render"
  fi
  return 0
}

uninstall() {
  prune_links
  rm -f "$AK_DATA/claude-mcp.json" "$AK_DATA/claude-settings.json" "$AK_DATA/omp-overlay.yml"
  [ -f "$AK_CLAUDE_HOME/CLAUDE.md" ] && grep -qF "$MARK" "$AK_CLAUDE_HOME/CLAUDE.md" && rm -f "$AK_CLAUDE_HOME/CLAUDE.md"
  f="$AK_OMP_AGENT/mcp.json"
  [ -f "$f" ] && jq 'del(.mcpServers.playwright)' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
  rm -rf "$UPSTREAM"
  ok "removed links, generated files and upstream clones"
  printf '  kept  %s, %s, %s (auth, sessions, your edits)\n' "$HOME/$AK_OMP_DIRNAME" "$AK_CLAUDE_HOME" "$AK_CONFIG"
}

case "${1:-}" in
  "")
    have git && have jq || { echo "need git and jq" >&2; exit 1; }
    fetch_upstream
    install_links
    install_mcp
    install_deny_template
    install_bin
    check
    ;;
  --check) check ;;
  --uninstall) uninstall ;;
  *) echo "usage: $0 [--check|--uninstall]" >&2; exit 2 ;;
esac
exit "$failed"

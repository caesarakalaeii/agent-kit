# Sourced by install.sh and bin/*. Requires REPO to be set.
# shellcheck shell=bash

# PI_CONFIG_DIR moves omp's whole user base (auth, plugins, profiles, sessions)
# out of ~/.omp. A named --profile is not enough: the plugin root under
# ~/.omp/plugins is shared by every profile, so a plugin installed for another
# context loads here too.
AK_OMP_DIRNAME=.omp-agent-kit
AK_OMP_AGENT="$HOME/$AK_OMP_DIRNAME/agent"
AK_CLAUDE_HOME="$HOME/.claude-agent-kit"
AK_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/agent-kit"
AK_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/agent-kit"
AK_DENY_FILE="$AK_CONFIG/deny-paths"

# Prints one absolute path per line from the personal deny list.
ak_deny_paths() {
  [ -f "$AK_DENY_FILE" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    case "$line" in
      "~/"*) line="$HOME/${line#\~/}" ;;
    esac
    printf '%s\n' "${line%/}"
  done <"$AK_DENY_FILE"
}

# omp overlay = repo template + one deny pattern per personal path. Arrays are
# replaced, not merged, across overlays, so the personal entries have to land
# in the same bash.patterns list as the shared ones.
ak_render_omp_overlay() {
  out="$AK_DATA/omp-overlay.yml"
  mkdir -p "$AK_DATA"
  {
    cat "$REPO/omp/config.yml"
    ak_deny_paths | while IFS= read -r p; do
      printf '    - { match: "*%s*", approval: deny }\n' "$p"
      case "$p" in
        "$HOME"/*) printf '    - { match: "*~/%s*", approval: deny }\n' "${p#"$HOME"/}" ;;
      esac
    done
  } >"$out.tmp"
  mv "$out.tmp" "$out"
  printf '%s\n' "$out"
}

# Claude Code flag settings = repo settings + Read/Edit denies and a classifier
# hard_deny per personal path.
ak_render_claude_settings() {
  out="$AK_DATA/claude-settings.json"
  mkdir -p "$AK_DATA"
  paths=$(ak_deny_paths | jq -R . | jq -s .)
  jq --argjson paths "$paths" '
    .permissions.deny += ($paths | map("Read(/" + . + "/**)", "Edit(/" + . + "/**)"))
    | if ($paths | length) > 0 then
        .autoMode.hard_deny = ((.autoMode.hard_deny // ["$defaults"]) + ["Never read, list, search, copy or modify anything under these paths, by any tool or command: " + ($paths | join(", ")) + ". They belong to a different context and are out of bounds for this agent."])
      else . end
  ' "$REPO/claude/settings.json" >"$out.tmp"
  mv "$out.tmp" "$out"
  printf '%s\n' "$out"
}

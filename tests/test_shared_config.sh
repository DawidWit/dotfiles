#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home" "$tmp_dir/cache" "$tmp_dir/config" "$tmp_dir/data" "$tmp_dir/state"
: >"$tmp_dir/config/chezmoi.toml"

render_template() {
  env \
    HOME="$tmp_dir/home" \
    XDG_CACHE_HOME="$tmp_dir/cache" \
    XDG_CONFIG_HOME="$tmp_dir/config" \
    XDG_DATA_HOME="$tmp_dir/data" \
    XDG_STATE_HOME="$tmp_dir/state" \
    chezmoi \
      --config "$tmp_dir/config/chezmoi.toml" \
      --source "$repo" \
      --destination "$tmp_dir/home" \
      --refresh-externals=never \
      execute-template <"$1"
}

semantic_color() {
  local rendered=$1 role=$2 key=$3 relation=$4

  printf '%s\n' "$rendered" | awk \
    -v role="$role" \
    -v key="$key" \
    -v relation="$relation" '
      function exact_key_position(scope, key, offset, position, candidate, previous) {
        offset = 0
        while ((position = index(substr(scope, offset + 1), key)) > 0) {
          candidate = offset + position
          previous = candidate == 1 ? "" : substr(scope, candidate - 1, 1)
          if (candidate == 1 || previous == ",") return candidate
          offset = candidate
        }
        return 0
      }

      { source = source $0 }

      END {
        gsub(/[[:space:]]/, "", source)
        role_position = index(source, role)
        if (!role_position) exit

        if (relation == "table") {
          scope_start = role_position + length(role)
          depth = 1
          for (i = scope_start; i <= length(source); i++) {
            character = substr(source, i, 1)
            if (character == "{") depth++
            if (character == "}") depth--
            if (depth == 0) break
          }
          if (depth != 0) exit
          scope = substr(source, scope_start, i - scope_start)
          key_position = exact_key_position(scope, key)
          if (!key_position) exit
          value = substr(scope, key_position + length(key))
        } else if (relation == "after") {
          scope = substr(source, role_position + length(role))
          key_position = index(scope, key)
          if (!key_position) exit
          value = substr(scope, key_position + length(key))
        } else {
          scope = substr(source, 1, role_position - 1)
          offset = 0
          while ((position = index(substr(scope, offset + 1), key)) > 0) {
            offset += position
          }
          if (!offset) exit
          value = substr(scope, offset + length(key))
        }

        if (match(value, /#[[:xdigit:]]+/)) {
          print substr(value, RSTART, RLENGTH)
        }
      }
    '
}

rendered_tmux=$(render_template "$repo/dot_tmux.conf.tmpl")
assert_eq '#ff9e64' "$(semantic_color "$rendered_tmux" 'set-gstatus-left' 'fg=' after)"
assert_eq '#ff9e64' "$(semantic_color "$rendered_tmux" 'set-gwindow-status-current-format' 'bg=' after)"
assert_eq '#565f89' "$(semantic_color "$rendered_tmux" '│' 'fg=' before)"

rendered_wezterm=$(render_template "$repo/private_dot_config/wezterm/wezterm.lua.tmpl")
assert_eq '#0d1428' "$(semantic_color "$rendered_wezterm" 'config.window_frame={' 'active_titlebar_bg=' table)"
assert_eq '#16161e' "$(semantic_color "$rendered_wezterm" 'config.window_frame={' 'inactive_titlebar_bg=' table)"
assert_eq '#0d1428' "$(semantic_color "$rendered_wezterm" ',active_tab={' 'bg_color=' table)"
assert_eq '#c0caf5' "$(semantic_color "$rendered_wezterm" ',active_tab={' 'fg_color=' table)"
assert_eq '#16161e' "$(semantic_color "$rendered_wezterm" ',inactive_tab={' 'bg_color=' table)"
assert_eq '#565f89' "$(semantic_color "$rendered_wezterm" ',inactive_tab={' 'fg_color=' table)"
assert_eq '#7aa2f7' "$(semantic_color "$rendered_wezterm" 'Text=\047\047..workspace' 'Color=' before)"
assert_eq '#9ece6a' "$(semantic_color "$rendered_wezterm" 'Text=date..\047\047' 'Color=' before)"

rendered_nvim=$(render_template "$repo/private_dot_config/nvim/lua/plugins/palette.lua.tmpl")
assert_eq '#ff9e64' "$(semantic_color "$rendered_nvim" '\"Conditional\"' '[\"' before)"

rendered_gitconfig=$(env \
  HOME="$tmp_dir/home" \
  XDG_CACHE_HOME="$tmp_dir/cache" \
  XDG_CONFIG_HOME="$tmp_dir/config" \
  XDG_DATA_HOME="$tmp_dir/data" \
  XDG_STATE_HOME="$tmp_dir/state" \
  chezmoi \
    --config "$tmp_dir/config/chezmoi.toml" \
    --source "$repo" \
    --destination "$tmp_dir/home" \
    --refresh-externals=never \
    execute-template <"$repo/dot_gitconfig")

git_config="$tmp_dir/home/.gitconfig"
printf '%s\n' "$rendered_gitconfig" >"$git_config"
git_entries=$(HOME="$tmp_dir/home" GIT_CONFIG_NOSYSTEM=1 git config --global --list --show-origin)

assert_contains "$git_entries" $'file:'"$git_config"$'\tcore.editor=nvim'
assert_contains "$git_entries" $'file:'"$git_config"$'\tinit.defaultbranch=main'
assert_contains "$git_entries" $'file:'"$git_config"$'\tfetch.prune=true'
assert_contains "$git_entries" $'file:'"$git_config"$'\tpush.autosetupremote=true'
assert_contains "$git_entries" $'file:'"$git_config"$'\trerere.enabled=true'
assert_contains "$git_entries" $'file:'"$git_config"$'\tmerge.conflictstyle=zdiff3'
assert_contains "$git_entries" $'file:'"$git_config"$'\tdiff.algorithm=histogram'

pass 'shared templates use the palette and Git defaults render correctly'

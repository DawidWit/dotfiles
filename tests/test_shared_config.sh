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

rendered_tmux=$(render_template "$repo/dot_tmux.conf.tmpl")
assert_contains "$rendered_tmux" "set -g status-left '#[fg=#ff9e64,bg=default,bold] #S '"
assert_contains "$rendered_tmux" "set -g window-status-current-format '#[fg=#000000,bg=#ff9e64,bold] #I:#W '"
assert_contains "$rendered_tmux" '#[fg=#565f89,bg=default]│'

rendered_wezterm=$(render_template "$repo/private_dot_config/wezterm/wezterm.lua.tmpl")
assert_contains "$rendered_wezterm" $'  active_titlebar_bg = \'#0d1428\',\n  inactive_titlebar_bg = \'#16161e\','
assert_contains "$rendered_wezterm" $'    active_tab = {\n      bg_color = \'#0d1428\',\n      fg_color = \'#c0caf5\',\n      intensity = \'Bold\',\n    },'
assert_contains "$rendered_wezterm" $'    inactive_tab = {\n      bg_color = \'#16161e\',\n      fg_color = \'#565f89\',\n    },'
assert_contains "$rendered_wezterm" "Foreground = { Color = '#7aa2f7' }"
assert_contains "$rendered_wezterm" "Foreground = { Color = '#9ece6a' }"

rendered_nvim=$(render_template "$repo/private_dot_config/nvim/lua/plugins/palette.lua.tmpl")
assert_contains "$rendered_nvim" $'  ["#ff9e64"] = {\n    "Conditional",'

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

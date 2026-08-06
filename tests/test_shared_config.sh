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

for template in \
  "$repo/dot_tmux.conf.tmpl" \
  "$repo/private_dot_config/wezterm/wezterm.lua.tmpl" \
  "$repo/private_dot_config/nvim/lua/plugins/palette.lua.tmpl"; do
  rendered=$(render_template "$template")
  assert_contains "$rendered" '#ff9e64'
done

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

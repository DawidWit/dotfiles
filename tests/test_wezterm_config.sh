#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

assert_not_contains() {
  case "$1" in
  *"$2"*) fail "expected [$1] not to contain [$2]" ;;
  esac
}

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home" "$tmp_dir/cache" "$tmp_dir/config" "$tmp_dir/data" "$tmp_dir/state"
: >"$tmp_dir/config/chezmoi.toml"

render_template() {
  local platform=$1
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
      --override-data "{\"chezmoi\":{\"os\":\"$platform\"}}" \
      execute-template <"$repo/private_dot_config/wezterm/wezterm.lua.tmpl"
}

rendered_darwin=$(render_template darwin)
rendered_linux=$(render_template linux)

for rendered in "$rendered_darwin" "$rendered_linux"; do
  assert_not_contains "$rendered" 'config.disable_default_key_bindings = true'
  assert_not_contains "$rendered" "'/opt/homebrew/bin/tmux'"
  assert_not_contains "$rendered" "'/home/linuxbrew/.linuxbrew/bin/tmux'"
  assert_contains "$rendered" "config.default_prog = { 'tmux', 'new-session', '-A', '-s', 'main' }"
  assert_contains "$rendered" "PATH = inherited_path .. ':/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin'"
  assert_contains "$rendered" 'wezterm.column_width'
  assert_contains "$rendered" 'wezterm.truncate_right'
  assert_contains "$rendered" "bg_state_dir .. '/count'"
  assert_contains "$rendered" 'bg_index = default_index'
  assert_contains "$rendered" "image = 'background10.gif'"
done

assert_contains "$rendered_darwin" "key = 'c', mods = 'SUPER'"
assert_not_contains "$rendered_linux" "key = 'c', mods = 'SUPER'"

wezterm_bin=
if command -v wezterm >/dev/null 2>&1; then
  wezterm_bin=$(command -v wezterm)
elif [ -x /Applications/WezTerm.app/Contents/MacOS/wezterm ]; then
  wezterm_bin=/Applications/WezTerm.app/Contents/MacOS/wezterm
fi

if [ -n "$wezterm_bin" ]; then
  case "$(uname -s)" in
  Darwin) runtime_config=$rendered_darwin ;;
  *) runtime_config=$rendered_linux ;;
  esac
  printf '%s\n' "$runtime_config" >"$tmp_dir/wezterm.lua"
  keys=$(env \
    HOME="$tmp_dir/home" \
    XDG_CACHE_HOME="$tmp_dir/cache" \
    XDG_CONFIG_HOME="$tmp_dir/config" \
    XDG_DATA_HOME="$tmp_dir/data" \
    XDG_STATE_HOME="$tmp_dir/state" \
    "$wezterm_bin" --config-file "$tmp_dir/wezterm.lua" show-keys --lua)
  assert_contains "$keys" "act.Search 'CurrentSelectionOrEmptyString'"
  assert_contains "$keys" "act.SpawnTab 'CurrentPaneDomain'"
  assert_contains "$keys" 'act.ActivateTabRelative(1)'
else
  printf '%s\n' 'SKIP: WezTerm runtime config check (wezterm binary unavailable)'
fi

pass 'rendered wezterm configuration is portable and keeps native keys'

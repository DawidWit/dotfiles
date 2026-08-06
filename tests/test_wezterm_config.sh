#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

assert_not_contains() {
  case "$1" in
  *"$2"*) fail "expected [$1] not to contain [$2]" ;;
  esac
}

rendered=$(chezmoi execute-template <"$repo/private_dot_config/wezterm/wezterm.lua.tmpl")

assert_not_contains "$rendered" 'config.disable_default_key_bindings = true'
assert_contains "$rendered" 'wezterm.column_width'
assert_contains "$rendered" 'wezterm.truncate_right'
assert_contains "$rendered" "bg_state_dir .. '/count'"
assert_contains "$rendered" 'bg_index = default_index'

pass 'rendered wezterm configuration keeps native keys and handles unicode titles'

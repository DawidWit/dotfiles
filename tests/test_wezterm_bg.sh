#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
state_dir="$tmp_dir/cache/wezterm-bg"
mkdir -p "$state_dir"

printf '4' >"$state_dir/count"
XDG_CACHE_HOME="$tmp_dir/cache" bash "$repo/dot_local/bin/executable_wezterm-bg" reset
XDG_CACHE_HOME="$tmp_dir/cache" bash "$repo/dot_local/bin/executable_wezterm-bg" prev
assert_eq "$(<"$state_dir/current")" '3'

XDG_CACHE_HOME="$tmp_dir/cache" bash "$repo/dot_local/bin/executable_wezterm-bg" next
assert_eq "$(<"$state_dir/current")" '0'

printf 'not-an-index' >"$state_dir/current"
XDG_CACHE_HOME="$tmp_dir/cache" bash "$repo/dot_local/bin/executable_wezterm-bg" next
assert_eq "$(<"$state_dir/current")" '1'

printf '000' >"$state_dir/count"
printf '2' >"$state_dir/current"
XDG_CACHE_HOME="$tmp_dir/cache" bash "$repo/dot_local/bin/executable_wezterm-bg" next
assert_eq "$(<"$state_dir/current")" '3'

printf '08' >"$state_dir/count"
printf '2' >"$state_dir/current"
XDG_CACHE_HOME="$tmp_dir/cache" bash "$repo/dot_local/bin/executable_wezterm-bg" next
assert_eq "$(<"$state_dir/current")" '3'

pass 'wezterm background cycling wraps against the configured count'

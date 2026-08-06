#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

[ -f "$repo/.chezmoi.toml.tmpl" ] || fail 'missing Chezmoi config template'

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

home_dir="$tmp_dir/home"
config_dir="$tmp_dir/config"
data_dir="$tmp_dir/data"
cache_dir="$tmp_dir/cache"
state_dir="$tmp_dir/state"
source_dir="$tmp_dir/arbitrary source"
mkdir -p "$home_dir" "$config_dir/chezmoi" "$data_dir" "$cache_dir" "$state_dir" "$source_dir/.git"

cp "$repo/.chezmoi.toml.tmpl" "$source_dir/.chezmoi.toml.tmpl"
printf '%s\n' 'persisted source marker' >"$source_dir/dot_bootstrap-source"
printf '%s\n' \
  'sourceDir = "/previous/source"' \
  '' \
  '[data]' \
  'existingSetting = "preserved"' >"$config_dir/chezmoi/chezmoi.toml"

HOME="$home_dir" XDG_CONFIG_HOME="$config_dir" XDG_DATA_HOME="$data_dir" \
  XDG_CACHE_HOME="$cache_dir" XDG_STATE_HOME="$state_dir" \
  chezmoi --source "$source_dir" --no-tty init

resolved_source=$(HOME="$home_dir" XDG_CONFIG_HOME="$config_dir" XDG_DATA_HOME="$data_dir" \
  XDG_CACHE_HOME="$cache_dir" XDG_STATE_HOME="$state_dir" chezmoi source-path)
assert_eq "$source_dir" "$resolved_source"

preserved_value=$(HOME="$home_dir" XDG_CONFIG_HOME="$config_dir" XDG_DATA_HOME="$data_dir" \
  XDG_CACHE_HOME="$cache_dir" XDG_STATE_HOME="$state_dir" \
  chezmoi execute-template '{{ .existingSetting }}')
assert_eq 'preserved' "$preserved_value"

HOME="$home_dir" XDG_CONFIG_HOME="$config_dir" XDG_DATA_HOME="$data_dir" \
  XDG_CACHE_HOME="$cache_dir" XDG_STATE_HOME="$state_dir" chezmoi --no-tty apply
assert_eq 'persisted source marker' "$(<"$home_dir/.bootstrap-source")"

pass 'Chezmoi config preserves settings and persists an arbitrary source'

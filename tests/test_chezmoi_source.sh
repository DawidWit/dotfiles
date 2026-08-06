#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home" "$tmp_dir/cache" "$tmp_dir/config" "$tmp_dir/data"

if ! output=$(HOME="$tmp_dir/home" \
  XDG_CACHE_HOME="$tmp_dir/cache" \
  XDG_CONFIG_HOME="$tmp_dir/config" \
  XDG_DATA_HOME="$tmp_dir/data" \
  chezmoi --source "$repo" \
    --destination "$tmp_dir/home" \
    --no-tty \
    --refresh-externals=never \
    --dry-run \
    --verbose \
    apply 2>&1); then
  printf '%s\n' "$output" >&2
  fail 'whole-source chezmoi dry-run failed'
fi

assert_contains "$output" '.config/zsh/aliases.zsh'
assert_contains "$output" '.config/zsh/integrations.zsh'
assert_contains "$output" '.config/zsh/kompas.zsh'

pass 'whole-source chezmoi dry-run includes modular Zsh configuration'

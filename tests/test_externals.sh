#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home" "$tmp_dir/config"
: >"$tmp_dir/config/chezmoi.toml"

routine_render=$(HOME="$tmp_dir/home" DOTFILES_BOOTSTRAP_EXTERNALS= \
  chezmoi --config "$tmp_dir/config/chezmoi.toml" --source "$repo" execute-template \
  <"$repo/.chezmoiexternal.toml.tmpl")
assert_eq '' "$routine_render"

bootstrap_render=$(HOME="$tmp_dir/home" DOTFILES_BOOTSTRAP_EXTERNALS=1 \
  chezmoi --config "$tmp_dir/config/chezmoi.toml" --source "$repo" execute-template \
  <"$repo/.chezmoiexternal.toml.tmpl")
assert_contains "$bootstrap_render" 'ohmyzsh/ohmyzsh/archive/'
assert_contains "$bootstrap_render" 'tmux-plugins/tpm/archive/'

pass 'Chezmoi externals render only for bootstrap'

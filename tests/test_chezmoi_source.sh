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
: >"$tmp_dir/chezmoi.toml"

if ! output=$(HOME="$tmp_dir/home" \
  XDG_CACHE_HOME="$tmp_dir/cache" \
  XDG_CONFIG_HOME="$tmp_dir/config" \
  XDG_DATA_HOME="$tmp_dir/data" \
  XDG_STATE_HOME="$tmp_dir/state" \
  DOTFILES_BOOTSTRAP_EXTERNALS= \
  HTTP_PROXY=http://127.0.0.1:9 \
  HTTPS_PROXY=http://127.0.0.1:9 \
  ALL_PROXY=http://127.0.0.1:9 \
  NO_PROXY= \
  http_proxy=http://127.0.0.1:9 \
  https_proxy=http://127.0.0.1:9 \
  all_proxy=http://127.0.0.1:9 \
  no_proxy= \
  chezmoi --config "$tmp_dir/chezmoi.toml" \
    --source "$repo" \
    --destination "$tmp_dir/home" \
    --no-tty \
    --dry-run \
    --verbose \
    apply 2>&1); then
  printf '%s\n' "$output" >&2
  fail 'whole-source chezmoi dry-run failed'
fi

assert_contains "$output" '.config/zsh/aliases.zsh'
assert_contains "$output" '.config/zsh/integrations.zsh'
assert_contains "$output" '.config/zsh/kompas.zsh'
assert_not_contains "$output" 'diff --git a/.oh-my-zsh'
assert_not_contains "$output" 'diff --git a/.tmux/plugins/tpm'
assert_not_contains "$output" 'github.com/ohmyzsh'

pass 'whole-source chezmoi dry-run is isolated and offline'

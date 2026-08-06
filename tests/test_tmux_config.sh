#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
tmux_socket="$tmp_dir/tmux.sock"
cleanup() {
  tmux -S "$tmux_socket" kill-server >/dev/null 2>&1 || true
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/home" "$tmp_dir/cache" "$tmp_dir/config" "$tmp_dir/data" "$tmp_dir/state"
: >"$tmp_dir/config/chezmoi.toml"

rendered=$(env \
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
    execute-template <"$repo/dot_tmux.conf.tmpl")
rendered_config="$tmp_dir/tmux.conf"
printf '%s\n' "$rendered" >"$rendered_config"

assert_contains "$rendered" 'default-terminal "tmux-256color"'
assert_contains "$rendered" 'terminal-features'
assert_contains "$rendered" 'RGB'
assert_contains "$rendered" 'set-clipboard on'
assert_contains "$rendered" 'history-limit 100000'
assert_contains "$rendered" 'renumber-windows on'
assert_contains "$rendered" 'base-index 1'
assert_contains "$rendered" 'pane-base-index 1'
assert_contains "$rendered" 'confirm-before'
assert_contains "$rendered" 'tmux-sessionizer'
assert_contains "$rendered" "@resurrect-capture-pane-contents 'off'"
assert_contains "$rendered" "@continuum-save-interval '60'"

tmux -S "$tmux_socket" -f "$rendered_config" new-session -d -s config-check
assert_success tmux -S "$tmux_socket" has-session -t config-check

pass 'rendered tmux configuration parses in an isolated server'

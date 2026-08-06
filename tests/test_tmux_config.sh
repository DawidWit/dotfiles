#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

rendered=$(chezmoi execute-template <"$repo/dot_tmux.conf.tmpl")

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

pass 'rendered tmux configuration enables safe terminal and session defaults'

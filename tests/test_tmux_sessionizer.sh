#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
project_dir="$tmp_dir/My Project"
mkdir -p "$project_dir"
log="$tmp_dir/tmux.log"

source "$repo/dot_local/bin/executable_tmux-sessionizer"

assert_eq "$(session_name '/tmp/My Project')" 'my-project'

TMUX=inside \
TMUX_SESSIONIZER_SELECTION="$project_dir" \
TMUX_SESSIONIZER_TMUX_LOG="$log" \
main

commands=$(<"$log")
assert_contains "$commands" 'new-session -d -s my-project'
assert_contains "$commands" 'switch-client -t my-project'

pass 'tmux sessionizer creates and switches to a normalized project session'

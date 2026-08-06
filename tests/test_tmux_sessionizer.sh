#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
project_dir="$tmp_dir/My Project"
mkdir -p "$project_dir"
log="$tmp_dir/tmux.log"
choices_log="$tmp_dir/choices.log"

source "$repo/dot_local/bin/executable_tmux-sessionizer"

assert_eq "$(session_name '/tmp/My Project')" 'my-project'

# An existing session remains selectable even when no zoxide path maps to it.
: >"$log"
TMUX=inside \
TMUX_SESSIONIZER_SELECTION=$'session\torphan-session' \
TMUX_SESSIONIZER_SESSIONS='orphan-session' \
TMUX_SESSIONIZER_PROJECTS="$project_dir" \
TMUX_SESSIONIZER_TMUX_LOG="$log" \
TMUX_SESSIONIZER_CHOICES_LOG="$choices_log" \
main

commands=$(<"$log")
assert_contains "$commands" 'switch-client -t orphan-session'
case "$commands" in
  *new-session*) fail 'selecting an existing session must not create a session' ;;
esac
choices=$(<"$choices_log")
assert_eq "$choices" $'session\torphan-session\nproject\t'"$project_dir"

# A zoxide path still creates its normalized session before switching to it.
: >"$log"
TMUX=inside \
TMUX_SESSIONIZER_SELECTION=$'project\t'"$project_dir" \
TMUX_SESSIONIZER_SESSIONS='other-session' \
TMUX_SESSIONIZER_PROJECTS="$project_dir" \
TMUX_SESSIONIZER_TMUX_LOG="$log" \
TMUX_SESSIONIZER_CHOICES_LOG="$choices_log" \
main

commands=$(<"$log")
assert_contains "$commands" 'new-session -d -s my-project'
assert_contains "$commands" 'switch-client -t my-project'

# When a project maps to an existing session, prefer the typed session choice
# and collapse repeated project records to one target.
: >"$log"
TMUX=inside \
TMUX_SESSIONIZER_SELECTION=$'session\tmy-project' \
TMUX_SESSIONIZER_SESSIONS='my-project' \
TMUX_SESSIONIZER_PROJECTS="$project_dir
$project_dir" \
TMUX_SESSIONIZER_TMUX_LOG="$log" \
TMUX_SESSIONIZER_CHOICES_LOG="$choices_log" \
main

commands=$(<"$log")
assert_contains "$commands" 'switch-client -t my-project'
case "$commands" in
  *new-session*) fail 'a de-duplicated existing session must not be recreated' ;;
esac
choices=$(<"$choices_log")
assert_eq "$choices" $'session\tmy-project'

pass 'tmux sessionizer combines typed sessions and projects without duplicates'

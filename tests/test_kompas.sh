#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/kompas-backend"

log="$tmp_dir/tmux.log"
KOMPAS_SCRIPT="$repo/dot_config/zsh/kompas.zsh" \
KOMPAS_BACKEND_REPO="$tmp_dir/kompas-backend" \
TMUX_LOG="$log" \
TMUX=inside \
zsh -fc '
  session_exists=0
  tmux() {
    printf "%s\\n" "$*" >> "$TMUX_LOG"
    if [ "$1" = has-session ]; then
      [ "$session_exists" -eq 1 ]
      return
    fi
    if [ "$1" = new-session ]; then
      session_exists=1
    elif [ "$1" = kill-session ]; then
      session_exists=0
    fi
  }

  source "$KOMPAS_SCRIPT"
  runkompasbackend
  stopkompasbackend
'

commands=$(<"$log")
assert_contains "$commands" 'new-session -d -s kompas-backend'
assert_contains "$commands" 'split-window -h -t kompas-backend'
assert_contains "$commands" './gradlew --no-daemon :kompas2:bootRun'
assert_contains "$commands" './gradlew --no-daemon :kompas2investments:bootRun'
assert_contains "$commands" 'select-layout -t kompas-backend even-horizontal'
assert_contains "$commands" 'switch-client -t kompas-backend'
assert_contains "$commands" 'kill-session -t kompas-backend'
case "$commands" in
  *pkill*) fail 'Kompas lifecycle must not kill processes by pattern' ;;
esac

missing_repo="$tmp_dir/missing-kompas-backend"
if missing_output=$(KOMPAS_SCRIPT="$repo/dot_config/zsh/kompas.zsh" KOMPAS_BACKEND_REPO="$missing_repo" zsh -fc '
  tmux() {
    print -u2 "tmux must not run for a missing repository"
    return 99
  }

  source "$KOMPAS_SCRIPT"
  runkompasbackend
' 2>&1); then
  fail 'Kompas startup succeeded without its backend repository'
fi
assert_contains "$missing_output" "Kompas backend repository not found: $missing_repo"

no_op_log="$tmp_dir/no-op-tmux.log"
no_op_output=$(KOMPAS_SCRIPT="$repo/dot_config/zsh/kompas.zsh" TMUX_LOG="$no_op_log" zsh -fc '
  tmux() {
    printf "%s\\n" "$*" >> "$TMUX_LOG"
    if [ "$1" = has-session ]; then
      return 1
    fi
    return 99
  }

  source "$KOMPAS_SCRIPT"
  stopkompasbackend
')
assert_contains "$no_op_output" 'Kompas backend is not running.'
no_op_commands=$(<"$no_op_log")
case "$no_op_commands" in
  *kill-session*) fail 'Kompas stop must not kill an absent session' ;;
esac

pass 'Kompas lifecycle uses daemon-free Gradle commands and safe session cleanup'

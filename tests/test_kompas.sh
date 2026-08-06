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
assert_contains "$commands" 'switch-client -t kompas-backend'
assert_contains "$commands" 'kill-session -t kompas-backend'
case "$commands" in
  *pkill*) fail 'Kompas lifecycle must not kill processes by pattern' ;;
esac

pass 'Kompas uses one named tmux session without broad process kills'

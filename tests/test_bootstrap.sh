#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

output=$(DOTFILES_SOURCE_DIR="$repo" DOTFILES_TEST_OS=Darwin bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run)
assert_contains "$output" 'brew bundle --file'
assert_contains "$output" 'chezmoi --refresh-externals apply'
assert_contains "$output" 'pnpm install --frozen-lockfile'
assert_contains "$output" 'pnpm rules:generate'
assert_contains "$output" 'dotfiles-doctor'

if DOTFILES_TEST_OS=Windows_NT bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run >/dev/null 2>&1; then
  fail 'unsupported OS succeeded'
fi

if DOTFILES_SOURCE_DIR="$repo" DOTFILES_TEST_OS=Darwin bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run unexpected >/dev/null 2>&1; then
  fail 'unexpected bootstrap argument succeeded'
fi

pass 'bootstrap dry-run reports the required plan and rejects unsupported OSes'

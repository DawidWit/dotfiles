#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

source_dir="$tmp_dir/source clone"
mkdir -p "$source_dir"
: >"$source_dir/Brewfile"
: >"$source_dir/package.json"

output=$(DOTFILES_SOURCE_DIR="$source_dir" DOTFILES_TEST_OS=Darwin bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run)
escaped_source_dir=$(printf '%q' "$source_dir")
assert_contains "$output" 'brew bundle --file'
assert_contains "$output" "$escaped_source_dir/Brewfile"
assert_contains "$output" "chezmoi --source $escaped_source_dir --no-tty init"
assert_contains "$output" "env DOTFILES_BOOTSTRAP_EXTERNALS=1 chezmoi --source $escaped_source_dir --refresh-externals apply"
assert_contains "$output" "pnpm --dir $escaped_source_dir install --frozen-lockfile"
assert_contains "$output" "pnpm --dir $escaped_source_dir rules:generate"
assert_contains "$output" 'dotfiles-doctor'

incomplete_source="$tmp_dir/incomplete-source"
mkdir -p "$incomplete_source"
: >"$incomplete_source/Brewfile"
if DOTFILES_SOURCE_DIR="$incomplete_source" DOTFILES_TEST_OS=Darwin bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run >/dev/null 2>&1; then
  fail 'bootstrap accepted a source without package.json'
fi

fallback_bin_dir="$tmp_dir/fallback-homebrew/bin"
mkdir -p "$fallback_bin_dir"
fallback_brew="$fallback_bin_dir/brew"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "brew|%s|%s\n" "$*" "$PATH" >>"$DOTFILES_TEST_LOG"' \
  'if [ "${1:-}" = "--prefix" ] && [ "${2:-}" = "node@22" ]; then' \
  '  printf "%s\n" "$DOTFILES_TEST_NODE_PREFIX"' \
  'fi' >"$fallback_brew"
chmod +x "$fallback_brew"
fallback_output=$(PATH=/usr/bin:/bin DOTFILES_SOURCE_DIR="$source_dir" DOTFILES_TEST_OS=Darwin DOTFILES_TEST_BREW_FALLBACK="$fallback_brew" /bin/bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run)
escaped_fallback_brew=$(printf '%q' "$fallback_brew")
assert_contains "$fallback_output" "$escaped_fallback_brew bundle --file"

for command_name in chezmoi pnpm; do
  recorder="$fallback_bin_dir/$command_name"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s|%s|%s|%s\n" "${0##*/}" "$*" "$PATH" "${DOTFILES_BOOTSTRAP_EXTERNALS:-}" >>"$DOTFILES_TEST_LOG"' >"$recorder"
  chmod +x "$recorder"
done

test_home="$tmp_dir/home"
mkdir -p "$test_home/.local/bin"
doctor="$test_home/.local/bin/dotfiles-doctor"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "doctor|%s|%s\n" "$*" "$PATH" >>"$DOTFILES_TEST_LOG"' >"$doctor"
chmod +x "$doctor"

node_prefix="$tmp_dir/fallback-homebrew/opt/node@22"
mkdir -p "$node_prefix/bin"
recording="$tmp_dir/bootstrap.log"
HOME="$test_home" PATH=/usr/bin:/bin DOTFILES_SOURCE_DIR="$source_dir" DOTFILES_TEST_OS=Linux \
  DOTFILES_TEST_BREW_FALLBACK="$fallback_brew" DOTFILES_TEST_LOG="$recording" \
  DOTFILES_TEST_NODE_PREFIX="$node_prefix" /bin/bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" >/dev/null
recorded=$(<"$recording")
assert_contains "$recorded" "brew|bundle --file $source_dir/Brewfile|$fallback_bin_dir:/usr/bin:/bin"
assert_contains "$recorded" "chezmoi|--source $source_dir --no-tty init|$node_prefix/bin:$fallback_bin_dir:/usr/bin:/bin|"
assert_contains "$recorded" "chezmoi|--source $source_dir --refresh-externals apply|$node_prefix/bin:$fallback_bin_dir:/usr/bin:/bin|1"
assert_contains "$recorded" "|$node_prefix/bin:$fallback_bin_dir:/usr/bin:/bin"
assert_contains "$recorded" "pnpm|--dir $source_dir install --frozen-lockfile"
assert_contains "$recorded" 'doctor|'

if DOTFILES_SOURCE_DIR="$source_dir" DOTFILES_TEST_OS=Windows_NT bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run >/dev/null 2>&1; then
  fail 'unsupported OS succeeded'
fi

if DOTFILES_SOURCE_DIR="$repo" DOTFILES_TEST_OS=Darwin bash "$repo/dot_local/bin/executable_dotfiles-bootstrap" --dry-run unexpected >/dev/null 2>&1; then
  fail 'unexpected bootstrap argument succeeded'
fi

pass 'bootstrap uses the selected source and fallback Homebrew environment'

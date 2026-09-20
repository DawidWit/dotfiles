#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

config_fish="$repo/private_dot_config/private_fish/config.fish"
cclaude_fish="$repo/private_dot_config/private_fish/functions/cclaude.fish"

fish --no-execute "$config_fish"
fish --no-execute "$cclaude_fish"

config=$(<"$config_fish")

# Non-interactive shells must stay quiet: only exported variables run before
# the `status is-interactive` guard.
assert_contains "$config" 'set -gx EDITOR nvim'
assert_contains "$config" 'set -gx SHELL /usr/bin/fish'
assert_contains "$config" 'if status is-interactive'
assert_contains "$config" 'set -g fish_greeting'

# Ghostty's shell integration is sourced only when Ghostty exported its
# resources directory, so the config stays usable under other terminals.
assert_contains "$config" 'set -q GHOSTTY_RESOURCES_DIR'
assert_contains "$config" 'test -f "$ghostty_fish"; and source "$ghostty_fish"'

# Atuin owns Ctrl+R; fzf keeps Ctrl+T and Alt+C.
assert_contains "$config" "set -gx FZF_CTRL_R_COMMAND ''"
assert_contains "$config" 'atuin init fish --disable-up-arrow | source'

# Starship must not initialise under a dumb terminal.
assert_contains "$config" 'if test "$TERM" != dumb'
assert_contains "$config" 'starship init fish | source'

# Abbreviations, not aliases, so the expanded command stays visible in history.
for abbreviation in ll la lt g gs gd gl c; do
  assert_contains "$config" "abbr -a -g $abbreviation"
done

# The helper wraps `claude` rather than shadowing it, and reaches the real
# binary through `command` so it cannot recurse.
cclaude=$(<"$cclaude_fish")
assert_contains "$cclaude" 'function cclaude --wraps claude'
assert_contains "$cclaude" 'command claude --dangerously-skip-permissions $argv'

pass 'fish configuration is parseable and guards interactive-only setup'

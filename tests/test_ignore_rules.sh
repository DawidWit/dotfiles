#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib/assert.sh"
repo=$(cd "$(dirname "$0")/.." && pwd)
assert_success git -C "$repo" check-ignore -q private_dot_config/wezterm/backgrounds/background0.gif
assert_success git -C "$repo" check-ignore -q docs/superpowers/private-plan.md
assert_contains "$(<"$repo/.chezmoiignore")" '.config/wezterm/backgrounds/background*.*'
pass background-ignore-rules

#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib/assert.sh"
repo=$(cd "$(dirname "$0")/.." && pwd)
assert_success git -C "$repo" check-ignore -q private_dot_config/wezterm/backgrounds/background0.gif
assert_success git -C "$repo" check-ignore -q docs/superpowers/private-plan.md
if git -C "$repo" ls-files --error-unmatch docs/superpowers >/dev/null 2>&1; then
  fail 'docs/superpowers contains tracked files'
fi
[ -f "$repo/docs/superpowers/plans/2026-08-06-cohesive-dotfiles-bootstrap.md" ] || fail 'local plan is missing'
[ -f "$repo/docs/superpowers/specs/2026-08-06-dotfiles-bootstrap-hardening-design.md" ] || fail 'local spec is missing'
assert_contains "$(<"$repo/.chezmoiignore")" '.config/wezterm/backgrounds/background*.*'
pass background-ignore-rules

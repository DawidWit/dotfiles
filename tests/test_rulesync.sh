#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

pnpm --dir "$repo" rules:check
doctor_output=$(pnpm --dir "$repo" exec rulesync doctor)
assert_contains "$doctor_output" '0 error(s), 0 warning(s), 0 info(s)'

[ -f "$repo/AGENTS.md" ] || fail 'missing generated AGENTS.md'
[ -f "$repo/CLAUDE.md" ] || fail 'missing generated CLAUDE.md'
[ ! -e "$repo/GEMINI.md" ] || fail 'RuleSync must not generate GEMINI.md'
assert_success git -C "$repo" check-ignore -q node_modules

pass 'RuleSync outputs are committed and synchronized'

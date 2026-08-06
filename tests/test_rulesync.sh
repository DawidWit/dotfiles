#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

# Invoke rulesync directly: going through `pnpm run` couples the suite to the
# installed pnpm version. When it differs from the packageManager pin, pnpm
# tries to download the pinned version (and to reconcile node_modules), which
# the poisoned proxy rightly blocks. CI still runs `pnpm rules:check` with the
# pinned pnpm as a separate workflow step.
rulesync="$repo/node_modules/.bin/rulesync"
[ -x "$rulesync" ] || fail 'missing node_modules/.bin/rulesync; run pnpm install'

(cd "$repo" && "$rulesync" generate --check)
doctor_output=$(cd "$repo" && "$rulesync" doctor)
assert_contains "$doctor_output" '0 error(s), 0 warning(s), 0 info(s)'

[ -f "$repo/AGENTS.md" ] || fail 'missing generated AGENTS.md'
[ -f "$repo/CLAUDE.md" ] || fail 'missing generated CLAUDE.md'
[ ! -e "$repo/GEMINI.md" ] || fail 'RuleSync must not generate GEMINI.md'
assert_success git -C "$repo" check-ignore -q node_modules

pass 'RuleSync outputs are committed and synchronized'

#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

for command_name in zsh git chezmoi tmux nvim node pnpm eza rg fd fzf zoxide shellcheck shfmt stylua; do
  stub="$tmp_dir/$command_name"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$stub"
  chmod +x "$stub"
done

output=$(DOTFILES_DOCTOR_SKIP_PATHS=1 PATH="$tmp_dir" /bin/bash "$repo/dot_local/bin/executable_dotfiles-doctor")
assert_contains "$output" 'doctor: all required checks passed'

rm "$tmp_dir/tmux"
if DOTFILES_DOCTOR_SKIP_PATHS=1 PATH="$tmp_dir" /bin/bash "$repo/dot_local/bin/executable_dotfiles-doctor" >/dev/null 2>&1; then
  fail 'doctor succeeded without tmux'
fi

pass 'doctor requires every command'

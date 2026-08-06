#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
home_dir="$tmp_dir/home"
cache_dir="$tmp_dir/cache"
config_dir="$tmp_dir/config"
data_dir="$tmp_dir/data"
state_dir="$tmp_dir/state"
bin_dir="$tmp_dir/bin"
source_dir="$tmp_dir/source"
install_log="$tmp_dir/installer.log"
mkdir -p "$home_dir" "$cache_dir" "$config_dir" "$data_dir" "$state_dir" "$bin_dir" "$source_dir"

git -C "$repo" archive HEAD | tar -x -C "$source_dir"
cp "$repo/.chezmoiignore" "$source_dir/.chezmoiignore"
cp "$repo/.chezmoi.toml.tmpl" "$source_dir/.chezmoi.toml.tmpl"
cp "$repo/.chezmoiexternal.toml.tmpl" "$source_dir/.chezmoiexternal.toml.tmpl"
mkdir -p "$source_dir/.git" "$source_dir/docs/superpowers" "$source_dir/node_modules/example-package" "$source_dir/.superpowers" "$source_dir/.worktrees"
printf '%s\n' 'local plan fixture' >"$source_dir/docs/superpowers/private-plan.md"
printf '%s\n' 'module fixture' >"$source_dir/node_modules/example-package/index.js"
printf '%s\n' 'local agent fixture' >"$source_dir/.superpowers/private-note.md"
printf '%s\n' 'local worktree fixture' >"$source_dir/.worktrees/private-marker"

for installer in brew pnpm; do
  printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$0" >> "$DOTFILES_INSTALL_LOG"' >"$bin_dir/$installer"
  chmod +x "$bin_dir/$installer"
done

HOME="$home_dir" \
XDG_CACHE_HOME="$cache_dir" \
XDG_CONFIG_HOME="$config_dir" \
XDG_DATA_HOME="$data_dir" \
XDG_STATE_HOME="$state_dir" \
chezmoi --source "$source_dir" --no-tty init

managed_output=$(HOME="$home_dir" \
  XDG_CACHE_HOME="$cache_dir" \
  XDG_CONFIG_HOME="$config_dir" \
  XDG_DATA_HOME="$data_dir" \
  XDG_STATE_HOME="$state_dir" \
  chezmoi --destination "$home_dir" --no-tty managed --path-style=relative)

while IFS= read -r target; do
  case "$target" in
    AGENTS.md | Brewfile | CLAUDE.md | GEMINI.md | LICENSE | README.md | package.json | pnpm-lock.yaml | rulesync.jsonc | \
      .git | .git/* | .github | .github/* | .gitignore | .rulesync | .rulesync/* | .superpowers | .superpowers/* | \
      .worktrees | .worktrees/* | docs | docs/* | node_modules | node_modules/* | tests | tests/*)
      fail "repository infrastructure became a managed target: $target"
      ;;
  esac
done <<<"$managed_output"

HOME="$home_dir" \
XDG_CACHE_HOME="$cache_dir" \
XDG_CONFIG_HOME="$config_dir" \
XDG_DATA_HOME="$data_dir" \
XDG_STATE_HOME="$state_dir" \
PATH="$bin_dir:$PATH" \
DOTFILES_INSTALL_LOG="$install_log" \
HTTP_PROXY=http://127.0.0.1:9 \
HTTPS_PROXY=http://127.0.0.1:9 \
ALL_PROXY=http://127.0.0.1:9 \
NO_PROXY= \
chezmoi --destination "$home_dir" --no-tty apply

for repo_path in AGENTS.md Brewfile CLAUDE.md GEMINI.md LICENSE README.md package.json pnpm-lock.yaml rulesync.jsonc \
  .git .github .gitignore .rulesync .superpowers .worktrees docs node_modules tests; do
  [ ! -e "$home_dir/$repo_path" ] || fail "repository infrastructure was applied to home: $repo_path"
done

[ ! -e "$home_dir/.oh-my-zsh" ] || fail 'fresh apply must not fetch Chezmoi externals'
[ ! -s "$install_log" ] || fail 'routine chezmoi apply must not invoke package installers'
zsh -n "$home_dir/.zprofile"
zsh -n "$home_dir/.zshrc"
bash -n "$home_dir/.local/bin/dotfiles-bootstrap"
bash -n "$home_dir/.local/bin/dotfiles-doctor"
bash -n "$home_dir/.local/bin/tmux-sessionizer"
bash -n "$home_dir/.local/bin/tmux-weather"
bash -n "$home_dir/.local/bin/wezterm-bg"

git -C "$repo" diff --check

pass 'fresh isolated chezmoi apply renders parseable shell files'

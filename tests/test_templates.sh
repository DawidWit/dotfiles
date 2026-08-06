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
install_log="$tmp_dir/installer.log"
mkdir -p "$home_dir" "$cache_dir" "$config_dir" "$data_dir" "$state_dir" "$bin_dir"

for installer in brew pnpm; do
  printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$0" >> "$DOTFILES_INSTALL_LOG"' >"$bin_dir/$installer"
  chmod +x "$bin_dir/$installer"
done

HOME="$home_dir" \
XDG_CACHE_HOME="$cache_dir" \
XDG_CONFIG_HOME="$config_dir" \
XDG_DATA_HOME="$data_dir" \
XDG_STATE_HOME="$state_dir" \
PATH="$bin_dir:$PATH" \
DOTFILES_INSTALL_LOG="$install_log" \
chezmoi --source "$repo" --destination "$home_dir" --no-tty --refresh-externals=never --exclude externals apply

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

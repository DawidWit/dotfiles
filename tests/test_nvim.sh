#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

home_dir="$tmp_dir/home"
source_dir="$tmp_dir/source"
data_dir="$tmp_dir/data"
state_dir="$tmp_dir/state"
cache_dir="$tmp_dir/cache"
config_dir="$tmp_dir/config"
caller_config_dir="$tmp_dir/caller-config"
bin_dir="$tmp_dir/bin"
network_log="$tmp_dir/network.log"
fixture_lazy_dir="$repo/tests/fixtures/lazy.nvim"

[ -f "$fixture_lazy_dir/lua/lazy/init.lua" ] || fail 'missing committed lazy.nvim smoke fixture'

mkdir -p \
  "$home_dir" \
  "$source_dir/private_dot_config" \
  "$data_dir/nvim/lazy" \
  "$state_dir" \
  "$cache_dir" \
  "$config_dir" \
  "$caller_config_dir/chezmoi" \
  "$bin_dir"
for command_name in git curl; do
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s|%s\n" "${0##*/}" "$*" >>"$DOTFILES_NETWORK_LOG"' \
    'exit 99' >"$bin_dir/$command_name"
  chmod +x "$bin_dir/$command_name"
done
printf 'invalid = [\n' >"$caller_config_dir/chezmoi/chezmoi.toml"
export XDG_CONFIG_HOME="$caller_config_dir"

cp -R "$repo/private_dot_config/nvim" "$source_dir/private_dot_config/nvim"
cp "$repo/.chezmoidata.toml" "$source_dir/.chezmoidata.toml"
env \
  HOME="$home_dir" \
  XDG_CONFIG_HOME="$config_dir" \
  XDG_DATA_HOME="$data_dir" \
  XDG_STATE_HOME="$state_dir" \
  XDG_CACHE_HOME="$cache_dir" \
  chezmoi --source "$source_dir" --destination "$home_dir" apply
cp -R "$fixture_lazy_dir" "$data_dir/nvim/lazy/lazy.nvim"

env \
  HOME="$home_dir" \
  XDG_CONFIG_HOME="$config_dir" \
  XDG_DATA_HOME="$data_dir" \
  XDG_STATE_HOME="$state_dir" \
  XDG_CACHE_HOME="$cache_dir" \
  PATH="$bin_dir:$PATH" \
  DOTFILES_NETWORK_LOG="$network_log" \
  nvim --clean --headless \
  --cmd "set rtp+=$home_dir/.config/nvim" \
  -l "$repo/tests/nvim/member_depth_spec.lua"

env \
  HOME="$home_dir" \
  XDG_CONFIG_HOME="$home_dir/.config" \
  XDG_DATA_HOME="$data_dir" \
  XDG_STATE_HOME="$state_dir" \
  XDG_CACHE_HOME="$cache_dir" \
  PATH="$bin_dir:$PATH" \
  DOTFILES_NETWORK_LOG="$network_log" \
  nvim --headless \
  --cmd 'let g:dotfiles_nvim_smoke = 1' \
  -c "luafile $repo/tests/nvim/member_depth_spec.lua" \
  -c 'qa!'

[ ! -s "$network_log" ] || fail "Neovim smoke attempted network access: $(<"$network_log")"

pass 'Neovim starts headlessly with custom explorer and picker specs'

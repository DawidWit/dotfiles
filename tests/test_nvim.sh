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
installed_lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
caller_config_dir="$tmp_dir/caller-config"

[ -d "$installed_lazy_dir/lazy.nvim" ] || fail "missing installed lazy.nvim at $installed_lazy_dir"

mkdir -p \
  "$home_dir" \
  "$source_dir/private_dot_config" \
  "$data_dir/nvim" \
  "$state_dir" \
  "$cache_dir" \
  "$config_dir" \
  "$caller_config_dir/chezmoi"
printf 'invalid = [\n' >"$caller_config_dir/chezmoi/chezmoi.toml"
export XDG_CONFIG_HOME="$caller_config_dir"

cp -R "$repo/private_dot_config/nvim" "$source_dir/private_dot_config/nvim"
env \
  HOME="$home_dir" \
  XDG_CONFIG_HOME="$config_dir" \
  XDG_DATA_HOME="$data_dir" \
  XDG_STATE_HOME="$state_dir" \
  XDG_CACHE_HOME="$cache_dir" \
  chezmoi --source "$source_dir" --destination "$home_dir" apply
ln -s "$installed_lazy_dir" "$data_dir/nvim/lazy"

env \
  HOME="$home_dir" \
  XDG_CONFIG_HOME="$config_dir" \
  XDG_DATA_HOME="$data_dir" \
  XDG_STATE_HOME="$state_dir" \
  XDG_CACHE_HOME="$cache_dir" \
  nvim --clean --headless \
  --cmd "set rtp+=$home_dir/.config/nvim" \
  -l "$repo/tests/nvim/member_depth_spec.lua"

env \
  HOME="$home_dir" \
  XDG_CONFIG_HOME="$home_dir/.config" \
  XDG_DATA_HOME="$data_dir" \
  XDG_STATE_HOME="$state_dir" \
  XDG_CACHE_HOME="$cache_dir" \
  nvim --headless \
  --cmd "lua local root = vim.env.XDG_DATA_HOME .. '/nvim/lazy/lazy.nvim/lua/'; package.path = root .. '?.lua;' .. root .. '?/init.lua;' .. package.path; local lazy = require('lazy'); local setup = lazy.setup; lazy.setup = function(opts) opts.install = opts.install or {}; opts.install.missing = false; opts.checker = opts.checker or {}; opts.checker.enabled = false; return setup(opts) end" \
  --cmd 'let g:dotfiles_nvim_smoke = 1' \
  -c "luafile $repo/tests/nvim/member_depth_spec.lua" \
  -c 'qa!'

pass 'Neovim starts headlessly with custom explorer and picker specs'

#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/tests/lib/assert.sh"

render_template() {
  chezmoi execute-template <"$1"
}

zprofile=$(render_template "$repo/dot_zprofile.tmpl")
zshrc=$(render_template "$repo/dot_zshrc.tmpl")

printf '%s\n' "$zprofile" | zsh -n
printf '%s\n' "$zshrc" | zsh -n

rendered="$zprofile
$zshrc"
case "$rendered" in
  */Users/dawid/*) fail 'shell configuration must not contain a personal home path' ;;
esac
case "$rendered" in
  *dangerously-skip-permissions*) fail 'shell configuration must not bypass AI permissions' ;;
esac

assert_contains "$zshrc" 'source "$HOME/.config/zsh/aliases.zsh"'
assert_contains "$zshrc" 'source "$HOME/.config/zsh/integrations.zsh"'
assert_contains "$zshrc" 'source "$HOME/.config/zsh/kompas.zsh"'

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/bin" "$tmp_dir/home"
printf '#!/usr/bin/env bash\nexit 0\n' >"$tmp_dir/bin/eza"
chmod +x "$tmp_dir/bin/eza"

aliases=$(HOME="$tmp_dir/home" PATH="$tmp_dir/bin:$PATH" ZSH_ALIASES="$repo/dot_config/zsh/aliases.zsh" zsh -fc '
  source "$ZSH_ALIASES"
  alias ls
  alias ll
  alias lt
')
assert_contains "$aliases" 'ls='
assert_contains "$aliases" 'll='
assert_contains "$aliases" 'lt='

printf 'FZF_SOURCE_LOADED=1\n' >"$tmp_dir/home/.fzf.zsh"
integrations=$(HOME="$tmp_dir/home" ZSH_INTEGRATIONS="$repo/dot_config/zsh/integrations.zsh" zsh -fc '
  zoxide() {
    if [[ "$1" = init && "$2" = zsh ]]; then
      print "ZOXIDE_SOURCE_LOADED=1"
    fi
  }
  source "$ZSH_INTEGRATIONS"
  print "${ZOXIDE_SOURCE_LOADED:-0}:${FZF_SOURCE_LOADED:-0}"
')
assert_eq "$integrations" '1:1'

pass 'rendered shell configuration is portable and loads modular files'

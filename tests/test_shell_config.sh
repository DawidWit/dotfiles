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

aliases=$(HOME="$tmp_dir/home" PATH="$tmp_dir/bin:$PATH" ZSH_ALIASES="$repo/private_dot_config/zsh/aliases.zsh" zsh -fc '
  source "$ZSH_ALIASES"
  alias ls
  alias ll
  alias lt
')
assert_contains "$aliases" 'ls='
assert_contains "$aliases" 'll='
assert_contains "$aliases" 'lt='

printf 'FZF_SOURCE_LOADED=1\n' >"$tmp_dir/home/.fzf.zsh"
integrations=$(HOME="$tmp_dir/home" ZSH_INTEGRATIONS="$repo/private_dot_config/zsh/integrations.zsh" zsh -fc '
  zoxide() {
    if [[ "$1" = init && "$2" = zsh ]]; then
      print "ZOXIDE_SOURCE_LOADED=1"
    fi
  }
  source "$ZSH_INTEGRATIONS"
  print "${ZOXIDE_SOURCE_LOADED:-0}:${FZF_SOURCE_LOADED:-0}"
')
assert_eq "$integrations" '1:1'

load_home="$tmp_dir/load-home"
load_log="$tmp_dir/zsh-load.log"
mkdir -p \
  "$load_home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" \
  "$load_home/.config/zsh"

printf '%s\n' \
  'print -r -- "omz:${(j:,:)plugins}" >> "$ZSH_LOAD_LOG"' \
  >"$load_home/.oh-my-zsh/oh-my-zsh.sh"
printf '%s\n' 'print -r -- p10k >> "$ZSH_LOAD_LOG"' >"$load_home/.p10k.zsh"
printf '%s\n' 'print -r -- aliases >> "$ZSH_LOAD_LOG"' >"$load_home/.config/zsh/aliases.zsh"
printf '%s\n' 'print -r -- integrations >> "$ZSH_LOAD_LOG"' >"$load_home/.config/zsh/integrations.zsh"
printf '%s\n' 'print -r -- kompas >> "$ZSH_LOAD_LOG"' >"$load_home/.config/zsh/kompas.zsh"

if ! missing_plugin_output=$(HOME="$load_home" ZSH_LOAD_LOG="$load_log" zsh -dfc "$zshrc" 2>&1); then
  printf '%s\n' "$missing_plugin_output" >&2
  fail 'zshrc failed when optional syntax highlighting was absent'
fi
missing_plugin_order=$(<"$load_log")
assert_eq 'omz:git,zsh-autosuggestions,zsh-interactive-cd
p10k
aliases
integrations
kompas' "$missing_plugin_order"

printf '%s\n' 'print -r -- syntax-highlighting >> "$ZSH_LOAD_LOG"' \
  >"$load_home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
: >"$load_log"
HOME="$load_home" ZSH_LOAD_LOG="$load_log" zsh -dfc "$zshrc"
load_order=$(<"$load_log")
assert_eq 'omz:git,zsh-autosuggestions,zsh-interactive-cd
p10k
aliases
integrations
kompas
syntax-highlighting' "$load_order"

pass 'rendered shell configuration is portable and loads modular files'

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

if [[ -r "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
fi

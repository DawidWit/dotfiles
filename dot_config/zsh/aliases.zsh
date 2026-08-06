if (( $+commands[eza] )); then
  alias ls='eza --color=auto'
  alias ll='eza --long --git'
  alias lt='eza --tree --level=2'
fi

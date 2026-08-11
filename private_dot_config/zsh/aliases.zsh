if (( $+commands[eza] )); then
  alias ls='eza --color=auto'
  alias ll='eza --long --git'
  alias lt='eza --tree --level=2'
fi

alias ccodex='codex --dangerously-bypass-approvals-and-sandbox'
alias cclaude='claude --dangerously-skip-permissions'

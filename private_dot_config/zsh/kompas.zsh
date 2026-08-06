runkompasbackend() {
  local session='kompas-backend'
  local repo="${KOMPAS_BACKEND_REPO:-$HOME/Documents/GitHub/kompas2-backend}"
  local kompas_command='SPRING_PROFILES_ACTIVE=local ./gradlew --no-daemon :kompas2:bootRun; exec zsh'
  local investments_command='SPRING_PROFILES_ACTIVE=local ./gradlew --no-daemon :kompas2investments:bootRun; exec zsh'

  if [[ ! -d "$repo" ]]; then
    print -u2 "Kompas backend repository not found: $repo"
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session" -c "$repo" "$kompas_command"
    tmux split-window -h -t "$session" -c "$repo" "$investments_command"
    tmux select-layout -t "$session" even-horizontal
  fi

  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

stopkompasbackend() {
  local session='kompas-backend'

  if ! tmux has-session -t "$session" 2>/dev/null; then
    print 'Kompas backend is not running.'
    return 0
  fi

  tmux kill-session -t "$session"
  print 'Kompas backend stopped.'
}

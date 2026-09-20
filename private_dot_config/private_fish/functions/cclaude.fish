function cclaude --wraps claude --description 'claude with permission prompts disabled'
    command claude --dangerously-skip-permissions $argv
end

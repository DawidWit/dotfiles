---
root: true
targets: ["agentsmd", "codexcli", "claudecode"]
description: "Safe maintenance rules for the Chezmoi dotfiles source"
globs: ["**/*"]
---

# Dotfiles repository rules

This is a Chezmoi source repository for a personal macOS and Linux development environment. Windows is unsupported.

## Source layout

- Follow Chezmoi naming conventions: `dot_` maps to a leading dot, `private_` maps to private permissions, `executable_` marks an executable, and `.tmpl` files are rendered templates.
- `dot_local/bin/` holds installed user commands; `private_dot_config/` holds private XDG configuration; `tests/` contains hermetic shell tests.
- Local WezTerm assets named `private_dot_config/wezterm/backgrounds/background*.*` are intentionally ignored and must not be managed or committed.

## Provisioning and safety

- `dotfiles-bootstrap` is the only command that installs packages or refreshes Chezmoi externals. Routine `chezmoi apply` only manages files and must never install packages.
- Preserve the intentional WezTerm behavior that resets the selected background to the configured default whenever a new WezTerm process starts.
- Keep Bash scripts compatible with macOS Bash 3.2.
- Do not reintroduce unconditional AI permission bypasses, broad process-pattern kills, or tmux pane-content archive inspection.
- Never manage or infer existing local WezTerm backgrounds. Tests must use temporary homes and caches and must not contact weather or Kompas services.

## Agent-maintained files

- This file is the canonical RuleSync source. Regenerate committed `AGENTS.md` and `CLAUDE.md` with `pnpm rules:generate`; do not edit generated outputs directly.
- Generate only the `agentsmd`, `codexcli`, and `claudecode` targets. Do not add a `GEMINI.md` target or output.
- `docs/superpowers/` contains local planning/specification artifacts only. It must remain local-only and must never be committed.

## Validation

Before completing a change, run the relevant tests and, when available, `pnpm rules:check`, `bash tests/run`, `shellcheck dot_local/bin/executable_*`, `shfmt -d -i 2 dot_local/bin/executable_*`, `stylua --check private_dot_config/nvim/lua`, and `git diff --check`.

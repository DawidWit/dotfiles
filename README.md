# Dawid's dotfiles

Chezmoi-managed terminal and editor configuration for macOS and Linux. It includes Zsh, tmux, WezTerm, Neovim, Git defaults, and a small set of supporting commands.

## Requirements

Use macOS or Linux; Windows is unsupported. Bootstrap requires Homebrew on macOS or Linuxbrew on Linux, plus a cloned Chezmoi source directory. On a fresh Linux machine, install Linuxbrew first with its official noninteractive installer.

## First run

Clone this repository as your Chezmoi source, then run the explicit provisioning command from that source directory:

```bash
DOTFILES_SOURCE_DIR="$HOME/.local/share/chezmoi" \
  bash "$HOME/.local/share/chezmoi/dot_local/bin/executable_dotfiles-bootstrap"
```

`dotfiles-bootstrap` is intentionally the only command that installs packages, refreshes externals, installs the pinned Node tooling, generates agent rules, and runs the doctor. It is safe to rerun.

## Daily use

Apply configuration changes without provisioning software:

```bash
chezmoi apply
```

Update source changes with your normal Git workflow, then apply them. Routine `chezmoi apply` never installs packages or refreshes external dependencies.

Local WezTerm backgrounds stay local: place assets at `~/.config/wezterm/backgrounds/background*.*`. They are ignored by Git and Chezmoi. A newly started WezTerm process deliberately resets its selection to the configured default background.

## Agent rules

RuleSync maintains committed instructions for Codex and Claude from `.rulesync/rules/`:

```bash
pnpm install --frozen-lockfile
pnpm rules:generate
pnpm rules:check
```

Do not edit `AGENTS.md` or `CLAUDE.md` directly. `docs/superpowers/` is local-only planning material and must never be committed.

## Tests

Run the repository suite with:

```bash
pnpm test
```

The test suite uses temporary homes and caches, so it does not modify your user configuration or contact weather and Kompas services. CI additionally checks shell and Lua formatting and syntax on macOS and Linux.

## Directory map

- `dot_local/bin/` — installed helper commands, including bootstrap and diagnostics.
- `private_dot_config/` — XDG configuration for Neovim, WezTerm, and Zsh modules.
- `dot_*.tmpl` — rendered Chezmoi templates for shell, tmux, and Git config.
- `.chezmoidata.toml` — shared palette values used by templates.
- `.rulesync/rules/` — canonical instructions that generate `AGENTS.md` and `CLAUDE.md`.
- `tests/` — hermetic shell tests and Neovim smoke coverage.

# Dawid's dotfiles

Chezmoi-managed terminal and editor configuration for macOS and Linux. It includes Zsh, tmux, WezTerm, Neovim, Git defaults, and a small set of supporting commands.

## Requirements

Use macOS or Linux; Windows is unsupported. Bootstrap requires Homebrew on macOS or Linuxbrew on Linux, plus a cloned Chezmoi source directory. The macOS bootstrap installs the WezTerm and JetBrains Mono Nerd Font casks as well as the shared CLI toolchain. On Linux, bootstrap installs the CLI tools and managed configuration only; install WezTerm separately from your distribution or the upstream project, and install JetBrains Mono Nerd Font separately from your distribution or Nerd Fonts.

## First run

Clone this repository as your Chezmoi source, then run the explicit provisioning command from that source directory:

```bash
DOTFILES_SOURCE_DIR="$PWD" \
  bash "$PWD/dot_local/bin/executable_dotfiles-bootstrap"
```

`dotfiles-bootstrap` records the current clone as Chezmoi's source and is intentionally the only command that installs packages. Its explicitly gated apply fetches the pinned shell and tmux externals, then it installs the pinned Node tooling, generates agent rules, and runs the doctor. It is safe to rerun.

## Daily use

Apply configuration changes without provisioning software:

```bash
chezmoi apply
```

Plain `chezmoi apply` uses the source recorded during bootstrap. Update that clone with your normal Git workflow, then apply it. The external manifest is disabled unless bootstrap sets `DOTFILES_BOOTSTRAP_EXTERNALS=1`, so routine apply neither downloads externals nor installs packages. Rerun `dotfiles-bootstrap` when you intentionally want to provision or refresh dependencies.

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

The test suite uses temporary homes and caches, so it does not modify your user configuration or contact weather services. CI additionally checks shell and Lua formatting and syntax on macOS and Linux.

## Directory map

- `dot_local/bin/` — installed helper commands, including bootstrap and diagnostics.
- `private_dot_config/` — XDG configuration for Neovim, WezTerm, and Zsh modules.
- `dot_*.tmpl` — rendered Chezmoi templates for shell, tmux, and Git config.
- `.chezmoidata.toml` — shared palette values used by templates.
- `.rulesync/rules/` — canonical instructions that generate `AGENTS.md` and `CLAUDE.md`.
- `tests/` — hermetic shell tests and Neovim smoke coverage.

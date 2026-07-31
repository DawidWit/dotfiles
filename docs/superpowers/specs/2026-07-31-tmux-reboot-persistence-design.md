# Tmux Reboot Persistence Design

## Context

The existing chezmoi-managed tmux configuration already declares TPM,
tmux-resurrect, and tmux-continuum. Automatic restore is enabled and snapshots
are configured for every 10 minutes, but the newest snapshot is from June 30,
2026.

The failure is caused by configuration order. Tmux Continuum installs its
periodic-save command into `status-right` when TPM loads the plugin. The
configuration then replaces `status-right` with the custom weather status,
removing Continuum's save command.

## Goal

After a computer restart, the first normal `tmux` launch restores the most
recent saved workspace:

- sessions, windows, panes, names, layouts, and working directories;
- captured pane contents;
- fresh `nvim`, `claude`, and `codex` processes in their former pane
  directories.

Claude and Codex conversation state is explicitly out of scope. The commands
start fresh and do not attempt to resume prior conversations.

## Design

`~/.local/share/chezmoi/dot_tmux.conf` remains the canonical configuration.
Chezmoi applies it to `~/.tmux.conf`.

Tmux Resurrect remains responsible for serializing and reconstructing tmux
state. Tmux Continuum remains responsible for triggering a save every 10
minutes and restoring the newest snapshot when the first tmux server starts
after reboot.

The configuration will:

1. Preserve the existing Resurrect directory and pane-content capture options.
2. Preserve automatic restore and the 10-minute save interval.
3. Add `claude` and `codex` to `@resurrect-processes`. Neovim is already in
   Resurrect's conservative default process list.
4. Define the complete custom status line before TPM is initialized.
5. Keep `run '~/.tmux/plugins/tpm/tpm'` as the final configuration command, so
   Continuum can add its save command without a later assignment removing it.

The design deliberately avoids `@resurrect-processes ':all:'`. Restoring every
recorded process could rerun unsafe or context-dependent commands.

## Save and Restore Flow

While tmux is running, Continuum evaluates its command through `status-right`.
Once 10 minutes have elapsed since the previous save, it asks Resurrect to
write a timestamped snapshot under `~/.local/share/tmux/resurrect` and update
the `last` symlink.

After a reboot, the first `tmux` invocation starts a new tmux server. Continuum
waits for plugin initialization, then asks Resurrect to load `last`. Resurrect
reconstructs the saved tmux structure and launches the allowed programs in
their saved pane working directories.

Automatic restore runs only at tmux server startup. Starting another client
against an existing server does not duplicate the restored workspace.

## Failure Behavior

If no usable snapshot exists, tmux still starts as a normal new server.

If `nvim`, `claude`, or `codex` is unavailable during restore, the failure is
limited to that pane. The other sessions, windows, panes, and processes can
still be restored.

Resurrect's standard manual save and restore bindings remain available as a
fallback. With the configured `C-Space` prefix, they are `C-Space C-s` and
`C-Space C-r`.

## Verification

Implementation verification will:

1. Confirm the chezmoi source applies cleanly to `~/.tmux.conf`.
2. Load the configuration and inspect the effective tmux options.
3. Confirm `status-right` still contains Continuum's save command after all
   configuration has loaded.
4. Trigger or observe a new Resurrect snapshot and confirm that it contains
   the expected window, pane, directory, and allowed-process records.
5. Provide a reboot acceptance check: after a snapshot is current, reboot,
   launch `tmux`, and confirm the workspace is restored and `nvim`, `claude`,
   and `codex` start fresh in their former panes.

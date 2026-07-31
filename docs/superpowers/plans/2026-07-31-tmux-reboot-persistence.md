# Tmux Reboot Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the first tmux launch after a reboot restore the saved workspace and relaunch fresh Neovim, Claude, and Codex processes.

**Architecture:** Keep tmux-resurrect as the state serializer and tmux-continuum as the 10-minute save and server-start restore trigger. Repair the configuration order so the custom weather status is established before TPM loads Continuum, allowing Continuum's `status-right` save command to survive. Add only Claude and Codex to Resurrect's conservative process allowlist; Neovim is already included by default.

**Tech Stack:** tmux 3.6a, TPM, tmux-resurrect, tmux-continuum, chezmoi 2.70.5, POSIX shell checks, Git

## Global Constraints

- `~/.local/share/chezmoi/dot_tmux.conf` is the canonical configuration; do not edit `~/.tmux.conf` directly.
- Restore on the first normal `tmux` server start after reboot, not at macOS login.
- Preserve sessions, windows, panes, names, layouts, working directories, and captured pane contents.
- Launch fresh `nvim`, `claude`, and `codex` processes without resuming editor or conversation state.
- Keep the automatic save interval at exactly 10 minutes.
- Keep snapshots under `~/.local/share/tmux/resurrect`.
- Do not enable `@resurrect-processes ':all:'`.
- Preserve all unrelated tmux bindings, appearance, and weather status behavior.

## File Structure

- Modify `dot_tmux.conf`: declare the additional safe processes, define the full status line before plugin initialization, and make the TPM loader the final command.
- Apply the managed result to `~/.tmux.conf` with chezmoi; this generated target is not edited or committed directly.
- No new runtime scripts or dependencies are needed.

---

### Task 1: Repair and Verify Automatic Tmux Persistence

**Files:**

- Modify: `dot_tmux.conf:35-51`
- Verify generated target: `~/.tmux.conf`

**Interfaces:**

- Consumes: TPM plugin declarations, Resurrect's `@resurrect-processes` option, Continuum's `status-right` command injection, and chezmoi's source-to-target application.
- Produces: an effective tmux configuration in which `@resurrect-processes` equals `claude codex`, the custom weather status remains visible, and the final `status-right` also contains `continuum_save.sh`.

- [ ] **Step 1: Run the static contract check and verify the current configuration fails**

Run:

```bash
cd /Users/dawid/.local/share/chezmoi
bash -eu -o pipefail -c '
config=dot_tmux.conf
status_right_line=$(awk "/^set -g status-right / { print NR }" "$config")
tpm_run_line=$(awk "/^run .*tmux\\/plugins\\/tpm\\/tpm/ { print NR }" "$config")
test -n "$status_right_line"
test -n "$tpm_run_line"
test "$status_right_line" -lt "$tpm_run_line"
test "$(tail -n 1 "$config")" = "run '\''~/.tmux/plugins/tpm/tpm'\''"
rg -q "^set -g @resurrect-processes '\''claude codex'\''$" "$config"
'
```

Expected: FAIL with a non-zero exit status. In the current file,
`status-right` is below the TPM loader and the explicit Claude/Codex process
allowlist is absent.

- [ ] **Step 2: Make the minimal configuration change**

Edit `dot_tmux.conf` so lines 35 through the end have exactly this structure:

```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-dir '~/.local/share/tmux/resurrect'
set -g @resurrect-processes 'claude codex'
set -g @continuum-save-interval '10'
set -g status-position top

set -g status-style 'bg=default'
set -g status-left '#[fg=#ff9e64,bg=default,bold] #S '
set -g window-status-current-format '#[fg=#000000,bg=#ff9e64,bold] #I:#W '
set -g window-status-format '#[fg=#888888,bg=default] #I:#W '
set -g status-right '#[fg=#ffb86c,bg=default] #(~/.tmux/plugins/tmux/scripts/weather_wrapper.sh false false "Warsaw" false) '

run '~/.tmux/plugins/tpm/tpm'
```

Do not add `nvim` to `@resurrect-processes`; tmux-resurrect appends the custom
list to its built-in list, which already contains `nvim`.

- [ ] **Step 3: Run the static contract check and whitespace validation**

Run:

```bash
cd /Users/dawid/.local/share/chezmoi
bash -eu -o pipefail -c '
config=dot_tmux.conf
status_right_line=$(awk "/^set -g status-right / { print NR }" "$config")
tpm_run_line=$(awk "/^run .*tmux\\/plugins\\/tpm\\/tpm/ { print NR }" "$config")
test -n "$status_right_line"
test -n "$tpm_run_line"
test "$status_right_line" -lt "$tpm_run_line"
test "$(tail -n 1 "$config")" = "run '\''~/.tmux/plugins/tpm/tpm'\''"
rg -q "^set -g @resurrect-processes '\''claude codex'\''$" "$config"
'
git diff --check
```

Expected: both commands exit 0 with no output.

- [ ] **Step 4: Preview and apply only the managed tmux target**

Run:

```bash
cd /Users/dawid/.local/share/chezmoi
chezmoi diff /Users/dawid/.tmux.conf
chezmoi apply /Users/dawid/.tmux.conf
cmp dot_tmux.conf /Users/dawid/.tmux.conf
```

Expected: the preview shows only the intended tmux changes; `chezmoi apply`
completes successfully; `cmp` exits 0 with no output.

- [ ] **Step 5: Load the configuration into a tmux server**

First try to reload an existing server:

```bash
tmux source-file /Users/dawid/.tmux.conf
```

If the command reports that no tmux server is running, start a detached test
session instead:

```bash
tmux new-session -d -s persistence-check
```

Expected: the selected command exits 0. Starting a new server may immediately
restore the existing `last` snapshot; that is the intended startup path.

- [ ] **Step 6: Verify the effective options and the surviving Continuum hook**

Run:

```bash
test "$(tmux show-options -gv @continuum-restore)" = "on"
test "$(tmux show-options -gv @continuum-save-interval)" = "10"
test "$(tmux show-options -gv @resurrect-capture-pane-contents)" = "on"
test "$(tmux show-options -gv @resurrect-dir)" = "~/.local/share/tmux/resurrect"
test "$(tmux show-options -gv @resurrect-processes)" = "claude codex"
tmux show-options -gv status-right | rg -F 'continuum_save.sh'
tmux show-options -gv status-right | rg -F 'weather_wrapper.sh'
```

Expected: every command exits 0. The two final commands print the effective
`status-right`, proving that both the Continuum save command and the Warsaw
weather command survived configuration loading.

- [ ] **Step 7: Create and inspect a fresh snapshot**

Run:

```bash
resurrect_dir=/Users/dawid/.local/share/tmux/resurrect
old_snapshot=$(readlink "$resurrect_dir/last" 2>/dev/null || true)
/Users/dawid/.tmux/plugins/tmux-resurrect/scripts/save.sh quiet
new_snapshot=$(readlink "$resurrect_dir/last")
test -n "$new_snapshot"
test "$new_snapshot" != "$old_snapshot"
test -s "$resurrect_dir/$new_snapshot"
rg -n '^(pane|window|state)' "$resurrect_dir/$new_snapshot"
```

Expected: the save command exits 0, `last` points to a newly named non-empty
snapshot, and the final command prints pane, window, and state records. Process
records for `nvim`, `claude`, or `codex` appear only when those programs are
running during the save; their restore eligibility was verified in Step 6.

- [ ] **Step 8: Review the complete change and commit**

Run:

```bash
cd /Users/dawid/.local/share/chezmoi
git diff --check
git diff -- dot_tmux.conf
git status --short
git add dot_tmux.conf
git commit -m "feat(tmux): persist workspace across reboots"
```

Expected: the diff contains only the approved configuration change; the
commit succeeds.

- [ ] **Step 9: Perform the user-owned reboot acceptance check**

Before rebooting, ensure panes running `nvim`, `claude`, and `codex` are open
and run the manual save binding `C-Space C-s`, or wait at least 10 minutes with
the tmux status line enabled.

After reboot:

```bash
tmux
```

Expected: the saved sessions, windows, panes, names, layouts, working
directories, and captured pane contents return. Panes that previously ran
Neovim, Claude, or Codex launch fresh instances of those commands. Claude and
Codex do not resume their previous conversations.

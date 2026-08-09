# WezTerm background10 design

## Goal

Add `/Users/dawid/Desktop/background10.gif` to the existing WezTerm background rotation without changing the currently selected background.

## Design

- Copy the GIF to `/Users/dawid/.config/wezterm/backgrounds/background10.gif` so the runtime configuration does not depend on a Desktop file.
- Add `background10.gif` as the final image preset before the color-only preset in both the live WezTerm configuration and the chezmoi source template.
- Match the established image defaults: opacity `0.06`, brightness `0.85`, saturation `1.10`, and maximum frame rate `60`.
- Preserve `/Users/dawid/.cache/wezterm-bg/current` so the active background does not change. The generated preset count may update after WezTerm reloads.

## Verification

- Confirm the copied GIF matches the Desktop source byte-for-byte.
- Render the chezmoi template and confirm it contains the new preset.
- Validate the rendered WezTerm configuration with `wezterm ls-fonts --config-file` or another available WezTerm configuration-loading command.
- Confirm the current background state index is unchanged.


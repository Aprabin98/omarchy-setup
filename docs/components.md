# Components and their scripts

## Omarchy Setup command

`bin/omarchy-setup` is the only setup entry point. Use `help`, `install`, `update`, `status`, `remove`, or `uninstall`; details and effects are documented in [install and update](install-update.md) and [remove and uninstall](remove-uninstall.md). It does not run project tests or install system packages.

Commands accept optional component selectors. `hypr`, `omarchy`/`omarchy-shell`/`music`, `launcher`/`vice-city-radial`, `terminals`, and `alacritty`, `foot`, `ghostty`, or `kitty` can be managed independently. `music` includes the bar/shell configuration that refers to plugins. `hypr` and `launcher` include their launcher binding/command dependency. See the selector examples in [install and update](install-update.md).

Select an individual config file or directory with `config:<path>`, relative to `config/`. For example, `config:hypr/input.lua` selects one Hyprland config file and `config:omarchy/plugins/yogeshojha.patro` selects one plugin directory. This selector works with install, update, status, and remove.

## Omarchy Launcher

Source: `projects/vice-city-radial/`. Its `install.sh` and `uninstall.sh` are kept for standalone use and are documented in that project's README. In this unified setup, the main setup command manages its executable and binding from `config/`; do not run the standalone scripts on top of managed files. Run the launcher menu parser check only when explicitly requested; instructions are in the project README.

## YouTube Music

Source: `projects/youtube-music/`; `config/omarchy/plugins/damir.ytmusic/` aliases that source, which the setup command copies into the live plugin directory. Edit the project source and run `./install.sh update`. The plugin's `bin/ytm`, `bin/ytm-mpv`, and `scripts/` commands are documented in its README. Sign-in state is stored outside the repository. The plugin README documents dependency setup, sign-in/out, cache removal, self-test, and development notes.

## Other active plugins

Patro and the personal system monitor are stored under `config/omarchy/plugins/` because they are enabled in the active bar layout. Their plugin READMEs or manifests describe use and dependencies.

## Personal SDDM theme

`projects/omarchy-official-sddm/` is a complete Qt 6 theme matching the inactivity lock screen layout. Follow its README to preview, install, and remove it. SDDM themes and settings are system-wide, so this theme is not installed by `omarchy-setup`; the setup command never writes to `/usr/share/sddm/` or `/etc/sddm.conf.d/`.

## Host-specific HDMI audio switch

`hosts/omarchy/omarchy-hdmi-audio-switch.py` and `omarchy-hdmi-audio-switch.service` describe the current machine's hardware-specific audio routing. The general installer does not install or enable them. To install these files, review the hard-coded PulseAudio/PipeWire card and sink names, then run `OMARCHY_SETUP_HOST=omarchy ./install.sh install`; this links them and reloads user systemd unit definitions when available. To enable the service, run `systemctl --user enable --now omarchy-hdmi-audio-switch.service`. Do not use this profile on another machine without checking its audio device names.

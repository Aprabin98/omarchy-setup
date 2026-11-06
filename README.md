# Omarchy dotfiles

One repository for the Omarchy desktop configuration, plugins, and related projects. The first commit is the original setup snapshot; this second commit organizes it for ongoing changes and adds documented install, update, status, remove, and uninstall commands.

## Install

On an Omarchy machine, clone the repository and run:

```bash
git clone https://github.com/Aprabin98/omarchy-setup.git ~/omarchy-setup
cd ~/omarchy-setup
./install.sh install
```

This saves conflicts under `~/.local/state/omarchy-setup/backups/`, links the ordinary config files, and copies YouTube Music files into Omarchy's real plugin directory. It does not install packages or write into `/usr/share/omarchy/`. Sign in to YouTube Music again on a new machine; browser cookies and account data are not included.

Use the current machine's monitor and HDMI audio profile with:

```bash
OMARCHY_SETUP_HOST=omarchy ./install.sh install
```

Leave that variable unset on other machines to use portable monitor defaults. Review the hardware-specific audio device names before enabling the optional audio service.

## Manage

```bash
./install.sh update
./install.sh status
./install.sh remove
./install.sh uninstall
```

`update` fast-forwards from `origin` when the worktree is clean, then applies the checkout. `remove` and `uninstall` remove setup-managed files and restore saved conflicts; they keep this repository and its backups. See [docs](docs/) and [AGENTS.md](AGENTS.md).

Add component names after a command to manage only those groups. With no names, commands handle all portable components. For example:

```bash
./install.sh install hypr
./install.sh install music
./install.sh install launcher
./install.sh install alacritty kitty
./install.sh status terminals
./install.sh update music
./install.sh remove launcher
```

Groups are `hypr`, `omarchy` (aliases: `omarchy-shell`, `music`), `launcher` (alias: `vice-city-radial`), `terminals`, and individual terminal names `alacritty`, `foot`, `ghostty`, and `kitty`. `host` selects a machine-specific profile and requires `OMARCHY_SETUP_HOST=<profile>`. The `music` selector includes Omarchy shell/bar configuration because its layout can reference installed plugins. The `hypr` and `launcher` groups include the launcher command and binding needed by their configs.

To manage one config file or directory, use `config:<path>` relative to `config/`:

```bash
./install.sh install config:hypr/input.lua
./install.sh update config:omarchy/shell.json
./install.sh remove config:omarchy/plugins/yogeshojha.patro
```

## What's here

- `config/` — portable Hyprland, Omarchy shell, plugin, launcher, and terminal configuration.
- `projects/` — the Vice City launcher, YouTube Music plugin, and personal SDDM theme. The theme has a documented system-wide install; `omarchy-setup` leaves SDDM and `/usr/share/sddm/themes/` untouched.
- `hosts/omarchy/` — optional monitor and HDMI audio settings for this machine.
- `system/omarchy/` — retained lock-screen overlay source. The installer does not replace package-owned files under `/usr/share/omarchy/`.
- `current-theme.txt` — the current theme preference, Solitude. Apply it manually with `omarchy theme set "$(cat current-theme.txt)"` if wanted.

Existing configs, terminal settings, shell layout, plugins, launcher, theme preference, and lock-screen source from the first commit are retained. Project documentation explains each component's scripts and requirements.

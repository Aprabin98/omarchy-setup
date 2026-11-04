# Omarchy Launcher

A native Quickshell radial launcher for Omarchy on Hyprland, styled after the Vice City selection wheel. The inner ring shows Omarchy menu categories; the outer ring shows the selected category's entries. Open a submenu to move deeper into the menu.

## Features

- Reads Omarchy's stock `omarchy-menu.jsonc` and merges the user's `~/.config/omarchy/extensions/omarchy-menu.jsonc` overrides.
- Evaluates menu `when` conditions so unavailable actions, such as Hibernate on a machine without hibernation, stay hidden.
- Runs ordinary menu actions directly and hands dynamic provider entries, such as generated font or language choices, to `omarchy-menu summon`.
- Searches menu actions, installed applications, and open windows together, ranking the best matches first.
- Uses installed desktop entries and system icons for applications, and Quickshell's Hyprland integration for open windows.
- Supports mouse selection, keyboard navigation, numbered slots, and paging through long menus.
- Reads Omarchy theme colors and shell color overrides. User preferences can override colors and layout in the launcher config.

## Requirements

- Omarchy running Hyprland. The installer adds the shortcut with Omarchy's `o.bind(...)` helper.
- Quickshell (`qs`) with its Qt Quick, Wayland, Hyprland, and IO modules. Omarchy normally supplies it.
- Omarchy's menu data, normally found at `$OMARCHY_PATH/default/omarchy/omarchy-menu.jsonc`. If `OMARCHY_PATH` is unset, this launcher uses `/usr/share/omarchy`.
- `gtk-launch` and `uwsm-app` to start desktop applications.
- Omarchy commands available in the session `PATH` for menu actions and provider entries.
- A Git client to install or update the checkout.

The install and uninstall scripts use Bash and standard system utilities. They do not install packages or modify system files.

## Install

Keep the checkout in a stable location because the installed command is a symlink into it. On a new device, clone it under your user data directory:

```sh
mkdir -p "$HOME/.local/share"
git clone git@github.com:Aprabin98/vice-city-radial.git "$HOME/.local/share/omarchy-launcher"
cd "$HOME/.local/share/omarchy-launcher"
./install.sh
hyprctl reload
hyprctl configerrors
```

If you do not use SSH keys with GitHub, use HTTPS for the clone:

```sh
git clone https://github.com/Aprabin98/vice-city-radial.git "$HOME/.local/share/omarchy-launcher"
```

The installer checks that Quickshell is available, backs up the Hyprland bindings file before its first change, adds a marked `ALT + SPACE` binding, creates `~/.local/bin/omarchy-launcher` as a symlink to this checkout, and copies the default preferences if you do not already have a config file. It keeps existing user preferences on reinstall.

If Alt+Space is already assigned outside a launcher-managed block, installation stops and names the conflict. Remove or change that binding before retrying. The script refuses to replace a regular file or a symlink owned by another launcher at `~/.local/bin/omarchy-launcher`.

### Custom locations

The installer and wrapper honor `XDG_CONFIG_HOME` and `XDG_BIN_HOME`. The wrapper and installer honor `QUICKSHELL_BIN` if your Quickshell executable is not named `qs`. Keep these variables set in your Hyprland session as well as when installing.

If Omarchy is installed somewhere other than `/usr/share/omarchy`, set `OMARCHY_PATH` in the environment inherited by Quickshell and Hyprland.

## Use

Press **Alt + Space** to open or close the wheel. The first ring contains the main categories. Select a category and press Enter or click it to show its children on the outer ring. Continue into submenus as needed. Selecting an action runs it; selecting an app launches it; selecting a window focuses it.

Type to search menu entries, installed applications, and open windows. The first matching result is selected. The current category path and selection appear in the status panel below the wheel.

| Key or action | Result |
| --- | --- |
| Letters and punctuation | Search menu entries, apps, and windows |
| Up / Left | Select the previous item on the active ring |
| Down / Right | Select the next item on the active ring |
| Tab | Switch between rings when not searching |
| Enter or Space | Open a submenu or run the selected item |
| 1–9 | Select that numbered slot on the current ring or page |
| 0 | Select slot 10 |
| Page Up / Page Down | Move through outer-ring pages |
| Backspace | Remove a search character, or go up one menu level |
| Escape | Clear search, then go up one level, then close |
| Click the center | Clear search or go up one level |
| Click outside the wheel | Close the launcher |

## Configuration

Preferences are stored in `~/.config/omarchy-launcher/config.json`. The installer copies `config.json` only when no user config exists, so reinstalling or updating preserves your preferences.

```json
{
  "radius": 238,
  "iconSize": 44,
  "animationMs": 110,
  "mouseNavigation": true,
  "keyboardNavigation": true,
  "colors": {
    "pink": "#b784ff",
    "purple": "#7548bd",
    "text": "#f5efff"
  },
  "pageSize": 12,
  "iconFont": "JetBrainsMono Nerd Font"
}
```

- `radius`: outer wheel radius in logical pixels; it shrinks to fit the monitor.
- `iconSize`: maximum size for icons and menu glyphs.
- `animationMs`: fade duration in milliseconds.
- `mouseNavigation`: allow pointer movement to change selection.
- `keyboardNavigation`: enable keyboard control while the wheel is open.
- `pageSize`: number of outer-ring entries shown at a time (minimum 4).
- `iconFont`: font used for menu glyphs. A Nerd Font is recommended.
- `colors`: optional color overrides such as `text`, `pink`, `purple`, `muted`, `background`, `selectedBackground`, `selectedText`, and `border`. `backgroundAlpha` controls the wheel surface opacity from 0 to 1 and defaults to `0.5`. Empty or missing color overrides use Omarchy theme colors.

## Update

From the checkout:

```sh
cd "$HOME/.local/share/omarchy-launcher"
git pull --ff-only
```

The launcher runs directly from the checkout, so the next open uses the updated files. Your preferences stay in `~/.config/omarchy-launcher/config.json`.

## Troubleshooting

- **The shortcut does nothing:** run `hyprctl reload`, confirm the symlink at `~/.local/bin/omarchy-launcher` points to this checkout, and run that command from a terminal.
- **Install reports an Alt+Space conflict:** inspect `~/.config/hypr/bindings.lua`, change the conflicting binding, and rerun `./install.sh`.
- **The launcher has no menu entries:** check that `OMARCHY_PATH/default/omarchy/omarchy-menu.jsonc` exists. This project falls back to `/usr/share/omarchy` when `OMARCHY_PATH` is unset.
- **Quickshell reports QML errors:** run `qs --path "$HOME/.local/share/omarchy-launcher" --verbose` in a Hyprland session and inspect the errors.
- **Applications do not launch:** check that `gtk-launch`, `uwsm-app`, and the app's desktop entry are available.
- **Menu actions fail:** confirm Omarchy's command directories are in the session `PATH` and that the action works when run in a terminal.
- **Nerd Font icons are missing:** install or select a Nerd Font and set its family name in `iconFont`.

To inspect Quickshell logs:

```sh
qs --path "$HOME/.local/share/omarchy-launcher" log
```

## Test menu parsing

The menu parser can be checked with Node.js and the installed Omarchy menu data:

```sh
OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}" node tests/menu.test.js
```

## Run without the shortcut

From the project directory in an active Hyprland session:

```sh
qs --path "$PWD" --no-duplicate --verbose
```

## Uninstall

From the checkout:

```sh
./uninstall.sh
hyprctl reload
```

Uninstall removes the installer's symlink and marked binding. It keeps the checkout, preferences, and binding backup. Remove the checkout separately after uninstalling.

## Project files

| File | Purpose |
| --- | --- |
| `shell.qml` | Radial interface, menu integration, app/window search, input, IPC, and theme colors |
| `menu.js` | JSONC parsing, menu tree construction, `when` evaluation, and search ranking |
| `Slot.qml` | Ring icon and label component |
| `config.json` | Defaults copied on first install |
| `omarchy-launcher` | Starts or toggles this Quickshell config through IPC |
| `install.sh` | Installs the command symlink, preferences, and Alt+Space binding |
| `uninstall.sh` | Removes the managed symlink and binding |
| `legacy/apps-shell.qml` | Previous apps-and-windows wheel implementation |
| `tests/menu.test.js` | Menu parser and search smoke test against Omarchy's menu data |

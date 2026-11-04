# Install and update

## Install

Run from the checkout:

```bash
./bin/omarchy-setup install
```

The installer derives all paths from the checkout and `$HOME`. It creates parent directories, backs up a conflicting file or symlink before replacing it, and records managed links in `~/.local/state/omarchy-setup/installed.tsv`. It is safe to run again. Use `./bin/omarchy-setup status` to inspect the result.

The installer does not use `sudo`, install packages, change system files, enable optional services, or handle account sign-in. Omarchy and Quickshell must already be installed. The YouTube Music plugin can prompt to install missing `uv` and `deno` dependencies.

## Select components

Add one or more component names after `install`, `update`, or `status`; no names means all portable components:

```bash
./bin/omarchy-setup install hypr
./bin/omarchy-setup install music
./bin/omarchy-setup install launcher
./bin/omarchy-setup install alacritty kitty
./bin/omarchy-setup update music
./bin/omarchy-setup status terminals
```

Available groups are `hypr`, `omarchy` (aliases `omarchy-shell` and `music`), `launcher` (alias `vice-city-radial`), and `terminals`. Terminal names can be selected individually: `alacritty`, `foot`, `ghostty`, or `kitty`. The `music` group includes the Omarchy shell/bar configuration, since the bar layout may reference the plugin. `hypr` and `launcher` include the launcher command/binding required by their configs. Select the optional machine profile with `OMARCHY_SETUP_HOST=<profile> ./bin/omarchy-setup install host`.

For one individual config file or directory, use `config:<path>` where the path is relative to `config/`:

```bash
./bin/omarchy-setup install config:hypr/input.lua
./bin/omarchy-setup update config:omarchy/shell.json
./bin/omarchy-setup status config:omarchy/plugins/yogeshojha.patro
```

The selector verifies that the path exists in this checkout. A directory selector includes files beneath that directory. Use group selectors when related settings need to be installed together.

## Update

To apply edits already present in this checkout:

```bash
./bin/omarchy-setup update
```

If this checkout has a Git upstream, `update` first requires a clean worktree and runs `git pull --ff-only`. If the pull fails, no setup files are applied. With no upstream, it reapplies the local checkout. This command never discards local Git changes.

For a manual update, pull explicitly and then apply:

```bash
git pull --ff-only
./bin/omarchy-setup install
```

Hyprland normally reloads config changes. Restart the Omarchy shell if a QML change does not appear:

```bash
omarchy restart shell
```

## Status

```bash
./bin/omarchy-setup status
```

Status reports each managed path as linked, missing, or changed. A nonzero exit status means at least one managed link needs attention.

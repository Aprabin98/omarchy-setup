# Omarchy Setup Repository Instructions

This folder is the single source of truth for personal Omarchy setup and related development.

## Where changes go

- Managed user configuration belongs in `config/`; `dotfiles/.config` is a compatibility alias used by the installer. Do not duplicate configs under both paths.
- Machine-specific configuration belongs in `hosts/<profile>/`; portable setup must work when no profile matches.
- Omarchy-related projects and plugins belong in `projects/`.
- Setup and maintenance entry points belong in `bin/` and must be documented in `README.md` and `docs/`.
- The setup command supports both component groups and individual config paths. For a single file or directory under `config/`, use `config:<path>` (relative to `config/`), such as `config:hypr/input.lua` or `config:omarchy/plugins/yogeshojha.patro` with `install`, `update`, `status`, or `remove`.
- When adding, moving, or removing a selectable component, update the command's `help`, `README.md`, `docs/components.md`, and the install/remove lifecycle docs in the same change. Keep selector matching aligned with the installed paths under `~/.config`.
- Keep upstream project history when consolidating a repository. Do not add nested `.git` directories.
- Keep the first commit as the repository baseline. The consolidated setup work is the next commit on `main`.

## Safety and portability

- Never commit tokens, cookies, browser sessions, account data, machine IDs, or cache files.
- Do not write into `/usr/share/omarchy/`.
- Setup scripts must be idempotent, fail clearly, back up files before replacing them, and restore backups on uninstall.
- Do not overwrite a user-edited path during removal. Preserve it and report the conflict.
- Use `$HOME`, XDG paths, or paths derived from this checkout. Never hard-code `/home/<user>`.
- A fresh machine with no matching host profile must use Omarchy defaults and portable settings.
- Never install files from `system/omarchy/` into `/usr/share/omarchy/`; retain that tree as source only.
- Document every command and script before adding it. Do not run project tests unless asked.

## Workflow

1. Read the relevant project README and inspect existing local changes.
2. Make changes here; avoid editing the live config as the source of truth.
3. Apply changes with `./bin/omarchy-setup update` when the user asks to activate them.
4. Explain what changed, what was backed up, and any step that needs interactive authentication.

## Managing one config at a time

Use `./bin/omarchy-setup install config:<path>` to apply a single config file or directory from `config/`. For example, `config:hypr/input.lua` selects one Hyprland file, while `config:omarchy/plugins/yogeshojha.patro` selects that plugin directory. The path is relative to this repository's `config/` directory. Group selectors such as `hypr`, `music`, and `terminals` remain available when a set of related files should stay together. `remove` accepts the same selectors and preserves unrelated managed components.

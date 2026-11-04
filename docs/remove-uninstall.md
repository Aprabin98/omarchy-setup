# Remove and uninstall

Run either command from the checkout:

```bash
./bin/omarchy-setup remove
# or
./bin/omarchy-setup uninstall
```

Both commands remove only links that still point to this checkout. They restore the file or symlink saved at first install. If a path has been changed since installation, the command keeps it and reports it rather than overwriting it. The checkout and backups remain available.

`remove` accepts the same component names as install, so you can remove one group, for example `./bin/omarchy-setup remove music` or `./bin/omarchy-setup remove kitty`. With no component names, `remove` removes all managed components. `uninstall` always removes all managed components.

Individual config files or directories can be removed with the same `config:<path>` selector, such as `./bin/omarchy-setup remove config:hypr/input.lua`. Paths are relative to `config/` in this checkout.

To remove the checkout after uninstalling, first confirm it contains no uncommitted work and keep a copy of `~/.local/state/omarchy-setup/backups/` if you may need the previous configs. Then remove `~/omarchy-setup` yourself. This separate step avoids accidental loss of project changes.

YouTube Music account data and its cache are deliberately not removed by setup uninstall. To sign out, use the plugin's `bin/ytm logout`; consult `projects/youtube-music/README.md` before removing plugin data.

The optional HDMI audio service is not enabled or disabled by the main installer. Before uninstalling, if you enabled it, stop and disable it with:

```bash
systemctl --user disable --now omarchy-hdmi-audio-switch.service
```

This command is optional and applies only to the profile in `hosts/omarchy/`.

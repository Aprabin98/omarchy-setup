# Layout and portability

```text
AGENTS.md                         contributor and automation rules
config/                           portable user configuration, relative to ~/.config
dotfiles/.config                  compatibility alias to config/ for the installer
hosts/omarchy/                    optional settings for this current machine
projects/                         launcher, music plugin, and SDDM draft
system/omarchy/                   retained lock-screen overlay source, not installed
bin/omarchy-setup                 single install/update/status/remove command
docs/                             operator and component documentation
```

The installer derives paths from the checkout and `$HOME`. A new machine with no host profile receives the portable settings and monitor scale defaults. This machine's display and HDMI audio files are in `hosts/omarchy/`; select them with `OMARCHY_SETUP_HOST=omarchy ./install.sh install`. The profile copies its settings and reloads user systemd definitions when possible, but does not enable or start the HDMI audio service.

YouTube Music's canonical source is `projects/youtube-music/`. The setup copies its files into a real plugin directory under `~/.config/omarchy/plugins/damir.ytmusic/`, because Omarchy rejects symlinks inside plugin folders. Edit the project source and run `./install.sh update` to apply it.

## Adding or changing configuration

Edit or add files in `config/` at the path they should have under `~/.config`. The `dotfiles/.config` symlink lets the installer consume the existing layout. Run `./install.sh install` to back up conflicts and apply changes. Commit changes here. Avoid editing the live file after installation; ordinary managed files point back into this checkout.

Put hardware-dependent changes in `hosts/<profile>/` and document how to activate them. Keep the default install independent of a host profile. Never add secrets or machine identifiers.

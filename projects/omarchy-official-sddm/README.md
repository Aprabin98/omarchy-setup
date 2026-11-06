# Omarchy Personal SDDM theme

This Qt 6 SDDM theme carries the startup screen design from the inactivity lock screen: the Bikram Sambat and Gregorian dates, clock, welcome message, blurred wallpaper, and centered password field. The theme and its background live outside Omarchy's managed files, so Omarchy updates do not replace them. SDDM runs before your user session and cannot read the lock screen's selected wallpaper, so this theme uses its bundled `background.jpg`; replace that file if you want both screens to use the same image.

The date display uses the same `Bikram.js`, `Nepali.js`, and calendar table as `system/omarchy/shell/plugins/lock/`. Keep those files in sync when changing the lock screen's calendar implementation.

## Install on Arch / Omarchy

SDDM themes are system-wide. Install the theme and add a dedicated SDDM drop-in:

```bash
theme_dir=/usr/share/sddm/themes/omarchy-personal
theme_config=/etc/sddm.conf.d/99-omarchy-personal.conf

if sudo test -e "$theme_dir" || sudo test -L "$theme_dir"; then
  echo "Refusing to replace existing $theme_dir" >&2
  exit 1
fi
if sudo test -e "$theme_config" || sudo test -L "$theme_config"; then
  echo "Refusing to replace existing $theme_config" >&2
  exit 1
fi

sudo install -d -m 0755 "$theme_dir" /etc/sddm.conf.d
sudo cp -a Main.qml Bikram.js Nepali.js CalendarData.js metadata.desktop theme.conf background.jpg "$theme_dir/"
printf '[Theme]\nCurrent=omarchy-personal\n' | sudo tee "$theme_config" >/dev/null
```

Run the commands from this project directory. The checks ensure existing theme files or SDDM settings are not overwritten. Restart the computer to see the startup theme. Save your work before restarting.

## Preview

Preview without changing the active SDDM theme:

```bash
QT_QPA_PLATFORM=xcb sddm-greeter-qt6 --test-mode --theme "$PWD"
```

This requires the SDDM Qt 6 greeter and an active graphical session. Check that the date, font fallback, wallpaper, and password field fit the display before enabling the theme.

## Remove

First switch SDDM back to its previous theme by removing the dedicated drop-in. Remove the theme directory only if you have not edited its installed files; compare it with this project first:

```bash
sudo rm -- /etc/sddm.conf.d/99-omarchy-personal.conf
sudo diff -qr --exclude='README.md' "$PWD" /usr/share/sddm/themes/omarchy-personal
# Only if diff reports no differences:
sudo rm -r -- /usr/share/sddm/themes/omarchy-personal
```

If `diff` reports differences, keep the theme directory and review the changes before removing anything. Omarchy setup does not manage or remove SDDM system files.

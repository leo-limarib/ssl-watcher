# ssl-watcher

SSL certificate expiry watcher for [Omarchy](https://omarchy.org) / Waybar. Shows a single lock icon in your bar — default color = all OK, yellow = at least one certificate expiring soon, red = at least one expired or unreachable — with a tooltip listing the status and label of every host.

## Requirements

`openssl`, `jq`, `systemd` (user services), and a bar: the Omarchy shell bar (Omarchy 3+) or Waybar.

## Install

```bash
./install.sh
```

This copies the scripts to `~/.local/bin`, installs a systemd user timer that refreshes hourly, and creates `~/.config/ssl-watcher/sites.conf` from the example. On Omarchy it also installs the bar widget into `~/.config/omarchy/plugins/local.ssl-watcher/`, but does not put it on the bar until you enable it. It never touches a Waybar config.

## Configure your sites

Edit `~/.config/ssl-watcher/sites.conf`, one host per line:

```
example.com
api.example.com:443 # Production API
old-box.example.com:8443 # IIS box
```

- Default port is `443`.
- Text after `#` is a friendly label; blank/comment lines are ignored.

Then run an immediate check:

```bash
ssl-watcher-check --force
```

## Add it to the bar

### Omarchy (shell bar)

Omarchy 3 replaced Waybar with its own Quickshell bar, so ssl-watcher ships as a
native bar widget:

```bash
omarchy plugin enable local.ssl-watcher --section right
```

`shell.json` hot-reloads, so the lock appears immediately. Move it with
`omarchy bar move local.ssl-watcher --before omarchy.tray`, and take it off with
`omarchy plugin disable local.ssl-watcher`.

The widget leaves its color at the bar default when everything is fine, so it
matches the other status icons. Override the two alert colors per-widget:

```bash
omarchy bar set local.ssl-watcher warnColor '#d7a65c'
omarchy bar set local.ssl-watcher criticalColor '#a55555'
```

It polls `ssl-watcher-bar` every 5 minutes (`intervalMs`), and `ssl-watcher-check`
pokes it over IPC the moment a check finishes. Clicking the lock forces a
re-check.

### Waybar

Paste the snippets into your Waybar config, then reload:

```bash
cat waybar.snippet.jsonc   # → ~/.config/waybar/config.jsonc
cat waybar.snippet.css     # → ~/.config/waybar/style.css
omarchy restart waybar
```

## Tuning

Override via environment variables (e.g. in the systemd unit or your shell):

| Variable | Default | Meaning |
|---|---|---|
| `SSL_WATCHER_WARN_DAYS` | `14` | Days-left threshold for the yellow "expiring soon" state |
| `SSL_WATCHER_INTERVAL` | `86400` | Min seconds between real checks |
| `SSL_WATCHER_TIMEOUT` | `10` | Per-site openssl connect timeout |
| `SSL_WATCHER_ICON` | `` | Glyph shown in the bar |
| `SSL_WATCHER_COLOR_OK` / `_WARN` / `_CRIT` / `_UNKNOWN` | Catppuccin | Tooltip marker colors |

The icon's own color does not come from those variables. On Waybar it comes from
CSS classes — `ok` (no rule, so it inherits the bar's default color), `warn`,
`critical`, `empty` — restyled in `~/.config/waybar/style.css`. On Omarchy it
comes from the widget's `warnColor` / `criticalColor` settings, with the ok state
left at the bar foreground.

## Uninstall

```bash
./uninstall.sh
```

Removes the binaries and timer; leaves your config and state in place.

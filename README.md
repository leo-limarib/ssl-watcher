# ssl-watcher

SSL certificate expiry watcher for [Omarchy](https://omarchy.org) / Waybar. Shows a colored dot per site in your bar — green = OK, red = expiring soon or expired, gray = unknown — with a tooltip listing days-to-expiry for each host.

## Requirements

`openssl`, `jq`, `systemd` (user services), and Waybar.

## Install

```bash
./install.sh
```

This copies the scripts to `~/.local/bin`, installs a systemd user timer that refreshes hourly, and creates `~/.config/ssl-watcher/sites.conf` from the example. It does **not** touch your Waybar config — add the module yourself (see below).

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

## Add the Waybar module

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
| `SSL_WATCHER_WARN_DAYS` | `14` | Days-left threshold to turn a site red |
| `SSL_WATCHER_INTERVAL` | `86400` | Min seconds between real checks |
| `SSL_WATCHER_TIMEOUT` | `10` | Per-site openssl connect timeout |
| `SSL_WATCHER_COLOR_OK` / `_WARN` / `_UNKNOWN` | Catppuccin | Dot colors |

## Uninstall

```bash
./uninstall.sh
```

Removes the binaries and timer; leaves your config and state in place.

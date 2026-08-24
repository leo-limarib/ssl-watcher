#!/usr/bin/env bash
# Install ssl-watcher into the user's home: bin scripts, systemd user timer,
# and a starter sites.conf. Does NOT modify ~/.config/waybar/* — paste the
# snippets from waybar.snippet.jsonc / waybar.snippet.css yourself.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
CONFIG_DIR="$HOME/.config/ssl-watcher"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ssl-watcher"

for cmd in openssl jq systemctl; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "missing dependency: $cmd" >&2
    exit 1
  }
done

mkdir -p "$BIN_DIR" "$SYSTEMD_USER_DIR" "$CONFIG_DIR" "$STATE_DIR"

install -m 0755 "$SRC_DIR/bin/ssl-watcher-check" "$BIN_DIR/ssl-watcher-check"
install -m 0755 "$SRC_DIR/bin/ssl-watcher-bar"   "$BIN_DIR/ssl-watcher-bar"

install -m 0644 "$SRC_DIR/systemd/ssl-watcher-check.service" \
  "$SYSTEMD_USER_DIR/ssl-watcher-check.service"
install -m 0644 "$SRC_DIR/systemd/ssl-watcher-check.timer" \
  "$SYSTEMD_USER_DIR/ssl-watcher-check.timer"

if [[ ! -f "$CONFIG_DIR/sites.conf" ]]; then
  install -m 0644 "$SRC_DIR/config/sites.conf.example" "$CONFIG_DIR/sites.conf"
  echo "→ created $CONFIG_DIR/sites.conf (edit it to add your sites)"
else
  echo "→ keeping existing $CONFIG_DIR/sites.conf"
fi

systemctl --user daemon-reload
systemctl --user enable --now ssl-watcher-check.timer

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "WARNING: $BIN_DIR is not on your PATH; waybar exec may fail." >&2 ;;
esac

cat <<EOF

ssl-watcher installed.

Next steps:
  1. Edit $CONFIG_DIR/sites.conf and list your domains.
  2. Run an immediate check:
       ssl-watcher-check --force
  3. Add the waybar module:
       cat $SRC_DIR/waybar.snippet.jsonc
       cat $SRC_DIR/waybar.snippet.css
     Paste the JSONC into ~/.config/waybar/config.jsonc and the CSS into
     ~/.config/waybar/style.css, then:
       omarchy restart waybar

Timer status:
  systemctl --user status ssl-watcher-check.timer
EOF

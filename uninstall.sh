#!/usr/bin/env bash
# Remove the ssl-watcher binaries, timer, and (optionally) state/config.

set -euo pipefail

BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
CONFIG_DIR="$HOME/.config/ssl-watcher"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ssl-watcher"
PLUGIN_ID="local.ssl-watcher"
OMARCHY_PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

systemctl --user disable --now ssl-watcher-check.timer 2>/dev/null || true

rm -f "$SYSTEMD_USER_DIR/ssl-watcher-check.service" \
      "$SYSTEMD_USER_DIR/ssl-watcher-check.timer" \
      "$BIN_DIR/ssl-watcher-check" \
      "$BIN_DIR/ssl-watcher-bar"

if [[ -d $OMARCHY_PLUGIN_DIR ]]; then
  # Take it off the bar before deleting the files it points at.
  omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
  rm -rf "$OMARCHY_PLUGIN_DIR"
  echo "Omarchy bar widget $PLUGIN_ID removed."
fi

systemctl --user daemon-reload

echo "ssl-watcher binaries and timer removed."
echo "Config at $CONFIG_DIR and state at $STATE_DIR were left in place."
echo "Remove them manually if desired:"
echo "  rm -rf '$CONFIG_DIR' '$STATE_DIR'"

if [[ -d "$HOME/.config/waybar" ]]; then
  echo
  echo "On waybar, also remove 'custom/ssl-watcher' from ~/.config/waybar/config.jsonc"
  echo "and the related styling from ~/.config/waybar/style.css, then:"
  echo "  omarchy restart waybar"
fi

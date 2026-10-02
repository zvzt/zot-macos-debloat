#!/bin/bash
set -euo pipefail
INSTALL="$HOME/.zot"
ALIASES=(
  zot zot-status zot-performance zot-scan zot-clean zot-analyze zot-apps
  zot-startup zot-login zot-optimize zot-install zot-services zot-theme zot-gui
  zot-doctor zot-history zot-restore zot-update
)

printf '\nZot - Uninstall\n===============\n\n'
if [ -x "$INSTALL/zot" ]; then
  echo "Disabling Zot login items..."
  "$INSTALL/zot" login-disable-all || true
  echo "Restoring Zot-managed startup/service changes..."
  "$INSTALL/zot" restore || true
fi

for name in "${ALIASES[@]}"; do
  if [ -e "/usr/local/bin/$name" ] || [ -L "/usr/local/bin/$name" ]; then
    sudo rm -f "/usr/local/bin/$name"
  fi
done

rm -rf "$INSTALL"
echo "Zot has been uninstalled."

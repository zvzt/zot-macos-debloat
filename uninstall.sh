#!/bin/bash
set -euo pipefail
INSTALL="$HOME/.zot"

printf '\nZot - Uninstall\n===============\n\n'
if [ -x "$INSTALL/zot" ]; then
  echo "Restoring Zot-managed startup/service changes first..."
  "$INSTALL/zot" restore || true
fi
if [ -e /usr/local/bin/zot ] || [ -L /usr/local/bin/zot ]; then sudo rm -f /usr/local/bin/zot; fi
rm -rf "$INSTALL"
echo "Zot has been uninstalled."

#!/bin/bash
# Did the /Library/Displays EDID renames take effect? Run after a reboot.
echo "=== macOS sees ==="
osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.js.map(s=>s.localizedName.js).join("\n")'
echo
echo "=== AeroSpace sees ==="
aerospace list-monitors
echo
echo "=== workspace placement ==="
aerospace list-workspaces --all --format "%{workspace} -> %{monitor-name}" | grep -E "^(T|E) "
echo
if osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.js.map(s=>s.localizedName.js).join(" ")' \
   | grep -qiE "vertical|horizontal"; then
  echo "RESULT: rename IS live. The model-name fallbacks in ~/.aerospace.toml can be dropped."
else
  echo "RESULT: rename NOT live -> macOS 26.7 ignores DisplayProductName. Roll back:"
  echo "  sudo rm -rf /Library/Displays/Contents/Resources/Overrides"
fi

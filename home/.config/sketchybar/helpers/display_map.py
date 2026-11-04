#!/usr/bin/env python3
"""Map aerospace monitor-id -> sketchybar display (arrangement) id.

Aerospace numbers monitors left-to-right, top-to-bottom. SketchyBar's
arrangement-id follows the CoreGraphics arrangement instead, which is a
different order -- on a laptop + two externals they disagree, so the bars
end up on the wrong screens.

`sketchybar --query displays` reports each display's arrangement-id together
with its frame, so we can re-sort those frames the way aerospace does and
read off the correspondence. Nothing about the current setup is assumed.

Prints one "<aerospace-monitor-id> <sketchybar-display-id>" line per display.
"""
import json
import subprocess
import sys

try:
    out = subprocess.run(
        ["sketchybar", "--query", "displays"],
        capture_output=True, text=True, timeout=5, check=True,
    ).stdout
    displays = json.loads(out)
except Exception as exc:  # noqa: BLE001 - degrade quietly; caller falls back
    print("error: %s" % exc, file=sys.stderr)
    sys.exit(1)

# Same ordering rule aerospace uses to assign monitor-ids.
ordered = sorted(displays, key=lambda d: (d["frame"]["x"], d["frame"]["y"]))

for monitor_id, display in enumerate(ordered, start=1):
    print("%d %d" % (monitor_id, display["arrangement-id"]))

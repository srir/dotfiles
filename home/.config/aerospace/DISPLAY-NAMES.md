# Monitor identification for AeroSpace workspace placement

Workspace intent: E = zed -> VERTICAL external. T = terminal -> HORIZONTAL external.
A/B/C/D/S/P -> built-in.

## The two setups

|      | vertical                  | horizontal            | built-in |
|------|---------------------------|-----------------------|----------|
| home | LG Ultra HD (rot 270)     | DELL U2720Q (main)    | yes      |
| work | DELL U2722DE (2) rot 270  | DELL U2722DE (1) main | yes      |

## Two separate traps (both have bitten)

1. WORK: the externals are the same model, so macOS itself disambiguates them in
   NSScreen.localizedName as "(1)"/"(2)", where (1) is whichever is currently the
   MAIN display. The suffix flips silently when the primary display changes.
2. HOME: a bare 'dell' fallback matches the HORIZONTAL U2720Q. Any chain that
   ends in 'dell' will drag the vertical workspace onto the horizontal screen the
   moment the work Dells are absent. Do not use a bare 'dell' fallback.

Current chains in ~/.aerospace.toml list home names, then work names, then 'main'.

## The scheme: names encode ORIENTATION, not model
Every panel is renamed so its name contains "Vertical" or "Horizontal". The
AeroSpace chains then match on that one word and work in any location:
    E = ['Vertical',   ...]   T = ['Horizontal', ...]

| setup | panel        | vendor/product | renamed to           |
|-------|--------------|----------------|----------------------|
| work  | U2722DE vert | 10ac / 4231    | "Dell Vertical"      |
| work  | U2722DE horz | 10ac / 4237    | "Dell Horizontal"    |
| home  | LG Ultra HD  | 1e6d / 5b09    | "LG Vertical"        |
| home  | U2720Q       | 10ac / 41b5    | "Dell 4K Horizontal" |

If a panel is ever physically re-rotated, edit its plist - the name would
otherwise lie. That is the one maintenance cost of this scheme.

## Pending: EDID rename (installed, NOT yet loaded)
All four installed under /Library/Displays/Contents/Resources/Overrides/.
Needs a REBOOT to load; none since Sep 16, so this is still UNVERIFIED on
macOS 26.7. Cosmetic relabel only - no effect on resolution/color/refresh.
The home pair is the useful test case: both are connected at home, so the next
reboot there answers whether DisplayProductName still works at all.

### Verify after any reboot
    ~/.config/aerospace/check-display-names.sh
Confirm it separately in BOTH locations: the work pair shares a vendor+product
namespace with the home U2720Q, and only work can prove the two U2722DE units
really have distinct product IDs rather than per-input ones.

### Roll back
sudo rm -rf /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-10ac

## If a third setup ever shows up
Stop enumerating names: drop E/T from workspace-to-monitor-force-assignment and
place them by GEOMETRY instead - pick the external whose height > width for E and
width > height for T, resolve its left-to-right index, and call
`aerospace move-workspace-to-monitor --workspace <ws> <idx>`. AeroSpace's numeric
monitor pattern means "Nth from the left" (verified). That is location-independent
and needs no per-monitor config, at the cost of a script plus a trigger
(after-startup-command + a hotkey; AeroSpace 0.21 has no monitor-connected hook).

# Changelog

## 3.1.0

- Simplified the Install section to Browsers, Utilities, and Developer.
- Browsers now contain only Zen, Firefox, LibreWolf, and Tor Browser.
- Utilities now contain iTerm2, Mousecape, Raycast, Ice, LuLu, BetterDisplay, and OnyX.
- Developer now includes Xcode as an official Apple website action.
- Added short descriptions throughout the hub and installer catalog.
- Added Cyan, Purple, Blue, Green, Amber, Red, and Mono terminal themes.
- Refined the terminal UI with a bordered header and cleaner selections.
- Added a lightweight native macOS popup launcher via `zot gui` / `zot-gui`.
- Changed destructive confirmations to explicit `[Y/N]` with no Enter default.
- Added `zot-status` and other `zot-*` shortcut commands.
- `zot-status` reports Spotlight, service profile, Siri/AI preferences, Zot-managed disabled jobs, background-helper state, and the last optimization action.
- Browser cache cleanup no longer targets Chrome, Safari, Brave, Edge, or Arc.

## 3.0.0

- Rebuilt the project around the `zot` terminal hub.
- Removed the Python runtime requirement; Zot now uses dependency-free Bash plus built-in macOS utilities.
- Added a clean nested terminal UI with arrow navigation and multi-select screens.
- Added live performance status and a system doctor.
- Added read-only cleanup/storage scanning.
- Added Quick Clean, Deep Clean, age-based cache cleanup, browser cleanup, and developer cleanup.
- Added inactive project-artifact discovery and purge review.
- Added large-file, installer, and iPhone/iPad backup analyzers.
- Added application uninstall with exact bundle-ID leftover review.
- Added startup/background item management with restore tracking.
- Added bounded optimization/maintenance tasks and explicitly avoids fake RAM/defrag tweaks.
- Added a curated software installer that uses Homebrew only when already installed and otherwise opens official download pages.
- Integrated the existing macOS service profiles into the hub.
- Added operation history and in-tool updating.
- Removed the persistent login reapply helper.
- Consolidated owned files under `~/.zot`.

## 2.1.0

- Added interactive mass cleaner and cleanup safety checks.

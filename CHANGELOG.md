# Changelog

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

## 2.0.1

- Hardened launchd disabled-state parsing and removed the old root helper.

## 2.0.0

- Added Balanced/Aggressive profiles, optional Siri/Apple Intelligence controls, Spotlight controls, dry-run support, diagnostics, state tracking, and restore.

# Changelog

## 2.1.0

- Added an interactive mass cleaner with per-category questions and a final confirmation.
- Added dry-run support for cleanup selection.
- Added cleanup for user caches, logs, Trash, Xcode DerivedData, Homebrew, pip, npm, pnpm, Yarn, and Quick Look caches when available.
- Added strict cleanup path allowlisting so arbitrary paths are refused.
- Added direct category flags and guarded non-interactive `--yes` mode.
- Added cleaner safety and dry-run tests.

## 2.0.1

- Fixed parsing of `launchctl print-disabled` so disabled services are reported correctly.
- Removed the root LaunchDaemon used by older versions for system reapply.
- Installer now removes the legacy system helper during updates.
- Added behavior and security regression tests.
- Expanded CI to run a real dry-run on macOS.

## 2.0.0

- Added Balanced and Aggressive profiles.
- Made Siri optional.
- Made Apple Intelligence optional.
- Added explicit Spotlight indexing controls.
- Added interactive configuration wizard.
- Added dry-run mode.
- Added system diagnostics with `zxt doctor`.
- Improved state tracking so ZXT only restores services it actually changed.
- Changed bare `zxt` behavior to show status instead of applying changes.
- Added a dedicated uninstaller.
- Improved update behavior and documentation.
- Added CI syntax checks.

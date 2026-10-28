# Changelog

## 3.4.1

- Clarify that service change records are not a count of currently disabled launchd overrides; use `zot audit` to verify live state.
- Show selected automatic login-cleaning categories in Zot Status.
- Include SIP, FileVault, firewall, Gatekeeper, sealed snapshot and Time Machine destination diagnostics in System Check.
- These diagnostics are read-only and do not alter the user's macOS settings.

## 3.4.0

- Consolidated the interface into six named areas with shorter, clearer navigation.
- Added **Power & Gaming** profiles, power status, live health checks, and exact restore of previous Low Power Mode settings.
- Added `zot mode [status|health|game|battery|restore]` and `zot audit` commands and `zot-mode`/`zot-audit` shortcuts.
- Made service-audit output show configured targets, disabled overrides and post-reboot verification guidance.
- Removed legacy `full`/standalone `cleanup` hooks from Zot and its installer. Standalone Mac Cleanup remains independent.
- Skip obsolete periodic scripts if the command does not exist, and avoid Spotlight reindexing when indexing is off.
- Maintained existing saved service presets, boot/login reapply jobs, and direct commands.
- Power profiles do not turn off SIP, security services, input, audio, network, or controller services.


## 3.2.0

- Added a dedicated **Login Items** hub.
- Added separate **Tweaks** and **Cleaning** login profiles.
- Added `zot login` and the `zot-login` shortcut.
- Tweaks Login Items can save Balanced/Aggressive/None plus Siri, Apple Intelligence, and Spotlight choices.
- Cleaning Login Items can independently select caches, logs, Trash, Xcode DerivedData, supported browser caches, Homebrew, pip, npm, pnpm, Yarn, and Quick Look cleanup.
- Both features require explicit `[Y/N]` confirmation before enabling auto-run.
- Login jobs are one-shot: they run at boot/login and exit instead of remaining resident.
- Enabling a login job does not run it immediately; **Run Tweaks Now** and **Run Cleaning Now** are separate actions.
- Added status/toggle/disable-all controls inside the Login Items hub.
- `zot-status` now reports Tweaks Auto Apply and Cleaning Auto Run states.
- System-level tweak reapplication uses a minimal generated **root-owned** helper rather than executing user-writable Zot code as root.
- `zot restore` disables Tweaks Auto Apply first so restored service changes are not re-disabled on the next boot.
- Uninstall removes Zot login/boot helpers before restoring and deleting Zot.

## 3.1.0

- Simplified the Install section to Browsers, Utilities, and Developer.
- Browsers now contain only Zen, Firefox, LibreWolf, and Tor Browser.
- Utilities now contain iTerm2, Mousecape, Raycast, Ice, LuLu, BetterDisplay, and OnyX.
- Developer now includes Xcode as an official Apple website action.
- Added short descriptions throughout the hub and installer catalog.
- Added Cyan, Purple, Blue, Green, Amber, Red, and Mono terminal themes.
- Added a lightweight native macOS popup launcher via `zot gui` / `zot-gui`.
- Changed destructive confirmations to explicit `[Y/N]` with no Enter default.
- Added `zot-status` and other `zot-*` shortcut commands.

## 3.0.0

- Rebuilt the project around the `zot` terminal hub.
- Removed the Python runtime requirement.
- Added cleanup, storage analysis, app uninstall, startup management, optimization, software installs, service profiles, history, restore, and updates.

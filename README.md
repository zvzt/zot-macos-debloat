# Zot

A lightweight terminal hub for cleaning, analyzing, maintaining, and configuring macOS.

Run `zot` to open the interactive interface. Zot is dependency-free on the tool side: it uses Bash and macOS system utilities already present on the machine. It does not install a Python environment, UI framework, telemetry service, account service, or persistent background helper.

## Install / Update

```bash
bash <(curl -fsSL -H "Accept: application/vnd.github.raw+json" "https://api.github.com/repositories/1356850441/contents/install.sh?ref=main")
```

Then run:

```bash
zot
```

Everything Zot owns lives under:

```text
~/.zot/
├── zot
├── config
├── lib/
├── presets/
└── state/
```

The only system-level file Zot creates is the command symlink at `/usr/local/bin/zot`.

## Hub

The terminal hub uses arrow-key navigation, nested menus, multi-select lists, review screens, and explicit confirmations.

Main sections:

- **Dashboard / Performance** — live RAM, swap, free disk, uptime, and top processes.
- **Scan** — read-only size scan of common cleanup locations.
- **Clean** — quick clean, deep-clean wizard, age-based caches, browser caches, developer caches, and project artifacts.
- **Analyze Storage** — storage overview, large files, installers, local iPhone/iPad backups, and rebuildable project artifacts.
- **Apps & Leftovers** — uninstall applications to Trash and review exact bundle-ID leftovers.
- **Startup & Background** — inspect third-party LaunchAgents/LaunchDaemons, disable selected items, and restore Zot-managed changes.
- **Optimize** — bounded maintenance such as DNS flush, Quick Look reset, LaunchServices refresh, disk verification, Spotlight reindex, periodic maintenance, Homebrew cleanup, and unavailable simulator cleanup.
- **Install Apps** — curated app browser similar to a setup utility.
- **Services & Features** — Balanced/Aggressive service profiles plus optional Siri, Apple Intelligence, and Spotlight controls.
- **Tools** — System Doctor, operation history, updater, Activity Monitor, and Storage Settings.

## Cleaning

Zot distinguishes between rebuildable data and personal files.

### Quick Clean

Reviews common disposable locations:

- User application caches
- User logs
- Trash

### Deep Clean

Walks through general cleanup, supported browser caches, and developer/package-manager cleanup.

### Age-based Cache Clean

Delete cache files older than:

- 7 days
- 30 days
- 90 days

### Browser Caches

Supported cache detection includes:

- Safari
- Firefox
- Google Chrome
- Brave
- Microsoft Edge
- Arc

Running browsers are skipped instead of force-killed.

### Developer Cleanup

When relevant tools are installed, Zot can clean:

- Xcode DerivedData
- Homebrew old versions/downloads
- pip cache
- npm cache
- pnpm store
- Yarn cache
- unavailable Xcode simulators

Project cleanup scans common development folders for rebuildable artifacts such as `node_modules`, Rust `target`, Swift `.build`, and `dist`. Older artifacts are review-only and nothing is selected automatically.

## Storage Analyzer

Zot can review:

- Files larger than 500 MB in common user folders
- DMG, PKG, MPKG, ISO, and XIP installers
- Local Finder iPhone/iPad backups
- Major user storage folders
- Rebuildable project artifacts

Personal files and backups are moved to Trash only after explicit selection and confirmation.

## App Uninstaller

Zot scans `/Applications` and `~/Applications`, shows application sizes, and moves selected apps to Trash.

For leftovers, Zot only proposes exact paths tied to the app name or bundle identifier in known user-library locations. Leftovers are reviewed separately before moving them to Trash.

## Startup Manager

Zot can inspect:

- `~/Library/LaunchAgents`
- `/Library/LaunchAgents`
- `/Library/LaunchDaemons`

Disabled items are recorded in `~/.zot/state/` so they can be restored later.

Zot intentionally does not enumerate `/System/Library` as user-selectable startup items.

## Optimize

The optimization section avoids fake performance tricks. Zot does **not** use RAM purging, forced process killing, APFS defragmentation, indiscriminate system-cache deletion, or random `defaults` tweaks.

Available maintenance tasks are explicit and individually selectable.

## Install Apps

The Install section is a curated list of common software grouped by category.

If Homebrew is already installed, Zot uses it for selected applications. If Homebrew is not installed, Zot opens the applications' official download pages instead. Zot does not silently install a package manager.

Current categories include browsers, utilities, developer tools, communication, media, and gaming.

## Service Profiles

The existing service optimizer remains available inside the Zot hub.

- **Balanced** — lower-impact optional background-service reductions.
- **Aggressive** — additional optional services with larger feature tradeoffs.
- **Siri** — keep/disable.
- **Apple Intelligence** — keep/disable.
- **Spotlight indexing** — keep/off.

Use the restore option to revert launchd changes recorded by Zot.

## Commands

```text
zot
zot status
zot scan
zot clean
zot analyze
zot apps
zot startup
zot optimize
zot install
zot services
zot doctor
zot history
zot restore
zot update
zot version
```

## Safety

- Run Zot as your normal user.
- Administrator access is requested only for an action that actually needs it.
- Destructive actions require review and confirmation.
- Supported personal-file cleanup uses Trash where practical.
- Rebuildable caches/artifacts may be permanently removed after confirmation.
- Startup and service changes made by Zot are tracked for restore.
- No always-running Zot process is installed.
- No telemetry or remote account is used.
- Paths are bounded to known cleanup locations or explicitly selected items.

## Inspiration

The interface and workflows are inspired by the clean terminal experience of [Mole](https://github.com/tw93/Mole), the review-first terminal patterns used in [FileSentry](https://github.com/zvzt/filesentry), and the all-in-one Install/Tweaks/Config concept of [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil).

Zot is its own implementation and does not vendor those projects or their dependencies.

The original service-debloat work was inspired by [OleksandrKrupko/mac-os-debloat](https://github.com/OleksandrKrupko/mac-os-debloat).

## Uninstall

```bash
bash <(curl -fsSL -H "Accept: application/vnd.github.raw+json" "https://api.github.com/repositories/1356850441/contents/uninstall.sh?ref=main")
```

The uninstaller restores Zot-managed startup/service changes first and then removes Zot's own files.

## Maintainer

Maintained by **Zot**.

## License

MIT — see [LICENSE](LICENSE).

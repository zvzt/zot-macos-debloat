# Zot — macOS Debloat

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

### First-install legacy cleanup

On the first Zot install, the installer checks for older Zot/ZXT/debloat versions. If any are found, it lists them and asks whether you want to remove all previous-version data.

Choosing **Yes** will first try to restore changes tracked by the old version, restore Spotlight if the old version had disabled it, unload/remove old login and background launchd jobs, remove legacy command links such as `zxt` and `debloat`, and delete the old `~/.zxt-macos-debloat` / `~/.macos-debloat` data.

Choosing **No** leaves the old installation and its jobs untouched.

The new Zot version itself does not install an auto-login item, LaunchAgent, LaunchDaemon, or persistent background helper.

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

Automatic cache cleanup is limited to the selected browser family:

- Zen
- Firefox
- LibreWolf

Tor Browser remains available in the Install section, but Zot does not automatically delete its profile data because Tor keeps sensitive browser state alongside its profile. Running browsers are skipped instead of force-killed.

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

The Install section is intentionally small and curated. Every item includes a short description in the UI.

### Browsers

- **Zen** — privacy-focused Firefox-based browser
- **Firefox** — open-source web browser
- **LibreWolf** — hardened privacy-focused Firefox fork
- **Tor Browser** — anonymous browsing over the Tor network

### Utilities

- **iTerm2** — advanced terminal emulator
- **Mousecape** — custom cursor manager
- **Raycast** — launcher and productivity tool
- **Ice** — menu bar manager
- **LuLu** — outbound firewall
- **BetterDisplay** — display manager
- **OnyX** — macOS maintenance utility

### Developer

- **Visual Studio Code** — code editor
- **GitHub CLI** — GitHub from Terminal
- **Python** — programming language and runtime
- **Node.js** — JavaScript runtime
- **Xcode** — Apple app development IDE

If Homebrew is already installed, Zot uses it for supported selections. If Homebrew is not installed, Zot opens official download pages instead. Mousecape and Xcode always open their official download/developer pages. Zot never silently installs a package manager.

## Service Profiles

The existing service optimizer remains available inside the Zot hub.

- **Balanced** — lower-impact optional background-service reductions.
- **Aggressive** — additional optional services with larger feature tradeoffs.
- **Siri** — keep/disable.
- **Apple Intelligence** — keep/disable.
- **Spotlight indexing** — keep/off.

Use the restore option to revert launchd changes recorded by Zot.

## Interface & Appearance

The terminal UI uses a bordered header, cleaner selection markers, descriptions beside menu actions, and a configurable accent theme.

Run `zot theme` or `zot-theme` to choose Cyan, Purple, Blue, Green, Amber, Red, or Mono.

Run `zot gui` or `zot-gui` for a lightweight native macOS popup launcher built with system dialogs. It adds no framework or background process; deeper interactive operations still open/use the terminal UI.

## Commands

Every command has a short description in `zot --help`. Common shortcuts include:

```text
zot
zot status
zot performance
zot gui
zot theme
zot-status
zot-performance
zot-clean
zot-optimize
zot-install
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

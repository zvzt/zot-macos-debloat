# macOS Debloat

A configurable macOS background-service optimizer focused on reducing optional background work without blindly disabling core macOS infrastructure.

macOS Debloat defaults to a **Balanced** profile and lets you choose whether to keep or disable **Siri**, **Apple Intelligence**, and **Spotlight indexing**.

> Designed primarily for personal Apple Silicon Macs. Service labels vary between macOS releases, so macOS Debloat automatically skips labels that are not present on your system.

## Quick install / update

Run this in Terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zvzt/macos-debloat/main/install.sh)
```

The first install opens a setup wizard. Existing installs keep their saved configuration when updated.

Python 3 is required. If you use Homebrew and do not already have Python 3:

```bash
brew install python
```

## First-time setup

The installer asks four things:

1. **Profile**
   - `balanced` — recommended for most people; trims telemetry, analytics, experiments, Tips, and promotional background work.
   - `aggressive` — adds many more optional services. It can affect HomeKit, Screen Time, family controls, Sidecar, printing, controllers, Photos analysis, Maps helpers, and other Apple features.
2. **Siri**
   - `keep` — Siri stays available.
   - `disable` — disables the Siri launchd targets in the optional Siri module.
3. **Apple Intelligence**
   - `keep` — Apple Intelligence services stay available.
   - `disable` — disables the optional Apple Intelligence service module.
4. **Spotlight indexing**
   - `keep` — recommended. macOS Debloat leaves Spotlight indexing alone.
   - `off` — disables indexing on the startup volume using `mdutil`. Spotlight file-content search may be reduced until indexing is re-enabled.

macOS Debloat does **not** disable Spotlight's core launchd infrastructure. Spotlight indexing is controlled separately and can be restored at any time.

### Recommended Spotlight alternative: Raycast

If you prefer a launcher-style workflow, macOS Debloat recommends [Raycast](https://www.raycast.com/) as an alternative to using Spotlight for everyday launching and quick actions.

Raycast provides app launching, file search, Quicklinks, extensions, script commands, window management, snippets, and other productivity tools.

If you choose `debloat spotlight off`, Raycast can still be useful as your main launcher, but it is not a complete replacement for every Spotlight indexing/search feature. Some macOS file-search behavior can still depend on system indexing.

Apple documents Spotlight privacy/indexing behavior here: [Apple Support — Spotlight search privacy](https://support.apple.com/guide/mac-help/mchl1bb43b84/mac).

## Common commands

Show your current configuration and status:

```bash
debloat status
```

Open the configuration wizard again:

```bash
debloat configure
```

Open the interactive mass cleaner:

```bash
debloat clean
```

Preview what macOS Debloat would change without changing anything:

```bash
debloat apply --dry-run
```

Apply your saved configuration:

```bash
debloat apply
```

Check the installation and required macOS tools:

```bash
debloat doctor
```

List selected services and whether they exist on this macOS build:

```bash
debloat list
```

Restore changes made by macOS Debloat:

```bash
debloat restore
```

Show every command:

```bash
debloat help
```


## Mass cleaner

Run:

```bash
debloat clean
```

Nothing is selected by default. macOS Debloat shows each available category, explains what it removes, and asks before selecting it. After the questions, it shows one combined summary and asks again before deleting anything.

Available cleanup categories:

- User app caches in `~/Library/Caches`
- User logs in `~/Library/Logs`
- Current user Trash
- Xcode `DerivedData`
- Homebrew cleanup when Homebrew is installed
- Python pip cache
- npm cache when npm is installed
- pnpm store pruning when pnpm is installed
- Yarn cache when Yarn is installed
- Quick Look thumbnail/preview cache

Preview a cleanup without changing anything:

```bash
debloat clean --dry-run
```

You can also select categories directly:

```bash
debloat clean --caches --logs --homebrew
debloat clean --trash --xcode
debloat clean --all
```

Direct category flags still require the final confirmation. For deliberate non-interactive use, add `--yes`:

```bash
debloat clean --caches --logs --yes
```

`--yes` is rejected unless cleanup categories were explicitly supplied.

The cleaner does not target Documents, Downloads, iPhone backups, application preferences, user projects, or protected macOS system files. File cleanup runs without sudo. Some in-use or privacy-protected cache/log files may be skipped.

## Change features quickly

Switch profiles:

```bash
debloat profile balanced
debloat profile aggressive
```

Keep or disable Siri:

```bash
debloat siri keep
debloat siri disable
```

Keep or disable Apple Intelligence:

```bash
debloat intelligence keep
debloat intelligence disable
```

Spotlight controls:

```bash
debloat spotlight status
debloat spotlight keep
debloat spotlight off
debloat spotlight on
debloat spotlight reindex
```

`debloat spotlight keep` means "leave Spotlight alone" and restores indexing only if macOS Debloat previously disabled it. `debloat spotlight on` explicitly enables indexing. `debloat spotlight reindex` rebuilds the Spotlight index and can temporarily increase CPU and disk activity.

## What changed in v2

### 2.0.1 hardening

- Fixed disabled-service status detection to match current `launchctl print-disabled` output.
- Removed the legacy root LaunchDaemon. macOS launchd disable overrides persist without a root background helper.
- Updates automatically remove the old system helper if a previous version installed it.
- Expanded automated syntax, dry-run, and behavior checks.


- Balanced profile is now the default.
- Aggressive extras are separated from the safer base profile.
- Siri is optional instead of always being disabled.
- Apple Intelligence is optional instead of always being disabled.
- Spotlight is a separate explicit choice.
- `debloat apply --dry-run` previews changes.
- `debloat doctor` checks the installation.
- `debloat configure` provides a repeatable setup wizard.
- `debloat` with no arguments now shows status instead of immediately making changes.
- Restore state only records launchd targets that macOS Debloat actually changed.
- Updating preserves your config and state.
- The user-level login reapply job remains limited to selected user launchd targets.
- A dedicated uninstaller restores managed changes before removing macOS Debloat.

## Safety model

macOS Debloat intentionally does **not** target core services such as `launchd`, `WindowServer`, `tccd`, `securityd`, `powerd`, `runningboardd`, `dasd`, `mds`, `mdworker`, or CoreSpotlight infrastructure.

The installer does not keep a root background helper installed. System launchd disable overrides are applied directly and persist through launchd's override state.

The Balanced profile is the recommended choice if you want fewer background processes without intentionally removing major macOS features.

The Aggressive profile is for personal Macs where you understand the feature tradeoffs. Do not use the Aggressive profile on a managed/work Mac unless you know which services your organization requires.

Before applying a profile:

```bash
debloat apply --dry-run
```

## Restore

To restore launchd changes recorded by macOS Debloat and restore Spotlight if macOS Debloat was the tool that disabled it:

```bash
debloat restore
```

Restart macOS afterward so restored services can return normally.

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zvzt/macos-debloat/main/uninstall.sh)
```

The uninstaller first calls `debloat restore`, removes macOS Debloat's user LaunchAgent, any legacy macOS Debloat system LaunchDaemon, and the command symlink, then removes `~/.macos-debloat`.

## Files

```text
~/.macos-debloat/
├── debloat
├── config.json
├── presets/
│   ├── balanced.txt
│   ├── aggressive.txt
│   ├── siri.txt
│   └── apple-intelligence.txt
└── state/
```

macOS Debloat installs the command at:

```text
/usr/local/bin/debloat
```

## Troubleshooting

### `debloat: command not found`

```bash
ls -l /usr/local/bin/debloat
```

If the link is missing, run the installer again.

### Something you use stopped working

First switch back to the Balanced profile and keep optional features enabled:

```bash
debloat profile balanced
debloat siri keep
debloat intelligence keep
debloat spotlight keep
```

If needed, restore all managed changes:

```bash
debloat restore
```

### Spotlight search is incomplete

Enable indexing:

```bash
debloat spotlight on
```

If Spotlight itself is behaving incorrectly:

```bash
debloat spotlight reindex
```

Reindexing can temporarily increase CPU and disk activity.

## Security

See [SECURITY.md](SECURITY.md) for security notes and reporting guidance.

## Credits

This project was inspired by and originally based on work from [OleksandrKrupko/mac-os-debloat](https://github.com/OleksandrKrupko/mac-os-debloat).

Maintained by [Zot](https://github.com/zvzt).

## License

MIT — see [LICENSE](LICENSE). The original project copyright notice is preserved in the license.

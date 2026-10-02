# Security

Zot performs local macOS maintenance and can remove files or disable optional background services. Its default interface is review-first and destructive actions require confirmation.

## Safety boundaries

- Zot does not require a third-party runtime or package.
- Zot is run as the normal user and requests administrator access only for selected system actions.
- Personal-file cleanup moves reviewed items to Trash where practical.
- Rebuildable caches and project artifacts can be permanently removed only after confirmation.
- App leftovers are limited to exact app-name or bundle-ID paths in known user Library locations.
- Startup management does not expose /System/Library launchd items for selection.
- Zot records service/startup changes that it makes so they can be restored.
- Zot does not install a persistent background helper.

Use `zot restore` to restore recorded startup/service changes.

## Reporting

For a potentially unsafe cleanup target or bug, open an issue and include:

- macOS version
- Mac architecture
- Zot version
- feature used
- affected path/service
- relevant terminal output

Do not post passwords, tokens, private keys, or other secrets.

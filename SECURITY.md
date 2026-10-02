# Security

macOS Debloat changes launchd override state and can optionally change Spotlight indexing. It does not keep a root background helper installed; older system helpers are removed during update/uninstall. Review the source and use `debloat apply --dry-run` before applying changes if you want to inspect the selected targets first.

## Reporting a problem

For bugs or potentially unsafe service selections, open a GitHub issue with:

- macOS version
- Mac model / architecture
- selected profile
- output of `debloat doctor`
- the service or command involved

Do not post passwords, tokens, private keys, or other secrets in issues.

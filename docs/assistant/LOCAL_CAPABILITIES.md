# Local Capabilities

Last updated: 2026-03-08

This is the shared capability inventory for the current project harness.
Record only capabilities that were actually discovered and that materially affect workflow decisions.

## Discovered CLI Surface

| Capability | Status | Evidence | Workflow impact |
|---|---|---|---|
| `dart` | Available with cross-host caveat | `/home/fa507/.local/bin/dart` -> Dart SDK `3.11.0` (`windows_x64`) | Direct Dart validators can run from WSL, but Dart child-process calls may inherit Windows path semantics. |
| `git` | Available | `/usr/bin/git` -> `2.43.0` | Normal repo workflows are available in WSL. |
| `rg` | Available | `/home/linuxbrew/.linuxbrew/bin/rg` -> `15.1.0` | Fast repo search is available in WSL. |
| `code` | Available | WSL remote CLI under `~/.vscode-server/.../remote-cli/code` | Saved workspace files can be opened directly from WSL. |

## Flutter Status

- Status: currently blocked in WSL.
- Evidence:
  - `command -v flutter` resolved to `/mnt/c/dev/tools/flutter/bin/flutter`
  - `flutter --version` failed on 2026-03-08 because `/mnt/c/dev/tools/flutter/bin/cache/dart-sdk/bin/dart` was missing
- Workflow impact:
  - direct Dart validators remain usable
  - Dart helpers that shell out to Git or other host-sensitive tools should prefer file-based metadata or explicit host-aware routing
  - Flutter test and app-launch commands are environment-dependent until the WSL Flutter install is repaired
  - GUI validation should use the local environment overlay and same-host rules

## MCP Surface

- Status: no project-local MCP resources or resource templates were discoverable in the current session
- Workflow impact:
  - do not assume MCP-backed docs or automation exists unless rediscovered later

## Routing Summary

- Prefer dynamic capability checks over hardcoded assumptions.
- If a tool is unavailable, record the limitation here instead of seeding a fake issue-memory incident.
- Use `docs/assistant/LOCAL_ENV_PROFILE.example.md` and the local overlay to decide WSL-vs-Windows routing.

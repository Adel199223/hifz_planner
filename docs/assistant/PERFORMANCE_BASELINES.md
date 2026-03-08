# Workspace Performance Baselines

This file is the canonical source for workspace/editor performance defaults.

If any other doc conflicts with this file for performance exclusions or environment placement policy, this file wins.

## Core Principles

1. Keep generated artifacts and environments out of normal code indexing paths.
2. Prefer environment directories outside repo root when practical.
3. Keep VS Code watcher/search excludes explicit and stack-aware.
4. Optimize for correctness first, then responsiveness; do not hide source files needed for implementation.
5. CUDA is not a fix for file-watching/indexing lag in editors.

## Baseline VS Code Excludes (Language-Neutral)

Use these as minimum defaults in `.vscode/settings.json`:

```json
{
  "files.watcherExclude": {
    "**/.git/**": true,
    "**/.idea/**": true,
    "**/build/**": true,
    "**/dist/**": true
  },
  "search.exclude": {
    "**/build/**": true,
    "**/dist/**": true
  }
}
```

## Stack-Specific Exclude Additions

Add based on detected stack:

- Flutter/Dart:
  - `**/.dart_tool/**`
  - platform build intermediates as needed
- Python:
  - `**/.venv/**`
  - `**/__pycache__/**`
  - `**/.pytest_cache/**`
  - `**/.mypy_cache/**`
- Node:
  - `**/node_modules/**`
- JVM/Gradle:
  - `**/.gradle/**`
- Rust:
  - `**/target/**`

## Environment Placement Policy

Default:
- keep heavyweight environments outside repo root.

Examples:
- Python virtualenv under `C:\dev\venvs\<project>`
- other language package stores/tool caches outside repo when toolchain supports it.

Safety rule:
- never delete old environment before replacement is verified.

## Diagnostic Checklist (`code --status`)

1. Check workspace file counts and dominant file types.
2. Confirm extension host memory/CPU behavior.
3. Verify no unexpected large generated/environment directory is indexed.
4. Re-check after applying excludes/environment policy.

## Task-Scoping Guidance for Agents

- Keep diffs focused; avoid touching unrelated directories.
- Prefer targeted tests over broad suites during iteration.
- Avoid unnecessary large file generation in workspace root.

## PowerShell Command Snippets

Create/update `.vscode/settings.json`:

```powershell
New-Item -ItemType Directory -Force .vscode | Out-Null
@'
{
  "files.watcherExclude": {
    "**/.git/**": true,
    "**/.idea/**": true,
    "**/.dart_tool/**": true,
    "**/build/**": true,
    "**/.venv/**": true
  },
  "search.exclude": {
    "**/.dart_tool/**": true,
    "**/build/**": true,
    "**/.venv/**": true
  }
}
'@ | Set-Content -Encoding UTF8 .vscode\settings.json
```

Create an external Python venv safely:

```powershell
python -m venv C:\dev\venvs\my_project
& C:\dev\venvs\my_project\Scripts\Activate.ps1
python -m pip install -U pip
python -c "print('env ok')"
```

Only after verification:

```powershell
Remove-Item -Recurse -Force .venv
```

## OS Guidance

- Windows:
  - consider Defender exclusions for `.dart_tool`, `build`, SDK/toolchain folders.
- macOS:
  - consider Spotlight privacy exclusions for generated/cache-heavy folders.
- Linux:
  - consider tracker/indexer exclusions for generated/cache-heavy folders.

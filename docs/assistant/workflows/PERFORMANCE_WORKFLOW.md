# Workspace Performance Workflow

## What This Workflow Is For

Use this workflow to keep editor responsiveness high while preserving build/test quality.
It covers VS Code lag, file-watcher/indexing pressure, extension overhead, and workspace artifact placement.

## When To Use

Use when:
- VS Code becomes slow during edits, tests, or large Codex diffs.
- `code --status` shows unexpectedly high workspace file counts.
- local responsiveness regresses after adding tools, generated files, or environments.
- CI and local runs diverge because local artifact folders pollute workspace behavior.

## What Not To Do

- Do not assume CUDA improves VS Code indexing or file watcher performance.
- Do not delete an existing environment until a replacement environment is verified.
- Do not keep large runtime environments/caches in repo root when avoidable.
- Do not duplicate performance exclusion tables across docs; keep canonical rules in `docs/assistant/PERFORMANCE_BASELINES.md`.

## Primary Files

- `docs/assistant/PERFORMANCE_BASELINES.md`
- `.vscode/settings.json`
- `.gitignore`
- `tooling/validate_workspace_hygiene.dart`
- `test/tooling/validate_workspace_hygiene_test.dart`
- `.github/workflows/dart.yml`
- `docs/assistant/manifest.json`

## Source Priority

1. `docs/assistant/PERFORMANCE_BASELINES.md` (canonical defaults).
2. Measured workspace reality (`code --status`, file counts, active processes).
3. Stack-specific conventions for detected languages/toolchains.

## Execution Sequence

1. Measure workspace load:
   - `code --status` (when available) and note file counts/process pressure.
2. Apply safe watcher/search excludes in `.vscode/settings.json`.
3. Apply environment/artifact placement policy:
   - prefer environments outside workspace.
4. Validate hygiene:
   - run `dart run tooling/validate_workspace_hygiene.dart`.
5. Re-check responsiveness and keep settings/contracts in sync.

## Stack Matrix (Conditional Rules)

- Flutter/Dart projects:
  - exclude `.dart_tool`, `build`, platform build artifacts.
- Python projects:
  - exclude `.venv`, `__pycache__`, `.pytest_cache`, `.mypy_cache`.
  - prefer venv outside repo root.
- Node projects:
  - exclude `node_modules`, dist/build caches.
- JVM/Gradle projects:
  - exclude `.gradle` and build outputs.
- Rust/Go/C++ projects:
  - exclude `target`, build, and intermediate output directories.

## OS Matrix

- Windows:
  - consider Defender exclusions for heavy generated/toolchain folders.
- macOS:
  - consider Spotlight/privacy exclusions for large generated folders.
- Linux:
  - consider tracker/indexer exclusions if indexing daemons scan generated folders.

## Safety Migration Pattern

1. Create replacement environment outside workspace.
2. Install dependencies in replacement environment.
3. Verify imports/commands succeed.
4. Only then remove old in-repo environment.

## Minimal Commands

```powershell
git status --short
code --status
dart run tooling/validate_workspace_hygiene.dart
```

## Targeted Tests

```powershell
flutter test -j 1 -r expanded test/tooling/validate_workspace_hygiene_test.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: workspace still lags after excludes.
   - Re-check `code --status` for unexpected high file counts and extension host load.
2. Symptoms: validation fails for stack-specific excludes.
   - Add missing excludes in `.vscode/settings.json` and corresponding ignore patterns.
3. Symptoms: accidental environment deletion risk.
   - Recreate and verify replacement environment first; keep old env until verification passes.

## Handoff Checklist

- canonical performance defaults are documented in `docs/assistant/PERFORMANCE_BASELINES.md`
- `.vscode/settings.json` and `.gitignore` align with detected stack needs
- `dart run tooling/validate_workspace_hygiene.dart` passes
- workspace hygiene tests pass
- no runtime feature behavior changed by performance-only edits

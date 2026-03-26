# Local Environment

This is a repo-local environment overlay. It is allowed to contain machine-specific workflow facts that should not live in universal bootstrap templates.

## Current Working Assumptions

- Main repo path:
  - `C:\dev\hifz_planner`
- Preferred isolated worktree root:
  - `C:\dev\worktrees`
- Primary shell:
  - PowerShell
- Bootstrap harness Python entrypoint:
  - `py -3.11`
- Main browser target for local HTML explainers and browser accessibility checks:
  - Microsoft Edge on Windows

## Hard Boundary

- Keep secrets out of this file.
- If a machine fact stops being true, update this overlay instead of rewriting the universal bootstrap templates.

## Browser validation overlay (2026-03-26)

- Chromium is now an active local validation target for the Flutter web surface.
- Playwright smoke tests live under `tooling/playwright/`.
- `node` and `npx` are available locally for browser automation setup.

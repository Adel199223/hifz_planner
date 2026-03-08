# Local Environment Profile (Example)

This tracked file defines the format for the machine-local overlay.

Create or update a same-directory machine-local overlay on the machine that actually runs the repo.
Do not put secrets in either file.

## Required Fields

- capture date
- host OS
- Linux/WSL status if present
- canonical repo path
- canonical workspace file
- routing defaults
- same-host validation rule
- known local limitations that affect workflow

## Project Routing Defaults

- Prefer WSL/Linux for code edits, docs work, git, and direct Dart validators.
- Prefer Windows when visible GUI launch, Windows-only tooling, or same-host validation is required.
- If an integration depends on browser, desktop, or local auth state, validate it on the same host where the app runs.

## Example Structure

```md
# Local Environment Profile (Local)

## Host Profile
- Capture date: YYYY-MM-DD
- Host OS: Windows 11
- Linux layer: WSL Ubuntu
- Repo path: /home/USER/dev/PROJECT
- Canonical workspace: /home/USER/dev/PROJECT-only.code-workspace

## Routing Defaults
- Prefer WSL/Linux for code/docs/git.
- Prefer Windows for GUI app launches and same-host validation.

## Local Limitations
- Record local toolchain gaps here.
```

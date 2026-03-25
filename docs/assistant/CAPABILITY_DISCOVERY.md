# Capability Discovery

Use discovered local capabilities to guide workflow choices. Do not hardcode guesses when the machine can be checked directly.

## Currently Useful Discovered Capabilities

- Primary shell in this repo flow: PowerShell
- Python launcher available:
  - `py -3.11`
  - `python` currently resolves to a different interpreter, so bootstrap harness commands should use `py -3.11`
- Flutter/Dart tooling is part of the normal repo workflow
- Git worktrees are available and should be preferred for parallel major streams
- Microsoft Edge is the main browser target for local HTML explainer review and browser-based accessibility checks

## Rules

- Record only capabilities that change workflow decisions.
- Do not record secrets, tokens, or auth material.
- Re-check fragile assumptions when a tool starts failing or the host changes.

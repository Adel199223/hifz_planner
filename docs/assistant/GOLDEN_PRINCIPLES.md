# Golden Principles

Repository-wide mechanical rules for humans and AI agents.

## Use When

Use this file whenever planning or implementing non-trivial changes.

## Principles

1. Source code wins over docs on conflict.
2. Preserve canonical precedence: `APP_KNOWLEDGE.md` is canonical app-level doc; bridge docs defer.
3. No speculative parsing: validate external data shapes before usage.
4. Prefer shared utilities over copy-pasted logic.
5. Keep changes scoped; do not mix unrelated concerns in one pass.
6. Use path-safe, PowerShell-compatible commands in docs and manifest contracts.
7. Maintain fallback/no-crash behavior for reader/data flows.
8. Never hand-edit generated Drift output (`lib/data/database/app_database.g.dart`).
9. Run targeted tests first, then broader suites.
10. Preserve branch safety: major changes on `feat/*`, keep `main` stable via PR checks.
11. Respect template isolation: `docs/assistant/templates/*` is read-on-demand only.
12. After significant implementation changes, ask exactly: "Would you like me to run Assistant Docs Sync for this change now?"
13. Major implementation stages default to: targeted validation, feature commit, exact Assistant Docs Sync prompt, targeted docs sync if approved, docs-only commit, clean local worktree. Push stays explicit.

## Change Discipline

- Record policy changes in `docs/assistant/manifest.json` contracts.
- Keep workflow docs concise and compaction-ready.
- Use explicit negative-routing in workflows: include "Don't use this workflow when... Instead use ..." guidance.

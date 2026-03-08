# Worktree Build Identity Workflow

## What This Workflow Is For

Use this workflow for parallel worktrees, runnable-build identity, and deterministic handoff when someone says "open the app" or "run this build".

## Expected Outputs

- The latest approved baseline is locked before parallel work starts.
- Every runnable build handoff includes an identity packet.
- Canonical and non-canonical worktrees are distinguished clearly.

## When To Use

Use when:
- work spans multiple branches or worktrees
- someone asks to open or run the app
- a GUI handoff or comparison build is in scope
- branch provenance is unclear and launch ambiguity would be risky

## What Not To Do

- Don't use this workflow when the task is a small single-worktree code edit with no runnable-build ambiguity. Instead use the relevant feature or docs workflow directly.
- Don't treat any convenient worktree as runnable by default.
- Do not launch or hand off a GUI build without a branch, SHA, and worktree path.
- Do not keep accepted feature behavior stranded only on a side branch.
- Do not skip same-host validation when the app launch target is Windows-bound.

## Primary Files

- `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md`
- `tooling/print_build_identity.dart`
- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/manifest.json`

## Minimal Commands

```powershell
git worktree list
git status --short --branch
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
dart tooling/print_build_identity.dart
```

## Targeted Tests

```powershell
dart tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: parallel work starts from an unknown base.
   - Lock the latest approved baseline by branch and base SHA before continuing.
2. Symptoms: the wrong GUI build is opened.
   - Run `dart tooling/print_build_identity.dart` and include the full identity packet in the handoff.
3. Symptoms: feature work happens in multiple runnable worktrees.
   - Treat side worktrees as source-only until one worktree is explicitly promoted.
4. Symptoms: accepted behavior lives only on a side branch.
   - Merge immediately into the approved base, then prune obsolete branch state.
5. Symptoms: launch instructions are ambiguous.
   - Use the canonical workspace `/home/fa507/dev/hifz_planner-only.code-workspace` and restate the canonical launch command explicitly.

## Handoff Checklist

- latest approved baseline is recorded by branch and base SHA
- major ExecPlan records worktree path, branch, base branch, base SHA, intended scope, and target integration branch
- canonical runnable build is `/home/fa507/dev/hifz_planner` opened through `/home/fa507/dev/hifz_planner-only.code-workspace`
- side worktrees are treated as source-only unless explicitly promoted
- runnable-build handoff includes worktree path, branch, HEAD SHA, workspace file, and launch command
- accepted features are merged immediately after acceptance instead of remaining only on side branches

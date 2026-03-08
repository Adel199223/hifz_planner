# Commit and Publish Workflow

## What This Workflow Is For

Use this workflow whenever the user asks to commit. It enforces safe staging, ignore hygiene, validation, push, and optional remote cleanup.

## Expected Outputs

- Staged scope matches intended change set with no accidental files.
- Targeted validation for touched scope is complete before commit/push.
- Branch/publish operations are safe and auditable.

## When To Use

Use when requests include:
- `commit`
- `stage`
- `push`
- `merge to main`
- branch cleanup/pruning on local or remote

## What Not To Do

- Don't use this workflow when the request is runtime feature implementation without commit intent. Instead use the relevant feature workflow first.
- Don't use this workflow when CI policy/contracts are being redesigned. Instead use `docs/assistant/workflows/CI_REPO_WORKFLOW.md`.
- Don't use this workflow to perform broad assistant-doc rewrites after implementation. Instead apply targeted docs sync via `docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md`.
- Do not commit blindly with `git add .` unless the user explicitly wants every change.
- Do not include unrelated files in the same commit.
- Do not force-push to `main`.
- Do not delete remote branches without a keep-list and user intent.
- Do not perform broad assistant-doc rewrites after implementation; use targeted docs sync by scope only.

## Primary Files

- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/manifest.json`
- `docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md`
- `docs/assistant/workflows/CI_REPO_WORKFLOW.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `.gitignore`
- `tooling/print_build_identity.dart`

## Minimal Commands

```powershell
git worktree list
git fetch --prune origin
git status --short --branch
git diff --name-only
git diff --cached --name-only
git ls-files --others --exclude-standard
git branch -vv
git branch -r
```

Staging and commit:

```powershell
git add <path_or_file>
git restore --staged <path_or_file>
git commit -m "<message>"
git push
```

Main sync and cleanup (only when explicitly requested):

```powershell
git switch main
git pull --ff-only origin main
git merge --ff-only <feature-branch>
git push origin main
git push origin --delete <stale-branch>
git fetch --prune origin
```

## Shorthand Defaults

### Bare `commit`

Treat `commit` as full pending-tree triage:
- inspect modified tracked files, staged files, untracked files, and temp artifacts
- split the result into logical grouped commits
- validate each commit scope before committing
- suggest push immediately after the commits are complete

### Bare `push`

Treat `push` as Push+PR+Merge+Cleanup:
- push the correct branch
- create or update the PR
- ensure the latest SHA is under review
- merge when green and clean
- remove stale branch state when safe

### Override Rule

If the user narrows scope, follow the narrower scope instead of the default lifecycle.

## Targeted Tests

Use tests that match touched files before committing. For docs/repo operations, minimum:

```powershell
dart run tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
```

## Failure Modes and Fallback Steps

1. Symptoms: unrelated dirty files appear.
   - Stop and ask whether to split commits or include all changes.
2. Symptoms: files should be ignored but are untracked.
   - verify with `git check-ignore -v <path>` and update `.gitignore` if appropriate.
3. Symptoms: push to `main` rejected.
   - push feature branch and open a PR instead of forcing.
4. Symptoms: non-fast-forward merge failure.
   - re-fetch and re-check divergence before any merge.
5. Symptoms: remote branch deletion denied.
   - keep branch and report the denied deletion explicitly.
6. Symptoms: parallel feature streams keep polluting staged scope.
   - move each stream to its own `git worktree` and recommit from isolated working trees.
7. Symptoms: runnable build identity is unclear before commit/push handoff.
   - run `dart tooling/print_build_identity.dart` and include the resulting packet in the handoff.

## Significant-Change Docs Sync Policy

Significant change definition:
- Any behavior/UI/data-flow change under `lib/` or `tooling/` affecting runtime behavior, agent workflows, CI contracts, or developer process.
- Any multi-file feature pass.
- If uncertain, treat as significant.

Mandatory prompt at end of significant implementation work:
- Ask exactly: "Would you like me to run Assistant Docs Sync for this change now?"

If user says yes:
- update only relevant assistant docs by touched scope:
  - Reader/UI -> reader workflow + canonical app sections + related routing docs
  - Data pipeline -> data workflow + manifest/contract references only where needed
  - Localization -> localization workflow/glossary + impacted routing docs
  - CI/repo ops -> CI workflow + manifest/validator docs
  - Template-only -> template file only unless user explicitly requests propagation

If user says no:
- continue without docs edits
- mention potential docs drift risk briefly in handoff

## Handoff Checklist

- staged file list exactly matches requested scope
- ignored files are not accidentally staged
- targeted validation/tests passed
- commit message matches change intent
- push succeeded to correct remote branch
- optional merge/prune operations completed only when requested
- final state is clean (`git status --short --branch`)
- worktree isolation was used when parallel streams existed

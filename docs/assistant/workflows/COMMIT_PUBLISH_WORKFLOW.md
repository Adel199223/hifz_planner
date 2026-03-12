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
- Do not mix assistant-doc sync updates into the feature commit for a significant stage.
- Do not force-push to `main`.
- Do not auto-push as the default end of stage closeout.
- Do not delete remote branches without a keep-list and user intent.
- Do not perform broad assistant-doc rewrites after implementation; use targeted docs sync by scope only.

## Primary Files

- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/manifest.json`
- `docs/assistant/workflows/CI_REPO_WORKFLOW.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `.gitignore`

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

## Targeted Tests

Use tests that match touched files before committing. For docs/repo operations, minimum:

```powershell
dart run tooling/validate_agent_docs.dart
flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart
flutter test -j 1 -r expanded test/app/navigation_shell_menu_test.dart
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
```

## Default Stage Closeout Sequence

For major implementation stages, default local closeout order is:

1. Finish implementation and run targeted validation for the touched scope.
2. Commit implementation files first.
3. Ask exactly: "Would you like me to run Assistant Docs Sync for this change now?"
4. If approved, run targeted Assistant Docs Sync for the touched scope.
5. Commit docs changes separately as a docs-only commit.
6. End with a clean local worktree.
7. Push remains a separate, explicit action.

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

## Significant-Change Docs Sync Policy

Significant change definition:
- Any behavior/UI/data-flow change under `lib/` or `tooling/` affecting runtime behavior, agent workflows, CI contracts, or developer process.
- Any multi-file feature pass.
- If uncertain, treat as significant.

Mandatory prompt at end of significant implementation work:
- Ask exactly: "Would you like me to run Assistant Docs Sync for this change now?"

If user says yes:
- after the implementation commit already exists, update only relevant assistant docs by touched scope:
  - Reader/UI -> reader workflow + canonical app sections + related routing docs
  - Data pipeline -> data workflow + manifest/contract references only where needed
  - Localization -> localization workflow/glossary + impacted routing docs
  - CI/repo ops -> CI workflow + manifest/validator docs
  - Template-only -> template file only unless user explicitly requests propagation
- commit docs changes separately from the implementation commit

If user says no:
- continue without docs edits
- mention potential docs drift risk briefly in handoff

## Handoff Checklist

- staged file list exactly matches requested scope
- ignored files are not accidentally staged
- targeted validation/tests passed
- commit message matches change intent
- major-stage closeout kept implementation and docs sync in separate commits when docs sync ran
- push succeeded to correct remote branch
- optional merge/prune operations completed only when requested
- push/publish happened only when explicitly requested
- final state is clean (`git status --short --branch`)
- worktree isolation was used when parallel streams existed

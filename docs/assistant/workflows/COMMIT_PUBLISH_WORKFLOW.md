# Commit and Publish Workflow

## What This Workflow Is For

Use this workflow whenever the user asks to commit. It enforces safe staging, ignore hygiene, validation, push, and optional remote cleanup.

## When To Use

Use when requests include:
- `commit`
- `stage`
- `push`
- `merge to main`
- branch cleanup/pruning on local or remote

## What Not To Do

- Do not commit blindly with `git add .` unless the user explicitly wants every change.
- Do not include unrelated files in the same commit.
- Do not force-push to `main`.
- Do not delete remote branches without a keep-list and user intent.

## Primary Files

- `agent.md`
- `APP_KNOWLEDGE.md`
- `docs/assistant/manifest.json`
- `docs/assistant/workflows/CI_REPO_WORKFLOW.md`
- `docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md`
- `.gitignore`

## Minimal Commands

```powershell
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

## Handoff Checklist

- staged file list exactly matches requested scope
- ignored files are not accidentally staged
- targeted validation/tests passed
- commit message matches change intent
- push succeeded to correct remote branch
- optional merge/prune operations completed only when requested
- final state is clean (`git status --short --branch`)

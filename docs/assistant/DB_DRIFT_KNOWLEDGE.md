# DB/Drift Knowledge - Hifz Planner

This document is the DB truth/runbook for contributors and AI agents.
Use it when changes touch schema, migrations, repositories, planner state, or review scheduling.

## What This Is For

Use this doc to:
- understand current Drift schema and invariants
- modify schema/migrations safely
- locate ownership for DB-touching logic
- run the right tests after DB-related changes

## When To Use vs Not Use

Use this doc:
- before editing `lib/data/database/app_database.dart`
- before changing planner/review repositories/services
- when adding fields/tables/indexes

Do not rely on this doc alone when:
- code and docs disagree (code wins)
- behavior depends on reader UI logic rather than persistence logic

## Source of Truth Files

- Schema + migrations:
  - `lib/data/database/app_database.dart`
- Generated Drift output:
  - `lib/data/database/app_database.g.dart`
- Provider wiring:
  - `lib/data/providers/database_providers.dart`
- Repositories:
  - `lib/data/repositories/*.dart`
- Planner/scheduler services:
  - `lib/data/services/daily_planner.dart`
  - `lib/data/services/spaced_repetition_scheduler.dart`
  - `lib/data/services/calibration_service.dart`
  - `lib/data/services/forecast_simulation_service.dart`

## Current Schema Snapshot

Database:
- class: `AppDatabase`
- schema version: `3`

Tables:
1. `ayah`
2. `bookmark`
3. `note`
4. `mem_unit`
5. `schedule_state`
6. `review_log`
7. `app_settings`
8. `calibration_sample`
9. `pending_calibration_update`
10. `mem_progress`

## Invariants and Constraints

### `ayah`
- Unique key: `(surah, ayah)`
- `page_madina` can be null until metadata import

### `mem_unit`
- `unit_key` must be unique
- `kind` constrained to:
  - `ayah_range`, `page_segment`, `custom`

### `schedule_state`
- Primary key: `unit_id`
- Foreign key to `mem_unit(id)` with cascade delete
- grade checks for `last_grade_q`: `5,4,3,2,0`
- suspension flags constrained to `0/1`

### `review_log`
- Foreign key to `mem_unit(id)` with cascade delete
- grade check for `grade_q`: `5,4,3,2,0`

### `app_settings` singleton
- `id` constrained to `1`
- single-row policy enforced by `ensureSingletonRows()`
- important fields:
  - profile
  - force_revision_only
  - daily/default minute settings
  - caps and averages
  - grade distribution JSON

### `mem_progress` singleton
- `id` constrained to `1`
- single-row policy enforced by `ensureSingletonRows()`
- stores cursor:
  - `next_surah`
  - `next_ayah`

### Calibration tables
- `calibration_sample` stores time-per-ayah samples by kind
- `pending_calibration_update` stores deferred settings updates
- singleton policy on `pending_calibration_update` via `id == 1`

### Indexes (created in migration helpers)
- `idx_schedule_state_due_day`
- `idx_schedule_state_is_suspended`
- `idx_review_log_unit_id_ts_day`
- `idx_calibration_sample_kind_day_id`

## Migration and Codegen Workflow

## Where schema changes happen
- Edit `lib/data/database/app_database.dart`
- Update migration logic in `MigrationStrategy.onUpgrade`

## Generated file policy
- `lib/data/database/app_database.g.dart` is generated, do not hand-edit
- if regeneration is needed, use Drift build workflow in your dev environment

## Required migration discipline

For any schema change:
1. bump `schemaVersion`
2. add compatible upgrade path from previous versions
3. preserve singleton row initialization via `ensureSingletonRows()`
4. keep indexes in sync with query patterns

## Ownership Map (DB Touching)

### Repository ownership
- `quran_repo.dart`: ayah reads/search/page queries
- `bookmark_repo.dart`: bookmark CRUD and watchers
- `note_repo.dart`: note CRUD and watchers
- `mem_unit_repo.dart`: memorization unit persistence
- `schedule_repo.dart`: schedule row lifecycle + scheduler apply
- `review_log_repo.dart`: review event writes/reads
- `settings_repo.dart`: app settings persistence
- `progress_repo.dart`: memorization cursor persistence
- `calibration_repo.dart`: sample and pending calibration persistence

### Service ownership
- `daily_planner.dart`: plan generation from settings/progress/schedule
- `spaced_repetition_scheduler.dart`: due-date and interval calculations
- `calibration_service.dart`: applies sample-derived parameter updates
- `forecast_simulation_service.dart`: deterministic projection from current state
- importers:
  - `quran_text_importer_service.dart`
  - `page_metadata_importer_service.dart`

## Common Change Scenarios

### Add a new field safely

1. add column to target table in `app_database.dart`
2. bump `schemaVersion`
3. add migration logic in `onUpgrade`
4. update impacted repository APIs
5. update service logic and tests

### Update planner settings path

Likely files:
- `lib/data/repositories/settings_repo.dart`
- `lib/screens/plan_screen.dart`
- `lib/data/services/daily_planner.dart`
- `lib/data/services/forecast_simulation_service.dart`

Validate:
- plan screen tests
- planner/forecast service tests

### Update review-log + schedule flow

Likely files:
- `lib/screens/today_screen.dart`
- `lib/data/repositories/review_log_repo.dart`
- `lib/data/repositories/schedule_repo.dart`
- `lib/data/services/spaced_repetition_scheduler.dart`

Validate:
- today screen tests
- schedule repo tests
- scheduler tests

## Validation Checklist for DB Changes

Minimum:

```powershell
flutter test -j 1 -r expanded test/data/database/app_database_test.dart
flutter test -j 1 -r expanded test/data/repositories
flutter test -j 1 -r expanded test/data/services
flutter analyze
```

Reader/planner regressions (recommended):

```powershell
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/screens/plan_screen_test.dart
flutter test -j 1 -r expanded test/screens/today_screen_test.dart
```

## What Not To Do

- Do not hand-edit `app_database.g.dart`.
- Do not change schema without migration path.
- Do not break singleton initialization for `app_settings` and `mem_progress`.
- Do not skip repository/service tests after DB updates.

## Quick Discovery Commands

```powershell
rg -n "schemaVersion|MigrationStrategy|ensureSingletonRows" lib/data/database
rg -n "class .*Repo|updateSettings|applyReviewWithScheduler|planToday" lib/data
rg -n "mem_unit|schedule_state|review_log|app_settings|mem_progress" test/data
```

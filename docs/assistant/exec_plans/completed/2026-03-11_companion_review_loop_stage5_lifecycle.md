# ExecPlan: Companion Review Loop + Stage-5 Lifecycle

## Purpose
- Close the gap between Companion review completion and scheduler state updates.
- Promote `stable` lifecycle units to `maintained` on the first successful scheduled review.

## Scope
- In scope:
- add a shared review-completion service/provider
- wire Today and Companion review completion through the same service
- promote `stable -> maintained` on successful scheduled review
- add targeted tests and localized UI strings for Companion review completion
- Out of scope:
- new routes or launch modes
- schema changes or Drift codegen
- lifecycle demotion/decay policy

## Assumptions
- Successful review means `gradeQ >= 3`.
- Stage 5 remains an overlay on the existing review scheduler.
- Today grade buttons remain available as a fallback path.

## Milestones
1. Add shared review completion service and provider.
2. Refactor Today and Companion review completion UI to use the shared flow.
3. Add lifecycle promotion tests and screen coverage.

## Detailed Steps
1. Add `ReviewCompletionService` and `ReviewCompletionResult`; wire a provider in `lib/data/providers/database_providers.dart`.
2. Refactor `TodayScreen` grading to call the shared service.
3. Extend `CompanionChainScreen` summary card to support review-mode grading, promotion messaging, and return-to-today action.
4. Add targeted tests for service behavior, Today fallback behavior, Companion review summary behavior, and maintained counting.

## Decision Log
- 2026-03-11: Stage 5 rides existing `mode=review`; no dedicated runtime in this milestone.
- 2026-03-11: Promotion rule is `stable -> maintained` on first scheduled review success (`gradeQ >= 3`).
- 2026-03-11: Companion review summary owns grade submission; Today keeps fallback grade buttons.

## Validation
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/review_completion_service_test.dart`
- `flutter test -j 1 -r expanded test/screens/companion_chain_screen_test.dart`
- `flutter test -j 1 -r expanded test/screens/today_screen_test.dart`
- `flutter test -j 1 -r expanded test/data/services/daily_planner_test.dart`
- `dart run tooling/validate_localization.dart`

## Progress
- [x] Milestone one
- [x] Milestone two
- [x] Milestone three

## Surprises and Adjustments
- Today currently duplicates review-log + scheduler writes instead of using a shared review completion path.
- `dart format` must exclude ExecPlan markdown files; formatting code files only avoids parser errors on `.md`.

## Handoff
- Added a shared review-completion service/provider, refactored Today to use it, and extended Companion review summaries with grade-save + promotion flow.
- Added targeted coverage for the service contract, Today fallback promotion path, Companion review save path, and planner maintained-count snapshot.

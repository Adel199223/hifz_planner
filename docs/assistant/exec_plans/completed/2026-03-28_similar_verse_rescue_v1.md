# ExecPlan: Similar-Verse Rescue V1

## Purpose
- Turn `similar_confusion` from a repair tag into a real Quran-specific rescue flow.

## Scope
- In scope:
  - local-only similar-verse candidate matching over existing memorization units
  - a focused rescue screen reachable from Today and Companion
  - Today sectioning/next-step support for similar-verse rescue
  - focused tests and thin continuity docs
- Out of scope:
  - schema changes
  - planner rewrite
  - ASR, teacher workflows, or global mutashabihat indexing

## Assumptions
- `last_error_type = similar_confusion` remains the source signal for rescue routing.
- Candidate generation should stay conservative and may honestly return no confident match.
- Existing Reader routes remain the comparison surface for manual inspection.

## Milestones
1. Add the candidate service and rescue screen.
2. Surface rescue entry points in Today and Companion.
3. Add focused tests and continuity docs.

## Detailed Steps
1. Add `SimilarVerseCandidateService` and provider using `MemUnitRepo`, `QuranRepo`, and existing Arabic normalization.
2. Add `/similar-verses/rescue?unitId=...` and a thin rescue screen with confident/no-candidate states.
3. Extend `TodayPath` to derive `similarVerseRepairs` from weak spots without changing planner buckets.
4. Add Today/Companion rescue actions for `similar_confusion`.
5. Add focused tests for service scoring, Today split/next-step, rescue UI, and Companion entry points.
6. Run the normal lightweight validation set and leave a review-ready local snapshot.

## Decision Log
- 2026-03-28: Use a route-backed rescue screen instead of a sheet so Today next-step and Companion follow-up can share one clean navigation target.
- 2026-03-28: Derive the Similar Verses section in `TodayPath` instead of adding a new planner bucket.

## Validation
- `flutter pub get`
- `dart run tooling/validate_localization.dart`
- `dart run tooling/validate_agent_docs.dart`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test -j 1 -r expanded test/data/services/similar_verse_candidate_service_test.dart test/screens/today_path_test.dart test/screens/today_screen_test.dart test/screens/similar_verse_repair_screen_test.dart test/screens/companion_chain_screen_test.dart`
- `flutter build web`
- `npm run smoke`
- Recorded closeout outcome:
  - docs validation passed
  - web build and Playwright smoke passed during implementation closeout
  - targeted Flutter tests remained blocked in this environment by the native-assets `objective_c` `hook.dill` failure

## Progress
- [x] Add the candidate service and rescue screen
- [x] Surface rescue entry points in Today and Companion
- [x] Add focused tests and continuity docs

## Surprises and Adjustments
- The existing Error-Aware Repair V1 plumbing already exposed `similar_confusion` cleanly in Today and Companion, so this pass could stay thin and avoid scheduler/schema changes.

## Handoff
- Status: complete and closed enough for continuity on the current branch.
- Similar-Verse Rescue V1 now ships a dedicated Similar Verses section on Today, a conservative local candidate finder over memorized units, and a focused rescue screen / Companion follow-up action for `similar_confusion`.
- Shell coherence is closed in source: the rescue route now renders inside the shared app shell with truthful narrow-shell titles and medium/wide in-body page headings instead of nested page chrome.
- The remaining local blocker is environmental, not product-level: Flutter test execution is still blocked here by the native-assets `objective_c` `hook.dill` failure.
- The next follow-up should refine rescue quality and memorization-engine depth, not broaden into platform or schema work.

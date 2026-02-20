## 0. How to use this knowledge pack (for the Codex/AI agent)

**Read order (keep token usage low):**
1) `agent.md` (Codex entrypoint / operating rules)
2) `docs/assistant/APP_KNOWLEDGE.md` (this file: repo map + commands + pointers)
3) Only open other docs when relevant (examples: testing, DB, assets, UI)

**Rules:**
- Prefer file-path-grounded answers. When unsure, say `Uncertain` and give a command to verify.
- Before implementing changes, locate the owning file(s) using Section J and verify with ripgrep:
  - `rg -n "symbol_or_keyword" lib test tooling`
- Keep diffs small and localized; avoid repo-wide rewrites.
- Prefer adding small helpers/tests over fragile test sleeps/timeouts.

## 0b. How we work / Workflow (token-efficient, Windows-friendly)

**Safe change flow:**
1) Snapshot:
   - `git status --short`
   - `git diff --name-only`
   - `flutter --version`
2) Verify (default):
   - `dart format .`
   - `flutter analyze`
   - `flutter test -j 1 -r expanded`
3) Make a focused change.
4) Re-run the smallest relevant test target(s), then the full suite if practical.
5) Commit with a descriptive message.

**Windows notes that prevent common failures:**
- `flutter format` is not a Flutter command → use `dart format .`
- Prefer `flutter test -j 1` on Windows to avoid occasional build/test cache file conflicts.
- If `flutter` is not on PATH in the current shell, run it via the absolute path:
  - `& "C:\dev\tools\flutter\bin\flutter.bat" <command>`

---

## A. What the app does (user workflows)

**Hifz Planner** is a Qur’an memorization app with:
1) **Reader (verse-level)**: each ayah is selectable, highlightable (hover/tap), with actions:
   - Bookmark ayah
   - Add note on ayah
   - Copy ayah text
   - (Later) Play audio for ayah / play from ayah (audio provider interface exists; no reciters bundled until licensing is solved)

2) **Local Qur’an dataset (offline)**:
   - Bundles Tanzil Uthmani text locally (verbatim).
   - Imports it into a local database (idempotent importer).
   - Optional import of Madina Mushaf page metadata.
   - Includes Text Integrity Guard (checksum + sanity tests) to protect correctness.

3) **Memorization & revision planning**:
   - Default onboarding uses a short questionnaire to propose a plan (editable before activation).
   - Optional “Calibration Mode” measures actual user timing/recall for 7 days and proposes a more accurate plan.
   - Daily “Today” session:
     - Reviews due items first (spaced repetition)
     - Adds new memorization only if time budget allows
     - Auto “revision-only” days when overloaded (default; user can change)
   - Adaptive new memorization amount:
     - Can start high for users with lots of time
     - Naturally decreases later as review load grows (while keeping daily time stable)

4) **Forecasting**:
   - Estimates completion date and future workload using simulation based on the user’s capacity and measured timings.

Primary user workflows:
- Import Qur’an text dataset → open Reader → bookmark/note verses.
- Onboard (questionnaire or calibration) → preview suggested plan → edit → activate.
- Daily “Today” session: review + (optional) new memorization.
- Adjust plan any time (apply from tomorrow by default) and continue.

---

## B. How to run it (dev / test / build) — exact commands + entrypoints

### Run (Windows desktop dev)
```powershell
flutter pub get
flutter run -d windows

Run (PATH-safe / PowerShell-safe)
Use this when flutter isn’t recognized in the current terminal/session:
& "C:\dev\tools\flutter\bin\flutter.bat" pub get
& "C:\dev\tools\flutter\bin\flutter.bat" run -d windows

Verify (default, Windows-safe)
dart format .
flutter analyze
flutter test -j 1 -r expanded

Targeted tests (run the smallest thing that proves the change)
flutter test -j 1 -r expanded test/screens/reader_screen_test.dart
flutter test -j 1 -r expanded test/screens/notes_screen_test.dart
flutter test -j 1 -r expanded test/screens/bookmarks_screen_test.dart
flutter test -j 1 -r expanded test/screens/settings_screen_test.dart
flutter test -j 1 -r expanded test/widget_test.dart

Widget test stability rule (important)
Avoid unbounded pumpAndSettle() when dialogs/animations/timers exist.
Prefer the bounded helper:
test/helpers/pump_until_found.dart → pumpUntilFound(...)

Assets policy (Tanzil)
The repo may contain only assets/quran/.gitkeep during development.
If assets/quran/tanzil_uthmani.txt is not present locally, integrity tests should skip (expected).
When you later decide to bundle the Tanzil text in the repo, place it at:
assets/quran/tanzil_uthmani.txt


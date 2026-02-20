# APP_KNOWLEDGE — Hifz Planner (Desktop first, Mobile/Web later)

## 0. How to use this knowledge pack (for the Codex/AI agent)
- Primary source of truth for project Q&A: `docs/assistant/APP_KNOWLEDGE.md` (this file).
- Always answer with file-path-grounded facts, then suggest a command to verify.
- If a claim cannot be proven from files/grep output, label it `Uncertain` and provide a command to verify.
- Assistant routing hint:
  - If asked “where does X live?”, inspect **Section J. Where is X? index** first, then verify with:
    - `rg -n "symbol_or_keyword" lib test tooling`
- Keep changes small and localized. Avoid rewriting unrelated files.

## 0b. How we work / Workflow (token-efficient)
- Safe change flow:
  1) Snapshot: `git status -sb`, `git diff --stat`, `flutter --version`
  2) Run tests: `flutter test`
  3) Make a focused change
  4) Re-run relevant tests
  5) Commit with a descriptive message
- AI agent rule: when asked to implement a change, first identify the owning file(s) from Section J and verify with `rg`.

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
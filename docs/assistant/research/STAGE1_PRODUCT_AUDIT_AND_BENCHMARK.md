# Stage 1 Product Audit and Benchmark Matrix

## Executive Summary

The app already has uncommon depth for Quran reading plus hifz planning:
- `Reader` is a strong Quran.com-inspired reading surface with audio, translation, tajweed, notes, and bookmarks.
- `Today` is the strongest learner-facing planning surface because it turns the system into clear daily actions.
- `Companion` contains the most learning-science depth, especially around staged retrieval and delayed consolidation.
- `Plan` is the biggest product risk: it is powerful, but currently asks a non-coder to think like a planner engineer.

Stage 1 conclusion:
- keep the current planning engine direction
- keep Stage-4 delayed durability as a core differentiator
- keep Companion as the deep memorization engine
- make `Today`, not `Plan`, the center of the learner experience
- simplify `Plan` into a guided coaching system and hide most advanced knobs

This stage recommends a redesign sequence of:
1. simplify information architecture
2. redesign planner as a guided coach
3. redesign the scheduler contract
4. implement the algorithm upgrade only after product behavior is fixed

## Stage 1 Method

Internal evaluation sources:
- current repo docs and code in `APP_KNOWLEDGE.md`, planner/support guides, `plan_screen.dart`, `today_screen.dart`, `daily_planner.dart`, `forecast_simulation_service.dart`, and companion runtime files

External benchmark set:
- Quran.com:
  - https://quran.com/
  - https://quran.com/product-updates/take-a-tour-of-quran-com
- Tarteel:
  - https://support.tarteel.ai/hc/en-us/articles/32486640388877-How-do-I-use-the-Goals-feature
  - https://support.tarteel.ai/hc/en-us/articles/25988182452749-Hide-Ayahs
  - https://tarteel.ai/blog/how-to-search-quranic-ayat-by-voice-with-tarteel/
  - https://tarteel.ai/blog/tarteel-ai-adaptive-mode/
- Thabit:
  - https://thabitapp.io/
- Quranki:
  - https://www.quranki.com/
- Anki / FSRS:
  - https://docs.ankiweb.net/deck-options
- SuperMemo:
  - https://www.super-memory.com/help/smalg.htm
- Learning science:
  - https://pubmed.ncbi.nlm.nih.gov/33094555/
  - https://pubmed.ncbi.nlm.nih.gov/37856684/
  - https://pubmed.ncbi.nlm.nih.gov/27027887/
  - https://pubmed.ncbi.nlm.nih.gov/27530500/
  - https://www.learningscientists.org/powerpoint-slides

Scoring rubric:
- `1` = weak
- `3` = workable but needs redesign
- `5` = strong fit for the solo-learner, simple-first target

Dimensions:
- purpose clarity
- beginner usability
- solo-learner usefulness
- memorization effectiveness
- resilience under missed/slower days
- cognitive load
- mobile suitability

## Feature-Purpose Scorecard

| Surface | Purpose clarity | Beginner usability | Solo usefulness | Memorization effectiveness | Resilience | Cognitive load | Mobile suitability | Verdict |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Reader | 4 | 3 | 4 | 3 | 4 | 3 | 2 | Keep and polish |
| Plan | 3 | 1 | 4 | 4 | 4 | 1 | 1 | Highest simplification priority |
| Today | 5 | 4 | 5 | 5 | 4 | 3 | 3 | Make this the primary learner home |
| Companion | 3 | 2 | 4 | 5 | 4 | 2 | 2 | Keep as engine, simplify entry and framing |
| Bookmarks / Notes | 4 | 4 | 3 | 2 | 4 | 4 | 3 | Keep lightweight |
| Settings / Imports | 3 | 2 | 2 | 2 | 3 | 3 | 2 | Keep functional, reduce exposure |
| Reciters | 4 | 4 | 3 | 3 | 4 | 4 | 4 | Keep as secondary support surface |

## Surface Findings

### Reader

Current value:
- strong reading/listening foundation
- good parity direction with Quran.com
- already supports audio, translation, notes, bookmarks, tajweed, and reciter switching

Main friction:
- too many visible actions for a first-time solo learner
- several placeholder actions still sit beside real actions
- desktop-first density will not translate cleanly to mobile

Stage-1 verdict:
- keep the feature depth
- simplify visible actions
- separate “read now” from “study tools” more clearly

### Plan

Current value:
- impressive planning depth for a hifz app
- already includes scheduling, overrides, calibration, forecast, caps, and advanced availability models

Main friction:
- too many decisions before the learner has confidence in the system
- calibration and grade-distribution inputs are expert-level concepts
- advanced scheduling, time windows, overrides, and forecast all live too close to first-run setup
- the screen currently behaves more like a control panel than a coach

Stage-1 verdict:
- preserve the engine
- redesign the product layer
- move most knobs out of the default learner path

### Today

Current value:
- clearest expression of the app’s real purpose
- good prioritization of Stage-4 delayed checks, reviews, and new work
- actions are concrete: open reader, open companion, submit grade

Main friction:
- still assumes the learner already understands why items are ordered this way
- no recovery assistant when the day becomes impossible
- grading and overload handling are not explained enough

Stage-1 verdict:
- promote `Today` to the core daily home
- add coaching, explanations, and recovery flows here first

### Companion

Current value:
- this is the app’s biggest differentiation
- staged retrieval, weak-target handling, hidden recall, and delayed consolidation are stronger than most public Quran memorization apps

Main friction:
- conceptually dense for a solo learner without a teacher
- stage logic is powerful but hard to understand from the product surface
- mobile use would need clearer progressive disclosure and simpler language

Stage-1 verdict:
- keep the stage logic
- do not expose it as the first thing users must understand
- present it as guided practice, not as internal stage mechanics

### Bookmarks / Notes

Current value:
- useful support tools for reading and reflection

Main friction:
- secondary to the main product promise
- not yet deeply integrated into planning or memorization reflection loops

Stage-1 verdict:
- keep
- do not expand until the planner/Today redesign is stable

### Settings / Imports

Current value:
- necessary operational surface

Main friction:
- technical concepts like imports and metadata readiness are more operational than learner-facing

Stage-1 verdict:
- keep functional
- reduce exposure in the main learner journey

### Reciters

Current value:
- practical and understandable
- strong fit as a support feature for reading and memorization

Main friction:
- secondary surface, not a planning differentiator

Stage-1 verdict:
- keep as-is with minor polish

## External Benchmark Matrix

| Reference | Strong patterns | Best-fit adoption for this app | What not to copy directly |
|---|---|---|---|
| Quran.com | clear reading entry, strong settings for reading comfort, multi-language reading/listening, lightweight onboarding tour, topic/reflection ecosystem | reader simplification, onboarding help, better action prioritization, comfort-first reading defaults | do not turn this app into a content portal before planner clarity is solved |
| Tarteel | suggested goals, active-recall-only progress, hide-ayah memorization flow, adaptive presentation, voice-first utility, off-platform session support | guided goals, “progress only counts when recalling”, cleaner memorization mode framing, mobile-friendly adaptive reader, manual/off-platform recovery logging | heavy ASR/A.I. dependencies are not required for the first planner redesign |
| Thabit | explicit New Lesson / New Review / Old Review mental model, Quran-specific long-term review framing, strong “keep me on track” positioning | split review lanes more clearly, explain short-term vs long-term review, stronger page-level retention model, simpler learner language | proprietary algorithm claims and page-perfect promises should not be copied without local validation |
| Quranki | ultra-simple daily review loop, configurable prompt size, show-answer flow, progress stats | add a minimal daily review mode and simpler progress framing, especially for solo learners who want less setup | too little planning depth for this app’s longer-term vision |
| Anki / FSRS | adapt scheduling to forgetting likelihood, hide legacy knobs when the smarter scheduler is on, retain explainability around desired retention and workload tradeoffs | later algorithm stage should expose fewer user knobs and more understandable outcomes | do not introduce generic flashcard metaphors that weaken Quran/hifz specificity |
| SuperMemo | item difficulty matters, spacing should adapt to stability, simple heuristics can evolve into richer models over time | confirms the staged approach: deterministic heuristic first, more adaptive later | do not import opaque complexity before learner-facing behavior is settled |
| Learning science | retrieval practice beats passive restudy, spaced practice reduces forgetting, successive relearning reduces the value of overtraining the first session, sleep between sessions matters | reinforce hidden recall, next-day checks, repeated retrieval across days, and avoiding too much initial overlearning | do not turn learning-science principles into jargon-heavy UI |

## Strengths to Keep

1. `Today` as an action surface with review/new/stage4 prioritization.
2. Stage-4 delayed consolidation as a first-class product concept.
3. Companion’s retrieval-first, correction-aware memorization engine.
4. Reader’s Quran.com-aligned direction.
5. Local-first planning and execution model.

## Features to Simplify

1. `Plan` screen complexity:
   - onboarding inputs, advanced scheduling, overrides, calibration, and forecast currently compete for attention on one screen
2. Technical planner language:
   - calibration timing
   - grade-distribution percentages
   - deterministic simulation
   - q=5/4/3/2/0 mental model
3. Advanced scheduling controls:
   - availability model
   - fixed times
   - specific hour windows
   - per-day session-time override buttons
4. Companion framing:
   - keep the engine, simplify how it is explained and entered
5. Reader action density:
   - separate real daily actions from secondary/coming-soon actions

## Missing Features Worth Adding

### High-value, near-term additions

1. Guided learner presets:
   - easy
   - normal
   - intensive
2. Missed-session recovery wizard:
   - “I missed today”
   - “I missed several days”
3. Minimum viable day mode:
   - a low-time fallback plan instead of silent failure
4. Daily explanation layer:
   - “why this is assigned today”
   - “why new is blocked”
   - “what to do if you cannot finish”
5. Plan health indicator:
   - healthy / pressured / overloaded
6. Backlog burn-down mode:
   - short-term recovery posture until the system stabilizes

### Strong medium-term additions

7. Off-platform/manual session logging:
   - useful when the learner studies outside the app
8. Adaptive reader presentation for memorization:
   - stronger mobile-first memorization display modes
9. Suggested goals:
   - memorize a juz
   - review a surah
   - maintain existing hifz
10. Motivation layer:
   - streaks or consistency summaries that support, rather than distract from, memorization quality

## Features That Should Stay Advanced or Hidden

Keep out of the default beginner path:
- exact session times
- specific-hours windows editor
- advanced availability model selection
- manual q-percentage editing
- calibration apply timing choice
- raw forecast curves
- per-day override buttons for session A/B times

Keep internal-only unless later evidence proves otherwise:
- low-level scheduling formulas
- item stability jargon
- retrieval-strength jargon
- raw stage/state machine vocabulary

## Planner-Specific Gap List

1. The current planner is stronger as an engine than as a product.
2. The app has no simple-first planner preset layer yet.
3. Missed-day behavior is not yet presented as a learner-facing recovery workflow.
4. Forecast output is still closer to a diagnostic tool than a decision-support coach.
5. Calibration is powerful but too technical for the default audience.
6. The planner does not yet visibly translate overload into a simple recommendation like “reduce new”, “switch to recovery”, or “do minimum day”.
7. The distinction between immediate review pressure and long-term maintenance could be framed more clearly, similar to Thabit’s new-review vs old-review model.
8. The app needs a plain-language explanation model for:
   - why a day is heavy
   - why Stage-4 blocks new
   - what happens after missed sessions
   - when the plan is too aggressive

## Ranked Opportunity Backlog

### Tier A: highest-value next stage inputs

1. Make `Today` the primary learner home.
2. Redesign `Plan` into a guided, preset-first coaching surface.
3. Add a recovery workflow for missed sessions and overloaded weeks.
4. Add plain-language assignment explanations and plan-health feedback.
5. Hide most advanced scheduling and calibration controls by default.

### Tier B: strong follow-up after the UX redesign

6. Reframe Companion as guided memorization practice, not internal stage logic.
7. Add a simpler daily-review-only mode inspired by Quranki-style minimalism.
8. Add suggested goals and consistent progress framing inspired by Tarteel.
9. Improve reader action prioritization and mobile adaptability.

### Tier C: later stage inputs

10. Add off-platform/manual session logging.
11. Explore voice-first search or memorization support only after the planner product is stable.
12. Add more advanced adaptive scheduler behavior after the heuristic redesign is accepted.

## Stage 1 Conclusions for Stage 2

Stage 2 should treat the app as four learner journeys:
1. I just want to read.
2. I want to do today’s memorization.
3. I missed days and need recovery.
4. I want a realistic plan without understanding the engine.

Stage 2 should explicitly:
- reduce visible planner decisions
- move expert controls behind an advanced layer
- make `Today` more coach-like
- define a simple-first app map that survives mobile constraints

## Validation Checklist

Stage 1 deliverables included here:
- feature-purpose scorecard
- external benchmark matrix
- ranked opportunity backlog
- planner-specific gap list
- clear stage-2 handoff

No runtime behavior, schema, or public interface changes are introduced in this stage.

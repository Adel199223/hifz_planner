# Web Version Roadmap

This roadmap tracks the serious Flutter web target for the Adaptive Hifz Path product.

## Product intent

The web target should make the app more useful as a calm solo memorization companion, not reduce it to a marketing shell or a platform demo.

## Wave 0 - reset and audit

Completed in this pass:
- created a repo-native ExecPlan for the web initiative
- documented the preferred browser architecture and honest fallbacks
- identified platform seams around Drift opening, filesystem services, fonts, and audio

## Wave 1 - bootable web foundation

Completed in this pass:
- added standard Flutter `web/` support
- split startup so desktop-only audio initialization is guarded off web
- enabled semantics on web startup for accessibility and Playwright discoverability
- preserved the existing Flutter route structure with Today as the center of gravity

## Wave 2 - storage and platform abstractions

Completed in this pass:
- added `AppDatabaseConnectionFactory`
- added `DatabaseStorageStatus`
- kept native Drift opening intact and added Drift web opening for browser storage
- added `QuranDataReadiness` so web can guide first-run imports honestly
- swapped filesystem-only service exports to native/web conditional exports

## Wave 3 - reader and audio web parity

Completed in this pass:
- kept streaming-first audio on web
- disabled offline-download-only audio behavior on web
- preserved Quran.com and QCF loading with browser-safe memory/network fallbacks
- kept Reader deep-link routes intact

## Wave 4 - guided solo path web polish

Completed in this pass:
- made the shell responsive for narrow, medium, and wide widths
- added a Settings-visible storage status and Quran-data status
- added a shared guided setup path for Today and Settings that imports Qur'an text first, backfills page metadata only if it is still missing, saves a calm starter plan, and prepares the first memorization unit
- tightened zero-unit Today so guided setup is the only release-visible first-run path and the initial planner pass stays non-materializing until setup owns the first unit
- made Today show a browser-storage warning only when persistence is degraded or transient
- restored beginner Plan setup from the same saved truth that the scheduler uses
- switched TodayPath to typed planner availability/notice state so it no longer invents a stricter new-work lock than the planner

## Wave 5 - browser automation and release quality

Started in this pass:
- add Playwright + Chromium smoke coverage under `tooling/playwright/`
- prefer role/text locators and failure traces/screenshots
- gate persistence-sensitive smoke assertions on the browser storage mode that is actually active
- keep the suite intentionally small and product-centered

## Wave 6 - later enhancements

Later waves can add:
- stronger browser storage diagnostics
- cleaner path-based web URLs if the hosting environment is ready
- richer keyboard shortcuts for grading and playback
- PWA/installability once core launch and persistence are stable

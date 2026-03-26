# Playwright smoke harness

This folder contains a small Chromium smoke suite for the Flutter web target.

## Usage

```powershell
cd tooling/playwright
npm install
npx playwright test
```

The config serves `../../build/web`, so run `flutter build web` first.

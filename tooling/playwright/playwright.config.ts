import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 120000,
  expect: {
    timeout: 15000,
  },
  fullyParallel: false,
  retries: 1,
  reporter: [['list']],
  use: {
    baseURL: 'http://127.0.0.1:4317',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    serviceWorkers: 'block',
    video: 'off',
    viewport: { width: 1440, height: 1024 },
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
      },
    },
  ],
  webServer: {
    command: 'npx http-server ../../build/web -p 4317 -c-1 --silent',
    url: 'http://127.0.0.1:4317',
    reuseExistingServer: true,
    timeout: 120000,
  },
  outputDir: './test-results',
});



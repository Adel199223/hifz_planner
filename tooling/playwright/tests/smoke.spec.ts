import { expect, Page, test } from '@playwright/test';

async function openToday(page: Page) {
  await page.goto('/#/today');
  await expect(page.getByText(/today/i).first()).toBeVisible();
}

async function openSettings(page: Page) {
  await page.goto('/#/settings');
  await expect(page.getByText(/settings/i).first()).toBeVisible();
}

async function storageSupportsPersistence(page: Page) {
  await openSettings(page);
  const transientWarning = page.getByText(
    /refreshing or closing the tab may lose your progress/i,
  );
  if ((await transientWarning.count()) > 0) {
    return false;
  }

  const persistentLabel = page.getByText(
    /stored on this device|persistent browser storage/i,
  );
  return (await persistentLabel.count()) > 0;
}

async function ensureGuidedSetupReady(page: Page) {
  await openToday(page);

  const openCompanion = page.getByRole('button', {
    name: /^open companion$/i,
  });
  if ((await openCompanion.count()) > 0) {
    return;
  }

  const setupButton = page.getByRole('button', {
    name: /prepare my first session/i,
  });
  if ((await setupButton.count()) === 0) {
    return;
  }

  await expect(page.getByText(/next step/i)).toHaveCount(0);
  await expect(page.getByText(/review queue/i)).toHaveCount(0);
  await expect(page.getByText(/optional new/i)).toHaveCount(0);

  await setupButton.click();
  await Promise.race([
    openCompanion.waitFor({ state: 'visible', timeout: 90000 }),
    page
        .getByText(/your first memorization unit is ready/i)
        .first()
        .waitFor({ state: 'visible', timeout: 90000 }),
    page
        .getByText(/your solo setup is ready/i)
        .first()
        .waitFor({ state: 'visible', timeout: 90000 }),
    page
        .getByRole('button', { name: /open companion chain/i })
        .first()
        .waitFor({ state: 'visible', timeout: 90000 }),
  ]);
}

test('first-run guided setup reaches a ready state', async ({ page }) => {
  await ensureGuidedSetupReady(page);

  const isReady =
    (await page.getByRole('button', { name: /^open companion$/i }).count()) > 0 ||
    (await page.getByRole('button', { name: /open companion chain/i }).count()) > 0 ||
    (await page.getByText(/your solo setup is ready/i).count()) > 0 ||
    (await page.getByText(/your first memorization unit is ready/i).count()) > 0;

  expect(isReady).toBeTruthy();

  if (await storageSupportsPersistence(page)) {
    await page.goto('/#/today');
    await expect(
      page.getByRole('button', { name: /prepare my first session/i }),
    ).toHaveCount(0);
    const hasPostSetupTodayFlow =
      (await page.getByText(/next step/i).count()) > 0 ||
      (await page.getByText(/review queue/i).count()) > 0;
    expect(hasPostSetupTodayFlow).toBeTruthy();
  }
});

test('today to companion to reader core journey stays usable', async ({ page }) => {
  await ensureGuidedSetupReady(page);
  await openToday(page);

  const setupCompanion = page.getByRole('button', {
    name: /^open companion$/i,
  });
  if ((await setupCompanion.count()) > 0) {
    await setupCompanion.click();
  } else {
    await page.getByRole('button', { name: /open companion chain/i }).first().click();
  }

  await expect(page).toHaveURL(/companion\/chain/);
  await expect(
    page.getByRole('button', { name: /play current ayah/i }),
  ).toBeVisible();

  await page.goto('/#/reader?mode=page&page=1&targetSurah=1&targetAyah=1');
  await expect(page).toHaveURL(/reader/);
  await expect(page.getByText(/page/i).first()).toBeVisible();
});

test('plan persistence after refresh only asserts on persistent browser storage', async ({
  page,
}) => {
  if (!(await storageSupportsPersistence(page))) {
    return;
  }

  await page.goto('/#/plan');
  const weeklyMinutesInput = page.getByRole('textbox', {
    name: /weekly minutes/i,
  });
  await weeklyMinutesInput.fill('350');
  await weeklyMinutesInput.press('Tab');
  await expect(weeklyMinutesInput).toHaveValue('350');
  await page.getByRole('button', { name: /activate/i }).click();
  await page.waitForTimeout(1000);
  await page.reload();
  await expect(
    page.getByRole('textbox', {
      name: /weekly minutes/i,
    }),
  ).toHaveValue('350');
});

test('narrow shell stays usable', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await openToday(page);
  await expect(page.getByRole('tab', { name: /reader/i })).toBeVisible();
  await expect(page.getByRole('tab', { name: /plan/i })).toBeVisible();
  await expect(page.getByRole('tab', { name: /settings/i })).toBeVisible();
});

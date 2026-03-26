import { expect, Page, test } from '@playwright/test';

async function waitForFlutter(page: Page) {
  await page.goto('/#/today');
  await expect(page.getByText(/today/i).first()).toBeVisible();
}

async function runImportIfAvailable(page: Page, buttonName: RegExp) {
  const button = page.getByRole('button', { name: buttonName }).first();
  if ((await button.count()) === 0) {
    return;
  }
  await button.click();
  const progressBar = page.getByRole('progressbar').last();
  await progressBar.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {});
  await progressBar.waitFor({ state: 'hidden', timeout: 60000 }).catch(async () => {
    await page.waitForTimeout(5000);
  });
}

async function ensureBundledData(page: Page) {
  await page.goto('/#/settings');
  await expect(page.getByText(/settings/i).first()).toBeVisible();
  await runImportIfAvailable(page, /import quran text/i);
  await runImportIfAvailable(page, /import page metadata/i);
  await page.goto('/#/today');
  await page.waitForTimeout(2000);
}

test('plan activation persists after refresh', async ({ page }) => {
  await waitForFlutter(page);
  await page.goto('/#/plan');
  const weeklyMinutesInput = page.getByRole('textbox', {
    name: /weekly minutes/i,
  });
  await weeklyMinutesInput.fill('350');
  await page.getByRole('button', { name: /activate/i }).click();
  await page.waitForTimeout(2000);
  await page.reload();
  await expect(page.getByRole('textbox', { name: /weekly minutes/i })).toHaveValue('350');
});

test('core web learner journey', async ({ page }) => {
  await waitForFlutter(page);
  await ensureBundledData(page);

  await page.goto('/#/today');
  const starterUnitButton = page.getByRole('button', {
    name: /generate first memorization unit/i,
  });
  if ((await starterUnitButton.count()) > 0) {
    await starterUnitButton.click();
    await page.waitForTimeout(1500);
  }

  await page.getByRole('button', { name: /open companion chain/i }).first().click();
  await expect(page).toHaveURL(/companion\/chain/);
  await expect(page.getByRole('button', { name: /play current ayah/i })).toBeVisible();

  const autoplaySwitch = page.getByRole('switch', {
    name: /autoplay next ayah/i,
  });
  if ((await autoplaySwitch.count()) > 0) {
    await autoplaySwitch.check();
    await page.reload();
    await expect(page.getByRole('switch', { name: /autoplay next ayah/i })).toBeChecked();
  }

  await page.goto('/#/reader?mode=page&page=1&targetSurah=1&targetAyah=1');
  await expect(page).toHaveURL(/reader/);
  await expect(page.getByText(/page/i).first()).toBeVisible();
});

test('narrow shell stays usable', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await waitForFlutter(page);
  await expect(page.getByText(/today/i).first()).toBeVisible();
  await expect(page.getByRole('tab', { name: /reader/i })).toBeVisible();
  await expect(page.getByRole('tab', { name: /plan/i })).toBeVisible();
  await expect(page.getByRole('tab', { name: /settings/i })).toBeVisible();
});


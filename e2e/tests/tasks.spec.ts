import { test, expect } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.goto('/')
})

test('shows login gate for GAME ØVER! Red Team Fortress', async ({ page }) => {
  await expect(page.getByText(/GAME ØVER! Red Team Fortress/i)).toBeVisible()
  await expect(page.getByRole('button', { name: /enter fortress/i })).toBeVisible()
})

test('logs in and shows attack modules', async ({ page }) => {
  await page.getByPlaceholder(/operator id/i).fill('SpamKat2')
  await page.getByPlaceholder(/••••/).fill('Ev1lSchm33')
  await page.getByRole('button', { name: /enter fortress/i }).click()
  await expect(page.getByText(/ATTACK MODULES/i)).toBeVisible()
})

test('unlocks batcave vault for Gam3.0n', async ({ page }) => {
  await page.getByPlaceholder(/operator id/i).fill('Gam3.0n')
  await page.getByPlaceholder(/••••/).fill('Dig1tal.Ra1n99')
  await page.getByRole('button', { name: /enter fortress/i }).click()
  await page.getByRole('button', { name: /^Vault$/i }).click()
  await page.getByPlaceholder(/XX-XX-XR/i).fill('B1-66-3R')
  await page.getByRole('button', { name: /open batcave/i }).click()
  await expect(page.getByText(/OFFLINE AIR CHAMBER/i)).toBeVisible()
})

import { test, expect } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.goto('/')
})

test('shows the attack modules home screen', async ({ page }) => {
  await expect(page.getByText(/ATTACK MODULES/i)).toBeVisible()
  await expect(page.getByText(/GÅMÊ-ØVĒR Cyber Solutions/i)).toBeVisible()
  await expect(page.getByRole('button', { name: /AI Vuln Scanner/i })).toBeVisible()
})

test('navigates to scanner tab', async ({ page }) => {
  await page.getByRole('button', { name: /^Scanner$/i }).click()
  await expect(page.getByText(/AI VULNERABILITY SCANNER/i)).toBeVisible()
})

test('opens NetHunter bridge from home', async ({ page }) => {
  await page.getByRole('button', { name: /NetHunter Suite/i }).click()
  await expect(page.getByText(/Kali NetHunter Suite/i)).toBeVisible()
  await expect(page.getByText(/msfconsole/i)).toBeVisible()
})

test('shows captures sample data', async ({ page }) => {
  await page.getByRole('button', { name: /^Captures$/i }).click()
  await expect(page.getByText(/CREDENTIAL CAPTURE/i)).toBeVisible()
  await expect(page.getByText('192.168.4.12')).toBeVisible()
})

import { test, expect } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  // Playwright gives each test a fresh browser context (empty localStorage),
  // so the persistence test's reload keeps its own data intact.
  await page.goto('/')
})

test('shows the empty state on first load', async ({ page }) => {
  await expect(page.getByRole('heading', { name: 'My Tasks' })).toBeVisible()
  await expect(page.getByText(/add your first task/i)).toBeVisible()
})

test('adds a task and updates the remaining counter', async ({ page }) => {
  await page.getByRole('textbox', { name: /new task/i }).fill('Buy milk')
  await page.getByRole('button', { name: /add/i }).click()

  await expect(page.getByText('Buy milk')).toBeVisible()
  await expect(page.getByText(/1 of 1 remaining/i)).toBeVisible()
})

test('toggles a task done and back', async ({ page }) => {
  await page.getByRole('textbox', { name: /new task/i }).fill('Write tests')
  await page.getByRole('button', { name: /add/i }).click()

  const checkbox = page.getByRole('checkbox')
  await checkbox.check()
  await expect(page.getByText(/0 of 1 remaining/i)).toBeVisible()

  await checkbox.uncheck()
  await expect(page.getByText(/1 of 1 remaining/i)).toBeVisible()
})

test('deletes a task', async ({ page }) => {
  await page.getByRole('textbox', { name: /new task/i }).fill('Temporary')
  await page.getByRole('button', { name: /add/i }).click()
  await expect(page.getByText('Temporary')).toBeVisible()

  await page.getByRole('button', { name: /delete temporary/i }).click()
  await expect(page.getByText('Temporary')).toHaveCount(0)
})

test('persists tasks across a page reload', async ({ page }) => {
  await page.getByRole('textbox', { name: /new task/i }).fill('Persist me')
  await page.getByRole('button', { name: /add/i }).click()
  await expect(page.getByText('Persist me')).toBeVisible()

  await page.reload()
  await expect(page.getByText('Persist me')).toBeVisible()
  await expect(page.getByText(/1 of 1 remaining/i)).toBeVisible()
})

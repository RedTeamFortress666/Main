import { test, expect } from '@playwright/test'

test('round-trips a sample PQC bundle through sequenced QR frames', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: 'QR Transfer' }).click()
  await expect(page.getByRole('heading', { name: 'QR Transfer' })).toBeVisible()

  await page.getByRole('button', { name: /load sample pqc bundle/i }).click()
  await expect(page.getByText(/4493 bytes ready/i)).toBeVisible()
  await expect(page.getByTestId('qr-total-label')).toHaveTextContent('9')

  await page.getByRole('radio', { name: /manual next frame/i }).check()
  await expect(page.getByRole('button', { name: /next frame/i })).toBeEnabled()
  await page.getByRole('button', { name: /next frame/i }).click()
  await expect(page.getByTestId('qr-frame-label')).toContainText('2 /')

  await page.getByTestId('scan-all-frames').click()
  await expect(page.getByTestId('scan-result')).toContainText(/hash verified/i)
  await expect(page.getByTestId('scan-result')).toContainText(/4493/)
})

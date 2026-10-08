import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it } from 'vitest'
import App from './App'

async function loginAs(
  user: ReturnType<typeof userEvent.setup>,
  username: string,
  password: string,
) {
  await user.type(screen.getByPlaceholderText(/operator id/i), username)
  await user.type(screen.getByPlaceholderText(/••••/), password)
  await user.click(screen.getByRole('button', { name: /enter fortress/i }))
}

describe('GAME ØVER! Red Team Fortress', () => {
  beforeEach(() => {
    sessionStorage.clear()
  })

  it('requires login before showing attack modules', () => {
    render(<App />)
    expect(screen.getByText(/GAME ØVER! Red Team Fortress/i)).toBeInTheDocument()
    expect(screen.queryByText(/ATTACK MODULES/i)).not.toBeInTheDocument()
  })

  it('logs in SpamKat2 and shows the suite', async () => {
    const user = userEvent.setup()
    render(<App />)
    await loginAs(user, 'SpamKat2', 'Ev1lSchm33')
    expect(await screen.findByText(/ATTACK MODULES/i)).toBeInTheDocument()
    expect(screen.getByText('SpamKat2')).toBeInTheDocument()
  })

  it('unlocks the Batcave vault with W1-66-3R for SpamKat2', async () => {
    const user = userEvent.setup()
    render(<App />)
    await loginAs(user, 'SpamKat2', 'Ev1lSchm33')
    await user.click(screen.getByRole('button', { name: /^Vault$/i }))
    await user.type(screen.getByPlaceholderText(/XX-XX-XR/i), 'W1-66-3R')
    await user.click(screen.getByRole('button', { name: /open batcave/i }))
    expect(await screen.findByText(/OFFLINE AIR CHAMBER/i)).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /enter air console/i }))
    expect(await screen.findByText(/OFFLINE AIR/i)).toBeInTheDocument()
  })

  it('unlocks vault with B1-66-3R for Gam3.0n', async () => {
    const user = userEvent.setup()
    render(<App />)
    await loginAs(user, 'Gam3.0n', 'Dig1tal.Ra1n99')
    await user.click(screen.getByRole('button', { name: /^Vault$/i }))
    await user.type(screen.getByPlaceholderText(/XX-XX-XR/i), 'B1-66-3R')
    await user.click(screen.getByRole('button', { name: /open batcave/i }))
    expect(await screen.findByText(/Clearance granted · Gam3\.0n/i)).toBeInTheDocument()
  })

  it('navigates to scanner after login', async () => {
    const user = userEvent.setup()
    render(<App />)
    await loginAs(user, 'Gam3.0n', 'Dig1tal.Ra1n99')
    await user.click(screen.getByRole('button', { name: /^Scanner$/i }))
    expect(screen.getByText(/AI VULNERABILITY SCANNER/i)).toBeInTheDocument()
  })

  it('selects ESP32 attack device on WiFi tab', async () => {
    const user = userEvent.setup()
    render(<App />)
    await loginAs(user, 'SpamKat2', 'Ev1lSchm33')
    await user.click(screen.getByRole('button', { name: /^WiFi$/i }))
    await user.click(screen.getByRole('button', { name: /Attack device/i }))
    const menu = screen.getByRole('listbox')
    await user.click(within(menu).getByRole('button', { name: /ESP32-Bluetooth/i }))
    expect(
      screen.getByRole('button', { name: /Attack device · ESP32-Bluetooth/i }),
    ).toBeInTheDocument()
  })
})

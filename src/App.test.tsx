import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import App from './App'

describe('GÅMÊ-ØVĒR Pentest Suite', () => {
  it('renders the home attack modules', () => {
    render(<App />)
    expect(screen.getByText(/ATTACK MODULES/i)).toBeInTheDocument()
    expect(screen.getByText(/GÅMÊ-ØVĒR Cyber Solutions/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /AI Vuln Scanner/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /NetHunter Suite/i })).toBeInTheDocument()
  })

  it('navigates to scanner and queues a simulated recon', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(screen.getByRole('button', { name: /^Scanner$/i }))
    expect(screen.getByText(/AI VULNERABILITY SCANNER/i)).toBeInTheDocument()

    await user.type(
      screen.getByPlaceholderText(/https:\/\/target\.com/i),
      'lab.customer.local',
    )
    await user.click(screen.getByRole('button', { name: /LAUNCH FULL RECON/i }))
    expect(await screen.findByText(/Queued FULL recon/i)).toBeInTheDocument()
  })

  it('opens NetHunter device bridge from home', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(screen.getByRole('button', { name: /NetHunter Suite/i }))
    expect(screen.getByText(/Kali NetHunter Suite/i)).toBeInTheDocument()
    expect(screen.getByText(/msfconsole/i)).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /PING NETHUNTER/i }))
    expect(await screen.findByText(/NetHunter heartbeat OK/i)).toBeInTheDocument()
  })

  it('filters captures and shows sample credential cards', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(screen.getByRole('button', { name: /^Captures$/i }))
    expect(screen.getByText(/CREDENTIAL CAPTURE/i)).toBeInTheDocument()
    expect(screen.getByText('192.168.4.12')).toBeInTheDocument()

    const filters = screen.getByRole('group', { name: /capture filters/i })
    await user.click(within(filters).getByRole('button', { name: /^WIFI$/ }))
    expect(screen.getAllByText('CorpWifi_5G').length).toBeGreaterThan(0)
    expect(screen.queryByText('192.168.4.12')).not.toBeInTheDocument()
    expect(screen.queryByText('john.doe@gmail.com')).not.toBeInTheDocument()
  })

  it('selects ESP32 attack device on WiFi tab', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(screen.getByRole('button', { name: /^WiFi$/i }))
    await user.click(screen.getByRole('button', { name: /Attack device/i }))
    const menu = screen.getByRole('listbox')
    await user.click(within(menu).getByRole('button', { name: /ESP32-Bluetooth/i }))
    expect(
      screen.getByRole('button', { name: /Attack device · ESP32-Bluetooth/i }),
    ).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /^EXECUTE$/i }))
    expect(
      await screen.findByText(/Queued auto-scan on ESP32-Bluetooth/i),
    ).toBeInTheDocument()
  })
})

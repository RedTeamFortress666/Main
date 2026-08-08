import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import App from './App'

describe('POLYBIUS PRESS', () => {
  it('renders the brand hero', () => {
    render(<App />)
    expect(screen.getByText('POLYBIUS PRESS')).toBeInTheDocument()
    expect(
      screen.getByRole('heading', { name: /stage sd cards before you flash/i }),
    ).toBeInTheDocument()
  })

  it('selects LineageOS and shows dual-boot modes', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(
      screen.getByRole('button', { name: /r36s · lineageos \(andr36oid\)/i }),
    )

    expect(
      screen.getByRole('radio', { name: /dual card \(os \+ roms\)/i }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('radio', { name: /dual os swap/i }),
    ).toBeInTheDocument()
    expect(screen.getByText(/andr36oid release uploads/i)).toBeInTheDocument()
  })

  it('updates the stage plan when boot mode changes', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(
      screen.getByRole('button', { name: /r36s · lineageos \(andr36oid\)/i }),
    )
    await user.click(
      screen.getByRole('radio', { name: /dual os swap/i }),
    )

    expect(screen.getByRole('heading', { level: 2, name: /dual os swap/i })).toBeInTheDocument()
  })
})

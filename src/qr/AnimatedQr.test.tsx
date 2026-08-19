import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import { AnimatedQr } from './AnimatedQr'
import { encodeFrames } from './protocol'

describe('AnimatedQr', () => {
  it('shows frame numbering, total count, and content hash', async () => {
    const data = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
    const frames = await encodeFrames(data, { chunkSize: 4 })
    render(<AnimatedQr data={data} mode="manual" chunkSize={4} />)

    await waitFor(() => {
      expect(screen.getByTestId('qr-frame-label')).toHaveTextContent(`1 / ${frames.length}`)
    })
    expect(screen.getByTestId('qr-total-label')).toHaveTextContent(String(frames.length))
    expect(screen.getByTestId('qr-hash-label').textContent).toMatch(/[0-9A-F]/)
    expect(screen.getByRole('img', { name: /qr frame 1 of/i })).toBeInTheDocument()
  })

  it('advances frames in manual mode', async () => {
    const user = userEvent.setup()
    const data = new Uint8Array(20).map((_, i) => i)
    render(<AnimatedQr data={data} mode="manual" chunkSize={5} />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /next frame/i })).toBeEnabled()
    })

    await user.click(screen.getByRole('button', { name: /next frame/i }))
    expect(screen.getByTestId('qr-frame-label')).toHaveTextContent('2 /')
  })

  it('animates in continuous mode', async () => {
    const data = new Uint8Array(18).map((_, i) => i + 1)
    render(<AnimatedQr data={data} mode="continuous" chunkSize={6} intervalMs={80} />)

    await waitFor(() => {
      expect(screen.getByTestId('qr-frame-label')).toHaveTextContent('1 / 3')
    })
    await waitFor(
      () => {
        expect(screen.getByTestId('qr-frame-label')).toHaveTextContent('2 / 3')
      },
      { timeout: 1500 },
    )
  })
})

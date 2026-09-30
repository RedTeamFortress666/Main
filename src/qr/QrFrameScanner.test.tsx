import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { encodeFrames } from './protocol'
import { QrFrameScanner } from './QrFrameScanner'

describe('QrFrameScanner', () => {
  it('ingests pasted frames and fires onComplete with the rebuilt bytes', async () => {
    const user = userEvent.setup()
    const payload = new TextEncoder().encode('scan-me-from-paste-frames')
    const frames = await encodeFrames(payload, { chunkSize: 8 })
    const onComplete = vi.fn()

    render(<QrFrameScanner onComplete={onComplete} />)
    const input = screen.getByLabelText(/paste qr frame text/i)

    for (const frame of frames) {
      fireEvent.change(input, { target: { value: frame } })
      await user.click(screen.getByRole('button', { name: /ingest/i }))
    }

    await waitFor(() => expect(onComplete).toHaveBeenCalledTimes(1))
    const [data, meta] = onComplete.mock.calls[0] as [Uint8Array, { hash: string; frameCount: number }]
    expect(Array.from(data)).toEqual(Array.from(payload))
    expect(meta.frameCount).toBe(frames.length)
    expect(screen.getByTestId('scan-collected')).toHaveTextContent(
      `${frames.length} / ${frames.length}`,
    )
  })

  it('collects frames from a scan adapter', async () => {
    const user = userEvent.setup()
    const payload = new Uint8Array([42, 43, 44, 45, 46, 47, 48, 49])
    const frames = await encodeFrames(payload, { chunkSize: 3 })
    let push: (text: string) => void = () => {}
    let started = false
    const onComplete = vi.fn()

    render(
      <QrFrameScanner
        onComplete={onComplete}
        scanAdapter={{
          start: async (_id, onDecode) => {
            push = onDecode
            started = true
          },
          stop: async () => undefined,
        }}
      />,
    )

    await user.click(screen.getByRole('button', { name: /start camera/i }))
    await waitFor(() => expect(started).toBe(true))
    for (const frame of frames) push(frame)

    await waitFor(() => expect(onComplete).toHaveBeenCalledTimes(1))
    expect(Array.from(onComplete.mock.calls[0][0] as Uint8Array)).toEqual(Array.from(payload))
  })
})

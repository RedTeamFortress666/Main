import { describe, expect, it } from 'vitest'
import { FrameCollector } from './FrameCollector'
import { encodeFrames, parseFrame, serializeFrame } from './protocol'

describe('FrameCollector', () => {
  it('collects out-of-order frames and completes with the original bytes', async () => {
    const payload = new TextEncoder().encode('collector-roundtrip-payload!!')
    const frames = await encodeFrames(payload, { chunkSize: 7 })
    const collector = new FrameCollector()

    const reversed = [...frames].reverse()
    let last = await collector.ingest(reversed[0])
    expect(last.status).toBe('progress')

    last = await collector.ingest(reversed[0])
    expect(last.status).toBe('ignored')

    for (const frame of reversed.slice(1)) {
      last = await collector.ingest(frame)
    }

    expect(last.status).toBe('complete')
    expect(Array.from(last.data!)).toEqual(Array.from(payload))
    expect(last.missing).toEqual([])
    expect(last.collected).toBe(frames.length)
  })

  it('starts a new transfer when the content hash changes', async () => {
    const first = await encodeFrames(new Uint8Array([1, 2, 3, 4, 5, 6]), { chunkSize: 3 })
    const second = await encodeFrames(new Uint8Array([9, 8, 7, 6, 5, 4]), { chunkSize: 3 })
    const collector = new FrameCollector()

    await collector.ingest(first[0])
    const result = await collector.ingest(second[0])
    expect(result.reset).toBe(true)
    expect(result.hash).toBe(parseFrame(second[0])?.hash)
    expect(result.collected).toBe(1)
  })

  it('reports integrity_error when a collected set is complete but corrupt', async () => {
    const payload = new Uint8Array([10, 20, 30, 40, 50, 60])
    const frames = await encodeFrames(payload, { chunkSize: 3 })
    const parsed = frames.map((text) => parseFrame(text)!)
    parsed[0] = { ...parsed[0], chunk: new Uint8Array([0, 0, 0]) }
    const collector = new FrameCollector()
    await collector.ingest(serializeFrame(parsed[0]))
    const last = await collector.ingest(serializeFrame(parsed[1]))
    expect(last.status).toBe('integrity_error')
  })
})

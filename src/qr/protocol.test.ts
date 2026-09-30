import { describe, expect, it } from 'vitest'
import { sha256Hex } from './hash'
import {
  assembleFrames,
  encodeFrames,
  parseFrame,
  serializeFrame,
  PROTOCOL_PREFIX,
} from './protocol'
import { buildSamplePqcBundle, parseSampleHeader } from './samplePayload'

describe('multi-frame QR protocol', () => {
  it('encodes a disguise URL with frame index, total, and content hash', async () => {
    const data = new TextEncoder().encode('hello sequenced qr')
    const frames = await encodeFrames(data, { chunkSize: 8 })
    expect(frames.length).toBeGreaterThan(1)
    expect(frames[0].startsWith(PROTOCOL_PREFIX)).toBe(true)

    const parsed = parseFrame(frames[0])
    expect(parsed).not.toBeNull()
    expect(parsed?.index).toBe(1)
    expect(parsed?.total).toBe(frames.length)
    expect(parsed?.hash).toBe(await sha256Hex(data))
    expect(parsed?.byteLength).toBe(data.length)
  })

  it('reassembles shuffled frames of a Kyber + Dilithium sized bundle', async () => {
    const data = buildSamplePqcBundle((buffer) => {
      for (let i = 0; i < buffer.length; i++) buffer[i] = (i * 17) & 255
      return buffer
    })
    expect(data.length).toBe(16 + 1184 + 3293)
    expect(parseSampleHeader(data)?.magic).toBe('PQC1')

    const encoded = await encodeFrames(data, { chunkSize: 400 })
    expect(encoded.length).toBeGreaterThan(5)

    const shuffled = encoded
      .map((text, i) => ({ text, i }))
      .sort((a, b) => ((a.i * 7) % 13) - ((b.i * 7) % 13))
      .map((entry) => parseFrame(entry.text)!)

    const restored = await assembleFrames(shuffled)
    expect(Array.from(restored)).toEqual(Array.from(data))
    expect(await sha256Hex(restored)).toBe(shuffled[0].hash)
  })

  it('rejects a corrupted chunk via the content hash', async () => {
    const data = new Uint8Array([9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    const frames = await encodeFrames(data, { chunkSize: 4 })
    const parsed = frames.map((text) => parseFrame(text)!)
    parsed[1] = {
      ...parsed[1],
      chunk: new Uint8Array(parsed[1].chunk.map((byte) => byte ^ 0xff)),
    }
    const tampered = parsed.map((frame) => serializeFrame(frame))
    const mixed = tampered.map((text) => parseFrame(text)!)
    await expect(assembleFrames(mixed)).rejects.toThrow(/hash mismatch/i)
  })

  it('returns null for unrelated QR text', () => {
    expect(parseFrame('https://example.com')).toBeNull()
    expect(parseFrame('not a qr frame')).toBeNull()
  })
})

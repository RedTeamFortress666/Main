import { describe, expect, it } from 'vitest'
import { decodeBase32, encodeBase32 } from './base32'

describe('base32', () => {
  it('round-trips empty, short, and longer payloads', () => {
    const cases = [
      new Uint8Array(),
      new Uint8Array([0]),
      new Uint8Array([255]),
      new Uint8Array([1, 2, 3, 4, 5]),
      Uint8Array.from({ length: 64 }, (_, i) => (i * 3) & 255),
    ]
    for (const input of cases) {
      expect(Array.from(decodeBase32(encodeBase32(input)))).toEqual(Array.from(input))
    }
  })

  it('rejects invalid characters', () => {
    expect(() => decodeBase32('ABC1')).toThrow(/Invalid base32/)
  })
})

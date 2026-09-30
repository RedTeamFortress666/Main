/** RFC 4648 Base32 (no padding) so payloads stay in QR alphanumeric mode. */
const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

const DECODE = new Map<string, number>(
  [...ALPHABET].map((char, index) => [char, index]),
)

export function encodeBase32(data: Uint8Array): string {
  if (data.length === 0) return ''

  let bits = 0
  let value = 0
  let output = ''

  for (const byte of data) {
    value = (value << 8) | byte
    bits += 8
    while (bits >= 5) {
      output += ALPHABET[(value >>> (bits - 5)) & 31]
      bits -= 5
    }
  }

  if (bits > 0) {
    output += ALPHABET[(value << (5 - bits)) & 31]
  }

  return output
}

export function decodeBase32(input: string): Uint8Array {
  const cleaned = input.toUpperCase().replace(/=+$/g, '')
  if (cleaned.length === 0) return new Uint8Array(0)

  let bits = 0
  let value = 0
  const bytes: number[] = []

  for (const char of cleaned) {
    const index = DECODE.get(char)
    if (index === undefined) {
      throw new Error(`Invalid base32 character: ${char}`)
    }
    value = (value << 5) | index
    bits += 5
    if (bits >= 8) {
      bytes.push((value >>> (bits - 8)) & 255)
      bits -= 8
    }
  }

  return new Uint8Array(bytes)
}

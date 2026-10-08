export function bytesToHex(data: Uint8Array): string {
  return Array.from(data, (byte) => byte.toString(16).padStart(2, '0')).join('')
}

export function hexToBytes(hex: string): Uint8Array {
  const cleaned = hex.replace(/\s+/g, '')
  if (cleaned.length % 2 !== 0 || !/^[0-9a-fA-F]*$/.test(cleaned)) {
    throw new Error('Expected even-length hex')
  }
  const out = new Uint8Array(cleaned.length / 2)
  for (let i = 0; i < out.length; i++) {
    out[i] = Number.parseInt(cleaned.slice(i * 2, i * 2 + 2), 16)
  }
  return out
}

export function bytesToBase64(data: Uint8Array): string {
  return Buffer.from(data).toString('base64')
}

export function base64ToBytes(value: string): Uint8Array {
  return new Uint8Array(Buffer.from(value, 'base64'))
}

export function decodeKey(value: string): Uint8Array {
  const trimmed = value.trim()
  if (/^[0-9a-fA-F]+$/.test(trimmed) && trimmed.length % 2 === 0) {
    return hexToBytes(trimmed)
  }
  return base64ToBytes(trimmed)
}

export function canonicalJson(value: unknown): string {
  return JSON.stringify(value)
}

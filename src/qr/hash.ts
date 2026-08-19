export function bytesToHex(data: Uint8Array): string {
  let hex = ''
  for (const byte of data) {
    hex += byte.toString(16).padStart(2, '0')
  }
  return hex.toUpperCase()
}

export function hexToBytes(hex: string): Uint8Array {
  const cleaned = hex.replace(/\s+/g, '')
  if (cleaned.length % 2 !== 0) {
    throw new Error('Hex string must have an even length')
  }
  if (!/^[0-9a-fA-F]*$/.test(cleaned)) {
    throw new Error('Hex string contains non-hex characters')
  }
  const out = new Uint8Array(cleaned.length / 2)
  for (let i = 0; i < out.length; i++) {
    out[i] = Number.parseInt(cleaned.slice(i * 2, i * 2 + 2), 16)
  }
  return out
}

export async function sha256Bytes(data: Uint8Array): Promise<Uint8Array> {
  const copy = new Uint8Array(data.byteLength)
  copy.set(data)
  const digest = await crypto.subtle.digest('SHA-256', copy)
  return new Uint8Array(digest)
}

export async function sha256Hex(data: Uint8Array): Promise<string> {
  return bytesToHex(await sha256Bytes(data))
}

export function formatHashPreview(hex: string, groups = 4): string {
  const compact = hex.replace(/\s+/g, '').toUpperCase()
  if (compact.length <= 16) return compact
  const head = compact.slice(0, groups * 4)
  const tail = compact.slice(-4)
  const grouped = head.match(/.{1,4}/g)?.join(' ') ?? head
  return `${grouped} … ${tail}`
}

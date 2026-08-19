/** Kyber-768 public key size (bytes). */
export const KYBER768_PUBLIC_KEY_BYTES = 1184
/** ML-DSA-65 / Dilithium3 signature size (bytes). */
export const DILITHIUM3_SIGNATURE_BYTES = 3293
export const SAMPLE_HEADER_BYTES = 16
export const SAMPLE_MAGIC = 'PQC1'

/**
 * Builds a dummy post-quantum bundle: 16-byte header + Kyber-768 PK + Dilithium3 signature.
 * Random bytes stand in for real key material so the QR layer can be exercised without a PQC lib.
 */
export function buildSamplePqcBundle(
  fill: (buffer: Uint8Array) => Uint8Array = (buffer) => crypto.getRandomValues(buffer),
): Uint8Array {
  const header = new Uint8Array(SAMPLE_HEADER_BYTES)
  new TextEncoder().encodeInto(SAMPLE_MAGIC, header)
  const view = new DataView(header.buffer)
  view.setUint16(4, KYBER768_PUBLIC_KEY_BYTES, false)
  view.setUint16(6, DILITHIUM3_SIGNATURE_BYTES, false)

  const kyber = fill(new Uint8Array(KYBER768_PUBLIC_KEY_BYTES))
  const signature = fill(new Uint8Array(DILITHIUM3_SIGNATURE_BYTES))

  const out = new Uint8Array(
    SAMPLE_HEADER_BYTES + KYBER768_PUBLIC_KEY_BYTES + DILITHIUM3_SIGNATURE_BYTES,
  )
  out.set(header, 0)
  out.set(kyber, SAMPLE_HEADER_BYTES)
  out.set(signature, SAMPLE_HEADER_BYTES + KYBER768_PUBLIC_KEY_BYTES)
  return out
}

export function parseSampleHeader(data: Uint8Array): {
  magic: string
  kyberLen: number
  signatureLen: number
} | null {
  if (data.length < SAMPLE_HEADER_BYTES) return null
  const magic = new TextDecoder().decode(data.subarray(0, 4))
  if (magic !== SAMPLE_MAGIC) return null
  const view = new DataView(data.buffer, data.byteOffset, data.byteLength)
  return {
    magic,
    kyberLen: view.getUint16(4, false),
    signatureLen: view.getUint16(6, false),
  }
}

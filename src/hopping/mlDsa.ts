import { ml_dsa65 } from '@noble/post-quantum/ml-dsa.js'
import { bytesToBase64, base64ToBytes, canonicalJson } from './bytes'
import { SIGN_CONTEXT, type HopPayload, type SignedHopEnvelope } from './types'

export function generateMlDsaKeys(seed?: Uint8Array): {
  publicKey: Uint8Array
  secretKey: Uint8Array
} {
  return ml_dsa65.keygen(seed)
}

export function signHopPayload(
  payload: HopPayload,
  secretKey: Uint8Array,
): SignedHopEnvelope {
  const message = new TextEncoder().encode(canonicalJson(payload))
  const signature = ml_dsa65.sign(message, secretKey, {
    context: SIGN_CONTEXT,
    extraEntropy: false,
  })
  return {
    payload,
    algorithm: 'ML-DSA-65',
    signature: bytesToBase64(signature),
  }
}

export function verifyHopEnvelope(
  envelope: SignedHopEnvelope,
  publicKey: Uint8Array,
  now: Date = new Date(),
): HopPayload {
  if (envelope.algorithm !== 'ML-DSA-65') {
    throw new Error(`Unsupported signature algorithm: ${envelope.algorithm}`)
  }
  const message = new TextEncoder().encode(canonicalJson(envelope.payload))
  const ok = ml_dsa65.verify(base64ToBytes(envelope.signature), message, publicKey, {
    context: SIGN_CONTEXT,
  })
  if (!ok) {
    throw new Error('ML-DSA signature verification failed')
  }
  const expires = Date.parse(envelope.payload.expiresAt)
  if (Number.isNaN(expires) || expires <= now.getTime()) {
    throw new Error('Signed hop payload has expired')
  }
  return envelope.payload
}

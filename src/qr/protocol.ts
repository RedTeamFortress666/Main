import { decodeBase32, encodeBase32 } from './base32'
import { sha256Hex } from './hash'

/**
 * Multi-frame QR wire format.
 *
 * Each frame is an ordinary high-contrast QR whose *text* looks like a
 * mundane HTTPS deep-link. That URL wrapper is the only “steganographic”
 * layer — obfuscation by disguise, not pixel-level hiding. The modules
 * themselves stay black-on-white.
 *
 * HTTPS://XFR.APP/V1/{sha256}/{byteLen}/{frame}/{total}/{base32}
 */
export const PROTOCOL_PREFIX = 'HTTPS://XFR.APP/V1/'
export const PROTOCOL_VERSION = 1
export const MAX_FRAMES = 9999
export const DEFAULT_CHUNK_SIZE = 512

const FRAME_PATTERN =
  /^HTTPS:\/\/XFR\.APP\/V1\/([0-9A-F]{64})\/([0-9A-F]{8})\/(\d{4})\/(\d{4})\/([A-Z2-7]*)$/

export interface QrFrame {
  hash: string
  byteLength: number
  /** 1-based frame number */
  index: number
  total: number
  chunk: Uint8Array
}

export interface EncodeFramesOptions {
  /** Raw bytes per frame (last frame may be shorter). */
  chunkSize?: number
}

function pad4(value: number): string {
  return value.toString(10).padStart(4, '0')
}

function pad8Hex(value: number): string {
  return value.toString(16).toUpperCase().padStart(8, '0')
}

export function serializeFrame(frame: QrFrame): string {
  return (
    PROTOCOL_PREFIX +
    `${frame.hash}/${pad8Hex(frame.byteLength)}/${pad4(frame.index)}/${pad4(frame.total)}/${encodeBase32(frame.chunk)}`
  )
}

export function parseFrame(text: string): QrFrame | null {
  const trimmed = text.trim().toUpperCase()
  const match = FRAME_PATTERN.exec(trimmed)
  if (!match) return null

  const hash = match[1]
  const byteLength = Number.parseInt(match[2], 16)
  const index = Number.parseInt(match[3], 10)
  const total = Number.parseInt(match[4], 10)

  if (index < 1 || total < 1 || index > total || total > MAX_FRAMES) {
    return null
  }

  try {
    return {
      hash,
      byteLength,
      index,
      total,
      chunk: decodeBase32(match[5]),
    }
  } catch {
    return null
  }
}

export async function encodeFrames(
  data: Uint8Array,
  options: EncodeFramesOptions = {},
): Promise<string[]> {
  const chunkSize = options.chunkSize ?? DEFAULT_CHUNK_SIZE
  if (chunkSize < 1) {
    throw new Error('chunkSize must be at least 1')
  }

  const hash = await sha256Hex(data)
  const total = Math.max(1, Math.ceil(data.length / chunkSize))
  if (total > MAX_FRAMES) {
    throw new Error(
      `Payload needs ${total} frames (max ${MAX_FRAMES}). Increase chunkSize.`,
    )
  }

  const frames: string[] = []
  for (let i = 0; i < total; i++) {
    const start = i * chunkSize
    const chunk = data.subarray(start, start + chunkSize)
    frames.push(
      serializeFrame({
        hash,
        byteLength: data.length,
        index: i + 1,
        total,
        chunk,
      }),
    )
  }
  return frames
}

export async function assembleFrames(frames: QrFrame[]): Promise<Uint8Array> {
  if (frames.length === 0) {
    throw new Error('No frames to assemble')
  }

  const { hash, byteLength, total } = frames[0]
  if (frames.length !== total) {
    throw new Error(`Expected ${total} frames, got ${frames.length}`)
  }

  const ordered = new Array<QrFrame | undefined>(total)
  for (const frame of frames) {
    if (frame.hash !== hash) {
      throw new Error('Frame set contains mixed content hashes')
    }
    if (frame.byteLength !== byteLength || frame.total !== total) {
      throw new Error('Frame set contains inconsistent headers')
    }
    if (frame.index < 1 || frame.index > total) {
      throw new Error(`Frame index ${frame.index} is out of range`)
    }
    ordered[frame.index - 1] = frame
  }

  const parts: Uint8Array[] = []
  let assembled = 0
  for (let i = 0; i < total; i++) {
    const frame = ordered[i]
    if (!frame) {
      throw new Error(`Missing frame ${i + 1} of ${total}`)
    }
    parts.push(frame.chunk)
    assembled += frame.chunk.length
  }

  if (assembled !== byteLength) {
    throw new Error(
      `Reassembled length ${assembled} does not match advertised ${byteLength}`,
    )
  }

  const out = new Uint8Array(byteLength)
  let offset = 0
  for (const part of parts) {
    out.set(part, offset)
    offset += part.length
  }

  const actualHash = await sha256Hex(out)
  if (actualHash !== hash) {
    throw new Error('Content hash mismatch after reassembly')
  }

  return out
}

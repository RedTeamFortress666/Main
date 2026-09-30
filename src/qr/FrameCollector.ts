import { assembleFrames, parseFrame, type QrFrame } from './protocol'

export type CollectStatus =
  | 'invalid'
  | 'ignored'
  | 'progress'
  | 'complete'
  | 'integrity_error'

export interface CollectResult {
  status: CollectStatus
  collected: number
  total: number | null
  hash: string | null
  missing: number[]
  data?: Uint8Array
  error?: string
  reset?: boolean
}

export class FrameCollector {
  private slots = new Map<number, QrFrame>()
  private hash: string | null = null
  private total: number | null = null
  private byteLength: number | null = null
  private completed = false

  reset(): void {
    this.slots.clear()
    this.hash = null
    this.total = null
    this.byteLength = null
    this.completed = false
  }

  snapshot(): Omit<CollectResult, 'status'> {
    return {
      collected: this.slots.size,
      total: this.total,
      hash: this.hash,
      missing: this.missingIndexes(),
    }
  }

  missingIndexes(): number[] {
    if (this.total === null) return []
    const missing: number[] = []
    for (let i = 1; i <= this.total; i++) {
      if (!this.slots.has(i)) missing.push(i)
    }
    return missing
  }

  async ingest(text: string): Promise<CollectResult> {
    const frame = parseFrame(text)
    if (!frame) {
      return { status: 'invalid', error: 'Not a sequenced QR frame', ...this.snapshot() }
    }

    let reset = false
    if (this.hash && frame.hash !== this.hash) {
      this.reset()
      reset = true
    }

    if (this.hash === null) {
      this.hash = frame.hash
      this.total = frame.total
      this.byteLength = frame.byteLength
    } else if (
      frame.total !== this.total ||
      frame.byteLength !== this.byteLength
    ) {
      return {
        status: 'invalid',
        error: 'Frame header does not match the current transfer',
        ...this.snapshot(),
      }
    }

    if (this.slots.has(frame.index)) {
      return { status: 'ignored', reset, ...this.snapshot() }
    }

    this.slots.set(frame.index, frame)

    if (this.total !== null && this.slots.size === this.total) {
      try {
        const data = await assembleFrames([...this.slots.values()])
        this.completed = true
        return {
          status: 'complete',
          collected: this.slots.size,
          total: this.total,
          hash: this.hash,
          missing: [],
          data,
          reset,
        }
      } catch (error) {
        return {
          status: 'integrity_error',
          error: error instanceof Error ? error.message : 'Integrity check failed',
          ...this.snapshot(),
          reset,
        }
      }
    }

    return { status: 'progress', reset, ...this.snapshot() }
  }

  get isComplete(): boolean {
    return this.completed
  }
}

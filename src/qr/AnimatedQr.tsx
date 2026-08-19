import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react'
import { formatHashPreview, sha256Hex } from './hash'
import { DEFAULT_CHUNK_SIZE, encodeFrames } from './protocol'
import { renderQrSvg, renderQrToCanvas } from './render'

export type QrPlaybackMode = 'continuous' | 'manual'

export interface AnimatedQrHandle {
  getCanvas: () => HTMLCanvasElement | null
  getCurrentPayload: () => string | null
  getFrames: () => string[]
  next: () => void
  prev: () => void
}

export interface AnimatedQrProps {
  data: Uint8Array
  mode?: QrPlaybackMode
  intervalMs?: number
  chunkSize?: number
  size?: number
  onFrameChange?: (index: number, total: number) => void
  onReady?: (frames: string[], hash: string) => void
  onError?: (message: string) => void
}

export const AnimatedQr = forwardRef<AnimatedQrHandle, AnimatedQrProps>(
  function AnimatedQr(
    {
      data,
      mode = 'continuous',
      intervalMs = 650,
      chunkSize = DEFAULT_CHUNK_SIZE,
      size = 280,
      onFrameChange,
      onReady,
      onError,
    },
    ref,
  ) {
    const canvasRef = useRef<HTMLCanvasElement>(null)
    const [frames, setFrames] = useState<string[]>([])
    const [hash, setHash] = useState('')
    const [index, setIndex] = useState(0)
    const [svg, setSvg] = useState<string | null>(null)
    const [paused, setPaused] = useState(false)
    const [encoding, setEncoding] = useState(false)

    const total = frames.length
    const payload = frames[index] ?? null

    const dataKey = useMemo(() => `${fingerprint(data)}:${chunkSize}`, [data, chunkSize])

    useEffect(() => {
      let cancelled = false
      setEncoding(true)
      setFrames([])
      setHash('')
      setIndex(0)
      Promise.all([encodeFrames(data, { chunkSize }), sha256Hex(data)])
        .then(([nextFrames, nextHash]) => {
          if (cancelled) return
          setFrames(nextFrames)
          setHash(nextHash)
          setIndex(0)
          onReady?.(nextFrames, nextHash)
        })
        .catch((error: unknown) => {
          if (cancelled) return
          setFrames([])
          setHash('')
          onError?.(error instanceof Error ? error.message : 'Failed to encode QR frames')
        })
        .finally(() => {
          if (!cancelled) setEncoding(false)
        })
      return () => {
        cancelled = true
      }
      // onReady/onError are caller-provided; dataKey captures data + chunkSize.
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [dataKey, chunkSize])

    const goTo = useCallback(
      (nextIndex: number) => {
        if (total === 0) return
        const wrapped = ((nextIndex % total) + total) % total
        setIndex(wrapped)
      },
      [total],
    )

    const next = useCallback(() => goTo(index + 1), [goTo, index])
    const prev = useCallback(() => goTo(index - 1), [goTo, index])

    useImperativeHandle(
      ref,
      () => ({
        getCanvas: () => canvasRef.current,
        getCurrentPayload: () => payload,
        getFrames: () => frames,
        next,
        prev,
      }),
      [frames, next, payload, prev],
    )

    useEffect(() => {
      if (!payload) {
        setSvg(null)
        return
      }
      const canvas = canvasRef.current
      const drew = canvas ? renderQrToCanvas(canvas, payload, { cssSize: size }) : false
      if (!drew) {
        setSvg(renderQrSvg(payload, { cssSize: size }))
      } else {
        setSvg(null)
      }
    }, [payload, size])

    useEffect(() => {
      if (total > 0) onFrameChange?.(index + 1, total)
    }, [index, total, onFrameChange])

    useEffect(() => {
      if (mode !== 'continuous' || paused || total < 2) return
      const timer = window.setInterval(() => {
        setIndex((current) => (current + 1) % total)
      }, Math.max(120, intervalMs))
      return () => window.clearInterval(timer)
    }, [mode, paused, intervalMs, total])

    const frameLabel = total === 0 ? '—' : `${index + 1} / ${total}`
    const hashLabel = hash ? formatHashPreview(hash) : 'encoding…'

    return (
      <div className="qr-encoder">
        <div className="qr-stage">
          <canvas
            ref={canvasRef}
            className={svg ? 'qr-canvas qr-canvas--hidden' : 'qr-canvas'}
            role="img"
            aria-label={
              total === 0
                ? 'QR code not ready'
                : `QR frame ${index + 1} of ${total}, content hash ${hash}`
            }
          />
          {svg && (
            <div
              className="qr-svg"
              data-testid="qr-svg-fallback"
              dangerouslySetInnerHTML={{ __html: svg }}
            />
          )}
          {encoding && <p className="qr-stage__status">Encoding frames…</p>}
        </div>

        <dl className="qr-meta">
          <div>
            <dt>Frame</dt>
            <dd data-testid="qr-frame-label">{frameLabel}</dd>
          </div>
          <div>
            <dt>Total</dt>
            <dd data-testid="qr-total-label">{total || '—'}</dd>
          </div>
          <div className="qr-meta__hash">
            <dt>Content hash</dt>
            <dd data-testid="qr-hash-label" title={hash}>
              {hashLabel}
            </dd>
          </div>
        </dl>

        {payload && (
          <code className="qr-payload" data-testid="qr-current-payload" hidden>
            {payload}
          </code>
        )}

        <div className="qr-controls">
          {mode === 'manual' ? (
            <>
              <button type="button" onClick={prev} disabled={total < 2}>
                Previous frame
              </button>
              <button type="button" onClick={next} disabled={total < 2}>
                Next frame
              </button>
            </>
          ) : (
            <button type="button" onClick={() => setPaused((value) => !value)} disabled={total < 2}>
              {paused ? 'Resume animation' : 'Pause animation'}
            </button>
          )}
        </div>
      </div>
    )
  },
)

function fingerprint(data: Uint8Array): string {
  let hash = data.length
  for (let i = 0; i < data.length; i++) {
    hash = (Math.imul(hash, 31) + data[i]) | 0
  }
  return `${data.length}:${hash}`
}

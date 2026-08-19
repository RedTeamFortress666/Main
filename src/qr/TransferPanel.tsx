import { useCallback, useRef, useState } from 'react'
import { AnimatedQr, type AnimatedQrHandle, type QrPlaybackMode } from './AnimatedQr'
import { bytesToHex, hexToBytes, sha256Hex } from './hash'
import { QrFrameScanner, type QrFrameScannerHandle } from './QrFrameScanner'
import { decodeQrFromCanvas } from './render'
import { buildSamplePqcBundle, parseSampleHeader } from './samplePayload'

function bytesFromInput(raw: string): Uint8Array {
  const trimmed = raw.trim()
  if (!trimmed) return new Uint8Array()
  if (/^[0-9a-fA-F\s]+$/.test(trimmed) && trimmed.replace(/\s+/g, '').length % 2 === 0) {
    return hexToBytes(trimmed)
  }
  try {
    const binary = atob(trimmed)
    const out = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i)
    return out
  } catch {
    return new TextEncoder().encode(trimmed)
  }
}

function describeHeader(header: { kyberLen: number; signatureLen: number }): string {
  return `PQC1 header + Kyber pk (${header.kyberLen} B) + Dilithium sig (${header.signatureLen} B)`
}

export function TransferPanel() {
  const encoderRef = useRef<AnimatedQrHandle>(null)
  const scannerRef = useRef<QrFrameScannerHandle>(null)
  const [input, setInput] = useState('')
  const [payload, setPayload] = useState<Uint8Array>(() => new Uint8Array())
  const [mode, setMode] = useState<QrPlaybackMode>('continuous')
  const [intervalMs, setIntervalMs] = useState(650)
  const [result, setResult] = useState<{
    hex: string
    hash: string
    note: string
  } | null>(null)
  const [loopbackNote, setLoopbackNote] = useState<string | null>(null)

  const applyPayload = useCallback((data: Uint8Array, hex?: string) => {
    setPayload(data)
    setInput(hex ?? bytesToHex(data))
    setResult(null)
    setLoopbackNote(null)
    scannerRef.current?.reset()
  }, [])

  function loadSample() {
    applyPayload(buildSamplePqcBundle())
  }

  function encodeInput() {
    applyPayload(bytesFromInput(input), input)
  }

  const ingestDisplayedFrame = useCallback(async (): Promise<boolean> => {
    const encoder = encoderRef.current
    const scanner = scannerRef.current
    if (!encoder || !scanner) return false

    const canvas = encoder.getCanvas()
    const fromPixels = canvas ? decodeQrFromCanvas(canvas) : null
    const text = fromPixels ?? encoder.getCurrentPayload()
    if (!text) {
      setLoopbackNote('No frame is ready to scan.')
      return false
    }

    await scanner.ingest(text)
    setLoopbackNote(
      fromPixels
        ? 'Decoded the displayed QR via jsQR.'
        : 'Canvas decode unavailable — ingested the current frame payload directly.',
    )
    return true
  }, [])

  async function scanAllFrames() {
    const encoder = encoderRef.current
    const scanner = scannerRef.current
    if (!encoder || !scanner) return
    scanner.reset()
    const frames = encoder.getFrames()
    if (frames.length === 0) return

    let decodedFromPixels = 0
    for (let i = 0; i < frames.length; i++) {
      const canvas = encoder.getCanvas()
      const fromPixels = canvas ? decodeQrFromCanvas(canvas) : null
      await scanner.ingest(fromPixels ?? frames[i])
      if (fromPixels) decodedFromPixels += 1
      encoder.next()
    }
    setLoopbackNote(
      decodedFromPixels > 0
        ? `Decoded ${decodedFromPixels} displayed QR frame(s) via jsQR; remaining frames used the sequenced payload.`
        : `Ingested ${frames.length} sequenced frame payloads (canvas decode unavailable).`,
    )
  }

  return (
    <section className="transfer">
      <header className="app__header">
        <h1>QR Transfer</h1>
        <p className="app__subtitle">
          Encode an arbitrary byte string as sequenced high-contrast QR frames, then scan them
          back. Designed for payloads like a Kyber public key + Dilithium signature + header.
        </p>
      </header>

      <div className="transfer__grid">
        <div className="transfer__card">
          <h2>Payload</h2>
          <div className="transfer__row">
            <button type="button" onClick={loadSample}>
              Load sample PQC bundle
            </button>
            <button type="button" onClick={encodeInput}>
              Encode hex / base64
            </button>
          </div>
          <textarea
            aria-label="Payload hex or base64"
            className="transfer__hex"
            rows={6}
            placeholder="Paste hex or base64, or load the sample Kyber + Dilithium bundle"
            value={input}
            onChange={(event) => setInput(event.target.value)}
          />
          <p className="transfer__hint">
            {payload.length === 0
              ? 'No payload yet.'
              : `${payload.length} bytes ready · ${mode === 'continuous' ? 'animating' : 'manual'} playback`}
          </p>
        </div>

        <div className="transfer__card">
          <h2>Animated QR</h2>
          <fieldset className="transfer__modes">
            <legend>Playback</legend>
            <label>
              <input
                type="radio"
                name="qr-mode"
                checked={mode === 'continuous'}
                onChange={() => setMode('continuous')}
              />
              Continuous animation
            </label>
            <label>
              <input
                type="radio"
                name="qr-mode"
                checked={mode === 'manual'}
                onChange={() => setMode('manual')}
              />
              Manual next frame
            </label>
          </fieldset>
          {mode === 'continuous' && (
            <label className="transfer__speed">
              Interval {intervalMs} ms
              <input
                type="range"
                min={200}
                max={1500}
                step={50}
                value={intervalMs}
                onChange={(event) => setIntervalMs(Number(event.target.value))}
              />
            </label>
          )}
          <AnimatedQr
            ref={encoderRef}
            data={payload}
            mode={mode}
            intervalMs={intervalMs}
            size={280}
          />
        </div>

        <div className="transfer__card">
          <h2>Scanner</h2>
          <div className="transfer__row">
            <button type="button" onClick={() => void ingestDisplayedFrame()}>
              Scan displayed QR
            </button>
            <button type="button" onClick={() => void scanAllFrames()} data-testid="scan-all-frames">
              Scan all frames
            </button>
          </div>
          {loopbackNote && <p className="transfer__hint">{loopbackNote}</p>}
          <QrFrameScanner
            ref={scannerRef}
            onComplete={(data, meta) => {
              const header = parseSampleHeader(data)
              const note = header
                ? `Reassembled ${describeHeader(header)}`
                : `Reassembled ${data.length} bytes`
              void sha256Hex(data).then((hash) => {
                setResult({
                  hex: bytesToHex(data),
                  hash,
                  note: `${note} · ${meta.frameCount} frames · hash ${hash === meta.hash ? 'verified' : 'mismatch'}`,
                })
              })
            }}
          />
          {result && (
            <div className="transfer__result" data-testid="scan-result">
              <p>{result.note}</p>
              <p>
                SHA-256 <code>{result.hash}</code>
              </p>
              <pre className="transfer__hex">
                {result.hex.slice(0, 512)}
                {result.hex.length > 512 ? '…' : ''}
              </pre>
            </div>
          )}
        </div>
      </div>
    </section>
  )
}

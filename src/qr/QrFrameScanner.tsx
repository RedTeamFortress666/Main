import {
  forwardRef,
  useCallback,
  useEffect,
  useId,
  useImperativeHandle,
  useRef,
  useState,
} from 'react'
import { FrameCollector, type CollectResult } from './FrameCollector'
import { formatHashPreview } from './hash'

type Html5QrcodeClient = import('html5-qrcode').Html5Qrcode

export type QrScanAdapter = {
  start: (elementId: string, onDecode: (text: string) => void) => Promise<void>
  stop: () => Promise<void>
}

export interface QrCompleteMeta {
  hash: string
  frameCount: number
}

export interface QrFrameScannerHandle {
  ingest: (text: string) => Promise<CollectResult>
  reset: () => void
}

export interface QrFrameScannerProps {
  onComplete: (data: Uint8Array, meta: QrCompleteMeta) => void
  onProgress?: (result: CollectResult) => void
  scanAdapter?: QrScanAdapter
  fps?: number
}

function createHtml5Adapter(fps: number): QrScanAdapter {
  let scanner: Html5QrcodeClient | null = null
  return {
    async start(elementId, onDecode) {
      const { Html5Qrcode } = await import('html5-qrcode')
      scanner = new Html5Qrcode(elementId, { verbose: false })
      await scanner.start(
        { facingMode: 'environment' },
        { fps, qrbox: { width: 240, height: 240 } },
        (text) => onDecode(text),
        () => undefined,
      )
    },
    async stop() {
      if (!scanner) return
      try {
        if (scanner.isScanning) {
          await scanner.stop()
        }
        scanner.clear()
      } catch {
        // Camera teardown can race with unmount; ignore.
      } finally {
        scanner = null
      }
    },
  }
}

export const QrFrameScanner = forwardRef<QrFrameScannerHandle, QrFrameScannerProps>(
  function QrFrameScanner(
    {
      onComplete,
      onProgress,
      scanAdapter,
      fps = 12,
    },
    ref,
  ) {
  const rawId = useId()
  const elementId = `qr-reader-${rawId.replace(/:/g, '')}`
  const collectorRef = useRef(new FrameCollector())
  const completedRef = useRef(false)
  const fileScannerRef = useRef<Html5QrcodeClient | null>(null)

  const [cameraOn, setCameraOn] = useState(false)
  const [cameraError, setCameraError] = useState<string | null>(null)
  const [paste, setPaste] = useState('')
  const [status, setStatus] = useState<CollectResult>(() => ({
    status: 'progress',
    collected: 0,
    total: null,
    hash: null,
    missing: [],
  }))

  const handleResult = useCallback(
    (result: CollectResult) => {
      setStatus(result)
      onProgress?.(result)
      if (result.status === 'complete' && result.data && result.hash && !completedRef.current) {
        completedRef.current = true
        onComplete(result.data, {
          hash: result.hash,
          frameCount: result.total ?? 0,
        })
      }
    },
    [onComplete, onProgress],
  )

  const ingestText = useCallback(
    async (text: string) => {
      const result = await collectorRef.current.ingest(text)
      handleResult(result)
      return result
    },
    [handleResult],
  )

  useEffect(() => {
    if (!cameraOn) return
    let cancelled = false
    const adapter = scanAdapter ?? createHtml5Adapter(fps)

    adapter
      .start(elementId, (text) => {
        void ingestText(text)
      })
      .catch((error: unknown) => {
        if (cancelled) return
        setCameraError(error instanceof Error ? error.message : 'Could not start camera')
        setCameraOn(false)
      })

    return () => {
      cancelled = true
      void adapter.stop()
    }
  }, [cameraOn, elementId, fps, ingestText, scanAdapter])

  async function handleFile(fileList: FileList | null) {
    const file = fileList?.[0]
    if (!file) return
    try {
      const { Html5Qrcode } = await import('html5-qrcode')
      if (!fileScannerRef.current) {
        fileScannerRef.current = new Html5Qrcode(`${elementId}-file`, { verbose: false })
      }
      const text = await fileScannerRef.current.scanFile(file, false)
      await ingestText(text)
    } catch (error) {
      setCameraError(error instanceof Error ? error.message : 'Could not read QR from file')
    }
  }

  const reset = useCallback(() => {
    collectorRef.current.reset()
    completedRef.current = false
    const snapshot: CollectResult = {
      status: 'progress',
      collected: 0,
      total: null,
      hash: null,
      missing: [],
    }
    setStatus(snapshot)
    setPaste('')
    setCameraError(null)
  }, [])

  useImperativeHandle(
    ref,
    () => ({
      ingest: ingestText,
      reset,
    }),
    [ingestText, reset],
  )

  const missingPreview =
    status.missing.length === 0
      ? 'none'
      : status.missing.length <= 12
        ? status.missing.join(', ')
        : `${status.missing.slice(0, 12).join(', ')}…`

  return (
    <div className="qr-scanner">
      <div id={elementId} className="qr-scanner__viewport" hidden={!cameraOn} />
      <div id={`${elementId}-file`} hidden />

      <div className="qr-scanner__actions">
        <button type="button" onClick={() => setCameraOn((value) => !value)}>
          {cameraOn ? 'Stop camera' : 'Start camera'}
        </button>
        <label className="qr-file">
          Scan image
          <input
            type="file"
            accept="image/*"
            onChange={(event) => {
              void handleFile(event.target.files)
              event.target.value = ''
            }}
          />
        </label>
        <button type="button" onClick={reset}>
          Reset collection
        </button>
      </div>

      {cameraError && (
        <p className="qr-scanner__error" role="alert">
          {cameraError}
        </p>
      )}

      <dl className="qr-meta">
        <div>
          <dt>Collected</dt>
          <dd data-testid="scan-collected">
            {status.collected}
            {status.total !== null ? ` / ${status.total}` : ''}
          </dd>
        </div>
        <div className="qr-meta__hash">
          <dt>Content hash</dt>
          <dd data-testid="scan-hash">
            {status.hash ? formatHashPreview(status.hash) : 'waiting for first frame'}
          </dd>
        </div>
        <div>
          <dt>Missing</dt>
          <dd data-testid="scan-missing">{missingPreview}</dd>
        </div>
      </dl>

      {status.status === 'integrity_error' && (
        <p className="qr-scanner__error" role="alert">
          {status.error}
        </p>
      )}

      <form
        className="qr-paste"
        onSubmit={(event) => {
          event.preventDefault()
          const text = paste.trim()
          if (!text) return
          void ingestText(text)
          setPaste('')
        }}
      >
        <input
          aria-label="Paste QR frame text"
          placeholder="Paste a frame payload"
          value={paste}
          onChange={(event) => setPaste(event.target.value)}
        />
        <button type="submit">Ingest</button>
      </form>
    </div>
  )
  },
)

import { useEffect, useRef, useState } from 'react'
import type { OperatorAccount } from '../auth/operators'
import { LegalBanner } from '../components/LegalBanner'
import '../components/screens.css'
import './AirScreen.css'

interface AirScreenProps {
  operator: OperatorAccount
  onBack: () => void
  toast: (msg: string) => void
}

interface ChatMsg {
  id: string
  role: 'user' | 'assistant' | 'system'
  content: string
}

const DEFAULT_ENDPOINT = 'http://127.0.0.1:11434'
const MODEL_PRESETS = [
  'gemma2:latest',
  'gemma2-abliterated',
  'heretic',
  'llama3.1:latest',
  'custom',
]

export function AirScreen({ operator, onBack, toast }: AirScreenProps) {
  const [endpoint, setEndpoint] = useState(DEFAULT_ENDPOINT)
  const [model, setModel] = useState(MODEL_PRESETS[0])
  const [customModel, setCustomModel] = useState('')
  const [status, setStatus] = useState<'unknown' | 'online' | 'offline'>('unknown')
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)
  const [messages, setMessages] = useState<ChatMsg[]>([
    {
      id: 'sys-1',
      role: 'system',
      content: `AIR console for ${operator.displayName}. Point at a local Ollama / LM Studio / llama.cpp server. No cloud by default.`,
    },
  ])
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView?.({ behavior: 'smooth' })
  }, [messages, busy])

  const activeModel = model === 'custom' ? customModel.trim() || 'gemma2:latest' : model

  async function probe() {
    try {
      const res = await fetch(`${endpoint.replace(/\/$/, '')}/api/tags`, {
        signal: AbortSignal.timeout(2500),
      })
      if (!res.ok) throw new Error('bad status')
      setStatus('online')
      toast('Local AIR endpoint reachable')
    } catch {
      setStatus('offline')
      toast('No local AIR endpoint — replies will use fortress stub')
    }
  }

  async function send() {
    const text = input.trim()
    if (!text || busy) return
    setInput('')
    const userMsg: ChatMsg = { id: `u-${Date.now()}`, role: 'user', content: text }
    setMessages((m) => [...m, userMsg])
    setBusy(true)

    const history = [...messages, userMsg]
      .filter((m) => m.role !== 'system')
      .map((m) => ({ role: m.role, content: m.content }))

    try {
      const res = await fetch(`${endpoint.replace(/\/$/, '')}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: activeModel,
          stream: false,
          messages: [
            {
              role: 'system',
              content:
                'You are the offline AIR assistant inside GAME ØVER! Red Team Fortress. Help with authorized security research only. Be concise and tactical.',
            },
            ...history,
          ],
        }),
        signal: AbortSignal.timeout(60000),
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = (await res.json()) as { message?: { content?: string } }
      const reply = data.message?.content?.trim() || '(empty model response)'
      setStatus('online')
      setMessages((m) => [
        ...m,
        { id: `a-${Date.now()}`, role: 'assistant', content: reply },
      ])
    } catch {
      setStatus('offline')
      setMessages((m) => [
        ...m,
        {
          id: `a-${Date.now()}`,
          role: 'assistant',
          content: fortressStub(text, activeModel, endpoint),
        },
      ])
    } finally {
      setBusy(false)
    }
  }

  return (
    <section className="air screen">
      <button type="button" className="back-link" onClick={onBack}>
        ← Back to Batcave
      </button>
      <header className="screen-header">
        <div>
          <h1 className="screen-title">OFFLINE AIR</h1>
          <p className="screen-sub">
            Local Gemma / Heretic / GGUF bridge · {operator.displayName}
          </p>
        </div>
        <span className={status === 'online' ? 'device-pill' : 'badge badge--warn'}>
          {status === 'online' ? 'ENDPOINT UP' : status === 'offline' ? 'STUB MODE' : 'UNPROBED'}
        </span>
      </header>

      <div className="panel air__config">
        <h2 className="panel__label">ENDPOINT</h2>
        <label className="field">
          <span className="field__label">Base URL (Ollama-compatible)</span>
          <input
            className="field__input"
            value={endpoint}
            onChange={(e) => setEndpoint(e.target.value)}
            placeholder="http://127.0.0.1:11434"
          />
        </label>
        <label className="field">
          <span className="field__label">Model</span>
          <select
            className="field__input"
            value={model}
            onChange={(e) => setModel(e.target.value)}
          >
            {MODEL_PRESETS.map((m) => (
              <option key={m} value={m}>
                {m}
              </option>
            ))}
          </select>
        </label>
        {model === 'custom' && (
          <label className="field">
            <span className="field__label">Custom model id</span>
            <input
              className="field__input"
              value={customModel}
              onChange={(e) => setCustomModel(e.target.value)}
              placeholder="gemma2-abliterated:latest"
            />
          </label>
        )}
        <button type="button" className="ghost-btn ghost-btn--accent" onClick={probe}>
          PROBE LOCAL AIR
        </button>
      </div>

      <div className="air__transcript" aria-live="polite">
        {messages.map((msg) => (
          <div key={msg.id} className={`air__bubble air__bubble--${msg.role}`}>
            <span className="air__role">{msg.role}</span>
            <p>{msg.content}</p>
          </div>
        ))}
        {busy && <p className="air__thinking">AIR thinking…</p>}
        <div ref={bottomRef} />
      </div>

      <form
        className="air__composer"
        onSubmit={(e) => {
          e.preventDefault()
          void send()
        }}
      >
        <label className="sr-only" htmlFor="air-input">
          Message
        </label>
        <textarea
          id="air-input"
          className="field__textarea"
          rows={3}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask the local model…"
        />
        <button type="submit" className="cta" disabled={busy || !input.trim()}>
          TRANSMIT
        </button>
      </form>

      <LegalBanner>
        AIR is for authorized research assistants on systems you control. Do not use it to
        plan or execute unauthorized attacks.
      </LegalBanner>
    </section>
  )
}

function fortressStub(prompt: string, model: string, endpoint: string): string {
  return [
    `[FORTRESS STUB · ${model}]`,
    `No response from ${endpoint}.`,
    'Start Ollama (`ollama serve`) or LM Studio local server, pull your Gemma abliterated / Heretic GGUF, then PROBE again.',
    '',
    `Your prompt was received (${prompt.slice(0, 120)}${prompt.length > 120 ? '…' : ''}).`,
  ].join('\n')
}

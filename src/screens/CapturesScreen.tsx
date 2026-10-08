import { useMemo, useState } from 'react'
import { SAMPLE_CAPTURES, type CaptureSource } from '../data/modules'
import { LegalBanner } from '../components/LegalBanner'
import '../components/screens.css'

const FILTERS: { id: 'all' | CaptureSource; label: string }[] = [
  { id: 'all', label: 'ALL' },
  { id: 'evil', label: 'EVIL' },
  { id: 'wifi', label: 'WIFI' },
  { id: 'mitm', label: 'MITM' },
  { id: 'nethunter', label: 'NETHUNTER' },
  { id: 'manual', label: 'MANUAL' },
]

interface CapturesScreenProps {
  toast: (msg: string) => void
}

export function CapturesScreen({ toast }: CapturesScreenProps) {
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<'all' | CaptureSource>('all')
  const [revealed, setRevealed] = useState<Record<string, boolean>>({})

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    return SAMPLE_CAPTURES.filter((cap) => {
      if (filter !== 'all' && cap.source !== filter) return false
      if (!q) return true
      const hay = `${cap.ip} ${cap.mac} ${cap.ap} ${cap.userAgent} ${cap.fields.map((f) => f.value).join(' ')}`.toLowerCase()
      return hay.includes(q)
    })
  }, [filter, query])

  const stats = {
    total: SAMPLE_CAPTURES.length,
    portal: SAMPLE_CAPTURES.filter((c) => c.source === 'evil').length,
    flagged: SAMPLE_CAPTURES.filter((c) => c.highValue).length,
    uniqueIps: new Set(SAMPLE_CAPTURES.map((c) => c.ip)).size,
  }

  function copyAll() {
    const text = filtered
      .map((c) => `${c.sourceLabel}\t${c.ip}\t${c.mac}\t${c.ap}\t${c.timestamp}`)
      .join('\n')
    void navigator.clipboard?.writeText(text)
    toast('Copied visible captures to clipboard')
  }

  function exportCsv() {
    const header = 'source,ip,mac,ap,timestamp,userAgent'
    const rows = filtered.map(
      (c) =>
        `"${c.sourceLabel}","${c.ip}","${c.mac}","${c.ap}","${c.timestamp}","${c.userAgent}"`,
    )
    const blob = new Blob([[header, ...rows].join('\n')], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'game-over-captures-sample.csv'
    a.click()
    URL.revokeObjectURL(url)
    toast('Exported sample CSV')
  }

  return (
    <section className="screen">
      <header className="screen-header">
        <div>
          <h1 className="screen-title">CREDENTIAL CAPTURE</h1>
          <p className="screen-sub">Live capture log — Evil Portal, MITM, WiFi Handshakes.</p>
        </div>
        <span className="badge badge--alert">
          <span className="pulse" /> {stats.total} CAPTURED
        </span>
      </header>

      <div className="stat-grid">
        <div className="stat"><span>TOTAL</span><strong>{stats.total}</strong></div>
        <div className="stat"><span>PORTAL</span><strong>{stats.portal}</strong></div>
        <div className="stat"><span>FLAGGED</span><strong>{stats.flagged}</strong></div>
        <div className="stat"><span>UNIQUE IPS</span><strong>{stats.uniqueIps}</strong></div>
      </div>

      <label className="field">
        <span className="sr-only">Search captures</span>
        <input
          className="field__input"
          placeholder="Search IPs, credentials, devices..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </label>

      <div className="tool-row tool-row--wrap" role="group" aria-label="Capture filters">
        {FILTERS.map((f) => (
          <button
            key={f.id}
            type="button"
            className={filter === f.id ? 'tool-chip is-active' : 'tool-chip'}
            onClick={() => setFilter(f.id)}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div className="action-row">
        <button type="button" className="ghost-btn" onClick={copyAll}>COPY</button>
        <button type="button" className="ghost-btn" onClick={exportCsv}>CSV</button>
        <button
          type="button"
          className="ghost-btn ghost-btn--accent"
          onClick={() => toast('Manual capture entry opens in operator console')}
        >
          + ADD
        </button>
      </div>

      <p className="sample-note">
        Showing sample data — real captures appear here when your authorized portal
        or NetHunter bridge reports events.
      </p>

      <ul className="capture-list">
        {filtered.map((cap) => (
          <li key={cap.id} className="capture-card">
            <div className="capture-card__tags">
              <span className={cap.source === 'wifi' ? 'tag tag--warn' : 'tag tag--crit'}>
                {cap.sourceLabel}
              </span>
              {cap.highValue && <span className="tag tag--flag">HIGH VALUE</span>}
            </div>
            <p className="capture-card__net">
              <span className="neon">{cap.ip}</span>
              <span className="dim"> · {cap.mac}</span>
            </p>
            <p className="capture-card__meta">
              AP <span className="cyan">{cap.ap}</span> · {cap.timestamp}
            </p>
            <p className="capture-card__ua">{cap.userAgent}</p>
            <div className="capture-fields">
              {cap.fields.map((field) => {
                const key = `${cap.id}-${field.label}`
                const show = !field.secret || revealed[key]
                return (
                  <div key={field.label} className="capture-field">
                    <span className="capture-field__label">{field.label}</span>
                    <span className="capture-field__value neon">
                      {show ? field.value : '••••••••••••'}
                    </span>
                    {field.secret && (
                      <button
                        type="button"
                        className="linkish"
                        onClick={() =>
                          setRevealed((prev) => ({ ...prev, [key]: !prev[key] }))
                        }
                      >
                        {show ? 'HIDE' : 'VIEW'}
                      </button>
                    )}
                  </div>
                )
              })}
            </div>
          </li>
        ))}
      </ul>

      <LegalBanner />
    </section>
  )
}

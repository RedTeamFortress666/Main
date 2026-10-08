import { useState } from 'react'
import { SAMPLE_ENGAGEMENTS } from '../data/modules'
import { LegalBanner } from '../components/LegalBanner'
import '../components/screens.css'

type ScanMode = 'WEB' | 'NETWORK' | 'FULL'

interface ScannerScreenProps {
  toast: (msg: string) => void
}

export function ScannerScreen({ toast }: ScannerScreenProps) {
  const [target, setTarget] = useState('')
  const [mode, setMode] = useState<ScanMode>('FULL')
  const [running, setRunning] = useState(false)
  const [reports, setReports] = useState(SAMPLE_ENGAGEMENTS)

  function launch() {
    const value = target.trim() || 'lab-target.local'
    setRunning(true)
    toast(`Queued ${mode} recon on ${value} (simulation)`)
    window.setTimeout(() => {
      setReports((prev) => [
        {
          id: `eng-${Date.now()}`,
          target: value,
          status: 'DONE',
          critical: mode === 'FULL' ? 2 : 1,
        },
        ...prev,
      ])
      setRunning(false)
      toast('Simulated engagement report ready')
    }, 1200)
  }

  return (
    <section className="screen">
      <header className="screen-header">
        <div>
          <h1 className="screen-title">AI VULNERABILITY SCANNER</h1>
          <p className="screen-sub">Scan → Detect → Recon analysis powered by AI.</p>
        </div>
        <span className="badge badge--warn">LAB MODE</span>
      </header>

      <div className="panel">
        <h2 className="panel__label">TARGET ACQUISITION</h2>
        <label className="field">
          <span className="sr-only">Target URL or IP</span>
          <input
            className="field__input"
            placeholder="https://target.com | 192.168.1.0/24"
            value={target}
            onChange={(e) => setTarget(e.target.value)}
          />
        </label>
        <div className="seg" role="group" aria-label="Scan mode">
          {(['WEB', 'NETWORK', 'FULL'] as ScanMode[]).map((m) => (
            <button
              key={m}
              type="button"
              className={mode === m ? 'seg__btn is-active' : 'seg__btn'}
              onClick={() => setMode(m)}
            >
              {m}
            </button>
          ))}
        </div>
        <button
          type="button"
          className="cta"
          disabled={running}
          onClick={launch}
        >
          {running ? 'RUNNING RECON…' : `LAUNCH ${mode} RECON + ANALYSIS`}
        </button>
      </div>

      <div className="section-block">
        <h2 className="section-title">ENGAGEMENT REPORTS</h2>
        <ul className="engagement-list">
          {reports.map((eng) => (
            <li key={eng.id} className="engagement-row">
              <div>
                <p className="engagement-row__target">{eng.target}</p>
                <p className="engagement-row__meta">Simulated findings only</p>
              </div>
              <span className="tag tag--ok">{eng.status}</span>
            </li>
          ))}
        </ul>
      </div>

      <LegalBanner>
        Scanner runs in simulation mode in this build. Wire to your private recon
        stack for customer engagements — never against systems without written auth.
      </LegalBanner>
    </section>
  )
}

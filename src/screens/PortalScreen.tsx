import { useState } from 'react'
import { IconDevice, IconGlobe } from '../components/Icons'
import { LegalBanner } from '../components/LegalBanner'
import '../components/screens.css'

type PortalTool = 'clone' | 'templates' | 'ai' | 'editor' | 'preview' | 'flash'

interface PortalScreenProps {
  toast: (msg: string) => void
}

const TOOLS: { id: PortalTool; label: string }[] = [
  { id: 'clone', label: 'Clone Website' },
  { id: 'templates', label: 'Templates' },
  { id: 'ai', label: 'AI Generate' },
  { id: 'editor', label: 'HTML Editor' },
  { id: 'preview', label: 'Preview' },
  { id: 'flash', label: 'Flash T-Deck' },
]

const TEMPLATES = [
  'Corporate Guest WiFi (training)',
  'Hotel Captive Portal (lab)',
  'Conference Check-in (demo)',
]

export function PortalScreen({ toast }: PortalScreenProps) {
  const [ssid, setSsid] = useState('FreeWiFi')
  const [tool, setTool] = useState<PortalTool>('clone')
  const [url, setUrl] = useState('')
  const [html, setHtml] = useState(
    '<!doctype html>\n<title>Lab Portal</title>\n<h1>Authorized training portal</h1>\n',
  )

  function runClone() {
    const seed = url.trim() || 'lab.example'
    setHtml(
      `<!doctype html>\n<html><head><meta charset="utf-8"><title>Lab Portal</title></head>\n<body style="font-family:monospace;background:#111;color:#0f0;padding:2rem">\n  <h1>Training captive portal</h1>\n  <p>Seeded from: ${seed}</p>\n  <p>GAME ØVER! Red Team Fortress — authorized use only</p>\n  <form><label>Email <input name="email"></label><br><label>Password <input name="password" type="password"></label><br><button>Continue</button></form>\n</body></html>\n`,
    )
    setTool('editor')
    toast('Generated self-contained lab portal HTML')
  }

  function flash() {
    toast('Queued portal.html → T-Deck SD root (USB bridge simulation)')
  }

  return (
    <section className="screen">
      <header className="screen-header">
        <div>
          <h1 className="screen-title">EVIL PORTAL SUITE</h1>
          <p className="screen-sub">Clone → Edit → Flash to T-Deck SD / USB</p>
        </div>
        <span className="device-pill">
          <IconDevice size={14} /> T-DECK READY
        </span>
      </header>

      <div className="config-row">
        <label className="field field--inline">
          <span className="field__label">FAKE AP SSID</span>
          <input
            className="field__input"
            value={ssid}
            onChange={(e) => setSsid(e.target.value)}
          />
        </label>
        <p className="config-hint">
          <code>portal.html</code> → flash to SD root
        </p>
      </div>

      <div className="tool-row" role="tablist" aria-label="Portal tools">
        {TOOLS.map((t) => (
          <button
            key={t.id}
            type="button"
            role="tab"
            aria-selected={tool === t.id}
            className={tool === t.id ? 'tool-chip is-active' : 'tool-chip'}
            onClick={() => setTool(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tool === 'clone' && (
        <div className="panel">
          <h2 className="panel__label">WEBSITE CLONER</h2>
          <p className="panel__copy">
            Enter a URL — the lab builder recreates a simplified login/landing
            page as a self-contained training captive portal.
          </p>
          <label className="field">
            <span className="sr-only">Source URL</span>
            <input
              className="field__input"
              placeholder="https://lab.example/login"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
            />
          </label>
          <button type="button" className="cta" onClick={runClone}>
            <IconGlobe size={16} /> CLONE SITE
          </button>
        </div>
      )}

      {tool === 'templates' && (
        <div className="panel">
          <h2 className="panel__label">TEMPLATES</h2>
          <ul className="simple-list">
            {TEMPLATES.map((name) => (
              <li key={name}>
                <button
                  type="button"
                  className="list-btn"
                  onClick={() => {
                    setHtml(
                      `<!doctype html><title>${name}</title><h1>${name}</h1><p>SSID: ${ssid}</p>`,
                    )
                    setTool('editor')
                    toast(`Loaded template: ${name}`)
                  }}
                >
                  {name}
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      {tool === 'ai' && (
        <div className="panel">
          <h2 className="panel__label">AI GENERATE</h2>
          <p className="panel__copy">
            Describe a training portal scenario. Output stays local as static HTML.
          </p>
          <textarea
            className="field__textarea"
            rows={4}
            placeholder="Guest WiFi login for a hotel lobby awareness drill…"
            defaultValue=""
            id="ai-brief"
          />
          <button
            type="button"
            className="cta"
            onClick={() => {
              const brief =
                (document.getElementById('ai-brief') as HTMLTextAreaElement)?.value ||
                'generic guest wifi'
              setHtml(
                  `<!doctype html><title>AI Lab Portal</title><h1>Awareness portal</h1><p>${brief}</p><p>AP: ${ssid}</p><p>GAME ØVER! Red Team Fortress</p>`,
                )
              setTool('editor')
              toast('AI lab portal draft ready')
            }}
          >
            GENERATE PORTAL
          </button>
        </div>
      )}

      {(tool === 'editor' || tool === 'preview') && (
        <div className="panel">
          <h2 className="panel__label">{tool === 'preview' ? 'PREVIEW' : 'HTML EDITOR'}</h2>
          {tool === 'preview' ? (
            <iframe
              className="portal-preview"
              title="Portal preview"
              sandbox=""
              srcDoc={html}
            />
          ) : (
            <textarea
              className="field__textarea field__textarea--code"
              rows={12}
              value={html}
              onChange={(e) => setHtml(e.target.value)}
              spellCheck={false}
            />
          )}
        </div>
      )}

      {tool === 'flash' && (
        <div className="panel">
          <h2 className="panel__label">FLASH TO T-DECK</h2>
          <p className="panel__copy">
            USB serial / SD bridge for LilyGO T-Deck. This build simulates the
            transfer queue used by Bruce-compatible ESP32 workflows.
          </p>
          <dl className="kv">
            <div><dt>SSID</dt><dd>{ssid}</dd></div>
            <div><dt>Artifact</dt><dd>portal.html</dd></div>
            <div><dt>Target</dt><dd>SD root</dd></div>
            <div><dt>Bridge</dt><dd>USB-C serial · ready</dd></div>
          </dl>
          <button type="button" className="cta" onClick={flash}>
            FLASH PORTAL.HTML
          </button>
        </div>
      )}

      <LegalBanner>
        Captive portal tooling is for authorized phishing simulations and customer
        awareness drills only. Do not deploy against networks without written consent.
      </LegalBanner>
    </section>
  )
}

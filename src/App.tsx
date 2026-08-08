import { useMemo, useState } from 'react'
import './App.css'
import {
  BOOT_MODE_LABELS,
  profiles,
  type BootMode,
  type DeviceProfile,
} from './data/profiles'
import { buildStagePlan, treeToText } from './data/stagePlan'

function App() {
  const [profileId, setProfileId] = useState(profiles[0].id)
  const [bootMode, setBootMode] = useState<BootMode>('single')
  const [includePolybius, setIncludePolybius] = useState(true)
  const [copied, setCopied] = useState(false)

  const profile = useMemo(
    () => profiles.find((p) => p.id === profileId) ?? profiles[0],
    [profileId],
  )

  const plan = useMemo(
    () => buildStagePlan(profile, bootMode, includePolybius),
    [profile, bootMode, includePolybius],
  )

  function selectProfile(next: DeviceProfile) {
    setProfileId(next.id)
    if (!next.supportedModes.includes(bootMode)) {
      setBootMode(next.supportedModes[0] ?? 'single')
    }
  }

  async function copyManifest() {
    const text = JSON.stringify(
      {
        profileId: plan.profileId,
        mode: plan.mode,
        includePolybius: plan.includePolybius,
        title: plan.title,
        summary: plan.summary,
        tree: plan.tree,
        checklist: plan.checklist,
        flashCommands: plan.flashCommands,
      },
      null,
      2,
    )
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1800)
    } catch {
      /* ignore */
    }
  }

  return (
    <div className="press">
      <div className="press-atmosphere" aria-hidden="true" />

      <header className="press-hero">
        <p className="press-brand">POLYBIUS PRESS</p>
        <h1>Stage SD cards before you flash.</h1>
        <p className="press-lede">
          Organise OS images, dual-boot layouts, and POLYBIUS payloads for R36S
          and LilyGO — including LineageOS (AndR36oid).
        </p>
        <div className="press-cta-row">
          <a className="press-cta" href="#workshop">
            Open workshop
          </a>
          <a
            className="press-cta press-cta-ghost"
            href="https://github.com/andr36oid/release_uploads"
            target="_blank"
            rel="noreferrer"
          >
            Lineage images
          </a>
        </div>
      </header>

      <main id="workshop" className="press-workshop">
        <section className="press-panel" aria-labelledby="device-heading">
          <h2 id="device-heading">Device</h2>
          <p className="press-hint">Pick the handheld or deck you are preparing.</p>
          <div className="press-device-grid">
            {profiles.map((p) => (
              <button
                key={p.id}
                type="button"
                className={
                  p.id === profile.id
                    ? 'press-device press-device-active'
                    : 'press-device'
                }
                onClick={() => selectProfile(p)}
              >
                <span className="press-device-name">{p.name}</span>
                <span className="press-device-meta">
                  {p.family.toUpperCase()} · {p.supportedModes.length} layout
                  {p.supportedModes.length === 1 ? '' : 's'}
                </span>
              </button>
            ))}
          </div>
          <p className="press-blurb">{profile.blurb}</p>
        </section>

        <section className="press-panel" aria-labelledby="boot-heading">
          <h2 id="boot-heading">Boot layout</h2>
          <p className="press-hint">
            Dual boot on R36S means two physical cards — OS+ROMs or two OS
            images you swap in TF1.
          </p>
          <div className="press-mode-row" role="radiogroup" aria-label="Boot mode">
            {profile.supportedModes.map((id) => (
              <button
                key={id}
                type="button"
                role="radio"
                aria-checked={bootMode === id}
                className={
                  bootMode === id ? 'press-mode press-mode-active' : 'press-mode'
                }
                onClick={() => setBootMode(id)}
              >
                <span className="press-mode-label">{BOOT_MODE_LABELS[id]}</span>
                <span className="press-mode-desc">
                  {id === 'single' && 'One microSD with the full OS image.'}
                  {id === 'dual_card' &&
                    'TF1 for OS, TF2 for ROMs after first boot.'}
                  {id === 'dual_os_swap' &&
                    'Two OS cards (e.g. Lineage + ArkOS); swap TF1 to switch.'}
                </span>
              </button>
            ))}
          </div>

          {profile.ports && profile.ports.length > 0 && (
            <label className="press-toggle">
              <input
                type="checkbox"
                checked={includePolybius}
                onChange={(e) => setIncludePolybius(e.target.checked)}
              />
              <span>
                Include POLYBIUS{' '}
                {profile.id === 'r36s-lineage' ? 'APK sideload' : 'port folder'}
              </span>
            </label>
          )}
        </section>

        <section className="press-panel" aria-labelledby="files-heading">
          <h2 id="files-heading">Downloads</h2>
          <p className="press-hint">
            Grab official images, then stage with the CLI. Files are not uploaded
            — this UI only builds the plan.
          </p>
          <div className="press-links">
            {profile.images.map((h) => (
              <a key={h.url} href={h.url} target="_blank" rel="noreferrer">
                {h.label}
              </a>
            ))}
            {includePolybius &&
              profile.ports?.map((h) => (
                <a key={h.url} href={h.url} target="_blank" rel="noreferrer">
                  {h.label}
                </a>
              ))}
          </div>
          {profile.images.some((i) => i.note) && (
            <ul className="press-notes">
              {profile.images
                .filter((i) => i.note)
                .map((i) => (
                  <li key={i.url}>{i.note}</li>
                ))}
            </ul>
          )}
        </section>

        <section className="press-panel press-plan" aria-labelledby="plan-heading">
          <div className="press-plan-head">
            <div>
              <h2 id="plan-heading">{plan.title}</h2>
              <p className="press-hint">{plan.summary}</p>
            </div>
            <button type="button" className="press-copy" onClick={copyManifest}>
              {copied ? 'Copied' : 'Copy manifest'}
            </button>
          </div>

          <ol className="press-steps">
            {plan.checklist.map((step) => (
              <li key={step}>
                <p>{step}</p>
              </li>
            ))}
          </ol>

          <div className="press-tree" aria-label="Staging tree">
            {treeToText(plan.tree)
              .split('\n')
              .map((line) => (
                <code key={line}>{line}</code>
              ))}
          </div>

          {plan.flashCommands.length > 0 && (
            <pre className="press-cli" tabIndex={0}>
              {plan.flashCommands.join('\n')}
            </pre>
          )}

          <p className="press-hint">
            Stage on disk:{' '}
            <code className="press-inline">
              python tools/sd_organiser/sd_organiser.py stage --profile{' '}
              {profile.id} --mode {bootMode}
              {includePolybius ? ' --polybius' : ''}
            </code>
          </p>
        </section>
      </main>

      <footer className="press-foot">
        <span>POLYBIUS PRESS · local-only organiser</span>
        <span>Flash with verified images · dd / Balena / Rufus</span>
      </footer>
    </div>
  )
}

export default App

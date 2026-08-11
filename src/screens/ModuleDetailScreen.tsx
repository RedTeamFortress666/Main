import { ATTACK_DEVICES, NETHUNTER_TOOLS, type ModuleId } from '../data/modules'
import { LegalBanner } from '../components/LegalBanner'
import { ModuleIcon } from '../components/Icons'
import '../components/screens.css'

interface ModuleDetailScreenProps {
  moduleId: ModuleId
  toast: (msg: string) => void
  onBack: () => void
}

const META: Record<ModuleId, { title: string; blurb: string }> = {
  'ai-scanner': {
    title: 'AI Vuln Scanner',
    blurb: 'Open the Scanner tab for target acquisition and engagement reports.',
  },
  nethunter: {
    title: 'Kali NetHunter Suite',
    blurb: 'Bridge into an on-device NetHunter chroot for customer lab engagements.',
  },
  'evil-portal': {
    title: 'Evil Portal',
    blurb: 'Open the Portal tab to build and flash training captive portals.',
  },
  wifi: {
    title: 'WiFi Attacks',
    blurb: 'Open the WiFi tab for 802.11 lab tooling and ESP32 attack devices.',
  },
  bluetooth: {
    title: 'Bluetooth Attacks',
    blurb: 'BLE reconnaissance console with ESP32-Bluetooth / Bruce command link.',
  },
  badusb: {
    title: 'BadUSB / Ducky',
    blurb: 'HID payload staging for authorized cable implants (lab profiles only).',
  },
  ir: {
    title: 'IR Multi-Tool',
    blurb: 'Infrared learn / replay toolkit via ESP32-IR modules.',
  },
  payloads: {
    title: 'Payload Library',
    blurb: 'Versioned scripts for NetHunter and ESP32 bridges — operator managed.',
  },
  devices: {
    title: 'Devices',
    blurb: 'ESP32, Raspberry Pi, LilyGO T-Deck, and Kali NetHunter endpoints.',
  },
}

export function ModuleDetailScreen({ moduleId, toast, onBack }: ModuleDetailScreenProps) {
  const meta = META[moduleId]

  return (
    <section className="screen">
      <button type="button" className="back-link" onClick={onBack}>
        ← Back to modules
      </button>
      <header className="screen-header">
        <div className="screen-header__row">
          <span className="neon"><ModuleIcon name={iconFor(moduleId)} size={22} /></span>
          <div>
            <h1 className="screen-title">{meta.title}</h1>
            <p className="screen-sub">{meta.blurb}</p>
          </div>
        </div>
      </header>

      {moduleId === 'nethunter' && <NetHunterPanel toast={toast} />}
      {moduleId === 'bluetooth' && <BluetoothPanel toast={toast} />}
      {moduleId === 'badusb' && <BadUsbPanel toast={toast} />}
      {moduleId === 'ir' && <IrPanel toast={toast} />}
      {moduleId === 'payloads' && <PayloadsPanel toast={toast} />}
      {moduleId === 'devices' && <DevicesPanel toast={toast} />}
      {(moduleId === 'ai-scanner' || moduleId === 'evil-portal' || moduleId === 'wifi') && (
        <div className="panel">
          <p className="panel__copy">{meta.blurb}</p>
          <button type="button" className="cta" onClick={onBack}>
            RETURN TO HOME
          </button>
        </div>
      )}

      <LegalBanner />
    </section>
  )
}

function iconFor(id: ModuleId) {
  switch (id) {
    case 'ai-scanner':
      return 'shield'
    case 'nethunter':
      return 'terminal'
    case 'evil-portal':
      return 'globe'
    case 'wifi':
      return 'wifi'
    case 'bluetooth':
      return 'bluetooth'
    case 'badusb':
      return 'keyboard'
    case 'ir':
      return 'ir'
    case 'payloads':
      return 'code'
    case 'devices':
      return 'chip'
  }
}

function NetHunterPanel({ toast }: { toast: (m: string) => void }) {
  const nh = ATTACK_DEVICES.find((d) => d.id === 'nethunter')
  return (
    <>
      <div className="panel">
        <h2 className="panel__label">BRIDGE STATUS</h2>
        <dl className="kv">
          <div><dt>Endpoint</dt><dd>{nh?.label}</dd></div>
          <div><dt>Transport</dt><dd>ADB / chroot socket</dd></div>
          <div><dt>Status</dt><dd className="neon">{nh?.status.toUpperCase()}</dd></div>
        </dl>
        <button
          type="button"
          className="cta"
          onClick={() => toast('NetHunter heartbeat OK (simulated)')}
        >
          PING NETHUNTER
        </button>
      </div>
      <div className="section-block">
        <h2 className="section-title">TOOL CATALOG</h2>
        <ul className="simple-list">
          {NETHUNTER_TOOLS.map((t) => (
            <li key={t.name} className="kv-row">
              <strong className="neon">{t.name}</strong>
              <span className="dim">{t.purpose}</span>
            </li>
          ))}
        </ul>
        <button
          type="button"
          className="ghost-btn ghost-btn--accent"
          onClick={() => toast('Open NetHunter KeX / terminal on device')}
        >
          LAUNCH OPERATOR SHELL
        </button>
      </div>
    </>
  )
}

function BluetoothPanel({ toast }: { toast: (m: string) => void }) {
  return (
    <div className="panel">
      <h2 className="panel__label">ESP32 / BRUCE LINK</h2>
      <p className="panel__copy">
        Pair Bruce-compatible ESP32 firmware over Bluetooth LE or USB serial for
        authorized BLE scans and GATT inspection in customer labs.
      </p>
      <dl className="kv">
        <div><dt>Preferred</dt><dd>ESP32-Bluetooth</dd></div>
        <div><dt>Fallback</dt><dd>USB direct line (CH340)</dd></div>
        <div><dt>Profile</dt><dd>Bruce · Marauder command set</dd></div>
      </dl>
      <div className="action-row">
        <button type="button" className="cta" onClick={() => toast('BLE scan queued (lab sim)')}>
          BLE SCAN
        </button>
        <button
          type="button"
          className="ghost-btn"
          onClick={() => toast('Opened GATT inspector (lab sim)')}
        >
          GATT
        </button>
      </div>
    </div>
  )
}

function BadUsbPanel({ toast }: { toast: (m: string) => void }) {
  const profiles = ['Windows lab unlock demo', 'macOS awareness drill', 'Linux inventory script']
  return (
    <div className="panel">
      <h2 className="panel__label">HID PROFILES</h2>
      <ul className="simple-list">
        {profiles.map((p) => (
          <li key={p}>
            <button type="button" className="list-btn" onClick={() => toast(`Staged: ${p}`)}>
              {p}
            </button>
          </li>
        ))}
      </ul>
      <p className="panel__copy">
        Payloads stay in your private library. This console only stages operator-approved
        scripts to a connected BadUSB / Ducky device.
      </p>
    </div>
  )
}

function IrPanel({ toast }: { toast: (m: string) => void }) {
  return (
    <div className="panel">
      <h2 className="panel__label">INFRARED CONSOLE</h2>
      <p className="panel__copy">
        Learn and replay IR signals through ESP32-IR for physical security assessments
        you are contracted to perform.
      </p>
      <div className="action-row">
        <button type="button" className="cta" onClick={() => toast('IR learn mode armed')}>
          LEARN
        </button>
        <button type="button" className="ghost-btn" onClick={() => toast('IR replay queued')}>
          REPLAY
        </button>
      </div>
    </div>
  )
}

function PayloadsPanel({ toast }: { toast: (m: string) => void }) {
  const items = [
    { name: 'recon-nmap-quick.sh', target: 'NetHunter' },
    { name: 'bruce-ble-scan.json', target: 'ESP32-BT' },
    { name: 'portal-hotel-lab.html', target: 'T-Deck' },
    { name: 'hid-inventory.txt', target: 'BadUSB' },
  ]
  return (
    <div className="panel">
      <h2 className="panel__label">LIBRARY</h2>
      <ul className="simple-list">
        {items.map((item) => (
          <li key={item.name} className="kv-row">
            <strong className="neon">{item.name}</strong>
            <span className="dim">{item.target}</span>
            <button
              type="button"
              className="linkish"
              onClick={() => toast(`Synced ${item.name}`)}
            >
              SYNC
            </button>
          </li>
        ))}
      </ul>
    </div>
  )
}

function DevicesPanel({ toast }: { toast: (m: string) => void }) {
  return (
    <div className="section-block">
      <h2 className="section-title">CONNECTED ENDPOINTS</h2>
      <ul className="device-list">
        {ATTACK_DEVICES.map((d) => (
          <li key={d.id} className="device-card">
            <div>
              <p className="device-card__name">{d.label}</p>
              <p className="device-card__detail">{d.detail}</p>
              <p className="device-card__transport">{d.transport}</p>
            </div>
            <div className="device-card__side">
              <span className={d.status === 'ready' ? 'tag tag--ok' : 'tag tag--warn'}>
                {d.status.toUpperCase()}
              </span>
              <button
                type="button"
                className="linkish"
                onClick={() =>
                  toast(
                    d.status === 'ready'
                      ? `Linked ${d.label}`
                      : `Pairing ${d.label}…`,
                  )
                }
              >
                {d.status === 'ready' ? 'SELECT' : 'PAIR'}
              </button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  )
}

import { useState } from 'react'
import { ATTACK_DEVICES, WIFI_TOOLS } from '../data/modules'
import { IconPlay, IconWifi } from '../components/Icons'
import { LegalBanner } from '../components/LegalBanner'
import '../components/screens.css'

interface WifiScreenProps {
  toast: (msg: string) => void
}

interface DetectedNetwork {
  ssid: string
  bssid: string
  channel: number
  signal: number
  security: string
}

export function WifiScreen({ toast }: WifiScreenProps) {
  const [selectedTool, setSelectedTool] = useState<string>(WIFI_TOOLS[0].id)
  const [deviceId, setDeviceId] = useState(ATTACK_DEVICES[0].id)
  const [deviceOpen, setDeviceOpen] = useState(false)
  const [ssid, setSsid] = useState('')
  const [channel, setChannel] = useState('6')
  const [networks, setNetworks] = useState<DetectedNetwork[]>([])
  const [scanning, setScanning] = useState(false)

  const wifiDevices = ATTACK_DEVICES.filter((d) =>
    ['host-phone', 'esp32-bt', 'esp32-alpha', 'esp32-ir', 'nethunter'].includes(d.id),
  )
  const selectedDevice = wifiDevices.find((d) => d.id === deviceId) ?? wifiDevices[0]

  function scan() {
    setScanning(true)
    toast('Scanning via ' + selectedDevice.label)
    window.setTimeout(() => {
      setNetworks([
        { ssid: 'CorpWifi_5G', bssid: 'DC:A6:32:11:22:33', channel: 36, signal: -48, security: 'WPA2' },
        { ssid: 'Guest-Lab', bssid: 'A4:C3:F0:81:2B:11', channel: 6, signal: -62, security: 'OPEN' },
        { ssid: 'IoT-Bridge', bssid: 'B8:27:EB:44:55:AA', channel: 11, signal: -71, security: 'WPA3' },
      ])
      setScanning(false)
      toast('Discovered 3 lab networks (simulated)')
    }, 900)
  }

  function execute() {
    toast(
      `Queued ${selectedTool} on ${selectedDevice.label}` +
        (ssid ? ` · SSID ${ssid}` : '') +
        ` · ch ${channel} (simulation)`,
    )
  }

  return (
    <section className="screen">
      <header className="screen-header screen-header--stack">
        <div className="screen-header__row">
          <IconWifi className="neon" size={22} />
          <p className="screen-sub">Auto-detect networks + full 802.11 attack arsenal</p>
        </div>
      </header>

      <div className="wifi-grid">
        {WIFI_TOOLS.map((tool) => (
          <button
            key={tool.id}
            type="button"
            className={selectedTool === tool.id ? 'wifi-tool is-active' : 'wifi-tool'}
            onClick={() => setSelectedTool(tool.id)}
          >
            {tool.label}
          </button>
        ))}
      </div>

      <div className="section-block">
        <div className="section-title-row">
          <h2 className="section-title">DETECTED NETWORKS</h2>
          <button type="button" className="ghost-btn ghost-btn--accent" onClick={scan} disabled={scanning}>
            {scanning ? '…' : 'SCAN'}
          </button>
        </div>
        {networks.length === 0 ? (
          <p className="empty-hint">Click SCAN to discover networks.</p>
        ) : (
          <ul className="net-list">
            {networks.map((n) => (
              <li key={n.bssid}>
                <button
                  type="button"
                  className="net-row"
                  onClick={() => {
                    setSsid(n.ssid)
                    setChannel(String(n.channel))
                    toast(`Selected ${n.ssid}`)
                  }}
                >
                  <span>
                    <strong className="neon">{n.ssid}</strong>
                    <small>{n.bssid} · {n.security}</small>
                  </span>
                  <span className="net-row__meta">ch {n.channel} · {n.signal} dBm</span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="panel">
        <h2 className="panel__label">ATTACK CONFIG</h2>
        <div className="dropdown">
          <button
            type="button"
            className="dropdown__trigger"
            aria-expanded={deviceOpen}
            onClick={() => setDeviceOpen((v) => !v)}
          >
            Attack device · {selectedDevice.label}
          </button>
          {deviceOpen && (
            <ul className="dropdown__menu" role="listbox">
              {wifiDevices.map((d) => (
                <li key={d.id}>
                  <button
                    type="button"
                    className={d.id === deviceId ? 'dropdown__option is-active' : 'dropdown__option'}
                    onClick={() => {
                      setDeviceId(d.id)
                      setDeviceOpen(false)
                    }}
                  >
                    <span>{d.label}</span>
                    <small>{d.detail}</small>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
        <div className="config-grid">
          <label className="field">
            <span className="field__label">Custom SSID</span>
            <input
              className="field__input"
              value={ssid}
              onChange={(e) => setSsid(e.target.value)}
              placeholder="Target SSID"
            />
          </label>
          <label className="field">
            <span className="field__label">Channel</span>
            <input
              className="field__input"
              value={channel}
              onChange={(e) => setChannel(e.target.value)}
              inputMode="numeric"
            />
          </label>
        </div>
        <button type="button" className="cta" onClick={execute}>
          <IconPlay size={14} /> EXECUTE
        </button>
      </div>

      <LegalBanner>
        WiFi attacks are illegal without written authorization. Use only on networks
        you own or have explicit permission to test. This UI queues simulated lab jobs.
      </LegalBanner>
    </section>
  )
}

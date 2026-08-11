export type NavTab = 'home' | 'scanner' | 'portal' | 'captures' | 'wifi' | 'vault'

export type ModuleId =
  | 'ai-scanner'
  | 'nethunter'
  | 'evil-portal'
  | 'wifi'
  | 'bluetooth'
  | 'badusb'
  | 'ir'
  | 'payloads'
  | 'devices'

export interface AttackModule {
  id: ModuleId
  title: string
  description: string
  icon: string
  tab?: NavTab
}

export const ATTACK_MODULES: AttackModule[] = [
  {
    id: 'ai-scanner',
    title: 'AI Vuln Scanner',
    description: 'Scan + recon analysis chains.',
    icon: 'shield',
    tab: 'scanner',
  },
  {
    id: 'nethunter',
    title: 'NetHunter Suite',
    description: 'Kali bridge – nmap, msf, hydra.',
    icon: 'terminal',
  },
  {
    id: 'evil-portal',
    title: 'Evil Portal',
    description: 'Clone → Edit → Flash T-Deck.',
    icon: 'globe',
    tab: 'portal',
  },
  {
    id: 'wifi',
    title: 'WiFi Attacks',
    description: 'Auto-scan, deauth, handshake.',
    icon: 'wifi',
    tab: 'wifi',
  },
  {
    id: 'bluetooth',
    title: 'Bluetooth Attacks',
    description: 'BLE scan, GATT, BlueBorne.',
    icon: 'bluetooth',
  },
  {
    id: 'badusb',
    title: 'BadUSB / Ducky',
    description: 'HID inject via cable – all OS.',
    icon: 'keyboard',
  },
  {
    id: 'ir',
    title: 'IR Multi-Tool',
    description: 'Infrared replay & jam.',
    icon: 'ir',
  },
  {
    id: 'payloads',
    title: 'Payload Library',
    description: 'Scripts & payload manager.',
    icon: 'code',
  },
  {
    id: 'devices',
    title: 'Devices',
    description: 'ESP32, RPi, T-Deck, NetHunter.',
    icon: 'chip',
  },
]

export type CaptureSource = 'evil' | 'wifi' | 'mitm' | 'nethunter' | 'manual'

export interface CaptureRecord {
  id: string
  source: CaptureSource
  sourceLabel: string
  highValue: boolean
  ip: string
  mac: string
  ap: string
  timestamp: string
  userAgent: string
  fields: { label: string; value: string; secret?: boolean }[]
}

export const SAMPLE_CAPTURES: CaptureRecord[] = [
  {
    id: 'cap-1',
    source: 'evil',
    sourceLabel: 'Evil Portal',
    highValue: true,
    ip: '192.168.4.12',
    mac: 'A4:C3:F0:81:2B:11',
    ap: 'FreeWiFi',
    timestamp: '2026-08-11 09:56:51',
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)',
    fields: [
      { label: 'EMAIL', value: 'john.doe@gmail.com' },
      { label: 'PASSWORD', value: '••••••••••••', secret: true },
    ],
  },
  {
    id: 'cap-2',
    source: 'evil',
    sourceLabel: 'Evil Portal',
    highValue: false,
    ip: '192.168.4.7',
    mac: 'B8:27:EB:44:55:AA',
    ap: 'FreeWiFi',
    timestamp: '2026-08-11 09:49:51',
    userAgent: 'Samsung Galaxy S23 · Android 13',
    fields: [
      { label: 'EMAIL', value: 'sarah.t@corp.local' },
      { label: 'PASSWORD', value: '••••••••••••', secret: true },
    ],
  },
  {
    id: 'cap-3',
    source: 'wifi',
    sourceLabel: 'WiFi Handshake',
    highValue: true,
    ip: '10.0.0.5',
    mac: 'DC:A6:32:11:22:33',
    ap: 'CorpWifi_5G',
    timestamp: '2026-08-11 08:58:51',
    userAgent: 'Windows 11 workstation',
    fields: [
      { label: 'SSID', value: 'CorpWifi_5G' },
      { label: 'PMKID', value: '••••••••••••••••', secret: true },
      { label: 'HASH', value: '••••••••••••••••', secret: true },
    ],
  },
]

export interface Engagement {
  id: string
  target: string
  status: 'DONE' | 'RUNNING' | 'QUEUED'
  critical: number
}

export const SAMPLE_ENGAGEMENTS: Engagement[] = [
  { id: 'eng-1', target: 'Www.google.com', status: 'DONE', critical: 3 },
]

export type AttackDeviceId =
  | 'host-phone'
  | 'esp32-bt'
  | 'esp32-alpha'
  | 'esp32-ir'
  | 'nethunter'
  | 'tdeck'

export interface AttackDevice {
  id: AttackDeviceId
  label: string
  detail: string
  transport: 'wlan' | 'bluetooth' | 'usb-serial' | 'ir' | 'adb'
  status: 'ready' | 'offline' | 'pairing'
}

export const ATTACK_DEVICES: AttackDevice[] = [
  {
    id: 'host-phone',
    label: 'Host Phone (wlan adapter)',
    detail: 'On-device adapter / NetHunter wlan1',
    transport: 'wlan',
    status: 'ready',
  },
  {
    id: 'esp32-bt',
    label: 'ESP32-Bluetooth',
    detail: 'Bruce / Marauder BLE command link',
    transport: 'bluetooth',
    status: 'ready',
  },
  {
    id: 'esp32-alpha',
    label: 'ESP32-Alpha',
    detail: 'USB-C direct serial (CH340 / CP2102)',
    transport: 'usb-serial',
    status: 'offline',
  },
  {
    id: 'esp32-ir',
    label: 'ESP32-IR',
    detail: 'Infrared TX/RX module',
    transport: 'ir',
    status: 'offline',
  },
  {
    id: 'nethunter',
    label: 'Kali NetHunter',
    detail: 'chroot bridge via Termux / KeX',
    transport: 'adb',
    status: 'ready',
  },
  {
    id: 'tdeck',
    label: 'LilyGO T-Deck',
    detail: 'Portal flash over USB / SD',
    transport: 'usb-serial',
    status: 'ready',
  },
]

export const WIFI_TOOLS = [
  { id: 'auto-scan', label: 'Auto-Scan & Detect' },
  { id: 'deauth', label: 'Deauth Attack' },
  { id: 'handshake', label: 'WPA Handshake Capture' },
  { id: 'beacon', label: 'Beacon Spam' },
  { id: 'evil-twin', label: 'Evil Twin AP' },
  { id: 'pmkid', label: 'PMKID Attack' },
  { id: 'jammer', label: 'WiFi Jammer' },
  { id: 'sniffer', label: 'Packet Sniffer' },
  { id: 'farm', label: 'Auto Handshake Farm' },
] as const

export const NETHUNTER_TOOLS = [
  { name: 'nmap', purpose: 'Host / port discovery' },
  { name: 'msfconsole', purpose: 'Metasploit framework console' },
  { name: 'hydra', purpose: 'Credential brute-force (lab only)' },
  { name: 'aircrack-ng', purpose: '802.11 suite' },
  { name: 'bettercap', purpose: 'MITM / recon toolkit' },
  { name: 'responder', purpose: 'LLMNR/NBT-NS poisoning' },
] as const

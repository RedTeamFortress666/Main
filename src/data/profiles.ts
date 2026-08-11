/** Device / firmware profiles for POLYBIUS PRESS image organiser. */

export type BootMode = 'single' | 'dual_card' | 'dual_os_swap' | 'dual_firmware'

export type DeviceFamily = 'r36' | 'esp32'

export interface DownloadRef {
  label: string
  url: string
  note?: string
}

export interface TreeNode {
  path: string
  kind: 'dir' | 'file' | 'image' | 'port'
  hint?: string
}

export interface Esp32Meta {
  pioEnv: string
  chip: 'esp32s3' | 'esp32'
  firmwareFile: string
  /** Device has a user microSD slot for assets (not an OS image). */
  hasMicroSd: boolean
}

export interface DeviceProfile {
  id: string
  name: string
  family: DeviceFamily
  group: 'R36S' | 'ESP32'
  blurb: string
  supportedModes: BootMode[]
  images: DownloadRef[]
  ports?: DownloadRef[]
  notes: string[]
  esp32?: Esp32Meta
}

const BRANCH = 'cursor/pool-pin-bt-ui-d8fa'
const RAW = `https://github.com/RedTeamFortress666/Main/raw/${BRANCH}`
const ESP32 = `https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/esp32`

export const BOOT_MODE_LABELS: Record<BootMode, string> = {
  single: 'Single image',
  dual_card: 'Dual card (OS + ROMs / assets)',
  dual_os_swap: 'Dual OS swap (two OS cards)',
  dual_firmware: 'Dual firmware (reflash to switch)',
}

export const BOOT_MODE_HINTS: Record<BootMode, string> = {
  single: 'One OS card or one firmware binary.',
  dual_card: 'TF1/OS (or flash firmware) plus a second card or SD for ROMs/assets.',
  dual_os_swap: 'Two physical OS cards (e.g. Lineage + ArkOS); swap TF1 to switch.',
  dual_firmware: 'Stage two .bin files; reflash USB to switch between firmwares.',
}

const R36_PORT: DownloadRef = {
  label: 'PØLYBĪUS R36S port zip',
  url: `${RAW}/polybius/dist/polybius-1.0.0-beta.1-r36s-port.zip`,
}

function espProfile(
  id: string,
  name: string,
  blurb: string,
  meta: Esp32Meta,
  extraNotes: string[] = [],
): DeviceProfile {
  const modes: BootMode[] = meta.hasMicroSd
    ? ['single', 'dual_card', 'dual_firmware']
    : ['single', 'dual_firmware']

  return {
    id,
    name,
    family: 'esp32',
    group: 'ESP32',
    blurb,
    supportedModes: modes,
    esp32: meta,
    images: [
      {
        label: meta.firmwareFile,
        url: `${ESP32}/${meta.firmwareFile}`,
        note: `PlatformIO env: ${meta.pioEnv}`,
      },
    ],
    notes: [
      `Flash over USB: pio run -e ${meta.pioEnv} -t upload`,
      `Or: esptool.py --chip ${meta.chip} --port /dev/ttyACM0 write_flash 0x0 ${meta.firmwareFile}`,
      ...extraNotes,
    ],
  }
}

export const profiles: DeviceProfile[] = [
  {
    id: 'r36s-arkos',
    name: 'R36S · ArkOS / dArkOS',
    family: 'r36',
    group: 'R36S',
    blurb: 'Stock Linux handheld firmware. Flash the OS image, then drop Polybius into Ports.',
    supportedModes: ['single', 'dual_card', 'dual_os_swap'],
    images: [
      {
        label: 'ArkOS-R3XS / Multipanel (community)',
        url: 'https://github.com/AeolusUX/ArkOS-R3XS',
        note: 'Pick the R35S/R36S Multipanel .img.xz release for your panel family.',
      },
      {
        label: 'dArkOS (R36S successor fork)',
        url: 'https://github.com/southoz/dArkOSRE-R36',
      },
    ],
    ports: [R36_PORT],
    notes: [
      'Flash the .img to TF1/SD1 with Etcher, Rufus, or `sd_organiser.py flash`.',
      'First boot expands partitions — wait several minutes.',
      'Dual card: Options → Advanced → Switch to SD2 for ROMs after first boot.',
    ],
  },
  {
    id: 'r36s-rocknix',
    name: 'R36S · ROCKNIX',
    family: 'r36',
    group: 'R36S',
    blurb: 'JELOS-family RK3326 build. Same Port layout for Polybius.',
    supportedModes: ['single', 'dual_card', 'dual_os_swap'],
    images: [
      {
        label: 'ROCKNIX RK3326 releases',
        url: 'https://github.com/ROCKNIX/distribution/releases',
        note: 'Download ROCKNIX-RK3326.aarch64-*-a.img.gz',
      },
    ],
    ports: [R36_PORT],
    notes: [
      'Gunzip then flash .img to TF1.',
      'Ports typically live under /roms/ports/ after first boot.',
    ],
  },
  {
    id: 'r36s-lineage',
    name: 'R36S · LineageOS (AndR36oid)',
    family: 'r36',
    group: 'R36S',
    blurb:
      'Android 11 / Lineage 18.1 for R36S-class devices. Flash like ArkOS; use TF2 for games after first boot.',
    supportedModes: ['single', 'dual_card', 'dual_os_swap'],
    images: [
      {
        label: 'AndR36oid release uploads',
        url: 'https://github.com/andr36oid/release_uploads',
        note: 'Clean install images (not OTA). Latest notes: github.com/andr36oid/releases',
      },
      {
        label: 'AndR36oid release notes',
        url: 'https://github.com/andr36oid/releases/releases',
      },
    ],
    ports: [
      {
        label: 'PØLYBÎŪS PORTAL',
        url: `${RAW}/polybius/dist/polybius-v1-stable-hq-android-arm64.apk`,
      },
      {
        label: 'PØLYBÎŪS V.1',
        url: `${RAW}/polybius/dist/polybius-v1-stable-user-android-arm64.apk`,
      },
      {
        label: 'PØLYBÎŪS V.1 — iOS (Safari web portable)',
        url: `${RAW}/polybius/dist/polybius-v1-stable-user-ios-web-portable.zip`,
      },
      {
        label: 'DARTH CHERRY filter APK',
        url: `${RAW}/polybius/dist/darth-cherry-1.0.2-android-arm64.apk`,
      },
    ],
    notes: [
      'Flash the Lineage .img/.zip to TF1 the same way as ArkOS (Etcher / Rufus / sd_organiser).',
      'Card is reformatted (often f2fs). After first boot, use TF2 for ROMs / extras.',
      'Optional: place empty `.noroms` on BOOT before first boot to give all storage to Android.',
      'OTA zips are recovery-only updates — do not flash those as a clean image.',
      'Dual OS swap: keep Lineage on one card and ArkOS/ROCKNIX on another; swap TF1 to switch OS.',
      'Operator cards: full roster only for SpamKat2 / RedTeam01 / Gam3.0n; others see their own card.',
    ],
  },
  espProfile(
    'lilygo-tdeck',
    'LilyGO T-Deck',
    'ESP32-S3 handheld with keyboard + microSD. Stage Polybius firmware and optional SD assets.',
    {
      pioEnv: 'tdeck',
      chip: 'esp32s3',
      firmwareFile: 'polybius-tdeck.bin',
      hasMicroSd: true,
    },
    [
      'Dual firmware: keep stock / Meshtastic .bin as firmware_b and reflash to switch.',
      'Dual card mode stages a FAT microSD assets folder (not an OS image).',
    ],
  ),
  espProfile(
    'm5-cardputer',
    'M5Stack Cardputer',
    'ESP32-S3 Cardputer with matrix keyboard. Flash Polybius .bin over USB; optional dual-firmware swap.',
    {
      pioEnv: 'cardputer',
      chip: 'esp32s3',
      firmwareFile: 'polybius-cardputer.bin',
      hasMicroSd: true,
    },
    [
      'Targets original 74HC138 matrix keyboard (not Cardputer ADV).',
      'microSD (if fitted) can hold cipher notes / assets — not a full OS image.',
    ],
  ),
  espProfile(
    'lilygo-tembed',
    'LilyGO T-Embed S3',
    'ESP32-S3 T-Embed. Firmware flash only (no handheld OS SD layout).',
    {
      pioEnv: 'tembed',
      chip: 'esp32s3',
      firmwareFile: 'polybius-tembed.bin',
      hasMicroSd: false,
    },
  ),
  espProfile(
    'cyd',
    'CYD (Cheap Yellow Display)',
    'ESP32 CYD board. Flash Polybius firmware over USB.',
    {
      pioEnv: 'cyd',
      chip: 'esp32',
      firmwareFile: 'polybius-cyd.bin',
      hasMicroSd: false,
    },
  ),
]

export function profileById(id: string): DeviceProfile | undefined {
  return profiles.find((p) => p.id === id)
}

export function profilesByGroup(): { group: string; items: DeviceProfile[] }[] {
  const order = ['R36S', 'ESP32'] as const
  return order.map((group) => ({
    group,
    items: profiles.filter((p) => p.group === group),
  }))
}

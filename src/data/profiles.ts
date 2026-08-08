/** Device / firmware profiles for POLYBIUS PRESS SD organiser. */

export type BootMode = 'single' | 'dual_card' | 'dual_os_swap'

export type SlotRole = 'tf1_os' | 'tf2_roms' | 'tf1_os_a' | 'tf2_os_b' | 'single'

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

export interface DeviceProfile {
  id: string
  name: string
  family: 'r36' | 'esp32' | 'generic'
  blurb: string
  supportedModes: BootMode[]
  images: DownloadRef[]
  ports?: DownloadRef[]
  notes: string[]
}

export const BOOT_MODE_LABELS: Record<BootMode, string> = {
  single: 'Single card',
  dual_card: 'Dual card (OS + ROMs)',
  dual_os_swap: 'Dual OS swap (two OS cards)',
}

export const profiles: DeviceProfile[] = [
  {
    id: 'r36s-arkos',
    name: 'R36S · ArkOS / dArkOS',
    family: 'r36',
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
    ports: [
      {
        label: 'PØLYBĪUS R36S port zip',
        url: 'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/polybius-1.0.0-beta.1-r36s-port.zip',
      },
    ],
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
    blurb: 'JELOS-family RK3326 build. Same Port layout for Polybius.',
    supportedModes: ['single', 'dual_card', 'dual_os_swap'],
    images: [
      {
        label: 'ROCKNIX RK3326 releases',
        url: 'https://github.com/ROCKNIX/distribution/releases',
        note: 'Download ROCKNIX-RK3326.aarch64-*-a.img.gz',
      },
    ],
    ports: [
      {
        label: 'PØLYBĪUS R36S port zip',
        url: 'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/polybius-1.0.0-beta.1-r36s-port.zip',
      },
    ],
    notes: [
      'Gunzip then flash .img to TF1.',
      'Ports typically live under /roms/ports/ after first boot.',
    ],
  },
  {
    id: 'r36s-lineage',
    name: 'R36S · LineageOS (AndR36oid)',
    family: 'r36',
    blurb: 'Android 11 / Lineage 18.1 for R36S-class devices. Flash like ArkOS; use TF2 for games after first boot.',
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
        label: 'PØLYBĪUS Android APK (sideload on Lineage)',
        url: 'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/polybius-1.0.0-beta.2-android-arm64.apk',
      },
      {
        label: 'DARTH CHERRY filter APK',
        url: 'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/darth-cherry-1.0.2-android-arm64.apk',
      },
    ],
    notes: [
      'Flash the Lineage .img/.zip to TF1 the same way as ArkOS (Etcher / Rufus / sd_organiser).',
      'Card is reformatted (often f2fs). After first boot, use TF2 for ROMs / extras.',
      'Optional: place empty `.noroms` on BOOT before first boot to give all storage to Android.',
      'OTA zips are recovery-only updates — do not flash those as a clean image.',
      'Dual OS swap: keep Lineage on one card and ArkOS/ROCKNIX on another; swap TF1 to switch OS.',
    ],
  },
  {
    id: 'lilygo-tdeck',
    name: 'LilyGO T-Deck',
    family: 'esp32',
    blurb: 'ESP32-S3 firmware — not an SD OS image. Organiser stages the .bin and flash command.',
    supportedModes: ['single'],
    images: [
      {
        label: 'polybius-tdeck.bin',
        url: 'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/esp32/polybius-tdeck.bin',
      },
    ],
    notes: [
      'Flash over USB: `pio run -e tdeck -t upload` or esptool write_flash 0x0 polybius-tdeck.bin',
      'No microSD OS layout — optional TF for future assets only.',
    ],
  },
]

export function profileById(id: string): DeviceProfile | undefined {
  return profiles.find((p) => p.id === id)
}

import type { BootMode, DeviceProfile, TreeNode } from './profiles'
import { BOOT_MODE_LABELS } from './profiles'

export interface StagePlan {
  profileId: string
  mode: BootMode
  includePolybius: boolean
  title: string
  summary: string
  tree: TreeNode[]
  checklist: string[]
  flashCommands: string[]
}

function modeTitle(profile: DeviceProfile, mode: BootMode): string {
  return `${profile.name} · ${BOOT_MODE_LABELS[mode]}`
}

function buildEsp32Plan(
  profile: DeviceProfile,
  mode: BootMode,
  includePolybius: boolean,
): StagePlan {
  const tree: TreeNode[] = []
  const checklist: string[] = []
  const flashCommands: string[] = []
  const root = `stage/${profile.id}`
  const meta = profile.esp32!
  const bin = meta.firmwareFile
  const portHint = '/dev/ttyACM0'

  tree.push({ path: root, kind: 'dir', hint: 'Work folder on your PC' })
  tree.push({ path: `${root}/downloads`, kind: 'dir', hint: 'Drop firmware binaries here' })
  tree.push({
    path: `${root}/downloads/${bin}`,
    kind: 'image',
    hint: 'Primary POLYBIUS firmware',
  })

  checklist.push(`Download ${bin} into downloads/`)
  checklist.push(`Connect ${profile.name} over USB`)

  if (mode === 'single') {
    checklist.push('Flash the primary firmware (command below)')
    flashCommands.push(
      `esptool.py --chip ${meta.chip} --port ${portHint} write_flash 0x0 downloads/${bin}`,
    )
    flashCommands.push(`pio run -e ${meta.pioEnv} -t upload`)
  }

  if (mode === 'dual_firmware') {
    tree.push({
      path: `${root}/downloads/firmware_a_${bin}`,
      kind: 'image',
      hint: 'Firmware A — POLYBIUS',
    })
    tree.push({
      path: `${root}/downloads/firmware_b_alternate.bin`,
      kind: 'image',
      hint: 'Firmware B — stock / Meshtastic / other',
    })
    tree.push({
      path: `${root}/FLASH_A.txt`,
      kind: 'file',
      hint: 'Reflash A to boot POLYBIUS',
    })
    tree.push({
      path: `${root}/FLASH_B.txt`,
      kind: 'file',
      hint: 'Reflash B to boot alternate firmware',
    })
    checklist.push('Keep both .bin files in downloads/')
    checklist.push('To switch OS/firmware: reflash A or B over USB (ESP32 has no dual-OS SD boot)')
    flashCommands.push(
      `esptool.py --chip ${meta.chip} --port ${portHint} write_flash 0x0 downloads/firmware_a_${bin}  # A`,
    )
    flashCommands.push(
      `esptool.py --chip ${meta.chip} --port ${portHint} write_flash 0x0 downloads/firmware_b_alternate.bin  # B`,
    )
  }

  if (mode === 'dual_card') {
    tree.push({
      path: `${root}/card_microsd_assets`,
      kind: 'dir',
      hint: 'FAT/exFAT microSD — notes, keys, extras (not an OS image)',
    })
    tree.push({
      path: `${root}/card_microsd_assets/README.txt`,
      kind: 'file',
      hint: 'Optional assets for T-Deck / Cardputer SD slot',
    })
    if (includePolybius) {
      tree.push({
        path: `${root}/card_microsd_assets/polybius/`,
        kind: 'dir',
        hint: 'Optional cipher notes / export drops',
      })
    }
    checklist.push('Flash firmware to the device over USB (not to the SD card)')
    checklist.push('Format microSD FAT32/exFAT and copy assets from card_microsd_assets/')
    flashCommands.push(
      `esptool.py --chip ${meta.chip} --port ${portHint} write_flash 0x0 downloads/${bin}`,
    )
  }

  for (const n of profile.notes) checklist.push(n)

  return {
    profileId: profile.id,
    mode,
    includePolybius,
    title: modeTitle(profile, mode),
    summary: profile.blurb,
    tree,
    checklist,
    flashCommands,
  }
}

/** Build a staging tree the operator copies onto cards / a work folder. */
export function buildStagePlan(
  profile: DeviceProfile,
  mode: BootMode,
  includePolybius: boolean,
): StagePlan {
  if (profile.family === 'esp32') {
    const effective = profile.supportedModes.includes(mode)
      ? mode
      : profile.supportedModes[0]
    return buildEsp32Plan(profile, effective, includePolybius)
  }

  const tree: TreeNode[] = []
  const checklist: string[] = []
  const flashCommands: string[] = []
  const root = `stage/${profile.id}`

  tree.push({ path: root, kind: 'dir', hint: 'Work folder on your PC' })
  tree.push({ path: `${root}/downloads`, kind: 'dir', hint: 'Drop official images here' })

  tree.push({
    path: `${root}/downloads/os-image.img`,
    kind: 'image',
    hint: 'Decompressed .img (from .xz / .gz / .zip)',
  })

  if (mode === 'single') {
    tree.push({ path: `${root}/card_tf1`, kind: 'dir', hint: 'Maps to TF1 / SD1 after flash' })
    checklist.push('Flash os-image.img to the TF1 microSD (destroys card contents)')
    checklist.push('Insert TF1, power on, wait for first-boot resize')
    flashCommands.push(
      'python tools/sd_organiser/sd_organiser.py flash --image downloads/os-image.img --disk /dev/sdX',
    )
  }

  if (mode === 'dual_card') {
    tree.push({
      path: `${root}/card_tf1_os`,
      kind: 'dir',
      hint: 'TF1 — flash OS image here',
    })
    tree.push({
      path: `${root}/card_tf2_roms`,
      kind: 'dir',
      hint: 'TF2 — blank or FAT/exFAT for ROMs after first boot',
    })
    tree.push({
      path: `${root}/card_tf2_roms/README.txt`,
      kind: 'file',
      hint: 'Insert after first boot; ArkOS: Switch to SD2 for ROMs',
    })
    checklist.push('Flash os-image.img to TF1 only')
    checklist.push('Leave TF2 empty until first boot finishes')
    checklist.push(
      profile.id === 'r36s-lineage'
        ? 'After Lineage first boot, use TF2 for ROMs / extras (card is f2fs on TF1)'
        : 'ArkOS: Options → Advanced → Switch to SD2 for ROMs (then optionally Read from SD1+SD2)',
    )
    flashCommands.push(
      'python tools/sd_organiser/sd_organiser.py flash --image downloads/os-image.img --disk /dev/sdX  # TF1 only',
    )
  }

  if (mode === 'dual_os_swap') {
    tree.push({
      path: `${root}/card_a_lineage_or_primary`,
      kind: 'dir',
      hint: 'OS card A — e.g. LineageOS',
    })
    tree.push({
      path: `${root}/card_b_arkos_or_secondary`,
      kind: 'dir',
      hint: 'OS card B — e.g. ArkOS / ROCKNIX',
    })
    tree.push({
      path: `${root}/card_a_lineage_or_primary/FLASH_THIS.txt`,
      kind: 'file',
      hint: 'Flash Lineage image to this physical card',
    })
    tree.push({
      path: `${root}/card_b_arkos_or_secondary/FLASH_THIS.txt`,
      kind: 'file',
      hint: 'Flash ArkOS/ROCKNIX image to this physical card',
    })
    checklist.push('Flash LineageOS image to card A')
    checklist.push('Flash ArkOS or ROCKNIX image to card B')
    checklist.push('Boot by inserting the desired OS card in TF1 (swap cards to switch OS)')
    checklist.push('Optional third card or TF2 for shared ROMs depending on firmware')
    flashCommands.push(
      'python tools/sd_organiser/sd_organiser.py flash --image downloads/lineage.img --disk /dev/sdX',
    )
    flashCommands.push(
      'python tools/sd_organiser/sd_organiser.py flash --image downloads/arkos.img --disk /dev/sdY',
    )
  }

  if (includePolybius && profile.ports?.length) {
    if (profile.id === 'r36s-lineage') {
      tree.push({
        path: `${root}/sideload`,
        kind: 'dir',
        hint: 'APKs to install on Lineage after boot',
      })
      tree.push({
        path: `${root}/sideload/polybius.apk`,
        kind: 'port',
        hint: 'Install via Files / adb install',
      })
      tree.push({
        path: `${root}/sideload/darth-cherry.apk`,
        kind: 'port',
        hint: 'Optional night filter',
      })
      checklist.push('After Lineage boots, sideload Polybius (+ optional DARTH CHERRY) APKs')
    } else {
      const portsRoot =
        mode === 'dual_card'
          ? `${root}/card_tf1_os/roms/ports`
          : `${root}/after_flash/roms/ports`
      tree.push({ path: portsRoot, kind: 'dir', hint: 'Copy onto TF1 after first boot' })
      tree.push({
        path: `${portsRoot}/Polybius.sh`,
        kind: 'port',
        hint: 'Launcher from polybius-*-r36s-port.zip',
      })
      tree.push({
        path: `${portsRoot}/polybius/`,
        kind: 'dir',
        hint: 'Binary, lib/, data/ from the port zip',
      })
      checklist.push('Unzip polybius-*-r36s-port.zip')
      checklist.push(
        'Copy ports/Polybius.sh and ports/polybius/ into /roms/ports/ on the OS card (or /roms2/ports/)',
      )
      checklist.push('Refresh Ports menu / reboot → launch Polybius')
    }
  }

  for (const n of profile.notes) checklist.push(n)

  return {
    profileId: profile.id,
    mode,
    includePolybius,
    title: modeTitle(profile, mode),
    summary: profile.blurb,
    tree,
    checklist,
    flashCommands,
  }
}

export function treeToText(tree: TreeNode[]): string {
  return tree
    .map((n) => {
      const mark = n.kind === 'dir' ? '[dir]' : `[${n.kind}]`
      return `${mark} ${n.path}${n.hint ? `  — ${n.hint}` : ''}`
    })
    .join('\n')
}

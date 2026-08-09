import { describe, expect, it } from 'vitest'
import { profileById, profiles, profilesByGroup } from './profiles'
import { buildStagePlan, treeToText } from './stagePlan'

describe('profiles', () => {
  it('includes LineageOS, T-Deck, and Cardputer', () => {
    expect(profileById('r36s-lineage')).toBeDefined()
    expect(profileById('lilygo-tdeck')?.esp32?.firmwareFile).toBe(
      'polybius-tdeck.bin',
    )
    expect(profileById('m5-cardputer')?.esp32?.pioEnv).toBe('cardputer')
  })

  it('groups R36S and ESP32 devices', () => {
    const groups = profilesByGroup()
    expect(groups.map((g) => g.group)).toEqual(['R36S', 'ESP32'])
    expect(groups[0].items.every((p) => p.family === 'r36')).toBe(true)
    expect(groups[1].items.every((p) => p.family === 'esp32')).toBe(true)
  })

  it('lists expected device ids', () => {
    expect(profiles.map((p) => p.id)).toEqual([
      'r36s-arkos',
      'r36s-rocknix',
      'r36s-lineage',
      'lilygo-tdeck',
      'm5-cardputer',
      'lilygo-tembed',
      'cyd',
    ])
  })
})

describe('buildStagePlan', () => {
  it('stages dual-card Lineage with APK sideload', () => {
    const profile = profileById('r36s-lineage')!
    const plan = buildStagePlan(profile, 'dual_card', true)
    expect(plan.title).toMatch(/LineageOS/i)
    expect(plan.tree.some((n) => n.path.includes('card_tf2_roms'))).toBe(true)
    expect(plan.tree.some((n) => n.path.includes('sideload/polybius.apk'))).toBe(
      true,
    )
    expect(plan.flashCommands[0]).toMatch(/sd_organiser\.py flash/)
  })

  it('stages dual OS swap with two card folders', () => {
    const profile = profileById('r36s-arkos')!
    const plan = buildStagePlan(profile, 'dual_os_swap', false)
    expect(plan.tree.some((n) => n.path.includes('card_a_'))).toBe(true)
    expect(plan.tree.some((n) => n.path.includes('card_b_'))).toBe(true)
    expect(plan.flashCommands.length).toBeGreaterThanOrEqual(2)
  })

  it('stages Cardputer dual firmware', () => {
    const profile = profileById('m5-cardputer')!
    const plan = buildStagePlan(profile, 'dual_firmware', true)
    expect(plan.tree.some((n) => n.path.includes('firmware_b_alternate'))).toBe(
      true,
    )
    expect(plan.flashCommands.some((c) => c.includes('cardputer') || c.includes('polybius-cardputer'))).toBe(
      true,
    )
  })

  it('stages T-Deck dual card with microSD assets', () => {
    const profile = profileById('lilygo-tdeck')!
    const plan = buildStagePlan(profile, 'dual_card', true)
    expect(plan.tree.some((n) => n.path.includes('card_microsd_assets'))).toBe(
      true,
    )
    expect(plan.flashCommands[0]).toMatch(/esptool/)
  })

  it('stages T-Deck single as firmware only', () => {
    const profile = profileById('lilygo-tdeck')!
    const plan = buildStagePlan(profile, 'single', false)
    expect(plan.tree.some((n) => n.path.endsWith('polybius-tdeck.bin'))).toBe(
      true,
    )
    expect(plan.flashCommands[0]).toMatch(/esptool/)
  })

  it('renders tree text without crashing', () => {
    const profile = profileById('r36s-rocknix')!
    const plan = buildStagePlan(profile, 'single', true)
    const text = treeToText(plan.tree)
    expect(text).toContain('[dir]')
    expect(text).toContain('roms/ports')
  })
})

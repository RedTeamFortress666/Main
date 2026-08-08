import { describe, expect, it } from 'vitest'
import { profileById, profiles } from './profiles'
import { buildStagePlan, treeToText } from './stagePlan'

describe('profiles', () => {
  it('includes LineageOS for R36S', () => {
    const lineage = profileById('r36s-lineage')
    expect(lineage).toBeDefined()
    expect(lineage?.supportedModes).toContain('dual_os_swap')
    expect(lineage?.images.some((i) => /andr36oid/i.test(i.url))).toBe(true)
  })

  it('lists expected device ids', () => {
    expect(profiles.map((p) => p.id)).toEqual([
      'r36s-arkos',
      'r36s-rocknix',
      'r36s-lineage',
      'lilygo-tdeck',
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

  it('stages T-Deck as firmware only', () => {
    const profile = profileById('lilygo-tdeck')!
    const plan = buildStagePlan(profile, 'single', false)
    expect(plan.tree.some((n) => n.path.endsWith('.bin'))).toBe(true)
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

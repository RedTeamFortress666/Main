import { describe, it, expect } from 'vitest';
import { FONT5, pixelTextWidth, lifeBarWidth, fighterPoseFromState } from './js/pixel.js';

describe('pixel font', () => {
  it('has glyphs for A-Z, 0-9, and FIGHT punctuation', () => {
    const need = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?.\'-:/+*><';
    for (const ch of need) {
      expect(FONT5[ch], ch).toBeTruthy();
      expect(FONT5[ch]).toHaveLength(7);
    }
  });

  it('measures YOKO\'S TUNA BRAWL at scale 4', () => {
    expect(pixelTextWidth("YOKO'S TUNA BRAWL", 4)).toBe(17 * 6 * 4);
  });
});

describe('lifeBarWidth', () => {
  it('fills the bar at full HP and shrinks from the right when flipped by caller', () => {
    expect(lifeBarWidth(1000, 1000, 400)).toBe(400);
    expect(lifeBarWidth(500, 1000, 400)).toBe(200);
    expect(lifeBarWidth(0, 1000, 400)).toBe(0);
    expect(lifeBarWidth(50, 1000, 400)).toBe(20);
  });
});

describe('fighterPoseFromState', () => {
  it('crouches, punches, and KOs from fighter flags', () => {
    expect(fighterPoseFromState({ crouching: true, airborne: false, animTime: 0 }).crouch).toBe(1);
    expect(fighterPoseFromState({
      attacking: true,
      attack: { id: 'lp', startup: 1, active: 2, recovery: 1 },
      attackFrame: 2,
      animTime: 0,
    }).punch).toBe(1);
    expect(fighterPoseFromState({ state: 'ko', animTime: 0 }).ko).toBe(1);
  });

  it('fires laser-eye pose from laserEyes', () => {
    expect(fighterPoseFromState({
      attacking: true,
      attack: { id: 'laserEyes', projectile: 'laser', startup: 1, active: 2, recovery: 1 },
      attackFrame: 2,
      animTime: 0,
    }).laser).toBe(1);
  });
});

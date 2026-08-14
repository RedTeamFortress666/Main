import { describe, it, expect } from 'vitest';
import {
  numpadDir,
  motionMatches,
  detectSpecial,
  applyDamage,
  applyHeal,
  comboScale,
  isBlocked,
  timeoutWinner,
  matchOver,
  canMilkTimeout,
  canTunaRevive,
  contactVoice,
  gainMeter,
  spendMeter,
  MAX_HP,
  MAX_METER,
  MAX_MILKS_PER_ROUND,
  ATTACKS,
  CHARACTERS,
  GAME_TITLE,
  CANVAS_W,
  CANVAS_H,
} from './js/logic.js';

describe('title', () => {
  it('is Yoko\'s Tuna Brawl', () => {
    expect(GAME_TITLE).toBe("YOKO'S TUNA BRAWL");
  });

  it('exports a 1280x720 stage', () => {
    expect(CANVAS_W).toBe(1280);
    expect(CANVAS_H).toBe(720);
  });
});

describe('numpadDir', () => {
  it('treats right as forward when facing right', () => {
    expect(numpadDir(false, true, false, false, 1)).toBe(6);
    expect(numpadDir(true, false, false, false, 1)).toBe(4);
  });

  it('flips forward when facing left', () => {
    expect(numpadDir(true, false, false, false, -1)).toBe(6);
    expect(numpadDir(false, true, false, false, -1)).toBe(4);
  });

  it('encodes diagonals', () => {
    expect(numpadDir(false, true, false, true, 1)).toBe(3);
    expect(numpadDir(true, false, false, true, 1)).toBe(1);
  });
});

describe('motionMatches', () => {
  it('detects a clean QCF', () => {
    expect(motionMatches([5, 2, 3, 6, 6], [2, 3, 6])).toBe(true);
  });

  it('allows small gaps between steps', () => {
    expect(motionMatches([2, 5, 5, 3, 5, 6], [2, 3, 6])).toBe(true);
  });

  it('does not treat double QCF as a dragon punch', () => {
    expect(motionMatches([2, 3, 6, 2, 3, 6], [6, 2, 3])).toBe(false);
    expect(motionMatches([2, 3, 6, 2, 3, 6], [2, 3, 6])).toBe(true);
  });
});

describe('detectSpecial', () => {
  it('maps QCF + punch to Yoko tuna slap', () => {
    expect(detectSpecial([2, 3, 6], 'p', 0, 'yoko')).toBe('royalTunaSlap');
  });

  it('maps QCF + kick to Morlan soviet scratch', () => {
    expect(detectSpecial([2, 3, 6], 'k', 0, 'morlan')).toBe('sovietScratch');
  });

  it('maps DP + punch to Crown Dive / Hammer & Sickle', () => {
    expect(detectSpecial([6, 2, 3], 'p', 0, 'yoko')).toBe('crownDive');
    expect(detectSpecial([6, 2, 3], 'p', 0, 'morlan')).toBe('hammerSickle');
  });

  it('requires full meter for supers', () => {
    const dirs = [2, 3, 6, 2, 3, 6];
    expect(detectSpecial(dirs, 'p', 0, 'yoko')).toBe('royalTunaSlap');
    expect(detectSpecial(dirs, 'p', MAX_METER, 'yoko')).toBe('goldStandard');
    expect(detectSpecial(dirs, 'p', MAX_METER, 'morlan')).toBe('octoberRevolution');
  });
});

describe('damage and meter', () => {
  it('scales combo damage down', () => {
    expect(comboScale(1)).toBe(1);
    expect(comboScale(4)).toBeLessThan(comboScale(2));
    const first = applyDamage(MAX_HP, 100, 1);
    const fourth = applyDamage(MAX_HP, 100, 4);
    expect(fourth.dealt).toBeLessThan(first.dealt);
    expect(first.hp).toBe(MAX_HP - first.dealt);
  });

  it('caps heal at max HP', () => {
    const r = applyHeal(950, 220);
    expect(r.hp).toBe(MAX_HP);
    expect(r.healed).toBe(50);
  });

  it('fills and spends super meter', () => {
    expect(gainMeter(90, 20)).toBe(MAX_METER);
    expect(spendMeter(80).ok).toBe(false);
    expect(spendMeter(MAX_METER).ok).toBe(true);
    expect(spendMeter(MAX_METER).meter).toBe(0);
  });
});

describe('block rules', () => {
  it('mids block standing or crouching', () => {
    expect(isBlocked('mid', true, false, false)).toBe(true);
    expect(isBlocked('mid', true, true, false)).toBe(true);
  });

  it('lows require a crouch block', () => {
    expect(isBlocked('low', true, false, false)).toBe(false);
    expect(isBlocked('low', true, true, false)).toBe(true);
  });

  it('overheads require a stand block', () => {
    expect(isBlocked('overhead', true, true, false)).toBe(false);
    expect(isBlocked('overhead', true, false, false)).toBe(true);
  });

  it('airborne fighters cannot block', () => {
    expect(isBlocked('mid', true, false, true)).toBe(false);
  });
});

describe('round and timeout / revive rules', () => {
  it('timeout awards the higher HP', () => {
    expect(timeoutWinner(400, 200)).toBe(1);
    expect(timeoutWinner(100, 100)).toBe(0);
  });

  it('match is first to two rounds', () => {
    expect(matchOver(1, 1)).toBe(0);
    expect(matchOver(2, 1)).toBe(1);
    expect(matchOver(0, 2)).toBe(2);
  });

  it('limits milk timeouts per round and tuna revives per match', () => {
    expect(canMilkTimeout(0)).toBe(true);
    expect(canMilkTimeout(MAX_MILKS_PER_ROUND)).toBe(false);
    expect(canTunaRevive(0)).toBe(true);
    expect(canTunaRevive(1)).toBe(false);
  });
});

describe('roster', () => {
  it('names every advertised special', () => {
    const yoko = [
      CHARACTERS.yoko.specials.qcf_p,
      CHARACTERS.yoko.specials.qcb_p,
      CHARACTERS.yoko.specials.qcf_k,
      CHARACTERS.yoko.specials.dp_p,
      CHARACTERS.yoko.specials.super,
    ];
    const morlan = [
      CHARACTERS.morlan.specials.qcf_p,
      CHARACTERS.morlan.specials.qcb_p,
      CHARACTERS.morlan.specials.qcf_k,
      CHARACTERS.morlan.specials.dp_p,
      CHARACTERS.morlan.specials.super,
    ];
    for (const id of [...yoko, ...morlan]) {
      expect(ATTACKS[id]).toBeTruthy();
      expect(ATTACKS[id].name.length).toBeGreaterThan(3);
    }
    expect(ATTACKS.royalTunaSlap.name).toMatch(/Tuna/);
    expect(ATTACKS.hammerSickle.name).toMatch(/Hammer/);
  });
});

describe('contact voice', () => {
  it('meows on a peaceful bump and hisses during an attack', () => {
    expect(contactVoice(false, false)).toBe('meow');
    expect(contactVoice(true, false)).toBe('hiss');
    expect(contactVoice(false, true)).toBe('hiss');
  });
});

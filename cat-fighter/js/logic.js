/**
 * Cat Fighter: Tuna vs Blue — pure combat/rules helpers.
 * No DOM. Safe to unit-test from Vitest.
 *
 * Adding a special later:
 *   1. Register the motion in SPECIAL_MOTIONS
 *   2. Add an attack in ATTACKS
 *   3. Map it on the character in CHARACTERS[id].specials
 */

export const CANVAS_W = 1280;
export const CANVAS_H = 720;
export const GROUND_Y = 604;
export const ROUND_TIME = 99;
export const ROUNDS_TO_WIN = 2;
export const MAX_HP = 1000;
export const MAX_METER = 100;
export const MILK_HEAL = 220;
export const TUNA_HEAL = 180;
export const REVIVES_PER_MATCH = 1;
export const MAX_MILKS_PER_ROUND = 2;
export const MOTION_WINDOW = 22;
export const INPUT_BUFFER = 32;

export const CHARACTERS = {
  yoko: {
    id: 'yoko',
    name: 'Queen Yoko',
    short: 'YOKO',
    title: 'Tuna Monarch of the Realm',
    superName: 'THE GOLD STANDARD',
    color: '#e8c547',
    accent: '#111111',
    specials: {
      qcf_p: 'royalTunaSlap',
      qcb_p: 'monarchyMeow',
      qcf_k: 'capitalistClaw',
      dp_p: 'crownDive',
      super: 'goldStandard',
    },
    winQuotes: [
      'Do send the bill to the proletariat, darling.',
      'The pound sterling remains undefeated.',
      'Bow. Then fetch more tuna — chilled, not revolutionary.',
    ],
    intro: 'Her Majesty will take this round with interest.',
  },
  morlan: {
    id: 'morlan',
    name: 'Tsar Morlan',
    short: 'MORLAN',
    title: 'Red Tsar of the Proletariat',
    superName: 'OCTOBER REVOLUTION',
    color: '#c0392b',
    accent: '#8aa0b3',
    specials: {
      qcf_p: 'redOctoberPounce',
      qcb_p: 'proletariatBarrage',
      qcf_k: 'sovietScratch',
      dp_p: 'hammerSickle',
      super: 'octoberRevolution',
    },
    winQuotes: [
      'The crown is merely a shiny bourgeois trinket.',
      'From each cat, according to his tuna.',
      'The revolution will not be privatized.',
    ],
    intro: 'The winter palace falls before paw and will.',
  },
};

/** Numpad-notation motions. 6 = forward relative to facing. */
export const SPECIAL_MOTIONS = {
  qcf: [2, 3, 6],
  qcfLoose: [2, 6],
  qcb: [2, 1, 4],
  qcbLoose: [2, 4],
  dp: [6, 2, 3],
  dpLoose: [6, 3],
  super: [2, 3, 6, 2, 3, 6],
  superLoose: [2, 6, 2, 6],
};

/**
 * Attack definitions. Times are frames at 60fps.
 * hitbox is relative to the fighter origin (feet-center), x in facing-space.
 */
export const ATTACKS = {
  lp: {
    id: 'lp', name: 'Jab',
    startup: 4, active: 3, recovery: 9,
    damage: 28, meterGain: 6, chip: 2,
    hitstun: 12, blockstun: 8, hitstop: 6,
    knockback: 3.2, launch: 0, type: 'mid',
    hitbox: { x: 28, y: -92, w: 52, h: 36 },
  },
  mp: {
    id: 'mp', name: 'Strong',
    startup: 7, active: 4, recovery: 14,
    damage: 52, meterGain: 9, chip: 4,
    hitstun: 16, blockstun: 12, hitstop: 8,
    knockback: 5.4, launch: 0, type: 'mid',
    hitbox: { x: 30, y: -100, w: 66, h: 40 },
  },
  hp: {
    id: 'hp', name: 'Fierce',
    startup: 11, active: 5, recovery: 20,
    damage: 78, meterGain: 12, chip: 7,
    hitstun: 20, blockstun: 16, hitstop: 11,
    knockback: 7.5, launch: 1.2, type: 'mid',
    hitbox: { x: 34, y: -108, w: 78, h: 48 },
  },
  lk: {
    id: 'lk', name: 'Short',
    startup: 5, active: 3, recovery: 11,
    damage: 32, meterGain: 6, chip: 2,
    hitstun: 12, blockstun: 8, hitstop: 6,
    knockback: 3.6, launch: 0, type: 'mid',
    hitbox: { x: 36, y: -70, w: 58, h: 32 },
  },
  mk: {
    id: 'mk', name: 'Forward Kick',
    startup: 8, active: 4, recovery: 16,
    damage: 58, meterGain: 9, chip: 5,
    hitstun: 17, blockstun: 13, hitstop: 8,
    knockback: 6.0, launch: 0, type: 'mid',
    hitbox: { x: 40, y: -78, w: 74, h: 36 },
  },
  hk: {
    id: 'hk', name: 'Roundhouse',
    startup: 13, active: 5, recovery: 22,
    damage: 86, meterGain: 13, chip: 8,
    hitstun: 22, blockstun: 17, hitstop: 12,
    knockback: 8.4, launch: 2.4, type: 'mid',
    hitbox: { x: 42, y: -96, w: 86, h: 44 },
  },
  clp: {
    id: 'clp', name: 'Crouch Jab',
    startup: 4, active: 3, recovery: 10,
    damage: 26, meterGain: 5, chip: 2,
    hitstun: 11, blockstun: 8, hitstop: 5,
    knockback: 2.8, launch: 0, type: 'mid',
    hitbox: { x: 26, y: -58, w: 50, h: 30 },
  },
  cmk: {
    id: 'cmk', name: 'Low Kick',
    startup: 7, active: 4, recovery: 15,
    damage: 48, meterGain: 8, chip: 4,
    hitstun: 15, blockstun: 11, hitstop: 7,
    knockback: 5.0, launch: 0, type: 'low',
    hitbox: { x: 30, y: -28, w: 70, h: 28 },
  },
  chk: {
    id: 'chk', name: 'Sweep',
    startup: 10, active: 5, recovery: 24,
    damage: 72, meterGain: 11, chip: 6,
    hitstun: 8, blockstun: 16, hitstop: 10,
    knockback: 9.0, launch: 0, type: 'low', knockdown: true,
    hitbox: { x: 28, y: -30, w: 88, h: 30 },
  },
  jlp: {
    id: 'jlp', name: 'Jump Jab',
    startup: 4, active: 10, recovery: 6,
    damage: 36, meterGain: 6, chip: 3,
    hitstun: 12, blockstun: 8, hitstop: 6,
    knockback: 3.0, launch: 0, type: 'overhead',
    hitbox: { x: 22, y: -90, w: 54, h: 40 },
  },
  jhp: {
    id: 'jhp', name: 'Jump Fierce',
    startup: 7, active: 12, recovery: 8,
    damage: 70, meterGain: 10, chip: 6,
    hitstun: 14, blockstun: 10, hitstop: 9,
    knockback: 5.5, launch: 0, type: 'overhead',
    hitbox: { x: 26, y: -100, w: 70, h: 50 },
  },
  jmk: {
    id: 'jmk', name: 'Jump Kick',
    startup: 6, active: 12, recovery: 8,
    damage: 62, meterGain: 9, chip: 5,
    hitstun: 14, blockstun: 10, hitstop: 8,
    knockback: 6.2, launch: 0, type: 'overhead',
    hitbox: { x: 30, y: -60, w: 72, h: 36 },
  },

  royalTunaSlap: {
    id: 'royalTunaSlap', name: 'Royal Tuna Slap',
    startup: 12, active: 4, recovery: 22,
    damage: 40, meterGain: 8, chip: 8,
    hitstun: 16, blockstun: 12, hitstop: 8,
    knockback: 4.0, launch: 0, type: 'mid',
    projectile: 'tuna',
    hitbox: { x: 40, y: -96, w: 48, h: 36 },
  },
  monarchyMeow: {
    id: 'monarchyMeow', name: 'Monarchy Meow',
    startup: 10, active: 8, recovery: 20,
    damage: 64, meterGain: 10, chip: 10,
    hitstun: 18, blockstun: 14, hitstop: 9,
    knockback: 7.0, launch: 1.0, type: 'mid',
    hitbox: { x: 20, y: -120, w: 130, h: 90 },
  },
  capitalistClaw: {
    id: 'capitalistClaw', name: 'Capitalist Claw Combo',
    startup: 9, active: 14, recovery: 18,
    damage: 28, meterGain: 5, chip: 4,
    hitstun: 10, blockstun: 8, hitstop: 4,
    knockback: 2.4, launch: 0, type: 'mid',
    multi: 3, multiGap: 5,
    advance: 3.4,
    hitbox: { x: 30, y: -100, w: 70, h: 50 },
  },
  crownDive: {
    id: 'crownDive', name: 'Crown Dive',
    startup: 6, active: 16, recovery: 18,
    damage: 92, meterGain: 12, chip: 10,
    hitstun: 18, blockstun: 14, hitstop: 12,
    knockback: 6.0, launch: 4.0, type: 'overhead',
    dive: true, invuln: [4, 12],
    hitbox: { x: 10, y: -70, w: 70, h: 70 },
  },

  redOctoberPounce: {
    id: 'redOctoberPounce', name: 'Red October Pounce',
    startup: 10, active: 10, recovery: 18,
    damage: 88, meterGain: 11, chip: 10,
    hitstun: 18, blockstun: 14, hitstop: 10,
    knockback: 8.0, launch: 2.0, type: 'mid',
    advance: 11, invuln: [8, 14],
    hitbox: { x: 20, y: -90, w: 90, h: 70 },
  },
  proletariatBarrage: {
    id: 'proletariatBarrage', name: 'Proletariat Paw Barrage',
    startup: 8, active: 18, recovery: 16,
    damage: 22, meterGain: 4, chip: 3,
    hitstun: 8, blockstun: 6, hitstop: 3,
    knockback: 1.8, launch: 0, type: 'mid',
    multi: 5, multiGap: 4,
    advance: 2.2,
    hitbox: { x: 28, y: -100, w: 64, h: 48 },
  },
  sovietScratch: {
    id: 'sovietScratch', name: 'Soviet Scratch',
    startup: 11, active: 6, recovery: 20,
    damage: 80, meterGain: 11, chip: 9,
    hitstun: 20, blockstun: 15, hitstop: 10,
    knockback: 7.2, launch: 1.5, type: 'mid',
    hitbox: { x: 24, y: -110, w: 120, h: 44 },
  },
  hammerSickle: {
    id: 'hammerSickle', name: 'Hammer & Sickle Uppercut',
    startup: 5, active: 12, recovery: 22,
    damage: 100, meterGain: 13, chip: 12,
    hitstun: 16, blockstun: 14, hitstop: 13,
    knockback: 4.0, launch: 12, type: 'mid',
    uppercut: true, invuln: [1, 10],
    hitbox: { x: 16, y: -150, w: 60, h: 140 },
  },

  goldStandard: {
    id: 'goldStandard', name: 'The Gold Standard',
    startup: 8, active: 20, recovery: 24,
    damage: 48, meterGain: 0, chip: 12,
    hitstun: 12, blockstun: 10, hitstop: 14,
    knockback: 3.0, launch: 3.0, type: 'mid',
    super: true, multi: 5, multiGap: 4, advance: 4.5,
    hitbox: { x: 20, y: -120, w: 110, h: 110 },
  },
  octoberRevolution: {
    id: 'octoberRevolution', name: 'October Revolution',
    startup: 8, active: 22, recovery: 26,
    damage: 50, meterGain: 0, chip: 12,
    hitstun: 12, blockstun: 10, hitstop: 14,
    knockback: 3.2, launch: 3.4, type: 'mid',
    super: true, multi: 5, multiGap: 4, advance: 5.0,
    hitbox: { x: 20, y: -120, w: 110, h: 110 },
  },
};

export function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

export function lerp(a, b, t) {
  return a + (b - a) * t;
}

export function rectsOverlap(a, b) {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

/**
 * Convert held directions into Street Fighter numpad notation.
 * 6 is always forward relative to `facing` (1 = looking right).
 */
export function numpadDir(left, right, up, down, facing) {
  const fwd = facing >= 0;
  let h = 5;
  if (left && !right) h = fwd ? 4 : 6;
  else if (right && !left) h = fwd ? 6 : 4;

  if (down && !up) {
    if (h === 4) return 1;
    if (h === 6) return 3;
    return 2;
  }
  if (up && !down) {
    if (h === 4) return 7;
    if (h === 6) return 9;
    return 8;
  }
  return h;
}

/**
 * Match a motion anchored on the most recent non-neutral input.
 * The pattern's last step must be that input; earlier steps are found
 * searching backwards. A double QCF ends on 6, so it cannot also be a
 * DP (which must end on 3).
 */
export function motionMatches(dirs, pattern, windowFrames = MOTION_WINDOW) {
  if (!dirs.length || !pattern.length) return false;
  const start = Math.max(0, dirs.length - windowFrames);
  const slice = dirs.slice(start);
  let endAt = -1;
  for (let i = slice.length - 1; i >= 0; i--) {
    if (slice[i] !== 5) {
      endAt = i;
      break;
    }
  }
  if (endAt < 0 || slice[endAt] !== pattern[pattern.length - 1]) return false;
  let pi = pattern.length - 2;
  let last = endAt;
  for (let i = endAt - 1; i >= 0 && pi >= 0; i--) {
    if (slice[i] === pattern[pi] && last - i <= 10) {
      pi -= 1;
      last = i;
    }
  }
  return pi < 0;
}

export function anyMotion(dirs, keys) {
  return keys.some((k) => motionMatches(dirs, SPECIAL_MOTIONS[k]));
}

/**
 * Pick a special/super from the recent motion buffer + button class.
 * buttonClass: 'p' | 'k'
 */
export function detectSpecial(dirs, buttonClass, meter, characterId) {
  const ch = CHARACTERS[characterId];
  if (!ch) return null;
  const superReady = meter >= MAX_METER;
  if (superReady && anyMotion(dirs, ['super', 'superLoose'])) {
    return ch.specials.super;
  }
  if (anyMotion(dirs, ['dp', 'dpLoose']) && buttonClass === 'p') {
    return ch.specials.dp_p;
  }
  if (anyMotion(dirs, ['qcb', 'qcbLoose']) && buttonClass === 'p') {
    return ch.specials.qcb_p;
  }
  if (anyMotion(dirs, ['qcf', 'qcfLoose'])) {
    return buttonClass === 'k' ? ch.specials.qcf_k : ch.specials.qcf_p;
  }
  return null;
}

export function comboScale(hits) {
  if (hits <= 1) return 1;
  return Math.max(0.35, 0.92 ** (hits - 1));
}

export function applyDamage(hp, rawDamage, hitsInCombo) {
  const dmg = Math.max(1, Math.round(rawDamage * comboScale(hitsInCombo)));
  return { hp: clamp(hp - dmg, 0, MAX_HP), dealt: dmg };
}

export function applyHeal(hp, amount) {
  const next = clamp(hp + amount, 0, MAX_HP);
  return { hp: next, healed: next - hp };
}

export function gainMeter(meter, amount) {
  return clamp(meter + amount, 0, MAX_METER);
}

export function spendMeter(meter, cost = MAX_METER) {
  if (meter < cost) return { ok: false, meter };
  return { ok: true, meter: meter - cost };
}

export function isBlocked(attackType, blocking, crouching, airborne) {
  if (!blocking || airborne) return false;
  if (attackType === 'low') return crouching;
  if (attackType === 'overhead') return !crouching;
  return true;
}

export function timeoutWinner(hp1, hp2) {
  if (hp1 > hp2) return 1;
  if (hp2 > hp1) return 2;
  return 0;
}

export function matchOver(wins1, wins2, need = ROUNDS_TO_WIN) {
  if (wins1 >= need) return 1;
  if (wins2 >= need) return 2;
  return 0;
}

export function canMilkTimeout(milksThisRound, max = MAX_MILKS_PER_ROUND) {
  return milksThisRound < max;
}

export function canTunaRevive(revivesUsed, cap = REVIVES_PER_MATCH) {
  return revivesUsed < cap;
}

/** Meow on a friendly bump, hiss if someone is swinging. */
export function contactVoice(p1Attacking, p2Attacking) {
  return (p1Attacking || p2Attacking) ? 'hiss' : 'meow';
}

export function flavorForWin(winnerId) {
  const ch = CHARACTERS[winnerId];
  if (!ch) return 'The tea party is adjourned.';
  return ch.winQuotes[Math.floor(Math.random() * ch.winQuotes.length)];
}

export const CONTROL_MAP = {
  p1: {
    left: 'KeyA', right: 'KeyD', up: 'KeyW', down: 'KeyS',
    lp: 'KeyZ', mp: 'KeyX', hp: 'KeyC',
    lk: 'KeyF', mk: 'KeyG', hk: 'KeyH',
    block: 'ShiftLeft',
  },
  p2: {
    left: 'ArrowLeft', right: 'ArrowRight', up: 'ArrowUp', down: 'ArrowDown',
    lp: 'KeyN', mp: 'KeyM', hp: 'Comma',
    lk: 'KeyJ', mk: 'KeyK', hk: 'KeyL',
    block: 'ShiftRight',
  },
};

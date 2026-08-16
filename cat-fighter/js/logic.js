/**
 * Yoko's Tuna Brawl — pure combat/rules helpers.
 * No DOM. Safe to unit-test from Vitest.
 *
 * Adding a special later:
 *   1. Register the motion in SPECIAL_MOTIONS
 *   2. Add an attack in ATTACKS
 *   3. Map it on the character in CHARACTERS[id].specials
 */

export const GAME_TITLE = "YOKO'S TUNA BRAWL";
export const GAME_TITLE_SHORT = 'Tuna Brawl';
export const GAME_SUBTITLE = 'Yoko  Morlan  Kittens  Baby';
export const CANVAS_W = 1280;
export const CANVAS_H = 720;
export const GROUND_Y = 604;
export const ROUND_TIME = 99;
export const ROUNDS_TO_WIN = 2;
export const MAX_HP = 1000;
export const MAX_METER = 100;
export const LASER_MAX = 100;
export const LASER_COST = 34;
export const LASER_REGEN = 0.55;
export const P1_DAMAGE_MULT = 2.6;
export const CPU_DAMAGE_MULT = 0.14;
export const POWERUP_DURATION = 420;
export const POWERUP_DAMAGE = 2.15;
export const POWERUP_SPEED = 1.7;
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
  kittens: {
    id: 'kittens',
    name: 'Kittens',
    short: 'KITTENS',
    title: 'Lion of Socialist China',
    nation: 'China',
    superName: 'RED SUN RISING',
    color: '#e23b3b',
    accent: '#f4a04a',
    specials: {
      qcf_p: 'longMarchPounce',
      qcb_p: 'peoplesBarrage',
      qcf_k: 'starClaw',
      dp_p: 'greatLeapUpper',
      super: 'redSunRising',
    },
    winQuotes: [
      'The mane is collective. The tuna is shared.',
      'One cat, one star — the republic still stands.',
      'Your monarchy is a very small hill.',
    ],
    intro: 'The orange lion takes the square for the people.',
  },
  baby: {
    id: 'baby',
    name: 'Baby',
    short: 'BABY',
    title: 'Southern Cross of Australia',
    nation: 'Australia',
    superName: 'SOUTHERN CROSS',
    color: '#3a7bd5',
    accent: '#f3efe6',
    specials: {
      qcf_p: 'boomerangSlap',
      qcb_p: 'outbackBarrage',
      qcf_k: 'dropbearKick',
      dp_p: 'sydneyUpper',
      super: 'southernCross',
    },
    winQuotes: [
      'Fair go, mate. The tin is empty.',
      'Black fur. Gold eyes. End of argument.',
      'That was not a walkabout. That was a KO.',
    ],
    intro: 'The black Maine Coon clocks in from down under.',
  },
};

export const SELECTABLE_FIGHTERS = ['yoko', 'morlan', 'kittens', 'baby'];

export function defaultRival(id) {
  if (id === 'yoko') return 'morlan';
  if (id === 'morlan') return 'yoko';
  if (id === 'kittens') return 'baby';
  return 'kittens';
}

export function winBanner(id) {
  const ch = CHARACTERS[id];
  return ch ? `${ch.short} WINS!` : 'WINNER';
}

export function roundBanner(id) {
  const ch = CHARACTERS[id];
  return ch ? `${ch.short} TAKES THE ROUND` : 'ROUND';
}

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
  simplePunch: {
    id: 'simplePunch', name: 'Punch',
    startup: 4, active: 4, recovery: 8,
    damage: 96, meterGain: 8, chip: 6,
    hitstun: 14, blockstun: 8, hitstop: 5,
    knockback: 4.2, launch: 0, type: 'mid',
    hitbox: { x: 28, y: -100, w: 62, h: 44 },
  },
  simpleKick: {
    id: 'simpleKick', name: 'Kick',
    startup: 6, active: 5, recovery: 10,
    damage: 118, meterGain: 10, chip: 8,
    hitstun: 16, blockstun: 10, hitstop: 6,
    knockback: 6.0, launch: 1.4, type: 'mid',
    hitbox: { x: 34, y: -80, w: 78, h: 40 },
  },
  laserEyes: {
    id: 'laserEyes', name: 'Laser Eyes',
    startup: 8, active: 6, recovery: 14,
    damage: 150, meterGain: 0, chip: 20,
    hitstun: 16, blockstun: 10, hitstop: 8,
    knockback: 7.0, launch: 2.0, type: 'mid',
    projectile: 'laser',
    hitbox: { x: 40, y: -108, w: 90, h: 18 },
  },
  lp: {
    id: 'lp', name: 'Left Punch',
    startup: 3, active: 3, recovery: 8,
    damage: 26, meterGain: 6, chip: 2,
    hitstun: 13, blockstun: 7, hitstop: 5,
    knockback: 2.8, launch: 0, type: 'high',
    hitbox: { x: 28, y: -92, w: 52, h: 36 },
  },
  lp2: {
    id: 'lp2', name: 'Left Punch 2',
    startup: 3, active: 3, recovery: 7,
    damage: 30, meterGain: 6, chip: 2,
    hitstun: 14, blockstun: 8, hitstop: 5,
    knockback: 3.0, launch: 0, type: 'high',
    hitbox: { x: 30, y: -94, w: 56, h: 36 },
  },
  catThrow: {
    id: 'catThrow', name: 'Cat Throw',
    startup: 5, active: 4, recovery: 26,
    damage: 145, meterGain: 10, chip: 0,
    hitstun: 18, blockstun: 0, hitstop: 12,
    knockback: 10, launch: 7, type: 'throw', knockdown: true,
    hitbox: { x: 8, y: -110, w: 54, h: 100 },
  },
  mp: {
    id: 'mp', name: 'Right Punch',
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
    id: 'lk', name: 'Left Kick',
    startup: 5, active: 3, recovery: 11,
    damage: 32, meterGain: 6, chip: 2,
    hitstun: 12, blockstun: 8, hitstop: 6,
    knockback: 3.6, launch: 0, type: 'mid',
    hitbox: { x: 36, y: -70, w: 58, h: 32 },
  },
  mk: {
    id: 'mk', name: 'Right Kick',
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

  longMarchPounce: {
    id: 'longMarchPounce', name: 'Long March Pounce',
    startup: 10, active: 10, recovery: 18,
    damage: 90, meterGain: 11, chip: 10,
    hitstun: 18, blockstun: 14, hitstop: 10,
    knockback: 8.2, launch: 2.2, type: 'mid',
    advance: 12, invuln: [8, 14],
    hitbox: { x: 20, y: -90, w: 92, h: 72 },
  },
  peoplesBarrage: {
    id: 'peoplesBarrage', name: "People's Paw Barrage",
    startup: 8, active: 18, recovery: 16,
    damage: 24, meterGain: 4, chip: 3,
    hitstun: 8, blockstun: 6, hitstop: 3,
    knockback: 1.8, launch: 0, type: 'mid',
    multi: 5, multiGap: 4,
    advance: 2.4,
    hitbox: { x: 28, y: -100, w: 66, h: 50 },
  },
  starClaw: {
    id: 'starClaw', name: 'Five-Star Claw',
    startup: 11, active: 6, recovery: 20,
    damage: 82, meterGain: 11, chip: 9,
    hitstun: 20, blockstun: 15, hitstop: 10,
    knockback: 7.4, launch: 1.6, type: 'mid',
    hitbox: { x: 24, y: -110, w: 122, h: 44 },
  },
  greatLeapUpper: {
    id: 'greatLeapUpper', name: 'Great Leap Uppercut',
    startup: 5, active: 12, recovery: 22,
    damage: 102, meterGain: 13, chip: 12,
    hitstun: 16, blockstun: 14, hitstop: 13,
    knockback: 4.0, launch: 12, type: 'mid',
    uppercut: true, invuln: [1, 10],
    hitbox: { x: 16, y: -150, w: 62, h: 142 },
  },
  redSunRising: {
    id: 'redSunRising', name: 'Red Sun Rising',
    startup: 8, active: 22, recovery: 26,
    damage: 52, meterGain: 0, chip: 12,
    hitstun: 12, blockstun: 10, hitstop: 14,
    knockback: 3.2, launch: 3.4, type: 'mid',
    super: true, multi: 5, multiGap: 4, advance: 5.2,
    hitbox: { x: 20, y: -120, w: 112, h: 112 },
  },

  boomerangSlap: {
    id: 'boomerangSlap', name: 'Boomerang Slap',
    startup: 12, active: 4, recovery: 22,
    damage: 42, meterGain: 8, chip: 8,
    hitstun: 16, blockstun: 12, hitstop: 8,
    knockback: 4.2, launch: 0, type: 'mid',
    projectile: 'tuna',
    hitbox: { x: 40, y: -96, w: 48, h: 36 },
  },
  outbackBarrage: {
    id: 'outbackBarrage', name: 'Outback Barrage',
    startup: 8, active: 18, recovery: 16,
    damage: 23, meterGain: 4, chip: 3,
    hitstun: 8, blockstun: 6, hitstop: 3,
    knockback: 1.8, launch: 0, type: 'mid',
    multi: 5, multiGap: 4,
    advance: 2.3,
    hitbox: { x: 28, y: -100, w: 64, h: 48 },
  },
  dropbearKick: {
    id: 'dropbearKick', name: 'Drop Bear Kick',
    startup: 9, active: 14, recovery: 18,
    damage: 30, meterGain: 5, chip: 4,
    hitstun: 10, blockstun: 8, hitstop: 4,
    knockback: 2.6, launch: 0, type: 'mid',
    multi: 3, multiGap: 5,
    advance: 3.6,
    hitbox: { x: 30, y: -100, w: 72, h: 50 },
  },
  sydneyUpper: {
    id: 'sydneyUpper', name: 'Harbour Uppercut',
    startup: 5, active: 12, recovery: 22,
    damage: 98, meterGain: 13, chip: 12,
    hitstun: 16, blockstun: 14, hitstop: 13,
    knockback: 4.0, launch: 12, type: 'mid',
    uppercut: true, invuln: [1, 10],
    hitbox: { x: 16, y: -150, w: 60, h: 140 },
  },
  southernCross: {
    id: 'southernCross', name: 'Southern Cross',
    startup: 8, active: 20, recovery: 24,
    damage: 48, meterGain: 0, chip: 12,
    hitstun: 12, blockstun: 10, hitstop: 14,
    knockback: 3.0, launch: 3.0, type: 'mid',
    super: true, multi: 5, multiGap: 4, advance: 4.8,
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
  if (attackType === 'throw') return false;
  if (!blocking || airborne) return false;
  if (attackType === 'low') return crouching;
  if (attackType === 'overhead') return !crouching;
  if (attackType === 'high' && crouching) return false;
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

/** After a round pip is awarded: match over, or Stella serves milk between rounds. */
export function afterRoundEnd(wins1, wins2, need = ROUNDS_TO_WIN) {
  return matchOver(wins1, wins2, need) ? 'matchEnd' : 'stellaMilk';
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
    jump: 'Space', punch: 'KeyZ', kick: 'KeyX', laser: 'KeyC',
    lp: 'KeyZ', rp: 'KeyX', lk: 'KeyX', rk: 'KeyX',
    mp: 'KeyX', hp: 'KeyC', mk: 'KeyX', hk: 'KeyC',
    sidestep: 'KeyC',
    block: 'ShiftLeft',
  },
  p2: {
    left: 'ArrowLeft', right: 'ArrowRight', up: 'ArrowUp', down: 'ArrowDown',
    jump: 'KeyP', punch: 'KeyN', kick: 'KeyM', laser: 'Comma',
    lp: 'KeyN', rp: 'KeyM', lk: 'KeyM', rk: 'KeyM',
    mp: 'KeyM', hp: 'Comma', mk: 'KeyM', hk: 'KeyL',
    sidestep: 'Comma',
    block: 'ShiftRight',
  },
};

export function regenLaser(laser, max = LASER_MAX, rate = LASER_REGEN) {
  return clamp(laser + rate, 0, max);
}

export function spendLaser(laser, cost = LASER_COST) {
  if (laser < cost) return { ok: false, laser };
  return { ok: true, laser: laser - cost };
}

export function sideDamageMult(side, vsCpu, powered) {
  let m = side === 'p1' ? P1_DAMAGE_MULT : (vsCpu ? CPU_DAMAGE_MULT : 1);
  if (powered) m *= POWERUP_DAMAGE;
  return m;
}

export function pickupHitsFighter(pickup, fighter) {
  if (!pickup || !fighter) return false;
  const dx = pickup.x - fighter.x;
  const dy = pickup.y - (fighter.y - 70);
  return Math.abs(dx) < 52 && Math.abs(dy) < 78;
}

/** Tekken-style 4-limb ids. rp/rk reuse the stronger mid punch/kick data. */
export const LIMB_TO_NORMAL = { lp: 'lp', rp: 'mp', lk: 'lk', rk: 'mk' };

/**
 * Command throw, rage art, launchers and while-standing specials.
 * limbs: { lp, rp, lk, rk } just-pressed (throw also allows held partner).
 */
export function detectTekkenCommand(dir, limbs, meter, characterId) {
  const ch = CHARACTERS[characterId];
  if (!ch) return null;
  if (limbs.throw) return 'catThrow';
  if (meter >= MAX_METER && ((limbs.lp && limbs.rk) || (limbs.rp && limbs.lk))) {
    return ch.specials.super;
  }
  if ((dir === 3 || dir === 2) && limbs.rp) return ch.specials.dp_p;
  if (dir === 4 && limbs.rp) return ch.specials.qcb_p;
  if (dir === 3 && limbs.rk) return ch.specials.qcf_k;
  return null;
}

/** Cancel a confirmed hit into the next limb as a string. */
export function stringFollowup(prevId, nextLimb) {
  if (!nextLimb) return null;
  if (prevId === 'lp' && nextLimb === 'lp') return 'lp2';
  if ((prevId === 'lp' || prevId === 'lp2') && nextLimb === 'rp') return 'mp';
  if (prevId === 'lk' && nextLimb === 'rk') return 'hk';
  if (prevId === 'rp' && nextLimb === 'rk') return 'hk';
  if (prevId === 'mp' && nextLimb === 'rk') return 'hk';
  return LIMB_TO_NORMAL[nextLimb] || nextLimb;
}

export function canCancelAttack(attack, frame, hasHit) {
  if (!attack || !hasHit) return false;
  const start = attack.startup;
  const end = attack.startup + attack.active + Math.min(10, attack.recovery);
  return frame >= start && frame < end;
}

/** Double-tap forward (6) or back (4) in the recent numpad buffer. */
export function detectDash(dirs, forward = true, window = 12) {
  const want = forward ? 6 : 4;
  const slice = dirs.slice(-window);
  let last = -1;
  for (let i = slice.length - 1; i >= 0; i--) {
    if (slice[i] !== 5) { last = i; break; }
  }
  if (last < 0 || slice[last] !== want) return false;
  let sawNeutral = false;
  for (let i = last - 1; i >= 0; i--) {
    if (slice[i] === 5) { sawNeutral = true; continue; }
    return sawNeutral && slice[i] === want;
  }
  return false;
}

export const TRACK_LEN = 2400;
export const RACE_LAPS = 3;

export const RACERS = {
  yoko: {
    id: 'yoko', name: 'Queen Yoko', short: 'YOKO',
    car: 'Gold Rolls Royce', color: '#e8c547', accent: '#111111',
  },
  morlan: {
    id: 'morlan', name: 'Tsar Morlan', short: 'MORLAN',
    car: 'Black Hearse', color: '#ff8a80', accent: '#c0392b',
  },
  baby: {
    id: 'baby', name: 'Baby', short: 'BABY',
    car: 'Blue Lotus', color: '#3a7bd5', accent: '#f3efe6',
    title: 'Australia',
  },
  kittens: {
    id: 'kittens', name: 'Kittens', short: 'KITTENS',
    car: 'Red VW Beetle', color: '#e23b3b', accent: '#f4a04a',
    title: 'Socialist China',
  },
};

export function raceProgress(racer) {
  return (racer.laps || 0) * TRACK_LEN + (racer.s || 0);
}

export function raceRanking(racers) {
  return [...racers].sort((a, b) => raceProgress(b) - raceProgress(a));
}

export function trackPoint(s, lane = 0) {
  const t = ((s % TRACK_LEN) / TRACK_LEN) * Math.PI * 2;
  const rx = 470 + lane;
  const ry = 230 + lane * 0.55;
  return {
    x: CANVAS_W / 2 + Math.cos(t) * rx,
    y: CANVAS_H / 2 + 18 + Math.sin(t) * ry,
    heading: t + Math.PI / 2,
  };
}

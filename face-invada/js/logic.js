/**
 * FACE INVADA's BEAT BOXING — pure rhythm/fight rules.
 * No DOM. Safe to unit-test from Vitest.
 */

export const GAME_TITLE = "FACE INVADA'S BEAT BOXING";
export const GAME_SUBTITLE = 'SUPER POWER DJ BRAH';
export const CANVAS_W = 1280;
export const CANVAS_H = 720;
export const BPM = 120;
export const FPS = 60;
export const BEATS_PER_BAR = 4;
export const CHART_BEATS = 96;
export const COUNT_IN = 4;
export const MAX_HP = 1000;
export const CPU_HP = 720;
export const PERFECT_WINDOW = 0.22;
export const GOOD_WINDOW = 0.55;
export const MISS_AFTER = 0.62;
export const PERFECT_DMG = 58;
export const GOOD_DMG = 34;
export const MISS_DMG = 10;
export const SUPER_DMG = 160;
export const SUPER_COST = 80;
export const LANES = ['punch', 'kick', 'blade', 'bass'];
export const LANE_LABELS = {
  punch: 'PUNCH',
  kick: 'KICK',
  blade: 'BLADE',
  bass: 'BASS',
};

export const HERO = {
  id: 'face',
  name: 'FACE INVADA',
  title: 'SUPER POWER DJ BRAH',
  country: 'ITALY',
  age: 46,
  style: 'SILAT & BLADE',
  bio: 'THE SUPER POWER DJ BRAH BRINGS A DEADLY PRECISE COMBAT STYLE. MASTERING HIDDEN BLADES WITH BASS-DRIVEN ENERGY.',
  combo: 'H. BLADE  > > + 1 2',
};

export const RIVAL = {
  id: 'rivet',
  name: 'MC RIVET',
  title: 'NEON GHOST MC',
  country: 'NIGHT CITY',
  age: 31,
  style: 'BREAK & COUNTER',
};

export const ROSTER = [
  { id: 'face', name: 'FACE', locked: false },
  { id: 'vinyl', name: 'VINYL', locked: true },
  { id: 'kara', name: 'KARA', locked: true },
  { id: 'widow', name: 'WIDOW', locked: true },
  { id: 'rivet', name: 'RIVET', locked: true },
  { id: 'random', name: '?', locked: false },
];

export function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function framesPerBeat(bpm = BPM, fps = FPS) {
  return (fps * 60) / bpm;
}

export function beatAtFrame(frame, bpm = BPM, fps = FPS) {
  return (frame / fps) * (bpm / 60);
}

export function makeChart(seed = 7, beats = CHART_BEATS, countIn = COUNT_IN) {
  const rand = mulberry32(seed);
  const notes = [];
  for (let b = countIn; b < beats; b++) {
    const roll = rand();
    if (roll > 0.58) continue;
    let lane;
    if (rand() > 0.86) lane = 'bass';
    else if (rand() > 0.62) lane = 'blade';
    else if (rand() > 0.5) lane = 'kick';
    else lane = 'punch';
    if (notes.length && notes[notes.length - 1].beat === b) continue;
    notes.push({ id: notes.length, beat: b, lane, hit: false, grade: null });
  }
  return notes;
}

export function windowForGrade(grade) {
  if (grade === 'perfect') return PERFECT_WINDOW;
  if (grade === 'good') return GOOD_WINDOW;
  return 0;
}

export function gradeDelta(deltaBeat) {
  const ad = Math.abs(deltaBeat);
  if (ad <= PERFECT_WINDOW) return 'perfect';
  if (ad <= GOOD_WINDOW) return 'good';
  return null;
}

export function findHittable(notes, lane, currentBeat) {
  let best = null;
  let bestD = 99;
  for (const n of notes) {
    if (n.hit || n.lane !== lane) continue;
    const d = Math.abs(n.beat - currentBeat);
    if (d < bestD && d <= GOOD_WINDOW) {
      best = n;
      bestD = d;
    }
  }
  return best;
}

export function expireNotes(notes, currentBeat) {
  const missed = [];
  for (const n of notes) {
    if (n.hit) continue;
    if (currentBeat - n.beat > MISS_AFTER) {
      n.hit = true;
      n.grade = 'miss';
      missed.push(n);
    }
  }
  return missed;
}

export function loopBeat(beat, length = CHART_BEATS) {
  const span = length > 0 ? length : 1;
  const wrapped = ((beat % span) + span) % span;
  return { localBeat: wrapped, loop: Math.floor(beat / span) };
}

export function resetChartForLoop(notes) {
  for (const n of notes) {
    n.hit = false;
    n.grade = null;
  }
  return notes;
}

export function comboMult(combo) {
  if (combo >= 16) return 2.2;
  if (combo >= 8) return 1.6;
  if (combo >= 4) return 1.25;
  return 1;
}

export function hitDamage(grade, combo) {
  const base = grade === 'perfect' ? PERFECT_DMG : GOOD_DMG;
  return Math.round(base * comboMult(combo));
}

export function bassGain(grade) {
  if (grade === 'perfect') return 14;
  if (grade === 'good') return 8;
  return 0;
}

export function clamp(n, a, b) {
  return Math.max(a, Math.min(b, n));
}

export function applyPlayerHit(state, grade) {
  const combo = state.combo + 1;
  const dmg = hitDamage(grade, combo);
  const bass = clamp(state.bass + bassGain(grade), 0, 100);
  const score = state.score + (grade === 'perfect' ? 300 : 140) * combo;
  return {
    ...state,
    combo,
    maxCombo: Math.max(state.maxCombo, combo),
    bass,
    score,
    cpuHp: Math.max(0, state.cpuHp - dmg),
    lastGrade: grade,
    hits: state.hits + 1,
    perfects: state.perfects + (grade === 'perfect' ? 1 : 0),
  };
}

export function applyMiss(state) {
  return {
    ...state,
    combo: 0,
    playerHp: Math.max(0, state.playerHp - MISS_DMG),
    lastGrade: 'miss',
    misses: state.misses + 1,
  };
}

export function canSuper(bass) {
  return bass >= SUPER_COST;
}

export function applySuper(state) {
  if (!canSuper(state.bass)) return { ok: false, state };
  return {
    ok: true,
    state: {
      ...state,
      bass: 0,
      cpuHp: Math.max(0, state.cpuHp - SUPER_DMG),
      score: state.score + 1200,
      lastGrade: 'super',
      combo: state.combo + 1,
    },
  };
}

export function winnerOf(playerHp, cpuHp) {
  if (cpuHp <= 0 && playerHp <= 0) return 'draw';
  if (cpuHp <= 0) return 'face';
  if (playerHp <= 0) return 'rivet';
  return null;
}

export function emptyFightState() {
  return {
    playerHp: MAX_HP,
    cpuHp: CPU_HP,
    bass: 0,
    combo: 0,
    maxCombo: 0,
    score: 0,
    lastGrade: '',
    hits: 0,
    perfects: 0,
    misses: 0,
  };
}

export const CONTROL_MAP = {
  punch: 'KeyZ',
  kick: 'KeyX',
  blade: 'KeyC',
  bass: 'KeyV',
  start: 'Enter',
  left: 'KeyA',
  right: 'KeyD',
  up: 'KeyW',
  down: 'KeyS',
};

/**
 * CURIOUSLY STRONG ALL NIGHT LONG — homage structure, original street.
 * Mario walk/jump/stomp + packed combinable objects + sarcastic NPCs.
 * Android: walk, jump, tap to take/talk, bag USE to combine.
 */

export const NIGHT_W = 4200;
export const FLOOR_Y = 508;
export const GRAV = 0.75;
export const JUMP_V = -16.8;
export const RUN = 7.2;

export const BAG_X = 16;
export const BAG_Y = 78;
export const BAG_SLOT_W = 118;
export const BAG_SLOT_H = 40;
export const BAG_GAP = 6;
export const BAG_SLOTS = 10;

export const ITEM_LABEL = {
  mint: 'MINT TIN',
  gum: 'GUM',
  marker: 'MARKER',
  lighter: 'LIGHTER',
  cinnamon: 'CINNAMON',
  hotshot: 'HOT SHOT',
  keys: 'KEYS',
  battery: 'BATTERY',
  glow: 'GLOW STICK',
  lamp: 'LAMP',
  lipstick: 'LIPSTICK',
  wristband: 'WRISTBAND',
  matches: 'MATCHES',
  flyer: 'FLYER',
  coin: 'COIN',
  note: 'NOTE',
  badge: 'FAKE ID',
  spray: 'SPRAY',
};

export const RECIPES = [
  { need: ['glow', 'battery'], out: 'lamp', line: 'GLOW PLUS BATTERY. A LAMP. SCIENCE.' },
  { need: ['lighter', 'cinnamon'], out: 'hotshot', line: 'FIRE PLUS SPICE. DO NOT DRINK THIS.' },
  { need: ['matches', 'cinnamon'], out: 'hotshot', line: 'MATCHES PLUS SPICE. STILL A CRIME IN A CUP.' },
  { need: ['mint', 'gum', 'marker'], out: 'wristband', line: 'CURIOUSLY STRONG. ALL NIGHT LONG.' },
];

export const PLATFORMS = [
  { x: 180, y: 400, w: 160 },
  { x: 380, y: 320, w: 150 },
  { x: 560, y: 250, w: 140 },
  { x: 760, y: 360, w: 180 },
  { x: 1000, y: 280, w: 160 },
  { x: 1220, y: 360, w: 150 },
  { x: 1460, y: 270, w: 200 },
  { x: 1760, y: 340, w: 150 },
  { x: 1980, y: 250, w: 180 },
  { x: 2220, y: 320, w: 170 },
  { x: 2480, y: 240, w: 160 },
  { x: 2720, y: 330, w: 150 },
  { x: 2960, y: 260, w: 180 },
  { x: 3220, y: 350, w: 160 },
  { x: 3480, y: 280, w: 190 },
  { x: 3760, y: 380, w: 150 },
];

const START_PICKUPS = [
  { id: 'coin', x: 210, y: 480 },
  { id: 'flyer', x: 360, y: 480 },
  { id: 'mint', x: 260, y: 360 },
  { id: 'lighter', x: 450, y: 480 },
  { id: 'cinnamon', x: 820, y: 320 },
  { id: 'matches', x: 1120, y: 480 },
  { id: 'keys', x: 1060, y: 240 },
  { id: 'note', x: 1520, y: 230 },
  { id: 'battery', x: 1560, y: 230 },
  { id: 'glow', x: 2040, y: 210 },
  { id: 'lipstick', x: 2560, y: 200, dark: true },
  { id: 'spray', x: 2780, y: 290, dark: true },
  { id: 'badge', x: 3540, y: 480 },
];

export const NPCS = [
  {
    id: 'skater',
    paint: 'pipe',
    name: 'PIPE',
    x: 560,
    line: 'JUMP THE AWNINGS, CAP. GUM AINT FREE. BRIBE THE BAR WITH FIRE AND SPICE.',
  },
  {
    id: 'prophet',
    paint: 'mouth',
    name: 'MOUTH',
    x: 980,
    line: 'KEYS ON THE HIGH LEDGE. GLOW PLUS A DEAD BATTERY MAKES A LAMP. I PEAK AT 4AM.',
  },
  {
    id: 'bar',
    paint: 'brick',
    name: 'BRICK',
    x: 1680,
    line: 'I DONT SERVE DJS. UNLESS YOU INVENTED A CRIME IN A CUP.',
  },
  {
    id: 'nix',
    paint: 'nix',
    name: 'NIX',
    x: 2480,
    line: 'YOU ARE LATE AND YOUR SCARF IS TRYING TOO HARD. LIPSTICK. THEN MAYBE A MARKER.',
  },
  {
    id: 'bounce',
    paint: 'bolt',
    name: 'BOLT',
    x: 3920,
    line: 'NO BAND. NO ENTRY. CRAFT A WRISTBAND OR GO HOME TO YOUR VINYL.',
  },
];

export function emptyNightState() {
  return {
    px: 140,
    py: 0,
    vx: 0,
    vy: 0,
    facing: 1,
    onGround: true,
    grown: false,
    inv: [],
    selected: null,
    pickups: START_PICKUPS.map((p) => ({ ...p, got: false })),
    bats: [
      { x: 700, y: 340, vx: 2 },
      { x: 1400, y: 300, vx: -2.2 },
      { x: 2100, y: 260, vx: 2.4 },
      { x: 2900, y: 300, vx: -2 },
      { x: 3500, y: 320, vx: 2.1 },
    ],
    alleyLit: false,
    talked: {},
    banner: 'CURIOUSLY STRONG ALL NIGHT LONG. JUMP. GRAB. COMBINE.',
    log: 'WALK THE STREET. TAP STUFF. USE ITEMS ON PEOPLE.',
    won: false,
    dead: false,
  };
}

function clone(s) {
  return {
    ...s,
    inv: s.inv.slice(),
    pickups: s.pickups.map((p) => ({ ...p })),
    bats: s.bats.map((b) => ({ ...b })),
    talked: { ...s.talked },
  };
}

export function has(s, id) {
  return s.inv.includes(id);
}

export function nightCam(s, viewW = 1280) {
  return Math.max(0, Math.min(NIGHT_W - viewW, s.px - 400));
}

export function hitNightInv(x, y) {
  if (y < BAG_Y || y > BAG_Y + BAG_SLOT_H) return -1;
  const i = Math.floor((x - BAG_X) / (BAG_SLOT_W + BAG_GAP));
  if (i < 0 || i >= BAG_SLOTS) return -1;
  const sx = BAG_X + i * (BAG_SLOT_W + BAG_GAP);
  if (x < sx || x > sx + BAG_SLOT_W) return -1;
  return i;
}

function onPlatform(s) {
  const fx = s.px;
  const fy = FLOOR_Y + s.py;
  for (const p of PLATFORMS) {
    if (fx > p.x && fx < p.x + p.w && fy >= p.y - 8 && fy <= p.y + 14 && s.vy >= 0) {
      return p;
    }
  }
  return null;
}

export function tryRecipe(inv) {
  for (const r of RECIPES) {
    if (r.need.every((id) => inv.includes(id))) {
      const next = inv.filter((id) => !r.need.includes(id));
      next.push(r.out);
      return { inv: next, out: r.out, line: r.line };
    }
  }
  return null;
}

function give(s, id) {
  if (!s.inv.includes(id)) s.inv.push(id);
  s.selected = id;
}

function hiddenPickup(s, p) {
  return p.dark && !s.alleyLit;
}

export function stepNight(s, input) {
  if (s.won) return s;
  const next = clone(s);
  const dir = input.dir || 0;
  next.vx = dir * RUN * (next.grown ? 1.15 : 1);
  if (dir) next.facing = dir;
  next.px = Math.max(60, Math.min(NIGHT_W - 40, next.px + next.vx));

  if (input.jump && next.onGround) next.vy = JUMP_V * (next.grown ? 1.12 : 1);
  next.vy += GRAV;
  next.py += next.vy;

  const plat = onPlatform(next);
  if (plat && next.vy >= 0) {
    next.py = plat.y - FLOOR_Y;
    next.vy = 0;
    next.onGround = true;
  } else if (next.py >= 0) {
    next.py = 0;
    next.vy = 0;
    next.onGround = true;
  } else {
    next.onGround = false;
  }

  next.bats = next.bats.map((b) => {
    let x = b.x + b.vx;
    let vx = b.vx;
    if (x < 400 || x > 4000) vx *= -1;
    const stomp = Math.abs(next.px - x) < 36 && FLOOR_Y + next.py < b.y + 10 && next.vy > 0;
    if (stomp) {
      next.vy = -10;
      return { x: x + 420, y: b.y, vx };
    }
    if (Math.abs(next.px - x) < 28 && Math.abs(FLOOR_Y + next.py - 40 - b.y) < 36 && next.vy <= 0) {
      next.dead = true;
    }
    return { x, y: b.y, vx };
  });

  if (next.dead) {
    next.banner = 'A RAVE BAT ATE YOUR CAP. JUMP ON THEIR HEADS.';
    next.px = 140;
    next.py = 0;
    next.vy = 0;
    next.dead = false;
  }

  for (const p of next.pickups) {
    if (p.got || hiddenPickup(next, p)) continue;
    const near = Math.abs(next.px - p.x) < 48 && Math.abs(FLOOR_Y + next.py - 20 - p.y) < 56;
    if (near && (input.take || Math.abs(next.vy) < 1.2)) {
      p.got = true;
      give(next, p.id);
      next.banner = `TOOK ${ITEM_LABEL[p.id]}. TAP THE BAG, THEN USE.`;
      next.log = next.banner;
    }
  }

  if (input.look) lookNearest(next);
  if (input.talk) talkNearest(next);
  if (input.use) useSelected(next);

  if (has(next, 'wristband') && next.px > 4000) {
    next.won = true;
    next.banner = 'YOU ARE IN. CURIOUSLY STRONG. ALL NIGHT LONG.';
  }
  return next;
}

function nearestNpc(s) {
  let best = null;
  let d = 150;
  for (const n of NPCS) {
    const dd = Math.abs(s.px - n.x);
    if (dd < d) {
      best = n;
      d = dd;
    }
  }
  return best;
}

function nearestPickup(s) {
  let best = null;
  let d = 70;
  for (const p of s.pickups) {
    if (p.got || hiddenPickup(s, p)) continue;
    const dd = Math.hypot(s.px - p.x, FLOOR_Y + s.py - 20 - p.y);
    if (dd < d) {
      best = p;
      d = dd;
    }
  }
  return best;
}

export function lookNearest(s) {
  const n = nearestNpc(s);
  if (n) {
    s.banner = `${n.name} LOOKS LIKE TROUBLE WITH A PUNCHLINE. TALK THEM.`;
    s.log = s.banner;
    return s;
  }
  const p = nearestPickup(s);
  if (p) {
    s.banner = `${ITEM_LABEL[p.id]}. USEFUL. TAP TAKE OR WALK INTO IT.`;
    s.log = s.banner;
    return s;
  }
  s.banner = 'BRICK, NEON, AND BAD DECISIONS. KEEP WALKING.';
  return s;
}

export function talkNearest(s) {
  const n = nearestNpc(s);
  if (!n) {
    s.banner = 'NOBODY IN RANGE. WALK UP TO A FACE.';
    return s;
  }
  s.talked[n.id] = true;
  if (n.id === 'skater' && has(s, 'coin')) {
    s.banner = 'PIPE: A COIN. ROMANTIC. BAR WANTS FIRE PLUS SPICE. KEYS ARE UP HIGH.';
  } else if (n.id === 'bar' && has(s, 'hotshot')) {
    s.banner = 'BRICK: THAT SMELLS ILLEGAL. HERE. GUM. NOW LEAVE.';
    give(s, 'gum');
  } else if (n.id === 'nix' && has(s, 'lipstick')) {
    s.banner = 'NIX: GROSS. PERFECT. TAKE THE MARKER I STOLE FROM A TEEN.';
    give(s, 'marker');
  } else if (n.id === 'bounce' && has(s, 'wristband')) {
    s.banner = 'BOLT: FINE. YOU LOOK LIKE A MINT COMMERCIAL. GO IN.';
    s.px = 4050;
    s.won = true;
  } else if (n.id === 'bounce' && has(s, 'badge')) {
    s.banner = 'BOLT: THAT ID SAYS YOU ARE 12 AND A SENATOR. NO.';
  } else if (n.id === 'bounce' && has(s, 'flyer')) {
    s.banner = 'BOLT: PAPER IS NOT A BAND. CRAFT ONE. MINT. GUM. MARKER.';
  } else if (n.id === 'bounce' && has(s, 'mint') && has(s, 'gum') && has(s, 'marker')) {
    const r = tryRecipe(s.inv);
    if (r) {
      s.inv = r.inv;
      s.selected = r.out;
      s.banner = 'BOLT WATCHES YOU CRAFT A BAND. ' + r.line;
    }
  } else {
    s.banner = `${n.name}: ${n.line}`;
  }
  s.log = s.banner;
  return s;
}

export function useSelected(s) {
  if (!s.selected) {
    s.banner = 'TAP A BAG ITEM FIRST.';
    return s;
  }
  if (s.selected === 'mint') {
    s.grown = true;
    s.banner = 'PILLS THAT MAKE ME LARGER? YEAH RIGHT. STILL A MINT.';
    s.log = s.banner;
    return s;
  }
  if (s.selected === 'lamp') {
    s.alleyLit = true;
    s.banner = 'ALLEY LIGHTS UP. LIPSTICK WAS HIDING LIKE A COWARD.';
    return s;
  }
  if (s.selected === 'note') {
    s.banner = 'NOTE: MINT + GUM + MARKER = BAND. GLOW + BATTERY = LAMP.';
    return s;
  }
  if (s.selected === 'keys') {
    s.banner = 'KEYS TO NOTHING. A METAPHOR. ALSO THEY JINGLE SARCASTICALLY.';
    return s;
  }
  if (s.selected === 'spray') {
    s.banner = 'YOU TAG A WALL. ART. THE CITY DOES NOT CARE.';
    return s;
  }
  const crafted = tryRecipe(s.inv);
  if (crafted) {
    s.inv = crafted.inv;
    s.selected = crafted.out;
    s.banner = crafted.line;
    s.log = s.banner;
    if (crafted.out === 'lamp') s.alleyLit = true;
    return s;
  }
  return talkNearest(s);
}

export function tapNight(s, worldX, worldY) {
  const next = clone(s);
  for (const p of next.pickups) {
    if (p.got || hiddenPickup(next, p)) continue;
    if (Math.abs(worldX - p.x) < 56 && Math.abs(worldY - p.y) < 56) {
      next.px = p.x;
      return stepNight(next, { take: true });
    }
  }
  for (const n of NPCS) {
    if (Math.abs(worldX - n.x) < 64 && worldY > 280 && worldY < 540) {
      next.px = n.x;
      talkNearest(next);
      return next;
    }
  }
  return next;
}

export function selectNightItem(s, index) {
  const next = clone(s);
  const id = next.inv[index];
  if (!id) return next;
  next.selected = next.selected === id ? null : id;
  next.banner = next.selected
    ? `SELECTED ${ITEM_LABEL[id]}. USE ON A PERSON OR COMBINE.`
    : 'DESELECTED.';
  return next;
}

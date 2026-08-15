/**
 * Top-down night drive — GTA 2 homage structure, original streets.
 * Steer, accelerate, RAVE to grab speaker parts. No Rockstar assets.
 */

export const MAP_W = 2800;
export const MAP_H = 2800;
export const ROAD = 140;
export const BLOCK = 420;
export const PART_NEED = 5;

export const PART_LABEL = {
  woofer: 'WOOFER',
  tweeter: 'TWEETER',
  amp: 'AMP',
  cable: 'CABLE',
  sub: 'SUB',
};

export const PARTS = [
  { id: 'woofer', x: 520, y: 480 },
  { id: 'tweeter', x: 2100, y: 620 },
  { id: 'amp', x: 1400, y: 1680 },
  { id: 'cable', x: 680, y: 2200 },
  { id: 'sub', x: 2300, y: 1900 },
];

function buildings() {
  const list = [];
  for (let gy = 0; gy < 6; gy++) {
    for (let gx = 0; gx < 6; gx++) {
      const x = gx * BLOCK + ROAD;
      const y = gy * BLOCK + ROAD;
      const w = BLOCK - ROAD;
      const h = BLOCK - ROAD;
      if (w > 40 && h > 40) list.push({ x, y, w, h });
    }
  }
  return list;
}

export const BUILDINGS = buildings();

export function emptyDriveState() {
  return {
    x: 200,
    y: 200,
    ang: 0,
    vel: 0,
    rave: 0,
    frame: 0,
    got: 0,
    parts: PARTS.map((p) => ({ ...p, got: false })),
    traffic: [
      { x: 70, y: 800, ang: Math.PI / 2, vel: 3.2, c: '#ff4ad2' },
      { x: 900, y: 70, ang: 0, vel: 2.8, c: '#3df0ff' },
      { x: 2730, y: 1400, ang: -Math.PI / 2, vel: 3.4, c: '#ffe566' },
      { x: 1600, y: 2730, ang: Math.PI, vel: 2.6, c: '#7cff6b' },
    ],
    banner: 'RAVE TO GRAB SPEAKER PARTS. DONT KISS THE TOURIST CARS.',
    won: false,
    smashed: 0,
  };
}

function hitsBuilding(x, y) {
  for (const b of BUILDINGS) {
    if (x > b.x + 8 && x < b.x + b.w - 8 && y > b.y + 8 && y < b.y + b.h - 8) return true;
  }
  return false;
}

function wrap(n, max) {
  if (n < 40) return 40;
  if (n > max - 40) return max - 40;
  return n;
}

export function stepDrive(s, input) {
  if (s.won) return s;
  const next = {
    ...s,
    parts: s.parts.map((p) => ({ ...p })),
    traffic: s.traffic.map((t) => ({ ...t })),
  };
  next.frame += 1;
  const steer = input.steer || 0;
  const accel = input.accel || 0;
  next.ang += steer * 0.075 * (0.35 + Math.min(1, Math.abs(next.vel) / 6));
  next.vel += accel * 0.42;
  next.vel *= 0.97;
  if (next.vel > 9) next.vel = 9;
  if (next.vel < -3.5) next.vel = -3.5;

  const nx = wrap(next.x + Math.cos(next.ang) * next.vel, MAP_W);
  const ny = wrap(next.y + Math.sin(next.ang) * next.vel, MAP_H);
  if (hitsBuilding(nx, ny)) {
    next.vel *= -0.35;
    next.smashed += 1;
    next.banner = 'YOU HIT A BLOCK. THE BLOCK DID NOT CARE.';
  } else {
    next.x = nx;
    next.y = ny;
  }

  next.traffic = next.traffic.map((t) => {
    let x = t.x + Math.cos(t.ang) * t.vel;
    let y = t.y + Math.sin(t.ang) * t.vel;
    let ang = t.ang;
    if (x < 50 || x > MAP_W - 50 || y < 50 || y > MAP_H - 50 || hitsBuilding(x, y)) {
      ang += Math.PI / 2;
      x = wrap(t.x, MAP_W);
      y = wrap(t.y, MAP_H);
    }
    const hit = Math.hypot(x - next.x, y - next.y) < 36;
    if (hit) {
      next.vel *= 0.4;
      next.banner = 'TOURIST HONK. KEEP RAVING.';
    }
    return { ...t, x, y, ang };
  });

  if (input.rave) next.rave = 18;
  if (next.rave > 0) next.rave -= 1;

  const pulsing = next.frame % 28 < 10;
  if (next.rave > 0) {
    for (const p of next.parts) {
      if (p.got) continue;
      if (Math.hypot(p.x - next.x, p.y - next.y) < (pulsing ? 70 : 48)) {
        p.got = true;
        next.got += 1;
        next.banner = pulsing
          ? `RAVE CATCH ${PART_LABEL[p.id]}. ON THE BEAT.`
          : `GRABBED ${PART_LABEL[p.id]}. KEEP RAVING.`;
      }
    }
  }

  if (next.got >= PART_NEED) {
    next.won = true;
    next.banner = 'STACK IS LIVE. THE ISLAND CAN HEAR YOU.';
  }
  return next;
}

export function driveCam(s, viewW = 1280, viewH = 720) {
  return {
    x: Math.max(0, Math.min(MAP_W - viewW, s.x - viewW / 2)),
    y: Math.max(0, Math.min(MAP_H - viewH, s.y - viewH / 2)),
  };
}

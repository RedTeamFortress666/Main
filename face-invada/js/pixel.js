/**
 * 16-bit neon pixel helpers and FACE INVADA / MC RIVET sprites.
 */
export const FONT5 = {
  ' ': [0, 0, 0, 0, 0, 0, 0],
  A: [0x0e, 0x11, 0x11, 0x1f, 0x11, 0x11, 0x11],
  B: [0x1e, 0x11, 0x11, 0x1e, 0x11, 0x11, 0x1e],
  C: [0x0e, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0e],
  D: [0x1e, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1e],
  E: [0x1f, 0x10, 0x10, 0x1e, 0x10, 0x10, 0x1f],
  F: [0x1f, 0x10, 0x10, 0x1e, 0x10, 0x10, 0x10],
  G: [0x0e, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0e],
  H: [0x11, 0x11, 0x11, 0x1f, 0x11, 0x11, 0x11],
  I: [0x1f, 0x04, 0x04, 0x04, 0x04, 0x04, 0x1f],
  J: [0x01, 0x01, 0x01, 0x01, 0x11, 0x11, 0x0e],
  K: [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11],
  L: [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1f],
  M: [0x11, 0x1b, 0x15, 0x15, 0x11, 0x11, 0x11],
  N: [0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11],
  O: [0x0e, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0e],
  P: [0x1e, 0x11, 0x11, 0x1e, 0x10, 0x10, 0x10],
  Q: [0x0e, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0d],
  R: [0x1e, 0x11, 0x11, 0x1e, 0x14, 0x12, 0x11],
  S: [0x0e, 0x11, 0x10, 0x0e, 0x01, 0x11, 0x0e],
  T: [0x1f, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
  U: [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0e],
  V: [0x11, 0x11, 0x11, 0x11, 0x11, 0x0a, 0x04],
  W: [0x11, 0x11, 0x11, 0x15, 0x15, 0x1b, 0x11],
  X: [0x11, 0x11, 0x0a, 0x04, 0x0a, 0x11, 0x11],
  Y: [0x11, 0x11, 0x0a, 0x04, 0x04, 0x04, 0x04],
  Z: [0x1f, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1f],
  0: [0x0e, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0e],
  1: [0x04, 0x0c, 0x04, 0x04, 0x04, 0x04, 0x0e],
  2: [0x0e, 0x11, 0x01, 0x06, 0x08, 0x10, 0x1f],
  3: [0x0e, 0x11, 0x01, 0x06, 0x01, 0x11, 0x0e],
  4: [0x02, 0x06, 0x0a, 0x12, 0x1f, 0x02, 0x02],
  5: [0x1f, 0x10, 0x1e, 0x01, 0x01, 0x11, 0x0e],
  6: [0x06, 0x08, 0x10, 0x1e, 0x11, 0x11, 0x0e],
  7: [0x1f, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
  8: [0x0e, 0x11, 0x11, 0x0e, 0x11, 0x11, 0x0e],
  9: [0x0e, 0x11, 0x11, 0x0f, 0x01, 0x02, 0x0c],
  '!': [0x04, 0x04, 0x04, 0x04, 0x04, 0x00, 0x04],
  '?': [0x0e, 0x11, 0x01, 0x06, 0x04, 0x00, 0x04],
  '.': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04],
  ',': [0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x08],
  "'": [0x04, 0x04, 0x08, 0x00, 0x00, 0x00, 0x00],
  ':': [0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x00],
  '-': [0x00, 0x00, 0x00, 0x1f, 0x00, 0x00, 0x00],
  '/': [0x01, 0x02, 0x02, 0x04, 0x08, 0x08, 0x10],
  '+': [0x00, 0x04, 0x04, 0x1f, 0x04, 0x04, 0x00],
  '*': [0x00, 0x15, 0x0e, 0x1f, 0x0e, 0x15, 0x00],
  '>': [0x02, 0x06, 0x0e, 0x1e, 0x0e, 0x06, 0x02],
  '<': [0x08, 0x0c, 0x0e, 0x0f, 0x0e, 0x0c, 0x08],
  '&': [0x0c, 0x12, 0x14, 0x08, 0x15, 0x12, 0x0d],
};

export function pixelTextWidth(text, scale = 1) {
  return String(text).length * 6 * scale;
}

export function drawPixelText(ctx, text, x, y, scale = 2, color = '#fff', align = 'left') {
  const s = String(text).toUpperCase();
  const w = pixelTextWidth(s, scale);
  let ox = x;
  if (align === 'center') ox = Math.round(x - w / 2);
  if (align === 'right') ox = Math.round(x - w);
  ctx.fillStyle = color;
  for (let i = 0; i < s.length; i++) {
    const rows = FONT5[s[i]] || FONT5['?'] || FONT5[' '];
    for (let row = 0; row < 7; row++) {
      const bits = rows[row];
      for (let col = 0; col < 5; col++) {
        if (bits & (1 << (4 - col))) {
          ctx.fillRect(ox + (i * 6 + col) * scale, y + row * scale, scale, scale);
        }
      }
    }
  }
}

function rect(ctx, x, y, w, h, c) {
  ctx.fillStyle = c;
  ctx.fillRect(x | 0, y | 0, w | 0, h | 0);
}

export function drawNeonCity(ctx, w, h, t) {
  ctx.fillStyle = '#070614';
  ctx.fillRect(0, 0, w, h);
  const glow = 0.35 + Math.sin(t * 0.04) * 0.08;
  ctx.fillStyle = `rgba(180, 40, 220, ${0.12 + glow * 0.08})`;
  ctx.fillRect(0, 0, w, h * 0.55);

  for (let i = 0; i < 18; i++) {
    const bx = 20 + i * 72;
    const bh = 140 + ((i * 37) % 180);
    rect(ctx, bx, h - 210 - bh, 54, bh, i % 3 === 0 ? '#12101c' : '#0c0a16');
    for (let wy = 0; wy < 8; wy++) {
      const on = ((i * 3 + wy + (t / 20 | 0)) % 5) !== 0;
      rect(ctx, bx + 8, h - 210 - bh + 12 + wy * 16, 10, 8, on ? (i % 2 ? '#ff4ad2' : '#3df0ff') : '#1a1830');
      rect(ctx, bx + 28, h - 210 - bh + 12 + wy * 16, 10, 8, on ? '#ffe566' : '#1a1830');
    }
  }

  rect(ctx, 0, h - 210, w, 8, '#2a2040');
  rect(ctx, 0, h - 202, w, 202, '#12101a');
  for (let x = 0; x < w; x += 28) {
    rect(ctx, x, h - 202, 14, 4, '#1e1a2c');
  }
  ctx.fillStyle = `rgba(255, 80, 220, ${0.08 + glow * 0.05})`;
  ctx.fillRect(0, h - 202, w, 40);

  drawPixelText(ctx, 'TEKKEN-ESQUE', w - 24, h - 228, 2, '#ff4ad2', 'right');
  drawPixelText(ctx, 'NIGHT CITY', 24, 24, 2, '#3df0ff');
}

export const SPRITE_W = 56;
export const SPRITE_H = 88;

export function paintFaceInvada(ctx, pose = {}) {
  const punch = pose.punch || 0;
  const kick = pose.kick || 0;
  const blade = pose.blade || 0;
  const hit = pose.hit || 0;
  const walk = pose.walk || 0;
  const t = pose.t || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28 + Math.round(punch * 3 - hit * 3);
  const foot = SPRITE_H - 2;
  const step = Math.round(Math.sin(walk) * 4);

  const skin = '#e6c4a8';
  const skinSh = '#c9a288';
  const hair = '#1a1410';
  const jacket = '#1a1a1e';
  const jacketHi = '#2c2c32';
  const shirt = '#6a7380';
  const scarf = '#8ec4e8';
  const cap = '#3a3a40';
  const capHi = '#5a5a62';
  const pant = '#141418';
  const outline = '#0a0808';
  const rim = '#b8b8c0';
  const lens = '#1a1a1c';
  const stache = '#2a221c';

  const kExt = Math.round(kick * 12);
  const lLeg = step;
  const rLeg = -step + kExt;

  rect(ctx, cx - 11, foot - 24 + Math.max(0, lLeg), 10, 20, outline);
  rect(ctx, cx - 10, foot - 23 + Math.max(0, lLeg), 8, 18, pant);
  rect(ctx, cx + 2, foot - 24 + Math.max(0, rLeg), 10, 20, outline);
  rect(ctx, cx + 3, foot - 23 + Math.max(0, rLeg), 8, 18, pant);
  rect(ctx, cx - 12, foot - 6 + Math.max(0, lLeg), 12, 6, '#0c0c0e');
  rect(ctx, cx + 2, foot - 6 + Math.max(0, rLeg), 12, 6, '#0c0c0e');

  rect(ctx, cx - 13, foot - 52, 26, 30, outline);
  rect(ctx, cx - 12, foot - 51, 24, 28, jacket);
  rect(ctx, cx - 10, foot - 49, 8, 24, jacketHi);
  rect(ctx, cx - 4, foot - 48, 10, 22, shirt);
  rect(ctx, cx - 8, foot - 52, 18, 7, scarf);
  rect(ctx, cx + 4, foot - 48, 5, 14, scarf);
  rect(ctx, cx + 5, foot - 46, 3, 12, '#7ab0d4');

  const bx = cx - 18 - Math.round(blade * 8);
  rect(ctx, bx, foot - 48, 8, 16, outline);
  rect(ctx, bx + 1, foot - 47, 6, 14, jacket);
  rect(ctx, bx - 1, foot - 34, 7, 6, skin);
  const b1 = bx - 7 - Math.round(blade * 6);
  rect(ctx, b1, foot - 36, 11, 3, '#d8dee4');
  rect(ctx, b1 - 2, foot - 38, 6, 3, '#f0f4f8');
  rect(ctx, b1 + 7, foot - 35, 3, 3, '#8a2018');
  rect(ctx, b1 + 1, foot - 32, 9, 2, '#c8d0d8');
  rect(ctx, b1 + 6, foot - 31, 3, 2, '#8a2018');

  const ax = cx + 11 + Math.round(punch * 14);
  const ay = foot - 50 - Math.round(punch * 2);
  rect(ctx, ax, ay, 8, 17, outline);
  rect(ctx, ax + 1, ay + 1, 6, 15, jacket);
  rect(ctx, ax + 2, ay + 15, 8, 6, skin);
  rect(ctx, ax + 3, ay + 16, 2, 2, '#111');
  rect(ctx, ax + 6, ay + 16, 2, 2, '#111');

  const hx = cx;
  const hy = foot - 70;
  rect(ctx, hx - 10, hy + 2, 20, 18, outline);
  rect(ctx, hx - 9, hy + 3, 18, 16, skin);
  rect(ctx, hx - 8, hy + 14, 16, 4, skinSh);
  rect(ctx, hx - 6, hy + 10, 12, 3, stache);
  rect(ctx, hx - 5, hy + 11, 10, 2, stache);
  rect(ctx, hx - 1, hy + 13, 3, 3, stache);
  rect(ctx, hx - 11, hy - 5, 22, 10, outline);
  rect(ctx, hx - 10, hy - 4, 20, 8, cap);
  rect(ctx, hx - 8, hy - 7, 16, 4, capHi);
  rect(ctx, hx - 11, hy + 2, 22, 3, cap);
  rect(ctx, hx - 8, hy + 4, 7, 7, rim);
  rect(ctx, hx + 1, hy + 4, 7, 7, rim);
  rect(ctx, hx - 1, hy + 6, 2, 3, rim);
  rect(ctx, hx - 7, hy + 5, 5, 5, lens);
  rect(ctx, hx + 2, hy + 5, 5, 5, lens);
  rect(ctx, hx - 6, hy + 6, 2, 2, '#2a2a30');
  rect(ctx, hx + 3, hy + 6, 2, 2, '#2a2a30');
  rect(ctx, hx - 8, hy, 4, 3, hair);
  rect(ctx, hx + 5, hy, 4, 3, hair);
  if ((t | 0) % 50 < 3) {
    rect(ctx, hx - 3, hy + 16, 2, 1, '#b08070');
  }
}

export const ENEMY_PALETTES = {
  rivet: { coat: '#8a1230', hair: '#1a1018', skin: '#d2a07a', accent: '#f0e8ff' },
  vinyl: { coat: '#2a4a8a', hair: '#e8d080', skin: '#c49a72', accent: '#3df0ff' },
  kara: { coat: '#3a1840', hair: '#f0c0d0', skin: '#d8b090', accent: '#ff4ad2' },
  widow: { coat: '#101018', hair: '#f0f0f8', skin: '#c8b8b0', accent: '#b44cff' },
  stranger: { coat: '#1a1028', hair: '#080810', skin: '#6a6080', accent: '#ffe566' },
};

export function paintRival(ctx, pose = {}, enemyId = 'rivet') {
  const punch = pose.punch || 0;
  const hit = pose.hit || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const pal = ENEMY_PALETTES[enemyId] || ENEMY_PALETTES.rivet;
  const cx = 28 - Math.round(punch * 3 + hit * 4);
  const foot = SPRITE_H - 2;
  const skin = pal.skin;
  const coat = pal.coat;
  const hair = pal.hair;
  rect(ctx, cx - 9, foot - 22, 8, 20, '#1a1020');
  rect(ctx, cx + 3, foot - 22, 8, 20, '#1a1020');
  rect(ctx, cx - 11, foot - 50, 24, 30, '#050508');
  rect(ctx, cx - 10, foot - 49, 22, 28, coat);
  rect(ctx, cx - 6, foot - 46, 12, 8, pal.accent);
  const ax = cx - 16 - Math.round(punch * 12);
  rect(ctx, ax, foot - 46, 8, 16, coat);
  rect(ctx, ax, foot - 32, 7, 6, skin);
  rect(ctx, cx - 9, foot - 66, 18, 18, '#050508');
  rect(ctx, cx - 8, foot - 65, 16, 16, skin);
  rect(ctx, cx - 10, foot - 70, 20, 8, hair);
  rect(ctx, cx - 6, foot - 60, 12, 3, '#111');
}

let _sheet;
function sheet() {
  if (!_sheet) {
    _sheet = typeof document !== 'undefined' ? document.createElement('canvas') : { width: SPRITE_W, height: SPRITE_H, getContext: () => null };
    _sheet.width = SPRITE_W;
    _sheet.height = SPRITE_H;
  }
  return _sheet;
}

export function drawFighter(ctx, who, x, y, facing, pose, scale = 3) {
  const c = sheet();
  const octx = c.getContext && c.getContext('2d');
  if (!octx) return;
  octx.imageSmoothingEnabled = false;
  if (who === 'face') paintFaceInvada(octx, pose);
  else paintRival(octx, pose, who);
  ctx.save();
  ctx.imageSmoothingEnabled = false;
  ctx.translate(Math.round(x), Math.round(y));
  ctx.scale(facing * scale, scale);
  ctx.drawImage(c, -SPRITE_W / 2, -SPRITE_H);
  ctx.restore();
}

export const LANE_COLORS = {
  punch: '#ffe566',
  kick: '#ff6a3a',
  blade: '#c0c8d0',
  bass: '#b44cff',
};

export function drawHighway(ctx, notes, currentBeat, y0, w) {
  const hitX = 220;
  const pxPerBeat = 90;
  const lanes = ['punch', 'kick', 'blade', 'bass'];
  ctx.fillStyle = 'rgba(0,0,0,0.62)';
  ctx.fillRect(0, y0, w, 148);
  for (let i = 0; i < 4; i++) {
    const y = y0 + 10 + i * 34;
    ctx.fillStyle = '#1a1428';
    ctx.fillRect(40, y, w - 80, 26);
    ctx.fillStyle = LANE_COLORS[lanes[i]];
    ctx.fillRect(hitX - 8, y - 2, 12, 30);
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(hitX - 3, y + 4, 4, 16);
    drawPixelText(ctx, lanes[i].toUpperCase(), 48, y + 6, 1, LANE_COLORS[lanes[i]]);
  }
  for (const n of notes) {
    if (n.hit && n.grade !== 'miss') continue;
    const x = hitX + (n.beat - currentBeat) * pxPerBeat;
    if (x < 30 || x > w - 20) continue;
    const li = lanes.indexOf(n.lane);
    const y = y0 + 10 + li * 34;
    ctx.fillStyle = n.grade === 'miss' ? '#442222' : LANE_COLORS[n.lane];
    ctx.fillRect(x | 0, y + 4, 22, 22);
    ctx.fillStyle = '#fff';
    ctx.fillRect((x | 0) + 4, y + 8, 6, 6);
  }
}

export function lifeBarWidth(hp, max, barW) {
  const cur = Number.isFinite(hp) ? hp : max;
  const m = max > 0 ? max : 1;
  return Math.max(0, Math.min(barW, (cur / m) * barW));
}

const ROOM_FURNITURE = {
  lobby: [
    [48, 140, 200, 110, '#14301c'],
    [48, 300, 360, 160, '#2a2010'],
    [820, 170, 400, 280, '#1a3048'],
  ],
  hall: [
    [48, 140, 240, 90, '#243838'],
    [360, 180, 200, 250, '#3a2030'],
    [920, 200, 280, 230, '#2a1820'],
    [80, 450, 1080, 80, '#4a2030'],
  ],
  room101: [
    [48, 140, 360, 120, '#1a3040'],
    [48, 300, 520, 180, '#3a2840'],
    [600, 320, 220, 140, '#1a1a28'],
    [980, 170, 220, 280, '#202838'],
  ],
  maid: [
    [48, 200, 300, 250, '#c8b8a8'],
    [780, 260, 400, 180, '#2a2a20'],
  ],
  vent: [
    [48, 140, 320, 130, '#3a5048'],
    [460, 230, 360, 150, '#2a4850'],
    [80, 420, 1120, 100, '#1a2418'],
  ],
  bath: [
    [360, 140, 560, 110, '#8aa0b0'],
    [440, 350, 400, 140, '#1a2830'],
  ],
  kitchen: [
    [48, 170, 300, 300, '#203040'],
    [420, 300, 360, 160, '#304050'],
    [860, 220, 320, 180, '#402010'],
  ],
  cctv: [
    [80, 140, 1120, 180, '#102018'],
    [48, 350, 320, 140, '#1a1010'],
  ],
  penthouse: [
    [420, 140, 440, 130, '#4a1838'],
    [48, 330, 320, 150, '#2a1810'],
    [960, 170, 240, 300, '#181018'],
  ],
  closet: [
    [48, 160, 320, 320, '#201818'],
    [440, 240, 380, 160, '#8a9098'],
    [880, 390, 320, 100, '#141414'],
  ],
  roof: [
    [40, 130, 1200, 90, '#0a1028'],
    [360, 230, 640, 220, '#3a3020'],
  ],
};

export function drawMysteryRoom(ctx, room, t) {
  ctx.fillStyle = room.color || '#0b1020';
  ctx.fillRect(0, 118, 1280, 422);
  ctx.fillStyle = '#12101a';
  ctx.fillRect(0, 500, 1280, 40);
  ctx.fillStyle = '#2a2040';
  ctx.fillRect(0, 498, 1280, 4);
  drawPixelText(ctx, '<< WALK', 16, 508, 1, '#ffe566');
  drawPixelText(ctx, 'WALK >>', 1160, 508, 1, '#ffe566');
  const pulse = 0.45 + Math.sin(t * 0.12) * 0.12;
  const furniture = ROOM_FURNITURE[room.id] || [];
  for (const [x, y, w, h, c] of furniture) {
    rect(ctx, x, y, w, h, c);
  }
  for (const hs of room.hotspots) {
    ctx.strokeStyle = `rgba(61, 240, 255, ${pulse})`;
    ctx.lineWidth = 3;
    ctx.strokeRect(hs.x + 2, hs.y + 2, hs.w - 4, hs.h - 4);
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    ctx.fillRect(hs.x + 6, hs.y + 6, Math.min(hs.w - 12, 240), 22);
    drawPixelText(ctx, hs.label, hs.x + 10, hs.y + 10, 1, '#3df0ff');
  }
}

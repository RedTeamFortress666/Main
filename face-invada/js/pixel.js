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

export function drawClueBanner(ctx, text, t) {
  const pulse = 0.75 + Math.sin(t * 0.15) * 0.15;
  ctx.fillStyle = `rgba(255, 229, 102, ${0.18 + pulse * 0.08})`;
  ctx.fillRect(8, 8, 1264, 72);
  ctx.fillStyle = '#120c00';
  ctx.fillRect(12, 12, 1256, 64);
  ctx.strokeStyle = '#ffe566';
  ctx.lineWidth = 3;
  ctx.strokeRect(12, 12, 1256, 64);
  const s = String(text || '').toUpperCase();
  const words = s.split(' ');
  let line = '';
  let ly = 20;
  let lines = 0;
  for (const w of words) {
    const test = `${line}${w} `;
    if (test.length * 12 > 1220) {
      drawPixelText(ctx, line, 24, ly, 2, '#ffe566');
      line = `${w} `;
      ly += 22;
      lines += 1;
      if (lines >= 2) break;
    } else line = test;
  }
  if (lines < 2) drawPixelText(ctx, line, 24, ly, 2, '#fff4c2');
}

export function drawFaceHead(ctx, x, y, scale, t) {
  ctx.save();
  ctx.translate(x, y);
  ctx.scale(scale, scale);
  rect(ctx, -10, -10, 20, 18, '#0a0808');
  rect(ctx, -9, -9, 18, 16, '#e6c4a8');
  rect(ctx, -11, -16, 22, 8, '#3a3a40');
  rect(ctx, -8, -18, 16, 4, '#5a5a62');
  rect(ctx, -8, -6, 7, 6, '#b8b8c0');
  rect(ctx, 1, -6, 7, 6, '#b8b8c0');
  rect(ctx, -7, -5, 5, 4, '#1a1a1c');
  rect(ctx, 2, -5, 5, 4, '#1a1a1c');
  rect(ctx, -6, 2, 12, 2, '#2a221c');
  rect(ctx, -1, 4, 3, 3, '#2a221c');
  if ((t | 0) % 20 < 3) rect(ctx, -3, 8, 2, 1, '#b08070');
  ctx.restore();
}

export function drawRaveVampire(ctx, x, y, scale, scared) {
  ctx.save();
  ctx.translate(x, y);
  ctx.scale(scale, scale);
  rect(ctx, -9, -10, 18, 18, scared ? '#3df0ff' : '#6a1030');
  rect(ctx, -6, -6, 4, 4, '#ffe566');
  rect(ctx, 2, -6, 4, 4, '#ffe566');
  rect(ctx, -3, 4, 2, 4, '#fff');
  rect(ctx, 1, 4, 2, 4, '#fff');
  ctx.restore();
}

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

/** Packed Mario-night street — original blocks, signs, bins, neon. */
export function paintNightStreet(ctx, t, camX, worldW, alleyLit) {
  const sky = ctx.createLinearGradient(0, 0, 0, 720);
  sky.addColorStop(0, '#050214');
  sky.addColorStop(0.55, '#140628');
  sky.addColorStop(1, '#2a0830');
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, 1280, 720);

  for (let i = 0; i < 90; i++) {
    const sx = ((i * 137 - camX * 0.12) % 1400 + 1400) % 1400 - 40;
    const sy = 20 + ((i * 53) % 280);
    ctx.fillStyle = i % 7 === 0 ? '#ffe566' : '#fff';
    ctx.fillRect(sx, sy, 2, 2);
  }

  for (let i = 0; i < 12; i++) {
    const bx = i * 380 - (camX * 0.35) % 380;
    const h = 220 + (i % 4) * 40;
    rect(ctx, bx, 508 - h, 160, h, i % 2 ? '#1a1030' : '#120c24');
    for (let wy = 0; wy < 5; wy++) {
      for (let wx = 0; wx < 3; wx++) {
        const on = (i + wx + wy + Math.floor(t / 20)) % 4 !== 0;
        rect(ctx, bx + 18 + wx * 46, 508 - h + 20 + wy * 36, 22, 18, on ? '#ffe566' : '#221833');
      }
    }
  }

  rect(ctx, 0, 508, 1280, 212, '#141018');
  for (let i = 0; i < 24; i++) {
    const tx = ((i * 80 - camX) % 1280 + 1280) % 1280;
    rect(ctx, tx, 508, 46, 10, '#2a2038');
    rect(ctx, tx + 8, 518, 30, 6, '#1a1428');
  }

  const worldToScreen = (wx) => wx - camX;
  const props = [
    [80, 430, 70, 78, '#3a2418', 'BIN'],
    [220, 400, 90, 108, '#4a2010', 'BOX'],
    [400, 440, 50, 68, '#2a2030', 'METER'],
    [640, 390, 36, 118, '#2a2a2a', 'POLE'],
    [720, 360, 40, 148, '#2a2a2a', 'POLE'],
    [880, 450, 60, 58, '#3a2418', 'BIN'],
    [1100, 420, 80, 88, '#6a1818', 'FIRE'],
    [1320, 430, 70, 78, '#201018', 'CRATE'],
    [1480, 380, 220, 128, '#201018', 'BAR'],
    [1860, 440, 48, 68, '#2a2030', 'METER'],
    [2100, 300, 50, 208, '#1a1a22', 'LAMP'],
    [2320, 420, 80, 88, '#302010', 'BENCH'],
    [2680, 410, 90, 98, '#302010', 'DUMP'],
    [3100, 250, 280, 80, '#ff2bd6', 'CLUB'],
    [3420, 430, 70, 78, '#3a2418', 'BIN'],
    [3600, 200, 40, 308, '#222', 'ROPE'],
    [3780, 360, 90, 148, '#1a1020', 'DOOR'],
  ];
  for (const [wx, y, w, h, c, lab] of props) {
    const x = worldToScreen(wx);
    if (x < -300 || x > 1400) continue;
    rect(ctx, x, y, w, h, c);
    if (lab === 'CLUB') {
      drawPixelText(ctx, 'CLUB NIGHTCLUB', x + 10, y + 28, 2, '#ffe566');
      drawPixelText(ctx, 'TONIGHT ONLY', x + 40, y + 52, 1, '#3df0ff');
    } else if (lab === 'BAR') {
      drawPixelText(ctx, 'BRICKS', x + 50, y + 16, 2, '#ff6b6b');
    } else if (lab === 'FIRE') {
      const flick = 0.5 + Math.sin(t * 0.3) * 0.3;
      ctx.fillStyle = `rgba(255,120,40,${flick})`;
      ctx.fillRect(x + 10, y - 20, 60, 24);
    } else if (lab === 'DOOR') {
      drawPixelText(ctx, 'IN', x + 28, y + 60, 2, '#ffe566');
    } else if (lab === 'BIN' || lab === 'BOX' || lab === 'DUMP') {
      drawPixelText(ctx, lab, x + 8, y + 10, 1, '#ffe566');
    }
  }

  if (!alleyLit) {
    ctx.fillStyle = 'rgba(0,0,0,0.72)';
    ctx.fillRect(worldToScreen(2550), 200, 420, 320);
    drawPixelText(ctx, 'DARK ALLEY', worldToScreen(2660), 340, 2, '#666');
  } else {
    ctx.fillStyle = 'rgba(255,230,100,0.12)';
    ctx.fillRect(worldToScreen(2550), 200, 420, 320);
  }

  for (let i = 0; i < 8; i++) {
    const px = worldToScreen(400 + i * 480);
    rect(ctx, px, 360, 120, 18, '#6a3a18');
    rect(ctx, px + 8, 348, 104, 14, '#8a5020');
  }
}

/** 56x88 street NPCs — same pixel budget as Face Invada. */
export function paintPipe(ctx, pose = {}) {
  const t = pose.t || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28;
  const foot = SPRITE_H - 2;
  const step = Math.round(Math.sin((t || 0) * 0.12) * 3);
  const skin = '#e8c4a8';
  const skinSh = '#c9a288';
  rect(ctx, cx - 11, foot - 24 + step, 10, 20, '#0a0808');
  rect(ctx, cx - 10, foot - 23 + step, 8, 18, '#3a2a18');
  rect(ctx, cx + 2, foot - 24 - step, 10, 20, '#0a0808');
  rect(ctx, cx + 3, foot - 23 - step, 8, 18, '#3a2a18');
  rect(ctx, cx - 12, foot - 6 + step, 14, 6, '#c44');
  rect(ctx, cx + 2, foot - 6 - step, 14, 6, '#c44');
  rect(ctx, cx - 13, foot - 52, 26, 30, '#0a0808');
  rect(ctx, cx - 12, foot - 51, 24, 28, '#c44');
  rect(ctx, cx - 10, foot - 48, 8, 22, '#e05050');
  rect(ctx, cx - 4, foot - 46, 10, 16, '#111');
  rect(ctx, cx - 8, foot - 40, 16, 4, '#888');
  const ax = cx + 12;
  rect(ctx, ax, foot - 50, 8, 16, '#0a0808');
  rect(ctx, ax + 1, foot - 49, 6, 14, '#c44');
  rect(ctx, ax + 2, foot - 35, 10, 5, skin);
  rect(ctx, cx - 18, foot - 48, 8, 16, '#0a0808');
  rect(ctx, cx - 17, foot - 47, 6, 14, '#c44');
  rect(ctx, cx - 22, foot - 36, 16, 5, '#6a6a70');
  rect(ctx, cx - 20, foot - 38, 12, 3, '#888');
  const hx = cx;
  const hy = foot - 70;
  rect(ctx, hx - 10, hy + 2, 20, 18, '#0a0808');
  rect(ctx, hx - 9, hy + 3, 18, 16, skin);
  rect(ctx, hx - 8, hy + 14, 16, 4, skinSh);
  rect(ctx, hx - 5, hy + 12, 10, 2, '#2a221c');
  rect(ctx, hx - 4, hy + 16, 8, 2, '#8a4030');
  rect(ctx, hx - 11, hy - 4, 22, 10, '#0a0808');
  rect(ctx, hx - 10, hy - 3, 20, 8, '#2a1810');
  rect(ctx, hx - 6, hy - 6, 12, 4, '#3a2418');
  rect(ctx, hx - 7, hy + 6, 5, 5, '#111');
  rect(ctx, hx + 2, hy + 6, 5, 5, '#111');
  rect(ctx, hx - 6, hy + 7, 2, 2, '#3df0ff');
  rect(ctx, hx + 3, hy + 7, 2, 2, '#3df0ff');
}

export function paintMouth(ctx, pose = {}) {
  const t = pose.t || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28;
  const foot = SPRITE_H - 2;
  const bob = Math.round(Math.sin(t * 0.08) * 2);
  const skin = '#d4a888';
  rect(ctx, cx - 10, foot - 22 + bob, 9, 20, '#1a1020');
  rect(ctx, cx + 3, foot - 22 - bob, 9, 20, '#1a1020');
  rect(ctx, cx - 12, foot - 6 + bob, 12, 6, '#4a2060');
  rect(ctx, cx + 2, foot - 6 - bob, 12, 6, '#4a2060');
  rect(ctx, cx - 14, foot - 54, 28, 34, '#0a0808');
  rect(ctx, cx - 13, foot - 53, 26, 32, '#4a2060');
  rect(ctx, cx - 10, foot - 50, 20, 18, '#2a1040');
  rect(ctx, cx - 8, foot - 46, 16, 6, '#8b1e3f');
  rect(ctx, cx - 16, foot - 48, 6, 20, '#6a3080');
  rect(ctx, cx + 12, foot - 48, 6, 20, '#6a3080');
  rect(ctx, cx - 18, foot - 36, 6, 6, '#c9a050');
  rect(ctx, cx + 14, foot - 36, 6, 6, '#c9a050');
  const hx = cx;
  const hy = foot - 72;
  rect(ctx, hx - 11, hy + 2, 22, 20, '#0a0808');
  rect(ctx, hx - 10, hy + 3, 20, 18, skin);
  rect(ctx, hx - 12, hy - 6, 24, 12, '#111');
  rect(ctx, hx - 8, hy - 8, 16, 4, '#222');
  rect(ctx, hx - 7, hy + 6, 5, 4, '#111');
  rect(ctx, hx + 2, hy + 6, 5, 4, '#111');
  rect(ctx, hx - 6, hy + 12, 14, 8, '#8b1e3f');
  rect(ctx, hx - 4, hy + 14, 10, 4, '#fff4c2');
  if ((t | 0) % 40 < 8) rect(ctx, hx - 3, hy + 15, 8, 3, '#3df0ff');
}

export function paintBrick(ctx, pose = {}) {
  const t = pose.t || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28;
  const foot = SPRITE_H - 2;
  const skin = '#c88870';
  const skinSh = '#a06850';
  rect(ctx, cx - 10, foot - 22, 9, 20, '#1a1020');
  rect(ctx, cx + 3, foot - 22, 9, 20, '#1a1020');
  rect(ctx, cx - 12, foot - 6, 12, 6, '#3a2010');
  rect(ctx, cx + 2, foot - 6, 12, 6, '#3a2010');
  rect(ctx, cx - 14, foot - 54, 28, 34, '#0a0808');
  rect(ctx, cx - 13, foot - 53, 26, 32, '#8b1e3f');
  rect(ctx, cx - 8, foot - 48, 16, 20, '#fff8e8');
  rect(ctx, cx - 6, foot - 40, 12, 8, '#8b1e3f');
  rect(ctx, cx + 12, foot - 50, 8, 18, '#8b1e3f');
  rect(ctx, cx + 13, foot - 34, 10, 8, '#fff8e8');
  rect(ctx, cx - 18, foot - 48, 8, 16, '#8b1e3f');
  rect(ctx, cx - 17, foot - 34, 7, 6, skin);
  const hx = cx;
  const hy = foot - 70;
  rect(ctx, hx - 10, hy + 2, 20, 18, '#0a0808');
  rect(ctx, hx - 9, hy + 3, 18, 16, skin);
  rect(ctx, hx - 8, hy + 14, 16, 4, skinSh);
  rect(ctx, hx - 6, hy + 11, 12, 3, '#3a2010');
  rect(ctx, hx - 1, hy + 14, 3, 3, '#3a2010');
  rect(ctx, hx - 10, hy - 2, 20, 8, '#3a2010');
  rect(ctx, hx - 6, hy - 4, 12, 4, '#4a2a14');
  rect(ctx, hx - 7, hy + 6, 5, 5, '#111');
  rect(ctx, hx + 2, hy + 6, 5, 5, '#111');
  rect(ctx, hx - 6, hy + 7, 2, 2, '#ffe566');
  if ((t | 0) % 60 < 4) rect(ctx, hx - 3, hy + 16, 2, 1, '#8a4030');
}

export function paintNix(ctx, pose = {}) {
  const t = pose.t || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28;
  const foot = SPRITE_H - 2;
  const step = Math.round(Math.sin(t * 0.1) * 2);
  const skin = '#f0d0c0';
  rect(ctx, cx - 10, foot - 24 + step, 9, 22, '#0a0808');
  rect(ctx, cx - 9, foot - 23 + step, 7, 20, '#111');
  rect(ctx, cx + 3, foot - 24 - step, 9, 22, '#0a0808');
  rect(ctx, cx + 4, foot - 23 - step, 7, 20, '#111');
  rect(ctx, cx - 12, foot - 6 + step, 12, 6, '#ff2bd6');
  rect(ctx, cx + 2, foot - 6 - step, 12, 6, '#ff2bd6');
  rect(ctx, cx - 13, foot - 54, 26, 32, '#0a0808');
  rect(ctx, cx - 12, foot - 53, 24, 30, '#111');
  rect(ctx, cx - 8, foot - 48, 16, 14, '#ff2bd6');
  rect(ctx, cx - 6, foot - 44, 12, 4, '#111');
  rect(ctx, cx + 11, foot - 50, 8, 16, '#111');
  rect(ctx, cx + 12, foot - 36, 8, 6, skin);
  rect(ctx, cx - 18, foot - 50, 8, 16, '#111');
  rect(ctx, cx - 20, foot - 40, 6, 14, '#ff2bd6');
  const hx = cx;
  const hy = foot - 72;
  rect(ctx, hx - 10, hy + 4, 20, 18, '#0a0808');
  rect(ctx, hx - 9, hy + 5, 18, 16, skin);
  rect(ctx, hx - 12, hy - 6, 6, 16, '#111');
  rect(ctx, hx - 4, hy - 10, 5, 14, '#111');
  rect(ctx, hx + 4, hy - 8, 6, 16, '#111');
  rect(ctx, hx + 10, hy - 2, 5, 12, '#111');
  rect(ctx, hx - 8, hy + 2, 16, 4, '#ff2bd6');
  rect(ctx, hx - 5, hy + 12, 10, 3, '#8b1e3f');
  rect(ctx, hx - 7, hy + 8, 5, 5, '#111');
  rect(ctx, hx + 2, hy + 8, 5, 5, '#111');
  rect(ctx, hx - 6, hy + 9, 2, 2, '#ff2bd6');
  rect(ctx, hx - 4, hy + 18, 8, 3, '#111');
}

export function paintBolt(ctx, pose = {}) {
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28;
  const foot = SPRITE_H - 2;
  const skin = '#8a6048';
  rect(ctx, cx - 12, foot - 26, 11, 24, '#0a0808');
  rect(ctx, cx - 11, foot - 25, 9, 22, '#222');
  rect(ctx, cx + 3, foot - 26, 11, 24, '#0a0808');
  rect(ctx, cx + 4, foot - 25, 9, 22, '#222');
  rect(ctx, cx - 14, foot - 6, 14, 6, '#111');
  rect(ctx, cx + 2, foot - 6, 14, 6, '#111');
  rect(ctx, cx - 16, foot - 58, 32, 36, '#0a0808');
  rect(ctx, cx - 15, foot - 57, 30, 34, '#111');
  rect(ctx, cx - 10, foot - 50, 20, 16, '#ffe566');
  rect(ctx, cx - 6, foot - 46, 12, 8, '#111');
  rect(ctx, cx - 20, foot - 54, 8, 22, '#111');
  rect(ctx, cx + 14, foot - 54, 8, 22, '#111');
  rect(ctx, cx - 19, foot - 34, 8, 6, skin);
  rect(ctx, cx + 13, foot - 34, 8, 6, skin);
  const hx = cx;
  const hy = foot - 74;
  rect(ctx, hx - 12, hy + 4, 24, 20, '#0a0808');
  rect(ctx, hx - 11, hy + 5, 22, 18, skin);
  rect(ctx, hx - 10, hy + 2, 20, 6, '#111');
  rect(ctx, hx - 8, hy + 8, 6, 6, '#111');
  rect(ctx, hx + 2, hy + 8, 6, 6, '#111');
  rect(ctx, hx + 10, hy + 10, 4, 4, '#3df0ff');
  rect(ctx, hx - 4, hy + 16, 8, 3, '#3a2010');
}

export function drawNightNpc(ctx, paintId, x, y, facing, pose, scale = 2.6) {
  const c = sheet();
  const octx = c.getContext && c.getContext('2d');
  if (!octx) return;
  octx.imageSmoothingEnabled = false;
  const fn = NIGHT_NPC_PAINT[paintId] || paintPipe;
  fn(octx, pose);
  ctx.save();
  ctx.imageSmoothingEnabled = false;
  ctx.translate(Math.round(x), Math.round(y));
  const s = paintId === 'bolt' ? scale * 1.22 : scale;
  ctx.scale(facing * s, s);
  ctx.drawImage(c, -SPRITE_W / 2, -SPRITE_H);
  ctx.restore();
}

export function paintPickup(ctx, x, y, id, t) {
  const bob = Math.sin(t * 0.15 + x * 0.02) * 6;
  const colors = {
    biscuit: '#7cff6b',
    lighter: '#ff8844',
    cinnamon: '#c44',
    keys: '#ffe566',
    battery: '#3df0ff',
    glow: '#9b6bff',
    lipstick: '#ff2bd6',
    gum: '#ff88aa',
    marker: '#ffe566',
    lamp: '#fff8a0',
    hotshot: '#ff6b6b',
    wristband: '#7cff6b',
    matches: '#ffaa44',
    flyer: '#fff4c2',
    coin: '#ffe566',
    note: '#e8d080',
    badge: '#c0c8d0',
    spray: '#3df0ff',
  };
  const py = y + bob;
  ctx.fillStyle = '#0a0808';
  ctx.fillRect(x - 12, py - 12, 24, 24);
  ctx.fillStyle = colors[id] || '#fff';
  ctx.fillRect(x - 10, py - 10, 20, 20);
  ctx.strokeStyle = '#fff';
  ctx.lineWidth = 2;
  ctx.strokeRect(x - 10, py - 10, 20, 20);
}

export function paintRaveBat(ctx, x, y, t, facing = 1) {
  const flap = Math.sin(t * 0.4) * 8;
  ctx.save();
  ctx.translate(x, y);
  ctx.scale(facing, 1);
  ctx.fillStyle = '#2a1040';
  ctx.fillRect(-18, -4 + flap, 16, 8);
  ctx.fillRect(4, -4 - flap, 16, 8);
  ctx.fillStyle = '#ff2bd6';
  ctx.fillRect(-8, -8, 16, 16);
  ctx.fillStyle = '#ffe566';
  ctx.fillRect(-4, -4, 3, 3);
  ctx.fillRect(2, -4, 3, 3);
  ctx.restore();
}

export const NIGHT_NPC_PAINT = {
  pipe: paintPipe,
  mouth: paintMouth,
  brick: paintBrick,
  nix: paintNix,
  bolt: paintBolt,
};

export function paintGrass(ctx, x, y, w, t) {
  for (let i = 0; i < w; i += 10) {
    const h = 16 + ((i + (t | 0)) % 7);
    ctx.fillStyle = i % 20 === 0 ? '#3dcc5a' : '#2a8840';
    ctx.fillRect(x + i, y - h, 6, h);
  }
}

export function paintSpring(ctx, x, y, t) {
  const squash = 4 + Math.round(Math.abs(Math.sin(t * 0.2)) * 6);
  ctx.fillStyle = '#c0c8d0';
  ctx.fillRect(x - 16, y - squash - 8, 32, 8);
  ctx.fillStyle = '#ff4ad2';
  ctx.fillRect(x - 14, y - squash, 28, squash);
}

export function paintWarpPipe(ctx, x, y) {
  ctx.fillStyle = '#1a6a28';
  ctx.fillRect(x - 22, y - 70, 44, 70);
  ctx.fillStyle = '#2a9a38';
  ctx.fillRect(x - 28, y - 84, 56, 20);
  ctx.fillStyle = '#0a3010';
  ctx.fillRect(x - 12, y - 78, 24, 10);
}

export function paintBeat(ctx, id, x, y, t, facing = 1) {
  const bob = Math.sin(t * 0.2 + x * 0.01) * 4;
  ctx.save();
  ctx.translate(x, y + bob);
  ctx.scale(facing, 1);
  if (id === 'ravebug' || id === 'mintmite') {
    ctx.fillStyle = '#0a0808';
    ctx.fillRect(-12, -10, 24, 20);
    ctx.fillStyle = '#7cff6b';
    ctx.fillRect(-10, -8, 20, 16);
    ctx.fillStyle = '#111';
    ctx.fillRect(-6, -4, 3, 3);
    ctx.fillRect(3, -4, 3, 3);
    ctx.fillStyle = '#ffe566';
    ctx.fillRect(-2, 2, 4, 3);
  } else if (id === 'spicegrub') {
    ctx.fillStyle = '#8b1e3f';
    ctx.fillRect(-14, -8, 28, 16);
    ctx.fillStyle = '#c44';
    ctx.fillRect(-12, -6, 24, 12);
    ctx.fillStyle = '#111';
    ctx.fillRect(4, -3, 3, 3);
  } else if (id === 'glowbat' || id === 'bassling') {
    paintRaveBat(ctx, 0, 0, t, 1);
    if (id === 'bassling') {
      ctx.fillStyle = '#3df0ff';
      ctx.fillRect(-6, -6, 12, 12);
    }
  } else if (id === 'brewcrab') {
    ctx.fillStyle = '#6a4010';
    ctx.fillRect(-14, -10, 28, 18);
    ctx.fillStyle = '#c8b070';
    ctx.fillRect(-8, -18, 16, 10);
    ctx.fillStyle = '#111';
    ctx.fillRect(-6, -4, 3, 3);
    ctx.fillRect(3, -4, 3, 3);
    ctx.fillStyle = '#3a2010';
    ctx.fillRect(-18, -2, 8, 4);
    ctx.fillRect(10, -2, 8, 4);
  } else if (id === 'glazemoth') {
    ctx.fillStyle = '#e87880';
    ctx.fillRect(-16, -8 + Math.sin(t * 0.3) * 3, 12, 10);
    ctx.fillRect(4, -8 - Math.sin(t * 0.3) * 3, 12, 10);
    ctx.fillStyle = '#fff4c2';
    ctx.fillRect(-6, -6, 12, 12);
  } else {
    ctx.fillStyle = '#0a0808';
    ctx.fillRect(-10, -16, 20, 28);
    ctx.fillStyle = '#ffe566';
    ctx.fillRect(-8, -14, 16, 24);
    ctx.fillStyle = '#120c00';
    ctx.fillRect(-4, -6, 8, 8);
  }
  ctx.restore();
}

export function paintStreetCar(ctx, x, y, locked) {
  ctx.fillStyle = '#0a0808';
  ctx.fillRect(x - 70, y - 38, 140, 40);
  ctx.fillStyle = locked ? '#3a2030' : '#ff2bd6';
  ctx.fillRect(x - 66, y - 34, 132, 32);
  ctx.fillStyle = '#3df0ff';
  ctx.fillRect(x - 20, y - 28, 50, 16);
  ctx.fillStyle = '#111';
  ctx.fillRect(x - 48, y - 8, 18, 18);
  ctx.fillRect(x + 28, y - 8, 18, 18);
  ctx.fillStyle = locked ? '#ffe566' : '#7cff6b';
}

export function paintIslander(ctx, x, y, t) {
  const bob = Math.sin(t * 0.1) * 2;
  ctx.fillStyle = '#5a3a28';
  ctx.fillRect(x - 12, y - 70 + bob, 24, 22);
  ctx.fillStyle = '#c88870';
  ctx.fillRect(x - 10, y - 68 + bob, 20, 18);
  ctx.fillStyle = '#2a1810';
  ctx.fillRect(x - 16, y - 48 + bob, 32, 30);
  ctx.fillStyle = '#e87880';
  ctx.fillRect(x - 8, y - 40 + bob, 16, 10);
  ctx.fillStyle = '#1a1020';
  ctx.fillRect(x - 12, y - 18 + bob, 10, 20);
  ctx.fillRect(x + 2, y - 18 + bob, 10, 20);
}

export function paintDonut(ctx, x, y, t) {
  const bob = Math.sin(t * 0.2) * 3;
  ctx.fillStyle = '#e87880';
  ctx.beginPath();
  ctx.arc(x, y + bob, 12, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#1a1020';
  ctx.beginPath();
  ctx.arc(x, y + bob, 4, 0, Math.PI * 2);
  ctx.fill();
}

export function paintDriveWorld(ctx, camX, camY, t) {
  ctx.fillStyle = '#141018';
  ctx.fillRect(0, 0, 1280, 720);
  ctx.fillStyle = '#2a2430';
  for (let y = -camY % 40; y < 720; y += 40) {
    ctx.fillRect(0, y, 1280, 2);
  }
  for (let x = -camX % 40; x < 1280; x += 40) {
    ctx.fillRect(x, 0, 2, 720);
  }
}

export function paintDriveCar(ctx, x, y, ang, color, rave) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(ang);
  ctx.fillStyle = '#0a0808';
  ctx.fillRect(-22, -12, 44, 24);
  ctx.fillStyle = rave ? '#ffe566' : color;
  ctx.fillRect(-20, -10, 40, 20);
  ctx.fillStyle = '#3df0ff';
  ctx.fillRect(4, -7, 12, 14);
  ctx.restore();
}

export function paintPartyBalls(ctx, party, x, y) {
  party.forEach((id, i) => {
    const colors = {
      ravebug: '#7cff6b',
      spicegrub: '#c44',
      glowbat: '#9b6bff',
      brewcrab: '#6a4010',
      glazemoth: '#e87880',
      statuette: '#ffe566',
      bassling: '#3df0ff',
    };
    ctx.fillStyle = '#111';
    ctx.beginPath();
    ctx.arc(x + i * 28, y, 11, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = colors[id] || '#fff';
    ctx.beginPath();
    ctx.arc(x + i * 28, y, 8, 0, Math.PI * 2);
    ctx.fill();
  });
}


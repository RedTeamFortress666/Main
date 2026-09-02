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
  const t = pose.t || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28 + Math.round(punch * 3 - hit * 3);
  const foot = SPRITE_H - 2;

  const skin = '#c48a6a';
  const skinDk = '#9a6248';
  const jacket = '#141418';
  const scarf = '#6ec8ff';
  const cap = '#6a6a72';
  const jean = '#1c2430';
  const outline = '#050508';

  // legs
  const kExt = Math.round(kick * 12);
  rect(ctx, cx - 10, foot - 22, 9, 20, outline);
  rect(ctx, cx - 9, foot - 21, 7, 18, jean);
  rect(ctx, cx + 2 + kExt, foot - 22, 9, 20, outline);
  rect(ctx, cx + 3 + kExt, foot - 21, 7, 18, jean);
  rect(ctx, cx - 11, foot - 6, 11, 6, '#111');
  rect(ctx, cx + 2 + kExt, foot - 6, 11, 6, '#111');
  rect(ctx, cx - 9, foot - 12, 6, 4, '#3a3a40'); // knee pad
  rect(ctx, cx + 4 + kExt, foot - 12, 6, 4, '#3a3a40');
  rect(ctx, cx + 8, foot - 20, 5, 8, '#2a2018'); // holster

  // torso / jacket
  rect(ctx, cx - 12, foot - 50, 24, 30, outline);
  rect(ctx, cx - 11, foot - 49, 22, 28, jacket);
  rect(ctx, cx - 6, foot - 48, 12, 10, scarf);
  rect(ctx, cx - 4, foot - 46, 8, 14, scarf);
  rect(ctx, cx + 6, foot - 44, 4, 16, '#0a0a0c');
  rect(ctx, cx - 10, foot - 36, 4, 4, '#3a3a44');

  // back arm + karambit
  const bx = cx - 16;
  rect(ctx, bx, foot - 46, 7, 16, outline);
  rect(ctx, bx + 1, foot - 45, 5, 14, jacket);
  rect(ctx, bx - 1, foot - 32, 6, 6, skin);
  const bladeX = bx - 6 - Math.round(blade * 10);
  rect(ctx, bladeX, foot - 34, 10, 3, '#c0c8d0');
  rect(ctx, bladeX - 2, foot - 36, 6, 3, '#e8eef4');
  rect(ctx, bladeX + 6, foot - 33, 3, 3, '#8a2018');

  // punch arm
  const ax = cx + 10 + Math.round(punch * 14);
  const ay = foot - 48 - Math.round(punch * 2);
  rect(ctx, ax, ay, 7, 16, outline);
  rect(ctx, ax + 1, ay + 1, 5, 14, jacket);
  rect(ctx, ax + 2, ay + 14, 7, 6, skin);
  rect(ctx, ax + 3, ay + 16, 2, 2, '#1a1a1a'); // knuckle tattoo

  // head
  const hx = cx;
  const hy = foot - 66;
  rect(ctx, hx - 10, hy, 20, 18, outline);
  rect(ctx, hx - 9, hy + 1, 18, 16, skin);
  rect(ctx, hx - 7, hy + 10, 14, 8, skinDk); // beard
  rect(ctx, hx - 2, hy + 8, 6, 4, skinDk); // mustache
  rect(ctx, hx - 11, hy - 6, 22, 8, outline); // cap
  rect(ctx, hx - 10, hy - 5, 20, 6, cap);
  rect(ctx, hx - 8, hy - 8, 16, 4, cap);
  rect(ctx, hx - 8, hy + 4, 16, 4, '#111'); // shades
  rect(ctx, hx - 7, hy + 5, 5, 2, '#3df0ff');
  rect(ctx, hx + 2, hy + 5, 5, 2, '#ff4ad2');
  if ((t | 0) % 40 < 3) {
    rect(ctx, hx - 4, hy + 14, 3, 2, '#8a4030');
  }
}

export function paintRival(ctx, pose = {}) {
  const punch = pose.punch || 0;
  const hit = pose.hit || 0;
  ctx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const cx = 28 - Math.round(punch * 3 + hit * 4);
  const foot = SPRITE_H - 2;
  const skin = '#d2a07a';
  const coat = '#8a1230';
  const hair = '#1a1018';
  rect(ctx, cx - 9, foot - 22, 8, 20, '#1a1020');
  rect(ctx, cx + 3, foot - 22, 8, 20, '#1a1020');
  rect(ctx, cx - 11, foot - 50, 24, 30, '#050508');
  rect(ctx, cx - 10, foot - 49, 22, 28, coat);
  rect(ctx, cx - 6, foot - 46, 12, 8, '#f0e8ff');
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
  else paintRival(octx, pose);
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
  ctx.fillStyle = 'rgba(0,0,0,0.55)';
  ctx.fillRect(0, y0, w, 168);
  for (let i = 0; i < 4; i++) {
    const y = y0 + 12 + i * 38;
    ctx.fillStyle = '#1a1428';
    ctx.fillRect(40, y, w - 80, 30);
    ctx.fillStyle = LANE_COLORS[lanes[i]];
    ctx.fillRect(hitX - 6, y, 8, 30);
    drawPixelText(ctx, lanes[i].toUpperCase(), 48, y + 8, 1, LANE_COLORS[lanes[i]]);
  }
  for (const n of notes) {
    if (n.hit && n.grade !== 'miss') continue;
    const x = hitX + (n.beat - currentBeat) * pxPerBeat;
    if (x < 30 || x > w - 20) continue;
    const li = lanes.indexOf(n.lane);
    const y = y0 + 12 + li * 38;
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

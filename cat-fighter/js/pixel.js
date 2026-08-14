/**
 * 16-bit arcade helpers: 5x7 font, SF2-style life bars, bipedal cat sprites.
 * Drawn on integer pixels then nearest-neighbor scaled.
 */

export const SPRITE_W = 48;
export const SPRITE_H = 72;
export const SPRITE_SCALE = 4;

/** 5x7 glyphs as 5-bit rows (MSB = left pixel). */
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
  '◆': [0x04, 0x0e, 0x1f, 0x0e, 0x04, 0x00, 0x00],
  '◇': [0x04, 0x0a, 0x11, 0x0a, 0x04, 0x00, 0x00],
};

export function glyphWidth() {
  return 6;
}

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

export function lifeBarWidth(hp, max, barW) {
  const cur = Number.isFinite(hp) ? hp : max;
  const m = max > 0 ? max : 1;
  return Math.max(0, Math.min(barW, (cur / m) * barW));
}

export function chromaKeyMagenta(img) {
  const c = document.createElement('canvas');
  c.width = img.width;
  c.height = img.height;
  const x = c.getContext('2d');
  x.drawImage(img, 0, 0);
  const d = x.getImageData(0, 0, c.width, c.height);
  const px = d.data;
  for (let i = 0; i < px.length; i += 4) {
    const r = px[i], g = px[i + 1], b = px[i + 2];
    if (r > 150 && b > 150 && g < 140) px[i + 3] = 0;
  }
  x.putImageData(d, 0, 0);
  return c;
}

function rect(ctx, x, y, w, h, c) {
  ctx.fillStyle = c;
  ctx.fillRect(x | 0, y | 0, w | 0, h | 0);
}

function pal(yoko) {
  if (yoko) {
    return {
      fur: '#1a1a1a',
      furHi: '#2c2c2c',
      white: '#f3efe6',
      gold: '#e8c547',
      goldDk: '#b8942a',
      cloth: '#101014',
      sash: '#d4b84a',
      eye: '#3dcc6a',
      nose: '#f0b3c0',
      inner: '#e7a1b0',
      outline: '#050505',
    };
  }
  return {
    fur: '#8aa0b0',
    furHi: '#c5d2dc',
    white: '#d5dee6',
    gold: '#c9a227',
    goldDk: '#8a6a18',
    cloth: '#b01c1c',
    sash: '#e74c3c',
    eye: '#d7e36a',
    nose: '#c98490',
    inner: '#3a3228',
    outline: '#1a1010',
    pants: '#4a3a2c',
    boot: '#2a1c14',
  };
}

let _sheet;

function sheet() {
  if (!_sheet) {
    _sheet = document.createElement('canvas');
    _sheet.width = SPRITE_W;
    _sheet.height = SPRITE_H;
  }
  return _sheet;
}

/**
 * Paint a bipedal 16-bit cat onto the sprite canvas.
 * pose: punch/kick/crouch/jump/block/hit/walk/ko in 0..1 (walk -1..1)
 */
export function paintCatSprite(octx, yoko, pose) {
  const p = pal(yoko);
  const punch = pose.punch || 0;
  const kick = pose.kick || 0;
  const crouch = pose.crouch || 0;
  const jump = pose.jump || 0;
  const block = pose.block || 0;
  const hit = pose.hit || 0;
  const walk = pose.walk || 0;
  const ko = pose.ko || 0;

  octx.clearRect(0, 0, SPRITE_W, SPRITE_H);
  const drop = Math.round(crouch * 10 + ko * 18);
  const lean = Math.round(hit * 4 - block * 2 + punch * 2);
  const cx = 22 + lean;
  const footY = SPRITE_H - 2 - Math.round(jump * 6);

  // Tail
  const tw = Math.round(Math.sin((pose.t || 0) * 0.15) * 3);
  rect(octx, cx - 18 + tw, footY - 42 + drop, 4, 22, p.outline);
  rect(octx, cx - 17 + tw, footY - 41 + drop, 2, 20, p.fur);
  rect(octx, cx - 20 + tw, footY - 48 + drop, 6, 8, p.fur);

  // Back arm
  const backArmY = footY - 48 + drop;
  rect(octx, cx - 12, backArmY, 5, 16, p.outline);
  rect(octx, cx - 11, backArmY + 1, 3, 14, yoko ? p.fur : p.cloth);
  rect(octx, cx - 12, backArmY + 14, 5, 4, yoko ? p.white : p.fur);

  // Legs
  const legOff = Math.round(walk * 6);
  const kickExt = Math.round(kick * 14);
  const backLegX = cx - 6 - legOff;
  const frontLegX = cx + 4 + legOff + kickExt;
  const legH = 18 - Math.round(crouch * 6);
  const pants = yoko ? p.cloth : p.pants;
  const boot = yoko ? p.fur : p.boot;
  const paw = yoko ? p.white : p.fur;

  rect(octx, backLegX, footY - legH, 7, legH, p.outline);
  rect(octx, backLegX + 1, footY - legH + 1, 5, legH - 2, pants);
  rect(octx, backLegX, footY - 5, 8, 5, boot);
  rect(octx, backLegX + 1, footY - 3, 6, 3, paw);

  rect(octx, frontLegX, footY - legH, 7, legH, p.outline);
  rect(octx, frontLegX + 1, footY - legH + 1, 5, legH - 2, pants);
  rect(octx, frontLegX, footY - 5, 8, 5, boot);
  rect(octx, frontLegX + 1, footY - 3, 6, 3, paw);

  // Torso / coat
  const bodyTop = footY - 50 + drop;
  const bodyH = 26 - Math.round(crouch * 4);
  const bodyW = yoko ? 18 : 20;
  rect(octx, cx - 8, bodyTop, bodyW, bodyH, p.outline);
  rect(octx, cx - 7, bodyTop + 1, bodyW - 2, bodyH - 2, p.cloth);

  if (yoko) {
    rect(octx, cx - 2, bodyTop + 4, 8, 16, p.white);
    rect(octx, cx - 6, bodyTop + 14, bodyW - 4, 4, p.sash);
    rect(octx, cx + 4, bodyTop + 8, 2, 2, p.gold);
    rect(octx, cx + 4, bodyTop + 12, 2, 2, p.gold);
    rect(octx, cx + 4, bodyTop + 16, 2, 2, p.gold);
    // pocket watch
    rect(octx, cx + 6, bodyTop + 18, 4, 4, p.gold);
    rect(octx, cx + 7, bodyTop + 19, 2, 2, p.goldDk);
  } else {
    rect(octx, cx - 8, bodyTop - 2, 6, 4, p.gold);
    rect(octx, cx + 10, bodyTop - 2, 6, 4, p.gold);
    rect(octx, cx + 2, bodyTop + 6, 6, 6, p.sash);
    rect(octx, cx + 4, bodyTop + 8, 3, 3, '#e74c3c');
    rect(octx, cx + 5, bodyTop + 9, 1, 1, p.gold);
    rect(octx, cx - 6, bodyTop + 18, bodyW - 4, 3, p.inner);
    rect(octx, cx, bodyTop + 18, 4, 3, p.gold);
    // scarf
    rect(octx, cx - 4, bodyTop, 12, 5, p.sash);
    rect(octx, cx + 8, bodyTop + 4, 4, 10, p.sash);
  }

  // Front arm (punch extends)
  const armX = cx + 8 + Math.round(punch * 12 - block * 4);
  const armY = bodyTop + 4 - Math.round(block * 8);
  const armLen = 14 + Math.round(punch * 6);
  rect(octx, armX, armY, 5, armLen, p.outline);
  rect(octx, armX + 1, armY + 1, 3, armLen - 2, yoko ? p.fur : p.cloth);
  rect(octx, armX, armY + armLen - 2, 6, 5, yoko ? p.white : p.fur);

  // Head
  const hx = cx + 1;
  const hy = bodyTop - 16 + Math.round(jump * -2);
  rect(octx, hx - 10, hy, 22, 18, p.outline);
  rect(octx, hx - 9, hy + 1, 20, 16, p.fur);
  // ears
  rect(octx, hx - 10, hy - 8, 7, 10, p.outline);
  rect(octx, hx + 5, hy - 8, 7, 10, p.outline);
  rect(octx, hx - 9, hy - 7, 5, 8, p.fur);
  rect(octx, hx + 6, hy - 7, 5, 8, p.fur);
  rect(octx, hx - 8, hy - 5, 3, 4, p.inner);
  rect(octx, hx + 7, hy - 5, 3, 4, p.inner);

  if (yoko) {
    rect(octx, hx - 2, hy + 2, 6, 14, p.white);
    rect(octx, hx - 4, hy + 10, 12, 7, p.white);
    // crown
    rect(octx, hx - 7, hy - 4, 16, 4, p.gold);
    rect(octx, hx - 6, hy - 8, 3, 5, p.gold);
    rect(octx, hx - 1, hy - 10, 4, 7, p.gold);
    rect(octx, hx + 5, hy - 8, 3, 5, p.gold);
    rect(octx, hx, hy - 8, 2, 2, '#3dcc6a');
  } else {
    rect(octx, hx - 2, hy + 10, 10, 6, p.furHi);
    rect(octx, hx - 6, hy + 4, 2, 6, '#6a3030');
  }

  // Eyes
  if ((pose.t || 0) % 180 < 6) {
    rect(octx, hx - 6, hy + 7, 5, 1, p.outline);
    rect(octx, hx + 3, hy + 7, 5, 1, p.outline);
  } else {
    const eh = hit > 0.4 ? 1 : 4;
    rect(octx, hx - 6, hy + 5, 5, eh, p.eye);
    rect(octx, hx + 3, hy + 5, 5, eh, p.eye);
    rect(octx, hx - 4, hy + 6, 2, 2, '#111');
    rect(octx, hx + 5, hy + 6, 2, 2, '#111');
    if (yoko) {
      rect(octx, hx - 6, hy + 4, 5, 1, p.fur);
      rect(octx, hx + 3, hy + 4, 5, 1, p.fur);
    }
  }
  rect(octx, hx + (yoko ? 1 : 4), hy + 11, 3, 2, p.nose);
}

export function fighterPoseFromState(f) {
  const t = f.animTime || 0;
  const pose = { t, punch: 0, kick: 0, crouch: 0, jump: 0, block: 0, hit: 0, walk: 0, ko: 0 };
  if (f.crouching && !f.airborne) pose.crouch = 1;
  if (f.airborne || f.state === 'jump') pose.jump = 1;
  if (f.state === 'block') pose.block = 1;
  if (f.state === 'hit' || f.state === 'ko') pose.hit = 1;
  if (f.state === 'knockdown' || f.state === 'ko') pose.ko = 1;
  if (f.state === 'walk') pose.walk = Math.sin(t * 0.42);
  if (f.attacking && f.attack) {
    const a = f.attack;
    const local = f.attackFrame;
    const ext = local < a.startup
      ? local / Math.max(1, a.startup)
      : local < a.startup + a.active ? 1
        : 1 - (local - a.startup - a.active) / Math.max(1, a.recovery);
    if (a.id && a.id.includes('k') && !a.super) pose.kick = ext;
    else pose.punch = ext;
    if (a.uppercut) pose.punch = 1;
  }
  return pose;
}

export const SPRITE_DRAW = 3;

export function drawPixelFighter(ctx, f, sprite) {
  const pose = fighterPoseFromState(f);
  const jx = f.shake ? (Math.random() - 0.5) * f.shake : 0;
  const bob = f.state === 'idle' ? Math.sin((f.animTime || 0) * 0.12) * 3 : 0;
  ctx.save();
  ctx.imageSmoothingEnabled = false;
  ctx.translate(Math.round(f.x + jx + (pose.punch || 0) * 10 * f.facing), Math.round(f.y + bob));
  const sy = pose.crouch ? 0.82 : pose.ko ? 0.68 : pose.jump ? 1.05 : 1;
  const sx = (pose.punch ? 1.06 : 1) * (pose.kick ? 1.04 : 1);
  if (pose.hit) ctx.rotate(0.1 * f.facing);
  ctx.scale(f.facing * SPRITE_DRAW * sx, SPRITE_DRAW * sy);
  if (f.hitFlash > 0) ctx.filter = 'brightness(2.2)';
  if (sprite) {
    ctx.drawImage(sprite, -sprite.width / 2, -sprite.height);
  } else {
    const c = sheet();
    const octx = c.getContext('2d');
    octx.imageSmoothingEnabled = false;
    paintCatSprite(octx, f.characterId === 'yoko', pose);
    ctx.drawImage(c, -SPRITE_W / 2, -SPRITE_H);
  }
  ctx.filter = 'none';
  ctx.restore();

  ctx.save();
  ctx.fillStyle = 'rgba(0,0,0,0.35)';
  ctx.fillRect(Math.round(f.x - 22), Math.round(f.y + 2), 44, 6);
  ctx.restore();
}

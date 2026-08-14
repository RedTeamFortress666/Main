import {
  CANVAS_W, CANVAS_H, GROUND_Y, MAX_HP, MAX_METER, CHARACTERS, lerp,
} from './logic.js';

export class Assets {
  constructor() {
    this.images = {};
    this.ready = false;
  }

  async load() {
    const files = {
      yoko: 'assets/yoko_portrait.jpg',
      morlan: 'assets/morlan_portrait.jpg',
      stella: 'assets/stella_portrait.jpg',
      joye: 'assets/joye_portrait.jpg',
      palace: 'assets/palace_stage.jpg',
      russia: 'assets/russian_stage.jpg',
    };
    await Promise.all(Object.entries(files).map(([k, src]) => this._img(k, src)));
    this.ready = true;
  }

  _img(key, src) {
    return new Promise((resolve) => {
      const im = new Image();
      im.onload = () => { this.images[key] = im; resolve(); };
      im.onerror = () => resolve();
      im.src = src;
    });
  }
}

export class Particles {
  constructor() {
    this.list = [];
  }

  spawn(x, y, kind, extra = {}) {
    const n = kind === 'super' ? 28 : kind === 'hit' ? 14 : 10;
    for (let i = 0; i < n; i++) {
      const ang = Math.random() * Math.PI * 2;
      const spd = (kind === 'super' ? 7 : 4) * (0.4 + Math.random());
      this.list.push({
        x, y,
        vx: Math.cos(ang) * spd + (extra.vx || 0),
        vy: Math.sin(ang) * spd - 1.5,
        life: 18 + Math.random() * 16,
        max: 34,
        kind,
        color: extra.color || (kind === 'milk' ? '#f4f0e0' : kind === 'tuna' ? '#d4a017' : '#fff3a0'),
        r: 2 + Math.random() * 4,
      });
    }
  }

  update() {
    this.list = this.list.filter((p) => {
      p.life -= 1;
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.12;
      return p.life > 0;
    });
  }

  draw(ctx) {
    for (const p of this.list) {
      ctx.globalAlpha = p.life / p.max;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }
}

function roundRect(ctx, x, y, w, h, r) {
  const rr = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + rr, y);
  ctx.arcTo(x + w, y, x + w, y + h, rr);
  ctx.arcTo(x + w, y + h, x, y + h, rr);
  ctx.arcTo(x, y + h, x, y, rr);
  ctx.arcTo(x, y, x + w, y, rr);
  ctx.closePath();
}

function ellipse(ctx, x, y, rx, ry, fill) {
  ctx.beginPath();
  ctx.ellipse(x, y, rx, ry, 0, 0, Math.PI * 2);
  if (fill) ctx.fill();
  else ctx.stroke();
}

export function drawStage(ctx, assets, round, time, flash) {
  const imgA = assets.images.palace;
  const imgB = assets.images.russia;
  ctx.save();
  if (round <= 1 && imgA) {
    ctx.drawImage(imgA, 0, 0, CANVAS_W, CANVAS_H);
  } else if (round === 2 && imgB) {
    ctx.drawImage(imgB, 0, 0, CANVAS_W, CANVAS_H);
  } else {
    // Round 3: Black Lodge tea-party mash — both stages breathe into each other.
    if (imgA) ctx.drawImage(imgA, 0, 0, CANVAS_W, CANVAS_H);
    if (imgB) {
      ctx.globalAlpha = 0.42 + Math.sin(time * 0.03) * 0.28;
      ctx.drawImage(imgB, 0, 0, CANVAS_W, CANVAS_H);
      ctx.globalAlpha = 1;
    }
    ctx.fillStyle = `rgba(80,0,20,${0.12 + Math.sin(time * 0.05) * 0.06})`;
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
  }
  if (!imgA && !imgB) {
    const g = ctx.createLinearGradient(0, 0, 0, CANVAS_H);
    g.addColorStop(0, round === 2 ? '#6a8cae' : '#87b7e8');
    g.addColorStop(1, round === 2 ? '#c9d6df' : '#d4c4a8');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
  }
  // Floor shadow strip so feet read clearly.
  const fg = ctx.createLinearGradient(0, GROUND_Y - 8, 0, CANVAS_H);
  fg.addColorStop(0, 'rgba(0,0,0,0)');
  fg.addColorStop(0.15, 'rgba(0,0,0,0.18)');
  fg.addColorStop(1, 'rgba(0,0,0,0.45)');
  ctx.fillStyle = fg;
  ctx.fillRect(0, GROUND_Y - 8, CANVAS_W, CANVAS_H - GROUND_Y + 8);
  if (flash > 0) {
    ctx.fillStyle = `rgba(255,255,255,${Math.min(0.85, flash / 10)})`;
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
  }
  ctx.restore();
}

function catPalette(id) {
  if (id === 'yoko') {
    return {
      fur: '#161616', fur2: '#f7f4ee', gold: '#e6c35c', nose: '#f0b3c0',
      eye: '#c9d36a', cloth: '#111', sash: '#d4b84a', inner: '#fff',
      cheek: '#f4efe6',
    };
  }
  return {
    fur: '#8fa4b5', fur2: '#c5d2dc', gold: '#c9a227', nose: '#c98490',
    eye: '#d7e36a', cloth: '#8b1e1e', sash: '#c0392b', inner: '#3a3a3a',
    cheek: '#b7c5d0',
  };
}

function fluffHalo(ctx, x, y, rx, ry, color, n = 14) {
  ctx.fillStyle = color;
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2 + 0.2;
    const jx = Math.cos(a) * rx;
    const jy = Math.sin(a) * ry;
    ctx.beginPath();
    ctx.ellipse(x + jx, y + jy, 7 + (i % 4), 5 + (i % 3), a, 0, Math.PI * 2);
    ctx.fill();
  }
}

export function drawFighter(ctx, f) {
  const p = catPalette(f.characterId);
  const yoko = f.characterId === 'yoko';
  const t = f.animTime;
  const crouch = f.crouching && !f.airborne ? 0.28 : 0;
  const bob = f.state === 'idle' ? Math.sin(t * 0.12) * 3 : 0;
  const walk = f.state === 'walk' ? Math.sin(t * 0.42) : 0;
  let armR = -0.35 + Math.sin(t * 0.12) * 0.08;
  let armL = 0.25;
  let legR = walk * 0.55;
  let legL = -walk * 0.55;
  let bodyRot = 0;
  let squash = 1;

  if (f.state === 'crouch') { squash = 0.78; armR = -0.1; }
  if (f.state === 'jump' || f.airborne) { armR = -1.1; armL = 0.8; legR = -0.5; legL = 0.4; }
  if (f.state === 'block') { armR = -1.35; armL = -1.1; bodyRot = -0.08; }
  if (f.state === 'hit' || f.state === 'ko') { armR = 0.9; armL = -0.7; bodyRot = 0.25; }
  if (f.state === 'knockdown' || f.state === 'ko') { bodyRot = 1.15; squash = 0.7; }
  if (f.state === 'drink' || f.state === 'eat') { armR = 0.4; squash = 0.85; bodyRot = 0.35; }

  if (f.attacking && f.attack) {
    const a = f.attack;
    const local = f.attackFrame;
    const ext = local < a.startup
      ? local / a.startup
      : local < a.startup + a.active ? 1
        : 1 - (local - a.startup - a.active) / Math.max(1, a.recovery);
    if (a.id.includes('k') && !a.super) {
      legR = -0.2 + ext * 1.4;
      armR = -0.5;
    } else {
      armR = -0.2 - ext * 1.6;
      armL = 0.4;
    }
    if (a.uppercut) { armR = -2.2; bodyRot = -0.4; }
    if (a.dive) { bodyRot = 0.9; armR = -1.6; }
    if (a.multi) { armR = -0.4 - Math.sin(local * 1.2) * 1.3; }
  }

  ctx.save();
  const jx = f.shake ? (Math.random() - 0.5) * f.shake : 0;
  ctx.translate(f.x + jx, f.y + bob + crouch * 36);
  ctx.scale(f.facing * 1.32, squash * 1.32);
  ctx.shadowColor = 'rgba(0,0,0,0.85)';
  ctx.shadowBlur = 10;
  ctx.shadowOffsetY = 4;
  if (f.hitFlash > 0) ctx.filter = 'brightness(2.4) saturate(0.2)';
  ctx.rotate(bodyRot * 0.35);

  // Long fluffy tail (Yoko: solid black per reference photo)
  const tw = Math.sin(t * 0.15) * 18;
  ctx.strokeStyle = p.fur;
  ctx.lineCap = 'round';
  ctx.lineWidth = 18;
  ctx.beginPath();
  ctx.moveTo(-16, -36);
  ctx.quadraticCurveTo(-56, -78 + tw * 0.25, -42 + tw, -118);
  ctx.stroke();
  ctx.lineWidth = 12;
  ctx.strokeStyle = yoko ? '#0d0d0d' : p.fur2;
  ctx.beginPath();
  ctx.moveTo(-18, -40);
  ctx.quadraticCurveTo(-52, -74 + tw * 0.25, -40 + tw, -112);
  ctx.stroke();
  fluffHalo(ctx, -40 + tw, -112, 10, 8, p.fur, 8);

  const paw = yoko ? p.fur2 : p.fur;
  const drawLimb = (ang, len, thick, color, pawColor) => {
    ctx.save();
    ctx.rotate(ang);
    ctx.strokeStyle = color;
    ctx.lineCap = 'round';
    ctx.lineWidth = thick + 4;
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(0, len);
    ctx.stroke();
    ctx.lineWidth = thick;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.fillStyle = pawColor;
    ellipse(ctx, 0, len + 5, 11, 8, true);
    ctx.restore();
  };

  ctx.save();
  ctx.translate(-12, -26);
  drawLimb(0.15 + legL, 34, 15, p.fur, paw);
  ctx.restore();
  ctx.save();
  ctx.translate(12, -26);
  drawLimb(-0.1 + legR, 34, 15, p.fur, paw);
  ctx.restore();

  // Fluffy body under clothes
  fluffHalo(ctx, 0, -70, 30, 42, p.fur, 16);
  ctx.fillStyle = p.fur;
  ellipse(ctx, 0, -72, 28, 40, true);

  // Torso / clothes
  ctx.fillStyle = p.cloth;
  roundRect(ctx, -28, -112, 56, 88, 16);
  ctx.fill();
  ctx.strokeStyle = yoko ? '#e6c35c' : '#7a1515';
  ctx.lineWidth = 2;
  roundRect(ctx, -28, -112, 56, 88, 16);
  ctx.stroke();
  if (yoko) {
    // White chest ruff — the photo's tuxedo shirt
    ctx.fillStyle = p.fur2;
    fluffHalo(ctx, 2, -78, 16, 22, p.fur2, 10);
    ctx.beginPath();
    ctx.ellipse(2, -78, 18, 26, 0, 0, Math.PI * 2);
    ctx.fill();
    // Shoulder white patch
    ctx.beginPath();
    ctx.ellipse(-22, -96, 10, 8, -0.4, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = p.sash;
    ctx.fillRect(-26, -58, 52, 12);
    ctx.fillStyle = p.gold;
    ctx.beginPath();
    ctx.arc(18, -52, 5, 0, Math.PI * 2);
    ctx.fill();
  } else {
    ctx.fillStyle = p.sash;
    ctx.beginPath();
    ctx.moveTo(-8, -108);
    ctx.lineTo(22, -70);
    ctx.lineTo(8, -62);
    ctx.lineTo(-20, -96);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#e74c3c';
    ctx.beginPath();
    star(ctx, 14, -88, 5, 9, 4);
    ctx.fill();
  }

  // Head + cheek fluff
  fluffHalo(ctx, 0, -132, 30, 24, p.fur, 12);
  ctx.fillStyle = p.fur;
  ellipse(ctx, 0, -132, 30, 26, true);
  ctx.fillStyle = p.cheek;
  ellipse(ctx, -18, -122, 10, 9, true);
  ellipse(ctx, 18, -126, 9, 8, true);

  // ears
  ctx.fillStyle = p.fur;
  ctx.beginPath();
  ctx.moveTo(-22, -148);
  ctx.lineTo(-34, -182);
  ctx.lineTo(-6, -154);
  ctx.closePath();
  ctx.fill();
  ctx.beginPath();
  ctx.moveTo(22, -148);
  ctx.lineTo(34, -182);
  ctx.lineTo(6, -154);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = '#e7a1b0';
  ctx.beginPath();
  ctx.moveTo(-24, -156);
  ctx.lineTo(-31, -174);
  ctx.lineTo(-12, -158);
  ctx.fill();

  if (yoko) {
    // White blaze down the face, widening at muzzle (reference photo)
    ctx.fillStyle = p.fur2;
    ctx.beginPath();
    ctx.moveTo(-4, -152);
    ctx.lineTo(4, -152);
    ctx.lineTo(14, -118);
    ctx.lineTo(8, -110);
    ctx.lineTo(-10, -114);
    ctx.closePath();
    ctx.fill();
    ellipse(ctx, 4, -118, 16, 13, true);
  } else {
    ctx.fillStyle = p.fur2;
    ellipse(ctx, 6, -124, 16, 12, true);
  }

  ctx.fillStyle = p.nose;
  ellipse(ctx, yoko ? 4 : 16, -122, 5, 3.6, true);

  // Half-lidded arrogant eyes (Yoko) / stern (Morlan)
  const blink = (t % 180) < 6;
  const lid = yoko ? 0.45 : 0;
  if (!blink) {
    ctx.fillStyle = p.eye;
    ellipse(ctx, -8, -136, 7, f.state === 'hit' ? 2 : 7 * (1 - lid * 0.5), true);
    ellipse(ctx, 12, -136, 7, f.state === 'hit' ? 2 : 7 * (1 - lid * 0.5), true);
    ctx.fillStyle = '#111';
    ellipse(ctx, -6, -135, 3.2, 3.6, true);
    ellipse(ctx, 14, -135, 3.2, 3.6, true);
    ctx.fillStyle = '#fff';
    ellipse(ctx, -8, -138, 1.6, 1.6, true);
    ellipse(ctx, 12, -138, 1.6, 1.6, true);
    if (yoko) {
      ctx.strokeStyle = p.fur;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(-16, -142); ctx.quadraticCurveTo(-8, -140, 0, -142);
      ctx.moveTo(4, -142); ctx.quadraticCurveTo(12, -140, 20, -142);
      ctx.stroke();
    }
  } else {
    ctx.strokeStyle = '#111';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(-14, -136); ctx.lineTo(0, -136);
    ctx.moveTo(4, -136); ctx.lineTo(20, -136);
    ctx.stroke();
  }

  if (!yoko) {
    ctx.strokeStyle = '#4a5560';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(-14, -148); ctx.lineTo(-2, -128);
    ctx.moveTo(8, -122); ctx.lineTo(20, -114);
    ctx.stroke();
  }

  if (yoko) {
    ctx.fillStyle = p.gold;
    ctx.beginPath();
    ctx.moveTo(-16, -154);
    ctx.lineTo(-10, -174);
    ctx.lineTo(-4, -156);
    ctx.lineTo(0, -178);
    ctx.lineTo(4, -156);
    ctx.lineTo(10, -174);
    ctx.lineTo(16, -154);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = '#b8942a';
    ctx.stroke();
  }

  ctx.save();
  ctx.translate(16, -92);
  drawLimb(armR, 28, 12, p.fur, paw);
  ctx.restore();
  ctx.save();
  ctx.translate(-16, -92);
  drawLimb(armL, 26, 12, p.fur, paw);
  ctx.restore();

  ctx.filter = 'none';
  ctx.restore();

  ctx.save();
  ctx.globalAlpha = 0.25;
  ctx.fillStyle = '#000';
  ellipse(ctx, f.x, GROUND_Y + 8, 38, 9, true);
  ctx.restore();
}

function star(ctx, x, y, n, r, ir) {
  ctx.moveTo(x, y - r);
  for (let i = 0; i < n * 2; i++) {
    const ang = (Math.PI / n) * i - Math.PI / 2;
    const rad = i % 2 === 0 ? r : ir;
    ctx.lineTo(x + Math.cos(ang) * rad, y + Math.sin(ang) * rad);
  }
  ctx.closePath();
}

export function drawProjectile(ctx, p, time) {
  ctx.save();
  ctx.translate(p.x, p.y);
  if (p.kind === 'tuna') {
    ctx.rotate(time * 0.2 * Math.sign(p.vx || 1));
    ctx.fillStyle = '#c0c6cc';
    roundRect(ctx, -16, -12, 32, 24, 4);
    ctx.fill();
    ctx.fillStyle = '#7a1f1f';
    ctx.fillRect(-16, -4, 32, 8);
    ctx.fillStyle = '#f3e27a';
    ctx.font = 'bold 9px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('TUNA', 0, 3);
  } else {
    ctx.strokeStyle = `rgba(230,200,80,${0.4 + (p.life / 18) * 0.5})`;
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.ellipse(0, 0, p.w / 2, p.h / 2, 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.fillStyle = 'rgba(255,240,160,0.12)';
    ctx.fill();
  }
  ctx.restore();
}

export function drawStella(ctx, x, y, t, phase) {
  ctx.save();
  ctx.translate(x, y);
  const sway = Math.sin(t * 0.04) * 2;
  ctx.translate(sway, 0);
  // dress
  ctx.fillStyle = '#3d2b1f';
  ctx.beginPath();
  ctx.moveTo(-22, 0);
  ctx.lineTo(22, 0);
  ctx.lineTo(28, 90);
  ctx.lineTo(-28, 90);
  ctx.closePath();
  ctx.fill();
  // plaid
  ctx.strokeStyle = 'rgba(180,140,80,0.35)';
  ctx.lineWidth = 1;
  for (let i = -20; i < 24; i += 6) {
    ctx.beginPath(); ctx.moveTo(i, 8); ctx.lineTo(i + 8, 88); ctx.stroke();
  }
  // torso
  ctx.fillStyle = '#2c241c';
  roundRect(ctx, -16, -36, 32, 44, 8);
  ctx.fill();
  // log
  ctx.fillStyle = '#6b4423';
  ctx.save();
  ctx.rotate(-0.25);
  roundRect(ctx, -38, -18, 78, 18, 6);
  ctx.fill();
  ctx.fillStyle = '#8b5a2b';
  roundRect(ctx, -36, -16, 74, 8, 4);
  ctx.fill();
  ctx.restore();
  // head + hair
  ctx.fillStyle = '#1a1a1a';
  ellipse(ctx, 0, -58, 22, 28, true);
  ctx.fillStyle = '#f0d8c8';
  ellipse(ctx, 0, -52, 16, 18, true);
  ctx.fillStyle = '#3a3030';
  ellipse(ctx, -6, -54, 2.2, 2.2, true);
  ellipse(ctx, 6, -54, 2.2, 2.2, true);
  ctx.strokeStyle = '#5a4040';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(-4, -44); ctx.lineTo(4, -44);
  ctx.stroke();
  if (phase === 'place') {
    ctx.fillStyle = '#eee';
    ctx.font = 'italic 13px Georgia';
    ctx.textAlign = 'center';
    ctx.fillText('The log asked for milk.', 0, -96);
  }
  ctx.restore();
}

export function drawJoye(ctx, x, y, t, phase) {
  ctx.save();
  ctx.translate(x, y);
  const shuffle = Math.sin(t * 0.08) * 1.5;
  ctx.translate(shuffle, 0);

  // Walker (Zimmer frame) — behind / around her
  ctx.strokeStyle = '#c5ccd4';
  ctx.lineWidth = 4;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  const legs = [[-28, 8], [28, 8], [-22, 18], [22, 18]];
  for (const [lx, top] of legs) {
    ctx.beginPath();
    ctx.moveTo(lx, top);
    ctx.lineTo(lx, 78);
    ctx.stroke();
    ctx.fillStyle = '#4a4a4a';
    ctx.beginPath();
    ctx.arc(lx, 82, 6, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.beginPath();
  ctx.moveTo(-28, 8); ctx.lineTo(28, 8);
  ctx.moveTo(-22, 28); ctx.lineTo(22, 28);
  ctx.stroke();
  // basket
  ctx.fillStyle = '#9aa3ad';
  roundRect(ctx, -16, 30, 22, 16, 2);
  ctx.fill();
  ctx.strokeStyle = '#6d757e';
  ctx.lineWidth = 1.5;
  roundRect(ctx, -16, 30, 22, 16, 2);
  ctx.stroke();

  // Extra tuna in the basket
  ctx.fillStyle = '#cfd5da';
  roundRect(ctx, -12, 33, 14, 10, 2);
  ctx.fill();
  ctx.fillStyle = '#8b1e1e';
  ctx.fillRect(-12, 36, 14, 4);

  // Body — elderly, slim green cardigan
  ctx.fillStyle = '#2e6b45';
  roundRect(ctx, -12, -8, 24, 60, 10);
  ctx.fill();
  ctx.fillStyle = '#f2d56b';
  ctx.beginPath();
  ctx.moveTo(-7, -6); ctx.lineTo(11, 16); ctx.lineTo(6, 20); ctx.lineTo(-11, 2);
  ctx.fill();
  ctx.fillStyle = '#6b4a32';
  ctx.fillRect(-10, 48, 8, 24);
  ctx.fillRect(2, 48, 8, 24);

  // Hands on walker bar
  ctx.fillStyle = '#e8c4b0';
  ellipse(ctx, -26, 8, 4, 3.2, true);
  ellipse(ctx, 26, 8, 4, 3.2, true);

  // Head: copper-red hair a bit past the shoulders, round glasses, wrinkles
  const hair = '#c4451a';
  const hairDark = '#8f2e10';
  ctx.fillStyle = hair;
  ellipse(ctx, 0, -46, 20, 22, true);
  ellipse(ctx, 0, -60, 14, 11, true);
  // longer side locks
  ctx.fillStyle = hairDark;
  ellipse(ctx, -16, -28, 6, 24, true);
  ellipse(ctx, 16, -28, 6, 24, true);
  ctx.fillStyle = hair;
  ellipse(ctx, -15, -22, 5.5, 22, true);
  ellipse(ctx, 16, -20, 5.5, 24, true);
  ellipse(ctx, -13, -6, 5, 14, true);
  ellipse(ctx, 14, -4, 5, 16, true);
  ellipse(ctx, -12, 8, 4.5, 12, true);
  ellipse(ctx, 13, 10, 4.5, 14, true);
  ctx.fillStyle = '#f3c7b0';
  ellipse(ctx, 0, -40, 11, 15, true);
  // wrinkles
  ctx.strokeStyle = 'rgba(140,90,80,0.45)';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(-7, -48); ctx.quadraticCurveTo(-2, -46, 3, -48);
  ctx.moveTo(-6, -32); ctx.quadraticCurveTo(0, -30, 6, -32);
  ctx.stroke();
  ctx.strokeStyle = '#222';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(-5, -42, 4.5, 0, Math.PI * 2);
  ctx.arc(5, -42, 4.5, 0, Math.PI * 2);
  ctx.moveTo(-0.5, -42); ctx.lineTo(0.5, -42);
  ctx.stroke();
  ctx.fillStyle = '#5a3a28';
  ellipse(ctx, -5, -42, 1.7, 1.7, true);
  ellipse(ctx, 5, -42, 1.7, 1.7, true);
  ctx.fillStyle = '#c45c5c';
  ellipse(ctx, 0, -34, 3.2, 1.8, true);

  // Tuna tin in her left hand on the walker
  ctx.fillStyle = '#cfd5da';
  roundRect(ctx, 22, -6, 26, 18, 3);
  ctx.fill();
  ctx.fillStyle = '#8b1e1e';
  ctx.fillRect(22, 2, 26, 6);
  ctx.fillStyle = '#f6e27a';
  ctx.font = 'bold 8px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('TUNA', 35, 7);

  if (phase === 'feed') {
    ctx.fillStyle = '#fff6d0';
    ctx.font = 'italic 13px Georgia';
    ctx.textAlign = 'center';
    ctx.fillText('Tuna for the fallen, dears.', 0, -78);
  }
  ctx.restore();
}

export function drawSaucer(ctx, x, y, drinking) {
  ctx.save();
  ctx.shadowColor = 'rgba(255,248,220,0.8)';
  ctx.shadowBlur = 16;
  ctx.fillStyle = '#f2f2f2';
  ellipse(ctx, x, y, 28, 9, true);
  ctx.fillStyle = drinking ? '#fff8dc' : '#f4ead0';
  ellipse(ctx, x, y - 3, 20, 5, true);
  if (drinking) {
    ctx.strokeStyle = 'rgba(255,255,255,0.75)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x - 6, y - 14);
    ctx.quadraticCurveTo(x, y - 26, x + 8, y - 10);
    ctx.stroke();
  }
  ctx.restore();
}

export function drawHUD(ctx, game) {
  const { p1, p2, timer, wins, announce, combo } = game;
  ctx.save();
  // bars
  const barW = 430;
  const barH = 26;
  const y = 26;
  ctx.fillStyle = 'rgba(0,0,0,0.62)';
  roundRect(ctx, 40, y - 8, barW + 16, 56, 8); ctx.fill();
  roundRect(ctx, CANVAS_W - 56 - barW, y - 8, barW + 16, 56, 8); ctx.fill();

  const drawBar = (x, hp, color, flip) => {
    const cur = Number.isFinite(hp) ? hp : MAX_HP;
    ctx.fillStyle = '#0d0d0d';
    ctx.fillRect(x, y, barW, barH);
    const w = Math.max(0, Math.min(barW, (cur / MAX_HP) * barW));
    ctx.fillStyle = cur < MAX_HP * 0.22 ? '#ff3b3b' : color;
    if (flip) ctx.fillRect(x + barW - w, y, w, barH);
    else ctx.fillRect(x, y, w, barH);
    ctx.strokeStyle = '#ffe566';
    ctx.lineWidth = 3;
    ctx.strokeRect(x + 0.5, y + 0.5, barW - 1, barH - 1);
  };
  drawBar(48, p1.hp, '#e8c547', false);
  drawBar(CANVAS_W - 48 - barW, p2.hp, '#c0392b', true);

  ctx.fillStyle = '#f6e6a2';
  ctx.font = 'bold 16px Impact, sans-serif';
  ctx.textAlign = 'left';
  ctx.fillText(CHARACTERS.yoko.short, 52, y + 40);
  ctx.textAlign = 'right';
  ctx.fillText(CHARACTERS.morlan.short, CANVAS_W - 52, y + 40);

  // timer
  ctx.fillStyle = 'rgba(0,0,0,0.7)';
  roundRect(ctx, CANVAS_W / 2 - 44, 16, 88, 54, 8); ctx.fill();
  ctx.fillStyle = timer <= 10 ? '#ff6b6b' : '#fff';
  ctx.font = 'bold 40px Impact, sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(String(Math.ceil(timer)).padStart(2, '0'), CANVAS_W / 2, 56);

  // round pips
  for (let i = 0; i < 2; i++) {
    ctx.beginPath();
    ctx.fillStyle = i < wins[0] ? '#e8c547' : '#333';
    ctx.arc(CANVAS_W / 2 - 70 - i * 18, 74, 6, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.fillStyle = i < wins[1] ? '#c0392b' : '#333';
    ctx.arc(CANVAS_W / 2 + 70 + i * 18, 74, 6, 0, Math.PI * 2);
    ctx.fill();
  }

  // meters
  const drawMeter = (x, meter, color, flip) => {
    const mw = 220, mh = 10, my = CANVAS_H - 36;
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    roundRect(ctx, x, my, mw, mh, 4); ctx.fill();
    ctx.fillStyle = meter >= MAX_METER ? '#fff4a8' : color;
    const w = (meter / MAX_METER) * mw;
    if (flip) ctx.fillRect(x + mw - w, my, w, mh);
    else ctx.fillRect(x, my, w, mh);
    ctx.strokeStyle = '#eee';
    roundRect(ctx, x, my, mw, mh, 4); ctx.stroke();
    ctx.fillStyle = '#eee';
    ctx.font = '11px sans-serif';
    ctx.textAlign = flip ? 'right' : 'left';
    ctx.fillText(meter >= MAX_METER ? 'SUPER READY' : 'SUPER', flip ? x + mw : x, my - 4);
  };
  drawMeter(48, p1.meter, '#e8c547', false);
  drawMeter(CANVAS_W - 48 - 220, p2.meter, '#c0392b', true);

  // revive icons
  ctx.font = '12px sans-serif';
  ctx.fillStyle = '#f6e6a2';
  ctx.textAlign = 'left';
  ctx.fillText(p1.revivesUsed < 1 ? '◆ Tuna revive' : '◇ revive spent', 48, CANVAS_H - 48);
  ctx.textAlign = 'right';
  ctx.fillText(p2.revivesUsed < 1 ? 'Tuna revive ◆' : 'revive spent ◇', CANVAS_W - 48, CANVAS_H - 48);

  if (combo && combo.count > 1) {
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 28px Impact, sans-serif';
    ctx.textAlign = combo.side === 'p1' ? 'left' : 'right';
    const cx = combo.side === 'p1' ? 60 : CANVAS_W - 60;
    ctx.fillText(`${combo.count} HIT COMBO`, cx, 120);
  }

  if (announce.text) {
    ctx.fillStyle = `rgba(0,0,0,${0.45})`;
    ctx.fillRect(0, CANVAS_H / 2 - 48, CANVAS_W, 80);
    ctx.fillStyle = '#fff4c2';
    ctx.font = 'bold 48px Impact, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(announce.text, CANVAS_W / 2, CANVAS_H / 2 + 10);
    if (announce.sub) {
      ctx.font = 'italic 18px Georgia, serif';
      ctx.fillStyle = '#ddd';
      ctx.fillText(announce.sub, CANVAS_W / 2, CANVAS_H / 2 + 36);
    }
  }
  ctx.restore();
}

export function drawLetterbox(ctx, alpha = 0.7) {
  ctx.fillStyle = `rgba(0,0,0,${alpha})`;
  ctx.fillRect(0, 0, CANVAS_W, 90);
  ctx.fillRect(0, CANVAS_H - 90, CANVAS_W, 90);
}

export function drawPortraitCard(ctx, img, x, y, w, h, name, title) {
  ctx.save();
  ctx.fillStyle = 'rgba(0,0,0,0.65)';
  roundRect(ctx, x - 8, y - 8, w + 16, h + 70, 12);
  ctx.fill();
  ctx.strokeStyle = '#e8c547';
  ctx.lineWidth = 3;
  roundRect(ctx, x - 8, y - 8, w + 16, h + 70, 12);
  ctx.stroke();
  if (img) ctx.drawImage(img, x, y, w, h);
  ctx.fillStyle = '#fff';
  ctx.font = 'bold 22px Impact, sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(name, x + w / 2, y + h + 28);
  ctx.font = 'italic 13px Georgia, serif';
  ctx.fillStyle = '#ddd';
  ctx.fillText(title, x + w / 2, y + h + 48);
  ctx.restore();
}

export function fillTextWrap(ctx, text, x, y, maxW, lineH) {
  const words = text.split(' ');
  let line = '';
  let yy = y;
  for (const w of words) {
    const test = line + w + ' ';
    if (ctx.measureText(test).width > maxW) {
      ctx.fillText(line, x, yy);
      line = w + ' ';
      yy += lineH;
    } else line = test;
  }
  ctx.fillText(line, x, yy);
}

export { lerp };

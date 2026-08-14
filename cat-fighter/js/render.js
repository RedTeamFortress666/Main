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
      fur: '#1a1a1a', fur2: '#f4f1ea', gold: '#e6c35c', nose: '#e7a1b0',
      eye: '#f0c94d', cloth: '#111', sash: '#d4b84a', inner: '#fff',
    };
  }
  return {
    fur: '#8fa4b5', fur2: '#c5d2dc', gold: '#c9a227', nose: '#c98490',
    eye: '#d7e36a', cloth: '#8b1e1e', sash: '#c0392b', inner: '#3a3a3a',
  };
}

export function drawFighter(ctx, f) {
  const p = catPalette(f.characterId);
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
  ctx.scale(f.facing, squash);
  if (f.hitFlash > 0) ctx.filter = 'brightness(2.4) saturate(0.2)';
  ctx.rotate(bodyRot * f.facing);

  // Tail
  ctx.strokeStyle = p.fur;
  ctx.lineWidth = 10;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(-18, -40);
  const tw = Math.sin(t * 0.15) * 16;
  ctx.quadraticCurveTo(-48, -70 + tw * 0.2, -38 + tw, -96);
  ctx.stroke();
  if (f.characterId === 'yoko') {
    ctx.strokeStyle = p.fur2;
    ctx.lineWidth = 8;
    ctx.beginPath();
    ctx.moveTo(-36 + tw, -90);
    ctx.lineTo(-38 + tw, -96);
    ctx.stroke();
  }

  const drawLimb = (ang, len, thick, color, paw) => {
    ctx.save();
    ctx.rotate(ang);
    ctx.strokeStyle = color;
    ctx.lineWidth = thick;
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(0, len);
    ctx.stroke();
    ctx.fillStyle = paw;
    ellipse(ctx, 0, len + 4, 9, 7, true);
    ctx.restore();
  };

  ctx.save();
  ctx.translate(-10, -28);
  drawLimb(0.15 + legL, 32, 13, p.fur, f.characterId === 'yoko' ? p.fur2 : p.fur);
  ctx.restore();
  ctx.save();
  ctx.translate(10, -28);
  drawLimb(-0.1 + legR, 32, 13, p.fur, f.characterId === 'yoko' ? p.fur2 : p.fur);
  ctx.restore();

  // Torso / clothes
  ctx.fillStyle = p.cloth;
  roundRect(ctx, -26, -108, 52, 82, 16);
  ctx.fill();
  if (f.characterId === 'yoko') {
    ctx.fillStyle = p.fur2;
    ctx.beginPath();
    ctx.moveTo(0, -108);
    ctx.lineTo(16, -48);
    ctx.lineTo(-16, -48);
    ctx.closePath();
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

  // Head
  ctx.fillStyle = p.fur;
  ellipse(ctx, 0, -132, 28, 24, true);
  // ears
  ctx.beginPath();
  ctx.moveTo(-22, -146);
  ctx.lineTo(-32, -176);
  ctx.lineTo(-6, -152);
  ctx.closePath();
  ctx.fill();
  ctx.beginPath();
  ctx.moveTo(22, -146);
  ctx.lineTo(32, -176);
  ctx.lineTo(6, -152);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = '#e7a1b0';
  ctx.beginPath();
  ctx.moveTo(-24, -154);
  ctx.lineTo(-30, -170);
  ctx.lineTo(-12, -156);
  ctx.fill();

  // muzzle
  ctx.fillStyle = p.fur2;
  ellipse(ctx, 6, -124, 16, 12, true);
  ctx.fillStyle = p.nose;
  ellipse(ctx, 16, -126, 5, 3.5, true);

  // eyes
  ctx.fillStyle = '#111';
  const blink = (t % 180) < 6;
  if (!blink) {
    ctx.fillStyle = p.eye;
    ellipse(ctx, -6, -136, 6, f.state === 'hit' ? 2 : 7, true);
    ellipse(ctx, 10, -136, 6, f.state === 'hit' ? 2 : 7, true);
    ctx.fillStyle = '#111';
    ellipse(ctx, -4, -135, 3, 4, true);
    ellipse(ctx, 12, -135, 3, 4, true);
    ctx.fillStyle = '#fff';
    ellipse(ctx, -6, -138, 1.6, 1.6, true);
    ellipse(ctx, 10, -138, 1.6, 1.6, true);
  } else {
    ctx.strokeStyle = '#111';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(-12, -136); ctx.lineTo(0, -136);
    ctx.moveTo(4, -136); ctx.lineTo(16, -136);
    ctx.stroke();
  }

  if (f.characterId === 'morlan') {
    ctx.strokeStyle = '#4a5560';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(-14, -148); ctx.lineTo(-2, -128);
    ctx.moveTo(8, -122); ctx.lineTo(20, -114);
    ctx.stroke();
  }

  if (f.characterId === 'yoko') {
    ctx.fillStyle = p.gold;
    ctx.beginPath();
    ctx.moveTo(-16, -154);
    ctx.lineTo(-10, -172);
    ctx.lineTo(-4, -156);
    ctx.lineTo(0, -176);
    ctx.lineTo(4, -156);
    ctx.lineTo(10, -172);
    ctx.lineTo(16, -154);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = '#b8942a';
    ctx.stroke();
  }

  // Arms
  ctx.save();
  ctx.translate(16, -92);
  drawLimb(armR, 28, 11, p.fur, f.characterId === 'yoko' ? p.fur2 : p.fur);
  ctx.restore();
  ctx.save();
  ctx.translate(-16, -92);
  drawLimb(armL, 26, 11, p.fur, f.characterId === 'yoko' ? p.fur2 : p.fur);
  ctx.restore();

  ctx.filter = 'none';
  ctx.restore();

  // Ground blob shadow
  ctx.save();
  ctx.globalAlpha = 0.25;
  ctx.fillStyle = '#000';
  ellipse(ctx, f.x, GROUND_Y + 8, 34, 8, true);
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
  const bounce = Math.abs(Math.sin(t * 0.2)) * 3;
  ctx.translate(0, -bounce);
  ctx.fillStyle = '#2e6b45';
  roundRect(ctx, -20, -20, 40, 70, 12);
  ctx.fill();
  ctx.fillStyle = '#f2d56b';
  ctx.beginPath();
  ctx.moveTo(-8, -18); ctx.lineTo(22, 10); ctx.lineTo(10, 16); ctx.lineTo(-18, -8);
  ctx.fill();
  ctx.fillStyle = '#3a3330';
  ctx.fillRect(-16, 48, 14, 28);
  ctx.fillRect(4, 48, 14, 28);
  ctx.fillStyle = '#e36b2c';
  ellipse(ctx, 0, -48, 22, 24, true);
  ctx.fillStyle = '#f3c7b0';
  ellipse(ctx, 0, -42, 15, 16, true);
  ctx.strokeStyle = '#222';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(-6, -44, 5, 0, Math.PI * 2);
  ctx.arc(6, -44, 5, 0, Math.PI * 2);
  ctx.moveTo(-1, -44); ctx.lineTo(1, -44);
  ctx.stroke();
  ctx.fillStyle = '#3a6b3a';
  ellipse(ctx, -6, -44, 2, 2, true);
  ellipse(ctx, 6, -44, 2, 2, true);
  ctx.fillStyle = '#c45c5c';
  ellipse(ctx, 0, -36, 4, 2, true);
  // tuna tin
  ctx.fillStyle = '#cfd5da';
  roundRect(ctx, 18, -8, 26, 20, 3);
  ctx.fill();
  ctx.fillStyle = '#8b1e1e';
  ctx.fillRect(18, 0, 26, 7);
  ctx.fillStyle = '#f6e27a';
  ctx.font = 'bold 8px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('TUNA', 31, 6);
  if (phase === 'feed') {
    ctx.fillStyle = '#fff6d0';
    ctx.font = 'italic 13px Georgia';
    ctx.textAlign = 'center';
    ctx.fillText('Protein for the fallen!', 0, -84);
  }
  ctx.restore();
}

export function drawSaucer(ctx, x, y, drinking) {
  ctx.save();
  ctx.fillStyle = '#ddd';
  ellipse(ctx, x, y, 22, 7, true);
  ctx.fillStyle = drinking ? '#f7f1dc' : '#f4ead0';
  ellipse(ctx, x, y - 2, 16, 4, true);
  if (drinking) {
    ctx.strokeStyle = 'rgba(255,255,255,0.6)';
    ctx.beginPath();
    ctx.moveTo(x - 4, y - 10);
    ctx.quadraticCurveTo(x, y - 18, x + 6, y - 8);
    ctx.stroke();
  }
  ctx.restore();
}

export function drawHUD(ctx, game) {
  const { p1, p2, timer, wins, announce, combo } = game;
  ctx.save();
  // bars
  const barW = 430;
  const barH = 22;
  const y = 28;
  ctx.fillStyle = 'rgba(0,0,0,0.55)';
  roundRect(ctx, 40, y - 8, barW + 16, 52, 8); ctx.fill();
  roundRect(ctx, CANVAS_W - 56 - barW, y - 8, barW + 16, 52, 8); ctx.fill();

  const drawBar = (x, hp, color, flip) => {
    ctx.fillStyle = '#2a2a2a';
    roundRect(ctx, x, y, barW, barH, 4); ctx.fill();
    const w = (hp / MAX_HP) * barW;
    const g = ctx.createLinearGradient(x, y, x, y + barH);
    g.addColorStop(0, color);
    g.addColorStop(1, '#5a1010');
    ctx.fillStyle = hp < MAX_HP * 0.22 ? '#e74c3c' : g;
    if (flip) {
      ctx.fillRect(x + barW - w, y, w, barH);
    } else {
      ctx.fillRect(x, y, w, barH);
    }
    ctx.strokeStyle = '#f3e27a';
    ctx.lineWidth = 2;
    roundRect(ctx, x, y, barW, barH, 4); ctx.stroke();
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

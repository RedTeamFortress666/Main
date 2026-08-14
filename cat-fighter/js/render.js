import {
  CANVAS_W, CANVAS_H, GROUND_Y, MAX_HP, MAX_METER, lerp,
} from './logic.js';
import {
  drawPixelText, lifeBarWidth, drawPixelFighter, chromaKeyMagenta, SPRITE_DRAW,
} from './pixel.js';

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
      palace: 'assets/palace_stage_pixel.png',
      russia: 'assets/russian_stage_pixel.png',
      yokoHud: 'assets/yoko_hud.png',
      morlanHud: 'assets/morlan_hud.png',
      yokoSprite: 'assets/yoko_sprite.png',
      morlanSprite: 'assets/morlan_sprite.png',
    };
    await Promise.all(Object.entries(files).map(([k, src]) => this._img(k, src)));
    if (this.images.yokoSprite) this.images.yokoSprite = chromaKeyMagenta(this.images.yokoSprite);
    if (this.images.morlanSprite) this.images.morlanSprite = chromaKeyMagenta(this.images.morlanSprite);
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
      const s = Math.max(2, (p.r | 0) * 2);
      ctx.fillRect((p.x | 0) - s / 2, (p.y | 0) - s / 2, s, s);
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
  ctx.imageSmoothingEnabled = false;
  if (round <= 1 && imgA) {
    ctx.drawImage(imgA, 0, 0, CANVAS_W, CANVAS_H);
  } else if (round === 2 && imgB) {
    ctx.drawImage(imgB, 0, 0, CANVAS_W, CANVAS_H);
  } else {
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
    ctx.fillStyle = round === 2 ? '#6a8cae' : '#5aa0d8';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    ctx.fillStyle = '#7a7a7a';
    ctx.fillRect(0, GROUND_Y - 20, CANVAS_W, CANVAS_H - GROUND_Y + 20);
  }
  ctx.fillStyle = 'rgba(0,0,0,0.28)';
  ctx.fillRect(0, GROUND_Y + 4, CANVAS_W, CANVAS_H - GROUND_Y - 4);
  if (flash > 0) {
    ctx.fillStyle = `rgba(255,255,255,${Math.min(0.85, flash / 10)})`;
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
  }
  ctx.restore();
}

export function drawFighter(ctx, f, assets) {
  const key = f.characterId === 'yoko' ? 'yokoSprite' : 'morlanSprite';
  drawPixelFighter(ctx, f, assets?.images?.[key]);
}

export function drawFighterNames(ctx, p1, p2) {
  const h = 96 * SPRITE_DRAW;
  const gap = Math.abs(p1.x - p2.x);
  const items = [
    { f: p1, name: 'QUEEN YOKO' },
    { f: p2, name: 'TSAR MORLAN' },
  ];
  items.forEach(({ f, name }, i) => {
    let x = Math.round(f.x);
    let y = Math.round(f.y - h - 22);
    if (gap < 230) {
      x = i === 0 ? Math.round(Math.min(p1.x, p2.x) - 70) : Math.round(Math.max(p1.x, p2.x) + 70);
      y -= i * 20;
    }
    x = Math.max(90, Math.min(CANVAS_W - 90, x));
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    const nw = name.length * 12 + 8;
    ctx.fillRect(x - nw / 2, y - 2, nw, 16);
    drawPixelText(ctx, name, x, y, 2, '#ffffff', 'center');
  });
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
  const { p1, p2, timer, wins, announce, combo, round = 1, assets } = game;
  ctx.save();
  ctx.imageSmoothingEnabled = false;

  const portrait = 64;
  const barH = 22;
  const barY = 18;
  const barW = 400;
  const leftBarX = 12 + portrait + 8;
  const rightBarX = CANVAS_W - 12 - portrait - 8 - barW;

  const drawPortrait = (img, x, border) => {
    ctx.fillStyle = '#000';
    ctx.fillRect(x - 3, 9, portrait + 6, portrait + 6);
    ctx.fillStyle = border;
    ctx.fillRect(x - 2, 10, portrait + 4, portrait + 4);
    ctx.fillStyle = '#111';
    ctx.fillRect(x, 12, portrait, portrait);
    if (img) ctx.drawImage(img, x, 12, portrait, portrait);
  };
  drawPortrait(assets?.images?.yokoHud || assets?.images?.yoko, 12, '#e8c547');
  drawPortrait(assets?.images?.morlanHud || assets?.images?.morlan, CANVAS_W - 12 - portrait, '#c0392b');

  const drawLife = (x, hp, flip) => {
    ctx.fillStyle = '#1a1208';
    ctx.fillRect(x, barY, barW, barH);
    const w = Math.round(lifeBarWidth(hp, MAX_HP, barW));
    ctx.fillStyle = hp < MAX_HP * 0.22 ? '#e23b3b' : '#3dcc5a';
    if (flip) ctx.fillRect(x + barW - w, barY, w, barH);
    else ctx.fillRect(x, barY, w, barH);
    ctx.fillStyle = '#f4e27a';
    ctx.fillRect(x, barY, barW, 2);
    ctx.fillRect(x, barY + barH - 2, barW, 2);
    ctx.fillRect(x, barY, 2, barH);
    ctx.fillRect(x + barW - 2, barY, 2, barH);
    drawPixelText(ctx, 'LIFE', flip ? x + barW - 52 : x + 6, barY + 6, 2, '#fff8c0');
  };
  drawLife(leftBarX, p1.hp, false);
  drawLife(rightBarX, p2.hp, true);

  const roundLabel = round >= 3 ? 'FINAL' : `ROUND ${round}`;
  drawPixelText(ctx, roundLabel, CANVAS_W / 2, 8, 2, '#ffe566', 'center');

  const clock = String(Math.ceil(timer)).padStart(2, '0');
  ctx.fillStyle = '#000';
  ctx.fillRect(CANVAS_W / 2 - 40, 28, 80, 36);
  drawPixelText(ctx, clock, CANVAS_W / 2, 32, 4, timer <= 10 ? '#ff4d4d' : '#ffe566', 'center');

  for (let i = 0; i < 2; i++) {
    ctx.fillStyle = i < wins[0] ? '#e8c547' : '#333';
    ctx.fillRect(CANVAS_W / 2 - 78 - i * 16, 68, 10, 10);
    ctx.fillStyle = i < wins[1] ? '#c0392b' : '#333';
    ctx.fillRect(CANVAS_W / 2 + 68 + i * 16, 68, 10, 10);
  }

  const drawMeter = (x, meter, color, flip) => {
    const mw = 220, mh = 10, my = CANVAS_H - 28;
    ctx.fillStyle = '#111';
    ctx.fillRect(x, my, mw, mh);
    ctx.fillStyle = meter >= MAX_METER ? '#fff4a8' : color;
    const w = (meter / MAX_METER) * mw;
    if (flip) ctx.fillRect(x + mw - w, my, w, mh);
    else ctx.fillRect(x, my, w, mh);
    ctx.fillStyle = '#eee';
    ctx.fillRect(x, my, mw, 1);
    ctx.fillRect(x, my + mh - 1, mw, 1);
    drawPixelText(ctx, meter >= MAX_METER ? 'SUPER' : 'SUPER', flip ? x + mw : x, my - 12, 1, '#eee', flip ? 'right' : 'left');
  };
  drawMeter(12 + portrait + 8, p1.meter, '#e8c547', false);
  drawMeter(CANVAS_W - 12 - portrait - 8 - 220, p2.meter, '#c0392b', true);

  drawPixelText(ctx, p1.revivesUsed < 1 ? '+' : 'x', 12 + portrait + 8, CANVAS_H - 48, 2, '#f6e6a2');
  drawPixelText(ctx, p2.revivesUsed < 1 ? '+' : 'x', CANVAS_W - 12 - portrait - 8, CANVAS_H - 48, 2, '#f6e6a2', 'right');

  if (combo && combo.count > 1) {
    const cx = combo.side === 'p1' ? 80 : CANVAS_W - 80;
    drawPixelText(ctx, `${combo.count} HIT`, cx, 100, 3, '#fff', combo.side === 'p1' ? 'left' : 'right');
  }

  if (announce.text) {
    const fight = announce.text === 'FIGHT!';
    if (fight) {
      ctx.fillStyle = 'rgba(0,0,0,0.45)';
      ctx.fillRect(0, CANVAS_H - 70, CANVAS_W, 48);
      drawPixelText(ctx, 'FIGHT!', CANVAS_W / 2, CANVAS_H - 64, 6, '#ffffff', 'center');
    } else if (!/^ROUND /.test(announce.text) && announce.text !== 'FINAL ROUND') {
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      ctx.fillRect(0, CANVAS_H / 2 - 40, CANVAS_W, 72);
      drawPixelText(ctx, announce.text, CANVAS_W / 2, CANVAS_H / 2 - 24, 3, '#fff4c2', 'center');
      if (announce.sub) {
        drawPixelText(ctx, announce.sub, CANVAS_W / 2, CANVAS_H / 2 + 12, 1, '#dddddd', 'center');
      }
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
  ctx.imageSmoothingEnabled = false;
  ctx.fillStyle = '#000';
  ctx.fillRect(x - 6, y - 6, w + 12, h + 56);
  ctx.fillStyle = '#e8c547';
  ctx.fillRect(x - 4, y - 4, w + 8, h + 52);
  ctx.fillStyle = '#111';
  ctx.fillRect(x, y, w, h);
  if (img) ctx.drawImage(img, x, y, w, h);
  drawPixelText(ctx, name, x + w / 2, y + h + 10, 2, '#fff', 'center');
  drawPixelText(ctx, title, x + w / 2, y + h + 30, 1, '#ddd', 'center');
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

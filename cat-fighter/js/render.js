import {
  CANVAS_W, CANVAS_H, GROUND_Y, MAX_HP, LASER_MAX, LASER_COST, lerp,
  CHARACTERS,
} from './logic.js';
import {
  drawPixelText, lifeBarWidth, drawPixelFighter, chromaKeyMagenta, SPRITE_DRAW,
  drawAprilPixel,
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
      april: 'assets/april_portrait.png',
      palace: 'assets/palace_stage_pixel.png',
      russia: 'assets/russian_stage_pixel.png',
      yokoHud: 'assets/yoko_hud.png',
      morlanHud: 'assets/morlan_hud.png',
      kittens: 'assets/kittens_portrait.png',
      baby: 'assets/baby_portrait.png',
      kittensHud: 'assets/kittens_hud.png',
      babyHud: 'assets/baby_hud.png',
      yokoSprite: 'assets/yoko_sprite.png',
      morlanSprite: 'assets/morlan_sprite.png',
      stellaSprite: 'assets/stella_sprite.png',
      joyeSprite: 'assets/joye_sprite.png',
      titleLineup: 'assets/title_lineup.png',
    };
    await Promise.all(Object.entries(files).map(([k, src]) => this._img(k, src)));
    if (this.images.yokoSprite) this.images.yokoSprite = chromaKeyMagenta(this.images.yokoSprite);
    if (this.images.morlanSprite) this.images.morlanSprite = chromaKeyMagenta(this.images.morlanSprite);
    if (this.images.stellaSprite) this.images.stellaSprite = chromaKeyMagenta(this.images.stellaSprite);
    if (this.images.joyeSprite) this.images.joyeSprite = chromaKeyMagenta(this.images.joyeSprite);
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
    const n = kind === 'super' ? 28 : kind === 'fairy' ? 22 : kind === 'hit' ? 14 : 10;
    const palette = ['#ff9ad4', '#ffe566', '#fff6d0', '#c89bff', '#ff4da6'];
    for (let i = 0; i < n; i++) {
      const ang = Math.random() * Math.PI * 2;
      const spd = (kind === 'super' ? 7 : kind === 'fairy' ? 3.2 : 4) * (0.4 + Math.random());
      this.list.push({
        x, y,
        vx: Math.cos(ang) * spd + (extra.vx || 0),
        vy: Math.sin(ang) * spd - (kind === 'fairy' ? 2.8 : 1.5),
        life: 18 + Math.random() * 16,
        max: 34,
        kind,
        color: extra.color || (kind === 'milk' ? '#f4f0e0' : kind === 'tuna' ? '#d4a017' : kind === 'fairy' ? palette[i % palette.length] : '#fff3a0'),
        r: 2 + Math.random() * 4,
      });
    }
  }

  update() {
    this.list = this.list.filter((p) => {
      p.life -= 1;
      p.x += p.vx;
      p.y += p.vy;
      p.vy += p.kind === 'fairy' ? -0.06 : 0.12;
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

export function drawFighter(ctx, f) {
  drawPixelFighter(ctx, f);
}

function portraitFor(assets, id) {
  const images = assets?.images || {};
  return images[`${id}Hud`] || images[id];
}

export function drawFighterNames(ctx, p1, p2) {
  const h = 96 * SPRITE_DRAW;
  const gap = Math.abs(p1.x - p2.x);
  const items = [
    { f: p1, name: (CHARACTERS[p1.characterId]?.name || 'YOKO').toUpperCase() },
    { f: p2, name: (CHARACTERS[p2.characterId]?.name || 'MORLAN').toUpperCase() },
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
  if (p.kind === 'laser') {
    const dir = Math.sign(p.vx) || 1;
    const pulse = 0.55 + Math.sin(time * 0.6) * 0.25;
    ctx.fillStyle = `rgba(255, 80, 40, ${pulse})`;
    ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
    ctx.fillStyle = `rgba(255, 230, 120, ${0.7 + pulse * 0.3})`;
    ctx.fillRect(-p.w / 2, -3, p.w, 6);
    ctx.fillStyle = '#fff';
    ctx.fillRect(dir > 0 ? p.w / 2 - 8 : -p.w / 2, -2, 8, 4);
  } else if (p.kind === 'tuna') {
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

export function drawPickup(ctx, p, time) {
  ctx.save();
  ctx.imageSmoothingEnabled = false;
  ctx.translate(Math.round(p.x), Math.round(p.y + Math.sin(time * 0.2) * 3));
  ctx.rotate(Math.sin(time * 0.12) * 0.15);
  if (p.kind === 'chicken') {
    ctx.fillStyle = '#c47a18';
    ctx.fillRect(-14, -8, 28, 16);
    ctx.fillStyle = '#e8c547';
    ctx.fillRect(-12, -6, 24, 12);
    ctx.fillStyle = '#fff4c2';
    ctx.fillRect(8, -4, 10, 8);
    ctx.fillStyle = '#8a4a12';
    ctx.fillRect(-16, -2, 6, 4);
    drawPixelText(ctx, 'CHKN', 0, 12, 1, '#ffe566', 'center');
  } else {
    ctx.fillStyle = '#c0392b';
    ctx.fillRect(-16, -7, 32, 14);
    ctx.fillStyle = '#f4a0a0';
    ctx.fillRect(-14, -5, 28, 10);
    ctx.fillStyle = '#ffe566';
    ctx.fillRect(-2, -3, 6, 6);
    ctx.fillStyle = '#8aa0b0';
    ctx.fillRect(12, -2, 8, 4);
    drawPixelText(ctx, 'SLMN', 0, 12, 1, '#ff8a80', 'center');
  }
  ctx.restore();
}

export function drawStella(ctx, x, y, t, phase, img) {
  ctx.save();
  ctx.translate(x, y);
  const sway = Math.sin(t * 0.04) * 2;
  ctx.translate(sway, 0);
  if (img) {
    ctx.imageSmoothingEnabled = false;
    const h = 120;
    const w = (img.width / img.height) * h;
    ctx.drawImage(img, -w / 2, -h + 88, w, h);
  } else {
    ctx.fillStyle = '#3d2b1f';
    ctx.beginPath();
    ctx.moveTo(-22, 0);
    ctx.lineTo(22, 0);
    ctx.lineTo(28, 90);
    ctx.lineTo(-28, 90);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#6b4423';
    ctx.fillRect(-38, -18, 78, 18);
    ctx.fillStyle = '#1a1a1a';
    ellipse(ctx, 0, -58, 22, 28, true);
    ctx.fillStyle = '#f0d8c8';
    ellipse(ctx, 0, -52, 16, 18, true);
  }
  if (phase === 'place') {
    drawPixelText(ctx, 'THE LOG ASKED FOR MILK', 0, -108, 1, '#fff6d0', 'center');
  }
  ctx.restore();
}

export function drawJoye(ctx, x, y, t, phase, img) {
  ctx.save();
  ctx.translate(x, y);
  const shuffle = Math.sin(t * 0.08) * 1.5;
  ctx.translate(shuffle, 0);
  if (img) {
    ctx.imageSmoothingEnabled = false;
    const h = 120;
    const w = (img.width / img.height) * h;
    ctx.drawImage(img, -w / 2, -h + 88, w, h);
  } else {
    ctx.fillStyle = '#2e6b45';
    roundRect(ctx, -12, -8, 24, 60, 10);
    ctx.fill();
    ctx.fillStyle = '#c4451a';
    ellipse(ctx, 0, -46, 20, 22, true);
    ctx.fillStyle = '#cfd5da';
    roundRect(ctx, 22, -6, 26, 18, 3);
    ctx.fill();
  }
  if (phase === 'feed') {
    drawPixelText(ctx, 'TUNA FOR THE FALLEN', 0, -100, 1, '#fff6d0', 'center');
  }
  ctx.restore();
}

export function drawApril(ctx, x, y, t, phase, img) {
  ctx.save();
  ctx.translate(x, y);
  const sway = Math.sin(t * 0.12) * 3;
  ctx.translate(sway, phase === 'enter' ? Math.max(0, 18 - t) : 0);
  if (img) {
    ctx.imageSmoothingEnabled = false;
    const h = 128;
    const w = (img.width / img.height) * h;
    ctx.drawImage(img, -w / 2, -h + 20, w, h);
  } else {
    drawAprilPixel(ctx, 0, 8, t, phase, 2.4);
  }
  if (phase === 'dust') {
    drawPixelText(ctx, 'FAIRY DUST', 0, -118, 1, '#ff9ad4', 'center');
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
  const p1Ch = CHARACTERS[p1.characterId] || CHARACTERS.yoko;
  const p2Ch = CHARACTERS[p2.characterId] || CHARACTERS.morlan;
  drawPortrait(portraitFor(assets, p1.characterId), 12, p1Ch.color);
  drawPortrait(portraitFor(assets, p2.characterId), CANVAS_W - 12 - portrait, p2Ch.color);

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
    ctx.fillRect(CANVAS_W / 2 - 78 - i * 16, 78, 10, 10);
    ctx.fillStyle = i < wins[1] ? '#c0392b' : '#333';
    ctx.fillRect(CANVAS_W / 2 + 68 + i * 16, 78, 10, 10);
  }

  const drawLaser = (x, laser, color, flip) => {
    const mw = 220, mh = 10, my = barY + barH + 8;
    const ready = laser >= LASER_COST;
    ctx.fillStyle = '#111';
    ctx.fillRect(x, my, mw, mh);
    ctx.fillStyle = ready ? color : '#5a4030';
    const w = (Math.max(0, laser) / LASER_MAX) * mw;
    if (flip) ctx.fillRect(x + mw - w, my, w, mh);
    else ctx.fillRect(x, my, w, mh);
    ctx.fillStyle = '#eee';
    ctx.fillRect(x, my, mw, 1);
    ctx.fillRect(x, my + mh - 1, mw, 1);
    drawPixelText(ctx, ready ? 'LASER' : 'CHARGING', flip ? x + mw : x, my + 14, 1, ready ? '#eee' : '#c9a27a', flip ? 'right' : 'left');
  };
  drawLaser(leftBarX, p1.laser, '#ff6a3a', false);
  drawLaser(rightBarX, p2.laser, '#ff6a3a', true);

  drawPixelText(ctx, p1.revivesUsed < 1 ? '+' : 'x', leftBarX, 68, 2, '#f6e6a2');
  drawPixelText(ctx, p2.revivesUsed < 1 ? '+' : 'x', rightBarX + 400, 68, 2, '#f6e6a2', 'right');

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

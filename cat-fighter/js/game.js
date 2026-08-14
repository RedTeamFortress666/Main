/**
 * Yoko's Tuna Brawl — screens, rounds, Stella milk, Joye tuna.
 *
 * Flow: title → menu → intro → fight ⇄ timeout/revive → roundEnd → matchEnd
 * Adding a stage: drawStage() in render.js already swaps palace / Russia /
 * round-3 mash. Hook extra rounds there.
 */
import {
  CANVAS_W, CANVAS_H, GROUND_Y, ROUND_TIME,
  CHARACTERS, MILK_HEAL, TUNA_HEAL, canMilkTimeout, canTunaRevive,
  matchOver, flavorForWin, isBlocked, gainMeter, contactVoice,
  GAME_TITLE, GAME_SUBTITLE,
} from './logic.js';
import { Input } from './input.js';
import { AudioBus } from './audio.js';
import { Fighter, Projectile, collideProjectile } from './fighter.js';
import { thinkAI } from './ai.js';
import {
  Assets, Particles, drawStage, drawFighter, drawFighterNames, drawProjectile,
  drawStella, drawJoye, drawSaucer, drawHUD, drawLetterbox,
  drawPortraitCard,
} from './render.js';
import { drawPixelText } from './pixel.js';

const emptySnap = () => ({
  left: false, right: false, up: false, down: false,
  lp: false, mp: false, hp: false, lk: false, mk: false, hk: false,
  anyPunch: false, anyKick: false, block: false, dir: 5,
  pressedPunch: false, pressedKick: false, buttonClass: null, attackId: null,
});

export class Game {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.input = new Input();
    this.audio = new AudioBus();
    this.assets = new Assets();
    this.particles = new Particles();
    this.mode = 'boot';
    this.vsCpu = true;
    this.menuIndex = 0;
    this.menuCooldown = 0;
    this.round = 1;
    this.wins = [0, 0];
    this.timer = ROUND_TIME;
    this.timerAcc = 0;
    this.milksThisRound = 0;
    this.p1 = new Fighter({ id: 'p1', side: 'p1', x: 340, characterId: 'yoko' });
    this.p2 = new Fighter({ id: 'p2', side: 'p2', x: 940, characterId: 'morlan' });
    this.projectiles = [];
    this.announce = { text: '', sub: '', t: 0 };
    this.combo = null;
    this.cutscene = null;
    this.shake = 0;
    this.flash = 0;
    this.frozen = false;
    this.hitstop = 0;
    this.time = 0;
    this.quote = '';
    this.winner = null;
    this.contactCd = 0;
    this.wasTouching = false;
    this.debug = {
      fastTimer: /[?&]fasttimeout=1/.test(location.search),
      debug: /[?&]debug=1/.test(location.search),
    };
    this._boundLoop = (t) => this.loop(t);
    this._last = 0;
  }

  async start() {
    await this.assets.load();
    this.mode = 'title';
    requestAnimationFrame(this._boundLoop);
  }

  say(text, frames = 90, sub = '') {
    this.announce = { text, sub, t: frames };
  }

  spawnProjectile(fighter, kind) {
    const vx = fighter.facing * (kind === 'tuna' ? 8.5 : 0.2);
    this.projectiles.push(new Projectile({
      x: fighter.x + fighter.facing * 50,
      y: fighter.y - 90,
      vx,
      owner: fighter.side,
      kind: kind === 'meow' ? 'meow' : 'tuna',
    }));
    if (kind === 'meow') {
      this.projectiles[this.projectiles.length - 1].vx = fighter.facing * 3;
    }
    this.audio.whoosh();
  }

  resetRoundKeepMeter() {
    const m1 = this.p1.meter;
    const m2 = this.p2.meter;
    const r1 = this.p1.revivesUsed;
    const r2 = this.p2.revivesUsed;
    this.p1.resetRound(300);
    this.p2.resetRound(980);
    this.p1.meter = m1;
    this.p2.meter = m2;
    this.p1.revivesUsed = r1;
    this.p2.revivesUsed = r2;
    this.projectiles = [];
    this.milksThisRound = 0;
    this.timer = this.debug.fastTimer ? 8 : ROUND_TIME;
    this.timerAcc = 0;
    this.frozen = false;
    this.cutscene = null;
    this.combo = null;
  }

  beginFight() {
    this.resetRoundKeepMeter();
    this.mode = 'intro';
    this.introT = 0;
    const names = ['', 'ROUND 1', 'ROUND 2', 'FINAL ROUND'];
    this.say(names[this.round] || `ROUND ${this.round}`, 80, 'The tea party will wait.');
    this.audio.ui();
  }

  loop(ts) {
    const dt = Math.min(32, ts - (this._last || ts));
    this._last = ts;
    this.time += 1;
    const frames = dt / (1000 / 60);
    // Run a fixed-ish update; cap to avoid spiral.
    let acc = frames;
    while (acc > 0.5) {
      this.update();
      acc -= 1;
    }
    this.draw();
    this.input.endFrame();
    requestAnimationFrame(this._boundLoop);
  }

  update() {
    if (this._themeMode !== this.mode) {
      this._themeMode = this.mode;
      this.audio.setThemeScene(this.mode);
    }
    if (this.announce.t > 0) this.announce.t -= 1;
    else this.announce.text = '';

    if (this.mode === 'title') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        this.audio.ensure();
        this.audio.ui();
        this.audio.setThemeScene('menu');
        this.mode = 'menu';
        this.menuCooldown = 28;
      }
      return;
    }
    if (this.mode === 'menu') {
      if (this.menuCooldown > 0) this.menuCooldown -= 1;
      if (this.input.just('ArrowUp') || this.input.just('KeyW')) {
        this.menuIndex = (this.menuIndex + 3) % 4;
        this.audio.ui();
      }
      if (this.input.just('ArrowDown') || this.input.just('KeyS')) {
        this.menuIndex = (this.menuIndex + 1) % 4;
        this.audio.ui();
      }
      if (this.menuCooldown <= 0 && (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ'))) {
        this.audio.meow(true);
        if (this.menuIndex === 3) {
          this.mode = 'title';
          return;
        }
        if (this.menuIndex === 2) {
          window.location.href = './downloads.html';
          return;
        }
        this.vsCpu = this.menuIndex === 0;
        this.round = 1;
        this.wins = [0, 0];
        this.p1.meter = 0;
        this.p2.meter = 0;
        this.p1.revivesUsed = 0;
        this.p2.revivesUsed = 0;
        this.beginFight();
      }
      return;
    }
    if (this.mode === 'intro') {
      this.introT += 1;
      if (this.introT === 90) this.say('FIGHT!', 50);
      if (this.introT > 140) this.mode = 'fight';
      this._idlePose();
      return;
    }
    if (this.mode === 'timeout') {
      this._updateTimeout();
      return;
    }
    if (this.mode === 'revive') {
      this._updateRevive();
      return;
    }
    if (this.mode === 'roundEnd') {
      this.roundEndT += 1;
      this._idlePose();
      if (this.roundEndT > 150) {
        const over = matchOver(this.wins[0], this.wins[1]);
        if (over) {
          this.winner = over === 1 ? 'yoko' : 'morlan';
          this.quote = flavorForWin(this.winner);
          this.mode = 'matchEnd';
          this.audio.win();
          this.say(over === 1 ? 'QUEEN YOKO WINS!' : 'TSAR MORLAN IS VICTORIOUS!', 999, this.quote);
        } else {
          this.round += 1;
          this.beginFight();
        }
      }
      return;
    }
    if (this.mode === 'matchEnd') {
      if (this.input.just('Enter') || this.input.just('Space')) {
        this.mode = 'title';
        this.announce = { text: '', sub: '', t: 0 };
      }
      return;
    }

    if (this.mode !== 'fight') return;

    if (this.input.just('Escape')) {
      this.paused = !this.paused;
      return;
    }
    if (this.debug.fastTimer || this.debug.debug) {
      if (this.input.just('F9')) { this.forceTimeout(); return; }
      if (this.input.just('F10')) { this.forceKo('p1'); }
      if (this.input.just('F11')) { this.forceKo('p2'); }
    }
    if (this.paused) return;

    if (this.hitstop > 0) {
      this.hitstop -= 1;
      return;
    }

    this.timerAcc += 1;
    if (this.timerAcc >= 60) {
      this.timerAcc = 0;
      this.timer -= 1;
      if (this.timer <= 0) {
        this.timer = 0;
        this._onTimeout();
        return;
      }
    }

    const s1 = this.input.snapshot('p1', this.p1.facing);
    const s2 = this.vsCpu
      ? (this.time % 8 === 0 ? thinkAI(this.p2, this.p1) : this._aiHold || emptySnap())
      : this.input.snapshot('p2', this.p2.facing);
    if (this.vsCpu && this.time % 8 === 0) this._aiHold = s2;

    const world1 = {
      frozen: false,
      opponent: this.p2,
      spawnProjectile: (f, k) => this.spawnProjectile(f, k),
    };
    const world2 = {
      frozen: false,
      opponent: this.p1,
      spawnProjectile: (f, k) => this.spawnProjectile(f, k),
    };

    this.p1.update(s1, this.p2, world1);
    this.p2.update(s2, this.p1, world2);
    const touching = Fighter.separate(this.p1, this.p2) === true;
    if (this.contactCd > 0) this.contactCd -= 1;
    if (touching && !this.wasTouching && this.contactCd <= 0) {
      const voice = contactVoice(this.p1.attacking, this.p2.attacking);
      if (voice === 'hiss') this.audio.hiss();
      else this.audio.meow(this.p1.attacking || Math.random() < 0.5);
      this.contactCd = 32;
    }
    this.wasTouching = touching;
    if (this.combo) {
      this.combo.t -= 1;
      if (this.combo.t <= 0) this.combo = null;
    }

    this._resolveCombat(this.p1, this.p2);
    this._resolveCombat(this.p2, this.p1);

    for (const proj of this.projectiles) {
      proj.update();
      const target = proj.owner === 'p1' ? this.p2 : this.p1;
      const owner = proj.owner === 'p1' ? this.p1 : this.p2;
      const hit = collideProjectile(proj, target);
      if (hit) {
        this._onHit(hit, owner, target);
      }
    }
    this.projectiles = this.projectiles.filter((p) => !p.dead);
    this.particles.update();
    if (this.shake > 0) this.shake -= 1;
    if (this.flash > 0) this.flash -= 1;

    if (this.p1.hp <= 0) this._onKo(this.p1, this.p2);
    else if (this.p2.hp <= 0) this._onKo(this.p2, this.p1);
  }

  _idlePose() {
    this.p1.animTime += 1;
    this.p2.animTime += 1;
    this.p1.face(this.p2);
    this.p2.face(this.p1);
  }

  _resolveCombat(att, def) {
    if (def.invuln > 0) return;
    const hb = att.currentHitbox();
    if (!hb || !att.attack) return;
    const hurt = def.hurtbox;
    const overlap = hb.x < hurt.x + hurt.w && hb.x + hb.w > hurt.x
      && hb.y < hurt.y + hurt.h && hb.y + hb.h > hurt.y;
    if (!overlap) return;
    const maxHits = att.attack.multi || 1;
    if (att.hasHit >= maxHits) return;
    if (att.attack.multi) {
      const local = att.attackFrame - att.attack.startup;
      const pulse = Math.floor(local / att.attack.multiGap);
      if (pulse < att.hasHit) return;
    }
    const blocked = isBlocked(
      att.attack.type,
      def.blocking,
      def.crouching,
      def.airborne,
    );
    const r = def.takeHit(att.attack, att.facing, blocked);
    att.hasHit += 1;
    this._onHit({ ...r, hb, atk: att.attack, blocked: r.blocked }, att, def);
  }

  _onHit(hit, att, def) {
    this.hitstop = hit.atk?.hitstop || 6;
    this.shake = hit.blocked ? 2 : 8;
    this.particles.spawn((hit.hb?.x || def.x) + 20, (hit.hb?.y || def.y - 80), hit.blocked ? 'block' : 'hit', {
      color: att.characterId === 'yoko' ? '#f6e27a' : '#ff6b6b',
      vx: att.facing * 2,
    });
    att.meter = gainMeter(att.meter, hit.blocked ? 3 : (hit.atk.meterGain || 8));
    def.meter = gainMeter(def.meter, hit.blocked ? 8 : 4);
    if (hit.blocked) this.audio.block();
    else {
      this.audio.hit();
      if (att.attack?.id?.includes('k')) this.audio.kick();
      else this.audio.punch();
      if (Math.random() < 0.35) this.audio.meow(att.characterId === 'yoko');
    }
    if (!hit.blocked) {
      this.combo = { side: att.side, count: def.comboHits, t: 70 };
    }
    if (att.attack?.super) {
      this.flash = 10;
      this.audio.super();
      this.particles.spawn(att.x, att.y - 80, 'super', { color: att.characterId === 'yoko' ? '#ffe566' : '#ff4d4d' });
    }
  }

  _onTimeout() {
    if (canMilkTimeout(this.milksThisRound)) {
      this.mode = 'timeout';
      this.cutscene = { kind: 'stella', t: 0 };
      this.frozen = true;
      this.audio.sting();
      this.say('MILK TIME!', 120, 'Stella has arrived. The log requested a pause.');
      this.p1.state = 'idle';
      this.p2.state = 'idle';
      this.p1.attacking = false;
      this.p2.attacking = false;
      return;
    }
    // Too many milks — decide the round on remaining HP.
    this._finishRoundByHp();
  }

  _finishRoundByHp() {
    let w = 0;
    if (this.p1.hp > this.p2.hp) w = 1;
    else if (this.p2.hp > this.p1.hp) w = 2;
    else w = 0;
    if (w === 0) {
      this.say("DRAW — THE LOG IS UNSATISFIED", 120);
      this.wins[0] += 0;
      this.wins[1] += 0;
      // still advance? treat as no pip, rematch round
      this.mode = 'roundEnd';
      this.roundEndT = 0;
      this.p1.state = 'idle';
      this.p2.state = 'idle';
      return;
    }
    this._awardRound(w);
  }

  _awardRound(winnerSide) {
    if (winnerSide === 1) {
      this.wins[0] += 1;
      this.p1.state = 'win';
      this.p2.state = 'lose';
      this.say('QUEEN YOKO TAKES THE ROUND', 140, 'Capitalism, with extra sardines.');
    } else {
      this.wins[1] += 1;
      this.p2.state = 'win';
      this.p1.state = 'lose';
      this.say('TSAR MORLAN TAKES THE ROUND', 140, 'The winter palace is one paw closer.');
    }
    this.audio.ko();
    this.mode = 'roundEnd';
    this.roundEndT = 0;
  }

  _onKo(koFighter, winner) {
    if (this.mode !== 'fight') return;
    if (canTunaRevive(koFighter.revivesUsed)) {
      this.mode = 'revive';
      this.cutscene = { kind: 'joye', t: 0, target: koFighter, other: winner };
      this.audio.sting();
      this.audio.tuna();
      this.say('TUNA FOR THE FALLEN!', 100, 'Joye shuffles in with her walker and a tin of tuna.');
      koFighter.state = 'ko';
      koFighter.attacking = false;
      return;
    }
    const side = koFighter.side === 'p1' ? 2 : 1;
    this._awardRound(side);
  }

  _updateTimeout() {
    const cs = this.cutscene;
    cs.t += 1;
    this.p1.animTime += 1;
    this.p2.animTime += 1;
    this.particles.update();
    if (cs.t === 40) {
      this.p1.state = 'drink';
      this.p2.state = 'drink';
    }
    if (cs.t > 90 && cs.t < 200 && cs.t % 8 === 0) {
      this.p1.heal(MILK_HEAL / 12);
      this.p2.heal(MILK_HEAL / 12);
      this.particles.spawn(this.p1.x, GROUND_Y - 20, 'milk');
      this.particles.spawn(this.p2.x, GROUND_Y - 20, 'milk');
      if (cs.t % 16 === 0) this.audio.milk();
    }
    if (cs.t > 360) {
      this.milksThisRound += 1;
      this.timer = 40;
      this.timerAcc = 0;
      this.mode = 'fight';
      this.frozen = false;
      this.cutscene = null;
      this.p1.state = 'idle';
      this.p2.state = 'idle';
      this.say('THE LOG IS SATISFIED', 70, 'Round continues.');
      this.audio.meow();
    }
  }

  _updateRevive() {
    const cs = this.cutscene;
    cs.t += 1;
    const cat = cs.target;
    cat.animTime += 1;
    cs.other.animTime += 1;
    this.particles.update();
    if (cs.t === 50) cat.state = 'eat';
    if (cs.t > 70 && cs.t < 160 && cs.t % 6 === 0) {
      cat.heal(TUNA_HEAL / 10);
      this.particles.spawn(cat.x, cat.y - 40, 'tuna', { color: '#d4a017' });
    }
    if (cs.t === 80) this.audio.tuna();
    if (cs.t > 280) {
      cat.revivesUsed += 1;
      cat.hp = Math.max(cat.hp, 160);
      cat.state = 'idle';
      cat.y = GROUND_Y;
      this.mode = 'fight';
      this.cutscene = null;
      this.say('THE FALLEN RISES', 70, 'One tin. One more chance.');
      this.audio.meow(true);
    }
  }

  draw() {
    const ctx = this.ctx;
    ctx.imageSmoothingEnabled = false;
    ctx.save();
    if (this.shake) {
      ctx.translate((Math.random() - 0.5) * this.shake, (Math.random() - 0.5) * this.shake);
    }

    if (this.mode === 'title' || this.mode === 'boot') {
      this._drawTitle(ctx);
      ctx.restore();
      return;
    }
    if (this.mode === 'menu') {
      this._drawMenu(ctx);
      ctx.restore();
      return;
    }
    if (this.mode === 'matchEnd') {
      this._drawMatchEnd(ctx);
      ctx.restore();
      return;
    }

    drawStage(ctx, this.assets, this.round, this.time, this.flash);
    const back = this.p1.y <= this.p2.y ? this.p1 : this.p2;
    const front = back === this.p1 ? this.p2 : this.p1;
    drawFighter(ctx, back, this.assets);
    drawFighter(ctx, front, this.assets);
    drawFighterNames(ctx, this.p1, this.p2);
    for (const p of this.projectiles) drawProjectile(ctx, p, this.time);
    this.particles.draw(ctx);

    if (this.mode === 'timeout' && this.cutscene) {
      drawLetterbox(ctx, 0.82);
      ctx.fillStyle = 'rgba(10,0,20,0.35)';
      ctx.fillRect(0, 90, CANVAS_W, CANVAS_H - 180);
      const t = this.cutscene.t;
      const sx = CANVAS_W / 2;
      const enter = Math.min(1, t / 35);
      ctx.save();
      ctx.translate(sx, GROUND_Y - 20);
      ctx.scale(2.15, 2.15);
      drawStella(ctx, 0, -70 + (1 - enter) * 40, t, t > 50 ? 'place' : 'enter');
      ctx.restore();
      if (t > 40) {
        drawSaucer(ctx, this.p1.x + 36, GROUND_Y - 4, true);
        drawSaucer(ctx, this.p2.x - 36, GROUND_Y - 4, true);
      }
      const img = this.assets.images.stella;
      if (img && t > 10) {
        ctx.globalAlpha = Math.min(1, (t - 10) / 20) * 0.98;
        ctx.drawImage(img, 40, 100, 200, 280);
        ctx.globalAlpha = 1;
        ctx.fillStyle = '#f6e27a';
        ctx.font = 'italic 18px Georgia, serif';
        ctx.textAlign = 'left';
        ctx.fillText('Stella', 40, 396);
        ctx.fillStyle = '#ddd';
        ctx.font = '13px Georgia, serif';
        ctx.fillText('The log has spoken.', 40, 416);
      }
    }
    if (this.mode === 'revive' && this.cutscene) {
      drawLetterbox(ctx, 0.75);
      ctx.fillStyle = 'rgba(40,10,0,0.28)';
      ctx.fillRect(0, 90, CANVAS_W, CANVAS_H - 180);
      const cat = this.cutscene.target;
      const t = this.cutscene.t;
      ctx.save();
      ctx.translate(cat.x + cat.facing * -80, GROUND_Y - 10);
      ctx.scale(1.9, 1.9);
      drawJoye(ctx, 0, -50, t, t > 50 ? 'feed' : 'enter');
      ctx.restore();
      const img = this.assets.images.joye;
      if (img) {
        ctx.drawImage(img, CANVAS_W - 250, 100, 200, 280);
        ctx.fillStyle = '#ffd39a';
        ctx.font = 'italic 18px Georgia, serif';
        ctx.textAlign = 'right';
        ctx.fillText('Joye', CANVAS_W - 50, 396);
        ctx.fillStyle = '#ddd';
        ctx.font = '13px Georgia, serif';
        ctx.fillText('Tuna for the fallen, dears.', CANVAS_W - 50, 416);
      }
    }

    drawHUD(ctx, {
      p1: this.p1,
      p2: this.p2,
      timer: this.timer,
      wins: this.wins,
      announce: this.announce,
      combo: this.mode === 'fight' && this.combo && this.combo.count > 1 ? this.combo : null,
      round: this.round,
      assets: this.assets,
    });

    if (this.paused) {
      ctx.fillStyle = 'rgba(0,0,0,0.55)';
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
      drawPixelText(ctx, 'PAUSED', CANVAS_W / 2, CANVAS_H / 2 - 16, 5, '#fff', 'center');
      drawPixelText(ctx, 'ESC TO RESUME', CANVAS_W / 2, CANVAS_H / 2 + 28, 2, '#ddd', 'center');
    }
    ctx.restore();
  }

  _drawTitle(ctx) {
    drawStage(ctx, this.assets, 3, this.time, 0);
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPortraitCard(ctx, this.assets.images.yoko, 80, 150, 280, 360, 'QUEEN YOKO', CHARACTERS.yoko.title);
    drawPortraitCard(ctx, this.assets.images.morlan, CANVAS_W - 360, 150, 280, 360, 'TSAR MORLAN', CHARACTERS.morlan.title);

    drawPixelText(ctx, GAME_TITLE, CANVAS_W / 2, 36, 4, '#ffe566', 'center');
    drawPixelText(ctx, GAME_SUBTITLE, CANVAS_W / 2, 78, 2, '#ffffff', 'center');
    drawPixelText(ctx, 'A SLIGHTLY MYSTICAL TEA PARTY', CANVAS_W / 2, 590, 1, '#dddddd', 'center');

    const blink = Math.sin(this.time * 0.12) > -0.2;
    if (blink) {
      drawPixelText(ctx, 'PRESS ENTER', CANVAS_W / 2, 630, 3, '#fff4c2', 'center');
    }
    drawPixelText(ctx, 'Z SPACE OR TAP  -  ESC PAUSES', CANVAS_W / 2, 678, 1, '#aaaaaa', 'center');
  }

  _drawMenu(ctx) {
    drawStage(ctx, this.assets, 1, this.time, 0);
    ctx.fillStyle = 'rgba(8,6,20,0.72)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, 'CHOOSE YOUR IDEOLOGY', CANVAS_W / 2, 36, 3, '#ffe566', 'center');

    const items = [
      'VS CPU',
      'VS PLAYER',
      'DOWNLOADS',
      'BACK',
    ];
    items.forEach((label, i) => {
      const y = 90 + i * 40;
      const on = i === this.menuIndex;
      drawPixelText(ctx, (on ? '> ' : '  ') + label, CANVAS_W / 2, y, on ? 3 : 2, on ? '#fff4c2' : '#bbbbbb', 'center');
    });

    drawPixelText(ctx, 'P1  QUEEN YOKO', 80, 280, 2, '#ffe566');
    const p1 = [
      'WASD MOVE',
      'SHIFT BLOCK',
      'Z X C PUNCH',
      'F G H KICK',
      'QCF + BUTTON SPECIAL',
      'DOUBLE QCF SUPER',
    ];
    p1.forEach((l, i) => drawPixelText(ctx, l, 80, 310 + i * 18, 1, '#dddddd'));

    drawPixelText(ctx, 'P2  TSAR MORLAN', 700, 280, 2, '#ff8a80');
    const p2 = [
      'ARROWS MOVE',
      'SHIFT BLOCK',
      'N M , PUNCH',
      'J K L KICK',
      'SAME MOTIONS',
      'FULL METER SUPER',
    ];
    p2.forEach((l, i) => drawPixelText(ctx, l, 700, 310 + i * 18, 1, '#dddddd'));

    drawPixelText(ctx, 'TIMEOUT: STELLA MILK   KO: JOYE TUNA REVIVE   BEST OF 3', CANVAS_W / 2, 500, 1, '#aaaaaa', 'center');
    drawPixelText(ctx, 'ENTER / Z TO CONFIRM', CANVAS_W / 2, 640, 2, '#fff4c2', 'center');
  }

  _drawMatchEnd(ctx) {
    drawStage(ctx, this.assets, this.round, this.time, 0);
    ctx.fillStyle = 'rgba(0,0,0,0.62)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    const w = this.winner;
    const img = this.assets.images[w === 'yoko' ? 'yokoHud' : 'morlanHud'] || this.assets.images[w];
    ctx.imageSmoothingEnabled = false;
    if (img) {
      ctx.drawImage(img, CANVAS_W / 2 - 120, 80, 240, 240);
    }
    drawPixelText(ctx, this.announce.text || 'WINNER', CANVAS_W / 2, 360, 3, '#ffe566', 'center');
    drawPixelText(ctx, this.quote || '', CANVAS_W / 2, 410, 1, '#eeeeee', 'center');
    drawPixelText(ctx, 'THE TEA PARTY IS ADJOURNED', CANVAS_W / 2, 560, 2, '#cccccc', 'center');
    drawPixelText(ctx, 'PRESS ENTER', CANVAS_W / 2, 630, 3, '#fff4c2', 'center');
  }

  /** Demo / test hooks. */
  forceTimeout() {
    if (this.mode === 'fight') {
      this.timer = 0;
      this.timerAcc = 60;
    }
  }

  forceKo(side = 'p2') {
    const f = side === 'p1' ? this.p1 : this.p2;
    f.hp = 0;
  }
}

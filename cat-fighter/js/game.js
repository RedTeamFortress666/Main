/**
 * Yoko's Tuna Brawl — screens, rounds, Stella milk, Joye tuna.
 *
 * Flow: title → menu → intro → fight ⇄ timeout/revive → roundEnd → matchEnd
 * Adding a stage: drawStage() in render.js already swaps palace / Russia /
 * round-3 mash. Hook extra rounds there.
 */
import {
  CANVAS_W, CANVAS_H, GROUND_Y, ROUND_TIME,
  MILK_HEAL, TUNA_HEAL, canMilkTimeout, canTunaRevive,
  matchOver, flavorForWin, isBlocked, gainMeter, contactVoice,
  GAME_TITLE, GAME_SUBTITLE, afterRoundEnd,
  POWERUP_DURATION, pickupHitsFighter, sideDamageMult,
  CHARACTERS, SELECTABLE_FIGHTERS, defaultRival, winBanner, roundBanner,
} from './logic.js';
import { Input } from './input.js';
import { AudioBus } from './audio.js';
import { Fighter, Projectile, collideProjectile } from './fighter.js';
import { thinkAI } from './ai.js';
import { createRace, updateRace, drawRace } from './race.js';
import {
  Assets, Particles, drawStage, drawFighter, drawFighterNames, drawProjectile,
  drawPickup, drawStella, drawJoye, drawSaucer, drawHUD, drawLetterbox,
} from './render.js';
import { drawPixelText } from './pixel.js';

const emptySnap = () => ({
  left: false, right: false, up: false, down: false,
  jump: false, punch: false, kick: false, laser: false,
  lp: false, rp: false, lk: false, rk: false,
  mp: false, hp: false, mk: false, hk: false,
  anyPunch: false, anyKick: false, block: false, dir: 5,
  pressedPunch: false, pressedKick: false, buttonClass: null, attackId: null,
  limb: null, throw: false, sidestep: false,
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
    this.product = 'battle';
    this.vsCpu = true;
    this.menuIndex = 0;
    this.modeSelectIndex = 0;
    this.menuCooldown = 0;
    this.p1Select = 0;
    this.p2Select = 1;
    this.charSelectSlot = 'p1';
    this.race = null;
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
    this.pickups = [];
    this.chickenCd = 200;
    this.salmonCd = 480;
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
    const laser = kind === 'laser';
    const vx = fighter.facing * (laser ? 16 : kind === 'tuna' ? 8.5 : 0.2);
    this.projectiles.push(new Projectile({
      x: fighter.x + fighter.facing * (laser ? 70 : 50),
      y: fighter.y - (laser ? 108 : 90),
      vx,
      owner: fighter.side,
      kind: laser ? 'laser' : kind === 'meow' ? 'meow' : 'tuna',
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
    this.pickups = [];
    this.chickenCd = 180;
    this.salmonCd = 420;
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
    const intro = CHARACTERS[this.p1.characterId]?.intro || 'The tea party will wait.';
    this.say(names[this.round] || `ROUND ${this.round}`, 80, intro);
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
        this.mode = 'modeSelect';
        this.modeSelectIndex = 0;
        this.menuCooldown = 20;
      }
      return;
    }
    if (this.mode === 'modeSelect') {
      this._updateModeSelect();
      return;
    }
    if (this.mode === 'charSelect') {
      this._updateCharSelect();
      return;
    }
    if (this.mode === 'raceMenu') {
      this._updateRaceMenu();
      return;
    }
    if (this.mode === 'race') {
      this._updateRace();
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
          this.mode = 'modeSelect';
          this.menuCooldown = 16;
          return;
        }
        if (this.menuIndex === 2) {
          window.location.href = './downloads.html';
          return;
        }
        this.vsCpu = this.menuIndex === 0;
        this._openCharSelect();
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
        const next = afterRoundEnd(this.wins[0], this.wins[1]);
        if (next === 'matchEnd') {
          const over = matchOver(this.wins[0], this.wins[1]);
          this.winner = over === 1 ? this.p1.characterId : this.p2.characterId;
          this.quote = flavorForWin(this.winner);
          this.mode = 'matchEnd';
          this.audio.win();
          this.say(winBanner(this.winner), 999, this.quote);
        } else {
          this.round += 1;
          this._beginStellaVisit({ betweenRounds: true });
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
    let s2;
    if (this.vsCpu) {
      if (this.time % 16 === 0) this._aiHold = thinkAI(this.p2, this.p1, 0.18);
      s2 = { ...(this._aiHold || emptySnap()) };
      if (this.time % 16 !== 0) {
        s2.punch = false;
        s2.kick = false;
        s2.laser = false;
        s2.jump = false;
        s2.pressedPunch = false;
        s2.pressedKick = false;
      }
    } else {
      s2 = this.input.snapshot('p2', this.p2.facing);
    }

    this.p1.damageMult = sideDamageMult('p1', this.vsCpu, this.p1.powerT > 0);
    this.p2.damageMult = sideDamageMult('p2', this.vsCpu, this.p2.powerT > 0);

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
        hit.atk.damage = Math.round(hit.atk.damage * (owner.damageMult || 1));
        this._onHit(hit, owner, target);
      }
    }
    this.projectiles = this.projectiles.filter((p) => !p.dead);
    this._updatePickups();
    this.particles.update();
    if (this.shake > 0) this.shake -= 1;
    if (this.flash > 0) this.flash -= 1;

    if (this.p1.hp <= 0) this._onKo(this.p1, this.p2);
    else if (this.p2.hp <= 0) this._onKo(this.p2, this.p1);
  }

  _updatePickups() {
    this.chickenCd -= 1;
    this.salmonCd -= 1;
    if (this.chickenCd <= 0) {
      this.chickenCd = 360 + Math.floor(Math.random() * 180);
      this.pickups.push({
        kind: 'chicken', helper: 'joye',
        x: 48, y: GROUND_Y - 160, vx: 5.2, vy: -2.4, life: 260,
      });
      this.say('JOYE TOSSES CHICKEN', 48, 'Capitalist Chicken for Yoko');
    }
    if (this.salmonCd <= 0) {
      this.salmonCd = 720 + Math.floor(Math.random() * 240);
      this.pickups.push({
        kind: 'salmon', helper: 'stella',
        x: CANVAS_W - 48, y: GROUND_Y - 160, vx: -5.2, vy: -2.4, life: 260,
      });
      this.say('STELLA TOSSES SALMON', 48, 'Soviet Salmon for Morlan');
    }
    for (const p of this.pickups) {
      if (p.kind === 'chicken') p.vx += Math.sign(this.p1.x - p.x) * 0.18;
      if (p.kind === 'salmon') p.vx += Math.sign(this.p2.x - p.x) * 0.18;
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.12;
      if (p.y > GROUND_Y - 36) {
        p.y = GROUND_Y - 36;
        p.vy *= -0.32;
        p.vx *= 0.9;
      }
      p.life -= 1;
    }
    const kept = [];
    for (const p of this.pickups) {
      if (p.life <= 0) continue;
      if (p.kind === 'chicken' && pickupHitsFighter(p, this.p1)) {
        this.p1.grantPower('chicken', POWERUP_DURATION);
        this.say('CAPITALIST CHICKEN', 80, 'Strength  speed  invulnerable');
        this.particles.spawn(this.p1.x, this.p1.y - 80, 'super', { color: '#e8c547' });
        this.audio.meow(true);
        continue;
      }
      if (p.kind === 'salmon' && pickupHitsFighter(p, this.p2)) {
        this.p2.grantPower('salmon', POWERUP_DURATION);
        this.say('SOVIET SALMON', 80, 'Strength  speed  invulnerable');
        this.particles.spawn(this.p2.x, this.p2.y - 80, 'super', { color: '#c0392b' });
        this.audio.meow(true);
        continue;
      }
      kept.push(p);
    }
    this.pickups = kept;
  }

  _idlePose() {
    this.p1.animTime += 1;
    this.p2.animTime += 1;
    this.p1.face(this.p2);
    this.p2.face(this.p1);
  }

  _resolveCombat(att, def) {
    if (def.invuln > 0) return;
    if (def.state === 'sidestep' && att.attack?.type !== 'low') return;
    if (att.attack?.type === 'throw' && def.attack?.type === 'throw') {
      att.vx = -att.facing * 7;
      def.vx = -def.facing * 7;
      att.attacking = false;
      def.attacking = false;
      att.attack = null;
      def.attack = null;
      att.state = 'idle';
      def.state = 'idle';
      this.say('THROW BREAK', 40);
      return;
    }
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
    const scaled = {
      ...att.attack,
      damage: Math.round(att.attack.damage * (att.damageMult || 1)),
      chip: Math.round((att.attack.chip || 0) * (att.damageMult || 1)),
    };
    const blocked = isBlocked(
      scaled.type,
      def.blocking,
      def.crouching,
      def.airborne,
    );
    const r = def.takeHit(scaled, att.facing, blocked);
    att.hasHit += 1;
    this._onHit({ ...r, hb, atk: scaled, blocked: r.blocked }, att, def);
  }

  _onHit(hit, att, def) {
    this.hitstop = hit.atk?.hitstop || 6;
    this.shake = hit.blocked ? 2 : 8;
    this.particles.spawn((hit.hb?.x || def.x) + 20, (hit.hb?.y || def.y - 80), hit.blocked ? 'block' : 'hit', {
      color: CHARACTERS[att.characterId]?.color || '#ff6b6b',
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
      this.particles.spawn(att.x, att.y - 80, 'super', { color: CHARACTERS[att.characterId]?.color || '#ff4d4d' });
    }
  }

  _onTimeout() {
    if (canMilkTimeout(this.milksThisRound)) {
      this._beginStellaVisit({ betweenRounds: false });
      return;
    }
    // Too many milks — decide the round on remaining HP.
    this._finishRoundByHp();
  }

  _beginStellaVisit({ betweenRounds = false } = {}) {
    this.mode = 'timeout';
    this.cutscene = { kind: 'stella', t: 0, betweenRounds };
    this.frozen = true;
    this.audio.sting();
    this.say(
      'MILK TIME!',
      120,
      betweenRounds ? 'Stella serves milk between rounds. The log asked.' : 'Stella has arrived. The log requested a pause.',
    );
    this.p1.state = 'idle';
    this.p2.state = 'idle';
    this.p1.attacking = false;
    this.p2.attacking = false;
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
      this.say(roundBanner(this.p1.characterId), 140, CHARACTERS[this.p1.characterId]?.intro || '');
    } else {
      this.wins[1] += 1;
      this.p2.state = 'win';
      this.p1.state = 'lose';
      this.say(roundBanner(this.p2.characterId), 140, CHARACTERS[this.p2.characterId]?.intro || '');
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
    if (!cs.betweenRounds && cs.t > 90 && cs.t < 200 && cs.t % 8 === 0) {
      this.p1.heal(MILK_HEAL / 12);
      this.p2.heal(MILK_HEAL / 12);
      this.particles.spawn(this.p1.x, GROUND_Y - 20, 'milk');
      this.particles.spawn(this.p2.x, GROUND_Y - 20, 'milk');
      if (cs.t % 16 === 0) this.audio.milk();
    }
    if (cs.betweenRounds && cs.t > 90 && cs.t < 180 && cs.t % 16 === 0) {
      this.particles.spawn(this.p1.x, GROUND_Y - 20, 'milk');
      this.particles.spawn(this.p2.x, GROUND_Y - 20, 'milk');
      this.audio.milk();
    }
    const doneAt = cs.betweenRounds ? 220 : 360;
    if (cs.t > doneAt) {
      this.cutscene = null;
      this.frozen = false;
      this.p1.state = 'idle';
      this.p2.state = 'idle';
      if (cs.betweenRounds) {
        this.beginFight();
        return;
      }
      this.milksThisRound += 1;
      this.timer = 40;
      this.timerAcc = 0;
      this.mode = 'fight';
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
    if (this.mode === 'modeSelect') {
      this._drawModeSelect(ctx);
      ctx.restore();
      return;
    }
    if (this.mode === 'raceMenu') {
      this._drawRaceMenu(ctx);
      ctx.restore();
      return;
    }
    if (this.mode === 'race') {
      drawRace(ctx, this.race);
      ctx.restore();
      return;
    }
    if (this.mode === 'menu') {
      this._drawMenu(ctx);
      ctx.restore();
      return;
    }
    if (this.mode === 'charSelect') {
      this._drawCharSelect(ctx);
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
    drawFighter(ctx, back);
    drawFighter(ctx, front);
    drawFighterNames(ctx, this.p1, this.p2);
    for (const p of this.pickups) {
      if (p.life > 210 && p.helper === 'joye') {
        drawJoye(ctx, 70, GROUND_Y - 90, this.time, 'feed', this.assets.images.joyeSprite);
      }
      if (p.life > 210 && p.helper === 'stella') {
        drawStella(ctx, CANVAS_W - 70, GROUND_Y - 90, this.time, 'place', this.assets.images.stellaSprite);
      }
      drawPickup(ctx, p, this.time);
    }
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
      ctx.scale(2.35, 2.35);
      drawStella(ctx, 0, -70 + (1 - enter) * 40, t, t > 50 ? 'place' : 'enter', this.assets.images.stellaSprite);
      ctx.restore();
      if (t > 40) {
        drawSaucer(ctx, this.p1.x + 36, GROUND_Y - 4, true);
        drawSaucer(ctx, this.p2.x - 36, GROUND_Y - 4, true);
      }
      const img = this.assets.images.stella;
      if (img && t > 10) {
        ctx.imageSmoothingEnabled = false;
        ctx.globalAlpha = Math.min(1, (t - 10) / 20) * 0.98;
        ctx.drawImage(img, 36, 96, 210, 300);
        ctx.globalAlpha = 1;
        drawPixelText(ctx, 'STELLA', 40, 410, 2, '#f6e27a');
        drawPixelText(ctx, 'THE LOG ASKED FOR MILK', 40, 432, 1, '#dddddd');
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
      ctx.scale(2.2, 2.2);
      drawJoye(ctx, 0, -50, t, t > 50 ? 'feed' : 'enter', this.assets.images.joyeSprite);
      ctx.restore();
      const img = this.assets.images.joye;
      if (img) {
        ctx.imageSmoothingEnabled = false;
        ctx.drawImage(img, CANVAS_W - 250, 96, 210, 300);
        drawPixelText(ctx, 'JOYE', CANVAS_W - 50, 410, 2, '#ffd39a', 'right');
        drawPixelText(ctx, 'TUNA FOR THE FALLEN', CANVAS_W - 50, 432, 1, '#dddddd', 'right');
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

  _openCharSelect() {
    this.mode = 'charSelect';
    this.charSelectSlot = 'p1';
    this.menuCooldown = 12;
    if (this.p2Select === this.p1Select) {
      this.p2Select = (this.p1Select + 1) % SELECTABLE_FIGHTERS.length;
    }
  }

  _applySelectedFighters() {
    const p1id = SELECTABLE_FIGHTERS[this.p1Select] || 'yoko';
    let p2id = SELECTABLE_FIGHTERS[this.p2Select] || 'morlan';
    if (p1id === p2id) p2id = defaultRival(p1id);
    this.p1.characterId = p1id;
    this.p2.characterId = p2id;
    this.round = 1;
    this.wins = [0, 0];
    this.p1.meter = 0;
    this.p2.meter = 0;
    this.p1.revivesUsed = 0;
    this.p2.revivesUsed = 0;
  }

  _updateCharSelect() {
    if (this.menuCooldown > 0) this.menuCooldown -= 1;
    const n = SELECTABLE_FIGHTERS.length;
    const key = this.charSelectSlot === 'p1' ? 'p1Select' : 'p2Select';
    if (this.input.just('ArrowLeft') || this.input.just('KeyA')) {
      this[key] = (this[key] + n - 1) % n;
      this.audio.ui();
    }
    if (this.input.just('ArrowRight') || this.input.just('KeyD')) {
      this[key] = (this[key] + 1) % n;
      this.audio.ui();
    }
    if (this.input.just('Escape')) {
      this.mode = 'menu';
      this.menuCooldown = 12;
      return;
    }
    if (this.menuCooldown <= 0 && (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ'))) {
      this.audio.meow(true);
      if (this.charSelectSlot === 'p1') {
        this.charSelectSlot = 'p2';
        if (this.p2Select === this.p1Select) {
          this.p2Select = (this.p1Select + 1) % n;
        }
        this.menuCooldown = 10;
        return;
      }
      this._applySelectedFighters();
      this.beginFight();
    }
  }

  _updateModeSelect() {
    if (this.menuCooldown > 0) this.menuCooldown -= 1;
    if (this.input.just('ArrowUp') || this.input.just('KeyW')) {
      this.modeSelectIndex = (this.modeSelectIndex + 2) % 3;
      this.audio.ui();
    }
    if (this.input.just('ArrowDown') || this.input.just('KeyS')) {
      this.modeSelectIndex = (this.modeSelectIndex + 1) % 3;
      this.audio.ui();
    }
    if (this.menuCooldown <= 0 && (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ'))) {
      this.audio.meow(true);
      if (this.modeSelectIndex === 2) {
        this.mode = 'title';
        return;
      }
      if (this.modeSelectIndex === 0) {
        this.product = 'battle';
        this.mode = 'menu';
        this.menuIndex = 0;
        this.menuCooldown = 16;
        return;
      }
      this.product = 'race';
      this.mode = 'raceMenu';
      this.menuIndex = 0;
      this.menuCooldown = 16;
    }
  }

  _updateRaceMenu() {
    if (this.menuCooldown > 0) this.menuCooldown -= 1;
    if (this.input.just('ArrowUp') || this.input.just('KeyW')) {
      this.menuIndex = (this.menuIndex + 2) % 3;
      this.audio.ui();
    }
    if (this.input.just('ArrowDown') || this.input.just('KeyS')) {
      this.menuIndex = (this.menuIndex + 1) % 3;
      this.audio.ui();
    }
    if (this.menuCooldown <= 0 && (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ'))) {
      this.audio.meow(true);
      if (this.menuIndex === 2) {
        this.mode = 'modeSelect';
        this.menuCooldown = 16;
        return;
      }
      this.vsCpu = this.menuIndex === 0;
      this.race = createRace(this.vsCpu);
      this.mode = 'race';
      this.audio.ensure();
      this.say('3 LAPS', 80, 'Heads out the sunroof.');
    }
  }

  _updateRace() {
    if (this.input.just('Escape')) {
      this.mode = 'modeSelect';
      this.menuCooldown = 16;
      return;
    }
    const p1 = this.input.snapshot('p1', 1);
    const p2 = this.vsCpu ? emptySnap() : this.input.snapshot('p2', 1);
    updateRace(this.race, p1, p2);
    if (this.race.done && (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ'))) {
      this.mode = 'title';
    }
  }

  _drawTitle(ctx) {
    const lineup = this.assets.images.titleLineup;
    ctx.imageSmoothingEnabled = false;
    if (lineup) {
      ctx.drawImage(lineup, 0, 0, CANVAS_W, CANVAS_H);
      ctx.fillStyle = 'rgba(0,0,0,0.45)';
      ctx.fillRect(0, 0, CANVAS_W, 108);
      ctx.fillRect(0, CANVAS_H - 128, CANVAS_W, 128);
    } else {
      drawStage(ctx, this.assets, 3, this.time, 0);
      ctx.fillStyle = 'rgba(0,0,0,0.55)';
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    }

    drawPixelText(ctx, GAME_TITLE, CANVAS_W / 2, 28, 4, '#ffe566', 'center');
    drawPixelText(ctx, GAME_SUBTITLE, CANVAS_W / 2, 68, 2, '#ffffff', 'center');
    drawPixelText(ctx, 'MORLAN', 210, 548, 2, '#ff8a80', 'center');
    drawPixelText(ctx, 'STELLA', 500, 548, 2, '#c8e6c0', 'center');
    drawPixelText(ctx, 'JOYE', 780, 548, 2, '#ffd39a', 'center');
    drawPixelText(ctx, 'YOKO', 1070, 548, 2, '#ffe566', 'center');
    drawPixelText(ctx, 'BACK TO BACK  -  THE LOG AND THE WALKER', CANVAS_W / 2, 578, 1, '#dddddd', 'center');

    const blink = Math.sin(this.time * 0.12) > -0.2;
    if (blink) {
      drawPixelText(ctx, 'PRESS ENTER', CANVAS_W / 2, 620, 3, '#fff4c2', 'center');
    }
    drawPixelText(ctx, 'CAT BATTLE  OR  CAT CAR RACING', CANVAS_W / 2, 658, 1, '#ffe566', 'center');
    drawPixelText(ctx, 'Z SPACE START OR TAP  -  ESC PAUSES', CANVAS_W / 2, 678, 1, '#aaaaaa', 'center');
  }

  _drawModeSelect(ctx) {
    drawStage(ctx, this.assets, 1, this.time, 0);
    ctx.fillStyle = 'rgba(8,6,20,0.72)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, GAME_TITLE, CANVAS_W / 2, 36, 4, '#ffe566', 'center');
    drawPixelText(ctx, 'CHOOSE YOUR GAME', CANVAS_W / 2, 88, 2, '#ffffff', 'center');

    const items = [
      ['CAT BATTLE', 'PUNCH  KICK  JUMP  LASER EYES  -  ON-SCREEN PAD'],
      ['CAT CAR RACING', 'YOKO ROLLS  MORLAN HEARSE  BABY LOTUS  KITTENS BEETLE'],
      ['BACK', 'RETURN TO TITLE'],
    ];
    items.forEach(([label, sub], i) => {
      const y = 180 + i * 90;
      const on = i === this.modeSelectIndex;
      drawPixelText(ctx, (on ? '> ' : '  ') + label, CANVAS_W / 2, y, on ? 4 : 3, on ? '#fff4c2' : '#bbbbbb', 'center');
      drawPixelText(ctx, sub, CANVAS_W / 2, y + 40, 1, on ? '#ffe566' : '#888888', 'center');
    });
    drawPixelText(ctx, 'W S TO MOVE   ENTER TO CONFIRM', CANVAS_W / 2, 640, 2, '#fff4c2', 'center');
  }

  _drawRaceMenu(ctx) {
    drawStage(ctx, this.assets, 3, this.time, 0);
    ctx.fillStyle = 'rgba(8,6,20,0.72)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, 'CAT CAR RACING', CANVAS_W / 2, 36, 4, '#ffe566', 'center');
    drawPixelText(ctx, '3 LAPS  -  HEADS OUT THE SUNROOF', CANVAS_W / 2, 84, 2, '#ffffff', 'center');

    const items = ['VS CPU', 'VS PLAYER', 'BACK'];
    items.forEach((label, i) => {
      const y = 160 + i * 48;
      const on = i === this.menuIndex;
      drawPixelText(ctx, (on ? '> ' : '  ') + label, CANVAS_W / 2, y, on ? 3 : 2, on ? '#fff4c2' : '#bbbbbb', 'center');
    });

    const roster = [
      ['YOKO', 'GOLD ROLLS ROYCE', '#e8c547'],
      ['MORLAN', 'BLACK HEARSE', '#ff8a80'],
      ['BABY', 'BLUE LOTUS', '#8ad4ff'],
      ['KITTENS', 'RED VW BEETLE', '#ff6b6b'],
    ];
    roster.forEach(([n, car, col], i) => {
      drawPixelText(ctx, `${n}  -  ${car}`, CANVAS_W / 2, 360 + i * 28, 2, col, 'center');
    });
    drawPixelText(ctx, 'P1 YOKO  WASD    P2 MORLAN  ARROWS', CANVAS_W / 2, 640, 2, '#fff4c2', 'center');
  }

  _drawCharSelect(ctx) {
    drawStage(ctx, this.assets, 1, this.time, 0);
    ctx.fillStyle = 'rgba(8,6,20,0.78)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, 'SELECT YOUR FIGHTER', CANVAS_W / 2, 28, 3, '#ffe566', 'center');
    const slot = this.charSelectSlot === 'p1' ? 'P1' : (this.vsCpu ? 'CPU' : 'P2');
    drawPixelText(ctx, `${slot}  CHOOSE`, CANVAS_W / 2, 68, 2, '#ffffff', 'center');

    SELECTABLE_FIGHTERS.forEach((id, i) => {
      const ch = CHARACTERS[id];
      const x = 80 + i * 300;
      const y = 120;
      const chosen = (this.charSelectSlot === 'p1' ? this.p1Select : this.p2Select) === i;
      const locked = (this.charSelectSlot === 'p2' && this.p1Select === i);
      ctx.fillStyle = '#000';
      ctx.fillRect(x - 8, y - 8, 248, 360);
      ctx.fillStyle = chosen ? ch.color : '#444';
      ctx.fillRect(x - 6, y - 6, 244, 356);
      ctx.fillStyle = '#111';
      ctx.fillRect(x, y, 232, 232);
      const img = this.assets.images[`${id}Hud`] || this.assets.images[id];
      if (img) {
        ctx.imageSmoothingEnabled = false;
        ctx.drawImage(img, x, y, 232, 232);
      }
      drawPixelText(ctx, ch.short, x + 116, y + 248, 2, chosen ? '#fff4c2' : '#bbbbbb', 'center');
      drawPixelText(ctx, ch.title, x + 116, y + 278, 1, ch.color, 'center');
      if (locked) drawPixelText(ctx, 'P1', x + 116, y + 304, 1, '#ffe566', 'center');
      if (chosen) drawPixelText(ctx, '>', x - 28, y + 100, 4, '#fff4c2');
    });

    const p1 = CHARACTERS[SELECTABLE_FIGHTERS[this.p1Select]];
    const p2 = CHARACTERS[SELECTABLE_FIGHTERS[this.p2Select]];
    drawPixelText(ctx, `P1  ${p1.short}`, 80, 520, 2, p1.color);
    drawPixelText(ctx, `${this.vsCpu ? 'CPU' : 'P2'}  ${p2.short}`, 700, 520, 2, p2.color);
    drawPixelText(ctx, 'A D OR ARROWS   ENTER TO LOCK', CANVAS_W / 2, 640, 2, '#fff4c2', 'center');
    drawPixelText(ctx, 'KITTENS  SOCIALIST CHINA    BABY  AUSTRALIA', CANVAS_W / 2, 672, 1, '#aaaaaa', 'center');
  }

  _drawMenu(ctx) {
    drawStage(ctx, this.assets, 1, this.time, 0);
    ctx.fillStyle = 'rgba(8,6,20,0.72)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, 'CHOOSE YOUR IDEOLOGY', CANVAS_W / 2, 36, 3, '#ffe566', 'center');
    drawPixelText(ctx, 'CAT BATTLE  -  ANDROID PAD', CANVAS_W / 2, 68, 1, '#aaaaaa', 'center');

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

    drawPixelText(ctx, 'THEN SELECT  YOKO  MORLAN  KITTENS  BABY', CANVAS_W / 2, 250, 2, '#ffe566', 'center');
    drawPixelText(ctx, 'P1  ON-SCREEN PAD', 80, 280, 2, '#ffe566');
    const p1 = [
      'DPAD  UP DOWN LEFT RIGHT',
      'JUMP   PUNCH   KICK   LASER',
      'HOLD BACK TO BLOCK',
      'LASER WEARS OFF  THEN REFILLS',
      'JOYE THROWS CAPITALIST CHICKEN',
      'CHICKEN = STR SPEED INVULN',
    ];
    p1.forEach((l, i) => drawPixelText(ctx, l, 80, 310 + i * 18, 1, '#dddddd'));

    drawPixelText(ctx, 'P2  ARROWS', 700, 280, 2, '#ff8a80');
    const p2 = [
      'ARROWS MOVE  P JUMP',
      'N PUNCH   M KICK   , LASER',
      'HOLD BACK TO BLOCK',
      'LASER WEARS OFF  THEN REFILLS',
      'STELLA THROWS SOVIET SALMON',
      'SALMON = STR SPEED INVULN',
    ];
    p2.forEach((l, i) => drawPixelText(ctx, l, 700, 310 + i * 18, 1, '#dddddd'));

    drawPixelText(ctx, 'JOYE CHICKEN FOR YOKO   STELLA SALMON FOR MORLAN   BEST OF 3', CANVAS_W / 2, 500, 1, '#aaaaaa', 'center');
    drawPixelText(ctx, 'ENTER / Z TO CONFIRM', CANVAS_W / 2, 640, 2, '#fff4c2', 'center');
  }

  _drawMatchEnd(ctx) {
    drawStage(ctx, this.assets, this.round, this.time, 0);
    ctx.fillStyle = 'rgba(0,0,0,0.62)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    const w = this.winner;
    const img = this.assets.images[`${w}Hud`] || this.assets.images[w];
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

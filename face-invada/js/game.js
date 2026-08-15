/**
 * FACE INVADA — 5 DAYS A STRANGER then BEAT BOXING.
 * Android-first: tap hotspots, LOOK/TALK/TAKE/USE, then fight that day's enemy.
 */
import {
  CANVAS_W, CANVAS_H, GAME_TITLE, GAME_SUBTITLE,
  LANES, CONTROL_MAP, MAX_HP, SUPER_COST, CHART_BEATS,
  beatAtFrame, makeChart, findHittable, expireNotes, gradeDelta,
  applyPlayerHit, applyMiss, applySuper, winnerOf, emptyFightState, canSuper,
} from './logic.js';
import { Input } from './input.js';
import { AudioBus } from './audio.js';
import {
  drawPixelText, drawNeonCity, drawFighter, drawHighway, lifeBarWidth,
  drawMysteryRoom, drawClueBanner, drawFaceHead, drawRaveVampire,
  paintNightStreet, paintPickup, paintRaveBat, drawNightNpc,
  paintBeat, paintGrass, paintSpring, paintWarpPipe, paintPartyBalls,
} from './pixel.js';
import {
  emptyMysteryState, setVerb, tapAt, canFight,
  markBeaten, dayMeta, enemyOf, currentRoom, DAYS, ENEMIES,
  ITEM_NAMES, INV_X, INV_Y, INV_SLOT_W, INV_SLOT_H, INV_GAP,
  stepWalk, interactNearest, stepPhysics, seekDay,
} from './mystery.js';
import {
  CAMPAIGN, campaignStep, CUTS, CREDITS_BY, PONG_DISCLAIMER,
  LANA_LINE, KIM_LINE, DJ_TRICKS,
  emptyPacState, stepPac, emptyPongState, stepPong,
  emptyClubState, clubPress, emptySentinelState, stepSentinel,
  emptyGrammyState, stepGrammy, emptyBribeState, stepBribe,
} from './arcade.js';
import {
  emptyNightState, stepNight, tapNight, selectNightItem, nightCam,
  hitNightInv, ITEM_LABEL, PLATFORMS, NPCS, NIGHT_W, FLOOR_Y,
  BAG_X, BAG_Y, BAG_SLOT_W, BAG_SLOT_H, BAG_GAP, BAG_SLOTS,
  GRASS, SPRINGS, PIPES, platY,
} from './nightout.js';
import { beatName } from './catch.js';

const VERB_KEYS = { KeyZ: 'look', KeyX: 'talk', KeyC: 'take', KeyV: 'use' };

export class Game {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.input = new Input();
    this.audio = new AudioBus();
    this.mode = 'title';
    this.time = 0;
    this.mystery = emptyMysteryState();
    this.fight = null;
    this.enemy = ENEMIES.vinyl;
    this.announce = { text: '', sub: '', t: 0 };
    this.flash = 0;
    this._last = 0;
    this._bound = (t) => this.loop(t);
    this._beatInt = -1;
    this.facePose = { t: 0 };
    this.rivetPose = { t: 0 };
    this.onModeChange = null;
    this.winner = null;
    this.camp = 0;
    this.cut = null;
    this.cutLine = 0;
    this.arcade = null;
    this.night = emptyNightState();
  }

  setMode(mode) {
    this.mode = mode;
    if (typeof this.onModeChange === 'function') this.onModeChange(mode);
  }

  start() {
    requestAnimationFrame(this._bound);
  }

  say(text, frames = 70, sub = '') {
    this.announce = { text, sub, t: frames };
  }

  loop(ts) {
    const dt = Math.min(32, ts - (this._last || ts));
    this._last = ts;
    let acc = dt / (1000 / 60);
    while (acc > 0.5) {
      this.update();
      acc -= 1;
    }
    this.draw();
    this.input.endFrame();
    requestAnimationFrame(this._bound);
  }

  tapCanvas(x, y) {
    if (this.mode === 'mystery') {
      this.mystery = tapAt(this.mystery, x, y);
      this.audio.ensure();
      this.audio.ui();
      return;
    }
    if (this.mode === 'nightout') {
      const bag = hitNightInv(x, y);
      if (bag >= 0) {
        this.night = selectNightItem(this.night, bag);
        this.audio.ensure();
        this.audio.ui();
        return;
      }
      const cam = nightCam(this.night, CANVAS_W);
      this.night = tapNight(this.night, x + cam, y);
      this.audio.ensure();
      this.audio.ui();
      return;
    }
    if (this.mode === 'cut' || this.mode === 'title' || this.mode === 'briefing'
        || this.mode === 'result' || this.mode === 'credits' || this.mode === 'journal') {
      this.input.setVirtual('Enter', true);
      setTimeout(() => this.input.setVirtual('Enter', false), 80);
    }
  }

  beginCampaign() {
    this.camp = 0;
    this.mystery = emptyMysteryState();
    this.night = emptyNightState();
    this.audio.ensure();
    this.beginStep();
  }

  beginStep() {
    const step = campaignStep(this.camp);
    if (!step || step.kind === 'credits') {
      this.setMode('credits');
      return;
    }
    if (step.kind === 'cut') {
      this.cut = CUTS[step.cut];
      this.cutLine = 0;
      this.setMode('cut');
      this.audio.vocal();
      return;
    }
    if (step.kind === 'nightout') {
      this.night = emptyNightState();
      this.setMode('nightout');
      this.say('CURIOUSLY STRONG', 70, 'ALL NIGHT LONG');
      return;
    }
    if (step.kind === 'mystery') {
      this.mystery = seekDay(this.mystery, step.day);
      this.beginMystery();
      return;
    }
    if (step.kind === 'fight') {
      this.beginFight();
      return;
    }
    if (step.kind === 'pac') {
      this.arcade = emptyPacState();
      this.setMode('pac');
      this.say('LEVEL 2', 50, 'RAVE VAMPIRES');
      return;
    }
    if (step.kind === 'pong') {
      this.arcade = emptyPongState();
      this.setMode('pong');
      return;
    }
    if (step.kind === 'club') {
      this.arcade = emptyClubState();
      this.setMode('club');
      return;
    }
    if (step.kind === 'sentinel') {
      this.arcade = emptySentinelState();
      this.setMode('sentinel');
      return;
    }
    if (step.kind === 'grammy') {
      this.arcade = emptyGrammyState();
      this.setMode('grammy');
      return;
    }
    if (step.kind === 'bribe') {
      this.arcade = emptyBribeState();
      this.setMode('bribe');
      return;
    }
    this.setMode('credits');
  }

  advanceCampaign() {
    this.camp += 1;
    if (this.camp >= CAMPAIGN.length) this.camp = CAMPAIGN.length - 1;
    this.beginStep();
  }

  beginBriefing() {
    this.setMode('briefing');
    this.audio.ensure();
    this.audio.ui();
  }

  beginMystery() {
    this.setMode('mystery');
    this.say(`NIGHT ${this.mystery.day}`, 50, dayMeta(this.mystery).title);
  }

  beginFight() {
    const enemy = enemyOf(this.mystery);
    this.enemy = enemy;
    this.fight = {
      frame: 0,
      beat: 0,
      loop: 0,
      gradeT: 0,
      notes: makeChart(enemy.seed),
      state: emptyFightState(enemy.hp),
      enemyId: enemy.id,
    };
    this._beatInt = -1;
    this.setMode('fight');
    this.say('FIGHT!', 50, enemy.name);
    this.audio.ensure();
    this.audio.kick();
  }

  update() {
    this.time += 1;
    if (this.announce.t > 0) this.announce.t -= 1;
    else this.announce.text = '';
    if (this.flash > 0) this.flash -= 1;
    this.facePose.t = this.time;
    this.rivetPose.t = this.time;
    if (this.facePose.punch > 0) this.facePose.punch -= 0.08;
    if (this.facePose.kick > 0) this.facePose.kick -= 0.08;
    if (this.facePose.blade > 0) this.facePose.blade -= 0.08;
    if (this.facePose.hit > 0) this.facePose.hit -= 0.08;
    if (this.rivetPose.hit > 0) this.rivetPose.hit -= 0.08;
    if (this.rivetPose.punch > 0) this.rivetPose.punch -= 0.08;

    this.audio.dnbTick(this.time);

    if (this.mode === 'title') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        this.beginCampaign();
      }
      return;
    }

    if (this.mode === 'cut') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        this.cutLine += 1;
        this.audio.ui();
        if (!this.cut || this.cutLine >= this.cut.lines.length) this.advanceCampaign();
      }
      return;
    }

    if (this.mode === 'briefing') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        this.audio.vocal();
        this.beginMystery();
      }
      return;
    }

    if (this.mode === 'journal') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ') || this.input.just('KeyW')) {
        this.setMode('mystery');
        this.audio.ui();
      }
      return;
    }

    if (this.mode === 'credits') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        this.mystery = emptyMysteryState();
        this.camp = 0;
        this.setMode('title');
      }
      return;
    }

    if (this.mode === 'result') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        if (this.winner === 'face') {
          this.mystery = markBeaten(this.mystery);
          this.advanceCampaign();
        } else {
          this.beginFight();
        }
      }
      return;
    }

    if (this.mode === 'nightout') {
      const left = this.input.held('KeyA') || this.input.held('ArrowLeft');
      const right = this.input.held('KeyD') || this.input.held('ArrowRight');
      const dir = (right ? 1 : 0) - (left ? 1 : 0);
      const jump = this.input.just('KeyW') || this.input.just('ArrowUp');
      const take = this.input.just('KeyC') || this.input.just('KeyS');
      const talk = this.input.just('KeyX');
      const use = this.input.just('KeyV');
      const look = this.input.just('KeyZ');
      this.night = stepNight(this.night, { dir, jump, take, talk, use, look });
      if (dir) this.facePose.walk = this.time * 0.4;
      else this.facePose.walk = 0;
      if (jump) this.audio.ui();
      if (this.night.won) this.advanceCampaign();
      return;
    }

    if (this.mode === 'mystery') {
      for (const [code, verb] of Object.entries(VERB_KEYS)) {
        if (this.input.just(code)) {
          this.mystery = setVerb(this.mystery, verb);
          this.audio.ui();
        }
      }
      const left = this.input.held('KeyA') || this.input.held('ArrowLeft');
      const right = this.input.held('KeyD') || this.input.held('ArrowRight');
      const dir = (right ? 1 : 0) - (left ? 1 : 0);
      const before = this.mystery;
      this.mystery = stepWalk(this.mystery, dir);
      const jump = this.input.just('KeyW') || this.input.just('ArrowUp');
      this.mystery = stepPhysics(this.mystery, jump);
      if (jump) this.audio.ui();
      if (dir) this.facePose.walk = this.time * 0.4;
      else if (this.mystery.walkTarget != null) this.facePose.walk = this.time * 0.4;
      else this.facePose.walk = 0;
      if (this.mystery.room !== before.room) this.audio.ui();
      if (this.input.just('KeyS') || this.input.just('ArrowDown')) {
        this.mystery = interactNearest(this.mystery);
        this.audio.ui();
      }
      if (this.input.just('Enter') || this.input.just('Space')) {
        if (canFight(this.mystery)) this.beginFight();
        else {
          this.setMode('journal');
          this.audio.ui();
        }
      }
      return;
    }

    if (this.mode === 'pac' && this.arcade) {
      if (this.time % 8 === 0) {
        let dc = 0;
        let dr = 0;
        if (this.input.held('KeyA') || this.input.held('ArrowLeft')) dc = -1;
        if (this.input.held('KeyD') || this.input.held('ArrowRight')) dc = 1;
        if (this.input.held('KeyW') || this.input.held('ArrowUp')) dr = -1;
        if (this.input.held('KeyS') || this.input.held('ArrowDown')) dr = 1;
        this.arcade = stepPac(this.arcade, dc, dr);
        if (dc || dr) this.audio.hat();
      }
      if (this.arcade.won) this.advanceCampaign();
      if (this.arcade.dead && (this.input.just('Enter') || this.input.just('KeyZ'))) {
        this.arcade = emptyPacState();
      }
      return;
    }

    if (this.mode === 'pong' && this.arcade) {
      let dir = 0;
      if (this.input.held('KeyW') || this.input.held('ArrowUp')) dir = -1;
      if (this.input.held('KeyS') || this.input.held('ArrowDown')) dir = 1;
      this.arcade = stepPong(this.arcade, dir);
      if (this.arcade.won) this.advanceCampaign();
      if (this.arcade.lost && (this.input.just('Enter') || this.input.just('KeyZ'))) {
        this.arcade = emptyPongState();
      }
      return;
    }

    if (this.mode === 'club' && this.arcade) {
      for (const code of ['KeyZ', 'KeyX', 'KeyC', 'KeyV']) {
        if (this.input.just(code)) {
          this.arcade = clubPress(this.arcade, code);
          this.audio.sample(this.arcade.last || '');
        }
      }
      if (this.arcade.won) this.advanceCampaign();
      return;
    }

    if (this.mode === 'sentinel' && this.arcade) {
      const dir = (this.input.held('KeyD') || this.input.held('ArrowRight') ? 1 : 0)
        - (this.input.held('KeyA') || this.input.held('ArrowLeft') ? 1 : 0);
      const jump = this.input.just('KeyW') || this.input.just('ArrowUp');
      const take = this.input.just('KeyC') || this.input.just('KeyZ') || this.input.just('KeyS');
      this.arcade = stepSentinel(this.arcade, dir, jump, take);
      if (this.arcade.won) this.advanceCampaign();
      return;
    }

    if (this.mode === 'grammy' && this.arcade) {
      const dir = (this.input.held('KeyD') || this.input.held('ArrowRight') ? 1 : 0)
        - (this.input.held('KeyA') || this.input.held('ArrowLeft') ? 1 : 0);
      const jump = this.input.just('KeyW') || this.input.just('ArrowUp');
      const take = this.input.just('KeyC') || this.input.just('KeyS') || this.input.just('KeyZ');
      this.arcade = stepGrammy(this.arcade, dir, jump, take);
      if (this.arcade.won) this.advanceCampaign();
      return;
    }

    if (this.mode === 'bribe' && this.arcade) {
      const dir = (this.input.held('KeyD') || this.input.held('ArrowRight') ? 1 : 0)
        - (this.input.held('KeyA') || this.input.held('ArrowLeft') ? 1 : 0);
      const jump = this.input.just('KeyW') || this.input.just('ArrowUp');
      const punch = this.input.just('KeyZ') || this.input.just('KeyC');
      this.arcade = stepBribe(this.arcade, dir, jump, punch);
      if (punch) this.audio.punch();
      if (this.arcade.won) this.advanceCampaign();
      if (this.arcade.lost && (this.input.just('Enter') || this.input.just('KeyV'))) {
        this.arcade = emptyBribeState();
      }
      return;
    }

    if (this.mode !== 'fight' || !this.fight) return;

    this.fight.frame += 1;
    const beat = beatAtFrame(this.fight.frame);
    const loop = Math.floor(beat / CHART_BEATS);
    if (loop !== this.fight.loop) {
      this.fight.loop = loop;
      for (const n of this.fight.notes) {
        n.hit = false;
        n.grade = null;
      }
    }
    const localBeat = beat - loop * CHART_BEATS;
    this.fight.beat = localBeat;
    const bi = Math.floor(beat);
    if (bi !== this._beatInt && bi >= 0) {
      this._beatInt = bi;
      this.audio.tickBeat(bi);
    }
    if (this.fight.gradeT > 0) this.fight.gradeT -= 1;

    const missed = expireNotes(this.fight.notes, localBeat);
    for (const _m of missed) {
      this.fight.state = applyMiss(this.fight.state);
      this.fight.gradeT = 24;
      this.facePose.hit = 1;
      this.rivetPose.punch = 1;
      this.audio.miss();
    }

    for (const lane of LANES) {
      if (this.input.just(CONTROL_MAP[lane])) this._tryLane(lane);
    }

    const enemyId = this.fight.enemyId || 'rivet';
    const win = winnerOf(this.fight.state.playerHp, this.fight.state.cpuHp, enemyId);
    if (win) {
      this.winner = win;
      const name = this.enemy?.name || 'RIVAL';
      this.say(win === 'face' ? 'FACE INVADA WINS' : win === 'draw' ? 'DRAW' : `${name} WINS`, 180,
        win === 'face' ? 'CASE ADVANCES' : 'KEEP THE BEAT');
      this.setMode('result');
      this.audio.bassDrop();
    }
  }

  _tryLane(lane) {
    const f = this.fight;
    const note = findHittable(f.notes, lane, f.beat);
    if (note) {
      const grade = gradeDelta(note.beat - f.beat) || 'good';
      note.hit = true;
      note.grade = grade;
      f.state = applyPlayerHit(f.state, grade);
      f.gradeT = 50;
      this.facePose[lane === 'bass' ? 'punch' : lane] = 1;
      this.rivetPose.hit = 1;
      if (grade === 'perfect') this.audio.perfect();
      if (lane === 'punch') this.audio.punch();
      else if (lane === 'kick') this.audio.kickHit();
      else if (lane === 'blade') this.audio.blade();
      else this.audio.bassDrop();
      this.flash = grade === 'perfect' ? 4 : 2;
      return;
    }
    if (lane === 'bass' && canSuper(f.state.bass)) {
      const r = applySuper(f.state);
      f.state = r.state;
      this.facePose.punch = 1;
      this.facePose.blade = 1;
      this.rivetPose.hit = 1;
      this.audio.bassDrop();
      this.audio.vocal();
      this.say('BEAT BOX DROP', 50, 'SUPER POWER DJ BRAH');
      this.flash = 8;
      return;
    }
    this.audio.ui();
  }

  draw() {
    const ctx = this.ctx;
    ctx.imageSmoothingEnabled = false;
    if (this.mode === 'title') this._drawTitle(ctx);
    else if (this.mode === 'nightout') this._drawNightout(ctx);
    else if (this.mode === 'briefing') this._drawBriefing(ctx);
    else if (this.mode === 'cut') this._drawCut(ctx);
    else if (this.mode === 'mystery') this._drawMystery(ctx);
    else if (this.mode === 'journal') this._drawJournal(ctx);
    else if (this.mode === 'result') this._drawResult(ctx);
    else if (this.mode === 'credits') this._drawCredits(ctx);
    else if (this.mode === 'pac') this._drawPac(ctx);
    else if (this.mode === 'pong') this._drawPong(ctx);
    else if (this.mode === 'club') this._drawClub(ctx);
    else if (this.mode === 'sentinel') this._drawSentinel(ctx);
    else if (this.mode === 'grammy') this._drawGrammy(ctx);
    else if (this.mode === 'bribe') this._drawBribe(ctx);
    else this._drawFight(ctx);
  }

  _drawTitle(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.45)';
    ctx.fillRect(0, 80, CANVAS_W, 240);
    drawPixelText(ctx, "FACE INVADA'S", CANVAS_W / 2, 100, 4, '#ff4ad2', 'center');
    drawPixelText(ctx, 'CURIOUSLY STRONG', CANVAS_W / 2, 150, 4, '#ffe566', 'center');
    drawPixelText(ctx, 'ALL NIGHT LONG', CANVAS_W / 2, 196, 4, '#3df0ff', 'center');
    drawPixelText(ctx, GAME_TITLE, CANVAS_W / 2, 250, 2, '#e878ff', 'center');
    drawPixelText(ctx, 'JUMP. GRAB. COMBINE. GET IN THE CLUB.', CANVAS_W / 2, 284, 2, '#fff4c2', 'center');
    drawFighter(ctx, 'face', 640, 540, 1, { t: this.time, punch: Math.max(0, Math.sin(this.time * 0.08)), blade: 0.35 }, 4.8);
    if (Math.sin(this.time * 0.12) > -0.2) {
      drawPixelText(ctx, 'PRESS START', CANVAS_W / 2, 580, 3, '#ffffff', 'center');
    }
    drawPixelText(ctx, 'ITALY  37  SILAT + BLADE', CANVAS_W / 2, 620, 2, '#bbbbbb', 'center');
  }

  _drawNightout(ctx) {
    const n = this.night;
    const cam = nightCam(n, CANVAS_W);
    paintNightStreet(ctx, this.time, cam, NIGHT_W, n.alleyLit);

    for (const g of GRASS) {
      paintGrass(ctx, g.x - cam, FLOOR_Y, g.w, this.time);
    }
    for (const sp of SPRINGS) {
      paintSpring(ctx, sp.x - cam, sp.y, this.time);
    }
    for (const pipe of PIPES) {
      paintWarpPipe(ctx, pipe.x - cam, FLOOR_Y);
    }

    for (const p of PLATFORMS) {
      const py = platY(p, n.frame || 0);
      const x = p.x - cam;
      if (x < -200 || x > CANVAS_W + 40) continue;
      ctx.fillStyle = '#0a0808';
      ctx.fillRect(x - 2, py - 2, p.w + 4, 18);
      ctx.fillStyle = p.amp ? '#3df0ff' : '#8a5020';
      ctx.fillRect(x, py, p.w, 14);
      ctx.fillStyle = p.amp ? '#ffe566' : '#c87838';
      ctx.fillRect(x, py, p.w, 4);
    }

    for (const p of n.pickups) {
      if (p.got) continue;
      if (p.dark && !n.alleyLit) continue;
      const x = p.x - cam;
      if (x < -40 || x > CANVAS_W + 40) continue;
      paintPickup(ctx, x, p.y, p.id, this.time);
      drawPixelText(ctx, ITEM_LABEL[p.id] || p.id, x, p.y - 28, 1, '#fff4c2', 'center');
    }

    for (const npc of NPCS) {
      const x = npc.x - cam;
      if (x < -80 || x > CANVAS_W + 80) continue;
      const face = n.px < npc.x ? -1 : 1;
      drawNightNpc(ctx, npc.paint, x, FLOOR_Y, face, { t: this.time }, 2.7);
      drawPixelText(ctx, npc.name, x, FLOOR_Y - 240, 2, '#ffe566', 'center');
    }

    for (const w of n.wilds || []) {
      if (w.caught) continue;
      const x = w.x - cam;
      if (x < -40 || x > CANVAS_W + 40) continue;
      paintBeat(ctx, w.id, x, w.y, this.time, (w.vx || 1) >= 0 ? 1 : -1);
      drawPixelText(ctx, beatName(w.id), x, w.y - 36, 1, w.dazed ? '#ffe566' : '#7cff6b', 'center');
    }

    for (const b of n.bats) {
      const x = b.x - cam;
      if (x < -40 || x > CANVAS_W + 40) continue;
      paintRaveBat(ctx, x, b.y, this.time, b.vx >= 0 ? 1 : -1);
    }

    const grow = n.grown ? 1.5 : 1;
    drawFighter(ctx, 'face', n.px - cam, FLOOR_Y + n.py, n.facing || 1, {
      t: this.time,
      walk: this.facePose.walk || 0,
      blade: 0.25,
    }, 2.6 * grow);

    drawClueBanner(ctx, n.banner || n.log, this.time);
    ctx.fillStyle = 'rgba(6,4,14,0.88)';
    ctx.fillRect(0, 84, CANVAS_W, 36);
    drawPixelText(ctx, 'STOMP + TAKE TO CATCH    GRASS STARTS BATTLES    DO ON PIPES', 16, 92, 2, '#3df0ff');
    drawPixelText(ctx, 'PARTY', 16, 128, 1, '#888');
    paintPartyBalls(ctx, n.party || [], 80, 134);

    if (n.encounter) {
      ctx.fillStyle = 'rgba(0,0,20,0.72)';
      ctx.fillRect(200, 180, 880, 280);
      drawPixelText(ctx, `WILD ${beatName(n.encounter.id)}`, CANVAS_W / 2, 210, 3, '#ffe566', 'center');
      paintBeat(ctx, n.encounter.id, CANVAS_W / 2, 340, this.time, 1);
      drawPixelText(ctx, n.encounter.hp <= 1 ? 'WOBBLING  TAKE TO CATCH' : 'JUMP TO WEAKEN   TAKE TO THROW TIN', CANVAS_W / 2, 400, 2, '#fff', 'center');
      drawPixelText(ctx, 'WALK TO FLEE', CANVAS_W / 2, 430, 1, '#bbb', 'center');
    }

    drawPixelText(ctx, 'BAG', BAG_X, BAG_Y - 16, 1, '#888888');
    for (let i = 0; i < BAG_SLOTS; i++) {
      const x = BAG_X + i * (BAG_SLOT_W + BAG_GAP);
      const id = n.inv[i];
      const on = id && n.selected === id;
      ctx.fillStyle = on ? '#ff4ad2' : '#2a2438';
      ctx.fillRect(x - 2, BAG_Y - 2, BAG_SLOT_W + 4, BAG_SLOT_H + 4);
      ctx.fillStyle = '#100c18';
      ctx.fillRect(x, BAG_Y, BAG_SLOT_W, BAG_SLOT_H);
      drawPixelText(ctx, id ? ITEM_LABEL[id] || id : '--', x + 6, BAG_Y + 12, 1, id ? '#fff4c2' : '#444');
    }

    if (this.announce.text) {
      ctx.fillStyle = 'rgba(0,0,0,0.45)';
      ctx.fillRect(0, 200, CANVAS_W, 48);
      drawPixelText(ctx, this.announce.text, CANVAS_W / 2, 210, 3, '#ffffff', 'center');
    }
  }

  _drawBriefing(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(80, 60, 1120, 600);
    const day = dayMeta(this.mystery);
    const enemy = enemyOf(this.mystery);
    drawPixelText(ctx, `NIGHT ${day.day}`, CANVAS_W / 2, 90, 3, '#3df0ff', 'center');
    drawPixelText(ctx, day.title, CANVAS_W / 2, 140, 4, '#ffe566', 'center');
    this._wrap(ctx, day.casefile, 140, 230, 1000, 2, '#eeeeee');
    drawPixelText(ctx, 'THEN FIGHT', CANVAS_W / 2, 380, 2, '#ff4ad2', 'center');
    drawPixelText(ctx, enemy.name, CANVAS_W / 2, 420, 3, '#ffffff', 'center');
    drawPixelText(ctx, enemy.blurb.toUpperCase(), CANVAS_W / 2, 470, 1, '#bbbbbb', 'center');
    drawFighter(ctx, enemy.id, 640, 580, -1, { t: this.time }, 2.4);
    drawPixelText(ctx, 'START TO INVESTIGATE', CANVAS_W / 2, 610, 2, '#fff4c2', 'center');
  }

  _drawMystery(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    const m = this.mystery;
    const day = dayMeta(m);
    const room = currentRoom(m);
    drawMysteryRoom(ctx, room, this.time);

    const npc = room.hotspots.find((h) => ['bellhop', 'kara', 'widow', 'rivet', 'stranger'].includes(h.id));
    if (npc) {
      const who = npc.id === 'bellhop' ? 'vinyl' : npc.id;
      drawFighter(ctx, who, npc.x + npc.w / 2, npc.y + npc.h - 4, 1, { t: this.time }, 2.1);
    }
    const px = m.px ?? 260;
    const py = m.py || 0;
    const grow = m.grown ? 1.55 : 1;
    drawFighter(ctx, 'face', px, 518 + py, m.facing || 1, {
      t: this.time,
      walk: this.facePose.walk || 0,
      blade: 0.25,
    }, 2.6 * grow);

    drawClueBanner(ctx, m.banner || m.log, this.time);
    ctx.fillStyle = 'rgba(6,4,14,0.88)';
    ctx.fillRect(0, 84, CANVAS_W, 36);
    drawPixelText(ctx, `NIGHT ${day.day}  ${day.title}  ${room.name}  ${m.verb.toUpperCase()}`, 16, 92, 2, '#3df0ff');
    if (canFight(m)) drawPixelText(ctx, 'START FIGHT', 980, 92, 2, '#ff4ad2');

    drawPixelText(ctx, 'BAG', INV_X - 50, INV_Y + 8, 1, '#888888');
    for (let i = 0; i < 5; i++) {
      const x = INV_X + i * (INV_SLOT_W + INV_GAP);
      const id = m.inv[i];
      const on = id && m.selected === id;
      ctx.fillStyle = on ? '#ff4ad2' : '#2a2438';
      ctx.fillRect(x - 2, INV_Y - 2, INV_SLOT_W + 4, INV_SLOT_H + 4);
      ctx.fillStyle = '#100c18';
      ctx.fillRect(x, INV_Y, INV_SLOT_W, INV_SLOT_H);
      drawPixelText(ctx, id ? ITEM_NAMES[id] || id : '--', x + 8, INV_Y + 10, 1, id ? '#fff4c2' : '#444');
    }

    if (this.announce.text) {
      ctx.fillStyle = 'rgba(0,0,0,0.45)';
      ctx.fillRect(0, 200, CANVAS_W, 48);
      drawPixelText(ctx, this.announce.text, CANVAS_W / 2, 210, 3, '#ffffff', 'center');
    }
  }

  _drawJournal(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.75)';
    ctx.fillRect(80, 40, 1120, 640);
    drawPixelText(ctx, 'CASE JOURNAL', CANVAS_W / 2, 70, 4, '#e878ff', 'center');
    DAYS.forEach((d, i) => {
      const y = 130 + i * 48;
      let status = 'LOCKED';
      let col = '#666';
      if (this.mystery.beaten[i]) {
        status = 'BEATEN';
        col = '#3dcc5a';
      } else if (this.mystery.solved[i]) {
        status = 'FIGHT READY';
        col = '#ff4ad2';
      } else if (this.mystery.day === d.day) {
        status = 'INVESTIGATING';
        col = '#ffe566';
      } else if (this.mystery.day > d.day) {
        status = 'OPEN';
        col = '#3df0ff';
      }
      drawPixelText(ctx, `NIGHT ${d.day}  ${d.title}`, 120, y, 2, '#ffffff');
      drawPixelText(ctx, status, 860, y, 2, col);
    });
    drawPixelText(ctx, 'CLUES', 120, 390, 2, '#3df0ff');
    const clues = this.mystery.clues || [];
    if (!clues.length) drawPixelText(ctx, 'WALK. LOOK. TALK. TAKE. USE.', 120, 430, 1, '#888');
    clues.slice(-4).forEach((c, i) => {
      drawPixelText(ctx, c.toUpperCase(), 120, 430 + i * 22, 1, '#fff4c2');
    });
    drawPixelText(ctx, 'START TO CLOSE JOURNAL', CANVAS_W / 2, 600, 2, '#fff4c2', 'center');
  }

  _drawFight(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    const st = this.fight.state;
    const beat = this.fight.beat;
    const enemy = this.enemy;
    const cpuMax = enemy.hp;

    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(0, 0, CANVAS_W, 92);
    this._bar(ctx, 20, 18, 480, st.playerHp, MAX_HP, '#3dcc5a', false);
    this._bar(ctx, CANVAS_W - 500, 18, 480, st.cpuHp, cpuMax, '#ff4d6a', true);
    drawPixelText(ctx, 'FACE INVADA', 24, 48, 2, '#e878ff');
    drawPixelText(ctx, enemy.name, CANVAS_W - 24, 48, 2, '#ff8a80', 'right');
    ctx.fillStyle = '#111';
    ctx.fillRect(20, 70, 220, 10);
    ctx.fillStyle = st.bass >= SUPER_COST ? '#e878ff' : '#b44cff';
    ctx.fillRect(20, 70, (st.bass / 100) * 220, 10);
    drawPixelText(ctx, st.bass >= SUPER_COST ? 'BASS READY' : 'BASS', 24, 84, 1, '#eee');

    const pulse = 1 + Math.sin(beat * Math.PI * 2) * 0.04;
    drawFighter(ctx, 'face', 300, 330, 1, this.facePose, 3.2 * pulse);
    drawFighter(ctx, enemy.id, 980, 330, -1, this.rivetPose, 3.2);
    drawPixelText(ctx, 'FACE INVADA', 300, 344, 1, '#fff', 'center');
    drawPixelText(ctx, enemy.handle, 980, 344, 1, '#fff', 'center');

    drawHighway(ctx, this.fight.notes, beat, 360, CANVAS_W);

    if (st.combo > 1) {
      drawPixelText(ctx, `${st.combo} HIT`, 640, 100, 3, '#fff', 'center');
    }
    if (st.lastGrade && this.fight.gradeT > 0) {
      const col = st.lastGrade === 'perfect' ? '#ffe566' : st.lastGrade === 'good' ? '#3df0ff' : st.lastGrade === 'super' ? '#ff4ad2' : '#ff6a3a';
      drawPixelText(ctx, st.lastGrade.toUpperCase(), 640, 140, 2, col, 'center');
    }
    if (this.announce.text) {
      ctx.fillStyle = 'rgba(0,0,0,0.45)';
      ctx.fillRect(0, 300, CANVAS_W, 64);
      drawPixelText(ctx, this.announce.text, CANVAS_W / 2, 312, 4, '#ffffff', 'center');
      if (this.announce.sub) drawPixelText(ctx, this.announce.sub, CANVAS_W / 2, 348, 1, '#ddd', 'center');
    }
    if (this.flash > 0) {
      ctx.fillStyle = `rgba(255,80,220,${this.flash / 16})`;
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    }
  }

  _bar(ctx, x, y, w, hp, max, color, flip) {
    ctx.fillStyle = '#1a1208';
    ctx.fillRect(x, y, w, 22);
    const bw = Math.round(lifeBarWidth(hp, max, w));
    ctx.fillStyle = hp < max * 0.22 ? '#e23b3b' : color;
    if (flip) ctx.fillRect(x + w - bw, y, bw, 22);
    else ctx.fillRect(x, y, bw, 22);
    drawPixelText(ctx, 'LIFE', flip ? x + w - 52 : x + 6, y + 5, 2, '#fff8c0');
  }

  _drawResult(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.62)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    const win = this.winner === 'face';
    drawFighter(ctx, win ? 'face' : (this.enemy?.id || 'rivet'), CANVAS_W / 2, 420, 1, { t: this.time }, 4.5);
    drawPixelText(ctx, this.announce.text || 'WINNER', CANVAS_W / 2, 80, 4, '#e878ff', 'center');
    drawPixelText(ctx, this.announce.sub || '', CANVAS_W / 2, 130, 2, '#ffe566', 'center');
    const st = this.fight?.state;
    if (st) {
      drawPixelText(ctx, `SCORE ${st.score}`, CANVAS_W / 2, 500, 2, '#fff', 'center');
      drawPixelText(ctx, `MAX COMBO ${st.maxCombo}   PERFECTS ${st.perfects}`, CANVAS_W / 2, 534, 1, '#ddd', 'center');
    }
    const hint = win ? 'START FOR THE NEXT BIT' : 'START TO RETRY FIGHT';
    drawPixelText(ctx, hint, CANVAS_W / 2, 620, 2, '#fff4c2', 'center');
  }

  _drawCredits(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, 'THE BASSLINE WAS YOU', CANVAS_W / 2, 100, 3, '#ffe566', 'center');
    drawPixelText(ctx, CREDITS_BY, CANVAS_W / 2, 180, 4, '#ff4ad2', 'center');
    drawPixelText(ctx, 'NO ATARI WAS SUED', CANVAS_W / 2, 250, 2, '#3df0ff', 'center');
    drawFighter(ctx, 'face', 640, 500, 1, { t: this.time, blade: 0.5 }, 4);
    drawPixelText(ctx, 'START TO RETURN', CANVAS_W / 2, 620, 2, '#fff4c2', 'center');
  }

  _drawCut(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    const cut = this.cut || { title: '', lines: [''] };
    ctx.fillStyle = 'rgba(0,0,20,0.72)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    if (cut.bike) {
      ctx.fillStyle = '#111';
      ctx.fillRect(0, 420, CANVAS_W, 80);
      drawFighter(ctx, 'face', 200 + (this.time * 8) % 900, 420, 1, { t: this.time, punch: 1 }, 3.2);
      drawPixelText(ctx, LANA_LINE, CANVAS_W / 2, 200, 6, '#ffe566', 'center');
    } else if (cut.phone) {
      drawFighter(ctx, 'face', 400, 520, 1, { t: this.time }, 3.6);
      ctx.fillStyle = '#fff4c2';
      ctx.fillRect(520, 140, 680, 160);
      ctx.fillStyle = '#120c00';
      ctx.fillRect(528, 148, 664, 144);
      this._wrap(ctx, KIM_LINE, 548, 168, 620, 2, '#ffe566');
    } else {
      drawPixelText(ctx, cut.title || 'CUT', CANVAS_W / 2, 80, 4, '#e878ff', 'center');
      const line = cut.lines[Math.min(this.cutLine, cut.lines.length - 1)] || '';
      this._wrap(ctx, line, 80, 220, 1120, 3, '#ffffff');
      drawFighter(ctx, 'face', 640, 560, 1, { t: this.time, blade: 0.3 }, 3);
    }
    drawPixelText(ctx, 'START', CANVAS_W / 2, 640, 2, '#fff4c2', 'center');
  }

  _drawPac(ctx) {
    ctx.fillStyle = '#050510';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, 'LEVEL 2  FACE HEAD PAC  SLAY RAVE VAMPIRES', 24, 16, 2, '#ffe566');
    const a = this.arcade;
    const ox = 80;
    const oy = 80;
    const tw = 72;
    const th = 58;
    ctx.fillStyle = '#0a1430';
    ctx.fillRect(ox, oy, 15 * tw, 9 * th);
    for (const p of a.pellets) {
      ctx.fillStyle = p.power ? '#3df0ff' : '#ffe566';
      ctx.fillRect(ox + p.c * tw + 30, oy + p.r * th + 24, p.power ? 12 : 6, p.power ? 12 : 6);
    }
    drawFaceHead(ctx, ox + a.c * tw + 36, oy + a.r * th + 30, 2.2, this.time);
    for (const v of a.vamps) {
      drawRaveVampire(ctx, ox + v.c * tw + 36, oy + v.r * th + 30, 2, a.power > 0);
    }
    if (a.dead) drawPixelText(ctx, 'RAVE VAMPIRE GOT YOU  START', CANVAS_W / 2, 640, 2, '#ff6a3a', 'center');
  }

  _drawPong(ctx) {
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, PONG_DISCLAIMER, CANVAS_W / 2, 24, 2, '#ffe566', 'center');
    const a = this.arcade;
    ctx.fillStyle = '#fff';
    ctx.fillRect(40, a.py, 18, 90);
    ctx.fillRect(1222, a.cy, 18, 90);
    ctx.fillRect(a.ball.x, a.ball.y, 14, 14);
    drawFaceHead(ctx, 49, a.py + 20, 1.4, this.time);
    drawPixelText(ctx, `${a.ps}  ${a.cs}`, CANVAS_W / 2, 70, 3, '#fff', 'center');
    if (a.lost) drawPixelText(ctx, 'ATARI WINS  START', CANVAS_W / 2, 640, 2, '#ff6a3a', 'center');
  }

  _drawClub(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(40,0,40,0.45)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    const a = this.arcade;
    const trick = DJ_TRICKS[Math.min(a.i, DJ_TRICKS.length - 1)];
    drawPixelText(ctx, 'CLUB SET', CANVAS_W / 2, 30, 3, '#ff4ad2', 'center');
    drawPixelText(ctx, trick ? trick.name : 'DONE', CANVAS_W / 2, 90, 3, '#ffe566', 'center');
    drawPixelText(ctx, a.last || 'HIT THE COMBO', CANVAS_W / 2, 150, 2, '#3df0ff', 'center');
    ctx.fillStyle = '#111';
    ctx.fillRect(200, 200, 880, 24);
    ctx.fillStyle = '#e878ff';
    ctx.fillRect(200, 200, Math.min(880, a.cheer * 8), 24);
    drawFighter(ctx, 'face', 640, 480, 1, { t: this.time, punch: a.last ? 0.6 : 0 }, 3.4);
    drawPixelText(ctx, 'Z X C V   CROWD WANTS TRICKS', CANVAS_W / 2, 620, 2, '#fff4c2', 'center');
  }

  _drawSentinel(ctx) {
    ctx.fillStyle = '#1a3040';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    ctx.fillStyle = '#c8b070';
    ctx.fillRect(0, 500, CANVAS_W, 220);
    paintGrass(ctx, 300, 500, 640, this.time);
    ctx.fillStyle = '#3a2010';
    ctx.fillRect(1000, 300, 180, 200);
    drawPixelText(ctx, 'GYM', 1050, 320, 2, '#ffe566');
    const a = this.arcade;
    drawPixelText(ctx, 'SENTINEL SAFARI  CATCH BREAKFAST', 24, 20, 2, '#ffe566');
    if (a.breakShown && !a.won) {
      drawPixelText(ctx, 'HUT: NICE CRAB. STILL WANT THE MOTH. NOT YOUR PLAYLIST.', 24, 56, 2, '#ff4ad2');
    }
    drawPixelText(ctx, a.banner || `HOLDING ${a.holding || 'NOTHING'}  HUT WANTS BOTH CATCHES`, 24, 88, 2, '#fff');
    paintPartyBalls(ctx, a.party || [], 80, 130);
    for (const w of a.wilds || []) {
      if (w.caught) continue;
      paintBeat(ctx, w.beat || w.id, w.x, 500 + w.y, this.time, (w.vx || 1) >= 0 ? 1 : -1);
      drawPixelText(ctx, (w.beat || w.id).toUpperCase(), w.x, 454 + w.y, 1, '#ffe566', 'center');
    }
    drawFighter(ctx, 'face', a.px, 500 + a.py, 1, { t: this.time }, 2.4);
    drawPixelText(ctx, 'CHASE  JUMP TO DAZE  TAKE TO CATCH  DELIVER AT THE HUT', 24, 620, 1, '#ddd');
  }

  _drawGrammy(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    const a = this.arcade;
    drawPixelText(ctx, 'GRAMMY NIGHT  CATCH THE FLEEING STATUETTES', 24, 20, 2, '#ffe566');
    drawPixelText(ctx, `CAUGHT ${a.got} / 4`, 24, 56, 2, '#3df0ff');
    for (const t of a.trophies) {
      if (t.got) continue;
      paintBeat(ctx, 'statuette', t.x, 500 + t.y, this.time, (t.vx || 1) >= 0 ? 1 : -1);
    }
    drawFighter(ctx, 'face', a.px, 500 + a.py, 1, { t: this.time, blade: 0.4 }, 2.6);
    drawPixelText(ctx, 'THEY RUN. JUMP ON THEM OR TAKE TO TIN THEM.', 24, 620, 1, '#ddd');
  }

  _drawBribe(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    const a = this.arcade;
    drawPixelText(ctx, 'DON TRUMPET  DO NOT TAKE THE CASH', 24, 16, 2, '#ffe566');
    this._bar(ctx, 20, 50, 400, a.hp, 100, '#3dcc5a', false);
    this._bar(ctx, 860, 50, 400, a.boss, 120, '#ff4d6a', true);
    drawFighter(ctx, 'face', a.px, 500 + a.py, 1, { t: this.time }, 2.8);
    ctx.fillStyle = '#e8a060';
    ctx.fillRect(a.bossX - 30, 360, 70, 140);
    ctx.fillStyle = '#f0d080';
    ctx.fillRect(a.bossX - 20, 330, 50, 40);
    drawPixelText(ctx, 'DON', a.bossX - 20, 300, 2, '#fff');
    for (const c of a.cash) {
      ctx.fillStyle = '#3dcc5a';
      ctx.fillRect(c.x, c.y, 28, 16);
      drawPixelText(ctx, 'S', c.x + 4, c.y + 2, 1, '#fff');
    }
    if (a.lost) drawPixelText(ctx, 'BRIBED  START TO RETRY', CANVAS_W / 2, 200, 3, '#ff6a3a', 'center');
    drawPixelText(ctx, 'WALK JUMP PUNCH   CASH HURTS', 24, 620, 2, '#fff4c2');
  }

  _wrap(ctx, text, x, y, maxW, scale, color) {
    const words = String(text).toUpperCase().split(' ');
    let line = '';
    let ly = y;
    for (const w of words) {
      const test = `${line}${w} `;
      if (test.length * 6 * scale > maxW) {
        drawPixelText(ctx, line, x, ly, scale, color);
        line = `${w} `;
        ly += 12 * scale + 8;
      } else line = test;
    }
    drawPixelText(ctx, line, x, ly, scale, color);
  }
}

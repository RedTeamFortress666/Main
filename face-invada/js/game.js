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
  drawMysteryRoom,
} from './pixel.js';
import {
  emptyMysteryState, setVerb, cycleRoom, tapAt, canFight, allBeaten,
  markBeaten, advanceDay, dayMeta, enemyOf, currentRoom, DAYS, ENEMIES,
  ITEM_NAMES, INV_X, INV_Y, INV_SLOT_W, INV_SLOT_H, INV_GAP,
} from './mystery.js';

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
    if (this.mode !== 'mystery') return;
    this.mystery = tapAt(this.mystery, x, y);
    this.audio.ensure();
    this.audio.ui();
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

    if (this.mode === 'title') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        this.mystery = emptyMysteryState();
        this.beginBriefing();
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
        this.setMode('title');
      }
      return;
    }

    if (this.mode === 'result') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        if (this.winner === 'face') {
          this.mystery = markBeaten(this.mystery);
          if (allBeaten(this.mystery)) {
            this.setMode('credits');
            this.say('5 DAYS CLOSED', 180, 'THE STRANGER FALLS');
          } else {
            this.mystery = advanceDay(this.mystery);
            this.beginBriefing();
          }
        } else {
          this.beginFight();
        }
      }
      return;
    }

    if (this.mode === 'mystery') {
      for (const [code, verb] of Object.entries(VERB_KEYS)) {
        if (this.input.just(code)) {
          this.mystery = setVerb(this.mystery, verb);
          this.audio.ui();
        }
      }
      if (this.input.just('KeyA') || this.input.just('ArrowLeft')) {
        this.mystery = cycleRoom(this.mystery, -1);
        this.audio.ui();
      }
      if (this.input.just('KeyD') || this.input.just('ArrowRight')) {
        this.mystery = cycleRoom(this.mystery, 1);
        this.audio.ui();
      }
      if (this.input.just('KeyW') || this.input.just('ArrowUp')) {
        this.setMode('journal');
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
    else if (this.mode === 'briefing') this._drawBriefing(ctx);
    else if (this.mode === 'mystery') this._drawMystery(ctx);
    else if (this.mode === 'journal') this._drawJournal(ctx);
    else if (this.mode === 'result') this._drawResult(ctx);
    else if (this.mode === 'credits') this._drawCredits(ctx);
    else this._drawFight(ctx);
  }

  _drawTitle(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.45)';
    ctx.fillRect(0, 80, CANVAS_W, 240);
    drawPixelText(ctx, "FACE INVADA'S", CANVAS_W / 2, 100, 4, '#ff4ad2', 'center');
    drawPixelText(ctx, '5 DAYS A STRANGER', CANVAS_W / 2, 150, 4, '#ffe566', 'center');
    drawPixelText(ctx, GAME_TITLE, CANVAS_W / 2, 210, 2, '#3df0ff', 'center');
    drawPixelText(ctx, GAME_SUBTITLE, CANVAS_W / 2, 250, 2, '#e878ff', 'center');
    drawFighter(ctx, 'face', 640, 560, 1, { t: this.time, punch: Math.max(0, Math.sin(this.time * 0.08)) }, 4.2);
    if (Math.sin(this.time * 0.12) > -0.2) {
      drawPixelText(ctx, 'PRESS START', CANVAS_W / 2, 620, 3, '#ffffff', 'center');
    }
    drawPixelText(ctx, 'SOLVE THEN FIGHT   TAP HOTSPOTS', CANVAS_W / 2, 680, 1, '#bbbbbb', 'center');
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
    drawFighter(ctx, enemy.id, 640, 640, -1, { t: this.time }, 2.6);
    drawPixelText(ctx, 'START TO INVESTIGATE', CANVAS_W / 2, 670, 2, '#fff4c2', 'center');
  }

  _drawMystery(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    const m = this.mystery;
    const day = dayMeta(m);
    const room = currentRoom(m);
    drawMysteryRoom(ctx, room, this.time, m.verb);

    const npc = room.hotspots.find((h) => ['bellhop', 'kara', 'widow', 'rivet', 'stranger'].includes(h.id));
    if (npc) {
      const who = npc.id === 'bellhop' ? 'vinyl' : npc.id;
      drawFighter(ctx, who, npc.x + npc.w / 2, npc.y + npc.h - 8, 1, { t: this.time }, 2.2);
    }
    drawFighter(ctx, 'face', 1180, 520, 1, { t: this.time }, 1.8);

    ctx.fillStyle = 'rgba(0,0,0,0.72)';
    ctx.fillRect(0, 0, CANVAS_W, 70);
    drawPixelText(ctx, `NIGHT ${day.day}  ${day.title}`, 24, 16, 2, '#ffe566');
    drawPixelText(ctx, room.name, 24, 44, 2, '#3df0ff');
    drawPixelText(ctx, 'LEFT/RIGHT ROOM   UP JOURNAL', 700, 20, 1, '#aaaaaa');
    if (canFight(m)) {
      drawPixelText(ctx, 'START FIGHT', 900, 44, 2, '#ff4ad2');
    }

    ctx.fillStyle = 'rgba(0,0,0,0.78)';
    ctx.fillRect(0, 540, CANVAS_W, 80);
    drawPixelText(ctx, m.log.toUpperCase(), 24, 558, 2, '#ffffff');
    drawPixelText(ctx, `VERB ${m.verb.toUpperCase()}`, 24, 592, 1, '#ffe566');

    ctx.fillStyle = 'rgba(8,6,16,0.92)';
    ctx.fillRect(0, 618, CANVAS_W, 102);
    drawPixelText(ctx, 'INVENTORY  TAP TO SELECT', 24, 600, 1, '#888888');
    for (let i = 0; i < 5; i++) {
      const x = INV_X + i * (INV_SLOT_W + INV_GAP);
      const id = m.inv[i];
      const on = id && m.selected === id;
      ctx.fillStyle = on ? '#ff4ad2' : '#22202c';
      ctx.fillRect(x - 3, INV_Y - 3, INV_SLOT_W + 6, INV_SLOT_H + 6);
      ctx.fillStyle = '#141018';
      ctx.fillRect(x, INV_Y, INV_SLOT_W, INV_SLOT_H);
      drawPixelText(ctx, id ? ITEM_NAMES[id] || id : '---', x + 12, INV_Y + 26, 2, id ? '#fff4c2' : '#444');
    }

    if (this.announce.text) {
      ctx.fillStyle = 'rgba(0,0,0,0.45)';
      ctx.fillRect(0, 300, CANVAS_W, 64);
      drawPixelText(ctx, this.announce.text, CANVAS_W / 2, 312, 4, '#ffffff', 'center');
    }
  }

  _drawJournal(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.75)';
    ctx.fillRect(80, 40, 1120, 640);
    drawPixelText(ctx, 'CASE JOURNAL', CANVAS_W / 2, 70, 4, '#e878ff', 'center');
    DAYS.forEach((d, i) => {
      const y = 150 + i * 80;
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
      drawPixelText(ctx, status, 900, y, 2, col);
    });
    drawPixelText(ctx, 'START TO CLOSE JOURNAL', CANVAS_W / 2, 620, 2, '#fff4c2', 'center');
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
    drawFighter(ctx, 'face', 300, 470, 1, this.facePose, 3.4 * pulse);
    drawFighter(ctx, enemy.id, 980, 470, -1, this.rivetPose, 3.4);
    drawPixelText(ctx, 'FACE INVADA', 300, 490, 1, '#fff', 'center');
    drawPixelText(ctx, enemy.handle, 980, 490, 1, '#fff', 'center');

    drawHighway(ctx, this.fight.notes, beat, 530, CANVAS_W);

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
    const hint = win ? (this.mystery.day >= 5 ? 'START FOR CREDITS' : 'START FOR NIGHT ' + (this.mystery.day + 1)) : 'START TO RETRY FIGHT';
    drawPixelText(ctx, hint, CANVAS_W / 2, 620, 2, '#fff4c2', 'center');
  }

  _drawCredits(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    drawPixelText(ctx, '5 DAYS A STRANGER', CANVAS_W / 2, 120, 4, '#ffe566', 'center');
    drawPixelText(ctx, 'THE NEON ARMS IS QUIET', CANVAS_W / 2, 190, 2, '#3df0ff', 'center');
    drawPixelText(ctx, 'FACE INVADA WALKS OUT', CANVAS_W / 2, 240, 2, '#ffffff', 'center');
    drawFighter(ctx, 'face', 640, 520, 1, { t: this.time, blade: 0.5 }, 4);
    drawPixelText(ctx, 'START TO RETURN', CANVAS_W / 2, 640, 2, '#fff4c2', 'center');
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

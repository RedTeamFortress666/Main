/**
 * FACE INVADA's BEAT BOXING — title, Tekken-esque select, rhythm fight.
 */
import {
  CANVAS_W, CANVAS_H, GAME_TITLE, GAME_SUBTITLE, HERO, RIVAL, ROSTER,
  BPM, LANES, CONTROL_MAP, MAX_HP, CPU_HP, SUPER_COST,
  beatAtFrame, makeChart, findHittable, expireNotes, gradeDelta,
  applyPlayerHit, applyMiss, applySuper, winnerOf, emptyFightState, canSuper,
} from './logic.js';
import { Input } from './input.js';
import { AudioBus } from './audio.js';
import {
  drawPixelText, drawNeonCity, drawFighter, drawHighway, lifeBarWidth,
  LANE_COLORS, pixelTextWidth,
} from './pixel.js';

export class Game {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.input = new Input();
    this.audio = new AudioBus();
    this.mode = 'title';
    this.time = 0;
    this.rosterIndex = 0;
    this.fight = null;
    this.announce = { text: '', sub: '', t: 0 };
    this.flash = 0;
    this._last = 0;
    this._bound = (t) => this.loop(t);
    this._beatInt = -1;
    this.facePose = { t: 0 };
    this.rivetPose = { t: 0 };
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
        this.audio.ensure();
        this.audio.ui();
        this.mode = 'select';
      }
      return;
    }
    if (this.mode === 'select') {
      if (this.input.just('KeyA') || this.input.just('ArrowLeft')) {
        this.rosterIndex = (this.rosterIndex + ROSTER.length - 1) % ROSTER.length;
        this.audio.ui();
      }
      if (this.input.just('KeyD') || this.input.just('ArrowRight')) {
        this.rosterIndex = (this.rosterIndex + 1) % ROSTER.length;
        this.audio.ui();
      }
      if (this.input.just('KeyW') || this.input.just('ArrowUp')) {
        this.rosterIndex = (this.rosterIndex + ROSTER.length - 3) % ROSTER.length;
        this.audio.ui();
      }
      if (this.input.just('KeyS') || this.input.just('ArrowDown')) {
        this.rosterIndex = (this.rosterIndex + 3) % ROSTER.length;
        this.audio.ui();
      }
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        const pick = ROSTER[this.rosterIndex];
        if (pick.locked) {
          this.say('LOCKED', 40, 'FACE INVADA ONLY');
          this.audio.miss();
          return;
        }
        this.audio.vocal();
        this.beginFight();
      }
      return;
    }
    if (this.mode === 'result') {
      if (this.input.just('Enter') || this.input.just('Space') || this.input.just('KeyZ')) {
        this.mode = 'title';
        this.announce = { text: '', sub: '', t: 0 };
      }
      return;
    }
    if (this.mode !== 'fight' || !this.fight) return;

    this.fight.frame += 1;
    const beat = beatAtFrame(this.fight.frame);
    this.fight.beat = beat;
    const bi = Math.floor(beat);
    if (bi !== this._beatInt && bi >= 0) {
      this._beatInt = bi;
      this.audio.tickBeat(bi);
    }

    const missed = expireNotes(this.fight.notes, beat);
    for (const _m of missed) {
      this.fight.state = applyMiss(this.fight.state);
      this.facePose.hit = 1;
      this.rivetPose.punch = 1;
      this.audio.miss();
    }

    for (const lane of LANES) {
      if (this.input.just(CONTROL_MAP[lane])) this._tryLane(lane);
    }

    const win = winnerOf(this.fight.state.playerHp, this.fight.state.cpuHp);
    if (win) {
      this.mode = 'result';
      this.winner = win;
      this.say(win === 'face' ? 'FACE INVADA WINS' : win === 'draw' ? 'DRAW' : 'MC RIVET WINS', 180,
        win === 'face' ? 'BASS IN YOUR FACE' : 'KEEP THE BEAT');
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

  beginFight() {
    this.fight = {
      frame: 0,
      beat: 0,
      notes: makeChart(7),
      state: emptyFightState(),
    };
    this._beatInt = -1;
    this.mode = 'fight';
    this.say('FIGHT!', 50, 'HIT THE BEAT');
    this.audio.ensure();
    this.audio.kick();
  }

  draw() {
    const ctx = this.ctx;
    ctx.imageSmoothingEnabled = false;
    if (this.mode === 'title') this._drawTitle(ctx);
    else if (this.mode === 'select') this._drawSelect(ctx);
    else if (this.mode === 'result') this._drawResult(ctx);
    else this._drawFight(ctx);
  }

  _drawTitle(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(0,0,0,0.45)';
    ctx.fillRect(0, 80, CANVAS_W, 220);
    drawPixelText(ctx, "FACE INVADA'S", CANVAS_W / 2, 110, 4, '#ff4ad2', 'center');
    drawPixelText(ctx, 'BEAT BOXING', CANVAS_W / 2, 160, 6, '#ffe566', 'center');
    drawPixelText(ctx, GAME_SUBTITLE, CANVAS_W / 2, 230, 2, '#3df0ff', 'center');
    drawFighter(ctx, 'face', 640, 560, 1, { t: this.time, punch: Math.max(0, Math.sin(this.time * 0.08)) }, 4.2);
    if (Math.sin(this.time * 0.12) > -0.2) {
      drawPixelText(ctx, 'PRESS START', CANVAS_W / 2, 620, 3, '#ffffff', 'center');
    }
    drawPixelText(ctx, 'ITALY  46  SILAT & BLADE', CANVAS_W / 2, 660, 1, '#bbbbbb', 'center');
  }

  _drawSelect(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    ctx.fillStyle = 'rgba(8,6,20,0.55)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

    drawPixelText(ctx, HERO.name, 420, 28, 4, '#e878ff');
    drawPixelText(ctx, HERO.title, 420, 78, 2, '#ff4ad2');
    drawPixelText(ctx, `COUNTRY  ${HERO.country}`, 420, 118, 2, '#ffffff');
    drawPixelText(ctx, `AGE  ${HERO.age}`, 420, 148, 2, '#ffffff');
    drawPixelText(ctx, `STYLE  ${HERO.style}`, 420, 178, 2, '#3df0ff');

    ctx.fillStyle = 'rgba(0,0,0,0.65)';
    ctx.fillRect(420, 220, 520, 70);
    drawPixelText(ctx, HERO.combo, 430, 232, 2, '#ffe566');
    drawPixelText(ctx, 'RIGHT RIGHT + PUNCH KICK', 430, 258, 1, '#dddddd');

    ctx.fillStyle = 'rgba(0,0,0,0.65)';
    ctx.fillRect(780, 320, 460, 110);
    const bio = HERO.bio;
    const words = bio.split(' ');
    let line = '';
    let ly = 336;
    for (const w of words) {
      const test = `${line}${w} `;
      if (pixelTextWidth(test, 1) > 440) {
        drawPixelText(ctx, line, 792, ly, 1, '#eeeeee');
        line = `${w} `;
        ly += 18;
      } else line = test;
    }
    drawPixelText(ctx, line, 792, ly, 1, '#eeeeee');

    // roster 2x3
    ROSTER.forEach((r, i) => {
      const col = i % 3;
      const row = Math.floor(i / 3);
      const x = 40 + col * 110;
      const y = 40 + row * 110;
      const on = i === this.rosterIndex;
      ctx.fillStyle = on ? '#ff4ad2' : '#222';
      ctx.fillRect(x - 4, y - 4, 100, 100);
      ctx.fillStyle = r.locked ? '#1a1a22' : '#141022';
      ctx.fillRect(x, y, 92, 92);
      if (r.id === 'face') {
        ctx.save();
        ctx.beginPath();
        ctx.rect(x, y, 92, 92);
        ctx.clip();
        drawFighter(ctx, 'face', x + 46, y + 108, 1, { t: this.time }, 1.4);
        ctx.restore();
      } else if (r.id === 'rivet') {
        ctx.save();
        ctx.beginPath();
        ctx.rect(x, y, 92, 92);
        ctx.clip();
        drawFighter(ctx, 'rivet', x + 46, y + 108, -1, { t: this.time }, 1.4);
        ctx.restore();
      } else {
        drawPixelText(ctx, r.name, x + 46, y + 38, 1, r.locked ? '#666' : '#fff', 'center');
      }
      if (r.locked) drawPixelText(ctx, 'LOCK', x + 46, y + 70, 1, '#888', 'center');
    });

    drawFighter(ctx, 'face', 980, 620, 1, { t: this.time, blade: 0.4 }, 4.4);
    drawPixelText(ctx, 'START TO FIGHT MC RIVET', CANVAS_W / 2, 680, 2, '#fff4c2', 'center');

    if (this.announce.text) {
      drawPixelText(ctx, this.announce.text, CANVAS_W / 2, 400, 3, '#ff8a80', 'center');
    }
  }

  _drawFight(ctx) {
    drawNeonCity(ctx, CANVAS_W, CANVAS_H, this.time);
    const st = this.fight.state;
    const beat = this.fight.beat;

    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(0, 0, CANVAS_W, 92);
    this._bar(ctx, 20, 18, 480, st.playerHp, MAX_HP, '#3dcc5a', false);
    this._bar(ctx, CANVAS_W - 500, 18, 480, st.cpuHp, CPU_HP, '#ff4d6a', true);
    drawPixelText(ctx, 'FACE INVADA', 24, 48, 2, '#e878ff');
    drawPixelText(ctx, 'MC RIVET', CANVAS_W - 24, 48, 2, '#ff8a80', 'right');
    ctx.fillStyle = '#111';
    ctx.fillRect(20, 70, 220, 10);
    ctx.fillStyle = st.bass >= SUPER_COST ? '#e878ff' : '#b44cff';
    ctx.fillRect(20, 70, (st.bass / 100) * 220, 10);
    drawPixelText(ctx, st.bass >= SUPER_COST ? 'BASS READY' : 'BASS', 24, 84, 1, '#eee');

    const pulse = 1 + Math.sin(beat * Math.PI * 2) * 0.04;
    drawFighter(ctx, 'face', 300, 470, 1, this.facePose, 3.4 * pulse);
    drawFighter(ctx, 'rivet', 980, 470, -1, this.rivetPose, 3.4);
    drawPixelText(ctx, 'FACE INVADA', 300, 490, 1, '#fff', 'center');
    drawPixelText(ctx, 'MC RIVET', 980, 490, 1, '#fff', 'center');

    drawHighway(ctx, this.fight.notes, beat, 530, CANVAS_W);

    if (st.combo > 1) {
      drawPixelText(ctx, `${st.combo} HIT`, 640, 100, 3, '#fff', 'center');
    }
    if (st.lastGrade) {
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
    drawFighter(ctx, win ? 'face' : 'rivet', CANVAS_W / 2, 420, 1, { t: this.time }, 4.5);
    drawPixelText(ctx, this.announce.text || 'WINNER', CANVAS_W / 2, 80, 4, '#e878ff', 'center');
    drawPixelText(ctx, this.announce.sub || '', CANVAS_W / 2, 130, 2, '#ffe566', 'center');
    const st = this.fight?.state;
    if (st) {
      drawPixelText(ctx, `SCORE ${st.score}`, CANVAS_W / 2, 500, 2, '#fff', 'center');
      drawPixelText(ctx, `MAX COMBO ${st.maxCombo}   PERFECTS ${st.perfects}`, CANVAS_W / 2, 534, 1, '#ddd', 'center');
    }
    drawPixelText(ctx, 'PRESS START', CANVAS_W / 2, 620, 3, '#fff4c2', 'center');
  }
}

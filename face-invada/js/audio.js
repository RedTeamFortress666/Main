/**
 * Beat-box synth: kick, snare, hat, bass, vocal chops. No samples.
 */
export class AudioBus {
  constructor() {
    this.ctx = null;
    this.master = 0.22;
    this._clock = 0;
  }

  ensure() {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    if (!this.ctx) this.ctx = new AC();
    if (this.ctx.state === 'suspended') this.ctx.resume();
    return this.ctx;
  }

  now() {
    return this.ctx ? this.ctx.currentTime : 0;
  }

  tone(freq, dur, type = 'square', vol = 0.4, slide = null) {
    const ctx = this.ensure();
    if (!ctx) return;
    const osc = ctx.createOscillator();
    const g = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, ctx.currentTime);
    if (slide != null) osc.frequency.exponentialRampToValueAtTime(Math.max(20, slide), ctx.currentTime + dur);
    g.gain.setValueAtTime(0.0001, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(vol * this.master, ctx.currentTime + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + dur);
    osc.connect(g).connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + dur + 0.02);
  }

  noise(dur, vol, hp) {
    const ctx = this.ensure();
    if (!ctx) return;
    const n = Math.max(1, Math.floor(ctx.sampleRate * dur));
    const buf = ctx.createBuffer(1, n, ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < n; i++) data[i] = Math.random() * 2 - 1;
    const src = ctx.createBufferSource();
    src.buffer = buf;
    const filter = ctx.createBiquadFilter();
    filter.type = 'highpass';
    filter.frequency.value = hp;
    const g = ctx.createGain();
    g.gain.setValueAtTime(vol * this.master, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + dur);
    src.connect(filter).connect(g).connect(ctx.destination);
    src.start();
  }

  kick() {
    this.tone(140, 0.16, 'sine', 0.7, 42);
    this.tone(60, 0.12, 'triangle', 0.4, 30);
  }

  snare() {
    this.noise(0.1, 0.45, 1200);
    this.tone(220, 0.08, 'triangle', 0.18, 80);
  }

  hat() {
    this.noise(0.04, 0.22, 6000);
  }

  punch() { this.tone(180, 0.08, 'square', 0.35, 90); this.noise(0.05, 0.25, 400); }
  kickHit() { this.tone(140, 0.1, 'sawtooth', 0.3, 70); }
  blade() { this.noise(0.07, 0.4, 2800); this.tone(880, 0.08, 'square', 0.2, 400); }
  bassDrop() {
    this.tone(70, 0.4, 'sawtooth', 0.55, 36);
    this.tone(110, 0.28, 'square', 0.22, 50);
  }
  vocal() {
    this.tone(220, 0.12, 'sawtooth', 0.28, 160);
    this.tone(330, 0.1, 'triangle', 0.18, 200);
  }
  perfect() { this.tone(880, 0.06, 'square', 0.2); this.tone(1320, 0.05, 'triangle', 0.12); }
  miss() { this.tone(90, 0.14, 'sawtooth', 0.25, 40); }
  ui() { this.tone(520, 0.06, 'square', 0.18); }

  tickBeat(beatInt) {
    const b = beatInt % 4;
    this.kick();
    if (b === 1 || b === 3) this.hat();
    if (b === 2) this.snare();
    if (b === 0) this.tone(55, 0.2, 'sine', 0.18, 40);
  }
}

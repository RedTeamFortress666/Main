/**
 * Tiny Web Audio synth. No sample files — punches, meows, milk, and a
 * Twin Peaks-ish sting are all oscillators + noise.
 */
export class AudioBus {
  constructor() {
    this.ctx = null;
    this.enabled = true;
    this.master = 0.22;
  }

  ensure() {
    if (!this.enabled) return null;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    if (!this.ctx) this.ctx = new AC();
    if (this.ctx.state === 'suspended') this.ctx.resume();
    return this.ctx;
  }

  now() {
    return this.ctx ? this.ctx.currentTime : 0;
  }

  tone(freq, dur, type = 'square', vol = 0.4, slideTo = null) {
    const ctx = this.ensure();
    if (!ctx) return;
    const osc = ctx.createOscillator();
    const g = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, ctx.currentTime);
    if (slideTo != null) {
      osc.frequency.exponentialRampToValueAtTime(Math.max(20, slideTo), ctx.currentTime + dur);
    }
    g.gain.setValueAtTime(0.0001, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(vol * this.master, ctx.currentTime + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + dur);
    osc.connect(g).connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + dur + 0.02);
  }

  noise(dur = 0.08, vol = 0.5, hp = 400) {
    const ctx = this.ensure();
    if (!ctx) return;
    const n = ctx.sampleRate * dur;
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

  meow(high = false) {
    const f = high ? 520 : 340;
    this.tone(f, 0.18, 'sawtooth', 0.35, f * 0.55);
    this.tone(f * 1.5, 0.12, 'triangle', 0.12, f * 0.8);
  }

  punch() {
    this.noise(0.07, 0.55, 300);
    this.tone(90, 0.07, 'square', 0.3, 40);
  }

  kick() {
    this.noise(0.09, 0.45, 200);
    this.tone(70, 0.1, 'sine', 0.4, 30);
  }

  whoosh() {
    this.noise(0.12, 0.25, 800);
    this.tone(240, 0.1, 'triangle', 0.12, 80);
  }

  special() {
    this.tone(180, 0.16, 'sawtooth', 0.28, 420);
    this.tone(360, 0.2, 'square', 0.12, 220);
  }

  super() {
    this.tone(110, 0.4, 'sawtooth', 0.3, 440);
    this.tone(165, 0.45, 'triangle', 0.2, 660);
    this.noise(0.2, 0.3, 200);
  }

  hit() {
    this.noise(0.05, 0.5, 600);
    this.tone(200, 0.05, 'square', 0.2, 90);
  }

  block() {
    this.tone(160, 0.06, 'square', 0.18);
    this.noise(0.04, 0.2, 1200);
  }

  ko() {
    this.tone(220, 0.35, 'sawtooth', 0.28, 60);
    this.tone(110, 0.5, 'triangle', 0.22, 40);
  }

  /** Twin Peaks-adjacent: two low, slightly sour notes. */
  sting() {
    this.tone(55, 0.7, 'sine', 0.35);
    this.tone(82.4, 0.85, 'triangle', 0.22);
    this.tone(61, 0.4, 'sine', 0.12);
  }

  milk() {
    this.tone(420, 0.08, 'sine', 0.15, 280);
    setTimeout(() => this.tone(380, 0.08, 'sine', 0.12, 250), 90);
    setTimeout(() => this.tone(360, 0.1, 'sine', 0.1, 220), 180);
  }

  tuna() {
    this.tone(180, 0.08, 'square', 0.2);
    this.tone(540, 0.16, 'triangle', 0.18, 240);
  }

  win() {
    [262, 330, 392, 523].forEach((f, i) => {
      setTimeout(() => this.tone(f, 0.18, 'triangle', 0.22), i * 110);
    });
  }

  ui() {
    this.tone(520, 0.06, 'square', 0.16);
  }
}

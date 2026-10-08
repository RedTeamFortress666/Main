/**
 * Tiny Web Audio synth. Punches, meows, hisses, milk, and a looping
 * cartoon theme — no sample files required.
 */
export class AudioBus {
  constructor() {
    this.ctx = null;
    this.enabled = true;
    this.master = 0.22;
    this.themeOn = false;
    this.themeGain = null;
    this._themeTimer = null;
    this._themeStart = 0;
  }

  ensure() {
    if (!this.enabled) return null;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    if (!this.ctx) this.ctx = new AC();
    if (this.ctx.state === 'suspended') this.ctx.resume();
    this.startTheme();
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

  meow(high = false) {
    const f = high ? 560 : 360;
    this.tone(f, 0.22, 'sawtooth', 0.42, f * 0.52);
    this.tone(f * 1.48, 0.14, 'triangle', 0.16, f * 0.78);
    this.tone(f * 0.5, 0.1, 'sine', 0.08, f * 0.35);
  }

  /** Spitty cat hiss — used when the fighters bump during an attack. */
  hiss() {
    this.noise(0.16, 0.55, 1800);
    this.tone(920, 0.14, 'sawtooth', 0.18, 180);
    this.tone(1400, 0.08, 'square', 0.08, 400);
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

  fairy() {
    [880, 990, 1174, 1320].forEach((f, i) => {
      setTimeout(() => this.tone(f, 0.09, 'sine', 0.12, f + 80), i * 70);
    });
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

  /**
   * Catchy 16-beat cartoon loop in C major. Duck it during fights so
   * meows and hits stay readable.
   */
  startTheme() {
    const ctx = this.ctx;
    if (!ctx || this.themeOn) return;
    this.themeOn = true;
    this.themeGain = ctx.createGain();
    this.themeGain.gain.value = 0.28;
    this.themeGain.connect(ctx.destination);
    this._scheduleTheme(ctx.currentTime + 0.05);
  }

  setThemeScene(mode) {
    if (!this.themeGain || !this.ctx) return;
    const t = this.ctx.currentTime;
    let v = 0.28;
    if (mode === 'fight' || mode === 'intro') v = 0.1;
    else if (mode === 'timeout' || mode === 'revive' || mode === 'april') v = 0.06;
    else if (mode === 'matchEnd' || mode === 'race') v = 0.2;
    this.themeGain.gain.cancelScheduledValues(t);
    this.themeGain.gain.linearRampToValueAtTime(v * this.master * 4, t + 0.25);
  }

  _scheduleTheme(start) {
    if (!this.themeOn || !this.ctx || !this.themeGain) return;
    const beat = 60 / 128;
    const loop = 16 * beat;
    const melody = [
      [0, 76, 0.45], [0.5, 79, 0.45], [1, 84, 0.45], [1.5, 79, 0.45],
      [2, 76, 0.45], [2.5, 72, 0.45], [3, 74, 0.45], [3.5, 76, 0.9],
      [4.5, 79, 0.45], [5, 84, 0.45], [5.5, 86, 0.45], [6, 84, 0.45],
      [6.5, 79, 0.45], [7, 76, 0.9],
      [8, 72, 0.45], [8.5, 76, 0.45], [9, 79, 0.45], [9.5, 84, 0.9],
      [10.5, 83, 0.45], [11, 81, 0.45], [11.5, 79, 0.45],
      [12, 77, 0.45], [12.5, 76, 0.45], [13, 74, 0.45], [13.5, 72, 0.45],
      [14, 71, 0.45], [14.5, 72, 0.45], [15, 76, 0.9],
    ];
    const bass = [
      [0, 48, 1.9], [2, 43, 1.9], [4, 45, 1.9], [6, 47, 1.9],
      [8, 48, 1.9], [10, 41, 1.9], [12, 43, 1.9], [14, 48, 1.9],
    ];
    const sparkle = [
      [1, 96, 0.2], [3, 91, 0.2], [5, 96, 0.2], [7, 88, 0.2],
      [9, 96, 0.2], [11, 93, 0.2], [13, 91, 0.2], [15, 88, 0.3],
    ];
    for (const n of melody) this._themeNote(start, n, 'triangle', 0.22);
    for (const n of bass) this._themeNote(start, n, 'sine', 0.16);
    for (const n of sparkle) this._themeNote(start, n, 'square', 0.045);
    const next = start + loop;
    const wait = Math.max(40, (next - 0.12 - this.ctx.currentTime) * 1000);
    this._themeTimer = setTimeout(() => this._scheduleTheme(next), wait);
  }

  _themeNote(loopStart, [beat, midi, durBeats], type, vol) {
    const ctx = this.ctx;
    const t0 = loopStart + beat * (60 / 128);
    const dur = durBeats * (60 / 128);
    if (t0 < ctx.currentTime - 0.02) return;
    const freq = 440 * (2 ** ((midi - 69) / 12));
    const osc = ctx.createOscillator();
    const g = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t0);
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(vol, t0 + 0.02);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(g).connect(this.themeGain);
    osc.start(t0);
    osc.stop(t0 + dur + 0.03);
  }
}

import { CONTROL_MAP, INPUT_BUFFER, numpadDir } from './logic.js';

export class Input {
  constructor() {
    this.down = new Set();
    this.pressed = new Set();
    this.released = new Set();
    this._onDown = (e) => this._keydown(e);
    this._onUp = (e) => this._keyup(e);
    window.addEventListener('keydown', this._onDown);
    window.addEventListener('keyup', this._onUp);
  }

  _keydown(e) {
    if (e.repeat) return;
    if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) {
      e.preventDefault();
    }
    this.down.add(e.code);
    this.pressed.add(e.code);
    if (e.key === ',') this.down.add('Comma');
  }

  setVirtual(code, isDown) {
    if (isDown) {
      if (!this.down.has(code)) this.pressed.add(code);
      this.down.add(code);
    } else {
      this.down.delete(code);
      this.released.add(code);
    }
  }

  _keyup(e) {
    this.down.delete(e.code);
    this.released.add(e.code);
    if (e.key === ',') this.down.delete('Comma');
  }

  held(code) {
    return this.down.has(code);
  }

  just(code) {
    return this.pressed.has(code);
  }

  endFrame() {
    this.pressed.clear();
    this.released.clear();
  }

  snapshot(side, facing) {
    const m = CONTROL_MAP[side];
    const left = this.held(m.left);
    const right = this.held(m.right);
    const up = this.held(m.up);
    const down = this.held(m.down);
    const blockHeld = this.held(m.block) || (facing >= 0 ? left && !right : right && !left);
    const punch = this.just(m.punch) || this.just(m.lp);
    const kick = this.just(m.kick);
    const laser = this.just(m.laser);
    const jump = this.just(m.jump) || this.just(m.up);
    return {
      left, right, up, down, jump, punch, kick, laser,
      lp: punch, rp: false, lk: kick, rk: false,
      mp: kick, hp: laser, mk: kick, hk: false,
      anyPunch: punch,
      anyKick: kick,
      lpHeld: this.held(m.punch) || this.held(m.lp),
      mpHeld: this.held(m.kick),
      hpHeld: this.held(m.laser),
      block: blockHeld,
      sidestep: false,
      throw: false,
      dir: numpadDir(left, right, up, down, facing),
      pressedPunch: punch,
      pressedKick: kick,
      buttonClass: punch ? 'p' : kick ? 'k' : laser ? 'p' : null,
      attackId: punch ? 'lp' : kick ? 'lk' : laser ? 'hp' : null,
      limb: punch ? 'lp' : kick ? 'lk' : null,
    };
  }

  _buttonClass(m) {
    if (this.just(m.lk) || this.just(m.mk) || this.just(m.hk) || this.just(m.mp)) return 'k';
    if (this.just(m.lp) || this.just(m.hp)) return 'p';
    return null;
  }

  _attackId(m) {
    if (this.just(m.lp)) return 'lp';
    if (this.just(m.mp)) return 'mp';
    if (this.just(m.hp)) return 'hp';
    if (this.just(m.lk)) return 'lk';
    if (this.just(m.mk)) return 'mk';
    if (this.just(m.hk)) return 'hk';
    return null;
  }
}

export class MotionBuffer {
  constructor() {
    this.dirs = [];
  }

  push(dir) {
    this.dirs.push(dir);
    if (this.dirs.length > INPUT_BUFFER) this.dirs.shift();
  }

  clear() {
    this.dirs.length = 0;
  }
}

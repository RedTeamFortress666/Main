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
    return {
      left, right, up, down,
      lp: this.just(m.lp),
      mp: this.just(m.mp),
      hp: this.just(m.hp),
      lk: this.just(m.lk),
      mk: this.just(m.mk),
      hk: this.just(m.hk),
      anyPunch: this.just(m.lp) || this.just(m.hp),
      anyKick: this.just(m.lk) || this.just(m.mk) || this.just(m.hk) || this.just(m.mp),
      lpHeld: this.held(m.lp),
      mpHeld: this.held(m.mp),
      hpHeld: this.held(m.hp),
      block: blockHeld,
      dir: numpadDir(left, right, up, down, facing),
      pressedPunch: this.just(m.lp) || this.just(m.mp) || this.just(m.hp),
      pressedKick: this.just(m.lk) || this.just(m.mk) || this.just(m.hk),
      buttonClass: this._buttonClass(m),
      attackId: this._attackId(m),
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

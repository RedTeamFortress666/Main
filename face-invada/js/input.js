export class Input {
  constructor() {
    this.down = new Set();
    this.pressed = new Set();
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
  }

  _keyup(e) {
    this.down.delete(e.code);
  }

  setVirtual(code, isDown) {
    if (isDown) {
      if (!this.down.has(code)) this.pressed.add(code);
      this.down.add(code);
    } else {
      this.down.delete(code);
    }
  }

  just(code) {
    return this.pressed.has(code);
  }

  held(code) {
    return this.down.has(code);
  }

  endFrame() {
    this.pressed.clear();
  }
}

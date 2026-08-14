import { Game } from './game.js';
import { CANVAS_W, CANVAS_H } from './logic.js';

const canvas = document.getElementById('game');
canvas.width = CANVAS_W;
canvas.height = CANVAS_H;

function fit() {
  const wrap = document.getElementById('wrap');
  const scale = Math.min(window.innerWidth / CANVAS_W, window.innerHeight / CANVAS_H);
  wrap.style.transform = `translate(-50%, -50%) scale(${scale})`;
  wrap.style.width = `${CANVAS_W}px`;
  wrap.style.height = `${CANVAS_H}px`;
}
window.addEventListener('resize', fit);
window.addEventListener('orientationchange', fit);
fit();

const game = new Game(canvas);
window.CatFighter = game;
game.start();

const coarse = window.matchMedia('(pointer: coarse)').matches
  || 'ontouchstart' in window
  || navigator.maxTouchPoints > 0;
const touchUi = document.getElementById('touch-ui');
if (coarse && touchUi) {
  touchUi.classList.add('show');
  touchUi.setAttribute('aria-hidden', 'false');
  for (const btn of touchUi.querySelectorAll('[data-code]')) {
    const code = btn.getAttribute('data-code');
    const down = (e) => {
      e.preventDefault();
      btn.classList.add('held');
      game.audio.ensure();
      game.input.setVirtual(code, true);
    };
    const up = (e) => {
      e.preventDefault();
      btn.classList.remove('held');
      game.input.setVirtual(code, false);
    };
    btn.addEventListener('pointerdown', down);
    btn.addEventListener('pointerup', up);
    btn.addEventListener('pointercancel', up);
    btn.addEventListener('pointerleave', up);
  }
}

canvas.addEventListener('pointerdown', () => {
  game.audio.ensure();
  if (game.mode === 'title' || game.mode === 'menu' || game.mode === 'matchEnd') {
    game.input.setVirtual('Enter', true);
    setTimeout(() => game.input.setVirtual('Enter', false), 80);
  }
});

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js').catch(() => {});
}

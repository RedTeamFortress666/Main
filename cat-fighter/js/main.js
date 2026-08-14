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
fit();

const game = new Game(canvas);
window.CatFighter = game;
game.start();

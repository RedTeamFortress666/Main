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
window.FaceInvada = game;
game.start();

function syncPad(mode) {
  const mysteryModes = ['title', 'briefing', 'mystery', 'journal', 'credits', 'cut', 'sentinel', 'grammy', 'nightout', 'drive'];
  const mystery = mysteryModes.includes(mode);
  document.body.classList.toggle('mode-mystery', mystery && mode !== 'title');
  document.body.classList.toggle('mode-fight', mode === 'fight' || mode === 'club' || mode === 'bribe' || mode === 'pac' || mode === 'pong');
  for (const btn of document.querySelectorAll('[data-mystery][data-fight]')) {
    btn.textContent = mystery ? btn.getAttribute('data-mystery') : btn.getAttribute('data-fight');
  }
  const start = document.querySelector('.tbtn.start');
  if (start) {
    if (mode === 'mystery') start.textContent = 'START';
    else if (mode === 'fight') start.textContent = 'START';
    else start.textContent = 'START';
  }
}
game.onModeChange = syncPad;
syncPad(game.mode);

const touchUi = document.getElementById('touch-ui');
if (touchUi) {
  for (const btn of touchUi.querySelectorAll('[data-code]')) {
    const code = btn.getAttribute('data-code');
    const down = (e) => {
      e.preventDefault();
      btn.classList.add('held');
      game.audio.ensure();
      game.input.setVirtual(code, true);
      if (typeof e.pointerId === 'number' && btn.setPointerCapture) {
        try { btn.setPointerCapture(e.pointerId); } catch (_) { /* ignore */ }
      }
    };
    const up = (e) => {
      e.preventDefault();
      btn.classList.remove('held');
      game.input.setVirtual(code, false);
    };
    btn.addEventListener('pointerdown', down);
    btn.addEventListener('pointerup', up);
    btn.addEventListener('pointercancel', up);
    btn.addEventListener('lostpointercapture', up);
  }
}

function canvasToGame(e) {
  const r = canvas.getBoundingClientRect();
  return {
    x: ((e.clientX - r.left) / r.width) * CANVAS_W,
    y: ((e.clientY - r.top) / r.height) * CANVAS_H,
  };
}

canvas.addEventListener('pointerdown', (e) => {
  game.audio.ensure();
  const pt = canvasToGame(e);
  game.tapCanvas(pt.x, pt.y);
});

if ('serviceWorker' in navigator && !['localhost', '127.0.0.1'].includes(location.hostname)) {
  navigator.serviceWorker.register('./sw.js').catch(() => {});
}

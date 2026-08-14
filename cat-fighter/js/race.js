/**
 * Four-cat oval race. Heads poke out of the cars.
 * Pure helpers are in logic.js (trackPoint, raceRanking).
 */
import {
  CANVAS_W, CANVAS_H, TRACK_LEN, RACE_LAPS, RACERS,
  trackPoint, raceRanking, clamp,
} from './logic.js';
import { thinkRaceAI } from './ai.js';
import { drawPixelText, drawCatCar } from './pixel.js';

const LANE_MIN = -28;
const LANE_MAX = 36;
const ACCEL = 0.16;
const BRAKE = 0.22;
const DRAG = 0.985;
const STEER = 1.15;

function makeCar(id, index, human) {
  return {
    id,
    name: RACERS[id].name,
    short: RACERS[id].short,
    car: RACERS[id].car,
    color: RACERS[id].color,
    s: (TRACK_LEN - index * 55) % TRACK_LEN,
    lane: -12 + index * 12,
    speed: 0,
    finished: false,
    laps: 0,
    place: index + 1,
    human,
    _seed: index * 1.7 + 0.3,
  };
}

export function createRace(vsCpu) {
  return {
    vsCpu,
    t: 0,
    countdown: 180,
    cars: [
      makeCar('yoko', 0, true),
      makeCar('morlan', 1, !vsCpu),
      makeCar('baby', 2, false),
      makeCar('kittens', 3, false),
    ],
    done: false,
    winner: null,
    finishOrder: [],
  };
}

function controlFor(car, snap) {
  if (!car.human) return thinkRaceAI(car);
  return {
    accel: snap.up || snap.lp || snap.rp,
    brake: snap.down,
    left: snap.left,
    right: snap.right,
  };
}

export function updateRace(race, p1Snap, p2Snap) {
  race.t += 1;
  if (race.countdown > 0) {
    race.countdown -= 1;
    return race;
  }

  const snaps = { yoko: p1Snap, morlan: race.vsCpu ? null : p2Snap };

  for (const car of race.cars) {
    if (car.finished) continue;
    const ctrl = controlFor(car, snaps[car.id] || {});
    if (ctrl.accel) car.speed += ACCEL;
    if (ctrl.brake) car.speed -= BRAKE;
    car.speed *= DRAG;
    car.speed = clamp(car.speed, 0, car.id === 'yoko' ? 10.6 : car.id === 'baby' ? 10.4 : car.id === 'kittens' ? 9.4 : 9.2);

    if (ctrl.left) car.lane -= STEER;
    if (ctrl.right) car.lane += STEER;
    car.lane = clamp(car.lane, LANE_MIN, LANE_MAX);
    if (car.lane <= LANE_MIN + 1 || car.lane >= LANE_MAX - 1) car.speed *= 0.92;

    car.s += car.speed;
    if (car.s >= TRACK_LEN) {
      car.s -= TRACK_LEN;
      car.laps += 1;
      if (car.laps >= RACE_LAPS && !car.finished) {
        car.finished = true;
        car.speed = 0;
        race.finishOrder.push(car.id);
      }
    }
  }

  for (let i = 0; i < race.cars.length; i++) {
    for (let j = i + 1; j < race.cars.length; j++) {
      const a = race.cars[i];
      const b = race.cars[j];
      const ds = Math.abs(((a.s - b.s + TRACK_LEN / 2) % TRACK_LEN) - TRACK_LEN / 2);
      const dl = Math.abs(a.lane - b.lane);
      if (ds < 28 && dl < 18) {
        const bump = 0.8;
        if (a.s >= b.s) { a.speed *= 0.96; b.speed *= 0.88; b.lane -= Math.sign(b.lane - a.lane || 1) * bump; }
        else { b.speed *= 0.96; a.speed *= 0.88; a.lane -= Math.sign(a.lane - b.lane || 1) * bump; }
        a.lane = clamp(a.lane, LANE_MIN, LANE_MAX);
        b.lane = clamp(b.lane, LANE_MIN, LANE_MAX);
      }
    }
  }

  const ranked = raceRanking(race.cars);
  ranked.forEach((c, i) => { c.place = i + 1; });

  if (race.finishOrder.length && !race._finishT) race._finishT = race.t;
  if (race._finishT && !race.done && (race.t - race._finishT > 240 || race.finishOrder.length === 4)) {
    race.done = true;
    race.winner = race.finishOrder[0];
    race.cars.filter((c) => !c.finished).sort((a, b) => a.place - b.place)
      .forEach((c) => race.finishOrder.push(c.id));
  }
  return race;
}

export function drawRace(ctx, race) {
  ctx.imageSmoothingEnabled = false;
  ctx.fillStyle = '#1a5a28';
  ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

  ctx.fillStyle = '#0e3a18';
  ctx.beginPath();
  ctx.ellipse(CANVAS_W / 2, CANVAS_H / 2 + 18, 360, 150, 0, 0, Math.PI * 2);
  ctx.fill();

  ctx.strokeStyle = '#3a3a40';
  ctx.lineWidth = 88;
  ctx.beginPath();
  ctx.ellipse(CANVAS_W / 2, CANVAS_H / 2 + 18, 470, 230, 0, 0, Math.PI * 2);
  ctx.stroke();

  ctx.strokeStyle = '#f4e27a';
  ctx.lineWidth = 3;
  ctx.setLineDash([18, 16]);
  ctx.beginPath();
  ctx.ellipse(CANVAS_W / 2, CANVAS_H / 2 + 18, 470, 230, 0, 0, Math.PI * 2);
  ctx.stroke();
  ctx.setLineDash([]);

  ctx.strokeStyle = '#fff';
  ctx.lineWidth = 6;
  const start = trackPoint(0, 0);
  ctx.beginPath();
  ctx.moveTo(start.x - 18, start.y - 40);
  ctx.lineTo(start.x + 18, start.y + 40);
  ctx.stroke();

  drawPixelText(ctx, 'CAT CAR RACING', CANVAS_W / 2, 12, 3, '#ffe566', 'center');
  drawPixelText(ctx, `${RACE_LAPS} LAPS  -  HEADS OUT THE SUNROOF`, CANVAS_W / 2, 42, 1, '#ddd', 'center');

  const drawOrder = [...race.cars].sort((a, b) => trackPoint(a.s, a.lane).y - trackPoint(b.s, b.lane).y);
  for (const car of drawOrder) {
    const p = trackPoint(car.s, car.lane);
    drawCatCar(ctx, car.id, p.x, p.y, p.heading, race.t, 2.15);
    drawPixelText(ctx, car.short, p.x, p.y + 28, 1, car.color, 'center');
  }

  race.cars.forEach((car, i) => {
    const x = 16;
    const y = 80 + i * 36;
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    ctx.fillRect(x, y, 280, 32);
    drawPixelText(ctx, `${car.place}  ${car.short}`, x + 8, y + 8, 2, car.color);
    drawPixelText(ctx, `LAP ${Math.min(car.laps + 1, RACE_LAPS)}/${RACE_LAPS}`, x + 160, y + 12, 1, '#eee');
  });

  if (race.countdown > 0) {
    const n = race.countdown > 120 ? '3' : race.countdown > 60 ? '2' : race.countdown > 8 ? '1' : 'GO';
    drawPixelText(ctx, n, CANVAS_W / 2, CANVAS_H / 2 - 24, 8, '#fff', 'center');
  }

  if (race.done) {
    ctx.fillStyle = 'rgba(0,0,0,0.62)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    const w = RACERS[race.winner] || RACERS.yoko;
    drawPixelText(ctx, `${w.short} WINS`, CANVAS_W / 2, 200, 5, w.color, 'center');
    drawPixelText(ctx, w.car.toUpperCase(), CANVAS_W / 2, 260, 2, '#fff', 'center');
    race.finishOrder.forEach((id, i) => {
      const r = RACERS[id];
      drawPixelText(ctx, `${i + 1}  ${r.short}  -  ${r.car.toUpperCase()}`, CANVAS_W / 2, 330 + i * 36, 2, r.color, 'center');
    });
    drawPixelText(ctx, 'PRESS ENTER', CANVAS_W / 2, 640, 3, '#fff4c2', 'center');
  } else {
    drawPixelText(ctx, 'P1 YOKO  W GAS  S BRAKE  A D STEER', CANVAS_W / 2, 690, 1, '#aaa', 'center');
    if (!race.vsCpu) {
      drawPixelText(ctx, 'P2 MORLAN  ARROWS', CANVAS_W / 2, 706, 1, '#aaa', 'center');
    }
  }
}

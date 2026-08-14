/**
 * Simple vs-CPU brain for punch / kick / jump / laser.
 */
export function thinkAI(me, opp, difficulty = 0.28) {
  const snap = {
    left: false, right: false, up: false, down: false,
    jump: false, punch: false, kick: false, laser: false,
    lp: false, rp: false, lk: false, rk: false,
    mp: false, hp: false, mk: false, hk: false,
    anyPunch: false, anyKick: false, block: false,
    dir: 5, pressedPunch: false, pressedKick: false,
    buttonClass: null, attackId: null, limb: null,
    throw: false, sidestep: false,
  };

  if (me.busy) return snap;

  const dx = opp.x - me.x;
  const dist = Math.abs(dx);
  const towardLeft = dx < 0;
  const r = Math.random();

  if (opp.attacking && dist < 140 && r < 0.08 + difficulty * 0.12) {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
    return snap;
  }

  if (dist > 240) {
    if (towardLeft) snap.left = true;
    else snap.right = true;
    if (r < 0.04) snap.jump = true;
    if (r < 0.05 && me.laser >= 34) {
      snap.laser = true;
      snap.buttonClass = 'p';
    }
    return snap;
  }

  if (dist > 120) {
    if (r < 0.62) {
      if (towardLeft) snap.left = true;
      else snap.right = true;
    }
    if (r > 0.9) {
      snap.kick = true;
      snap.anyKick = true;
      snap.pressedKick = true;
      snap.buttonClass = 'k';
      snap.attackId = 'lk';
      snap.limb = 'lk';
    }
    return snap;
  }

  if (r < 0.32) {
    snap.punch = true;
    snap.anyPunch = true;
    snap.pressedPunch = true;
    snap.buttonClass = 'p';
    snap.attackId = 'lp';
    snap.limb = 'lp';
  } else if (r < 0.48) {
    snap.kick = true;
    snap.anyKick = true;
    snap.pressedKick = true;
    snap.buttonClass = 'k';
    snap.attackId = 'lk';
    snap.limb = 'lk';
  } else if (r < 0.54 && me.laser >= 34) {
    snap.laser = true;
    snap.buttonClass = 'p';
  } else if (r < 0.62) {
    snap.jump = true;
    snap.up = true;
  } else if (r < 0.82) {
    if (towardLeft) snap.left = true;
    else snap.right = true;
  } else if (r < 0.9) {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
  }
  return snap;
}

export function thinkRaceAI(car, difficulty = 0.55) {
  const target = 6.2 + difficulty * 1.8 + (car.id === 'baby' ? 0.6 : car.id === 'kittens' ? 0.2 : 0);
  const wobble = (Math.sin(car.s * 0.01 + car._seed) * 10);
  return {
    accel: car.speed < target,
    brake: car.speed > target + 1.6,
    left: wobble > 6,
    right: wobble < -6,
  };
}

/**
 * Tekken-style vs-CPU brain. Same snapshot shape as a human.
 */
export function thinkAI(me, opp, difficulty = 0.72) {
  const snap = {
    left: false, right: false, up: false, down: false,
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
  const aggressive = difficulty;

  if (opp.attacking && dist < 140 && r < 0.4 + aggressive * 0.2) {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
    if (opp.attackType === 'low') snap.down = true;
    if (r < 0.12) snap.sidestep = true;
    return snap;
  }

  if (me.hp < 280 && dist < 160 && r < 0.22) {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
    return snap;
  }

  if (dist > 280) {
    if (towardLeft) snap.left = true;
    else snap.right = true;
    if (r < 0.08) snap.up = true;
    if (r < 0.16 && me.meter >= 100) {
      snap.lp = true;
      snap.rk = true;
      snap.limb = 'lp';
      snap.attackId = 'lp';
      snap.buttonClass = 'p';
      snap.pressedPunch = true;
    }
    return snap;
  }

  if (dist > 130) {
    if (r < 0.55 * aggressive) {
      if (towardLeft) snap.left = true;
      else snap.right = true;
    } else if (r < 0.68) {
      snap.up = true;
      if (towardLeft) snap.left = true;
      else snap.right = true;
    }
    if (r > 0.86) {
      snap.rk = true;
      snap.limb = 'rk';
      snap.attackId = 'rk';
      snap.buttonClass = 'k';
      snap.pressedKick = true;
    }
    return snap;
  }

  if (dist < 88 && r < 0.14) {
    snap.throw = true;
    snap.lp = true;
    snap.rp = true;
    snap.limb = 'lp';
    snap.attackId = 'lp';
    snap.buttonClass = 'p';
    return snap;
  }

  if (r < 0.1) {
    snap.down = true;
    snap.rk = true;
    snap.limb = 'rk';
    snap.attackId = 'rk';
    snap.buttonClass = 'k';
    snap.pressedKick = true;
  } else if (r < 0.2) {
    snap.down = true;
    snap.rp = true;
    snap.limb = 'rp';
    snap.attackId = 'rp';
    snap.buttonClass = 'p';
    snap.pressedPunch = true;
  } else if (r < 0.45) {
    snap.lp = true;
    snap.limb = 'lp';
    snap.attackId = 'lp';
    snap.buttonClass = 'p';
    snap.pressedPunch = true;
  } else if (r < 0.6) {
    snap.rp = true;
    snap.limb = 'rp';
    snap.attackId = 'rp';
    snap.buttonClass = 'p';
    snap.pressedPunch = true;
  } else if (r < 0.72) {
    snap.lk = true;
    snap.limb = 'lk';
    snap.attackId = 'lk';
    snap.buttonClass = 'k';
    snap.pressedKick = true;
  } else if (r < 0.84) {
    if (towardLeft) snap.left = true;
    else snap.right = true;
  } else {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
  }
  return snap;
}

export function thinkRaceAI(car, difficulty = 0.7) {
  const target = 7.2 + difficulty * 2.4 + (car.id === 'kittens' ? 0.4 : 0);
  const wobble = (Math.sin(car.s * 0.01 + car._seed) * 10);
  return {
    accel: car.speed < target,
    brake: car.speed > target + 1.6,
    left: wobble > 6,
    right: wobble < -6,
  };
}

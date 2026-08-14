/**
 * Simple vs-CPU brain. Reads the same snapshot shape as a human so the
 * fighter never knows who is driving it.
 */
export function thinkAI(me, opp, difficulty = 0.72) {
  const snap = {
    left: false, right: false, up: false, down: false,
    lp: false, mp: false, hp: false, lk: false, mk: false, hk: false,
    anyPunch: false, anyKick: false, block: false,
    dir: 5, pressedPunch: false, pressedKick: false,
    buttonClass: null, attackId: null,
  };

  if (me.busy) return snap;

  const dx = opp.x - me.x;
  const dist = Math.abs(dx);
  const towardLeft = dx < 0;
  const r = Math.random();
  const aggressive = difficulty;

  if (opp.attacking && dist < 140 && r < 0.45 + aggressive * 0.2) {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
    if (opp.attackType === 'low') snap.down = true;
    return snap;
  }

  if (me.hp < 280 && dist < 160 && r < 0.25) {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
    return snap;
  }

  if (dist > 280) {
    if (towardLeft) snap.left = true;
    else snap.right = true;
    if (r < 0.08) snap.up = true;
    if (r < 0.12 && me.meter >= 100) {
      snap.down = true;
      snap.hp = true;
      snap.buttonClass = 'p';
      snap.attackId = 'hp';
      snap.pressedPunch = true;
      me.motion.dirs.push(2, 3, 6, 2, 3, 6);
    } else if (r < 0.2) {
      me.motion.dirs.push(2, 3, 6);
      snap.lp = true;
      snap.buttonClass = 'p';
      snap.attackId = 'lp';
      snap.pressedPunch = true;
    }
    return snap;
  }

  if (dist > 140) {
    if (r < 0.55 * aggressive) {
      if (towardLeft) snap.left = true;
      else snap.right = true;
    } else if (r < 0.7) {
      snap.up = true;
      if (towardLeft) snap.left = true;
      else snap.right = true;
    }
    if (r > 0.82) {
      me.motion.dirs.push(2, 3, 6);
      snap.mp = true;
      snap.buttonClass = 'k';
      snap.attackId = 'mp';
      snap.pressedKick = true;
    }
    return snap;
  }

  if (r < 0.12) {
    snap.down = true;
    snap.mk = true;
    snap.attackId = 'mk';
    snap.buttonClass = 'k';
    snap.pressedKick = true;
  } else if (r < 0.22) {
    me.motion.dirs.push(6, 2, 3);
    snap.hp = true;
    snap.buttonClass = 'p';
    snap.attackId = 'hp';
    snap.pressedPunch = true;
  } else if (r < 0.32) {
    me.motion.dirs.push(2, 1, 4);
    snap.lp = true;
    snap.buttonClass = 'p';
    snap.attackId = 'lp';
    snap.pressedPunch = true;
  } else if (r < 0.55) {
    snap.lp = r < 0.4;
    snap.mp = r >= 0.4 && r < 0.48;
    snap.hp = r >= 0.48;
    snap.attackId = snap.hp ? 'hp' : snap.mp ? 'mp' : 'lp';
    snap.buttonClass = 'p';
    snap.pressedPunch = true;
  } else if (r < 0.7) {
    snap.lk = true;
    snap.attackId = 'lk';
    snap.buttonClass = 'k';
    snap.pressedKick = true;
  } else if (r < 0.82) {
    if (towardLeft) snap.left = true;
    else snap.right = true;
  } else {
    snap.block = true;
    if (me.facing >= 0) snap.left = true;
    else snap.right = true;
  }
  return snap;
}

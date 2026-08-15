/**
 * FACE INVADA campaign: arcade homages, cutscenes, club tricks, bribe boss.
 * Original mechanics (not Atari/Nintendo assets).
 */

export const CREDITS_BY = 'MADE BY SOME BASTARD';
export const MISSION = 'TRACK DOWN THE FUNKIEST BASSLINE';
export const PONG_DISCLAIMER = "PONG DON'T SUE - ITS AN HOMAGE";
export const TABLET_JOKE = 'PILLS THAT MAKE ME LARGER? YEAH RIGHT.';
export const LANA_LINE = 'LANAAAAAA';
export const KIM_LINE = "I'M SORRY KIM, I JUST DON'T THINK KANYE'S THAT GOOD FOR YOU";

export const DJ_TRICKS = [
  { id: 'comp', name: 'MAD COMPRESSION', keys: ['KeyZ', 'KeyX'] },
  { id: 'wubz', name: 'BASS WUBZ', keys: ['KeyV'] },
  { id: 'glitch', name: 'GLITTTCHHH', keys: ['KeyC', 'KeyC'] },
  { id: 'sic', name: 'HEAPS SIC AYE', keys: ['KeyZ', 'KeyV'] },
  { id: 'scratch', name: 'VINYL SCRATCH', keys: ['KeyX', 'KeyC'] },
  { id: 'hippy', name: 'HIPPY HATE', keys: ['KeyZ', 'KeyX', 'KeyC'] },
];

export const CUTS = {
  mission: {
    title: 'MISSION',
    lines: [
      'NIGHT CITY WANTS THE FUNKIEST BASSLINE.',
      'FACE INVADA, 37, SILAT AND BLADE.',
      'FETCH. JUMP. SLAY RAVE VAMPIRES.',
      'DO NOT TRUST TABLETS. OR POLITICIANS.',
    ],
  },
  lana: {
    title: LANA_LINE,
    lines: [LANA_LINE],
    bike: true,
  },
  kim: {
    title: 'UNKNOWN NUMBER',
    lines: [KIM_LINE],
    phone: true,
  },
  atari: {
    title: 'HOMAGE HOUR',
    lines: [
      'COMBAT? MORE LIKE COMBAT FATIGUE.',
      'ET PHONED IN SICK. WE KEPT THE PIT.',
      'MARIO 64 HAD A HAT. WE HAVE A CAP.',
      'GOLDENEYE FOUR PLAYER? ONE HEAD. PAC TIME.',
      'BANJO HAD A BACKPACK. WE HAVE A BAG.',
    ],
  },
};

export const CAMPAIGN = [
  { id: 'nightout', kind: 'nightout' },
  { id: 'lana', kind: 'cut', cut: 'lana' },
  { id: 'pac', kind: 'pac' },
  { id: 'kim', kind: 'cut', cut: 'kim' },
  { id: 'sentinel', kind: 'sentinel' },
  { id: 'atari', kind: 'cut', cut: 'atari' },
  { id: 'pong', kind: 'pong' },
  { id: 'n2', kind: 'mystery', day: 2 },
  { id: 'f2', kind: 'fight' },
  { id: 'club', kind: 'club' },
  { id: 'n3', kind: 'mystery', day: 3 },
  { id: 'f3', kind: 'fight' },
  { id: 'grammy', kind: 'grammy' },
  { id: 'n4', kind: 'mystery', day: 4 },
  { id: 'f4', kind: 'fight' },
  { id: 'n5', kind: 'mystery', day: 5 },
  { id: 'f5', kind: 'fight' },
  { id: 'bribe', kind: 'bribe' },
  { id: 'credits', kind: 'credits' },
];

export function campaignStep(i) {
  return CAMPAIGN[Math.max(0, Math.min(CAMPAIGN.length - 1, i))];
}

export function emptyPacState() {
  const pellets = [];
  for (let r = 1; r < 9; r++) {
    for (let c = 1; c < 15; c++) {
      if ((r === 4 && c >= 6 && c <= 9) || (c === 7 && r >= 3 && r <= 5)) continue;
      pellets.push({ c, r, power: (r === 1 || r === 8) && (c === 1 || c === 14) });
    }
  }
  return {
    c: 1,
    r: 8,
    dir: 1,
    power: 0,
    pellets,
    eaten: 0,
    dead: false,
    won: false,
    vamps: [
      { c: 7, r: 4, dc: 1, dr: 0 },
      { c: 8, r: 4, dc: -1, dr: 0 },
      { c: 14, r: 1, dc: 0, dr: 1 },
    ],
  };
}

function wrapTile(n, max) {
  if (n < 1) return max;
  if (n > max) return 1;
  return n;
}

export function stepPac(state, dc, dr) {
  if (state.won || state.dead) return state;
  const next = {
    ...state,
    pellets: state.pellets.map((p) => ({ ...p })),
    vamps: state.vamps.map((v) => ({ ...v })),
  };
  if (dc || dr) {
    next.c = wrapTile(next.c + dc, 14);
    next.r = wrapTile(next.r + dr, 8);
    next.dir = dc || next.dir;
  }
  const hit = next.pellets.findIndex((p) => p.c === next.c && p.r === next.r);
  if (hit >= 0) {
    const p = next.pellets[hit];
    next.pellets.splice(hit, 1);
    next.eaten += 1;
    if (p.power) next.power = 80;
  }
  if (next.power > 0) next.power -= 1;
  next.vamps = next.vamps.map((v, i) => {
    const turn = (next.eaten + i) % 3 === 0;
    let dc2 = v.dc;
    let dr2 = v.dr;
    if (turn) {
      dc2 = i % 2 === 0 ? 1 : -1;
      dr2 = i % 2 === 0 ? 0 : 0;
      if (next.eaten % 2 === 0) {
        dc2 = 0;
        dr2 = i % 2 === 0 ? 1 : -1;
      }
    }
    return {
      ...v,
      c: wrapTile(v.c + dc2, 14),
      r: wrapTile(v.r + dr2, 8),
      dc: dc2,
      dr: dr2,
    };
  });
  for (const v of next.vamps) {
    if (v.c === next.c && v.r === next.r) {
      if (next.power > 0) {
        v.c = 7;
        v.r = 4;
        next.eaten += 5;
      } else {
        next.dead = true;
      }
    }
  }
  if (next.pellets.length === 0) next.won = true;
  return next;
}

export function emptyPongState() {
  return {
    py: 280,
    cy: 280,
    ball: { x: 640, y: 320, vx: 7, vy: 4 },
    ps: 0,
    cs: 0,
    won: false,
    lost: false,
    disclaimer: PONG_DISCLAIMER,
  };
}

export function stepPong(state, paddleDir) {
  if (state.won || state.lost) return state;
  const next = { ...state, ball: { ...state.ball } };
  next.py = Math.max(120, Math.min(500, next.py + paddleDir * 10));
  const b = next.ball;
  b.x += b.vx;
  b.y += b.vy;
  if (b.y < 130 || b.y > 530) b.vy *= -1;
  if (b.x < 80 && b.y > next.py && b.y < next.py + 90) {
    b.vx = Math.abs(b.vx) + 0.2;
    b.x = 80;
  }
  next.cy += Math.sign(b.y - (next.cy + 45)) * 5.2;
  next.cy = Math.max(120, Math.min(500, next.cy));
  if (b.x > 1200 && b.y > next.cy && b.y < next.cy + 90) {
    b.vx = -Math.abs(b.vx) - 0.2;
    b.x = 1200;
  }
  if (b.x < 20) {
    next.cs += 1;
    next.ball = { x: 640, y: 320, vx: 7, vy: 3 };
  }
  if (b.x > 1260) {
    next.ps += 1;
    next.ball = { x: 640, y: 320, vx: -7, vy: 3 };
  }
  if (next.ps >= 3) next.won = true;
  if (next.cs >= 3) next.lost = true;
  return next;
}

export function emptyClubState() {
  return {
    i: 0,
    buf: [],
    cheer: 0,
    won: false,
    last: '',
  };
}

export function clubPress(state, code) {
  if (state.won) return state;
  const next = { ...state, buf: state.buf.concat([code]) };
  const trick = DJ_TRICKS[next.i];
  const need = trick.keys;
  if (next.buf.length < need.length) return next;
  const ok = need.every((k, i) => next.buf[i] === k);
  next.buf = [];
  if (ok) {
    next.last = trick.name;
    next.cheer += 18;
    next.i += 1;
    if (next.i >= DJ_TRICKS.length) next.won = true;
  } else {
    next.last = 'CROWD BOOS';
    next.cheer = Math.max(0, next.cheer - 6);
  }
  return next;
}

export function emptySentinelState() {
  return {
    px: 160,
    py: 0,
    vy: 0,
    coffee: true,
    donut: true,
    deliveredC: false,
    deliveredD: false,
    holding: null,
    breakShown: false,
    won: false,
    party: [],
    banner: 'SAFARI HUT. CATCH BREWCRAB AND GLAZEMOTH IN THE TALL GRASS.',
    wilds: [
      { id: 'coffee', beat: 'brewcrab', x: 420, y: 0, vx: 2.4, dazed: 0 },
      { id: 'donut', beat: 'glazemoth', x: 720, y: -50, vx: -2.2, hop: 40, baseY: -50, dazed: 0 },
    ],
  };
}

export function stepSentinel(state, dir, jump, take) {
  if (state.won) return state;
  const next = {
    ...state,
    wilds: (state.wilds || []).map((w) => ({ ...w })),
    party: (state.party || []).slice(),
  };
  next.px = Math.max(80, Math.min(1180, next.px + dir * 8));
  const ground = next.py >= 0;
  if (jump && ground) next.vy = -12;
  next.vy = (next.vy || 0) + 0.6;
  next.py = (next.py || 0) + next.vy;
  if (next.py > 0) {
    next.py = 0;
    next.vy = 0;
  }

  next.wilds = next.wilds.map((w) => {
    if (w.caught) return w;
    let x = w.x + (w.vx || 0);
    let vx = w.vx || 0;
    if (x < 300 || x > 940) vx *= -1;
    let y = w.y;
    if (w.hop) y = (w.baseY || 0) + Math.sin(x * 0.05) * w.hop;
    const dazed = Math.max(0, (w.dazed || 0) - 1);
    const stomp = Math.abs(next.px - x) < 44 && Math.abs(next.py - y) < 46 && next.vy > 1;
    if (stomp) {
      next.vy = -8;
      next.banner = `${(w.beat || w.id).toUpperCase()} DAZED. TAKE TO TIN IT.`;
      return { ...w, x, vx, y, dazed: 80 };
    }
    return { ...w, x, vx, y, dazed };
  });

  if (take && !next.holding) {
    const w = next.wilds.find((c) => !c.caught && Math.abs(next.px - c.x) < 56 && Math.abs(next.py - c.y) < 56);
    if (w) {
      w.caught = true;
      next.holding = w.id;
      next.party.push(w.beat || w.id);
      if (w.id === 'coffee') next.coffee = false;
      if (w.id === 'donut') next.donut = false;
      next.banner = `CAUGHT ${(w.beat || w.id).toUpperCase()}. RUN IT TO THE HUT.`;
    }
  }
  if (take && next.px > 980 && next.holding) {
    if (next.holding === 'coffee') next.deliveredC = true;
    if (next.holding === 'donut') next.deliveredD = true;
    next.holding = null;
    if (next.deliveredC && !next.deliveredD) next.breakShown = true;
    next.banner = next.breakShown && !next.deliveredD
      ? 'HUT: NICE CRAB. STILL WANT THE MOTH. NOT YOUR PLAYLIST.'
      : 'HUT TAKES THE CATCH.';
  }
  if (next.deliveredC && next.deliveredD) next.won = true;
  return next;
}

export function emptyGrammyState() {
  return {
    px: 200,
    py: 0,
    vy: 0,
    got: 0,
    trophies: [
      { x: 360, y: -80, vx: 2.2, got: false },
      { x: 560, y: -40, vx: -2, got: false },
      { x: 780, y: -100, vx: 1.8, got: false },
      { x: 1000, y: -50, vx: -2.4, got: false },
    ],
    won: false,
  };
}

export function stepGrammy(state, dir, jump, take = false) {
  if (state.won) return state;
  const next = {
    ...state,
    trophies: state.trophies.map((t) => ({ ...t })),
  };
  next.px = Math.max(80, Math.min(1180, next.px + dir * 8));
  const ground = next.py >= 0;
  if (jump && ground) next.vy = -13;
  next.vy = (next.vy || 0) + 0.6;
  next.py = (next.py || 0) + next.vy;
  if (next.py > 0) {
    next.py = 0;
    next.vy = 0;
  }
  for (const t of next.trophies) {
    if (t.got) continue;
    if (Math.abs(next.px - t.x) < 50 && Math.abs(next.py - t.y) < 40) {
      t.got = true;
      next.got += 1;
    }
  }
  for (const t of next.trophies) {
    if (t.got) continue;
    t.x += t.vx || 0;
    if (t.x < 200 || t.x > 1100) t.vx = -(t.vx || 2);
    t.y += Math.sin((t.x || 0) * 0.08) * 0.8;
  }
  if (take) {
    for (const t of next.trophies) {
      if (t.got) continue;
      if (Math.abs(next.px - t.x) < 64 && Math.abs(next.py - t.y) < 56) {
        t.got = true;
        next.got += 1;
      }
    }
  }
  if (next.got >= 4) next.won = true;
  return next;
}

export function emptyBribeState() {
  return {
    px: 260,
    py: 0,
    vy: 0,
    hp: 100,
    boss: 120,
    bossX: 900,
    cash: [],
    won: false,
    lost: false,
    frame: 0,
  };
}

export function stepBribe(state, dir, jump, punch) {
  if (state.won || state.lost) return state;
  const next = { ...state, cash: state.cash.map((c) => ({ ...c })) };
  next.frame += 1;
  next.px = Math.max(80, Math.min(1100, next.px + dir * 8));
  const ground = next.py >= 0;
  if (jump && ground) next.vy = -12;
  next.vy = (next.vy || 0) + 0.6;
  next.py = (next.py || 0) + next.vy;
  if (next.py > 0) {
    next.py = 0;
    next.vy = 0;
  }
  next.bossX += Math.sin(next.frame * 0.04) * 3;
  if (next.frame % 36 === 0) {
    next.cash.push({ x: next.bossX, y: 360, vx: -6, vy: -2 + (next.frame % 5) });
  }
  const live = [];
  for (const c of next.cash) {
    c.x += c.vx;
    c.y += c.vy;
    c.vy += 0.25;
    const hit = Math.abs(c.x - next.px) < 40 && Math.abs((480 + next.py) - c.y) < 50;
    if (hit) {
      next.hp -= 12;
    } else if (c.y < 600 && c.x > 0) {
      live.push(c);
    }
  }
  next.cash = live;
  if (punch && Math.abs(next.px - next.bossX) < 120) next.boss -= 10;
  if (next.boss <= 0) next.won = true;
  if (next.hp <= 0) next.lost = true;
  return next;
}

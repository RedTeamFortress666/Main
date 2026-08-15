import { describe, it, expect } from 'vitest';
import {
  GAME_TITLE, HERO, LANES, makeChart, gradeDelta, findHittable,
  expireNotes, applyPlayerHit, applyMiss, applySuper, canSuper,
  winnerOf, emptyFightState,   beatAtFrame, comboMult, hitDamage, framesPerBeat,
  PERFECT_WINDOW, GOOD_WINDOW, SUPER_COST, CPU_HP, MAX_HP,
} from './js/logic.js';
import { FONT5, pixelTextWidth } from './js/pixel.js';
import {
  emptyMysteryState, setVerb, applyVerb, tapInventory, tapAt,
  canFight, advanceDay, cycleRoom, hasItem, hitHotspot, hitInventoryIndex,
  DAYS, ENEMIES, INV_X, INV_Y, currentRoom, enemyOf, stepWalk, PX_MAX,
  stepPhysics,
} from './js/mystery.js';
import {
  CAMPAIGN, CREDITS_BY, PONG_DISCLAIMER, DJ_TRICKS, KIM_LINE, LANA_LINE, DONUT_LINE,
  emptyPacState, stepPac, emptyPongState, stepPong, clubPress, emptyClubState,
  emptyBribeState, stepBribe, emptySentinelState, stepSentinel,
  emptyGrammyState, stepGrammy,
} from './js/arcade.js';
import {
  emptyNightState, stepNight, tryRecipe, talkNearest, useSelected, has,
  selectNightItem, tapNight, hitNightInv, BAG_X, BAG_Y, PIPES, CAR,
} from './js/nightout.js';
import { resolveEncounter, makeEncounter, addToParty, beatName } from './js/catch.js';
import { emptyDriveState, stepDrive, PART_NEED } from './js/drive.js';

describe('title and hero', () => {
  it('is FACE INVADA\'s BEAT BOXING', () => {
    expect(GAME_TITLE).toBe("FACE INVADA'S BEAT BOXING");
    expect(HERO.name).toBe('FACE INVADA');
    expect(HERO.country).toBe('ITALY');
    expect(HERO.age).toBe(37);
    expect(HERO.style).toMatch(/SILAT/);
  });
});

describe('chart', () => {
  it('builds a deterministic note chart after the count-in', () => {
    const a = makeChart(7);
    const b = makeChart(7);
    expect(a.length).toBeGreaterThan(8);
    expect(a.map((n) => `${n.beat}:${n.lane}`)).toEqual(b.map((n) => `${n.beat}:${n.lane}`));
    expect(a.every((n) => n.beat >= 4)).toBe(true);
    expect(a.every((n) => LANES.includes(n.lane))).toBe(true);
  });

  it('changes when the seed changes', () => {
    const a = makeChart(1).map((n) => `${n.beat}:${n.lane}`).join(',');
    const b = makeChart(99).map((n) => `${n.beat}:${n.lane}`).join(',');
    expect(a).not.toBe(b);
  });
});

describe('timing', () => {
  it('maps frames to beats using BPM', () => {
    expect(beatAtFrame(0)).toBe(0);
    expect(beatAtFrame(framesPerBeat())).toBeCloseTo(1);
    expect(beatAtFrame(framesPerBeat() * 2)).toBeCloseTo(2);
  });

  it('grades perfect and good windows', () => {
    expect(gradeDelta(0)).toBe('perfect');
    expect(gradeDelta(PERFECT_WINDOW)).toBe('perfect');
    expect(gradeDelta(PERFECT_WINDOW + 0.01)).toBe('good');
    expect(gradeDelta(GOOD_WINDOW)).toBe('good');
    expect(gradeDelta(GOOD_WINDOW + 0.05)).toBe(null);
  });

  it('finds the nearest unhit note in a lane', () => {
    const notes = [
      { beat: 4, lane: 'punch', hit: false },
      { beat: 8, lane: 'kick', hit: false },
    ];
    expect(findHittable(notes, 'punch', 4.05).beat).toBe(4);
    expect(findHittable(notes, 'kick', 4.05)).toBe(null);
  });

  it('expires late notes as misses', () => {
    const notes = [{ beat: 4, lane: 'punch', hit: false, grade: null }];
    const missed = expireNotes(notes, 5.2);
    expect(missed).toHaveLength(1);
    expect(notes[0].grade).toBe('miss');
  });
});

describe('combat math', () => {
  it('rewards combos and fills bass on hits', () => {
    let s = emptyFightState();
    expect(s.playerHp).toBe(MAX_HP);
    expect(s.cpuHp).toBe(CPU_HP);
    s = applyPlayerHit(s, 'perfect');
    expect(s.cpuHp).toBeLessThan(CPU_HP);
    expect(s.combo).toBe(1);
    expect(s.bass).toBeGreaterThan(0);
    expect(hitDamage('perfect', 16)).toBeGreaterThan(hitDamage('perfect', 1));
    expect(comboMult(16)).toBeGreaterThan(comboMult(0));
  });

  it('misses drop combo and chip Face Invada', () => {
    let s = applyPlayerHit(emptyFightState(), 'good');
    s = applyMiss(s);
    expect(s.combo).toBe(0);
    expect(s.playerHp).toBeLessThan(MAX_HP);
  });

  it('fires a bass super only when charged', () => {
    expect(canSuper(SUPER_COST - 1)).toBe(false);
    const charged = { ...emptyFightState(), bass: 100 };
    const r = applySuper(charged);
    expect(r.ok).toBe(true);
    expect(r.state.bass).toBe(0);
    expect(r.state.cpuHp).toBeLessThan(CPU_HP);
    expect(applySuper(emptyFightState()).ok).toBe(false);
  });

  it('declares Face Invada the winner when Rivet hits 0', () => {
    expect(winnerOf(100, 0)).toBe('face');
    expect(winnerOf(0, 100)).toBe('rivet');
    expect(winnerOf(0, 100, 'vinyl')).toBe('vinyl');
    expect(winnerOf(50, 50)).toBe(null);
  });

  it('builds a fight with custom enemy HP', () => {
    const s = emptyFightState(88);
    expect(s.cpuHp).toBe(88);
    expect(s.playerHp).toBe(MAX_HP);
  });
});

describe('pixel font', () => {
  it('has glyphs for FACE INVADA BEAT BOXING', () => {
    const need = "FACE INVADA'S BEAT BOXING!?0123456789>-+";
    for (const ch of need) {
      expect(FONT5[ch], ch).toBeTruthy();
    }
    expect(pixelTextWidth('FACE', 2)).toBe(4 * 6 * 2);
  });
});

function solveDay(state, steps) {
  let s = state;
  for (const step of steps) {
    if (step.verb) s = setVerb(s, step.verb);
    if (step.hotspot) s = applyVerb(s, step.hotspot);
    if (typeof step.inv === 'number') s = tapInventory(s, step.inv);
  }
  return s;
}

describe('5 days a stranger', () => {
  it('has five original nights and five enemies', () => {
    expect(DAYS).toHaveLength(5);
    expect(DAYS[0].title).toBe('LOCKED LOBBY');
    expect(ENEMIES.vinyl.name).toMatch(/BELLHOP/);
    expect(ENEMIES.stranger.id).toBe('stranger');
  });

  it('refuses the keycard while Vinyl is watching', () => {
    let s = emptyMysteryState();
    s = solveDay(s, [
      { verb: 'look', hotspot: 'desk' },
      { verb: 'take', hotspot: 'desk' },
    ]);
    expect(hasItem(s, 'keycard')).toBe(false);
    expect(canFight(s)).toBe(false);
  });

  it('solves night 1 by distracting Vinyl, then PIN 333', () => {
    let s = emptyMysteryState();
    s = solveDay(s, [
      { verb: 'look', hotspot: 'plant' },
      { verb: 'look', hotspot: 'desk' },
      { verb: 'look', hotspot: 'carpet' },
      { verb: 'take', hotspot: 'carpet' },
      { verb: 'use', hotspot: 'bellhop' },
      { verb: 'take', hotspot: 'desk' },
      { verb: 'use', hotspot: 'door' },
    ]);
    expect(hasItem(s, 'vinyl')).toBe(true);
    expect(hasItem(s, 'keycard')).toBe(true);
    expect(s.solved[0]).toBe(true);
    expect(canFight(s)).toBe(true);
    expect(enemyOf(s).id).toBe('vinyl');
  });

  it('walks Face Invada and changes rooms at the edge', () => {
    let s = emptyMysteryState();
    const start = s.px;
    s = stepWalk(s, 1);
    expect(s.px).toBeGreaterThan(start);
    s.px = PX_MAX + 1;
    s = stepWalk(s, 1);
    expect(s.room).toBe('hall');
    s = cycleRoom(s, 1);
    expect(s.room).toBe('room101');
    s = emptyMysteryState();
    s = applyVerb(s, 'exitR');
    expect(s.room).toBe('hall');
  });

  it('solves nights 2-5 then advances', () => {
    let s = emptyMysteryState();
    s.solved[0] = true;
    s = advanceDay(s);
    expect(s.day).toBe(2);
    expect(s.room).toBe('hall');
    s = solveDay(s, [
      { verb: 'talk', hotspot: 'kara' },
      { verb: 'look', hotspot: 'linens' },
      { verb: 'take', hotspot: 'linens' },
      { verb: 'use', hotspot: 'ventgrate' },
      { verb: 'take', hotspot: 'tape' },
      { verb: 'use', hotspot: 'deck' },
    ]);
    expect(s.solved[1]).toBe(true);
    expect(canFight(s)).toBe(true);

    s.beaten[1] = true;
    s = advanceDay(s);
    expect(s.day).toBe(3);
    s = solveDay(s, [
      { verb: 'look', hotspot: 'mirror' },
      { verb: 'look', hotspot: 'bed' },
      { verb: 'take', hotspot: 'bed' },
      { verb: 'look', hotspot: 'drain' },
      { verb: 'use', hotspot: 'drain' },
      { verb: 'use', hotspot: 'widow' },
    ]);
    expect(s.solved[2]).toBe(true);

    s.beaten[2] = true;
    s = advanceDay(s);
    expect(s.day).toBe(4);
    s = solveDay(s, [
      { verb: 'look', hotspot: 'coffee' },
      { verb: 'take', hotspot: 'coffee' },
      { verb: 'look', hotspot: 'fridge' },
      { verb: 'use', hotspot: 'fridge' },
      { verb: 'take', hotspot: 'fridge' },
      { verb: 'use', hotspot: 'monitors' },
    ]);
    expect(s.solved[3]).toBe(true);

    s.beaten[3] = true;
    s = advanceDay(s);
    expect(s.day).toBe(5);
    s = solveDay(s, [
      { verb: 'look', hotspot: 'diary' },
      { verb: 'take', hotspot: 'blade' },
      { verb: 'talk', hotspot: 'stranger' },
      { verb: 'use', hotspot: 'sigilbig' },
    ]);
    expect(s.solved[4]).toBe(true);
    expect(enemyOf(s).id).toBe('stranger');
  });

  it('jumps for air clues and tablets make you larger', () => {
    let s = emptyMysteryState();
    expect(s.py).toBe(0);
    s = stepPhysics(s, true);
    expect(s.py).toBeLessThan(0);
    s = setVerb(s, 'look');
    s = applyVerb(s, 'tablet');
    s = setVerb(s, 'take');
    s = applyVerb(s, 'tablet');
    expect(hasItem(s, 'tablet')).toBe(true);
    s = setVerb(s, 'use');
    s = applyVerb(s, 'desk');
    expect(s.grown).toBe(true);
    expect(s.banner).toMatch(/PILLS THAT MAKE ME LARGER/);
  });

  it('maps canvas taps to hotspots and inventory', () => {
    const s = emptyMysteryState();
    const desk = currentRoom(s).hotspots.find((h) => h.id === 'desk');
    expect(hitHotspot(s, desk.x + 10, desk.y + 10).id).toBe('desk');
    expect(hitInventoryIndex(INV_X + 10, INV_Y + 10)).toBe(0);
    const after = tapAt(s, desk.x + 10, desk.y + 10);
    expect(after.flags.deskLook).toBe(true);
  });
});

describe('campaign arcade', () => {
  it('credits a bastard and warns Atari', () => {
    expect(CREDITS_BY).toBe('MADE BY SOME BASTARD');
    expect(PONG_DISCLAIMER).toMatch(/HOMAGE/);
    expect(KIM_LINE).toMatch(/KANYE/);
    expect(LANA_LINE).toBe('LANAAAAAA');
    expect(CAMPAIGN[0].kind).toBe('nightout');
    expect(CAMPAIGN[1].kind).toBe('cut');
    expect(CAMPAIGN[2].kind).toBe('drive');
    expect(DONUT_LINE).toMatch(/SENTINALESE/);
    expect(CAMPAIGN.some((s) => s.kind === 'mystery' && s.day === 1)).toBe(false);
    expect(CAMPAIGN.some((s) => s.kind === 'pac')).toBe(true);
    expect(CAMPAIGN[CAMPAIGN.length - 1].kind).toBe('credits');
  });

  it('lets Face head chomp pellets and slay a powered vampire', () => {
    let p = emptyPacState();
    const n = p.pellets.length;
    p = stepPac(p, 1, 0);
    expect(p.pellets.length).toBeLessThanOrEqual(n);
    p.power = 20;
    p.c = p.vamps[0].c;
    p.r = p.vamps[0].r;
    p = stepPac(p, 0, 0);
    expect(p.dead).toBe(false);
  });

  it('plays pong until Face scores 3', () => {
    let s = emptyPongState();
    s.ps = 2;
    s.ball = { x: 1261, y: 300, vx: 7, vy: 0 };
    s.cy = 0;
    s = stepPong(s, 0);
    expect(s.won).toBe(true);
  });

  it('clears a club set with the six trick combos', () => {
    let s = emptyClubState();
    for (const trick of DJ_TRICKS) {
      for (const k of trick.keys) s = clubPress(s, k);
    }
    expect(s.won).toBe(true);
    expect(s.cheer).toBeGreaterThan(50);
  });

  it('catches roaming breakfast and delivers it to the hut gym', () => {
    let s = emptySentinelState();
    const crab = s.wilds.find((w) => w.id === 'coffee');
    s.px = crab.x;
    s.py = crab.y;
    s = stepSentinel(s, 0, false, true);
    expect(s.holding).toBe('coffee');
    expect(s.party).toContain('brewcrab');
    s.px = 1000;
    s = stepSentinel(s, 0, false, true);
    expect(s.deliveredC).toBe(true);
    expect(s.breakShown).toBe(true);
    const moth = s.wilds.find((w) => w.id === 'donut');
    s.px = moth.x;
    s.py = moth.y;
    s = stepSentinel(s, 0, false, true);
    expect(s.holding).toBe('donut');
    s.px = 1000;
    s = stepSentinel(s, 0, false, true);
    expect(s.won).toBe(true);
  });

  it('collects four grammys by jumping', () => {
    let s = emptyGrammyState();
    for (const t of s.trophies) {
      s.px = t.x;
      s.py = t.y;
      s = stepGrammy(s, 0, false);
    }
    expect(s.won).toBe(true);
  });

  it('hurts Face when Don Trumpet bribes him with cash', () => {
    let s = emptyBribeState();
    s.cash = [{ x: s.px, y: 480, vx: 0, vy: 0 }];
    s = stepBribe(s, 0, false, false);
    expect(s.hp).toBeLessThan(100);
    s.px = s.bossX;
    const boss = s.boss;
    s = stepBribe(s, 0, false, true);
    expect(s.boss).toBeLessThan(boss);
  });
});

describe('curiously strong night out', () => {
  it('picks up street junk by walking into it', () => {
    let s = emptyNightState();
    s.px = 210;
    s.py = 0;
    s = stepNight(s, { dir: 0 });
    expect(has(s, 'coin')).toBe(true);
    expect(s.banner).toMatch(/COIN/);
  });

  it('hides alley lipstick until a lamp exists', () => {
    let s = emptyNightState();
    const lip = s.pickups.find((p) => p.id === 'lipstick');
    expect(lip.dark).toBe(true);
    s.px = lip.x;
    s.py = lip.y - 508;
    s = stepNight(s, { take: true });
    expect(has(s, 'lipstick')).toBe(false);
    s.alleyLit = true;
    s = stepNight(s, { take: true });
    expect(has(s, 'lipstick')).toBe(true);
  });

  it('crafts lamp, hotshot, and wristband', () => {
    expect(tryRecipe(['glow', 'battery']).out).toBe('lamp');
    expect(tryRecipe(['lighter', 'cinnamon']).out).toBe('hotshot');
    expect(tryRecipe(['matches', 'cinnamon']).out).toBe('hotshot');
    expect(tryRecipe(['biscuit', 'gum', 'marker']).out).toBe('wristband');
    expect(tryRecipe(['biscuit', 'gum', 'marker']).line).toMatch(/RAVE BISCUIT/);
  });

  it('trades hotshot for gum and lipstick for marker, then Bolt points at the car', () => {
    let s = emptyNightState();
    s.inv = ['hotshot'];
    s.selected = 'hotshot';
    s.px = 1680;
    talkNearest(s);
    expect(has(s, 'gum')).toBe(true);
    s.inv = ['lipstick'];
    s.px = 2480;
    talkNearest(s);
    expect(has(s, 'marker')).toBe(true);
    s.inv = ['keys'];
    s.px = 3920;
    talkNearest(s);
    expect(s.banner).toMatch(/CAR/);
    expect(s.won).toBe(false);
  });

  it('grows on rave biscuit USE and maps bag taps', () => {
    let s = emptyNightState();
    s.inv = ['biscuit'];
    s.selected = 'biscuit';
    s = useSelected(s);
    expect(s.grown).toBe(true);
    expect(s.banner).toMatch(/PILLS THAT MAKE ME LARGER/);
    s = emptyNightState();
    s.inv = ['glow'];
    s = selectNightItem(s, 0);
    expect(s.selected).toBe('glow');
    expect(hitNightInv(BAG_X + 10, BAG_Y + 10)).toBe(0);
    const lip = s.pickups.find((p) => p.id === 'flyer');
    s = tapNight(s, lip.x, lip.y);
    expect(has(s, 'flyer')).toBe(true);
  });

  it('locks the car until keys, then ENTER CAR Y wins', () => {
    let s = emptyNightState();
    s.px = CAR.x;
    s = stepNight(s, { dir: 0 });
    expect(s.won).toBe(false);
    expect(s.banner).toMatch(/LOCKED/);
    s.inv = ['keys'];
    s = stepNight(s, { dir: 0 });
    expect(s.carPrompt).toBe(true);
    expect(s.banner).toMatch(/ENTER CAR/);
    s = stepNight(s, { no: true });
    expect(s.won).toBe(false);
    s.px = CAR.x;
    s = stepNight(s, { dir: 0 });
    s = stepNight(s, { yes: true });
    expect(s.won).toBe(true);
  });

  it('tins a dazed wild beat and warps through a pipe', () => {
    let s = emptyNightState();
    const mite = s.wilds.find((w) => w.id === 'ravebug');
    s.px = mite.x;
    mite.dazed = 40;
    s = stepNight(s, { take: true });
    expect(s.party).toContain('ravebug');
    expect(has(s, 'biscuit')).toBe(true);
    s.px = PIPES[0].x;
    s.onGround = true;
    s = stepNight(s, { take: true });
    expect(s.px).toBe(PIPES[0].to);
  });
});

describe('wild beats', () => {
  it('names original critters and fills a party', () => {
    expect(beatName('ravebug')).toBe('RAVEBUG');
    expect(addToParty([], 'glowbat')).toEqual(['glowbat']);
    expect(addToParty(['glowbat'], 'glowbat')).toEqual(['glowbat']);
  });

  it('catches only after a stomp wobble', () => {
    let enc = makeEncounter('spicegrub', 2);
    let r = resolveEncounter(enc, 'throw');
    expect(r.caught).toBe(null);
    r = resolveEncounter(r.enc, 'stomp');
    expect(r.enc.hp).toBe(1);
    r = resolveEncounter(r.enc, 'throw');
    expect(r.caught).toBe('spicegrub');
    r = resolveEncounter(makeEncounter('glowbat', 2), 'flee');
    expect(r.fled).toBe(true);
  });
});

describe('rave drive', () => {
  it('picks up speaker parts only while raving nearby', () => {
    let s = emptyDriveState();
    const part = s.parts[0];
    s.x = part.x;
    s.y = part.y;
    s = stepDrive(s, {});
    expect(s.got).toBe(0);
    s = stepDrive(s, { rave: true });
    expect(s.got).toBe(1);
    expect(s.parts[0].got).toBe(true);
  });

  it('wins after all five speaker parts', () => {
    let s = emptyDriveState();
    for (const p of s.parts) {
      s.x = p.x;
      s.y = p.y;
      s = stepDrive(s, { rave: true });
    }
    expect(s.got).toBe(PART_NEED);
    expect(s.won).toBe(true);
  });
});

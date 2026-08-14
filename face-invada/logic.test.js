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
} from './js/mystery.js';

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

  it('maps canvas taps to hotspots and inventory', () => {
    const s = emptyMysteryState();
    const desk = currentRoom(s).hotspots.find((h) => h.id === 'desk');
    expect(hitHotspot(s, desk.x + 10, desk.y + 10).id).toBe('desk');
    expect(hitInventoryIndex(INV_X + 10, INV_Y + 10)).toBe(0);
    const after = tapAt(s, desk.x + 10, desk.y + 10);
    expect(after.flags.deskLook).toBe(true);
  });
});

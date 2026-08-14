import { describe, it, expect } from 'vitest';
import {
  GAME_TITLE, HERO, LANES, makeChart, gradeDelta, findHittable,
  expireNotes, applyPlayerHit, applyMiss, applySuper, canSuper,
  winnerOf, emptyFightState,   beatAtFrame, comboMult, hitDamage, framesPerBeat,
  PERFECT_WINDOW, GOOD_WINDOW, SUPER_COST, CPU_HP, MAX_HP,
} from './js/logic.js';
import { FONT5, pixelTextWidth } from './js/pixel.js';

describe('title and hero', () => {
  it('is FACE INVADA\'s BEAT BOXING', () => {
    expect(GAME_TITLE).toBe("FACE INVADA'S BEAT BOXING");
    expect(HERO.name).toBe('FACE INVADA');
    expect(HERO.country).toBe('ITALY');
    expect(HERO.age).toBe(46);
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
      { beat: 5, lane: 'kick', hit: false },
    ];
    expect(findHittable(notes, 'punch', 4.05).beat).toBe(4);
    expect(findHittable(notes, 'kick', 4.05)).toBe(null);
  });

  it('expires late notes as misses', () => {
    const notes = [{ beat: 4, lane: 'punch', hit: false, grade: null }];
    const missed = expireNotes(notes, 5.0);
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
    expect(winnerOf(50, 50)).toBe(null);
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

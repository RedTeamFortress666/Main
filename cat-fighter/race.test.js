import { describe, it, expect } from 'vitest';
import { createRace, updateRace } from './js/race.js';
import { RACE_LAPS } from './js/logic.js';

const gas = { up: true, down: false, left: false, right: false, lp: false, rp: false };

describe('race session', () => {
  it('puts Yoko, Morlan, Baby, and Kittens on the grid with heads-out cars', () => {
    const race = createRace(true);
    expect(race.cars.map((c) => c.id)).toEqual(['yoko', 'morlan', 'baby', 'kittens']);
    expect(race.cars[0].human).toBe(true);
    expect(race.cars[1].human).toBe(false);
    expect(race.cars[0].car).toMatch(/Rolls/i);
    expect(race.cars[3].car).toMatch(/Beetle/i);
    expect(race.countdown).toBeGreaterThan(0);
  });

  it('lets Yoko pull away when holding gas after the lights', () => {
    const race = createRace(true);
    race.countdown = 0;
    const start = race.cars[0].s;
    for (let i = 0; i < 40; i++) updateRace(race, gas, {});
    expect(race.cars[0].s).toBeGreaterThan(start);
    expect(race.cars[0].speed).toBeGreaterThan(1);
    expect(RACE_LAPS).toBe(3);
  });
});

/**
 * WILD BEATS — original street critters. Chase, stomp, tin-catch.
 * Pokemon-like loop, not Pokemon IP.
 */

export const PARTY_MAX = 6;

export const BEATS = {
  mintmite: { name: 'MINTMITE', item: 'mint', color: '#7cff6b' },
  spicegrub: { name: 'SPICEGRUB', item: 'cinnamon', color: '#c44' },
  glowbat: { name: 'GLOWBAT', item: 'glow', color: '#9b6bff' },
  brewcrab: { name: 'BREWCRAB', item: 'coffee', color: '#6a4010' },
  glazemoth: { name: 'GLAZEMOTH', item: 'donut', color: '#e87880' },
  statuette: { name: 'STATUETTE', item: null, color: '#ffe566' },
  bassling: { name: 'BASSLING', item: 'battery', color: '#3df0ff' },
};

export const BEAT_LABEL = Object.fromEntries(
  Object.entries(BEATS).map(([id, b]) => [id, b.name]),
);

export function beatName(id) {
  return BEATS[id]?.name || String(id).toUpperCase();
}

export function inGrass(px, patches) {
  return patches.some((g) => px >= g.x && px <= g.x + g.w);
}

export function addToParty(party, id) {
  const next = party.slice();
  if (next.includes(id) || next.length >= PARTY_MAX) return next;
  next.push(id);
  return next;
}

export function hasBeat(party, id) {
  return party.includes(id);
}

export function makeEncounter(id, hp = 2) {
  return { id, hp, turns: 0 };
}

/** Jump weakens. TAKE/USE throws a tin. Catch when wobbling (hp <= 1). */
export function resolveEncounter(enc, action) {
  if (!enc) return { enc: null, caught: null, fled: false, line: '' };
  const next = { ...enc };
  if (action === 'flee') {
    return { enc: null, caught: null, fled: true, line: `${beatName(enc.id)} FLED. COWARD. LIKE YOUR EX.` };
  }
  if (action === 'stomp') {
    next.hp -= 1;
    next.turns += 1;
    if (next.hp <= 0) next.hp = 1;
    return { enc: next, caught: null, fled: false, line: `${beatName(enc.id)} WOBBLES. THROW THE TIN.` };
  }
  if (action === 'throw') {
    next.turns += 1;
    if (next.hp <= 1) {
      return { enc: null, caught: enc.id, fled: false, line: `CAUGHT ${beatName(enc.id)}. IT HATES YOU ALREADY.` };
    }
    if (next.turns >= 3) {
      return { enc: null, caught: null, fled: true, line: `${beatName(enc.id)} BROKE THE TIN AND LEFT.` };
    }
    return { enc: next, caught: null, fled: false, line: 'TIN BOUNCED OFF. STOMP IT FIRST.' };
  }
  return { enc: next, caught: null, fled: false, line: '' };
}

export function roam(w, minX, maxX) {
  let x = w.x + (w.vx || 0);
  let vx = w.vx || 0;
  let y = w.y + (w.vy || 0);
  if (x < minX || x > maxX) vx *= -1;
  if (w.hop) y = w.baseY + Math.sin((w.phase || 0) + x * 0.04) * w.hop;
  return { ...w, x, vx, y };
}

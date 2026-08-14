/**
 * FACE INVADA — 5 DAYS A STRANGER
 * Original motel-noir cases (homage to classic adventure structure, not a remake).
 * LOOK / TALK / TAKE / USE. Solve the day's mystery, then fight that day's enemy.
 */

export const VERBS = ['look', 'talk', 'take', 'use'];

export const ITEM_NAMES = {
  keycard: 'KEYCARD',
  mixtape: 'MIXTAPE',
  ring: 'RING',
  receipt: 'RECEIPT',
  silverblade: 'SILVER BLADE',
};

export const INV_X = 24;
export const INV_Y = 628;
export const INV_SLOT_W = 200;
export const INV_SLOT_H = 72;
export const INV_GAP = 12;

export const ENEMIES = {
  vinyl: {
    id: 'vinyl',
    name: 'THE BELLHOP',
    handle: 'VINYL',
    hp: 88,
    seed: 11,
    blurb: 'Desk clerk with a vinyl-scratch combo.',
  },
  kara: {
    id: 'kara',
    name: 'KARA DROP',
    handle: 'KARA',
    hp: 96,
    seed: 22,
    blurb: 'Housekeeper who hides tracks in the vents.',
  },
  widow: {
    id: 'widow',
    name: 'BASS WIDOW',
    handle: 'WIDOW',
    hp: 108,
    seed: 33,
    blurb: 'Guest whose grief hits in 808s.',
  },
  rivet: {
    id: 'rivet',
    name: 'MC RIVET',
    handle: 'RIVET',
    hp: 116,
    seed: 44,
    blurb: 'The silent witness on the tapes.',
  },
  stranger: {
    id: 'stranger',
    name: 'THE STRANGER',
    handle: 'STRANGER',
    hp: 132,
    seed: 55,
    blurb: 'The guest who never checked in.',
  },
};

export const DAYS = [
  {
    day: 1,
    title: 'LOCKED LOBBY',
    casefile: 'Night 1. The Neon Arms motel will not let you leave. The lobby door is dead.',
    enemyId: 'vinyl',
    rooms: ['lobby', 'hall', 'room101'],
  },
  {
    day: 2,
    title: 'MISSING MIXTAPE',
    casefile: 'Night 2. A stolen beat is looping through the vents. Find the tape before dawn.',
    enemyId: 'kara',
    rooms: ['hall', 'maid', 'vent'],
  },
  {
    day: 3,
    title: 'BLOODY BASSLINE',
    casefile: 'Night 3. The bathroom drain is singing. Someone left a ring in the trap.',
    enemyId: 'widow',
    rooms: ['room101', 'bath', 'hall'],
  },
  {
    day: 4,
    title: 'SILENT WITNESS',
    casefile: 'Night 4. The cameras never blink. A receipt in the fridge names the ghost.',
    enemyId: 'rivet',
    rooms: ['lobby', 'kitchen', 'cctv'],
  },
  {
    day: 5,
    title: 'THE STRANGER',
    casefile: 'Night 5. A diary, a closet, a sigil on the roof. Face the guest who never checked in.',
    enemyId: 'stranger',
    rooms: ['penthouse', 'closet', 'roof'],
  },
];

export const ROOMS = {
  lobby: {
    id: 'lobby',
    name: 'LOBBY',
    color: '#0b1020',
    hotspots: [
      { id: 'desk', label: 'FRONT DESK', x: 48, y: 280, w: 360, h: 170 },
      { id: 'bellhop', label: 'BELLHOP', x: 440, y: 180, w: 240, h: 280 },
      { id: 'door', label: 'EXIT DOORS', x: 820, y: 140, w: 400, h: 320 },
      { id: 'plant', label: 'DEAD PLANT', x: 48, y: 90, w: 200, h: 140 },
    ],
  },
  hall: {
    id: 'hall',
    name: 'HALLWAY',
    color: '#12081c',
    hotspots: [
      { id: 'ventgrate', label: 'VENT', x: 48, y: 90, w: 240, h: 100 },
      { id: 'roomdoor', label: 'ROOM 101', x: 360, y: 140, w: 200, h: 280 },
      { id: 'maid', label: 'MAID CART', x: 920, y: 170, w: 280, h: 250 },
      { id: 'carpet', label: 'CARPET STAIN', x: 80, y: 430, w: 1080, h: 90 },
    ],
  },
  room101: {
    id: 'room101',
    name: 'ROOM 101',
    color: '#0e1424',
    hotspots: [
      { id: 'window', label: 'WINDOW', x: 48, y: 90, w: 360, h: 140 },
      { id: 'bed', label: 'BED', x: 48, y: 280, w: 520, h: 200 },
      { id: 'radio', label: 'NIGHT RADIO', x: 600, y: 300, w: 220, h: 150 },
      { id: 'bathdoor', label: 'BATHROOM', x: 980, y: 140, w: 220, h: 320 },
    ],
  },
  maid: {
    id: 'maid',
    name: 'MAID CLOSET',
    color: '#1a0c14',
    hotspots: [
      { id: 'linens', label: 'LINENS', x: 48, y: 180, w: 300, h: 280 },
      { id: 'kara', label: 'KARA', x: 420, y: 150, w: 280, h: 310 },
      { id: 'deck', label: 'BOOMBOX', x: 780, y: 240, w: 400, h: 200 },
    ],
  },
  vent: {
    id: 'vent',
    name: 'AIR VENT',
    color: '#081410',
    hotspots: [
      { id: 'fan', label: 'FAN BLADES', x: 48, y: 90, w: 320, h: 150 },
      { id: 'tape', label: 'SHINY OBJECT', x: 460, y: 210, w: 360, h: 160 },
      { id: 'dust', label: 'DUST', x: 80, y: 400, w: 1120, h: 110 },
    ],
  },
  bath: {
    id: 'bath',
    name: 'BATHROOM',
    color: '#0c1018',
    hotspots: [
      { id: 'mirror', label: 'MIRROR', x: 360, y: 90, w: 560, h: 130 },
      { id: 'widow', label: 'GUEST', x: 48, y: 170, w: 260, h: 320 },
      { id: 'drain', label: 'DRAIN', x: 440, y: 340, w: 400, h: 160 },
    ],
  },
  kitchen: {
    id: 'kitchen',
    name: 'KITCHENETTE',
    color: '#141008',
    hotspots: [
      { id: 'fridge', label: 'MINI FRIDGE', x: 48, y: 150, w: 300, h: 340 },
      { id: 'sink', label: 'SINK', x: 420, y: 280, w: 360, h: 180 },
      { id: 'coffee', label: 'COFFEE POT', x: 860, y: 200, w: 320, h: 200 },
    ],
  },
  cctv: {
    id: 'cctv',
    name: 'CAMERA CLOSET',
    color: '#080c14',
    hotspots: [
      { id: 'monitors', label: 'MONITORS', x: 80, y: 90, w: 1120, h: 220 },
      { id: 'tapes', label: 'TAPE SHELF', x: 48, y: 340, w: 320, h: 160 },
      { id: 'rivet', label: 'FIGURE', x: 500, y: 330, w: 320, h: 180 },
    ],
  },
  penthouse: {
    id: 'penthouse',
    name: 'PENTHOUSE',
    color: '#100818',
    hotspots: [
      { id: 'sigil', label: 'NEON SIGIL', x: 420, y: 90, w: 440, h: 150 },
      { id: 'diary', label: 'DIARY', x: 48, y: 320, w: 320, h: 160 },
      { id: 'closetdoor', label: 'CLOSET', x: 960, y: 140, w: 240, h: 340 },
    ],
  },
  closet: {
    id: 'closet',
    name: 'WALK-IN',
    color: '#0c0c10',
    hotspots: [
      { id: 'coats', label: 'COATS', x: 48, y: 130, w: 320, h: 360 },
      { id: 'blade', label: 'SILVER CASE', x: 440, y: 220, w: 380, h: 180 },
      { id: 'shoes', label: 'SHOES', x: 880, y: 380, w: 320, h: 110 },
    ],
  },
  roof: {
    id: 'roof',
    name: 'ROOF',
    color: '#060810',
    hotspots: [
      { id: 'city', label: 'CITY', x: 40, y: 80, w: 1200, h: 110 },
      { id: 'stranger', label: 'SILHOUETTE', x: 48, y: 210, w: 260, h: 280 },
      { id: 'sigilbig', label: 'ROOF SIGIL', x: 360, y: 210, w: 640, h: 250 },
    ],
  },
};

export function emptyMysteryState() {
  return {
    day: 1,
    room: 'lobby',
    verb: 'look',
    inv: [],
    selected: null,
    flags: {},
    log: 'Night 1. Tap a hotspot. LOOK first.',
    solved: [false, false, false, false, false],
    beaten: [false, false, false, false, false],
  };
}

export function dayMeta(state) {
  return DAYS[state.day - 1];
}

export function enemyOf(state) {
  return ENEMIES[dayMeta(state).enemyId];
}

export function roomsOf(state) {
  return dayMeta(state).rooms;
}

export function currentRoom(state) {
  return ROOMS[state.room];
}

function clone(state) {
  return {
    ...state,
    inv: state.inv.slice(),
    flags: { ...state.flags },
    solved: state.solved.slice(),
    beaten: state.beaten.slice(),
  };
}

export function setVerb(state, verb) {
  const next = clone(state);
  next.verb = verb;
  next.log = `${verb.toUpperCase()} selected.`;
  return next;
}

export function cycleRoom(state, dir) {
  const rooms = roomsOf(state);
  const i = Math.max(0, rooms.indexOf(state.room));
  const nextI = (i + dir + rooms.length) % rooms.length;
  const next = clone(state);
  next.room = rooms[nextI];
  next.log = `Moved to ${ROOMS[next.room].name}.`;
  return next;
}

export function hasItem(state, id) {
  return state.inv.includes(id);
}

function give(state, id) {
  if (hasItem(state, id)) return false;
  state.inv.push(id);
  state.selected = id;
  state.verb = 'use';
  state.log = `Took ${ITEM_NAMES[id] || id.toUpperCase()}. USE a hotspot.`;
  return true;
}

function markSolved(state) {
  state.solved[state.day - 1] = true;
  const enemy = enemyOf(state);
  state.log = `CASE CLOSED. START to fight ${enemy.name}.`;
}

export function hitHotspot(state, x, y) {
  const room = currentRoom(state);
  for (let i = room.hotspots.length - 1; i >= 0; i--) {
    const h = room.hotspots[i];
    if (x >= h.x && x <= h.x + h.w && y >= h.y && y <= h.y + h.h) return h;
  }
  return null;
}

export function hitInventoryIndex(x, y) {
  if (y < INV_Y || y > INV_Y + INV_SLOT_H) return -1;
  const i = Math.floor((x - INV_X) / (INV_SLOT_W + INV_GAP));
  if (i < 0 || i > 4) return -1;
  const sx = INV_X + i * (INV_SLOT_W + INV_GAP);
  if (x < sx || x > sx + INV_SLOT_W) return -1;
  return i;
}

export function applyVerb(state, hotspotId) {
  const next = clone(state);
  const verb = next.verb;
  const day = next.day;
  const id = hotspotId;
  const flag = (k) => !!next.flags[k];
  const set = (k) => {
    next.flags[k] = true;
  };

  if (verb === 'look') {
    if (day === 1 && id === 'desk') {
      next.log = flag('deskLook')
        ? 'A KEYCARD still glints in the pigeonhole.'
        : 'Pigeonholes. A KEYCARD winks under a fake fern.';
      set('deskLook');
    } else if (day === 1 && id === 'door') {
      next.log = flag('d1solved')
        ? 'The doors hiss. The Bellhop blocks the lot.'
        : 'Magnetic lock. Needs a KEYCARD.';
    } else if (day === 1 && id === 'bellhop') {
      next.log = 'THE BELLHOP. Name tag: VINYL. He smiles like a scratch.';
    } else if (day === 1 && id === 'plant') {
      next.log = 'Plastic fern. Dust older than the neon.';
    } else if (day === 2 && id === 'maid') {
      next.log = 'A maid cart. Someone has been crying into the towels.';
    } else if (day === 2 && id === 'ventgrate') {
      next.log = 'The grate is loose. Something shiny ticks inside.';
      set('ventLook');
    } else if (day === 2 && id === 'kara') {
      next.log = 'KARA DROP. She will not meet your eyes.';
    } else if (day === 2 && id === 'tape') {
      next.log = flag('tapeTaken')
        ? 'Empty vent. Dust and a beat that will not die.'
        : 'A MIXTAPE, still spinning with no deck.';
      set('tapeLook');
    } else if (day === 2 && id === 'deck') {
      next.log = 'A boombox. Hungry for a MIXTAPE.';
    } else if (day === 3 && id === 'drain') {
      next.log = flag('ringTaken')
        ? 'The drain is quiet now.'
        : 'A wedding RING flashes in the trap. The bassline is wet.';
      set('drainLook');
    } else if (day === 3 && id === 'widow') {
      next.log = 'BASS WIDOW. She waits for a name you do not have yet.';
    } else if (day === 3 && id === 'mirror') {
      next.log = 'Your cap. Your shades. A second silhouette behind you — gone.';
    } else if (day === 4 && id === 'fridge') {
      next.log = flag('receiptTaken')
        ? 'Empty fridge. Condensation like static.'
        : 'A RECEIPT taped to a leftover carton. Time stamp: 3:33.';
      set('fridgeLook');
    } else if (day === 4 && id === 'monitors') {
      next.log = 'Every camera loops the same hallway. A figure never blinks.';
    } else if (day === 4 && id === 'rivet') {
      next.log = 'MC RIVET, frozen on the tape. He already knows you.';
    } else if (day === 5 && id === 'diary') {
      next.log = flag('diaryLook')
        ? 'Last page: THE STRANGER never checked in. He checked THROUGH.'
        : 'A DIARY. Ink still wet. "Five days. Then the roof."';
      set('diaryLook');
    } else if (day === 5 && id === 'blade') {
      next.log = flag('bladeTaken')
        ? 'The case is empty. Silver dust.'
        : 'A SILVER BLADE in a velvet case. It hums in 4/4.';
      set('bladeLook');
    } else if (day === 5 && (id === 'sigil' || id === 'sigilbig')) {
      next.log = flag('d5solved')
        ? 'The sigil is open. THE STRANGER steps through the beat.'
        : 'A neon pentagram of turntables. It wants a blade.';
    } else if (day === 5 && id === 'stranger') {
      next.log = 'A silhouette with no face. Not yet.';
    } else {
      const hs = currentRoom(next).hotspots.find((h) => h.id === id);
      next.log = hs ? `You LOOK at the ${hs.label}.` : 'Nothing to see.';
    }
    return next;
  }

  if (verb === 'talk') {
    if (day === 1 && id === 'bellhop') {
      next.log = flag('d1solved')
        ? '"You opened the door. Now you box, DJ."'
        : '"Checkout is never. Card stays at the desk."';
    } else if (day === 2 && id === 'kara') {
      next.log = 'Kara: "The MIXTAPE is in the vent. I did not steal it. I hid it."';
      set('karaTalk');
    } else if (day === 2 && id === 'maid') {
      next.log = 'The cart does not talk. The towels do: "vent."';
    } else if (day === 3 && id === 'widow') {
      next.log = flag('d3solved')
        ? '"You brought him back. Now drop with me."'
        : '"Bring the RING. Then we dance."';
    } else if (day === 4 && id === 'rivet') {
      next.log = 'The tape-figure mouths: "USE the RECEIPT on the monitors."';
    } else if (day === 5 && id === 'stranger') {
      next.log = 'No voice. Only a count-in.';
    } else {
      next.log = 'No one answers.';
    }
    return next;
  }

  if (verb === 'take') {
    if (day === 1 && id === 'desk') {
      if (!flag('deskLook')) next.log = 'LOOK first. Do not grab blind.';
      else if (!give(next, 'keycard')) next.log = 'You already have the KEYCARD.';
    } else if (day === 2 && (id === 'tape' || id === 'ventgrate')) {
      if (!(flag('tapeLook') || flag('ventLook') || flag('karaTalk'))) {
        next.log = 'LOOK or TALK first.';
      } else if (!give(next, 'mixtape')) {
        next.log = 'You already have the MIXTAPE.';
      } else {
        set('tapeTaken');
      }
    } else if (day === 3 && id === 'drain') {
      if (!flag('drainLook')) next.log = 'LOOK at the drain first.';
      else if (!give(next, 'ring')) next.log = 'You already have the RING.';
      else set('ringTaken');
    } else if (day === 4 && id === 'fridge') {
      if (!flag('fridgeLook')) next.log = 'LOOK in the fridge first.';
      else if (!give(next, 'receipt')) next.log = 'You already have the RECEIPT.';
      else set('receiptTaken');
    } else if (day === 5 && id === 'blade') {
      if (!flag('bladeLook') && !flag('diaryLook')) {
        next.log = 'LOOK at the diary or the case first.';
      } else if (!give(next, 'silverblade')) {
        next.log = 'You already have the SILVER BLADE.';
      } else {
        set('bladeTaken');
      }
    } else if (day === 5 && id === 'diary') {
      next.log = 'The diary is nailed to the table. LOOK only.';
    } else {
      next.log = 'You cannot take that.';
    }
    return next;
  }

  if (verb === 'use') {
    const item = next.selected;
    if (!item) {
      next.log = 'Select an item in the tray, then USE a hotspot.';
      return next;
    }
    if (day === 1 && item === 'keycard' && id === 'door') {
      set('d1solved');
      markSolved(next);
    } else if (day === 2 && item === 'mixtape' && id === 'deck') {
      set('d2solved');
      markSolved(next);
    } else if (day === 3 && item === 'ring' && id === 'widow') {
      set('d3solved');
      markSolved(next);
    } else if (day === 4 && item === 'receipt' && (id === 'monitors' || id === 'rivet')) {
      set('d4solved');
      markSolved(next);
    } else if (day === 5 && item === 'silverblade' && (id === 'sigil' || id === 'sigilbig')) {
      set('d5solved');
      markSolved(next);
    } else {
      next.log = 'That item does not work here.';
    }
    return next;
  }

  next.log = 'Nothing happens.';
  return next;
}

export function tapHotspot(state, x, y) {
  const hs = hitHotspot(state, x, y);
  if (!hs) {
    const next = clone(state);
    next.log = 'Tap a highlighted hotspot.';
    return next;
  }
  return applyVerb(state, hs.id);
}

export function tapInventory(state, index) {
  const next = clone(state);
  const id = next.inv[index];
  if (!id) return next;
  next.selected = next.selected === id ? null : id;
  next.verb = 'use';
  next.log = next.selected
    ? `Selected ${ITEM_NAMES[id] || id.toUpperCase()}. USE a hotspot.`
    : 'Item deselected.';
  return next;
}

export function tapAt(state, x, y) {
  const inv = hitInventoryIndex(x, y);
  if (inv >= 0) return tapInventory(state, inv);
  return tapHotspot(state, x, y);
}

export function canFight(state) {
  return !!state.solved[state.day - 1] && !state.beaten[state.day - 1];
}

export function allBeaten(state) {
  return state.beaten.every(Boolean);
}

export function markBeaten(state) {
  const next = clone(state);
  next.beaten[next.day - 1] = true;
  return next;
}

export function advanceDay(state) {
  const next = clone(state);
  if (next.day >= 5) return next;
  next.day += 1;
  next.room = DAYS[next.day - 1].rooms[0];
  next.verb = 'look';
  next.selected = null;
  next.log = `NIGHT ${next.day}. ${DAYS[next.day - 1].title}.`;
  return next;
}

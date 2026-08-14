/**
 * FACE INVADA — 5 DAYS A STRANGER
 * Original motel-noir cases. Walk the rooms, LOOK / TALK / TAKE / USE.
 * Close the case, then fight that night's enemy.
 */

export const VERBS = ['look', 'talk', 'take', 'use'];

export const ITEM_NAMES = {
  keycard: 'KEYCARD',
  vinyl: 'WAX DISC',
  mixtape: 'MIXTAPE',
  screwdriver: 'DRIVER',
  hanger: 'HANGER',
  ring: 'RING',
  pot: 'HOT POT',
  receipt: 'RECEIPT',
  silverblade: 'S.BLADE',
};

export const INV_X = 620;
export const INV_Y = 78;
export const INV_SLOT_W = 124;
export const INV_SLOT_H = 34;
export const INV_GAP = 6;

export const REACH = 150;
export const WALK_SPEED = 8;
export const PX_MIN = 70;
export const PX_MAX = 1210;
export const ROOM_Y0 = 120;
export const ROOM_Y1 = 540;

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
    casefile: 'Night 1. Vinyl guards the desk. The doors want a PIN. Something in the hall scratches.',
    enemyId: 'vinyl',
    rooms: ['lobby', 'hall', 'room101'],
  },
  {
    day: 2,
    title: 'MISSING MIXTAPE',
    casefile: 'Night 2. A stolen beat loops the vents. Kara will talk if you ask. The grate is screwed shut.',
    enemyId: 'kara',
    rooms: ['hall', 'maid', 'vent'],
  },
  {
    day: 3,
    title: 'BLOODY BASSLINE',
    casefile: 'Night 3. A ring is stuck in the drain. Widow will not take nameless gold. Steam on the mirror.',
    enemyId: 'widow',
    rooms: ['room101', 'bath', 'hall'],
  },
  {
    day: 4,
    title: 'SILENT WITNESS',
    casefile: 'Night 4. The receipt is frozen to the fridge. Heat it. The cameras want a timestamp.',
    enemyId: 'rivet',
    rooms: ['lobby', 'kitchen', 'cctv'],
  },
  {
    day: 5,
    title: 'THE STRANGER',
    casefile: 'Night 5. Read the diary. The closet case wants a word. The roof sigil wants steel spoken aloud.',
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
      { id: 'plant', label: 'DEAD PLANT', x: 48, y: 140, w: 200, h: 110 },
      { id: 'desk', label: 'FRONT DESK', x: 48, y: 300, w: 360, h: 160 },
      { id: 'bellhop', label: 'BELLHOP', x: 440, y: 200, w: 220, h: 260 },
      { id: 'door', label: 'EXIT DOORS', x: 820, y: 170, w: 400, h: 280 },
    ],
  },
  hall: {
    id: 'hall',
    name: 'HALLWAY',
    color: '#12081c',
    hotspots: [
      { id: 'ventgrate', label: 'VENT', x: 48, y: 140, w: 240, h: 90 },
      { id: 'roomdoor', label: 'ROOM 101', x: 360, y: 180, w: 200, h: 250 },
      { id: 'maid', label: 'MAID CART', x: 920, y: 200, w: 280, h: 230 },
      { id: 'carpet', label: 'CARPET STAIN', x: 80, y: 450, w: 1080, h: 80 },
    ],
  },
  room101: {
    id: 'room101',
    name: 'ROOM 101',
    color: '#0e1424',
    hotspots: [
      { id: 'window', label: 'WINDOW', x: 48, y: 140, w: 360, h: 120 },
      { id: 'bed', label: 'BED', x: 48, y: 300, w: 520, h: 180 },
      { id: 'radio', label: 'NIGHT RADIO', x: 600, y: 320, w: 220, h: 140 },
      { id: 'bathdoor', label: 'BATHROOM', x: 980, y: 170, w: 220, h: 280 },
    ],
  },
  maid: {
    id: 'maid',
    name: 'MAID CLOSET',
    color: '#1a0c14',
    hotspots: [
      { id: 'linens', label: 'LINENS', x: 48, y: 200, w: 300, h: 250 },
      { id: 'kara', label: 'KARA', x: 420, y: 180, w: 280, h: 280 },
      { id: 'deck', label: 'BOOMBOX', x: 780, y: 260, w: 400, h: 180 },
    ],
  },
  vent: {
    id: 'vent',
    name: 'AIR VENT',
    color: '#081410',
    hotspots: [
      { id: 'fan', label: 'FAN BLADES', x: 48, y: 140, w: 320, h: 130 },
      { id: 'tape', label: 'SHINY OBJECT', x: 460, y: 230, w: 360, h: 150 },
      { id: 'dust', label: 'DUST', x: 80, y: 420, w: 1120, h: 100 },
    ],
  },
  bath: {
    id: 'bath',
    name: 'BATHROOM',
    color: '#0c1018',
    hotspots: [
      { id: 'mirror', label: 'MIRROR', x: 360, y: 140, w: 560, h: 110 },
      { id: 'widow', label: 'GUEST', x: 48, y: 190, w: 260, h: 280 },
      { id: 'drain', label: 'DRAIN', x: 440, y: 350, w: 400, h: 140 },
    ],
  },
  kitchen: {
    id: 'kitchen',
    name: 'KITCHENETTE',
    color: '#141008',
    hotspots: [
      { id: 'fridge', label: 'MINI FRIDGE', x: 48, y: 170, w: 300, h: 300 },
      { id: 'sink', label: 'SINK', x: 420, y: 300, w: 360, h: 160 },
      { id: 'coffee', label: 'COFFEE POT', x: 860, y: 220, w: 320, h: 180 },
    ],
  },
  cctv: {
    id: 'cctv',
    name: 'CAMERA CLOSET',
    color: '#080c14',
    hotspots: [
      { id: 'monitors', label: 'MONITORS', x: 80, y: 140, w: 1120, h: 180 },
      { id: 'tapes', label: 'TAPE SHELF', x: 48, y: 350, w: 320, h: 140 },
      { id: 'rivet', label: 'FIGURE', x: 500, y: 340, w: 320, h: 160 },
    ],
  },
  penthouse: {
    id: 'penthouse',
    name: 'PENTHOUSE',
    color: '#100818',
    hotspots: [
      { id: 'sigil', label: 'NEON SIGIL', x: 420, y: 140, w: 440, h: 130 },
      { id: 'diary', label: 'DIARY', x: 48, y: 330, w: 320, h: 150 },
      { id: 'closetdoor', label: 'CLOSET', x: 960, y: 170, w: 240, h: 300 },
    ],
  },
  closet: {
    id: 'closet',
    name: 'WALK-IN',
    color: '#0c0c10',
    hotspots: [
      { id: 'coats', label: 'COATS', x: 48, y: 160, w: 320, h: 320 },
      { id: 'blade', label: 'SILVER CASE', x: 440, y: 240, w: 380, h: 160 },
      { id: 'shoes', label: 'SHOES', x: 880, y: 390, w: 320, h: 100 },
    ],
  },
  roof: {
    id: 'roof',
    name: 'ROOF',
    color: '#060810',
    hotspots: [
      { id: 'city', label: 'CITY', x: 40, y: 130, w: 1200, h: 90 },
      { id: 'stranger', label: 'SILHOUETTE', x: 48, y: 230, w: 260, h: 250 },
      { id: 'sigilbig', label: 'ROOF SIGIL', x: 360, y: 230, w: 640, h: 220 },
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
    clues: [],
    log: 'Walk with LEFT/RIGHT. DOWN to act. LOOK the plant.',
    px: 260,
    facing: 1,
    walkTarget: null,
    pendingHotspot: null,
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
    clues: (state.clues || []).slice(),
    solved: state.solved.slice(),
    beaten: state.beaten.slice(),
  };
}

function addClue(state, text) {
  if (!state.clues.includes(text)) state.clues.push(text);
}

export function setVerb(state, verb) {
  const next = clone(state);
  next.verb = verb;
  return next;
}

export function cycleRoom(state, dir) {
  const rooms = roomsOf(state);
  const i = Math.max(0, rooms.indexOf(state.room));
  const nextI = (i + dir + rooms.length) % rooms.length;
  const next = clone(state);
  next.room = rooms[nextI];
  next.walkTarget = null;
  next.pendingHotspot = null;
  next.log = `Walked into ${ROOMS[next.room].name}.`;
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
  state.log = `Took ${ITEM_NAMES[id] || id.toUpperCase()}. Walk to where it belongs.`;
  return true;
}

function markSolved(state) {
  state.solved[state.day - 1] = true;
  const enemy = enemyOf(state);
  state.log = `CASE CLOSED. START fights ${enemy.name}.`;
  addClue(state, `Night ${state.day} closed.`);
}

export function hotspotCX(h) {
  return h.x + h.w / 2;
}

export function inRangeOf(state, h) {
  return Math.abs((state.px ?? 260) - hotspotCX(h)) <= REACH;
}

export function stepWalk(state, dir) {
  const next = clone(state);
  let px = next.px ?? 260;
  if (dir) {
    next.walkTarget = null;
    next.pendingHotspot = null;
    px += dir * WALK_SPEED;
    next.facing = dir;
  } else if (next.walkTarget != null) {
    const t = next.walkTarget;
    const d = t - px;
    if (Math.abs(d) <= WALK_SPEED) {
      px = t;
      next.px = px;
      next.walkTarget = null;
      const pending = next.pendingHotspot;
      next.pendingHotspot = null;
      if (pending) return applyVerb(next, pending);
      return next;
    }
    next.facing = d > 0 ? 1 : -1;
    px += Math.sign(d) * WALK_SPEED;
  } else {
    return next;
  }
  if (px < PX_MIN) {
    const moved = cycleRoom(next, -1);
    moved.px = PX_MAX - 50;
    moved.facing = -1;
    return moved;
  }
  if (px > PX_MAX) {
    const moved = cycleRoom(next, 1);
    moved.px = PX_MIN + 50;
    moved.facing = 1;
    return moved;
  }
  next.px = px;
  return next;
}

export function interactNearest(state) {
  const room = currentRoom(state);
  let best = null;
  let bestD = 9999;
  const px = state.px ?? 260;
  for (const h of room.hotspots) {
    const d = Math.abs(px - hotspotCX(h));
    if (d < bestD) {
      best = h;
      bestD = d;
    }
  }
  if (!best) return state;
  if (bestD <= REACH) return applyVerb(state, best.id);
  const next = clone(state);
  next.walkTarget = hotspotCX(best);
  next.pendingHotspot = best.id;
  next.log = `Walking to ${best.label}.`;
  return next;
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
    if (day === 1 && id === 'plant') {
      next.log = 'Scrap in the dirt: WAX IN THE HALL. DOOR PIN 333.';
      set('plantLook');
      addClue(next, 'PIN 333. Wax in the hall.');
    } else if (day === 1 && id === 'desk') {
      next.log = flag('vinylBusy')
        ? 'Slot 3 is free. A KEYCARD sits in the dark.'
        : 'Pigeonholes. Slot 3 has a KEYCARD. Vinyl\'s hand is on it.';
      set('deskLook');
    } else if (day === 1 && id === 'door') {
      next.log = flag('d1solved')
        ? 'Doors hiss. Vinyl wants a bout in the lot.'
        : 'Magnetic lock plus a 3-digit pad. PIN unknown? Check the plant.';
    } else if (day === 1 && id === 'bellhop') {
      next.log = flag('vinylBusy')
        ? 'Headphones on. He is lost in a scratch loop.'
        : 'Name tag: VINYL. "Bring me wax. Then we talk."';
    } else if (day === 1 && id === 'carpet') {
      next.log = flag('vinylTaken')
        ? 'A pale ring in the runner where wax sat.'
        : 'A 12-inch WAX DISC under the runner. Still warm.';
      set('carpetLook');
    } else if (day === 2 && id === 'kara') {
      next.log = 'Kara will not meet your eyes. TALK to her.';
    } else if (day === 2 && id === 'linens') {
      next.log = 'A rusted SCREWDRIVER in the pillowcases.';
      set('linensLook');
    } else if (day === 2 && id === 'ventgrate') {
      next.log = flag('grateOpen')
        ? 'Grate hangs open. The vent yawns.'
        : 'Four screws. You need a driver.';
      set('ventLook');
    } else if (day === 2 && id === 'tape') {
      next.log = flag('tapeTaken')
        ? 'Empty duct. The beat still ticks in the metal.'
        : flag('grateOpen')
          ? 'A MIXTAPE taped to the duct wall. Kara hid it well.'
          : 'Something shiny behind screws.';
      set('tapeLook');
    } else if (day === 2 && id === 'deck') {
      next.log = 'Boombox. Hungry. The label says "PLAY ME LAST."';
    } else if (day === 3 && id === 'mirror') {
      next.log = 'Steam letters: MARCO. They fade as you breathe.';
      set('mirrorLook');
      addClue(next, 'The name is MARCO.');
    } else if (day === 3 && id === 'bed') {
      next.log = 'A wire HANGER on the bedpost. Good hook.';
      set('bedLook');
    } else if (day === 3 && id === 'drain') {
      next.log = flag('ringTaken')
        ? 'The drain is quiet.'
        : 'A wedding RING flashes too deep to grab.';
      set('drainLook');
    } else if (day === 3 && id === 'widow') {
      next.log = 'BASS WIDOW. She waits for a name, then gold.';
    } else if (day === 4 && id === 'coffee') {
      next.log = 'A HOT POT still bubbling. Good for ice.';
      set('coffeeLook');
    } else if (day === 4 && id === 'fridge') {
      next.log = flag('receiptTaken')
        ? 'Empty fridge. Condensation like static.'
        : flag('fridgeThaw')
          ? 'Ice gone. A RECEIPT, timestamp 3:33.'
          : 'A RECEIPT frozen to a carton. Your fingers slip.';
      set('fridgeLook');
    } else if (day === 4 && id === 'monitors') {
      next.log = 'Every camera loops the same hall. Needs a timestamp.';
    } else if (day === 4 && id === 'rivet') {
      next.log = 'MC RIVET frozen on tape. He already knows you.';
    } else if (day === 5 && id === 'diary') {
      next.log = 'Last page: THE STRANGER never checked in. Password: THROUGH. Roof wants steel spoken.';
      set('diaryLook');
      addClue(next, 'Password THROUGH. Speak on the roof.');
    } else if (day === 5 && id === 'blade') {
      next.log = flag('bladeTaken')
        ? 'The case is empty. Silver dust.'
        : flag('diaryLook')
          ? 'The lock accepts THROUGH. A SILVER BLADE hums in 4/4.'
          : 'A locked silver case. It wants a word from a diary.';
      set('bladeLook');
    } else if (day === 5 && (id === 'sigil' || id === 'sigilbig')) {
      next.log = flag('d5solved')
        ? 'The sigil is open. THE STRANGER steps through the beat.'
        : 'Turntables in a pentagram. It wants a blade AND a name spoken.';
    } else if (day === 5 && id === 'stranger') {
      next.log = 'No face. If you TALK, the count-in starts.';
    } else {
      const hs = currentRoom(next).hotspots.find((h) => h.id === id);
      next.log = hs ? `You LOOK at the ${hs.label}.` : 'Nothing to see.';
    }
    return next;
  }

  if (verb === 'talk') {
    if (day === 1 && id === 'bellhop') {
      next.log = flag('vinylBusy')
        ? '"Nice wax. Door is your problem now, DJ."'
        : '"Checkout is never. Bring me something that scratches."';
      set('vinylTalk');
    } else if (day === 2 && id === 'kara') {
      next.log = 'Kara: "Tape is in the vent. Grate is screwed. Driver is in the linens. Play it last."';
      set('karaTalk');
      addClue(next, 'Driver in linens. Tape in the vent.');
    } else if (day === 2 && id === 'maid') {
      next.log = 'The towels whisper: "vent."';
    } else if (day === 3 && id === 'widow') {
      next.log = flag('d3solved')
        ? '"Marco is home. Now we drop."'
        : '"Hook the RING. Say the name on the mirror. Then we dance."';
    } else if (day === 4 && id === 'rivet') {
      next.log = 'The tape-figure mouths: "Heat the fridge. Stamp the monitors."';
    } else if (day === 5 && id === 'stranger') {
      next.log = 'You speak THROUGH. The silhouette nods once.';
      set('nameSpoken');
      addClue(next, 'You spoke THROUGH.');
    } else if (day === 5 && (id === 'sigil' || id === 'sigilbig')) {
      next.log = 'You count in. The sigil wants steel in your hand.';
      set('nameSpoken');
    } else {
      next.log = 'No one answers.';
    }
    return next;
  }

  if (verb === 'take') {
    if (day === 1 && id === 'carpet') {
      if (!flag('carpetLook')) next.log = 'LOOK at the stain first.';
      else if (!give(next, 'vinyl')) next.log = 'You already have the WAX DISC.';
      else set('vinylTaken');
    } else if (day === 1 && id === 'desk') {
      if (!flag('deskLook')) next.log = 'LOOK the desk first.';
      else if (!flag('vinylBusy')) next.log = 'Vinyl slaps your wrist. Distract him with wax.';
      else if (!give(next, 'keycard')) next.log = 'You already have the KEYCARD.';
    } else if (day === 2 && id === 'linens') {
      if (!flag('linensLook') && !flag('karaTalk')) next.log = 'LOOK the linens or TALK to Kara.';
      else if (!give(next, 'screwdriver')) next.log = 'You already have the DRIVER.';
    } else if (day === 2 && (id === 'tape' || id === 'ventgrate')) {
      if (!flag('grateOpen')) next.log = 'The grate is screwed shut.';
      else if (!give(next, 'mixtape')) next.log = 'You already have the MIXTAPE.';
      else set('tapeTaken');
    } else if (day === 3 && id === 'bed') {
      if (!flag('bedLook')) next.log = 'LOOK at the bed first.';
      else if (!give(next, 'hanger')) next.log = 'You already have the HANGER.';
    } else if (day === 3 && id === 'drain') {
      if (!flag('drainHooked')) next.log = 'Too deep. USE a hanger.';
      else if (!give(next, 'ring')) next.log = 'You already have the RING.';
      else set('ringTaken');
    } else if (day === 4 && id === 'coffee') {
      if (!flag('coffeeLook')) next.log = 'LOOK at the pot first.';
      else if (!give(next, 'pot')) next.log = 'You already have the HOT POT.';
    } else if (day === 4 && id === 'fridge') {
      if (!flag('fridgeLook')) next.log = 'LOOK in the fridge first.';
      else if (!flag('fridgeThaw')) next.log = 'Frozen solid. USE heat.';
      else if (!give(next, 'receipt')) next.log = 'You already have the RECEIPT.';
      else set('receiptTaken');
    } else if (day === 5 && id === 'blade') {
      if (!flag('diaryLook')) next.log = 'The case wants a word. READ the diary.';
      else if (!give(next, 'silverblade')) next.log = 'You already have the SILVER BLADE.';
      else set('bladeTaken');
    } else if (day === 5 && id === 'diary') {
      next.log = 'Nailed down. LOOK only.';
    } else {
      next.log = 'You cannot take that.';
    }
    return next;
  }

  if (verb === 'use') {
    const item = next.selected;
    if (!item) {
      next.log = 'Select an item up top, then USE on a hotspot.';
      return next;
    }
    if (day === 1 && item === 'vinyl' && id === 'bellhop') {
      set('vinylBusy');
      next.log = 'Vinyl drops the needle. Headphones on. Desk is clear.';
      addClue(next, 'Vinyl is busy.');
    } else if (day === 1 && item === 'keycard' && id === 'door') {
      if (!flag('plantLook')) next.log = 'Pad wants 3 digits. The plant had a scrap.';
      else {
        set('d1solved');
        markSolved(next);
      }
    } else if (day === 2 && item === 'screwdriver' && id === 'ventgrate') {
      set('grateOpen');
      next.log = 'Screws drop. The vent is open. Walk in for the tape.';
      addClue(next, 'Vent is open.');
    } else if (day === 2 && item === 'mixtape' && id === 'deck') {
      set('d2solved');
      markSolved(next);
    } else if (day === 3 && item === 'hanger' && id === 'drain') {
      set('drainHooked');
      if (!give(next, 'ring')) next.log = 'The RING is hooked. TAKE it.';
      else {
        set('ringTaken');
        next.log = 'Hooked the RING. Widow is waiting.';
      }
    } else if (day === 3 && item === 'ring' && id === 'widow') {
      if (!flag('mirrorLook')) next.log = 'Widow: "Whose name is on this gold?" Check the mirror.';
      else {
        set('d3solved');
        markSolved(next);
      }
    } else if (day === 4 && item === 'pot' && id === 'fridge') {
      set('fridgeThaw');
      next.log = 'Ice screams. The RECEIPT peels free. TAKE it.';
      addClue(next, 'Fridge thawed. Timestamp 3:33.');
    } else if (day === 4 && item === 'receipt' && (id === 'monitors' || id === 'rivet')) {
      set('d4solved');
      markSolved(next);
    } else if (day === 5 && item === 'silverblade' && (id === 'sigil' || id === 'sigilbig')) {
      if (!flag('nameSpoken')) next.log = 'The sigil wants the name spoken. TALK to the silhouette.';
      else {
        set('d5solved');
        markSolved(next);
      }
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
    if (y >= ROOM_Y0 && y <= ROOM_Y1) {
      const next = clone(state);
      next.walkTarget = Math.max(PX_MIN, Math.min(PX_MAX, x));
      next.pendingHotspot = null;
      return next;
    }
    return state;
  }
  if (inRangeOf(state, hs)) return applyVerb(state, hs.id);
  const next = clone(state);
  next.walkTarget = hotspotCX(hs);
  next.pendingHotspot = hs.id;
  next.log = `Walking to ${hs.label}.`;
  return next;
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
  next.px = 260;
  next.facing = 1;
  next.walkTarget = null;
  next.pendingHotspot = null;
  next.log = `NIGHT ${next.day}. ${DAYS[next.day - 1].title}. Walk. LOOK.`;
  return next;
}

import {
  ATTACKS, GROUND_Y, MAX_HP, MAX_METER, CANVAS_W,
  applyDamage, applyHeal, spendMeter,
  detectSpecial, isBlocked, clamp,
} from './logic.js';
import { MotionBuffer } from './input.js';

const WALK = 4.35;
const JUMP_V = -16.4;
const GRAVITY = 0.78;
const FRICTION = 0.82;

export class Projectile {
  constructor({ x, y, vx, owner, kind }) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.owner = owner;
    this.kind = kind;
    this.w = kind === 'tuna' ? 36 : 70;
    this.h = kind === 'tuna' ? 28 : 70;
    this.life = kind === 'tuna' ? 90 : 18;
    this.dead = false;
    this.hasHit = false;
  }

  get hitbox() {
    return { x: this.x - this.w / 2, y: this.y - this.h / 2, w: this.w, h: this.h };
  }

  update() {
    this.x += this.vx;
    this.life -= 1;
    if (this.kind === 'meow') {
      this.w += 6;
      this.h += 3;
    }
    if (this.life <= 0 || this.x < -40 || this.x > CANVAS_W + 40) this.dead = true;
  }
}

export class Fighter {
  constructor({ id, side, x, characterId }) {
    this.id = id;
    this.side = side;
    this.characterId = characterId;
    this.x = x;
    this.y = GROUND_Y;
    this.vx = 0;
    this.vy = 0;
    this.facing = side === 'p1' ? 1 : -1;
    this.hp = MAX_HP;
    this.meter = 0;
    this.revivesUsed = 0;
    this.state = 'idle';
    this.stateTime = 0;
    this.animTime = Math.random() * 40;
    this.attack = null;
    this.attackFrame = 0;
    this.hasHit = 0;
    this.comboHits = 0;
    this.hitstun = 0;
    this.blockstun = 0;
    this.hitFlash = 0;
    this.invuln = 0;
    this.motion = new MotionBuffer();
    this.busy = false;
    this.attacking = false;
    this.attackType = 'mid';
    this.crouching = false;
    this.airborne = false;
    this.blocking = false;
    this.wonRound = false;
    this.lastSpecial = '';
    this.shake = 0;
  }

  resetRound(x) {
    this.x = x;
    this.y = GROUND_Y;
    this.vx = 0;
    this.vy = 0;
    this.hp = MAX_HP;
    this.state = 'idle';
    this.stateTime = 0;
    this.attack = null;
    this.attackFrame = 0;
    this.hasHit = 0;
    this.comboHits = 0;
    this.hitstun = 0;
    this.blockstun = 0;
    this.invuln = 0;
    this.motion.clear();
    this.busy = false;
    this.attacking = false;
    this.crouching = false;
    this.airborne = false;
    this.blocking = false;
    this.wonRound = false;
    this.lastSpecial = '';
  }

  get hurtbox() {
    const crouch = this.crouching && !this.airborne;
    const h = crouch ? 78 : this.airborne ? 100 : 132;
    const w = 58;
    return {
      x: this.x - w / 2,
      y: this.y - h,
      w,
      h,
    };
  }

  currentHitbox() {
    if (!this.attack || !this.attacking) return null;
    const a = this.attack;
    const total = a.startup + a.active + a.recovery;
    const f = this.attackFrame;
    if (f < a.startup || f >= a.startup + a.active) return null;
    if (a.multi) {
      const local = f - a.startup;
      if (local % a.multiGap >= 2) return null;
    }
    const hb = a.hitbox;
    const x = this.facing >= 0 ? this.x + hb.x : this.x - hb.x - hb.w;
    return { x, y: this.y + hb.y, w: hb.w, h: hb.h };
  }

  face(opponent) {
    if (this.attacking || this.hitstun > 0 || this.blockstun > 0) return;
    if (['knockdown', 'getup', 'drink', 'eat', 'ko', 'win', 'lose'].includes(this.state)) return;
    this.facing = opponent.x >= this.x ? 1 : -1;
  }

  startAttack(id) {
    const a = ATTACKS[id];
    if (!a) return;
    this.attack = a;
    this.attackFrame = 0;
    this.hasHit = 0;
    this.attacking = true;
    this.attackType = a.type;
    this.state = a.super ? 'super' : (a.projectile || a.dive || a.uppercut || a.multi ? 'special' : 'attack');
    this.stateTime = 0;
    this.lastSpecial = a.name;
    this.crouching = id.startsWith('c') && !this.airborne;
    if (a.dive) {
      this.vy = -13;
      this.vx = this.facing * 6.5;
    }
    if (a.uppercut) {
      this.vy = -14;
      this.vx = this.facing * 2.2;
    }
  }

  pickNormals(snap) {
    if (!snap.attackId) return null;
    if (this.airborne) {
      if (snap.attackId === 'lp' || snap.attackId === 'lk') return 'jlp';
      if (snap.attackId === 'mk' || snap.attackId === 'mp') return 'jmk';
      return 'jhp';
    }
    if (snap.down) {
      if (snap.attackId === 'lp' || snap.attackId === 'lk') return 'clp';
      if (snap.attackId === 'mp' || snap.attackId === 'mk') return 'cmk';
      return 'chk';
    }
    return snap.attackId;
  }

  tryAttack(snap) {
    if (!snap.attackId && !snap.buttonClass) return false;
    if (this.attacking || this.hitstun || this.blockstun) return false;
    if (['knockdown', 'getup', 'drink', 'eat', 'ko'].includes(this.state)) return false;

    const cls = snap.buttonClass || (['lk', 'mk', 'hk', 'mp'].includes(snap.attackId) ? 'k' : 'p');
    const specialId = detectSpecial(this.motion.dirs, cls, this.meter, this.characterId);
    if (specialId) {
      const def = ATTACKS[specialId];
      if (def?.super) {
        const spent = spendMeter(this.meter, MAX_METER);
        if (!spent.ok) {
          // fall through to a special-strength heavy
        } else {
          this.meter = spent.meter;
          this.startAttack(specialId);
          this.motion.clear();
          return 'super';
        }
      } else {
        this.startAttack(specialId);
        this.motion.clear();
        return 'special';
      }
    }
    const normal = this.pickNormals(snap);
    if (normal) {
      this.startAttack(normal);
      return 'normal';
    }
    return false;
  }

  takeHit(atk, attackerFacing, blocked) {
    if (this.invuln > 0) return { blocked: true, dmg: 0, ko: false };
    this.comboHits = blocked ? 0 : this.comboHits + 1;
    const raw = blocked ? atk.chip : atk.damage;
    const { hp, dealt } = applyDamage(this.hp, raw, blocked ? 1 : this.comboHits);
    this.hp = hp;
    this.hitFlash = blocked ? 4 : 8;
    this.shake = 6;
    this.vx = attackerFacing * (blocked ? atk.knockback * 0.35 : atk.knockback);
    if (!blocked && atk.launch) this.vy = -atk.launch;
    if (blocked) {
      this.blockstun = atk.blockstun;
      this.state = 'block';
      this.attacking = false;
      this.attack = null;
    } else if (atk.knockdown || this.hp <= 0) {
      this.hitstun = 0;
      this.state = this.hp <= 0 ? 'ko' : 'knockdown';
      this.stateTime = 0;
      this.attacking = false;
      this.attack = null;
      this.vy = Math.min(this.vy, -6);
    } else {
      this.hitstun = atk.hitstun;
      this.state = 'hit';
      this.attacking = false;
      this.attack = null;
    }
    this.stateTime = 0;
    return { blocked, dmg: dealt, ko: this.hp <= 0 };
  }

  heal(amount) {
    const r = applyHeal(this.hp, amount);
    this.hp = r.hp;
    return r.healed;
  }

  update(snap, opponent, world) {
    this.animTime += 1;
    this.stateTime += 1;
    if (this.hitFlash > 0) this.hitFlash -= 1;
    if (this.shake > 0) this.shake -= 1;
    if (this.invuln > 0) this.invuln -= 1;

    this.motion.push(snap.dir);
    this.face(opponent);

    const locked = ['drink', 'eat', 'ko', 'win', 'lose', 'intro'].includes(this.state)
      || world.frozen;
    this.busy = locked || this.attacking || this.hitstun > 0 || this.blockstun > 0
      || this.state === 'knockdown' || this.state === 'getup';

    if (locked) {
      this._physics(world);
      return;
    }

    if (this.hitstun > 0) {
      this.hitstun -= 1;
      if (this.hitstun <= 0 && this.state === 'hit') this.state = this.airborne ? 'jump' : 'idle';
      this._physics(world);
      return;
    }
    this.comboHits = 0;

    if (this.blockstun > 0) {
      this.blockstun -= 1;
      this.blocking = true;
      if (this.blockstun <= 0) this.state = 'idle';
      this._physics(world);
      return;
    }

    if (this.state === 'knockdown') {
      if (this.stateTime > 36 && !this.airborne) {
        this.state = 'getup';
        this.stateTime = 0;
        this.invuln = 18;
      }
      this._physics(world);
      return;
    }
    if (this.state === 'getup') {
      if (this.stateTime > 16) this.state = 'idle';
      this._physics(world);
      return;
    }

    if (this.attacking && this.attack) {
      this.attackFrame += 1;
      const a = this.attack;
      if (a.invuln && this.attackFrame >= a.invuln[0] && this.attackFrame <= a.invuln[1]) {
        this.invuln = 2;
      }
      if (a.advance && this.attackFrame >= a.startup && this.attackFrame < a.startup + a.active) {
        this.x += this.facing * a.advance;
      }
      if (a.projectile && this.attackFrame === a.startup && !this._shot) {
        this._shot = true;
        world.spawnProjectile(this, a.projectile);
      }
      const total = a.startup + a.active + a.recovery;
      if (this.attackFrame >= total) {
        this.attacking = false;
        this.attack = null;
        this._shot = false;
        this.state = this.airborne ? 'jump' : 'idle';
      }
      this._physics(world);
      return;
    }
    this._shot = false;

    const started = this.tryAttack(snap);
    if (started) {
      this._physics(world);
      return;
    }

    this.blocking = false;
    this.crouching = false;

    if (!this.airborne && snap.up) {
      this.vy = JUMP_V;
      this.airborne = true;
      this.state = 'jump';
      if (snap.left) this.vx = -WALK * 1.05;
      if (snap.right) this.vx = WALK * 1.05;
      this._physics(world);
      return;
    }

    if (!this.airborne && snap.down) {
      this.crouching = true;
      this.state = 'crouch';
      this.blocking = snap.block;
      this.vx *= 0.5;
      this._physics(world);
      return;
    }

    if (snap.block && !this.airborne) {
      this.blocking = true;
      this.state = 'block';
      this.vx *= 0.6;
      this._physics(world);
      return;
    }

    if (!this.airborne) {
      if (snap.left) {
        this.vx = -WALK;
        this.state = 'walk';
      } else if (snap.right) {
        this.vx = WALK;
        this.state = 'walk';
      } else {
        this.vx *= FRICTION;
        this.state = 'idle';
      }
      const o = world.opponent;
      if (o && Math.abs(this.y - o.y) < 90) {
        const min = 100;
        if (this.vx < 0 && this.x > o.x && this.x - o.x < min) this.vx = 0;
        if (this.vx > 0 && this.x < o.x && o.x - this.x < min) this.vx = 0;
      }
    }

    this._physics(world);
  }

  _physics(world) {
    this.vy += GRAVITY;
    this.x += this.vx;
    this.y += this.vy;

    if (this.y >= GROUND_Y) {
      this.y = GROUND_Y;
      this.vy = 0;
      this.airborne = false;
      if (this.state === 'jump') this.state = 'idle';
    } else {
      this.airborne = true;
    }

    const pad = 46;
    this.x = clamp(this.x, pad, CANVAS_W - pad);
  }

  static separate(a, b) {
    const pad = 46;
    const minDist = 100;
    if (Math.abs(a.y - b.y) > 96) return false;
    const left = a.x <= b.x ? a : b;
    const right = left === a ? b : a;
    const gap = right.x - left.x;
    if (gap >= minDist) return false;
    const need = minDist - gap;
    if (left.x <= pad + 2) {
      right.x = left.x + minDist;
    } else if (right.x >= CANVAS_W - pad - 2) {
      left.x = right.x - minDist;
    } else {
      left.x -= need / 2;
      right.x += need / 2;
    }
    left.x = clamp(left.x, pad, CANVAS_W - pad);
    right.x = clamp(right.x, pad, CANVAS_W - pad);
    if (right.x - left.x < minDist) {
      if (left.x <= pad + 1) right.x = Math.min(CANVAS_W - pad, left.x + minDist);
      else left.x = Math.max(pad, right.x - minDist);
    }
    return true;
  }
}

export function collideProjectile(proj, defender) {
  if (proj.dead || proj.hasHit) return null;
  if (proj.owner === defender.side) return null;
  const a = proj.hitbox;
  const b = defender.hurtbox;
  if (!(a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y)) return null;
  const dummyAtk = {
    damage: proj.kind === 'tuna' ? 70 : 55,
    chip: 8,
    hitstun: 14,
    blockstun: 10,
    knockback: 5,
    launch: 0,
    type: 'mid',
    meterGain: 8,
  };
  const blocked = isBlocked('mid', defender.blocking, defender.crouching, defender.airborne);
  const r = defender.takeHit(dummyAtk, Math.sign(proj.vx) || 1, blocked);
  proj.hasHit = true;
  proj.dead = true;
  return { kind: 'proj', ...r, atk: dummyAtk, hb: a };
}

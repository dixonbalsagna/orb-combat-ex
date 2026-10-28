// The moveset generator (docs/combat/moveset-generator.md), ported from Combat's reference script
// docs/combat/pending/movegen/gen_moveset.py (version 21). Function for function the same, so that its files come out byte for
// byte the same: tools/movegen/test/parity.mjs compares them. No generator state and no clock: the only randomness is a hash of
// the seed, the fighter, the cell and the candidate.
//
// Inputs (one folder, `dir`): parts.json, identity.json, cells.json and lock.json; Animation's data (the strike and entry
// manifests in data/anim/waves, data/anim/tips.json); Legal's docs/legal/movegen-banned.json. Outputs into the same folder: one
// moveset file a fighter, the lock and the review sheet.
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { cmp, dumps, eq, get, has, pad2, round, sorted, truthy, uniqSorted } from './py.mjs';

export const VERSION = 21;
export const LEVELS = ['posed', 'hand_state', 're_aim', 'hand_state_re_aim', 're_aim_edge', 'hand_state_re_aim_edge', 'stand_in'];
export const STANCES = ['martial', 'manoeuvre', 'energy', 'defensive', 'charging'];
export const FLOOR = 3;   // after any two blows of a mixed string, each strike button must still have this many pieces it may throw

// What the Python reference keeps in module globals, set when a build starts.
export const env = {
  root: null,   // the repository
  here: null,   // the folder of the inputs and outputs
  relock: false,
  recipes: null,   // --recipes PATH, or null for the default
  tipsOf: new Map(),   // limb -> the tips it can have, from the grammar
  alias: { weight: {}, form: {} },   // Legal's older words for a weight and a form
  missing: new Set(),   // packs an identity lists that the tree does not have yet: read as empty, and named by --check
};

export function configure({ root, here, relock = false, recipes = null }) {
  env.root = root;
  env.here = here;
  env.relock = relock;
  env.recipes = recipes;
  env.missing = new Set();
}

export class Stop extends Error {}   // Python's SystemExit with a message: printed, exit 1

export function load(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function raw(path) {
  return readFileSync(path).toString('latin1').replace(/\r\n/g, '\n');
}

const anim = (...rel) => join(env.root, 'data', 'anim', ...rel);
const here = (name) => join(env.here, name);

/** 0.85 to 1.15, in steps of 0.0003, from a hash: integer arithmetic until the last step. */
export function jitter(...parts) {
  const h = createHash('sha256').update(parts.map((p) => (p === null ? 'None' : p === true ? 'True' : p === false ? 'False' : String(p))).join('|'), 'utf8').digest();
  return 0.85 + (0.3 * Number(h.readBigUInt64BE(0) % 1000n)) / 1000.0;
}

/** A filter: every listed part has one of the listed values. `any`: one of a list of filters. */
export function match(flt, m) {
  if (has(flt, 'any')) return flt.any.some((f) => match(f, m));
  for (const [k, vals] of Object.entries(flt)) {
    if (k.startsWith('_')) continue;
    if (!has(vals, get(m, k))) return false;
  }
  return true;
}

export const fp = (m) => [m.limb, m.tip, m.path, m.target, m.weight];
export const fk = (m) => fp(m).join('\u0001');
const fk4 = (m) => fp(m).slice(0, 4).join('\u0001');
const tk = (t) => t.join('\u0001');

export function shapes(g) {
  const out = [];
  for (const [limb, tips] of Object.entries(g.tips)) {
    for (const [tip, paths] of Object.entries(tips)) {
      for (const path of paths) {
        for (const target of g.targets[limb][path]) {
          for (const weight of ['light', 'medium']) {
            const m = { limb, tip, path, target, weight };
            if (weight === 'light' && g.lightNever.some((r) => match(r, m))) continue;
            out.push(m);
          }
        }
      }
    }
  }
  const hv = get(g, 'heavy', {});   // the third strength has its own table of tips: a whole-body blow
  for (const [limb, tips] of Object.entries(get(hv, 'tips', {}))) {
    for (const [tip, paths] of Object.entries(tips)) {
      for (const path of paths) {
        for (const target of g.targets[limb][path]) {
          const m = { limb, tip, path, target, weight: 'heavy' };
          if (!get(hv, 'never', []).some((r) => match(r.shape, m))) out.push(m);
        }
      }
    }
  }
  return out;
}

// ---------------------------------------------------------------- Legal's rows

/** How a shape row bears on a move: 'match' (refuse), 'ask' (every named part matches and its flags are unknown), or null. */
export function bannedHit(row, m, forms, arms, flags) {
  const mt = row.match;
  forms = [...forms, ...forms.filter((f) => has(env.alias.form, f)).map((f) => env.alias.form[f])];
  for (const [k, vals] of Object.entries(mt)) {
    if (k === 'flags') continue;
    if (k === 'form') {
      if (!forms.some((f) => has(vals, f))) return null;
    } else if (k === 'arms') {
      if (!has(vals, arms)) return null;
    } else if (k === 'weight') {
      if (!has(vals, get(m, k)) && !has(vals, get(env.alias.weight, get(m, k)))) return null;
    } else if (k === 'tip') {   // a tip list binds the limbs that can have those tips (strike.legalTips)
      const mine = env.tipsOf.get(get(m, 'limb'));
      if (!has(vals, get(m, k)) && (mine === undefined || vals.some((v) => mine.has(v)))) return null;
    } else if (!has(vals, get(m, k))) return null;
  }
  if (!has(mt, 'flags')) return 'match';
  if (mt.flags.some((f) => flags.has.includes(f))) return 'match';
  if (mt.flags.every((f) => flags.not.includes(f))) return null;
  return 'ask';
}

/** Every row that judges one strike by its parts and flags: Legal's shape rows, and the rows of its other groups that the merge gave a shape (h05). */
export function shapeRows(parts) {
  const out = [...parts.strike.banned];
  for (const rows of Object.values(get(parts, 'legal', {}))) {
    if (Array.isArray(rows)) for (const r of rows) if (get(r, 'kind') === 'shape') out.push(r);
  }
  return out;
}

/** Known present, and known absent, pose flags of a move (parts.json strike.flags). */
export function flagsOf(g, idn, m, source) {
  const hasF = new Set(get(get(idn, 'tipFlags', {}), m.limb + '.' + m.tip, []));
  const notF = new Set(g.flags.byVocabulary);
  if (source) {
    for (const f of get(source, 'flags', [])) hasF.add(f);
    if (truthy(get(source, 'measured'))) for (const f of g.flags.fromAnimation) notF.add(f);
    for (const tag of source.legal) for (const f of get(g.flags.clearedBy, tag, [])) notF.add(f);
  }
  return { has: uniqSorted([...hasF]), not: uniqSorted([...notF].filter((f) => !hasF.has(f))) };
}

/** The sequence rules a list of blows breaks. A blow is a dict of parts; it may carry `arms` and `event`. */
export function sequenceBreaks(g, seq, airborne = true) {
  const out = [];
  for (const r of g.bannedSequences) {
    if (r.kind === 'hold') {
      let run = 0;
      for (let i = 0; i < seq.length; i++) {
        const b = seq[i];
        run = i > 0 && has(b, 'place') && eq(b.place, get(seq[i - 1], 'place')) ? run + 1 : 1;
        if (has(b, 'place') && run > r.max) {
          out.push(r.id);
          break;
        }
      }
    } else if (r.kind === 'run') {
      const caps = [[{}, r.max], ...get(r, 'tighter', []).map((t) => [t.when, t.max])];
      const part = (b, k) => (k === 'target' ? get(b, 'place', get(b, k)) : get(b, k));
      for (const [flt, cap] of caps) {
        let run = 0;
        for (let i = 0; i < seq.length; i++) {
          const b = seq[i];
          const same = i > 0 && r.same.every((k) => has(b, k) && has(seq[i - 1], k) && eq(part(b, k), part(seq[i - 1], k)));
          run = same ? run + 1 : 1;
          if (run > cap && match(flt, b)) {
            out.push(r.id);
            break;
          }
        }
      }
    } else if (r.kind === 'after') {
      if (get(r, 'state') === 'airborne' && !airborne) continue;
      for (let i = 1; i < seq.length; i++) {
        const prev = seq[i - 1];
        if (Object.entries(r.after).every(([k, v]) => has(v, get(prev, k))) && r.never.some((n) => match(n, seq[i]))) {
          out.push(r.id);
          break;
        }
      }
    } else if (r.kind === 'steps') {
      if (seq.some((b) => get(b, 'step', []).some((s) => !has(r.drawn, s)))) out.push(r.id);
    }
  }
  return uniqSorted(out);
}

/** Legal's rules on a whole string, whatever mix of buttons made it (flurry f02): the sequence rules, and for a run of energy pieces the rows that ask a
 * flurry to vary its piece (e06). A blow is a strike's parts or an energy move's. */
export function stringBreaks(parts, blows, airborne = true) {
  const g = parts.strike;
  const lg = get(parts, 'legal', {});
  const strikes = blows.filter((b) => has(b, 'limb'));
  let out = sequenceBreaks(g, strikes.map((b) => Object.fromEntries(Object.entries(b).filter(([k]) => k !== 'button'))), airborne);
  const flurry = get(lg, 'flurry', []).filter((r) => get(r, 'kind') === 'string');
  if (flurry.some((r) => r.uses.some((b) => out.includes(b)))) {
    out = out.concat(flurry.filter((r) => r.uses.some((b) => out.includes(b))).map((r) => r.id));
  }
  for (const r of get(lg, 'energy', [])) {
    const st = get(r, 'string');
    if (!truthy(st)) continue;
    let run = 0;
    for (let i = 0; i < blows.length; i++) {
      const b = blows[i];
      const same = i > 0 && has(b, 'hand') && has(blows[i - 1], 'hand') && st.same.every((k) => eq(get(b, k), get(blows[i - 1], k)));
      run = same ? run + 1 : 1;
      if (run > st.max) {
        out.push(r.id);
        break;
      }
    }
  }
  return uniqSorted(out);
}

/** The groups of Legal's file that are not copied into parts.json, with their row counts: said on --check's Legal line so a new group is seen. */
export function legalUnread(parts) {
  const lf = join(env.root, 'docs', 'legal', 'movegen-banned.json');
  if (!existsSync(lf)) return '';
  const known = get(get(parts, 'legal', {}), 'mirrored', []);
  const other = Object.entries(load(lf))
    .filter(([k, v]) => !['schema', '_about', 'banned', 'bannedSequences'].includes(k) && !has(known, k) && v !== null && typeof v === 'object')
    .map(([k, v]) => `${k} ${Array.isArray(v) ? v.length : Object.keys(v).length}`);
  return other.length ? ` (not read, no move is made of them: ${other.join(', ')})` : '';
}

/** Legal's group rows (parts.json legal) a travel or energy move matches. kind: 'travel' or 'energy'. */
export function groupHits(parts, m, kind) {
  const lg = get(parts, 'legal', {});
  const out = [];
  if (kind === 'travel') {
    for (const r of get(lg, 'motion', [])) {
      if (get(r, 'kind') === 'travel' && match(r.if, m) && !match(r.then, m)) out.push(r.id);
    }
  } else {
    const hand = get(parts.shot.hands, m.hand);
    for (const r of get(lg, 'energy', [])) {
      if (get(r, 'kind') === 'move' && match(r.if, m)) {
        const need = get(get(r, 'hand', {}), 'need', {});
        if (!match(r.then, m) || (hand !== null && Object.entries(need).some(([k, v]) => !has(v, get(hand, k))))) out.push(r.id);
      }
      if (get(r, 'kind') === 'hand') {
        if (hand === null) out.push(r.id);   // a hand Legal has not screened
        else if (Object.entries(get(r, 'never', {})).some(([k, v]) => has(v, get(hand, k))) || Object.entries(get(r, 'need', {})).some(([k, v]) => !has(v, get(hand, k)))) out.push(r.id);
      }
    }
  }
  return uniqSorted(out);
}

// ---------------------------------------------------------------- what is posed (Animation's data)

/** A pack's manifest, or an empty one when the tree does not have it yet. */
export function manifestOf(wave) {
  const path = anim('waves', wave + '.manifest.json');
  if (!existsSync(path)) {
    env.missing.add(wave);
    return { strikes: [] };
  }
  return load(path);
}

const armsDefault = (limb) => (limb === 'hand' || limb === 'elbow' ? 1 : 0);

/** His posed strikes as shapes of the grammar: fingerprint -> the key set it comes from and how. Returns [cover (a Map), unread]. */
export function posed(parts, idn, tips) {
  const g = parts.strike;
  const rows = new Map();
  const only = get(idn, 'borrowIds');   // a list of strike ids: of a pack he borrows he reads no other
  for (const wave of idn.waves) {
    const lent = only !== null && has(get(idn, 'borrows', []), wave) && !has(get(idn, 'tierWaves', []), wave);
    for (const s of manifestOf(wave).strikes) {
      if (lent && !has(only, s.combat)) continue;
      rows.set(s.combat, [wave, s]);
    }
  }
  const cover = new Map();
  const unread = [];
  const put = (key, entry) => cover.set(tk(key), { ...entry, _key: key });
  for (const sid of sorted([...rows.keys()])) {
    const [wave, s] = rows.get(sid);
    const limb = s.limb.endsWith('_r') || s.limb.endsWith('_l') ? s.limb.slice(0, -2) : s.limb;
    const tip = get(get(idn, 'tipOf', {}), sid, get(s, 'tip'));
    const path = get(s, 'path');
    const target = s.target.startsWith('arm') ? 'arm' : s.target;
    const tier = has(get(idn, 'tierWaves', []), wave) && get(s, 'weight', 'heavy') === 'heavy';
    const legal = [...get(s, 'legal', [])];
    const flags = [...get(s, 'flags', [])];
    const ground = get(s, 'ground', 'ok');
    if (tier) {
      const hm = { limb, tip, path, target, weight: 'heavy' };
      if (!has(get(get(g.heavy.tips, limb, {}), tip, []), path) || !has(get(g.targets[limb], path, []), target) || get(g.heavy, 'never', []).some((r) => match(r.shape, hm))) {
        unread.push(`${s.id} (${limb} ${tip} ${path} to the ${target}, a heavy)`);
        continue;
      }
      const arms = Math.trunc(Number(get(get(idn, 'armsOf', {}), sid, get(get(s, 'uses', {}), 'arms', armsDefault(limb)))));
      put([limb, tip, path, target, 'heavy'], { level: 'posed', from: sid, set: s.id, wave, legal, flags, measured: has(s, 'flags'), arms, ground, _rank: [0, arms <= 1 ? 0 : 1] });
      continue;
    }
    if (!has(get(g.tips, limb, {}), tip) || !has(g.tips[limb][tip], path) || !has(get(g.targets[limb], path, []), target)) {
      unread.push(`${s.id} (${limb} ${tip} ${path} to the ${target})`);
      continue;
    }
    const arms = Math.trunc(Number(get(get(s, 'uses', {}), 'arms', armsDefault(limb))));
    const wt = get(get(g, 'animWeight', {}), s.weight, s.weight);
    const tipsList = [tip];
    if (limb === 'hand' && has(g.swap, tip)) {
      const keep = get(s, 'legal', []).filter((t) => has(get(g, 'tagTips', {}), t)).map((t) => g.tagTips[t]);
      for (const t of g.swap) if (t !== tip && has(g.tips.hand[t], path) && keep.every((k) => has(k, t))) tipsList.push(t);
    }
    const aims = [[target, '']];
    const ra = get(get(tips, 'reaim', {}), s.id, {});
    for (const [grade, sfx] of [['ok', ''], ['edge', '_edge']]) {
      for (let t of get(ra, grade, [])) {
        t = t.startsWith('arm') ? 'arm' : t;
        if (t !== target && has(g.targets[limb][path], t) && aims.every(([a]) => t !== a)) aims.push([t, sfx]);
      }
    }
    for (const t of tipsList) {
      for (const [tg, sfx] of aims) {
        const level = t === tip ? (tg === target ? 'posed' : 're_aim' + sfx) : tg === target ? 'hand_state' : 'hand_state_re_aim' + sfx;
        const key = [limb, t, path, tg, wt];
        const rank = [LEVELS.indexOf(level), arms <= 1 ? 0 : 1];
        const was = cover.get(tk(key));
        if (!was || cmp(rank, was._rank) < 0) put(key, { level, from: sid, set: s.id, wave, legal: [...legal], flags: [...flags], measured: has(s, 'flags'), arms, ground, _rank: rank });
      }
    }
    const hv = get(g, 'heavy');
    if (truthy(hv) && wt === 'medium') {   // a posed medium that only reads on a long wind-up stands in for the heavy of its shape
      const base = { limb, tip, path, target, weight: 'medium' };
      const wr = windupOf(g, base, arms, get(s, 'flags', []));
      const hk = [limb, tip, path, target, 'heavy'];
      if (wr !== null && wr.reads === 'charged' && has(get(get(hv.tips, limb, {}), tip, []), path)
          && !get(hv, 'never', []).some((r) => match(r.shape, { ...base, weight: 'heavy' }))
          && get(cover.get(tk(hk)) || {}, 'level', 'stand_in') === 'stand_in') {   // never over a key set of the tier itself
        put(hk, { level: 'stand_in', from: sid, set: s.id, wave, legal: [...legal], flags: [...flags], measured: has(s, 'flags'), arms, ground, _rank: [LEVELS.indexOf('stand_in'), arms <= 1 ? 0 : 1] });
      }
    }
  }
  return [cover, unread];
}

export function entriesOf(idn) {
  const out = {};
  for (const wave of get(idn, 'entryWaves', [])) {
    for (const e of load(anim('waves', wave + '.entrymap.json')).entries) out[e.combat.split('.').slice(1).join('.')] = e.id;
  }
  return out;
}

/** The wind-up rule of a medium or a heavy (parts.json strike.windup): the first that matches. null for a light. */
export function windupOf(g, m, arms, flags = []) {
  if (!['medium', 'heavy'].includes(get(m, 'weight'))) return null;
  const probe = { ...m, arms };
  for (const r of get(get(g, 'windup', {}), m.weight, [])) {
    const when = { ...r.when };
    const fl = get(when, 'flags');
    delete when.flags;
    if (fl !== null && !fl.some((f) => flags.includes(f))) continue;
    if (match(when, probe)) return r;
  }
  return null;
}

/** A heavy's plain name: its drive, its tip and its place. */
export function nameOf(g, m, arms) {
  const hv = g.heavy;
  return `${hv.drive[m.path].word} ${hv.words[m.limb + '.' + m.tip]} to the ${m.target}${arms === 2 ? ' (both arms)' : ''}`;
}

export function formsOf(g, m, arms, flags = []) {
  const probe = { ...m, arms };
  const have = [];
  for (const rule of g.forms) {
    if (have.includes(rule.form) || (truthy(get(rule, 'unless')) && have.includes(rule.unless))) continue;
    const flt = has(rule, 'any') ? { any: rule.any } : rule.when;
    if (!match(flt, probe)) continue;
    if (has(rule, 'reads')) {   // a medium takes this form only if its wind-up rule reads that way
      const wr = windupOf(g, m, arms, flags);
      if (wr === null || wr.reads !== rule.reads) continue;
    }
    have.push(rule.form);
  }
  return have;
}

export function weightOf(idn, m) {
  const w = idn.weights;
  const tips = { ...get(w, 'tip', {}) };
  let extra = 1.0;
  for (const by of get(idn, 'weightsBy', [])) {
    if (match(by.when, m)) {
      Object.assign(tips, get(by, 'tip', {}));
      for (const part of ['target', 'path', 'limb']) extra *= get(get(by, part, {}), m[part], 1);
    }
  }
  return get(w.limb, m.limb, 1) * get(w.path, m.path, 1) * get(tips, m.limb + '.' + m.tip, 1) * extra;
}

export function quotaOk(q, m) {
  const shape = () => (!has(q, 'filter') && !has(q, 'any')) || match(has(q, 'any') ? { any: q.any } : q.filter, m);
  if (has(q, 'own')) return truthy(get(m, '_own')) && (!has(q, 'form') || m._forms.includes(q.form));
  if (has(q, 'form') && has(q, 'sends')) return m._forms.includes(q.form) && get(m, '_sends') === q.sends && shape();
  if (has(q, 'form')) return m._forms.includes(q.form) && shape();
  if (has(q, 'sends')) return get(m, '_sends') === q.sends;
  return match(has(q, 'any') ? { any: q.any } : q.filter, m);
}

/** Pick one at a time: quotas first, then the best score, each pick marking down what resembles it. allow(picked, m): whether the cell may still take a
 * candidate. many: a pick meets as many of the short quotas as it can. */
export function greedy(cand, count, quotas, penalty, locked = [], allow = null, many = false) {
  const picked = [...locked];
  cand = cand.filter((m) => picked.every((p) => m !== p));
  while (cand.length && picked.length < count) {
    if (allow !== null) {
      cand = cand.filter((m) => allow(picked, m));
      if (!cand.length) break;
    }
    let pool = cand;
    const short = quotas.filter((q) => picked.filter((p) => quotaOk(q, p)).length < q.min && cand.some((m) => quotaOk(q, m)));
    if (short.length) {
      pool = cand.filter((m) => quotaOk(short[0], m));
      for (const q of many ? short.slice(1) : []) {
        const both = pool.filter((m) => quotaOk(q, m));
        if (both.length) pool = both;
      }
    }
    let best = null;
    let bs = -1.0;
    for (const m of pool) {
      let w = m._w;
      for (const p of picked) w *= penalty(p, m);
      if (w > bs) {
        best = m;
        bs = w;
      }
    }
    cand.splice(cand.indexOf(best), 1);
    picked.push(best);
  }
  return picked;
}

function* product(lists) {
  if (!lists.length) {
    yield [];
    return;
  }
  const [first, ...rest] = lists;
  const tails = [...product(rest)];
  for (const x of first) for (const t of tails) yield [x, ...t];
}

// ---------------------------------------------------------------- the cells, by kind

function strikeCell(ctx, who, cid, cell) {
  const { parts, idn, cover, seed, spread } = ctx;
  const g = parts.strike;
  let cand = [];
  const refused = [];
  for (const m of shapes(g)) {
    if (!match(cell.filter, m)) continue;
    if (has(cell, 'weights') && !has(cell.weights, m.weight)) continue;
    if (idn.never.some((r) => match(r.shape, m)) || has(ctx.rejected, fp(m))) continue;
    if (get(get(idn, 'cellNever', {}), cid, []).some((r) => match(r.shape, m))) continue;   // a shape his row bans in this cell only
    if (get(cell, 'never', []).some((r) => match(r.shape, m))) continue;   // a cell's own bans, for every fighter
    const w = weightOf(idn, m);
    if (w <= 0) continue;
    const c = cover.get(fk(m)) || null;
    if (has(cell, 'only') && (c === null || c.level !== cell.only)) continue;   // a cell of stand-ins holds nothing else
    if (c !== null && has(get(get(cell, 'without', {}), who, []), c.from)) continue;
    if (c !== null && has(get(cell, 'notLevels', []), c.level)) continue;
    const kit = get(idn, 'kit');
    if (truthy(kit) && get(kit, 'from') === 'common' && !(c !== null && has(get(kit, 'levels', ['posed']), c.level) && (ctx.common.has(c.from) || has(get(kit, 'ownPacks', []), c.wave)))) {
      if (!(has(get(kit, 'newOf', []), m.weight) && c === null)) continue;   // a kit row (the guards): only common pieces, or a new shape of a weight his kit allows
      const owns = new Set();
      for (const d of Object.values(ctx.built)) for (const c2 of Object.values(d.cells)) for (const mv of get(c2, 'moves', [])) if (mv && typeof mv === 'object' && truthy(get(mv, 'own'))) owns.add(fk4(mv));
      if (owns.has(fk4(m))) continue;   // ... and never another fighter's own blow, at any strength
    }
    m._arms = c ? c.arms : armsDefault(m.limb);
    m._flags = flagsOf(g, idn, m, c);
    if (m.weight === 'heavy' && c === null) {   // a new heavy has the flags its drive brings (a spring is a leap)
      const brought = get(g.heavy.drive[m.path], 'flags', []);
      m._flags = { has: uniqSorted([...m._flags.has, ...brought]), not: m._flags.not.filter((f) => !brought.includes(f)) };
    }
    m._wind = windupOf(g, m, m._arms, m._flags.has);
    m._strike_forms = formsOf(g, m, m._arms, m._flags.has);
    m._forms = has(cell, 'readings') ? [...cell.readings] : m._strike_forms;
    if (get(cell, 'notFlags', []).some((f) => m._flags.has.includes(f))) continue;   // a push is never a leap
    const hits = shapeRows(parts).map((r) => [r.id, bannedHit(r, m, m._strike_forms, m._arms, m._flags)]);
    if (hits.some(([, h]) => h === 'match')) {
      refused.push({ shape: fp(m), rows: hits.filter(([, h]) => h === 'match').map(([i]) => i) });
      continue;
    }
    m._w = w * (c ? idn.reuse[c.level] : 1.0) * jitter(seed, who, cid, ...fp(m));
    m._sends = g.sends[m.path];
    cand.push(m);
  }
  if (truthy(get(cell, 'anyWeight'))) {   // one shape a place: keep the better-covered of light and heavy
    const best = new Map();
    for (const m of cand) {
      const k = fk4(m);
      const r = cover.has(fk(m)) ? cover.get(fk(m))._rank : [99, 0];
      const score = [r, m.weight !== 'light'];
      if (!best.has(k) || cmp(score, best.get(k)[0]) < 0) best.set(k, [score, m]);
    }
    cand = [...best.values()].map((v) => v[1]);
  }
  const valid = cand.length;
  const locked = [];
  const dropped = [];
  const reread = [];
  const byFp = new Map(cand.map((m) => [fk(m), m]));
  const coverSorted = sorted([...cover.values()], (e) => e._key);
  for (const entry of get(ctx.lock, cid, [])) {
    const mid = entry[0];
    const shape = entry[1];
    const kset = entry.length > 2 ? entry[2] : null;
    let m = null;
    if (truthy(kset)) {   // a move locked on a posed key set follows that key set to the shape Animation reads on it
      const real = coverSorted.find((e) => e.set === kset && e.level === 'posed');
      if (real !== undefined && !eq(real._key, shape) && byFp.has(tk(real._key))) {
        reread.push({ id: mid, set: kset, was: [...shape], now: [...real._key] });
        m = byFp.get(tk(real._key));
      }
    }
    if (m === null) m = byFp.get(tk(shape)) || null;
    if (m === null || has(m, '_id')) dropped.push({ id: mid, shape: [...shape] });
    else {
      m._id = mid;
      locked.push(m);
    }
  }
  const sp = { ...spread, ...get(cell, 'spread', {}) };
  const penalty = (p, m) => {
    let w = 1.0;
    if (p.path === m.path) w *= sp.path;
    if (p.target === m.target) w *= sp.target;
    if (p.tip === m.tip) w *= sp.tip;
    if (p.limb === m.limb && p.path === m.path && p.target === m.target) w *= sp.shape;
    if (p.limb === m.limb && p.tip === m.tip && p.path === m.path) w *= get(sp, 'look', 1.0);
    return w;
  };
  const pins = get(get(idn, 'pinned', {}), cid, []).filter((s) => byFp.has(tk(s))).map((s) => byFp.get(tk(s)));
  const ownQ = [...get(get(idn, 'cellQuotas', {}), cid, [])];
  let quotas = [...ownQ, ...get(cell, 'quotas', [])];
  let allow = null;
  const share = truthy(get(idn, 'kit')) ? null : get(cell, 'share');
  let others = [];
  let worlds = [];
  if (truthy(share)) {
    // A shared tier (Game Design, fighter-pipeline.md section 1): so many pieces that are his alone by his tier, no more than a part of the cell shared with
    // any one other fighter, and the fighter he takes a piece from keeps his own share.
    const fs = ctx.fighters;
    const alt = (f) => get(fs[f], 'alt');
    others = sorted(Object.keys(fs)).filter((o) => o !== who && !truthy(get(fs[o], 'kit')) && !(truthy(alt(who)) && eq(alt(who), alt(o))));
    const cellShapes = (o) => {
      if (has(ctx.built, o) && has(ctx.built[o].cells, cid)) return new Set(ctx.built[o].cells[cid].moves.map(fk));
      return new Set(get(get(ctx.locks, o, {}), cid, []).map((e) => tk(e[1])));
    };
    const shapesOf = Object.fromEntries(others.map((o) => [o, cellShapes(o)]));
    const groups = new Map();
    for (const o of others) {
      const k = truthy(alt(o)) ? alt(o) : '#' + o;
      if (!groups.has(k)) groups.set(k, []);
      groups.get(k).push(o);
    }
    worlds = [...product([...groups.values()])];
    const borrows = new Set(get(idn, 'borrows', []));
    const needOf = (f) => Math.trunc(Number(share.own[String(get(fs[f], 'tier', 1))]));
    const capN = Math.trunc(cell.count * share.maxWithOne);
    for (const m of cand) {
      const c = cover.get(fk(m)) || null;
      const sh = new Set(others.filter((o) => shapesOf[o].has(fk(m))));
      const borrowed = c !== null && borrows.has(c.wave);
      if (borrowed && others.includes(get(ctx.waveOwner, c.wave))) sh.add(ctx.waveOwner[c.wave]);
      m._shared = sh;
      m._own = c !== null ? !borrowed && !ctx.common.has(c.from) : sh.size === 0;
    }
    const theirsOwn = new Set();
    for (const o of others) {
      if (has(ctx.built, o)) {
        for (const c2 of Object.values(ctx.built[o].cells)) for (const mv of get(c2, 'moves', [])) if (mv && typeof mv === 'object' && truthy(get(mv, 'own'))) theirsOwn.add(fk4(mv));
      } else if (existsSync(here(`moveset.${o}.json`))) {   // not built yet in this run: his own as his current file has them
        for (const c2 of Object.values(load(here(`moveset.${o}.json`)).cells)) for (const mv of get(c2, 'moves', [])) if (mv && typeof mv === 'object' && truthy(get(mv, 'own')) && has(mv, 'limb')) theirsOwn.add(fk4(mv));
      }
    }
    cand = cand.filter((m) => has(m, '_id') || cover.has(fk(m)) || !theirsOwn.has(fk4(m)));
    allow = (picked, m) => {
      for (const o of m._shared) {
        if (picked.filter((p) => p._shared && p._shared.has(o)).length >= capN) return false;   // more than the cell's share with that fighter
        if (shapesOf[o].has(fk(m))) {
          for (const w of worlds) {   // and that fighter keeps his own: what nobody else in the roster holds
            if (w.includes(o)) {
              const taken = new Set();
              for (const x of w) if (x !== o) for (const s of shapesOf[x]) if (shapesOf[o].has(s)) taken.add(s);
              for (const p of picked) if (shapesOf[o].has(fk(p))) taken.add(fk(p));
              taken.add(fk(m));
              if (shapesOf[o].size - taken.size < needOf(o)) return false;
            }
          }
        }
      }
      return true;
    };
    quotas = [{ name: 'his alone', min: needOf(who), own: true }, ...quotas];
  }
  const count = cell.count + Math.trunc(Number(get(get(idn, 'adds', {}), cid, 0)));
  const picked = greedy(cand, count, quotas, penalty, [...locked, ...pins.filter((m) => locked.every((x) => m !== x))], allow, true);
  const used = new Set(picked.filter((m) => has(m, '_id')).map((m) => m._id));
  const free = [];
  for (let i = 0; i < picked.length + dropped.length + 5; i++) {
    const n = `mv.${who}.${cid}.${pad2(i + 1)}`;
    if (!used.has(n)) free.push(n);
  }
  const moves = [];
  for (const m of picked) {
    const c = cover.get(fk(m)) || null;
    const probe = { ...m, arms: m._arms };
    let asks = g.conditions.filter((cd) => has(cd, 'when') && match(cd.when, probe)).map((cd) => cd.id);
    if (get(cell, 'as') === 'push') asks = ['P1', ...asks.filter((a) => a === 'L2' || a === 'L7')];
    asks = asks.concat(get(cell, 'asks', []).filter((a) => !asks.includes(a)));
    let keys;
    if (c === null) keys = { level: 'new' };
    else {
      keys = { level: c.level, from: c.from, set: c.set, wave: c.wave };
      if (c.level.startsWith('hand_state')) keys.hand = m.tip;
      if (c.level.includes('re_aim')) keys.aim = m.target;
    }
    if (truthy(get(cell, 'layer'))) keys.layer = cell.layer;
    const mv = {
      id: has(m, '_id') && truthy(m._id) ? m._id : free.shift(), limb: m.limb, tip: m.tip, path: m.path, target: m.target, weight: m.weight, arms: m._arms,
      forms: m._forms, step: g.step[m.path], sends: m._sends, links: g.links[m.path], beat: g.beat[m.path],
      keys, ground: c ? c.ground : m.limb === 'foot' || m.limb === 'knee' ? 'plant' : 'ok',
      status: c && c.level === 'posed' ? 'posed' : c ? 'derived' : 'waiting',
      flags: m._flags.has, legal: c ? sorted(c.legal) : [], asks, review: truthy(get(cell, 'temporary')) ? 'stand-in' : 'locked',
    };
    if (m._wind !== null && !has(cell, 'readings')) mv.wind = m._wind.id;
    if (truthy(share) && truthy(get(m, '_own'))) mv.own = true;   // his own piece: never lent, and counted by the gate on blows
    if (m.weight === 'heavy') {
      mv.drive = g.heavy.drive[m.path].id;
      mv.name = nameOf(g, m, m._arms);
    }
    if (truthy(get(cell, 'as'))) mv.as = cell.as;
    moves.push(mv);
  }
  const movesSorted = sorted(moves, (x) => x.id);
  const met = {};
  for (const q of [...ownQ, ...get(cell, 'quotas', [])]) met[q.name] = picked.filter((p) => quotaOk(q, p)).length;
  if (truthy(share)) {   // his alone: in the roster that leaves him fewest (one option of each alt group)
    met['his alone'] = Math.min(...worlds.map((w) => picked.filter((p) => truthy(get(p, '_own')) && ![...(p._shared || [])].some((x) => w.includes(x))).length));
    for (const o of others) {
      const n = picked.filter((p) => p._shared && p._shared.has(o)).length;
      if (n) met['shared with ' + o] = n;
    }
  }
  const was = new Set(picked.filter((m) => has(m, '_id')).map((m) => m._id));
  ctx.changes[cid] = { dropped, reread, new: truthy(get(cell, 'temporary')) ? [] : movesSorted.filter((m) => !was.has(m.id)).map((m) => m.id) };
  const res = { kind: 'strikes', valid, refused, quotas: met, moves: movesSorted };
  if (truthy(get(cell, 'temporary'))) res.temporary = true;   // not locked: these ids go when the cell they stand in for is posed
  return res;
}

function travelCell(ctx, who, cid, cell, done) {
  const { parts, idn, seed } = ctx;
  const t = parts.travel;
  const ents = ctx.entries;
  const blows = done[cell.blows].moves.filter((b) => b.status !== 'waiting');
  const cand = [];
  const refused = [];
  const seenRefused = new Set();
  for (const kind of cell.kinds) {
    for (const mv of t.kinds[kind].moves) {
      for (const e of mv.entries) {
        if (!has(ents, e) || (truthy(mv.exit) && !has(ents, mv.exit))) continue;
        for (const b of blows) {
          if (!has(t.arrive[mv.direction], b.path)) continue;
          const m = { kind, direction: mv.direction, entry: e, exit: mv.exit, blow: b.id, path: b.path, target: b.target, limb: b.limb, _b: b };
          const hits = groupHits(parts, m, 'travel');
          if (hits.length) {
            const key = [kind, mv.direction, mv.exit].map(String).join('\u0001');
            if (!seenRefused.has(key)) {
              seenRefused.add(key);
              refused.push({ move: { kind, direction: mv.direction, exit: mv.exit }, rows: hits });
            }
            continue;
          }
          m._forms = [...cell.readings];
          m._w = get(get(idn.weights, 'entry', {}), e, 1) * weightOf(idn, b) * (b.status === 'posed' ? 1.3 : 1.0) * jitter(seed, who, cid, kind, mv.direction, e, b.id);
          cand.push(m);
        }
      }
    }
  }
  const valid = cand.length;
  const penalty = (p, m) => {
    let w = 1.0;
    if (p.blow === m.blow) w *= 0.1;
    if (p.entry === m.entry) w *= 0.5;
    if (p.kind === m.kind && p.direction === m.direction) w *= 0.5;
    if (p.path === m.path) w *= 0.7;
    if (p.target === m.target) w *= 0.8;
    return w;
  };
  const picked = greedy(cand, cell.count, get(cell, 'quotas', []), penalty);
  const moves = picked.map((m, i) => {
    const b = m._b;
    const asks = [...(m.kind.startsWith('zip') ? ['Z1'] : []), ...b.asks];
    return {
      id: `mv.${who}.${cid}.${pad2(i + 1)}`, kind: m.kind, band: t.kinds[m.kind].band, direction: m.direction,
      entry: { id: 'entry.' + m.entry, set: ents[m.entry] }, exit: truthy(m.exit) ? { id: 'entry.' + m.exit, set: ents[m.exit] } : null,
      blow: { move: b.id, limb: b.limb, tip: b.tip, path: b.path, target: b.target, weight: b.weight, set: get(b.keys, 'set') },
      forms: m._forms, status: b.status === 'posed' ? 'posed' : 'derived', flags: b.flags, legal: b.legal, asks, review: 'new',
    };
  });
  const met = {};
  for (const q of get(cell, 'quotas', [])) met[q.name] = picked.filter((p) => quotaOk(q, p)).length;
  return { kind: 'travel', valid, refused, quotas: met, moves };
}

function tableCell(ctx, who, cid, cell) {
  const { parts, idn, seed } = ctx;
  const blk = parts[cell.block];
  const en = idn.energy;
  const mineBlk = get(en, cell.block, {});
  const hands = get(mineBlk, 'hands', en.hands);   // a block may have its own weights for his hands (energy in reach)
  const cand = [];
  let refused = [];
  const ruleNow = {};
  for (const p of get(mineBlk, 'posed', [])) if (has(p, 'strikeNow')) ruleNow[p.strike] = p.strikeNow;
  for (const [hand, release, body, delivery, target] of product([sorted(Object.keys(hands)), blk.release, blk.body, cell.delivery, get(blk, 'targets', [null])])) {
    const m = { hand, release, body, delivery };
    if (truthy(target)) Object.assign(m, { target, limb: 'hand', path: blk.path[release] });   // a piece set on a place is a blow as well as a shot
    if (delivery === 'split' && !truthy(get(en, 'split'))) continue;
    if (blk.rules.some((r) => match(r.if, m) && !match(r.then, m))) continue;
    m._forms = blk.forms.filter((f) => match(f.when, m)).map((f) => f.form);
    if (!m._forms.length) continue;
    const hits = groupHits(parts, m, 'energy');
    if (hits.length) {
      refused.push({ move: { ...m, _forms: null }, rows: hits });
      continue;
    }
    m._w = hands[hand] * get(get(get(mineBlk, 'byDelivery', {}), delivery, {}), hand, 1) * get(en.release, release, 1) * jitter(seed, who, cid, hand, release, body, delivery, ...(truthy(target) ? [target] : []));
    const rule = [...get(mineBlk, 'posed', []), ...en.posed].find((p) => match(p.when, m)) || null;
    m._set = rule ? rule.set : null;
    m._strike = rule ? get(rule, 'strike') : null;   // a key set drawn for this very piece: it is posed, and this is the id the recipes name
    if (truthy(m._set)) m._w *= truthy(m._strike) ? 3.0 : has(en.posedHands, hand) ? 1.6 : 1.2;
    cand.push(m);
  }
  const valid = cand.length;
  const penalty = (p, m) => {
    let w = 1.0;
    for (const [k, f] of [['hand', 0.6], ['release', 0.6], ['body', 0.7], ['delivery', 0.8], ['target', 0.6]]) {
      if (has(p, k) && eq(p[k], get(m, k))) w *= f;
    }
    if (truthy(get(cell, 'distinct')) && cell.distinct.every((k) => eq(p[k], m[k]))) w *= 1e-9;   // Legal's e06 counts two bolts of one hand and release as one piece
    return w;
  };
  const quotas = get(cell, 'quotas', []).filter((q) => !(has(q, 'filter') && eq(get(q.filter, 'delivery'), ['split']) && !truthy(get(en, 'split'))));
  const picked = greedy(cand, cell.count, quotas, penalty);
  const moves = picked.map((m, i) => {
    const handSet = get(en.posedHands, m.hand);
    const keys = { set: m._set, hand: handSet };
    let status = truthy(m._set) && (truthy(handSet) || truthy(m._strike)) ? 'posed' : truthy(m._set) ? 'derived' : 'waiting';
    if (truthy(m._strike)) {
      keys.strike = m._strike;
      if (truthy(get(ruleNow, m._strike))) keys.strikeNow = ruleNow[m._strike];   // the id Animation's pack has today
    }
    if (status === 'posed' && truthy(get(cell, 'statusCap'))) status = cell.statusCap;   // posed pieces used a new way
    const mv = { id: `mv.${who}.${cid}.${pad2(i + 1)}`, hand: m.hand, release: m.release, body: m.body, delivery: m.delivery, forms: m._forms, keys, status, asks: [...get(cell, 'asks', ['E1'])], review: 'new' };
    if (has(m, 'target')) Object.assign(mv, { target: m.target, limb: m.limb, path: m.path });
    return mv;
  });
  const met = {};
  for (const q of get(cell, 'quotas', [])) met[q.name] = picked.filter((p) => quotaOk(q, p)).length;
  const by = new Map();
  for (const r of refused) {   // one line a shape of refusal, not one a candidate
    const key = [r.move.delivery, r.move.release, r.rows];
    const k = JSON.stringify(key);
    if (!by.has(k)) by.set(k, [key, []]);
    by.get(k)[1].push(r.move.hand);
  }
  refused = sorted([...by.values()], (e) => e[0]).map(([k, v]) => ({ move: { delivery: k[0], release: k[1] }, rows: [...k[2]], candidates: v.length, hands: uniqSorted(v) }));
  return { kind: 'table', valid, refused, quotas: met, moves };
}

/** The burst's own rules (parts.json strike.burst.noStutter) that a list of blows breaks. */
export function runBreaks(rules, seq) {
  let out = sequenceBreaks({ bannedSequences: rules.filter((r) => r.kind === 'run') }, seq);
  if (new Set(seq.map((b) => b.id)).size !== seq.length) out = out.concat(rules.filter((r) => r.kind === 'once').map((r) => r.id));
  return uniqSorted(out);
}

/** The lights that may be a burst's next blow: of the class of the gap before it, and breaking neither Legal's string rules nor the burst's own. */
export function burstNext(parts, pool, seq, cls) {
  const bu = parts.strike.burst;
  return pool.filter((n) => match(bu.classes[cls].when, n) && !runBreaks(bu.noStutter, [...seq, n]).length && !stringBreaks(parts, [...seq.slice(-2), n]).length);
}

/** A whole burst that starts with seq, or null: depth first, best first when an order is given. */
export function burstFill(parts, pool, slots, seq, order = null) {
  if (seq.length === slots.length) return seq;
  const cand = burstNext(parts, pool, seq, slots[seq.length]);
  for (const n of order ? order(cand, seq) : cand) {
    const got = burstFill(parts, pool, slots, [...seq, n], order);
    if (got) return got;
  }
  return null;
}

function burstCell(ctx, who, cid, cell, done) {
  const { parts, idn, seed } = ctx;
  const g = parts.strike;
  const pool = done[cell.from].moves.filter((m) => m.status !== 'waiting');
  const used = {};
  const moves = [];
  const close = get(get(idn, 'burst', {}), 'close', {});
  cell.leans.forEach((lean, i) => {
    const flt = has(lean, 'any') ? { any: lean.any } : lean.filter;
    const order = (cand, seq) => {
      const first = !seq.length;
      const last = seq.length === cell.slots.length - 1;
      const score = (n) => {
        let s = weightOf(idn, n) * jitter(seed, who, cid, lean.name, seq.length, n.id) * 0.5 ** get(used, n.id, 0);
        const fav = get(get(idn, 'burst', {}), 'favour');
        if (truthy(fav) && match(fav.filter, n)) s *= Number(get(fav, 'factor', 2.0));
        if (seq.length && has(g.links[seq[seq.length - 1].path], n.path)) s *= 2.0;   // it starts where the last one ended
        if (last && match(flt, n)) s *= 2.0;
        return s;
      };
      const rank = (n) => ((first && match(flt, n)) || (last && match(close, n)) ? 0 : 1);
      return sorted(cand, (n) => [rank(n), -score(n), n.id]);
    };
    const seq = burstFill(parts, pool, cell.slots, [], order);
    if (seq === null) throw new Stop(`${who}: no burst can be made on the lean ${lean.name}`);
    for (const n of seq) used[n.id] = get(used, n.id, 0) + 1;
    moves.push({ id: `mv.${who}.${cid}.${pad2(i + 1)}`, lean: lean.name, blows: seq.map((n) => n.id), slots: [...cell.slots],
      status: seq.every((n) => n.status === 'posed') ? 'posed' : 'derived', asks: [...get(cell, 'asks', [])], review: 'new' });
  });
  return { kind: 'string', from: cell.from, valid: pool.length, quotas: {}, moves };
}

/** A point-blank bolt as a blow of a string: it has a path and a place, and the energy parts Legal's e06 counts. */
export function reachBlow(parts, m, btn = 'rx') {
  return { id: m.id, limb: 'hand', tip: parts.shot.hands[m.hand].shape, path: m.path, target: m.target, weight: 'light', arms: 1,
    step: [], hand: m.hand, release: m.release, body: m.body, delivery: get(m, 'delivery'), button: btn };
}

/** What a mashed run of point-blank bolts breaks: Legal's e09 as parts.json reach.run words it, and what every string keeps. arms: lead or free. */
export function reachRunBreaks(parts, seq, arms) {
  const rr = parts.reach.run;
  let out = [];
  seq.forEach((n, i) => {
    if (seq.slice(Math.max(0, i - 2), i).some((p) => n.id === p.id)) out.push('one of his last two');
    out = out.concat(stringBreaks(parts, seq.slice(Math.max(0, i - 2), i + 1)));
    if (i && arms[i] === arms[i - 1] && n.path === seq[i - 1].path && n.target === seq[i - 1].target) out.push('e09: the same arm, path and place twice running');
  });
  const [need, span] = rr.pathsIn;
  for (let i = 0; i < seq.length - span + 1; i++) {
    if (new Set(seq.slice(i, i + span).map((n) => n.path)).size < need) {
      out.push(`e09: fewer than ${need} paths in ${span}`);
      break;
    }
  }
  const fa = rr.freeArm;
  const windows = (k, f) => {
    for (let i = 0; i < arms.length - k + 1; i++) if (f(arms.slice(i, i + k))) return true;
    return false;
  };
  if (windows(fa.atMostOneIn, (w) => w.filter((a) => a === 'free').length > 1)) out.push(`e09: the free arm twice in ${fa.atMostOneIn}, a left-right pump`);
  if (windows(fa.atLeastOneIn, (w) => !w.includes('free'))) out.push(`e09: one arm pumping, no bolt from the free arm in ${fa.atLeastOneIn}`);
  const at = arms.map((a, i) => (a === 'free' ? i : -1)).filter((i) => i >= 0);
  const gaps = at.slice(1).map((b, i) => b - at[i]);
  if (truthy(get(fa, 'gapsDiffer')) && gaps.slice(1).some((b, i) => gaps[i] === b)) out.push('e09: the free arm comes in on a regular count');
  for (const p of get(rr, 'notPeriodic', [])) {
    if (seq.length > 2 * p && seq.slice(0, seq.length - p).every((x, i) => x.id === seq[i + p].id)) {
      out.push('e09: the order repeats on a fixed count');
      break;
    }
  }
  return uniqSorted(out);
}

/** A run of that length ordered by e09, with its arms, or null: depth first, the order of tries from the key (a hash, so the same run every time).
 * loop: the run played round and round must keep every rule. */
export function reachRun(parts, pool, length, key, loop = false) {
  const rr = parts.reach.run;
  const [need, span] = rr.pathsIn;
  const armWords = ['e09: the free arm', 'e09: one arm pumping'];
  const armsFor = (seq) => {
    const arm = (arms) => {
      if (arms.length === length) return !reachRunBreaks(parts, loop ? [...seq, ...seq] : seq, loop ? [...arms, ...arms] : arms).length ? arms : null;
      const first = jitter(...key, 'arm', arms.length) > 1.06 ? 'free' : 'lead';
      for (const a of [first, first === 'free' ? 'lead' : 'free']) {
        const trial = [...arms, a];
        const br = reachRunBreaks(parts, seq.slice(0, trial.length), trial).filter((b) => !b.includes('no bolt from the free arm') || trial.length >= rr.freeArm.atLeastOneIn);
        if (!br.length) {
          const got = arm(trial);
          if (got) return got;
        }
      }
      return null;
    };
    return arm([]);
  };
  let orders = 400;   // how many whole orders of pieces may be tried for arms before giving up
  const grow = (seq) => {
    if (seq.length === length) {
      const twice = loop ? [...seq, ...seq] : seq;
      if (reachRunBreaks(parts, twice, twice.map(() => 'lead')).filter((b) => !armWords.some((w) => b.startsWith(w))).length) return null;
      const arms = armsFor(seq);   // an order of pieces is a run only when arms can be given to it
      if (arms) return [seq, arms];
      orders -= 1;
      return null;
    }
    if (orders <= 0) return null;
    const last2 = seq.slice(-2);
    const cand = pool.filter((n) => last2.every((p) => n.id !== p.id) && !stringBreaks(parts, [...last2, n]).length
      && (seq.length < span - 1 || new Set([...seq.slice(-(span - 1)), n].map((x) => x.path)).size >= need));
    for (const n of sorted(cand, (n) => [-jitter(...key, 'piece', seq.length, n.id), n.id])) {
      const got = grow([...seq, n]);
      if (got) return got;
    }
    return null;
  };
  return grow([]);
}

function runCell(ctx, who, cid, cell, done) {
  const { parts, seed } = ctx;
  const src = Object.fromEntries(done[cell.from].moves.map((m) => [m.id, m]));
  const pool = Object.values(src).map((m) => reachBlow(parts, m));
  const moves = [];
  for (let k = 0; k < cell.count; k++) {
    const got = reachRun(parts, pool, cell.length, [seed, who, cid, k], truthy(get(cell, 'loop')));
    if (got === null) throw new Stop(`${who}: no run of ${cell.length} point-blank bolts can be ordered by e09 from his ${pool.length}${truthy(get(cell, 'loop')) ? ' as a loop' : ''}`);
    const [seq, arms] = got;
    moves.push({ id: `mv.${who}.${cid}.${pad2(k + 1)}`, blows: seq.map((n) => n.id), arms,
      status: seq.some((n) => src[n.id].status === 'waiting') ? 'waiting' : 'derived', asks: [...get(cell, 'asks', [])], review: 'new' });
  }
  const res = { kind: 'run', from: cell.from, valid: pool.length, quotas: {}, moves };
  if (truthy(get(cell, 'loop'))) res.loop = true;
  return res;
}

function specialCell(ctx, who, cid, cell) {
  const { idn, seed } = ctx;
  const sp = idn.specials[cell.slot];
  const names = Object.keys(sp.parts);
  const cand = [];
  for (const combo of product(names.map((n) => sp.parts[n]))) {
    const m = Object.fromEntries(names.map((n, i) => [n, combo[i]]));
    if (get(sp, 'rules', []).some((r) => match(r.if, m) && !match(r.then, m))) continue;
    m._forms = [...cell.readings];
    m._w = jitter(seed, who, cid, ...combo);
    cand.push(m);
  }
  const penalty = (p, m) => {
    let w = 1.0;
    for (const n of names) if (eq(p[n], m[n])) w *= 0.55;
    return w;
  };
  const picked = greedy(cand, cell.count, [], penalty);
  const moves = picked.map((m, i) => ({ id: `mv.${who}.${cid}.${pad2(i + 1)}`, look: Object.fromEntries(names.map((n) => [n, m[n]])), forms: m._forms, status: 'waiting', asks: [], review: 'new' }));
  return { kind: 'special', special: sp.id, what: sp.what, state: sp.status, valid: cand.length, quotas: {}, moves };
}

/** Every cell in order: a button's own, then what each of its presses holds. Yields [stance, btn, press, cid, cell]. */
export function* cellIds(cells) {
  for (const stance of STANCES) {
    for (const btn of ['x', 'y', 'a', 'b']) {
      const cell = get(get(cells.stances, stance, {}), btn);
      if (cell === null) continue;
      yield [stance, btn, '', `${stance}.${btn}`, cell];
      for (const [press, sub] of Object.entries(get(cell, 'presses', {}))) yield [stance, btn, press, `${stance}.${btn}.${press}`, sub];
      if (has(cell, 'standIn')) yield [stance, btn, 'standin', `${stance}.${btn}.standin`, cell.standIn];
    }
  }
}

const ABOUT = 'GENERATED by gen_moveset.py from parts.json, identity.json, cells.json, lock.json and Animation\'s data. Do not edit by hand: change an input and generate '
  + 'again. PARKED: not loaded, not hashed. A move\'s status is posed (its poses exist), derived (a hand-state swap or a re-aim on a posed key set, or a posed '
  + 'piece used a new way) or waiting (it needs new poses; the director skips it). flags are the pose flags it is known to have; legal are Legal\'s tags on the '
  + 'key set it starts from; asks are Legal\'s conditions for its pose (parts.json strike.conditions). review is locked once its id is in lock.json';

/** Generate every fighter's moveset from the folder's inputs. Returns { out, parts, identity, cells, notes }. */
export function build() {
  const parts = load(here('parts.json'));
  const identity = load(here('identity.json'));
  const cells = load(here('cells.json'));
  env.tipsOf = new Map();
  for (const table of [parts.strike.tips, get(get(parts.strike, 'heavy', {}), 'tips', {})]) {
    for (const [limb, tips] of Object.entries(table)) {
      if (!env.tipsOf.has(limb)) env.tipsOf.set(limb, new Set());
      for (const t of Object.keys(tips)) env.tipsOf.get(limb).add(t);
    }
  }
  env.alias = { weight: { ...get(parts.strike, 'legalWeight', {}) }, form: { ...get(parts.strike, 'legalForm', {}) } };
  const tips = existsSync(anim('tips.json')) ? load(anim('tips.json')) : {};
  const lockPath = here('lock.json');
  const lock = existsSync(lockPath) && !env.relock ? load(lockPath).fighters : {};
  const { seed, spread } = cells;
  const out = {};
  const notes = {};
  const fighters = identity.fighters;
  const seenIds = new Map();   // a strike id -> the fighters who have it in a pack of their own (the heavy tier apart)
  for (const f2 of sorted(Object.keys(fighters))) {
    const d2 = fighters[f2];
    if (truthy(get(d2, 'kit'))) continue;   // a kit row (the guards) holds only common pieces: he never makes one
    for (const w2 of d2.waves) {
      if (has(get(d2, 'borrows', []), w2) || has(get(d2, 'tierWaves', []), w2)) continue;
      for (const s2 of manifestOf(w2).strikes) {
        if (!seenIds.has(s2.combat)) seenIds.set(s2.combat, new Set());
        seenIds.get(s2.combat).add(f2);
      }
    }
  }
  const common = new Set([...seenIds].filter(([, v]) => v.size > 1).map(([k]) => k));   // a common piece: more than one fighter has it posed
  for (const who of sorted(Object.keys(fighters), (f) => [truthy(get(fighters[f], 'borrows')), f])) {
    const idn = fighters[who];
    const [cover, unread] = posed(parts, idn, tips);
    notes[who] = { unread };
    const h = createHash('sha256');
    for (const name of ['parts.json', 'identity.json', 'cells.json']) h.update(raw(here(name)), 'latin1');
    for (const wave of [...idn.waves, ...get(idn, 'energyWaves', [])]) {
      const rows = manifestOf(wave).strikes;
      h.update(dumps(rows.map((s) => [s.id, s.combat, s.limb, get(s, 'tip'), get(s, 'path'), s.target, s.weight, get(s, 'legal', []), get(s, 'flags', [])]), { sortKeys: true }), 'utf8');
    }
    const sets = new Set([...cover.values()].map((v) => v.set));
    h.update(dumps(Object.fromEntries(Object.entries(get(tips, 'reaim', {})).filter(([k]) => sets.has(k))), { sortKeys: true }), 'utf8');
    const digest = h.digest('hex');
    const waveOwner = {};   // a pack is his who lists it and does not borrow it
    for (const f2 of sorted(Object.keys(fighters))) {
      for (const w2 of fighters[f2].waves) if (!has(get(fighters[f2], 'borrows', []), w2) && !has(waveOwner, w2)) waveOwner[w2] = f2;
    }
    const ctx = {
      parts, idn, cover, seed, spread, entries: entriesOf(idn), lock: get(lock, who, {}), locks: lock, built: out, fighters, waveOwner, common,
      rejected: get(identity, 'rejected', []).filter((r) => [who, '*'].includes(get(r, 'fighter'))).map((r) => r.shape), changes: {},
    };
    const doc = {
      schema: 'combat.moveset/1',
      _target: `data/combat/movesets/${who}.json`,
      _about: ABOUT,
      fighter: who,
      generator: { version: VERSION, seed, inputs: digest.slice(0, 16) },
      cells: {},
    };
    ctx.done = doc.cells;
    const kit = get(idn, 'kit');
    for (let [, , , cid, cell] of cellIds(cells)) {
      const k = cell.kind;
      if (truthy(kit) && !has(kit.cells, cid) && !['context', 'frame'].includes(k) && !(k === 'string' && has(kit.cells, get(cell, 'from')))) {
        doc.cells[cid] = { kind: k, valid: 0, refused: [], quotas: {}, moves: [], kit: 'not in his kit', ...(has(cell, 'from') ? { from: cell.from } : {}) };
        continue;   // a kit row (the guards): a cell his kit does not name is empty
      }
      if (truthy(kit)) cell = { ...cell, count: Math.trunc(Number(get(kit.cells, cid, get(cell, 'count', 0)))), ...(has(get(kit, 'quotas', {}), cid) ? { quotas: kit.quotas[cid] } : {}) };
      if (k === 'strikes') doc.cells[cid] = strikeCell(ctx, who, cid, cell);
      else if (k === 'string') doc.cells[cid] = burstCell(ctx, who, cid, cell, doc.cells);
      else if (k === 'run') doc.cells[cid] = runCell(ctx, who, cid, cell, doc.cells);
      else if (k === 'travel') doc.cells[cid] = travelCell(ctx, who, cid, cell, doc.cells);
      else if (k === 'table') doc.cells[cid] = tableCell(ctx, who, cid, cell);
      else if (k === 'special') doc.cells[cid] = specialCell(ctx, who, cid, cell);
      else if (k === 'context') doc.cells[cid] = { kind: 'context', pressed: cell.pressed, held: cell.held, asks: get(cell, 'asks', []), _note: 'not generated' };
      else doc.cells[cid] = { kind: 'frame', slots: cell.slots, readings: get(cell, 'readings', {}), asks: get(cell, 'asks', []), _note: cell.what };
    }
    notes[who].changes = ctx.changes;
    doc.generator.inputs = createHash('sha256').update(digest + dumps(lockRows(doc), { sortKeys: true }), 'utf8').digest('hex').slice(0, 16);
    out[who] = doc;
  }
  return { out, parts, identity, cells, notes };
}

/** indent 1, with each move on one line. */
export function dump(doc) {
  const j = (v) => dumps(v, { ensureAscii: false });
  const lines = ['{'];
  const keys = Object.keys(doc);
  keys.forEach((k, i) => {
    const comma = i < keys.length - 1 ? ',' : '';
    if (k !== 'cells') {
      lines.push(` ${j(k)}: ${j(doc[k])}${comma}`);
      return;
    }
    lines.push(' "cells": {');
    const cids = Object.keys(doc.cells);
    cids.forEach((cid, n) => {
      const c = doc.cells[cid];
      const cc = n < cids.length - 1 ? ',' : '';
      if (!has(c, 'moves')) {
        lines.push(`  ${j(cid)}: ${j(c)}${cc}`);
        return;
      }
      lines.push(`  ${j(cid)}: {`);
      const head = Object.fromEntries(Object.entries(c).filter(([k2]) => k2 !== 'moves'));
      lines.push('   ' + j(head).slice(1, -1) + ',');
      lines.push('   "moves": [');
      c.moves.forEach((m, x) => lines.push('    ' + j(m) + (x < c.moves.length - 1 ? ',' : '')));
      lines.push('   ]');
      lines.push('  }' + cc);
    });
    lines.push(' }' + comma);
  });
  lines.push('}');
  return lines.join('\n') + '\n';
}

export function lockRows(doc) {
  const out = {};
  for (const [cid, c] of Object.entries(doc.cells)) {
    if (c.kind === 'strikes' && !truthy(get(c, 'temporary'))) out[cid] = c.moves.map((m) => [m.id, [m.limb, m.tip, m.path, m.target, m.weight], m.keys.level === 'posed' ? m.keys.set : null]);
  }
  return out;
}

export function lockText(out) {
  const lock = {
    schema: 'combat.moveset.lock/1',
    _about: 'The moves that are locked: an id keeps its shape for good, because Animation\'s key sets and Legal\'s screen hang on it. The generator keeps every locked '
      + 'move that is still allowed, fills only the free places, and writes this file again. To start over, run it with --relock (a deliberate act, with its own sheet)',
    fighters: {},
  };
  for (const [who, doc] of Object.entries(out)) lock.fighters[who] = lockRows(doc);
  return dumps(lock, { indent: 1 }) + '\n';
}

// ---------------------------------------------------------------- the checks on what exists

export function recipesPath() {
  if (env.recipes) return env.recipes;
  const parked = join(env.here, '..', 'recipes.brawl.json');
  return existsSync(parked) ? parked : join(env.root, 'data', 'combat', 'recipes.json');
}

/** Everything on disk or in the grammar that matches one of Legal's rows. An empty list is a pass. */
export function legalFindings(docs, parts, identity) {
  const g = parts.strike;
  const bad = [];
  const grammarTargets = new Set(Object.values(g.targets).flatMap((limb) => Object.values(limb).flat()));
  for (const r of g.banned) {
    const keys = Object.keys(r.match);
    const hit = keys.length === 1 && keys[0] === 'target' ? uniqSorted(get(r.match, 'target', []).filter((t) => grammarTargets.has(t))) : [];
    if (hit.length) bad.push(`${r.id}: the grammar has the target ${hit.join(', ')}`);
  }
  for (const [who, doc] of Object.entries(docs)) {
    const idn = identity.fighters[who];
    for (const c of Object.values(doc.cells)) {
      for (const m of get(c, 'moves', [])) {
        const blows = c.kind === 'strikes' ? [m] : c.kind === 'travel' ? [{ ...m.blow, forms: ['light'], arms: 1, flags: m.flags, id: m.id }] : [];
        for (const b of blows) {
          const forms = formsOf(g, b, get(b, 'arms', 1), get(b, 'flags', []));
          for (const r of shapeRows(parts)) {
            if (bannedHit(r, b, forms, get(b, 'arms', 1), { has: get(b, 'flags', []), not: [] }) === 'match') bad.push(`${who}: ${m.id} matches ${r.id}`);
          }
          if (idn.never.some((n) => match(n.shape, b))) bad.push(`${who}: ${m.id} matches one of his never rows`);
          const br = sequenceBreaks(g, [b]);
          if (br.length) bad.push(`${who}: ${m.id} breaks ${br.join(', ')}`);
        }
      }
    }
  }
  for (const [who, doc] of Object.entries(docs)) {
    for (const c of Object.values(doc.cells)) {
      for (const m of get(c, 'moves', [])) {
        let hits = [];
        if (c.kind === 'travel') hits = groupHits(parts, { kind: m.kind, direction: m.direction, exit: m.exit ? m.exit.id.split('.').slice(1).join('.') : null }, 'travel');
        else if (c.kind === 'table') hits = groupHits(parts, m, 'energy');
        if (hits.length) bad.push(`${who}: ${m.id} matches ${hits.join(', ')}`);
        if (c.kind === 'run') {   // a mashed run of point-blank bolts: Legal's e09
          const byId = Object.fromEntries(doc.cells[c.from].moves.map((x) => [x.id, reachBlow(parts, x)]));
          const seq = m.blows.map((i) => get(byId, i));
          const loop = truthy(get(c, 'loop'));
          const br = seq.includes(null) ? [`a bolt that is not in ${c.from}`] : reachRunBreaks(parts, [...seq, ...(loop ? seq : [])], [...m.arms, ...(loop ? m.arms : [])]);
          if (br.length) bad.push(`${who}: ${m.id} breaks ${br.join('; ')}`);
        }
        if (c.kind === 'string') {   // a burst: every blow of its gap's class, and the whole string inside Legal's rules and the burst's own
          const bu = g.burst;
          const byId = Object.fromEntries(doc.cells[c.from].moves.map((x) => [x.id, x]));
          const seq = m.blows.map((i) => get(byId, i));
          if (seq.includes(null)) {
            bad.push(`${who}: ${m.id} names a blow that is not in ${c.from}`);
            continue;
          }
          let br = runBreaks(bu.noStutter, seq).concat(uniqSorted(seq.flatMap((_, i) => stringBreaks(parts, seq.slice(Math.max(0, i - 2), i + 1)))));
          br = br.concat(seq.map((n, i) => [n, m.slots[i]]).filter(([n, cl]) => cl !== undefined && !match(bu.classes[cl].when, n)).map(([, cl]) => `class ${cl}`));
          for (const r of get(get(parts, 'legal', {}), 'flurry', [])) {   // Legal's f04: the fastest gaps run for a few blows only
            if (get(r, 'kind') === 'slots') {
              let run = 0;
              let longest = 0;
              for (const cl of m.slots) {
                run = cl === r.class ? run + 1 : 0;
                longest = Math.max(longest, run);
              }
              if (longest > r.maxRun) br.push(r.id);
            }
          }
          if (br.length) bad.push(`${who}: ${m.id} breaks ${br.join(', ')}`);
        }
      }
    }
  }
  const lg = get(parts, 'legal', {});
  for (const [who, idn] of Object.entries(identity.fighters)) {
    for (const hand of Object.keys(get(get(idn, 'energy', {}), 'hands', {}))) {
      const hits = groupHits(parts, { hand, delivery: 'bolt', release: 'thrust' }, 'energy');
      if (hits.length) bad.push(`${who}: the energy hand ${hand} matches ${hits.join(', ')}`);
    }
  }
  for (const r of get(lg, 'grabs', [])) {
    if (get(r, 'kind') === 'holdPoints') {
      const hit = uniqSorted(get(get(parts, 'grab', {}), 'holdPoints', []).filter((p) => r.never.includes(p)));
      if (hit.length) bad.push(`${r.id}: a grab may hold the ${hit.join(', ')}`);
      if (has(r, 'grab')) {
        const mine = get(get(get(parts, 'grab', {}), 'kinds', {}), r.grab);
        if (mine === null || !mine.every((p) => r.allowed.includes(p))) bad.push(`${r.id}: the ${r.grab} may hold only the ${r.allowed.join(', ')}`);
      }
    }
  }
  const lf = join(env.root, 'docs', 'legal', 'movegen-banned.json');
  if (existsSync(lf)) {   // nothing of Legal's is dropped or loosened in the copy the generator reads
    const theirs = load(lf);
    if (!eq(get(theirs, 'banned'), g.banned)) bad.push('parts.json strike.banned differs from docs/legal/movegen-banned.json');
    const mineSeq = Object.fromEntries(g.bannedSequences.map((r) => [r.id, [r.rule, r.why]]));
    for (const r of get(theirs, 'bannedSequences', [])) {
      if (!eq(get(mineSeq, r.id), [r.rule, r.why])) bad.push(`sequence rule ${r.id} differs from Legal's file`);
    }
    for (const [group, rows] of Object.entries(theirs)) {
      if (['schema', '_about', 'banned', 'bannedSequences'].includes(group) || !has(get(lg, 'mirrored', []), group)) continue;
      if (!Array.isArray(rows)) {   // a block that is not rows (heldScope): the copy must be the same
        if (!eq(get(lg, group), rows)) bad.push(`Legal's block ${group} is missing from parts.json or differs`);
        continue;
      }
      const mine = Object.fromEntries(get(lg, group, []).map((r) => [r.id, [get(r, 'rule'), get(r, 'why')]]));
      for (const r of rows) {
        if (!eq(get(mine, r.id), [get(r, 'rule'), get(r, 'why')])) bad.push(`Legal's row ${r.id} (${group}) is missing from parts.json or differs`);
      }
    }
  }
  for (const [p, nexts] of Object.entries(g.links)) {
    for (const q of nexts) {
      const br = sequenceBreaks(g, [{ path: p }, { path: q }]).filter((b) => b === 's04' || b === 's05');
      if (br.length) bad.push(`links: ${p} then ${q} breaks ${br.join(', ')}`);
    }
  }
  const rp = recipesPath();
  if (existsSync(rp)) {
    for (const [name, steps] of Object.entries(get(load(rp), 'blurPatterns', {}))) {
      const seq = steps.map((s) => ({ limb: s[0], target: s[1] }));
      const br = sequenceBreaks(g, [...seq, ...seq.slice(0, 2)]);
      if (br.length) bad.push(`blur pattern ${name} (${relative(env.root, rp).split(sep).join('/')}) breaks ${br.join(', ')}`);
    }
  }
  return bad;
}

/** The parked recipes' pools by button, when the file has them: every pool that `brawl`, `burst` and `fallback` name exists for every fighter; every light a
 * tap can throw can open a whole burst from the burst's pools; each sample is one. Judged on the pieces table: limb, path and target. */
export function recipesFindings(parts) {
  const rp = recipesPath();
  const rec = existsSync(rp) ? load(rp) : {};
  const bu = get(rec, 'burst');
  if (!truthy(bu)) return [];
  const g = parts.strike;
  const bad = [];
  const legal = { bannedSequences: g.bannedSequences.map((r) => (r.id === 's01' ? { ...r, same: ['limb', 'path'] } : r)) };
  const rules = bu.rules.map((r) => ({ ...r, kind: truthy(get(r, 'once')) ? 'once' : 'run' }));
  const brawl = get(rec, 'brawl', {});
  const named = uniqSorted([...Object.entries(brawl).filter(([k]) => !k.startsWith('_')).map(([, v]) => v), ...Object.values(bu.pools), ...Object.values(get(get(rec, 'fallback', {}), 'lower', {}))]);
  for (const [who, pools] of sorted(Object.entries(rec.pools), (e) => e[0])) {
    const missing = named.filter((n) => !has(pools, n));
    if (missing.length) {
      bad.push(`recipes: ${who} has no pool ${missing.join(', ')}`);
      continue;
    }
    const rows = (name) => pools[name].filter((e) => e.status !== 'waiting').map((e) => {
      const r = rec.pieces[e.id];
      return { id: e.id, limb: r.limb, path: r.path, target: r.target.startsWith('arm') ? 'arm' : r.target, step: [] };
    });
    const by = Object.fromEntries(Object.entries(bu.pools).map(([cl, pn]) => [cl, rows(pn)]));
    const ok = (seq) => !runBreaks(rules, seq).length && !seq.some((_, i) => sequenceBreaks(legal, seq.slice(Math.max(0, i - 2), i + 1)).length);
    const fill = (seq) => {
      if (seq.length === bu.slots.length) return seq;
      for (const n of by[bu.slots[seq.length]]) {
        if (!runBreaks(rules, [...seq, n]).length && !sequenceBreaks(legal, [...seq.slice(-2), n]).length) {
          const got = fill([...seq, n]);
          if (got) return got;
        }
      }
      return null;
    };
    const openers = new Map();
    for (const k of ['light', 'lightToward', 'flurry', 'skill']) if (has(brawl, k)) for (const r of rows(brawl[k])) openers.set(r.id, r);
    const cant = sorted([...openers.keys()]).filter((i) => fill([openers.get(i)]) === null);
    if (cant.length) bad.push(`recipes: ${who} cannot open a whole burst with ${cant.join(', ')}`);
    const every = new Map();
    for (const cl of Object.keys(by)) for (const r of by[cl]) every.set(r.id, r);
    for (const [k, v] of openers) every.set(k, v);
    for (const [lean, ids] of sorted(Object.entries(get(get(bu, 'samples', {}), who, {})), (e) => e[0])) {
      const seq = ids.map((i) => every.get(i) || null);
      const pairs = seq.map((n, i) => [n, bu.slots[i]]).slice(1);
      if (seq.includes(null) || seq.length !== bu.slots.length || pairs.some(([n, cl]) => cl === undefined || !by[cl].some((x) => x.id === n.id)) || !ok(seq)) {
        bad.push(`recipes: ${who}'s burst sample for the lean ${lean} is not a whole burst under the rules`);
      }
    }
  }
  return bad;
}

/** Each key set a fighter's energy rules name is a row of the pack they name, drawn on the path and the place the rule says. */
export function identityFindings(parts, identity) {
  const bad = [];
  for (const [who, idn] of sorted(Object.entries(identity.fighters), (e) => e[0])) {
    for (const rule of get(get(get(idn, 'energy', {}), 'reach', {}), 'posed', [])) {
      const mp = anim('waves', rule.wave + '.manifest.json');
      const rows = existsSync(mp) ? Object.fromEntries(load(mp).strikes.map((s) => [s.id, s])) : {};
      const s = get(rows, rule.set);
      const want = [parts.reach.path[rule.when.release[0]], rule.when.target[0]];
      if (s === null || ![rule.strike, get(rule, 'strikeNow')].includes(get(s, 'combat')) || !eq([get(s, 'path'), get(s, 'target')], want)) {
        bad.push(`${who}: the energy key set ${rule.set} is not in ${rule.wave} as ${rule.strike} on a ${want[0]} to the ${want[1]}`);
      }
    }
  }
  return bad;
}

/** Rows of the hand-kept tables that say the same thing twice. */
export function dataFindings(parts) {
  const bad = [];
  for (const [kind, k] of sorted(Object.entries(get(get(parts, 'travel', {}), 'kinds', {})), (e) => e[0])) {
    const rows = k.moves.map((mv) => dumps(mv, { sortKeys: true }));
    if (rows.length !== new Set(rows).size) bad.push(`parts.json travel.kinds.${kind} lists a move twice`);
  }
  return bad;
}

export function slim(m, btn) {
  return { id: m.id, limb: m.limb, tip: m.tip, path: m.path, target: m.target, weight: m.weight, arms: m.arms, step: m.step, button: btn };
}

/** For each pool of pl (button -> blows): after every two blows of all the pools that Legal's string rules allow, how many of the pool may come next, never one
 * of the last two. Also the share of blind pairs that break a rule. */
export function afterTwo(parts, pl) {
  const g = parts.strike;
  const allb = Object.values(pl).flat();
  const pair = new Map();
  for (const a of allb) for (const b of allb) if (a !== b) pair.set(a.id + '\u0001' + b.id, !stringBreaks(parts, [a, b]).length);
  const runs3 = [];
  for (const r of g.bannedSequences) {
    if (r.kind !== 'run') continue;
    for (const [flt, cap] of [[{}, r.max], ...get(r, 'tighter', []).map((t) => [t.when, t.max])]) if (cap === 2) runs3.push([r.same, flt]);
  }
  const thirdOk = (p1, p2, n) => {
    if (!pair.get(p2.id + '\u0001' + n.id)) return false;
    return !runs3.some(([same, flt]) => same.every((k) => has(n, k) && eq(get(p1, k), get(p2, k)) && eq(get(p2, k), n[k])) && match(flt, n));
  };
  const counts = Object.fromEntries(Object.keys(pl).map((b) => [b, []]));
  for (const p1 of allb) {
    for (const p2 of allb) {
      if (p1 !== p2 && pair.get(p1.id + '\u0001' + p2.id)) {
        for (const [b, pool] of Object.entries(pl)) counts[b].push(pool.filter((n) => n.id !== p1.id && n.id !== p2.id && thirdOk(p1, p2, n)).length);
      }
    }
  }
  const broken = [...pair.values()].filter((v) => !v).length;
  return [counts, (100.0 * broken) / Math.max(1, pair.size)];   // the second is printed "%.1f" (py.fixed1), as Python's round(x, 1) then "%.1f"
}

/** What the martial pools give a string, for each fighter. */
export function stringReport(docs, parts, cells) {
  const rep = {};
  const hold = get(get(get(get(cells.stances, 'martial', {}), 'x', {}), 'presses', {}), 'hold');
  for (const [who, doc] of sorted(Object.entries(docs), (e) => e[0])) {
    const c = doc.cells;
    const pools = {};
    const today = {};
    for (const btn of ['x', 'y', 'b']) {
      const cell = get(c, 'martial.' + btn);
      if (truthy(cell) && cell.kind === 'strikes') {
        pools[btn] = cell.moves.filter((m) => btn !== 'y' || m.forms.includes('quick')).map((m) => slim(m, btn));
        const keep = new Set(cell.moves.filter((m) => m.status !== 'waiting').map((m) => m.id));
        today[btn] = [...pools[btn].filter((m) => keep.has(m.id)), ...get(get(c, `martial.${btn}.standin`, {}), 'moves', []).map((m) => slim(m, btn))];
      }
    }
    const rx = get(c, 'energy.x.reach');
    if (truthy(rx)) {   // energy in reach: a point-blank bolt takes a light's place in a string
      pools.rx = rx.moves.map((m) => reachBlow(parts, m));
      today.rx = pools.rx.filter((m, i) => rx.moves[i].status !== 'waiting');
    }
    const [counts, blind] = afterTwo(parts, pools);
    const [countsToday] = afterTwo(parts, today);
    const mix = {};
    for (const b of Object.keys(pools)) {
      mix[b] = { pool: pools[b].length, fewest: Math.min(...counts[b]), median: [...counts[b]].sort((x, y) => x - y)[Math.floor(counts[b].length / 2)],
        today: today[b].length, todayFewest: countsToday[b].length ? Math.min(...countsToday[b]) : 0 };
    }
    rep[who] = { mix, blind };
    if (truthy(rx) && has(get(parts, 'reach', {}), 'run')) {
      // The search is depth first with a budget, and the key only orders its tries, so one key that runs out is not a proof that no run
      // exists: up to seven more keys are tried (the port's one change from the reference; a fighter it passed on the first key is as before).
      const n = parts.reach.run.proof;
      const bolts = rx.moves.map((m) => reachBlow(parts, m));
      let made = false;
      for (let k = 0; k < 8 && !made; k++) made = reachRun(parts, bolts, n, k ? [who, 'proof', k] : [who, 'proof']) !== null;
      rep[who].run = { bolts: rx.moves.length, length: n, made };
    }
    if (has(c, 'martial.b') && c['martial.b'].kind === 'strikes') {
      const sends = Object.values(get(get(parts.strike.heavy, 'launcher', {}), 'aim', {}));
      const tier = {};
      const standIns = {};
      for (const sd of sends) {
        if (has(tier, sd)) continue;
        tier[sd] = c['martial.b'].moves.filter((m) => m.forms.includes('launch') && m.sends === sd).map((m) => m.id.split('.').pop());
        standIns[sd] = get(get(c, 'martial.b.standin', {}), 'moves', []).filter((m) => m.forms.includes('launch') && m.sends === sd).map((m) => m.keys.set);
      }
      rep[who].launch = { tier, standIns };
      const limbs = uniqSorted(Object.values(get(get(parts.strike.heavy, 'launcher', {}), 'wrench', {})));
      rep[who].wrench = Object.fromEntries(limbs.map((lb) => [lb, c['martial.b'].moves.filter((m) => m.forms.includes('wrench') && m.target === lb).map((m) => m.id.split('.').pop())]));
    }
    if (truthy(hold) && get(get(c, 'martial.x', {}), 'kind') === 'strikes') {
      const pool = c['martial.x'].moves.filter((m) => m.status !== 'waiting').map((m) => slim(m, 'x'));
      const opens = pool.filter((n) => burstFill(parts, pool, hold.slots, [n]) !== null);
      rep[who].burst = { lights: pool.length, openers: opens.length, fewestSecond: Math.min(...pool.map((n) => burstNext(parts, pool, [n], hold.slots[1]).length)),
        byClass: Object.fromEntries(['fast', 'mid', 'slow'].map((cl) => [cl, pool.filter((n) => match(parts.strike.burst.classes[cl].when, n)).length])) };
    }
  }
  return rep;
}

/** The part of a fighter's blows that are pieces only he has. */
export function blowShare(pools, mix, weight = 1.0) {
  let got = 0.0;
  for (const [c, [mine, every]] of Object.entries(pools)) {
    if (every > 0) got += (get(mix, c, 0.0) * (mine * weight)) / (mine * weight + (every - mine));
  }
  return got / Object.values(mix).reduce((a, b) => a + b, 0);
}

/** Game Design's gate (fighter-pipeline.md section 1): of the blows a fighter throws, the part that are pieces only he has. */
export function gateShares(out, cells, identity) {
  const g = cells.gate;
  const fs = identity.fighters;
  const sources = uniqSorted(Object.values(g.cells).map((spec) => spec.from));
  const sharedCells = new Set([...cellIds(cells)].filter(([, , , , cell]) => truthy(get(cell, 'share'))).map(([, , , cid]) => cid));
  const piece = (m) => {
    const k = get(m, 'keys', {});
    if (has(k, 'strike')) return JSON.stringify(['reach', k.strike, get(m, 'hand')]);
    return JSON.stringify(truthy(get(k, 'from')) ? ['strike', k.from] : ['shape', m.limb, m.tip, m.path, m.target, m.weight]);
  };
  const thrown = (m, planned) => m.status === 'posed' || (planned && m.status === 'waiting' && truthy(get(m, 'own')));
  const res = {};
  for (const [who, doc] of Object.entries(out)) {
    if (truthy(get(fs[who], 'kit'))) continue;   // a kit row (the guards) is outside the gate
    const alt = get(fs[who], 'alt');
    const others = sorted(Object.keys(out)).filter((o) => o !== who && !truthy(get(fs[o], 'kit')) && !(truthy(alt) && eq(get(fs[o], 'alt'), alt)));
    const groups = new Map();
    for (const o of others) {
      const k = truthy(get(fs[o], 'alt')) ? fs[o].alt : '#' + o;
      if (!groups.has(k)) groups.set(k, []);
      groups.get(k).push(o);
    }
    const worlds = [...product([...groups.values()])];
    const share = (planned, weight) => {
      let worst = 1.0;
      for (const w of worlds) {
        const theirs = new Set();
        for (const o of w) for (const cid of sources) for (const m of get(get(out[o].cells, cid, {}), 'moves', [])) if (thrown(m, planned)) theirs.add(piece(m));
        const pools = {};
        for (const [cell, spec] of Object.entries(g.cells)) {
          const ms = get(get(doc.cells, spec.from, {}), 'moves', []).filter((m) => thrown(m, planned)
            && (!has(spec, 'form') || get(m, 'forms', []).includes(spec.form)) && (!has(spec, 'filter') || match(spec.filter, m)));
          const mine = ms.filter((m) => (truthy(get(m, 'own')) || !sharedCells.has(spec.from)) && !theirs.has(piece(m)));
          pools[cell] = [mine.length, ms.length];
        }
        worst = Math.min(worst, blowShare(pools, g.mix, weight));
      }
      return worst;
    };
    const baseW = Number(get(g, 'ownWeight', 1));
    const need = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10].find((x) => share(true, x) >= g.quarter);
    res[who] = { today: share(false, baseW), planned: share(true, baseW), weight: need === undefined ? null : need };
  }
  return res;
}

/** Under a fifth, he gets more of his own or his weights change (Game Design): a failure. */
export function gateFindings(gate, cells) {
  const g = get(cells, 'gate', {});
  return sorted(Object.entries(gate), (e) => e[0]).filter(([, r]) => r.planned < g.fifth).map(([who, r]) => `${who}: ${round(100 * r.planned)}% of his blows would be pieces only he has, under a fifth${
    r.weight ? `: a quarter needs his own drawn ${r.weight} times as often` : ': no weight on his own reaches a quarter'}`);
}

export function gateLine(gate, cells) {
  const g = get(cells, 'gate', {});
  if (!truthy(gate)) return '';
  const word = (r) => (r.planned >= g.quarter ? '' : r.planned >= g.fifth ? ' (short of a quarter)' : ' (UNDER a fifth)');
  return 'own blows: ' + sorted(Object.entries(gate), (e) => e[0]).map(([who, r]) => `${who} ${round(100 * r.planned)}%${word(r)}`).join(', ');
}

/** A cell with a share rule keeps it for every fighter. */
export function shareFindings(out, cells, identity) {
  const bad = [];
  for (const [, , , cid, cell] of cellIds(cells)) {
    const sh = get(cell, 'share');
    if (!truthy(sh)) continue;
    for (const [who, doc] of Object.entries(out)) {
      if (truthy(get(identity.fighters[who], 'kit'))) continue;
      const q = doc.cells[cid].quotas;
      const need = Math.trunc(Number(sh.own[String(get(identity.fighters[who], 'tier', 1))]));
      if (get(q, 'his alone', 0) < need) bad.push(`${who}: ${cid} has ${get(q, 'his alone', 0)} pieces that are his alone, and his tier needs ${need}`);
      const cap = Math.trunc(cell.count * sh.maxWithOne);
      for (const [k, v] of Object.entries(q)) {
        if (k.startsWith('shared with ') && v > cap) bad.push(`${who}: ${cid} shares ${v} with ${k.slice(12)}, more than ${cap}`);
      }
    }
  }
  return bad;
}

export function stringFindings(rep, identity = null) {
  const bad = [];
  const fsOf = (who) => get(get(identity || {}, 'fighters', {}), who, {});
  for (let [who, r] of sorted(Object.entries(rep), (e) => e[0])) {
    if (truthy(get(fsOf(who), 'kit'))) {   // a kit row (the guards): only his strings of lights and mediums are read
      r = { ...r, run: null, launch: {}, wrench: {}, mix: Object.fromEntries(Object.entries(r.mix).filter(([b]) => b === 'x' || b === 'y')) };
    }
    for (const [b, v] of Object.entries(r.mix)) {
      const floor = b === 'rx' ? 1 : FLOOR;
      if (v.fewest < floor) bad.push(`${who}: after some two blows only ${v.fewest} of his ${v.pool} on ${b.toUpperCase()} may follow; the floor is ${floor}`);
    }
    if (truthy(get(r, 'run')) && !r.run.made) bad.push(`${who}: his ${r.run.bolts} point-blank bolts cannot make a run of ${r.run.length} by e09`);
    for (const [sd, ids] of sorted(Object.entries(get(get(r, 'launch', {}), 'tier', {})), (e) => e[0])) {
      if (!ids.length) bad.push(`${who}: no heavy of his tier is a launcher that sends ${sd}`);
    }
    for (const [lb, ids] of sorted(Object.entries(get(r, 'wrench', {})), (e) => e[0])) {
      if (!ids.length && !get(fsOf(who), 'waives', []).includes('wrench.' + lb)) bad.push(`${who}: no heavy of his tier lands on the ${lb === 'arm' ? 'arm' : lb}, so he cannot wrench it`);
    }
    const bu = get(r, 'burst');
    if (truthy(bu) && bu.openers < bu.lights) bad.push(`${who}: ${bu.lights - bu.openers} of his ${bu.lights} lights cannot open a whole burst`);
  }
  return bad;
}

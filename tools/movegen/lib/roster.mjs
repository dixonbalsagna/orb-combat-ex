// Proposals: generated movesets for fighters who are not in the build, as templates for Orb. Ported from Combat's roster builder
// (docs/combat/pending/roster/build_roster.py): each proposal row is laid over the build row it is `like`, the rows are put beside
// the build's identity in a temporary folder with its parts and cells, and the generator runs there. The two fighters of the build
// are generated too, since the share rule needs them, and their moves must come out as they are in the build's folder, or this stops.
import { copyFileSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { configure, dump, load, manifestOf } from './generator.mjs';
import { dumps, eq, get, has, sorted } from './py.mjs';

const clone = (v) => JSON.parse(JSON.stringify(v));

/** The lights and mediums that more than one fighter of the build has posed: the common pool as it stands. */
export function commonIds(base) {
  const seen = new Map();
  for (const [who, d] of Object.entries(base)) {
    for (const w of d.waves) {
      if (get(d, 'tierWaves', []).includes(w)) continue;
      for (const s of manifestOf(w).strikes) {
        if (!seen.has(s.combat)) seen.set(s.combat, new Set());
        seen.get(s.combat).add(who);
      }
    }
  }
  return sorted([...seen].filter(([, v]) => v.size > 1).map(([k]) => k));
}

/** A proposal row as a full identity row: the row it is `like`, with what the proposal says laid over it. */
export function resolve(row, base, fileDoc, borrowing = 'common') {
  const out = clone(base[row.like]);
  for (const k of ['reaimed', '_reaimed', '_pinned', '_tipOf', '_tipFlags', '_waves', '_tierWaves', 'adds', '_adds', 'cellQuotas', '_cellQuotas', 'chargedHeavy', '_chargedHeavy', 'skillAlso', '_skillAlso']) delete out[k];   // his named pieces are his alone
  Object.assign(out, { pinned: {}, tipOf: {}, tipFlags: {} });
  out.armsOf = {};
  for (const b of Object.values(base)) Object.assign(out.armsOf, get(b, 'armsOf', {}));
  const packs = [...get(row, 'waves', fileDoc.packs)];
  out.waves = packs;
  out.tierWaves = packs.filter((w) => Object.keys(base).some((b) => get(base[b], 'tierWaves', []).includes(w)));
  out.borrows = [...get(row, 'borrows', packs)];
  for (const [k, v] of Object.entries(row)) {
    if (['like', 'energy', 'waves', 'borrows'].includes(k)) continue;
    out[k] = clone(v);
  }
  const en = get(row, 'energy', {});
  for (const [k, v] of Object.entries(en)) if (k !== 'reach') out.energy[k] = clone(v);
  if (has(en, 'reach')) {   // energy in reach by name: key sets of the fighters in the build, until his own are drawn
    const r = fileDoc.reach[en.reach];
    out.energy.reach = Object.fromEntries(Object.entries(r).filter(([k]) => k !== 'energyWaves').map(([k, v]) => [k, clone(v)]));
    out.energy.reach._borrowed = `the \`${en.reach}\` set of ${fileDoc._path}: nothing of his own is drawn`;
    out.energyWaves = [...r.energyWaves];
  }
  if (borrowing === 'common') out.borrowIds = commonIds(base);
  out.specials = clone(base.protagonist.specials);
  out.specials._about = "PLACEHOLDERS, taken from the Protagonist's placeholders so that the charging row is not empty: his specials are not designed";
  return out;
}

/**
 * Generate the proposals of `proposalsPath` beside the build of `baseDir`, with `generate` (movegen.mjs). check: compare with the
 * files in outDir instead of writing. Returns { lines, ok, written }.
 */
export function propose({ generate, root, baseDir, proposalsPath, outDir, check = false, recipes }) {
  configure({ root, here: baseDir, recipes });
  const baseIdn = load(join(baseDir, 'identity.json'));
  const doc = load(proposalsPath);
  const src = load(join(root, doc.base));   // the packs, the borrowing policy and the named energy-in-reach sets the roster sketches use
  src._path = doc.base;
  const rows = doc.fighters;
  const keys = Object.keys(rows).filter((k) => !k.startsWith('_'));
  const borrowing = get(doc, 'borrowing', get(src, 'borrowing', 'common'));
  const lines = [];
  const tmp = mkdtempSync(join(tmpdir(), 'movegen-proposals-'));
  try {
    const idn = clone(baseIdn);
    for (const k of keys) {
      if (has(baseIdn.fighters, k)) throw new Error(`${k} is a fighter of the build`);
      idn.fighters[k] = resolve(rows[k], baseIdn.fighters, src, borrowing);
    }
    for (const n of ['parts.json', 'cells.json']) copyFileSync(join(baseDir, n), join(tmp, n));
    writeFileSync(join(tmp, 'identity.json'), dumps(idn, { indent: 1, ensureAscii: false }) + '\n');
    const lock = load(join(baseDir, 'lock.json'));
    const lp = join(outDir, 'lock.proposals.json');
    if (existsSync(lp)) for (const [k, v] of Object.entries(load(lp).fighters)) if (keys.includes(k)) lock.fighters[k] = v;
    writeFileSync(join(tmp, 'lock.json'), dumps(lock, { indent: 1 }) + '\n');
    const run = () => generate({ dir: tmp, recipes, live: join(tmp, 'no-live-recipes.json') });
    let r;
    if (check) {
      for (const k of keys) if (existsSync(join(outDir, `moveset.${k}.json`))) copyFileSync(join(outDir, `moveset.${k}.json`), join(tmp, `moveset.${k}.json`));
      for (const k of Object.keys(baseIdn.fighters)) copyFileSync(join(baseDir, `moveset.${k}.json`), join(tmp, `moveset.${k}.json`));
      r = run();
    } else {
      // twice: the first run locks every proposal's moves, and the second counts what each shares with the others now that all are locked
      for (let again = 0; again < 2; again++) {
        r = run();
        const stop = [...r.fresh, ...r.names, ...r.dead, ...r.data];
        if (stop.length) {
          lines.push('the generator refused: nothing is written', ...stop.map((b) => '  ' + b));
          return { lines, ok: false, written: [] };
        }
        for (const [n, t] of Object.entries(r.files)) writeFileSync(join(tmp, n), t, 'utf8');
      }
    }
    const moved = Object.keys(baseIdn.fighters).filter((k) => {
      const a = load(join(baseDir, `moveset.${k}.json`)).cells;
      const b = JSON.parse(r.files[`moveset.${k}.json`]).cells;
      return Object.keys(a).some((cid) => !eq(get(a[cid], 'moves'), get(b[cid] || {}, 'moves')));
    });
    const stale = keys.filter((k) => !existsSync(join(outDir, `moveset.${k}.json`)) || !eq(load(join(outDir, `moveset.${k}.json`)).cells, JSON.parse(r.files[`moveset.${k}.json`]).cells));
    const sheetStale = !existsSync(join(outDir, 'review-sheet.md')) || readFileSync(join(outDir, 'review-sheet.md'), 'utf8') !== r.files['review-sheet.md'];
    const bad = [...r.fresh, ...r.names];
    lines.push('proposals: ' + (check ? (!stale.length && !sheetStale ? 'up to date' : 'OUT OF DATE: ' + [...stale, ...(sheetStale ? ['review-sheet.md'] : [])].join(', ')) : 'generated ' + keys.join(', ')));
    lines.push('the two in the build: ' + (!moved.length ? 'their moves are as in the build' : 'MOVED: ' + moved.join(', ')));
    lines.push("Legal's rows and names: " + (!bad.length ? 'no match' : `${bad.length} MATCH`), ...bad.map((b) => '  ' + b));
    lines.push('strings and shares: ' + (!r.dead.length ? 'no dead end' : `${r.dead.length} PROBLEM`), ...r.dead.map((b) => '  ' + b));
    lines.push("own blows, of the gate's quarter (today; with his own drawn; the draw weight on his own that reaches a quarter):");
    const fifth = r.cells.gate.fifth;
    const quarter = r.cells.gate.quarter;
    const under = [];
    for (const k of sorted(Object.keys(r.gate), (f) => [!has(baseIdn.fighters, f), f])) {
      const g = r.gate[k];
      const pct = (x) => String(Math.round(100 * x)).padStart(3) + '%';
      if (keys.includes(k) && g.planned < fifth) under.push(k);
      lines.push(`  ${k.padEnd(15)} ${pct(g.today)}  ${pct(g.planned)}  ${g.weight ? 'x' + g.weight : 'none reaches it'}${g.planned >= quarter ? '' : g.planned >= fifth ? '  short of a quarter' : '  UNDER a fifth'}`);
    }
    const ok = !moved.length && !bad.length && !r.dead.length && !under.length && (!check || (!stale.length && !sheetStale));
    const written = [];
    if (!check && ok) {
      for (const k of keys) {
        writeFileSync(join(outDir, `moveset.${k}.json`), r.files[`moveset.${k}.json`], 'utf8');
        written.push(`moveset.${k}.json`);
      }
      const newLock = JSON.parse(r.files['lock.json']);
      writeFileSync(lp, dumps({
        schema: newLock.schema,
        _about: 'GENERATED by tools/movegen/movegen.mjs --propose: the ids and shapes of the proposals\' strike moves, so an id never changes shape. The two fighters of the build are locked in docs/combat/pending/movegen/lock.json',
        fighters: Object.fromEntries(keys.filter((k) => has(newLock.fighters, k)).map((k) => [k, newLock.fighters[k]])),
      }, { indent: 1 }) + '\n');
      writeFileSync(join(outDir, 'review-sheet.md'), r.files['review-sheet.md'], 'utf8');
      written.push('lock.proposals.json', 'review-sheet.md');
    }
    return { lines, ok, written, result: r, keys };
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
}

export { dump };

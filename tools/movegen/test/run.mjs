#!/usr/bin/env node
// The moveset generator's own tests: node tools/movegen/test/run.mjs. Exit 1 on any failure. No network, no clock.
//   1. the reference self-test (91 cases: the refusals on made-up moves and strings)
//   2. Legal's banned list: every row of docs/legal/movegen-banned.json is in parts.json; every shape row refuses a move made to match it;
//      every sequence rule is applied; a dropped or loosened row stops the generator; a banned move planted in a file on disk is found
//   3. names: Legal's word lists are read; a name built on one of their words is caught; every generated name passes
//   4. determinism: the same inputs give the same bytes, twice in one process and in two processes
//   5. the golden: --check on the build's folder and on the proposals (the files are what the inputs give, byte for byte)
//   6. the schemas: every schema uses supported keywords only, and every generated file and new block validates
//   7. coverage: every piece of a live brawl pool is generated, and the pool rules name real cells and quotas
//   8. parity with the Python reference (when python3 is on the path): a full --relock gives the same bytes in both
import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DEFAULT_DIR, ROOT, generate } from '../movegen.mjs';
import { bannedHit, build, configure, formsOf, legalFindings, sequenceBreaks, shapeRows } from '../lib/generator.mjs';
import { legalWords, namesFindings, screenName } from '../lib/names.mjs';
import { makeExpect, selfTest } from '../lib/selftest.mjs';

const require = createRequire(import.meta.url);
const { validate, checkSchema } = require('../../lib/schema.js');
const HERE = dirname(fileURLToPath(import.meta.url));
const CLI = join(HERE, '..', 'movegen.mjs');
const PROPOSALS = join(ROOT, 'docs', 'combat', 'proposals', 'identity.proposals.json');
const RECIPES = join(DEFAULT_DIR, '..', 'recipes.brawl.json');
const quiet = process.argv.includes('--quiet');

let failed = 0;
let passed = 0;
const check = (name, ok, detail = '') => {
  if (ok) passed += 1;
  else failed += 1;
  if (!ok || !quiet) console.log(`${ok ? 'pass' : 'FAIL'}  ${name}${ok || !detail ? '' : '\n      ' + detail}`);
};
const node = (args) => spawnSync(process.execPath, [CLI, ...args], { encoding: 'utf8', cwd: ROOT });
const tmp = (prefix) => mkdtempSync(join(tmpdir(), `movegen-test-${prefix}-`));
const load = (p) => JSON.parse(readFileSync(p, 'utf8'));

// 1. the reference self-test
{
  configure({ root: ROOT, here: DEFAULT_DIR });
  const { parts, identity } = build();
  const lines = [];
  const { expect, state } = makeExpect((l) => lines.push(l));
  selfTest(parts, identity, expect);
  check(`the reference self-test: ${state.n} cases, as many as gen_moveset.py --self-test`, state.ok && state.n === 91, state.failed.join('; '));
}

// 2. Legal's banned list
{
  configure({ root: ROOT, here: DEFAULT_DIR, recipes: RECIPES });
  const { out, parts, identity } = build();
  const g = parts.strike;
  const theirs = load(join(ROOT, 'docs', 'legal', 'movegen-banned.json'));
  const mirror = legalFindings({}, parts, identity).filter((b) => /differs|missing/.test(b));
  check("every row of Legal's file is in parts.json, word for word (banned, bannedSequences and each mirrored group)", mirror.length === 0, mirror.join('; '));
  check("parts.json strike.banned is Legal's banned list exactly", JSON.stringify(theirs.banned) === JSON.stringify(g.banned));
  // every shape row refuses a move made to match it: the row's first value of each part, its flags present, its form
  const tipsOf = (limb) => [...Object.keys(g.tips[limb] || {}), ...Object.keys((g.heavy && g.heavy.tips[limb]) || {})];
  const probe = (row) => {
    const mt = row.match;
    const limb = (mt.limb || ['hand'])[0];
    const tips = tipsOf(limb);
    const tip = mt.tip ? (mt.tip.find((t) => tips.includes(t)) || tips[0]) : tips[0];
    const m = { limb, tip, path: (mt.path || ['line'])[0], target: (mt.target || ['chest'])[0], weight: (mt.weight || ['light'])[0] };
    for (const [k, v] of Object.entries(mt)) if (!['limb', 'tip', 'path', 'target', 'weight', 'arms', 'flags', 'form'].includes(k)) m[k] = v[0];
    const arms = (mt.arms || [1])[0];
    const forms = mt.form ? [...mt.form] : formsOf(g, m, arms);
    return { m, arms, forms, flags: { has: [...(mt.flags || [])], not: [] } };
  };
  const notRefused = [];
  for (const row of shapeRows(parts)) {
    const p = probe(row);
    if (bannedHit(row, p.m, p.forms, p.arms, p.flags) !== 'match') notRefused.push(row.id);
  }
  check(`every shape row of Legal's (${shapeRows(parts).length}) refuses a move made to match it`, notRefused.length === 0, notRefused.join(', '));
  const ordinary = { limb: 'hand', tip: 'fist', path: 'line', target: 'chest', weight: 'light' };
  const clean = shapeRows(parts).filter((r) => bannedHit(r, ordinary, ['light', 'flurry'], 1, { has: [], not: g.flags.byVocabulary.concat(g.flags.fromAnimation) }) === 'match').map((r) => r.id);
  check('an ordinary straight fist to the chest, with no flag, is refused by no row', clean.length === 0, clean.join(', '));
  const seqIds = new Set(g.bannedSequences.map((r) => r.id));
  const missingSeq = theirs.bannedSequences.filter((r) => !seqIds.has(r.id)).map((r) => r.id);
  check("every sequence rule of Legal's is applied (parts.json strike.bannedSequences)", missingSeq.length === 0, missingSeq.join(', '));
  const applied = ['run', 'after', 'steps', 'hold'];
  const owners = ['audio', 'drawn'];   // conditions for Audio and Animation, which no shape of parts can break
  const unkinded = g.bannedSequences.filter((r) => !applied.includes(r.kind) && !owners.includes(r.kind)).map((r) => r.id);
  const conds = g.bannedSequences.filter((r) => owners.includes(r.kind)).map((r) => `${r.id} (${r.kind})`);
  check(`every sequence rule is applied by the generator or is a condition for its owner (${conds.join(', ')})`, unkinded.length === 0, unkinded.join(', '));
  const jab = { limb: 'hand', tip: 'blade', path: 'line', target: 'head', step: ['in', 'hold'] };
  check('four of the same blow running breaks s01 and s02', JSON.stringify(sequenceBreaks(g, [jab, jab, jab, jab])) === '["s01","s02"]');
  // a dropped or loosened row stops the generator: it refuses to write
  const dir = tmp('dropped');
  try {
    cpSync(DEFAULT_DIR, dir, { recursive: true });
    const p = load(join(dir, 'parts.json'));
    p.strike.banned = p.strike.banned.filter((r) => r.id !== 'b05');
    p.legal.energy = p.legal.energy.map((r) => (r.id === 'e01' ? { ...r, rule: r.rule + ' (loosened)' } : r));
    writeFileSync(join(dir, 'parts.json'), JSON.stringify(p, null, 1) + '\n');
    const r = generate({ dir, recipes: RECIPES });
    check("a copy of Legal's rows with b05 dropped and e01 reworded stops the generator", r.fresh.some((b) => b.includes('strike.banned differs')) && r.fresh.some((b) => b.includes('e01')), r.fresh.join('; '));
    const res = spawnSync(process.execPath, [CLI, '--dir', dir, '--recipes', RECIPES], { encoding: 'utf8' });
    check('... and it writes nothing (exit 1, REFUSED TO WRITE)', res.status === 1 && res.stdout.startsWith('REFUSED TO WRITE'), res.stdout.slice(0, 200));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
  // a banned move planted in a file on disk is found by --check
  const planted = JSON.parse(JSON.stringify(out.rival));
  const mv = planted.cells['martial.x'].moves[0];
  mv.flags = [...mv.flags, 'glow'];
  const found = legalFindings({ rival: planted }, parts, identity).filter((b) => b.includes(mv.id));
  check('a lit blow (b09) planted in a moveset on disk is found', found.some((b) => b.includes('b09')), found.join('; '));
  const neverMv = { ...planted.cells['martial.x'].moves[1], limb: 'hand', tip: 'palm', path: 'line', target: 'chest', flags: [] };
  planted.cells['martial.x'].moves[1] = neverMv;
  check("a palm planted in the rival's file breaks his never row", legalFindings({ rival: planted }, parts, identity).some((b) => b.includes(neverMv.id) && b.includes('never')));
}

// 3. names
{
  const lists = legalWords(ROOT);
  check("Legal's word lists are read from Legal's files (e11, e14, never-use-words.md, name-screening.md)", lists.problems.length === 0 && lists.words.length >= 10 && lists.leads.length >= 2, lists.problems.join('; '));
  const caught = screenName('Final Spirit Wave Strike', lists).map((h) => h.word);
  check('a name led by one of e11\'s words and built on another is caught', caught.includes('final') && caught.includes('wave'), JSON.stringify(caught));
  check('a plain heavy\'s name passes', screenName('falling hammer fist to the arm', lists).length === 0);
  check('"ball of the foot" is caught without its allow row, and passes with it', screenName('heaving ball of the foot to the gut', lists).length > 0
    && screenName('heaving ball of the foot to the gut', lists, [{ phrase: 'ball of the foot' }]).length === 0);
  configure({ root: ROOT, here: DEFAULT_DIR });
  const r = build();
  const bad = namesFindings(r.out, r.parts, r.identity);
  check('every name the build\'s movesets carry passes Legal\'s word lists', bad.length === 0, bad.join('; '));
}

// 4. determinism
{
  const a = generate({ recipes: RECIPES }).files;
  const b = generate({ recipes: RECIPES }).files;
  check('the same inputs give the same files, twice in one process', JSON.stringify(a) === JSON.stringify(b));
  const d1 = tmp('det1');
  const d2 = tmp('det2');
  try {
    for (const d of [d1, d2]) {
      cpSync(DEFAULT_DIR, d, { recursive: true });
      for (const f of readdirSync(d)) if (f.startsWith('moveset.') || f === 'lock.json' || f === 'review-sheet.md' || f === 'pools.json' || f === 'coverage.md') rmSync(join(d, f));
      cpSync(join(DEFAULT_DIR, 'lock.json'), join(d, 'lock.json'));
      spawnSync(process.execPath, [CLI, '--dir', d, '--recipes', RECIPES], { encoding: 'utf8' });
    }
    const same = readdirSync(d1).filter((f) => !f.endsWith('.py')).every((f) => readFileSync(join(d1, f)).equals(readFileSync(join(d2, f))));
    check('two processes from the same seed write the same bytes', same);
    const golden = ['moveset.rival.json', 'moveset.protagonist.json', 'lock.json', 'review-sheet.md'].every((f) => readFileSync(join(d1, f)).equals(readFileSync(join(DEFAULT_DIR, f))));
    check('... and the same bytes as the committed files', golden);
  } finally {
    rmSync(d1, { recursive: true, force: true });
    rmSync(d2, { recursive: true, force: true });
  }
}

// 5. the golden
{
  const r = node(['--check']);
  check('--check on the build\'s folder: files up to date, no Legal match, no dead end, today\'s pools covered', r.status === 0, r.stdout + r.stderr);
  const p = node(['--propose', '--check']);
  check('--propose --check: the proposals are up to date and the two of the build do not move', p.status === 0, p.stdout + p.stderr);
  const s = node(['--self-test']);
  check('--self-test exits 0', s.status === 0 && s.stdout.trim().endsWith('self-test passed'));
}

// 6. the schemas
{
  const sdir = join(HERE, '..', 'schemas');
  const schemas = Object.fromEntries(readdirSync(sdir).map((f) => [f, load(join(sdir, f))]));
  const loadSchema = (name) => schemas[name];
  for (const [f, s] of Object.entries(schemas)) {
    const problems = checkSchema(s, loadSchema);
    check(`${f} uses supported keywords only and its references resolve`, problems.length === 0, problems.join('; '));
  }
  const v = (schema, data) => validate(schema, data, loadSchema);
  const files = [];
  for (const d of [DEFAULT_DIR, join(ROOT, 'docs', 'combat', 'pending', 'roster'), dirname(PROPOSALS)]) {
    for (const f of readdirSync(d)) if (f.startsWith('moveset.') && f.endsWith('.json')) files.push(join(d, f));
  }
  const bad = files.flatMap((f) => v(schemas['combat-moveset.schema.json'], load(f)).map((e) => `${f.slice(ROOT.length + 1)}${e.pointer}: ${e.message}`));
  check(`every moveset file (${files.length}: the build, the roster sketches, the proposals) validates as combat.moveset/1`, bad.length === 0, bad.slice(0, 5).join('; '));
  for (const f of [join(DEFAULT_DIR, 'lock.json'), join(dirname(PROPOSALS), 'lock.proposals.json')]) {
    const e = v(schemas['combat-moveset-lock.schema.json'], load(f));
    check(`${f.slice(ROOT.length + 1)} validates as combat.moveset.lock/1`, e.length === 0, e.slice(0, 3).map((x) => x.pointer + ': ' + x.message).join('; '));
  }
  const ep = v(schemas['combat-movegen-pools.schema.json'], load(join(DEFAULT_DIR, 'pools.json')));
  check('pools.json validates as combat.movegen.pools/1', ep.length === 0, ep.slice(0, 3).map((x) => x.pointer + ': ' + x.message).join('; '));
  const recipesSchema = load(join(ROOT, 'tools', 'schemas', 'combat-recipes.schema.json'));
  const er = validate(recipesSchema.properties.pools, load(join(DEFAULT_DIR, 'pools.json')).pools, () => undefined);
  check("pools.json's pools validate against the recipes schema's own `pools` (the shape data/combat/ uses)", er.length === 0, er.slice(0, 3).map((x) => x.pointer + ': ' + x.message).join('; '));
  const ei = v(schemas['combat-identity-proposals.schema.json'], load(PROPOSALS));
  check('identity.proposals.json validates as combat.identity.proposals/1', ei.length === 0, ei.slice(0, 3).map((x) => x.pointer + ': ' + x.message).join('; '));
  const inputs = schemas['combat-movegen-inputs.schema.json'];
  const en = v(inputs.$defs.nameScreen, load(join(DEFAULT_DIR, 'parts.json')).nameScreen);
  const epo = v(inputs.$defs.pools, load(join(DEFAULT_DIR, 'cells.json')).pools);
  check('the new blocks validate: parts.json nameScreen and cells.json pools', en.length === 0 && epo.length === 0, [...en, ...epo].slice(0, 3).map((x) => x.pointer + ': ' + x.message).join('; '));
  // the schema can fail: a move with an unknown key, a heavy without its name, a lock row of four
  const ms = load(join(DEFAULT_DIR, 'moveset.rival.json'));
  const broken = JSON.parse(JSON.stringify(ms));
  broken.cells['martial.x'].moves[0].colour = 'red';
  delete broken.cells['martial.b'].moves[0].name;
  const eb = v(schemas['combat-moveset.schema.json'], broken);
  check('the moveset schema refuses a move with an unknown key and a heavy with no name', eb.some((e) => e.pointer.includes('martial.x')) && eb.some((e) => e.pointer.includes('martial.b')));
}

// 7. coverage
{
  const r = generate({ recipes: RECIPES });
  check("every piece of today's brawl pools (data/combat/recipes.json) is generated", r.uncovered.length === 0, r.uncovered.join('; '));
  const cells = r.cells;
  const ids = new Set();
  for (const st of Object.keys(cells.stances)) for (const [btn, c] of Object.entries(cells.stances[st])) {
    ids.add(`${st}.${btn}`);
    for (const p of Object.keys(c.presses || {})) ids.add(`${st}.${btn}.${p}`);
    if (c.standIn) ids.add(`${st}.${btn}.standin`);
  }
  const badRules = Object.entries(cells.pools.rules).filter(([, rule]) => !ids.has(rule.from)
    || (rule.quota && !cells.stances[rule.from.split('.')[0]][rule.from.split('.')[1]].quotas.some((q) => q.name === rule.quota))).map(([n]) => n);
  check('every pool rule names a cell of cells.json, and every quota it names is one of that cell\'s', badRules.length === 0, badRules.join(', '));
}

// 8. parity with the Python reference
{
  const py = spawnSync('python3', ['--version'], { encoding: 'utf8' });
  if (py.status !== 0) console.log('skip  parity with the Python reference: python3 is not on the path');
  else {
    const a = tmp('py');
    const b = tmp('js');
    try {
      for (const d of [a, b]) for (const f of ['parts.json', 'identity.json', 'cells.json', 'lock.json']) cpSync(join(DEFAULT_DIR, f), join(d, f));
      const src = readFileSync(join(DEFAULT_DIR, 'gen_moveset.py'), 'utf8').replace('ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))', `ROOT = ${JSON.stringify(ROOT)}`);
      writeFileSync(join(a, 'gen_moveset.py'), src);
      const rp = spawnSync('python3', ['-B', join(a, 'gen_moveset.py'), '--relock', '--recipes', RECIPES], { encoding: 'utf8', cwd: a });
      const rj = spawnSync(process.execPath, [CLI, '--dir', b, '--relock', '--recipes', RECIPES], { encoding: 'utf8' });
      const names = ['moveset.rival.json', 'moveset.protagonist.json', 'lock.json', 'review-sheet.md'];
      const diff = names.filter((f) => !existsSync(join(a, f)) || !existsSync(join(b, f)) || !readFileSync(join(a, f)).equals(readFileSync(join(b, f))));
      check('a full --relock gives the same bytes from the Python reference and from this port', rp.status === 0 && rj.status === 0 && diff.length === 0, `${diff.join(', ')} ${rp.stdout.slice(0, 200)} ${rp.stderr.slice(0, 200)}`);
      const pc = spawnSync('python3', ['-B', join(DEFAULT_DIR, 'gen_moveset.py'), '--check'], { encoding: 'utf8', cwd: ROOT });
      check("the Python reference's own --check passes on the committed files", pc.status === 0, pc.stdout.slice(0, 300));
    } finally {
      rmSync(a, { recursive: true, force: true });
      rmSync(b, { recursive: true, force: true });
    }
  }
}

console.log(`movegen tests: ${passed} passed, ${failed} failed`);
process.exitCode = failed ? 1 : 0;

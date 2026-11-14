// The scheme gauntlet (docs/tools/feel.md): scripted pads play many seeded matches against each computer level, once per scheme, and the run reports win rate, refusal rate and time without control.
//   node tools/feel/gauntlet.mjs [--scheme name=file:path=value;file:path=value ...] [--schemes-file f.json] [--arms stick,masher,timing,beam,circle] [--levels easy,medium,hard] [--n 10] [--seed 1] [--jobs 3] [--tree <tree folder>] [--json out.json] [--godot exe]
// A scheme is a named set of data overrides (any data file; they are written into a scratch copy of the tree, so a rule in the input hub counts here, which a replay of recorded intents cannot show). `shipped` (no override) is always run first; the others are read against it.
// The arms are in tools/feel/gauntlet.gd (stick-only, masher, timing, beam-first, circle-first), each a scripted pad on the real input hub. Every scheme plays the same seeds, so the comparison is paired.
// Machine: one Godot per cell, at most --jobs at once (default 3: six Windows processes, the project's cap), below-normal priority, a time limit on each; the tree is copied, never touched.
import { existsSync, mkdirSync, readdirSync, statSync, writeFileSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { ROOT, HERE, workCopy, runGd, patchTree, parseOverride, putFile } from './lib.mjs';

export const ARMS = ['stick', 'masher', 'timing', 'beam', 'circle'];
export const LEVELS = ['easy', 'medium', 'hard'];
export const ARM_WORDS = { stick: 'stick-only', masher: 'masher', timing: 'timing', beam: 'beam-first', circle: 'circle-first', orbs: "orb's scheme" };   // orbs is asked for by name (--arms orbs,stick), it is not one of the default five

/** The newest kept build's tree (the playable build), or throws. */
export function latestKeptTree(root = ROOT) {
  const dir = join(root, 'homework', 'Files', 'builds');
  const c = existsSync(dir) ? readdirSync(dir).map((n) => join(dir, n, 'tree')).filter((p) => existsSync(join(p, 'project.godot'))) : [];
  if (!c.length) throw new Error('no kept build tree in homework/Files/builds: pass --tree <a tree folder>');
  return c.sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)[0];
}

/** "name=file:path=value;file:path=value" -> { name, overrides }. */
export function parseScheme(spec) {
  const i = spec.indexOf('=');
  if (i < 1) throw new Error(`scheme "${spec}": expected name=file:dotted.path=value[;...]`);
  const name = spec.slice(0, i), rest = spec.slice(i + 1);
  return { name, overrides: rest ? rest.split(';').filter(Boolean).map(parseOverride) : [] };
}

/** Schemes from a JSON file: { "name": [ { file, path, value }, ... ] } or { "name": { "file:dotted.path": value } }. */
export function schemesFromFile(f) {
  const j = JSON.parse(readFileSync(f, 'utf8'));
  return Object.entries(j).map(([name, v]) => ({
    name,
    overrides: Array.isArray(v)
      ? v.map((o) => ({ file: o.file, path: Array.isArray(o.path) ? o.path : String(o.path).split('.'), value: o.value }))
      : Object.entries(v).map(([k, value]) => { const m = /^([^:]+):(.+)$/.exec(k); if (!m) throw new Error(`scheme ${name}: "${k}" is not file:dotted.path`); return { file: m[1], path: m[2].split('.'), value }; }),
  }));
}

/** Wilson 95% interval half-width of a share, in percent (a plain note of how little n matches can say). */
export function wilson(k, n) {
  if (!n) return 0;
  const z = 1.96, p = k / n, d = 1 + (z * z) / n;
  return Math.round((100 * (z * Math.sqrt((p * (1 - p)) / n + (z * z) / (4 * n * n)))) / d);
}

/** A cell's raw result -> the numbers read. */
export function readCell(r) {
  const minutes = r.ticks / 3600;
  return {
    n: r.done, won: r.won, lost: r.lost, other: r.draws + r.timeouts + r.capped,
    winPct: r.done ? Math.round((100 * r.won) / r.done) : 0, ci: wilson(r.won, r.done),
    refusalsPer100: r.presses ? Math.round((1000 * r.refused) / r.presses) / 10 : 0,
    noControlPerMin: minutes ? Math.round((r.noControl / 60 / minutes) * 10) / 10 : 0,
    beamsPerMatch: r.done ? Math.round((10 * r.beams) / r.done) / 10 : 0,
    medianSec: r.medianSec, topRefusal: Object.entries(r.refusedBy || {}).sort((a, b) => b[1] - a[1]).slice(0, 2).map(([k, v]) => `${k} ${v}`).join(', '),
  };
}

export function table(cells, schemes, arms, levels) {
  const out = [];
  const base = schemes[0];
  const sg = (x) => (x >= 0 ? '+' : '') + String(Math.round(x * 10) / 10);
  const W = [12, 7, 3, 17, 19, 22, 11];
  const row = (cols) => cols.map((c, i) => String(c).padEnd(W[i])).join(' ').trimEnd();
  for (const s of schemes) {
    out.push(`SCHEME ${s}${s === base ? ' (the reference)' : ''}`);
    out.push(row(['arm', 'level', 'n', 'win % (95% +/-)', 'refusals/100 presses', 's without control/min', 'beams/match']));
    for (const a of arms) for (const l of levels) {
      const c = cells[`${s}|${a}|${l}`];
      if (!c) continue;
      const ref = s !== base ? cells[`${base}|${a}|${l}`] : null;
      const d = (x, y) => (ref ? ` (${sg(x - y)})` : '');
      out.push(row([ARM_WORDS[a] || a, l, c.n, `${c.winPct}% +/-${c.ci}${d(c.winPct, ref?.winPct)}`, `${c.refusalsPer100}${d(c.refusalsPer100, ref?.refusalsPer100)}`, `${c.noControlPerMin}${d(c.noControlPerMin, ref?.noControlPerMin)}`, c.beamsPerMatch]));
    }
    out.push('');
  }
  return out.join(String.fromCharCode(10));
}

export async function gauntlet({ tree, schemes, arms = ARMS, levels = LEVELS, n = 10, seed = 1, jobs = 3, godot, capsec = 900, wall = 300, onCell, limitMs = 40 * 60 * 1000 }) {
  const base = tree ? resolve(tree) : latestKeptTree();
  const list = [{ name: 'shipped', overrides: [] }, ...schemes.filter((s) => s.name !== 'shipped')];
  // each scheme plays on its own scratch copy of the tree (the overrides written into its data files), with QA's planet helper beside it
  const qaPlanet = execFileSync('git', ['show', 'HEAD:qa/godot/qa_planet.gd'], { cwd: ROOT, maxBuffer: 1e7 });
  const trees = {};
  for (const s of list) {
    const t = workCopy(base, '-gt-' + s.name.replace(/[^A-Za-z0-9_-]/g, '_'));
    mkdirSync(join(t, 'qa', 'godot'), { recursive: true });
    putFile(join(t, 'qa', 'godot', 'qa_planet.gd'), qaPlanet);
    // always re-patch from a clean copy of the data files the overrides name
    for (const o of s.overrides) { const src = join(base, o.file); if (existsSync(src)) putFile(join(t, o.file), readFileSync(src)); }
    patchTree(t, s.overrides);
    trees[s.name] = t;
  }
  const queue = [];
  for (const s of list) for (const a of arms) for (const l of levels) queue.push({ s: s.name, a, l });
  const cells = {}, raw = {}, failed = [];
  let next = 0;
  const worker = async () => {
    while (next < queue.length) {
      const job = queue[next++];
      const r = await runGd(trees[job.s], [String(n), String(seed), `--arm=${job.a}`, `--level=${job.l}`, `--capsec=${capsec}`, `--wall=${wall}`], { godot, limitMs, script: join(HERE, 'gauntlet.gd') });
      const l = r.text.split(/\r?\n/).find((x) => x.startsWith('GAUNTLET '));
      if (!l) { failed.push({ ...job, why: (r.killedOn ? `stopped at the first script error (${r.bytes} bytes printed): ${r.killedOn}; a scratch tree with a new class needs a re-import first` : r.text.split(/\r?\n/).filter(Boolean).slice(-4).join(' | ')).slice(0, 400) }); continue; }
      const res = JSON.parse(l.slice(9));
      raw[`${job.s}|${job.a}|${job.l}`] = res;
      cells[`${job.s}|${job.a}|${job.l}`] = readCell(res);
      if (onCell) onCell(job, cells[`${job.s}|${job.a}|${job.l}`], Object.keys(cells).length, queue.length);
    }
  };
  await Promise.all(Array.from({ length: Math.max(1, Math.min(jobs, 3)) }, worker));   // never more than 3: six Godot processes
  return { tree: base, schemes: list.map((s) => s.name), overrides: Object.fromEntries(list.map((s) => [s.name, s.overrides])), arms, levels, n, seed, cells, raw, failed };
}

async function main() {
  const argv = process.argv.slice(2);
  const opt = (k, d) => { const i = argv.indexOf(k); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const all = (k) => argv.flatMap((a, i) => (a === k && argv[i + 1] ? [argv[i + 1]] : []));
  const schemes = [...all('--scheme').map(parseScheme), ...(opt('--schemes-file') ? schemesFromFile(opt('--schemes-file')) : [])];
  const res = await gauntlet({
    tree: opt('--tree'), schemes, arms: opt('--arms', ARMS.join(',')).split(','), levels: opt('--levels', LEVELS.join(',')).split(','),
    n: Number(opt('--n', 10)), seed: Number(opt('--seed', 1)), jobs: Number(opt('--jobs', 3)), godot: opt('--godot'),
    onCell: (j, c, k, total) => console.error(`[gauntlet] ${k}/${total} ${j.s} ${j.a} ${j.l}: win ${c.winPct}%, refusals ${c.refusalsPer100}/100, no control ${c.noControlPerMin} s/min`),
  });
  console.log(`tree ${res.tree}; ${res.n} matches a cell from seed ${res.seed}; the same seeds in every scheme`);
  console.log(table(res.cells, res.schemes, res.arms, res.levels));
  if (res.failed.length) console.log(`FAILED cells: ${res.failed.map((f) => `${f.s}/${f.a}/${f.l} (${f.why})`).join('; ')}`);
  if (opt('--json')) writeFileSync(opt('--json'), JSON.stringify(res, null, 1));
  process.exit(res.failed.length ? 1 : 0);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch((e) => { console.error('[gauntlet] FAILED: ' + e.message); process.exit(1); });

#!/usr/bin/env node
// The moveset generator (docs/combat/moveset-generator.md; tools/movegen/README.md). Node, no dependencies, no clock, no state.
//
//   node tools/movegen/movegen.mjs                  generate: one moveset file a fighter, the lock and the review sheet, into the folder
//   node tools/movegen/movegen.mjs --check          regenerate and compare with the folder's files; test the files on disk and Combat's own
//                                                   strings against Legal's rows (exit 1 on any difference or match)
//   node tools/movegen/movegen.mjs --self-test      prove the refusals on made-up moves and strings
//   node tools/movegen/movegen.mjs --merge-legal    copy Legal's new or reworded rows of the mirrored groups into parts.json
//   node tools/movegen/movegen.mjs --propose [FILE] [--check]
//                                                   proposals: fighters who are not in the build, generated beside its two from the rows
//                                                   of FILE (default docs/combat/proposals/identity.proposals.json), written beside FILE
//   ... --dir DIR        the folder of the inputs and outputs (default docs/combat/pending/movegen)
//   ... --relock         ignore the lock and fill every cell afresh (a deliberate act, with its own sheet)
//   ... --recipes PATH   the recipes file whose blur patterns and pools are tested (default: ../recipes.brawl.json beside the folder, else
//                        data/combat/recipes.json)
//   ... --live PATH      the recipes the fighters have today, for coverage.md (default data/combat/recipes.json)
//
// It refuses to write if any move matches one of Legal's rows (docs/legal/movegen-banned.json) or a string runs out of blows.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  Stop, build, configure, dataFindings, dump, env, gateFindings, gateLine, gateShares, identityFindings, legalFindings, legalUnread, load, lockText, recipesFindings,
  shareFindings, stringFindings, stringReport,
} from './lib/generator.mjs';
import { mergeLegal } from './lib/legal.mjs';
import { namesFindings } from './lib/names.mjs';
import { coverage, poolsCtx, poolsText } from './lib/pools.mjs';
import { propose } from './lib/roster.mjs';
import { makeExpect, selfTest } from './lib/selftest.mjs';
import { sheet } from './lib/sheet.mjs';
import { sorted } from './lib/py.mjs';

export const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const DEFAULT_DIR = join(ROOT, 'docs', 'combat', 'pending', 'movegen');

const arg = (argv, name) => (argv.includes(name) ? argv[argv.indexOf(name) + 1] : null);

/** Everything a run makes, without writing: { out, parts, identity, cells, notes, files, rep, dead, gate, under, fresh, data, names }. */
export function generate({ dir = DEFAULT_DIR, relock = false, recipes = null, live = join(ROOT, 'data', 'combat', 'recipes.json') } = {}) {
  configure({ root: ROOT, here: dir, relock, recipes });
  const { out, parts, identity, cells, notes } = build();
  const rep = stringReport(out, parts, cells);
  const dead = [...stringFindings(rep, identity), ...recipesFindings(parts), ...shareFindings(out, cells, identity)];
  const gate = 'gate' in cells ? gateShares(out, cells, identity) : {};
  const under = gateFindings(gate, cells);   // said by --check, and never a reason to refuse to write: a row has to be seen to be mended
  const files = {};
  for (const [who, doc] of Object.entries(out)) files[`moveset.${who}.json`] = dump(doc);
  files['lock.json'] = lockText(out);
  files['review-sheet.md'] = sheet(out, parts, cells, notes, rep, identity);
  let uncovered = [];
  if ('pools' in cells) {   // the recipes' pools written from the cells, and what each fighter has today against them
    const ctx = poolsCtx({ out, parts, identity, cells, notes }, live);
    files['pools.json'] = poolsText(ctx.pools, cells);
    const cov = coverage(ctx);
    files['coverage.md'] = cov.text;
    uncovered = cov.problems;
  }
  for (const [name, text] of Object.entries(files)) if (!name.endsWith('.md')) JSON.parse(text);
  const fresh = legalFindings(out, parts, identity);
  const names = namesFindings(out, parts, identity);
  const data = [...dataFindings(parts), ...identityFindings(parts, identity)];
  return { out, parts, identity, cells, notes, files, rep, dead, gate, under, fresh, names, data, uncovered };
}

function main(argv) {
  const dir = resolve(arg(argv, '--dir') || DEFAULT_DIR);
  const recipes = arg(argv, '--recipes') ? resolve(arg(argv, '--recipes')) : null;
  if (argv.includes('--propose')) {
    const given = arg(argv, '--propose');
    const file = resolve(given && !given.startsWith('--') ? given : join(ROOT, 'docs', 'combat', 'proposals', 'identity.proposals.json'));
    const p = propose({ generate, root: ROOT, baseDir: dir, proposalsPath: file, outDir: dirname(file), check: argv.includes('--check'), recipes: recipes || join(dir, '..', 'recipes.brawl.json') });
    for (const l of p.lines) console.log(l);
    if (p.written.length) console.log('written: ' + p.written.join(', '));
    return p.ok ? 0 : 1;
  }
  if (argv.includes('--merge-legal')) {
    const m = mergeLegal(ROOT, dir);
    for (const a of m.added) console.log(`added    ${a}: a condition until Combat gives it a kind`);
    for (const c of m.changed) console.log(`changed  ${c}: its words changed; look at its machine form`);
    if (m.added.length || m.changed.length) m.write(m.text);
    console.log(m.added.length || m.changed.length ? 'parts.json written' : "parts.json already holds Legal's rows");
    return 0;
  }
  if (argv.includes('--self-test')) {
    configure({ root: ROOT, here: dir, relock: argv.includes('--relock'), recipes });
    const { parts, identity } = build();
    const { expect, state } = makeExpect();
    selfTest(parts, identity, expect);
    console.log('self-test ' + (state.ok ? 'passed' : 'FAILED'));
    return state.ok ? 0 : 1;
  }
  const r = generate({ dir, relock: argv.includes('--relock'), recipes, ...(arg(argv, '--live') ? { live: resolve(arg(argv, '--live')) } : {}) });
  if (r.data.length) {
    console.log(`the hand-kept data: ${r.data.length} PROBLEM`);
    for (const b of r.data) console.log('  ' + b);
    return 1;
  }
  const here = (n) => join(dir, n);
  if (argv.includes('--check')) {
    const stale = Object.entries(r.files).filter(([n, t]) => !existsSync(here(n)) || readFileSync(here(n), 'latin1').replace(/\r\n/g, '\n') !== Buffer.from(t, 'utf8').toString('latin1')).map(([n]) => n);
    const onDisk = {};
    for (const who of Object.keys(r.out)) if (existsSync(here(`moveset.${who}.json`))) onDisk[who] = load(here(`moveset.${who}.json`));
    const bad = sorted([...new Set([...r.fresh, ...legalFindings(onDisk, r.parts, r.identity), ...r.names])]);
    console.log('files: ' + (!stale.length ? 'up to date' : 'OUT OF DATE: ' + stale.join(', ')) + (env.missing.size ? ` (packs the tree does not have yet, read as empty: ${sorted([...env.missing]).join(', ')})` : ''));
    console.log("Legal's rows: " + (!bad.length ? 'no match' : `${bad.length} MATCH`) + legalUnread(r.parts));
    for (const b of bad) console.log('  ' + b);
    console.log('strings: ' + (!r.dead.length ? 'no dead end' : `${r.dead.length} PROBLEM`));
    for (const b of r.dead) console.log('  ' + b);
    if (Object.keys(r.gate).length) {
      console.log(gateLine(r.gate, r.cells));
      for (const b of r.under) console.log('  ' + b);
    }
    if ('coverage.md' in r.files) {
      console.log("today's pools: " + (!r.uncovered.length ? 'every piece of a brawl pool is generated' : `${r.uncovered.length} NOT COVERED`));
      for (const b of r.uncovered) console.log('  ' + b);
    }
    return stale.length || bad.length || r.dead.length || r.under.length || r.uncovered.length ? 1 : 0;
  }
  if (r.fresh.length || r.names.length || r.dead.length) {
    console.log('REFUSED TO WRITE: ' + (r.fresh.length || r.names.length ? "Legal's rows match" : 'a string runs out of blows'));
    for (const b of [...r.fresh, ...r.names, ...r.dead]) console.log('  ' + b);
    return 1;
  }
  for (const [name, text] of Object.entries(r.files)) writeFileSync(here(name), text, 'utf8');
  for (const [who, doc] of Object.entries(r.out)) {
    for (const [cid, c] of Object.entries(doc.cells)) {
      if ('moves' in c && !c.kit) {
        const st = c.moves.map((m) => m.status);
        const n = (s) => st.filter((x) => x === s).length;
        const ch = r.notes[who].changes[cid] || {};
        const extra = c.kind === 'strikes' ? ` | refused ${c.refused.length}, dropped ${ch.dropped.length}, re-read ${ch.reread.length}, new since the lock ${ch.new.length}` : '';
        console.log(`${who.padEnd(12)} ${cid.padEnd(12)} ${String(st.length).padStart(2)} of ${String(c.valid).padStart(4)}: posed ${String(n('posed')).padStart(2)}, derived ${String(n('derived')).padStart(2)}, waiting ${String(n('waiting')).padStart(2)}${extra} | ${JSON.stringify(c.quotas)}`);
      }
    }
    for (const ch of Object.values(r.notes[who].changes)) {
      for (const d of ch.dropped) console.log(`   dropped  ${d.id} ${JSON.stringify(d.shape)}`);
      for (const d of ch.reread) console.log(`   re-read  ${d.id} ${d.set}: ${JSON.stringify(d.was)} -> ${JSON.stringify(d.now)}`);
    }
    console.log(`${who.padEnd(12)} seed ${doc.generator.seed}, inputs ${doc.generator.inputs}; unread: ${r.notes[who].unread.length ? JSON.stringify(r.notes[who].unread) : 'none'}`);
  }
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    process.exitCode = main(process.argv.slice(2));
  } catch (e) {
    if (e instanceof Stop) {
      console.error(e.message);
      process.exitCode = 1;
    } else throw e;
  }
}

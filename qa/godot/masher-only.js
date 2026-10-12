#!/usr/bin/env node
// Long batches run at below-normal priority so other sessions' short gate runs finish in normal time (CLAUDE.md, machine discipline); children inherit it. QA_PRIORITY=normal turns it off.
try { if (process.env.QA_PRIORITY !== 'normal') require('os').setPriority(0, require('os').constants.priority.PRIORITY_BELOW_NORMAL); } catch (e) { /* the run goes on at the priority it has */ }
// The masher stage on its own, with its results kept as they finish (docs/qa/baseline-fb8aafac.md: a stop used to lose the whole stage). From the repo root:
//   QA_GODOT_ROOT=<clean export> QA_MASHER_SAVE=<file.json> [QA_MASHER_ONLY=<regex on job names>] node qa/godot/masher-only.js [--n=100] [--base=1] [--jobs=3] [--md=<file.md>]
// Jobs already in the save file are not run again, so a run that was stopped is resumed by running the same command. The rows are printed (and written to --md) for the jobs that have results.
const fs = require('fs');
const { runMasher, masherRows } = require('./masher');

const arg = (k, d) => { const a = process.argv.slice(2).find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : d; };
const n = parseInt(arg('n', '100'), 10), base = parseInt(arg('base', '1'), 10), jobs = parseInt(arg('jobs', '3'), 10), md = arg('md', '');

(async () => {
  const t0 = Date.now();
  const results = await runMasher({ n, base, jobs });
  const rows = masherRows(results);
  const L = [`# Masher stage rows (${results.length} jobs with results, ${Math.round((Date.now() - t0) / 1000)} s this run)`, '', '| Status | Id | Measure | Value | Band | Note |', '| :--- | :--- | :--- | :--- | :--- | :--- |'];
  const cell = v => String(v === undefined ? '' : v).replace(/\|/g, '/').replace(/\n/g, ' ');
  for (const r of rows) L.push(`| ${r.status === 'FAIL' ? '**FAIL**' : r.status} | ${cell(r.id)} | ${cell(r.what)} | ${cell(r.value)} | ${cell(r.band)} | ${cell(r.note)} |`);
  const text = L.join('\n') + '\n';
  if (md) fs.writeFileSync(md, text);
  console.log(text);
  const c = {}; for (const r of rows) c[r.status] = (c[r.status] || 0) + 1;
  console.log('rows: ' + JSON.stringify(c));
})().catch(e => { console.error(e); process.exit(1); });

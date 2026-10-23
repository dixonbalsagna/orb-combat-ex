#!/usr/bin/env node
// One arm of records on its own, with its rows: for a read of one switch (recoil flips, the wall kick, the chase) in a scratch export with that switch on. From the export's root:
//   node qa/godot/run-arm.js --count=200 [--arm=default] [--start=city|crossing] [--jobs=3] [--out=<records.json>] [--md=<rows.md>]
// --start=city puts both fighters in a city (so wall slams, and so wall kicks, are common); --start=crossing is World's demo start. Below-normal priority.
try { if (process.env.QA_PRIORITY !== 'normal') require('os').setPriority(0, require('os').constants.priority.PRIORITY_BELOW_NORMAL); } catch (e) { /* the run goes on at the priority it has */ }
const fs = require('fs'), path = require('path');
const { runRecords } = require('./godot');
const { evaluate, hasEvent } = require('./bands');

const arg = (k, d) => { const a = process.argv.slice(2).find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : d; };
(async () => {
  const count = parseInt(arg('count', '200'), 10), arm = arg('arm', 'default'), startMode = arg('start', ''), jobs = parseInt(arg('jobs', '3'), 10), t0 = Date.now();
  const recs = await runRecords({ arm, base: 1, count, jobs, capSec: 900, startMode });
  if (arg('out', '')) fs.writeFileSync(path.resolve(arg('out')), JSON.stringify(recs));
  const A = { default: recs };
  const rows = evaluate(A, { scale: hasEvent(A, 'finisher_start') ? 'game' : 'testbed', cap: 900 });
  const cell = v => String(v === undefined ? '' : v).replace(/\|/g, '/').replace(/\n/g, ' ');
  const L = ['| Status | Id | Measure | Value | Band |', '| :--- | :--- | :--- | :--- | :--- |'];
  for (const r of rows) L.push(`| ${r.status === 'FAIL' ? '**FAIL**' : r.status} | ${cell(r.id)} | ${cell(r.what)} | ${cell(r.value)} | ${cell(r.band)} |`);
  const text = L.join('\n') + '\n';
  if (arg('md', '')) fs.writeFileSync(path.resolve(arg('md')), text);
  console.log(text + `(${count} matches${startMode ? ' from the ' + startMode + ' start' : ''}, ${Math.round((Date.now() - t0) / 1000)} s)`);
})().catch(e => { console.error(e); process.exit(1); });

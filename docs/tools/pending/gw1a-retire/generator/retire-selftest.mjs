// Edits COPIES of tools/preview/preview-selftest.mjs and stack-selftest.mjs for the GW1a retirement: the existing engine checks run on the table as it was before (retired-rows.mjs), and preview-selftest gets a new section for the live table.
// usage: node retire-selftest.mjs <the tools/preview folder of the copy>
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const dir = process.argv[2];
const NL = String.fromCharCode(10);
function edit(file, pairs) {
  const f = join(dir, file);
  let t = readFileSync(f, 'utf8');
  for (const [a, b] of pairs) { if (t.split(a).length !== 2) throw new Error(`${file}: anchor not exactly once: ${a.slice(0, 80)}`); t = t.replace(a, () => b); }
  writeFileSync(f, t);
  console.log('edited', file, pairs.length);
}

const head = [
  "// GW1a (2026-11-14): the rows main's own data landed are no longer in the live table (SWITCHES, LANDED_IDS). The engine checks below (flip, the cascade, waiting, the scratch patch, the builds) run on the table as it was",
  "// BEFORE the retirement (retired-rows.mjs: the retired rows from retired-rows.json and the live rows in their old order), so they go on proving the engine itself; the section at the end of the run checks the live table.",
  "const LIVE_ROWS = SWITCHES.slice();",
  "const HIST_ROWS = historicRows(LIVE_ROWS);",
  "const restoreLive = useHistoricTable();",
  "",
].join(NL);
const tail = [
  "  // ---- the live table after the GW1a retirement (A-CODE-03, the EP's GW1a item for Tools)",
  "  restoreLive();",
  "  {",
  "    const ids = new Set(IDS), landed = new Set(LANDED_IDS);",
  "    check('GW1a: every retired row is out of the live table, and none is both retired and kept', LANDED_IDS.every((id) => !ids.has(id)) && landed.size === LANDED_IDS.length && LANDED_IDS.length === RETIRED_ROWS.length && RETIRED_ROWS.every((r) => landed.has(r.id)));",
  "    check('GW1a: the kept rows are the ones the golden window did not land (the five held rows: the city rows and the aim cuts; and the three page rows: gen3, blackbox, go)', IDS.length === 8 && [...IDS].sort().join() === 'aimCuts,blackbox,cityHold,gen3,go,slamTurn,wallPush,wallPushAi', IDS.join());",
  "    check('GW1a: the old table is the live rows and the retired ones together, 93 rows with no id twice', HIST_ROWS.length === 93 && new Set(HIST_ROWS.map((s) => s.id)).size === 93 && HIST_ROWS.every((s) => s !== undefined));",
  "    check('GW1a: a kept row never needs a retired one (the cascade would turn it off for a switch that is not there)', SWITCHES.every((s) => s.needs.every((n) => ids.has(n))));",
  "    check('GW1a: asking to turn a landed row on or off is said so, not called unknown and not silently ignored', (() => { const r = resolve(['tiles', 'gen2']), r2 = resolve([], SWITCHES, ['rightStick']); return r.landed.join() === 'tiles,gen2' && r.unknown.length === 0 && r.active.join() === resolve([]).active.join() && r2.landed.join() === 'rightStick' && resolve(['nonsense']).unknown.join() === 'nonsense' && resolve(['nonsense']).landed.length === 0; })());",
  "    check('GW1a: the look words (tiles=1, meteor=loud, craterlook=1) are no longer launch words, and the page rows that stay still are', (() => { const w = tableWith([]).filter((s) => s.url).map((s) => s.url); return !w.includes('tiles=1') && !w.includes('meteor=loud') && !w.includes('craterlook=1') && w.includes('go=1') && w.includes('blackbox=1'); })());",
  "    check('GW1a: the smoke check expects the landed rows ON in the running game: the data generation 2, the biome, the interrupts and the turn, the right stick, the meteor', (() => { const e = expectations([]); return e.planetGen === 2 && e.dataGen === 2 && e.biome === true && e.interrupts === true && e.turn === true && e.rightStick === true && e.meteor === true && e.swingOn === true && e.struggle === true && e.water === true && e.surface === true && e.floor === true && e.mixed === true && e.kick === true; })());",
  "    check('GW1a: the probes of the retired rows stay, each with the code it needs, one for each row that had one', LANDED_PROBES.length > 30 && LANDED_PROBES.every((p) => p.id && p.probe && p.probeIf && p.probeIf.file && p.probeIf.text) && ['rightStick', 'meteor', 'struggle', 'swing', 'arc', 'beamFront'].every((id) => LANDED_PROBES.some((p) => p.id === id)) && LANDED_PROBES.every((p) => landed.has(p.id)));",
  "    check('GW1a: isOn says on for a preview switch that is on and for a landed row, and off for a kept row that is not on', isOn(['cityHold'], 'cityHold') && isOn([], 'tiles') && isOn([], 'rightStick') && isOn([], 'water') && !isOn([], 'cityHold') && !isOn(['cityHold'], 'gen3'));",
  "    check('GW1a: retired-rows.json says where each row went and why it is retired (an evidence line), and holds the old row whole', RETIRED_ROWS.every((r) => typeof r.evidence === 'string' && r.evidence.length > 10 && Number.isInteger(r.index)) && RETIRED_ROWS.find((r) => r.id === 'gen2').file === 'data/biomes/climate.json' && RETIRED_ROWS.find((r) => r.id === 'meteor').url === 'meteor=loud');",
  "  }",
].join(NL);

edit('preview-selftest.mjs', [
  ["import { SWITCHES, KICK_SAMPLES, HITSTOP_SAMPLES, PEAK_SAMPLES, IDS, locate,", "import { SWITCHES, LANDED_IDS, LANDED_PROBES, isOn, KICK_SAMPLES, HITSTOP_SAMPLES, PEAK_SAMPLES, IDS, locate,"],
  ["const HELD = SWITCHES.filter((x) => x.held)", "import { RETIRED_ROWS, historicRows, useHistoricTable } from './retired-rows.mjs';" + NL + head + "const HELD = SWITCHES.filter((x) => x.held)"],
  ["} finally {" + NL + "  rmSync(tmp, { recursive: true, force: true });", tail + NL + "} finally {" + NL + "  rmSync(tmp, { recursive: true, force: true });"],
]);
edit('stack-selftest.mjs', [
  ["import { templateZip, pageStamp, commitDate } from './stack-preview.mjs';", "import { templateZip, pageStamp, commitDate } from './stack-preview.mjs';" + NL + "import { useHistoricTable } from './retired-rows.mjs';" + NL + "useHistoricTable();   // GW1a: these checks were written on the switch table as it was before the retirement of the rows main's own data landed (retired-rows.mjs); they go on proving the engine on it"],
]);

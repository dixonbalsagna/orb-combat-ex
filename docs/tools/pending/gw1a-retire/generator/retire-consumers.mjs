// The consumers of the switch table, edited for the GW1a retirement (in a COPY of tools/preview): preview.mjs, stack-preview.mjs, smoke.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const dir = process.argv[2];
function edit(file, pairs) {
  const f = join(dir, file);
  let t = readFileSync(f, 'utf8');
  for (const [a, b] of pairs) {
    if (t.split(a).length !== 2) throw new Error(`${file}: anchor not exactly once: ${a.slice(0, 80)}`);
    t = t.replace(a, () => b);
  }
  writeFileSync(f, t);
  console.log('edited', file, pairs.length);
}
edit('preview.mjs', [
  ["import { IDS, SWITCHES,", "import { IDS, SWITCHES, LANDED_PROBES, isOn,"],
  ["return x !== null && x.includes('dashOn_') && active.includes('arrive'); })();", "return x !== null && x.includes('dashOn_') && isOn(active, 'arrive'); })();"],
  [".map((s) => s.probe));\n  return { table,", ".map((s) => s.probe))\n    .concat(LANDED_PROBES.filter((p) => !table.some((s) => s.id === p.id)).filter((p) => { const x = read(p.probeIf.file); return x !== null && x.includes(p.probeIf.text); }).map((p) => p.probe));   // the probes of the rows main's own data landed (GW1a): the page still reads what the running game says\n  return { table,"],
  ["unknown: r.unknown, setup,", "unknown: r.unknown, landed: r.landed, setup,"],
  ["struggleOff: pl.active.includes('struggle')", "struggleOff: isOn(pl.active, 'struggle')"],
  ["  if (r.unknown.length) throw new Error(", "  if (pl.landed && pl.landed.length) throw new Error(`${pl.landed.join(', ')} ${pl.landed.length > 1 ? 'are' : 'is'} main's own data since GW1a: there is no switch to turn on or off here`);\n  if (r.unknown.length) throw new Error("],
]);
edit('stack-preview.mjs', [
  ["injectPage, hasHeader, BB_FINGERPRINT } from './blackbox.mjs';", "injectPage, hasHeader, BB_FINGERPRINT } from './blackbox.mjs';\nimport { isOn } from './switches.mjs';"],
  ["struggleOff: pl.active.includes('struggle')", "struggleOff: isOn(pl.active, 'struggle')"],
  ["  if (pl.unknown.length) throw new Error(", "  if (pl.landed && pl.landed.length) throw new Error(`${pl.landed.join(', ')} ${pl.landed.length > 1 ? 'are' : 'is'} main's own data since GW1a: there is no switch to turn on or off here`);\n  if (pl.unknown.length) throw new Error("],
]);
edit('smoke.mjs', [
  ["import { IDS, errorSwitch } from './switches.mjs';", "import { IDS, LANDED_IDS, errorSwitch } from './switches.mjs';"],
  ["  const set = new Set(on);\n  return {\n    planet,", "  const set = new Set([...on, ...LANDED_IDS.filter((id) => !IDS.includes(id))]);   // a row main's own data landed (GW1a) is on in the running game whether or not the preview flipped it\n  return {\n    planet,"],
]);

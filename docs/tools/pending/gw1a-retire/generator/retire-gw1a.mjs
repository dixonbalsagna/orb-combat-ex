// Builds the GW1a retirement of the preview's switch rows from a copy of tools/preview/switches.mjs: removes the retired rows, drops them from the other rows' `needs`, and adds LANDED_IDS, LANDED_PROBES, isOn and the landed check in resolve().
// usage: node retire-gw1a.mjs <path to a COPY of switches.mjs> <retire-data.txt (one id a line)>
import { readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
const [file, listFile] = process.argv.slice(2);
const dataIds = readFileSync(listFile, 'utf8').split(/\r?\n/).filter(Boolean);
const extra = ['tiles', 'craterlook', 'meteor'];   // the look words: no data key to read, judged from the code of the tree (RenderTileGround.on, crater_look, VfxLook.METEOR_DEFAULT)
const retired = [...dataIds, ...extra];
const set = new Set(retired);
const orig = (await import(pathToFileURL(file).href + '?orig=1')).SWITCHES;   // the table as it is, before the text is edited
const landedProbes = [];
for (const r of orig) {
  if (!set.has(r.id)) continue;
  if (r.id === 'mixed') continue;   // its probe looks for sim/director/mixed.gd, which was never on main, in the GW1a stack or in the kept build (Combat, gw1a-rows): it could never be read, so it is not kept
  if (r.probe && r.probeIf) landedProbes.push({ id: r.id, probe: r.probe, probeIf: r.probeIf });
  for (const m of r.probeMore || []) landedProbes.push({ id: r.id, probe: m.line, probeIf: m.probeIf });
}
const NL = String.fromCharCode(10);
const lines = readFileSync(file, 'utf8').split(NL);
const s = lines.findIndex((l) => l.startsWith('export const SWITCHES = ['));
const e = lines.findIndex((l, i) => i > s && l === '];');
if (s < 0 || e < 0) throw new Error('array not found');
const rows = [];
for (let i = s + 1; i < e; i++) { const m = /^  \{ id: '([A-Za-z0-9]+)'/.exec(lines[i]); if (m) rows.push({ id: m[1], a: i }); }
rows.forEach((r, k) => { r.b = k + 1 < rows.length ? rows[k + 1].a : e; });
for (const id of retired) if (!rows.some((r) => r.id === id)) throw new Error('row to retire not in the table: ' + id);
const out = lines.slice(0, s + 1);
const droppedNeeds = [];
const needsBefore = {};
for (const r of rows) {
  if (set.has(r.id)) continue;
  const block = lines.slice(r.a, r.b).map((l) => l.replace(/needs: \[([^\]]*)\]/, (all, inner) => {
    const ids = inner.split(',').map((x) => x.trim().replace(/'/g, '')).filter(Boolean);
    const keep = ids.filter((x) => !set.has(x));
    if (keep.length !== ids.length) droppedNeeds.push(`${r.id}: ${ids.filter((x) => set.has(x)).join(', ')}`);
    if (keep.length !== ids.length) needsBefore[r.id] = ids;
    return `needs: [${keep.map((x) => `'${x}'`).join(', ')}]`;
  }));
  out.push(...block);
}
out.push(...lines.slice(e));
let t = out.join(NL);
const note = [
  '',
  "// GW1a (2026-11-14, Tools): the rows whose data the golden window landed as main's own are RETIRED from this table. A retired row's value is what main's data holds now, so applying it would change nothing",
  "// (or, where main's value moved on, would put the old one back): the page build neither flips them nor lists them, and the launch words of the look group (tiles, craterlook, meteor) are no longer added.",
  "// LANDED_IDS names them. smoke.mjs reads them as on when it works out what the running game must report; resolve() says so when someone asks to turn one off. node tools/preview/switch-diff.mjs --tree <a tree>",
  '// is the proof: after the GW1a stack the rows still differing from the 9 November build are the ones kept here.',
  `export const LANDED_IDS = ${JSON.stringify(retired)};`,
  "// The probes of the retired rows stay: the page still reads what the running game says each one is (window.__preview), so the smoke check goes on verifying that main's own data turned the thing on.",
  `export const LANDED_PROBES = ${JSON.stringify(landedProbes, null, 1)};`,
  "/** Whether a switch is on in a build: the preview turned it on, or main's own data has it on since GW1a. */",
  'export const isOn = (active, id) => active.includes(id) || (LANDED_IDS.includes(id) && !IDS.includes(id));',
  '',
];
t = t.replace('export const SWITCHES = [', () => note.join(NL) + NL + 'export const SWITCHES = [');
const a1 = "  const unknown = [...want, ...wantOn].filter((id) => id !== 'all' && !IDS.includes(id));";
if (t.split(a1).length !== 2) throw new Error('resolve anchor 1');
t = t.replace(a1, () => "  const landed = [...new Set([...want, ...wantOn].filter((id) => LANDED_IDS.includes(id) && !IDS.includes(id)))];   // main's own data since GW1a: nothing to turn on or off here" + NL + "  const unknown = [...want, ...wantOn].filter((id) => id !== 'all' && !IDS.includes(id) && !landed.includes(id));");
const a2 = '  return { active: IDS.filter((id) => active.has(id)), cascaded, unknown, held };';
if (t.split(a2).length !== 2) throw new Error('resolve anchor 2');
t = t.replace(a2, () => '  return { active: IDS.filter((id) => active.has(id)), cascaded, unknown, held, landed };');
writeFileSync(file, t);
console.log(`retired ${retired.length} rows (${dataIds.length} data rows by the GW1a tree, ${extra.length} by the sound group and the look words); kept ${rows.length - retired.length}; ${landedProbes.length} probes kept`);
console.log('needs dropped: ' + (droppedNeeds.join(' | ') || 'none'));
// the record of what landed: the retired rows as they were (without their long text), with the evidence for each
import { dirname, join } from 'node:path';
const ev = (id) => (dataIds.includes(id) ? 'the full GW1a stack (the EP\'s s422 tree, plus Simulation\'s data-fight-gw1a for the five data/fight rows) holds the row\'s value (to) at its key' : ['phrases', 'mixed'].includes(id) ? ('Combat park (docs/combat/pending/gw1a-rows) sets enabled true in data/combat/' + id + '.json; the GW1a scratch tree does not hold the file') : ['tiles', 'craterlook', 'meteor'].includes(id) ? 'the full GW1a stack has it on by default in code (RenderTileGround.on, crater_look, VfxLook.METEOR_DEFAULT)' : 'Audio\'s group sets it in audio/data (the park\'s files); the GW1a scratch tree has no audio folder to read');
const rec = orig.map((r, index) => ({ r, index })).filter((x) => set.has(x.r.id)).map(({ r, index }) => ({ ...r, index, evidence: ev(r.id) }));
writeFileSync(join(dirname(file), 'retired-rows.json'), JSON.stringify({ keptNeedsBefore: needsBefore, _about: 'The switch rows the golden window GW1a landed as main\'s own data (tools/preview/switches.mjs LANDED_IDS), as they were before: id, file, key, from, to. Kept as the record of what landed and as the selftest\'s fixtures for the flip engine. Written by the retirement, 2026-11-14.', rows: rec }, null, 1) + NL);
console.log('wrote retired-rows.json with', rec.length, 'rows');

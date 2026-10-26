// World, window 12: writes data/biomes/plates-b.json and the Prm class of sim/world/plateb.gd from Research's PB (research/planet-gen/gen/plates.mjs), so the numbers are Research's own.
//   node gen_b_params.mjs <repo root> <out dir>
import { pathToFileURL } from 'node:url';
import fs from 'node:fs';
const root = process.argv[2].replace(/\/$/, ''), out = process.argv[3].replace(/\/$/, '');
const { PB } = await import(pathToFileURL(root + '/research/planet-gen/gen/plates.mjs').href);
const INTS = new Set(['plates', 'areaPts', 'sepTries', 'cells', 'warpOct', 'crustOct', 'crustOctM', 'alongOct', 'interiorOct', 'oldOct', 'reliefOct', 'peakOct', 'detailOct', 'hotspots', 'chain', 'hotActive']);
const isInt = (k) => INTS.has(k) || /^s[A-Z]/.test(k);
const keys = Object.keys(PB);
let cls = 'class Prm extends RefCounted:\n\t## Research\'s PB (research/planet-gen/gen/plates.mjs), one member a number, set from plates-b.json by name (a member the file lacks keeps the default written here).\n';
for (const k of keys) {
  const v = PB[k];
  cls += isInt(k) ? `\tvar ${k}: int = ${v}\n` : `\tvar ${k}: float = ${Number.isInteger(v) ? v.toFixed(1) : v}\n`;
}
fs.writeFileSync(out + '/prm_class.txt', cls);
const o = { schema: 'biomes.plates-b/1', _about: '', params: {} };
for (const k of keys) o.params[k] = PB[k];
// JSON.stringify drops ".0"; fine for GDScript (float(int) is exact) and for the schema (number)
o._about = 'Planet generation 2, approach B (Research\'s plates, docs/research/planet-gen.md section 2; sim/world/plateb.gd, window 12). Read only when land.json b.enabled is true. Every number is Research\'s PB in research/planet-gen/gen/plates.mjs: see that file for what each one does. Seeds (the s* numbers) are added to the planet seed.';
fs.writeFileSync(out + '/plates-b.json', JSON.stringify(o, null, 2) + '\n');
console.log(keys.length + ' params');

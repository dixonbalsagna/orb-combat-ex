// scratch-quality helper kept with the shell cover: tone candidates against the beach ground, the beach rock and every energy lane's main colour
import fs from 'fs';
import { dE00 } from '../sky/colour.mjs';
const j = JSON.parse(fs.readFileSync(new URL('../../../data/art/biomes.json', import.meta.url), 'utf8')).biomes.beach.palette;
const L = JSON.parse(fs.readFileSync(new URL('../../../data/art/energy-lanes.json', import.meta.url), 'utf8'));
const cands = JSON.parse(process.argv[2]);
const lanes = []; for (const [f, o] of Object.entries(L.lanes)) for (const [k, v] of Object.entries(o.kinds)) lanes.push([f + ' ' + k, v.main]);
const ground = [...j.ground, ...j.rock, j.subsoil, j.accent];
for (const c of cands) {
  const g = Math.min(...ground.map(h => dE00(c, h))), a = lanes.map(([n, h]) => [n, dE00(c, h)]).sort((x, y) => x[1] - y[1])[0];
  console.log(c, 'nearest beach tone', g.toFixed(1), 'nearest lane main', a ? `${a[0]} ${a[1].toFixed(1)}` : 'n/a');
}

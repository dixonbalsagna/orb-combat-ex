// Proves the JS toolkit reads WorldPlanet's bits: today's surface at the 128 golden points of
// sim/world/tools/planet_vectors.json (two planets, height as 64 bits and the biome).
//   node research/planet-gen/check-base.mjs
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { surf } from './gen/base.mjs';

const V = JSON.parse(readFileSync(fileURLToPath(new URL('../../sim/world/tools/planet_vectors.json', import.meta.url)), 'utf8'));
const f = (hex) => Buffer.from(hex, 'hex').readDoubleLE(0);
let ok = 0, bad = 0;
for (const seed of Object.keys(V)) {
  for (const row of V[seed].points) {
    const [xyz, hHex, bio] = row.split('|');
    const px = f(xyz.slice(0, 16)), py = f(xyz.slice(16, 32)), pz = f(xyz.slice(32, 48));
    const [h, b] = surf(Number(seed), px, py, pz);
    const hb = Buffer.alloc(8); hb.writeDoubleLE(h, 0);
    if (hb.toString('hex') === hHex && b === Number(bio)) ok++;
    else { bad++; if (bad < 6) console.log('MISMATCH', seed, px, py, pz, h, f(hHex), b, bio); }
  }
}
console.log(`base vs WorldPlanet golden vectors: ${ok} of ${ok + bad} points bit-identical (height bits and biome)`);
process.exit(bad ? 1 : 0);

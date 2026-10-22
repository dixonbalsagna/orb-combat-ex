// lp.cjs: on a planet's world, each biome's share of the planet (DirLocation._planet, which the hero's "overstayed"
// test and the villain's prowl read) comes from the planet's own columns (WorldBiomes.planetCols), not from the
// hand-made world's segments. The hand-made world keeps today's tables, so the golden (which plays no planet) doesn't move.
//   node lp.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node lp.cjs <checkout root> [--check]');
const check = opts.includes('--check');
const rel = 'sim/director/location.gd';
const p = path.join(root, rel);
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const a = '\tfor sg in WorldBiomes.SEG:\n\t\t_planet[BIOMES.find(sg[2])] += (sg[1] - sg[0]) / (9600.0 * SimConst.PS)\n';
if (t.split(a).length !== 2) throw new Error(rel + ': the planet share anchor');
t = t.replace(a, () =>
  '\tvar cols: PackedByteArray = WorldBiomes.planetCols\n' +
  '\tif cols.size() > 0:\n' +
  '\t\t# a planet\'s world: each biome\'s share of its own columns (the hand-made world\'s segments don\'t describe it)\n' +
  '\t\tfor c in cols:\n' +
  '\t\t\tvar bi: int = BIOMES.find(String(WorldPlanetWorld.BIOME_NAME[c]))\n' +
  '\t\t\tif bi >= 0:\n' +
  '\t\t\t\t_planet[bi] += 1.0 / float(cols.size())\n' +
  '\telse:\n' +
  '\t\tfor sg in WorldBiomes.SEG:\n' +
  '\t\t\t_planet[BIOMES.find(sg[2])] += (sg[1] - sg[0]) / (9600.0 * SimConst.PS)\n');
if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log(rel + (check ? ': anchors ok' : ': a planet\'s shares from its own columns'));

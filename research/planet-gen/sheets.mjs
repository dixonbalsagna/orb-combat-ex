// Contact sheets from run.mjs's pictures: a comparison per seed (today, A, B, C: maps over globes), one sheet per
// approach (six seeds), the fight rings of each seed stacked, and the biome legend.
//   node research/planet-gen/sheets.mjs [root, default research/planet-gen]
import { readFileSync, existsSync } from 'node:fs';
import { inflateSync } from 'node:zlib';
import { join } from 'node:path';
import { Img } from './lib/img.mjs';
import { BIOMES, IS_WATER } from './lib/biomes.mjs';

const ROOT = process.argv[2] || 'research/planet-gen', OUT = join(ROOT, 'img'), SEEDS = [7, 11, 23, 42, 101, 2026];
const ORDER = [['base', 'TODAY'], ['A', 'A CLIMATE'], ['B', 'B PLATES'], ['C', 'C EROSION ON B'], ['Cb', 'C EROSION ON A']];
const BG = [24, 26, 34], INK = [232, 232, 236], DIM = [150, 154, 166];

// Our own PNGs only: 8-bit RGB, filter 0 on every row.
function load(path) {
  const b = readFileSync(path);
  let o = 8, w = 0, h = 0; const idat = [];
  while (o < b.length) {
    const len = b.readUInt32BE(o), type = b.toString('ascii', o + 4, o + 8), data = b.subarray(o + 8, o + 8 + len);
    if (type === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); }
    if (type === 'IDAT') idat.push(data);
    o += 12 + len;
  }
  const raw = inflateSync(Buffer.concat(idat)), img = new Img(w, h, null);
  for (let y = 0; y < h; y++) { if (raw[y * (w * 3 + 1)] !== 0) throw new Error('filter'); raw.copy(Buffer.from(img.d.buffer), y * w * 3, y * (w * 3 + 1) + 1, (y + 1) * (w * 3 + 1)); }
  return img;
}

// 1. per seed: today, A, B, C side by side (maps at half size over globes at half size)
for (const seed of SEEDS) {
  const cols = ORDER.slice(0, 4), cw = 512, gap = 12, W = cols.length * cw + (cols.length + 1) * gap, H = 34 + 22 + 256 + 12 + 240 + 12;
  const sh = new Img(W, H, BG);
  sh.text(gap, 8, `SEED ${seed}: TODAY AGAINST THE THREE APPROACHES. MAPS: THE FIGHT RING DOTTED, ITS TOUCH-DOWN A RED CROSS. GLOBES: FRONT AND BACK`, 2, INK);
  cols.forEach(([k, label], i) => {
    const x = gap + i * (cw + gap);
    sh.text(x, 36, label, 2, DIM);
    sh.blit(load(join(OUT, k, `s${seed}-map.png`)).shrink(2), x, 56);
    sh.blit(load(join(OUT, k, `s${seed}-front.png`)).shrink(2), x + 8, 56 + 256 + 12);
    sh.blit(load(join(OUT, k, `s${seed}-back.png`)).shrink(2), x + 8 + 240 + 16, 56 + 256 + 12);
  });
  sh.save(join(OUT, `compare-s${seed}.png`));
}

// 2. per approach: the six seeds
for (const [k, label] of ORDER) {
  const cw = 512, gap = 12, W = 3 * cw + 4 * gap, H = 40 + 2 * (22 + 256 + gap);
  const sh = new Img(W, H, BG);
  sh.text(gap, 10, `${label}: SIX SEEDS`, 2, INK);
  SEEDS.forEach((seed, i) => {
    const x = gap + (i % 3) * (cw + gap), y = 40 + Math.floor(i / 3) * (22 + 256 + gap);
    sh.text(x, y, `SEED ${seed}`, 2, DIM);
    sh.blit(load(join(OUT, k, `s${seed}-map.png`)).shrink(2), x, y + 20);
  });
  sh.save(join(OUT, `sheet-${k}.png`));
}

// 3. per seed: the fight ring in every approach, stacked
for (const seed of SEEDS) {
  const strips = ORDER.map(([k]) => load(join(OUT, k, `s${seed}-ring.png`)));
  const W = strips[0].w, H = strips.reduce((a, s) => a + s.h + 6, 30);
  const sh = new Img(W, H, BG);
  sh.text(6, 8, `SEED ${seed}: THE 4,800-COLUMN FIGHT RING, SIDE ON (SQUARE-ROOT HEIGHT SCALE; RED LINE: THE TOUCH-DOWN)`, 2, INK);
  let y = 30; for (const s of strips) { sh.blit(s, 0, y); y += s.h + 6; }
  sh.save(join(OUT, `rings-s${seed}.png`));
}

// 4. the legend: every biome and the approaches that use it (from stats/*.json land shares)
const used = {};
for (const [k] of ORDER) {
  const p = join(ROOT, 'stats', `${k}.json`);
  if (!existsSync(p)) continue;
  const j = JSON.parse(readFileSync(p, 'utf8'));
  for (const s of Object.values(j.seeds)) {
    for (const [name] of s.map.landBiomes) (used[name] ||= new Set()).add(k);
    for (const name of Object.keys(s.map.water)) (used[name] ||= new Set()).add(k);
  }
}
(used['River'] ||= new Set()).add('C').add('Cb');   // rivers are channels (a flag), not a share of the map
const rowH = 26, L = new Img(760, 40 + BIOMES.length * rowH, BG);
L.text(10, 10, 'BIOMES (AND THE APPROACHES THAT PRODUCE THEM)', 2, INK);
BIOMES.forEach(([id, , name, rgb], i) => {
  const y = 40 + i * rowH;
  L.fill(10, y, 40, 20, rgb);
  L.text(60, y + 3, name + (IS_WATER[id] ? ' (WATER)' : ''), 2, INK);
  L.text(470, y + 3, [...(used[name] || [])].map((k) => (k === 'base' ? 'TODAY' : k)).join(' '), 2, DIM);
});
L.save(join(OUT, 'legend.png'));
console.log('sheets written');

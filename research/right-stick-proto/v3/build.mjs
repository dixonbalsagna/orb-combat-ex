// Builds the single-file prototype docs/ep/prototypes/right-hand-v3.html from v3/page.html and the sim's three parts (the
// sim, its drawing and its clips, with no DOM, between the "HAND SIM" and "PAGE" markers that gif.mjs reads back).
//   node research/right-stick-proto/v3/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
const D = 'research/right-stick-proto/v3/', OUT = 'docs/ep/prototypes/right-hand-v3.html';
const page = readFileSync(D + 'page.html', 'utf8'), sim = ['sim-core.js', 'sim-draw.js', 'sim-clips.js'].map((f) => readFileSync(D + f, 'utf8')).join('\n');
if (!page.includes('/*SIM*/')) throw new Error('no /*SIM*/ slot in page.html');
writeFileSync(OUT, page.replace('/*SIM*/', () => sim.trimEnd()));
console.log(OUT + ' built');

// Builds the single-file prototype docs/ep/prototypes/right-stick-v1.html from work/page.html and work/sim.js (the sim and
// its drawing, with no DOM, between the "STICK SIM" and "PAGE" markers that gif.mjs reads back).
//   node research/right-stick-proto/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
const page = readFileSync('research/right-stick-proto/work/page.html', 'utf8'), sim = readFileSync('research/right-stick-proto/work/sim.js', 'utf8');
if (!page.includes('/*SIM*/')) throw new Error('no /*SIM*/ slot in page.html');
writeFileSync('docs/ep/prototypes/right-stick-v1.html', page.replace('/*SIM*/', () => sim.trimEnd()));
console.log('docs/ep/prototypes/right-stick-v1.html built');

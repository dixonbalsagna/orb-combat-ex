// Builds the single-file prototype docs/ep/prototypes/energy-v1.html from work/page.html and work/sim.js (the sim and its
// drawing, with no DOM, between the "ENERGY SIM" and "PAGE" markers that gif.mjs reads back).
//   node research/energy-proto/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
const page = readFileSync('research/energy-proto/work/page.html', 'utf8'), sim = readFileSync('research/energy-proto/work/sim.js', 'utf8');
if (!page.includes('/*SIM*/')) throw new Error('no /*SIM*/ slot in page.html');
writeFileSync('docs/ep/prototypes/energy-v1.html', page.replace('/*SIM*/', () => sim.trimEnd()));
console.log('docs/ep/prototypes/energy-v1.html built');

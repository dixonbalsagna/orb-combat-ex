// Builds the single-file prototype docs/ep/prototypes/rally-v1.html from work/page.html and work/sim.js (the sim and its
// drawing, with no DOM, between the "RALLY SIM" and "PAGE" markers that gif.mjs reads back).
//   node research/rally-proto/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
const page = readFileSync('research/rally-proto/work/page.html', 'utf8'), sim = readFileSync('research/rally-proto/work/sim.js', 'utf8');
if (!page.includes('/*SIM*/')) throw new Error('no /*SIM*/ slot in page.html');
writeFileSync('docs/ep/prototypes/rally-v1.html', page.replace('/*SIM*/', () => sim.trimEnd()));
console.log('docs/ep/prototypes/rally-v1.html built');

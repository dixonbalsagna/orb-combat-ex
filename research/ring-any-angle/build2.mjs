// Builds research/ring-any-angle/proto-v2.html: the turntable spike, one file, raw WebGL2, planet 7's real gen 2 ground inlined (gen2-p7.pack, from levels.mjs).
//   node research/ring-any-angle/build2.mjs
import { readFileSync, writeFileSync } from 'node:fs';
const D = 'research/ring-any-angle/', page = readFileSync(D + 'page2.html', 'utf8');
if (!page.includes('/*BUNDLE*/')) throw new Error('no slot');
writeFileSync(D + 'proto-v2.html', page.replace('/*BUNDLE*/', () => "var GEN2PACK = '" + readFileSync(D + 'gen2-p7.pack').toString('base64') + "';"));
console.log(D + 'proto-v2.html built, ' + Math.round(readFileSync(D + 'proto-v2.html').length / 1024) + ' KB');

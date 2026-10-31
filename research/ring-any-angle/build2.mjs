// Builds research/ring-any-angle/proto-v2.html: the turntable spike, one file, raw WebGL2, the planet's noise bundled in.
//   node research/ring-any-angle/build2.mjs
import { readFileSync, writeFileSync } from 'node:fs';
const D = 'research/ring-any-angle/', rd = (p) => readFileSync(p, 'utf8');
function mod(path, names, deps = '', sub = (s) => s) {
  const body = sub(rd(path)).replace(/^import .*$/gm, '').replace(/^export \{[^}]*\};?$/gm, '').replace(/^export /gm, '');
  return `(function () {\n${deps}\n${body}\nreturn { ${names.join(', ')} };\n})()`;
}
const planet = JSON.stringify(JSON.parse(rd('data/biomes/planet.json')));
const bundle = [
  `var __math = ${mod('sim/core/detmath.js', ['sin', 'cos', 'pow'])};`,
  `var __rng = ${mod('sim/core/rng.js', ['createRng', 'next'])};`,
  `var __det = ${mod('research/planet-gen/lib/det.mjs', ['R', 'fbm', 'ss', 'lat'], 'var sin = __math.sin, cos = __math.cos, pow = __math.pow, createRng = __rng.createRng, next = __rng.next;')};`,
  `var __base = ${mod('research/planet-gen/gen/base.mjs', ['surf'], 'var R = __det.R, fbm = __det.fbm, ss = __det.ss, lat = __det.lat, pow = __math.pow;', (s) => s.replace(/const C = JSON\.parse\([^\n]*\n/, `const C = ${planet};\n`))};`,
  'var surf = __base.surf;'].join('\n');
const page = rd(D + 'page2.html'); if (!page.includes('/*BUNDLE*/')) throw new Error('no slot');
writeFileSync(D + 'proto-v2.html', page.replace('/*BUNDLE*/', () => bundle));
console.log(D + 'proto-v2.html built, ' + Math.round(rd(D + 'proto-v2.html').length / 1024) + ' KB');

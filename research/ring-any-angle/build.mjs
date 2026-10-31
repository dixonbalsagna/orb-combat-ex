// Builds research/ring-any-angle/proto.html: one file that opens from file://, with the planet's noise (planet-gen's port, bit-exact
// with WorldPlanet) bundled in. Each module runs in its own scope, so their top-level names don't meet.
//   node research/ring-any-angle/build.mjs
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
  `var __det = ${mod('research/planet-gen/lib/det.mjs', ['R', 'fbm', 'ss', 'lat', 'atan2f'], 'var sin = __math.sin, cos = __math.cos, pow = __math.pow, createRng = __rng.createRng, next = __rng.next;')};`,
  `var __base = ${mod('research/planet-gen/gen/base.mjs', ['surf'], 'var R = __det.R, fbm = __det.fbm, ss = __det.ss, lat = __det.lat, pow = __math.pow;', (s) => s.replace(/const C = JSON\.parse\([^\n]*\n/, `const C = ${planet};\n`))};`,
  'var surf = __base.surf, sin = __math.sin, cos = __math.cos, atan2f = __det.atan2f, R = __det.R;',
  rd(D + 'sim.js'), rd(D + 'draw.js')].join('\n');
const page = rd(D + 'page.html'); if (!page.includes('/*BUNDLE*/')) throw new Error('no slot');
writeFileSync(D + 'proto.html', page.replace('/*BUNDLE*/', () => bundle));
console.log(D + 'proto.html built, ' + Math.round(bundle.length / 1024) + ' KB of script');

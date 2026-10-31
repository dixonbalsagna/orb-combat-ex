// SCRATCH: a seam test: in each still of a folder (sky magenta), magenta runs in a column, under something drawn, with something drawn below them too.
// A crack is a run of at most 8 pixels; a longer run is sky seen under an overhang of the picture (a tower's top beside it), and is listed apart, with where the worst one is.
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const [wcag, dir] = process.argv.slice(2);
const { decodePng } = require(wcag);
let cracks = 0, worst = 0, worstFile = '', files = 0, withAny = 0, large = 0, largeRun = 0, largeAt = '';
const where = [];
for (const f of readdirSync(dir).filter((x) => x.endsWith('.png')).sort()) {
  const p = decodePng(readFileSync(join(dir, f)));
  let n = 0;
  for (let x = 0; x < p.w; x++) {
    let seen = false, run = 0;
    for (let y = 0; y < p.h; y++) {
      const i = (y * p.w + x) * 4;
      const m = p.data[i] > 235 && p.data[i + 1] < 40 && p.data[i + 2] > 235;
      if (m) { if (seen) run++; continue; }
      if (seen && run > 0) {
        if (run <= 8) { n += run; if (where.length < 6) where.push(`${f}:${x},${y}`); }
        else { large += run; if (run > largeRun) { largeRun = run; largeAt = `${f}:${x},${y}`; } }
      }
      seen = true;
      run = 0;
    }
  }
  files++;
  cracks += n;
  if (n) withAny++;
  if (n > worst) { worst = n; worstFile = f; }
}
console.log(`${dir.split(/[\\/]/).pop()}: ${files} stills, ${withAny} with a crack; ${cracks} crack pixels, worst still ${worst} (${worstFile}); first at ${where.join(' ')}; longer runs ${large} pixels, longest ${largeRun} at ${largeAt}`);

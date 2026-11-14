// Applies the switches the page's match file says were on, in a scratch tree: node pageflip.mjs <repo> <tree> <switches.json>
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
const [repo, tree, listFile] = process.argv.slice(2);
const mod = await import(pathToFileURL(join(repo, 'tools/preview/switches.mjs')).href);
const all = mod.SWITCHES || mod.switches || mod.default;
const want = JSON.parse(readFileSync(listFile, 'utf8'));
let n = 0;
for (const sw of all) {
  if (!want.includes(sw.id) || !sw.file || !sw.path) continue;
  const p = join(tree, sw.file);
  if (!existsSync(p)) { console.log('missing', sw.id, sw.file); continue; }
  const j = JSON.parse(readFileSync(p, 'utf8'));
  let o = j;
  for (const k of sw.path.slice(0, -1)) { if (o[k] === undefined) { o = null; break; } o = o[k]; }
  if (!o) { console.log('no path', sw.id); continue; }
  o[sw.path[sw.path.length - 1]] = sw.to;
  writeFileSync(p, JSON.stringify(j, null, 2) + '\n');
  n++;
  console.log('on', sw.id, sw.file, sw.path.join('.'), JSON.stringify(sw.to));
}
console.log('flipped', n);

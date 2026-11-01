// The handover (the EP, 2026-11-01, item 10 of docs/ep/first-press-list.md): Orb gets exactly the build that passed, kept untouched.
//
//   node tools/preview/handover.mjs --dir <the built web folder> --out <a folder OUTSIDE the repository> [--serve [--port 8766]]
//
// It copies the web folder to <out>/orb-first-play-<commit8>-<build key 8>/web (the commit and the key are read from the page itself: the black box stamps them into index.html as window.__build and into every saved match file as `build`),
// checks the copy byte for byte against the source, marks every file read-only, and writes a README.txt beside it. Nothing in the copy is ever rebuilt or swapped: land anything you like in the repository afterwards, the copy stays the
// build Orb played, so Orb's first match stays a watchable clip (blackbox-clip.mjs --dir <that web folder>). --serve then serves the copy on 127.0.0.1 (the same local server as the page; no watch, no rebuild).
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync, chmodSync } from 'node:fs';
import { join, resolve, sep } from 'node:path';
import { serveLocal } from './preview.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), OUT = opt('--out');
if (opt('--serve-only')) {   // serve a kept copy again, as it is: no copy, no watch, no rebuild
  const server = await serveLocal(resolve(opt('--serve-only')), Number(opt('--port', 8766)), { strict: true });
  console.log(`serving ${resolve(opt('--serve-only'))} at http://127.0.0.1:${server.address().port}/index.html (Ctrl-C stops it)`);
  await new Promise(() => {});
}
if (!DIR || !OUT) { console.error('usage: node tools/preview/handover.mjs --dir <built web folder> --out <folder outside the repository> [--serve [--port 8766]]'); process.exit(2); }
const repo = resolve(new URL('../..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const out = resolve(OUT);
if (out === repo || out.startsWith(repo + sep)) { console.error('refused: the copy goes OUTSIDE the repository (a landing, a checkout or a clean could touch it)'); process.exit(2); }
const src = resolve(DIR);
const index = join(src, 'index.html');
if (!existsSync(index)) { console.error(`no index.html in ${src}`); process.exit(2); }
const html = readFileSync(index, 'utf8');
const m = html.match(/window\.__build = (\{.*?\});<\/script>/s);
if (!m) { console.error('this build carries no stamp (window.__build): it was made without the black box, or by older tools. Rebuild it with the current tools first.'); process.exit(2); }
const build = JSON.parse(m[1]);
const name = `orb-first-play-${String(build.commit).slice(0, 8)}-${String(build.folder || build.stackKey || '').replace(/[^A-Za-z0-9]/g, '').slice(0, 8)}`;
const dest = join(out, name);
if (existsSync(dest)) { console.error(`refused: ${dest} already exists (a handover copy is never overwritten)`); process.exit(2); }
mkdirSync(join(dest, 'web'), { recursive: true });
cpSync(src, join(dest, 'web'), { recursive: true });
const walk = (d) => readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(join(d, e.name)) : [join(d, e.name)]));
const a = walk(src), b = walk(join(dest, 'web'));
let bad = a.length === b.length ? 0 : 1;
for (let i = 0; i < a.length && !bad; i++) { if (statSync(a[i]).size !== statSync(b[i]).size || !readFileSync(a[i]).equals(readFileSync(b[i]))) bad++; }
if (bad) { console.error('the copy differs from the source: refused'); process.exit(1); }
for (const f of b) { try { chmodSync(f, 0o444); } catch { /* read-only is a courtesy on Windows */ } }
writeFileSync(join(dest, 'README.txt'), [
  `The build Orb played: commit ${build.commit} ${build.subject || ''}`,
  `Made ${new Date().toISOString()} from the stack of ${build.parks ? build.parks.length : '?'} parks (key ${build.stackKey}); folder name in the tools' cache: ${build.folder || '?'}.`,
  `${a.length} files, checked byte for byte against the source. Untouched since: never rebuild, swap or edit this folder.`,
  '',
  'To serve this copy again, as it is (no watch, no rebuild):   node tools/preview/handover.mjs --serve-only "<this folder>/web" --port 8766',
  'To watch a saved match file as a clip:   node tools/preview/blackbox-clip.mjs --file <the saved json> --dir "<this folder>/web" --out <a folder>',
  'The saved file names this build in its `build` field.',
].join('\n') + '\n');
console.log(`copied to ${dest}\\web: ${a.length} files, identical to the source, read-only; commit ${build.commit}, ${build.parks ? build.parks.length : '?'} parks`);
if (argv.includes('--serve')) {
  const port = Number(opt('--port', 8766));
  const server = await serveLocal(join(dest, 'web'), port, { strict: true });
  console.log(`serving the copy at http://127.0.0.1:${server.address().port}/index.html (Ctrl-C stops it; nothing watches or rebuilds it)`);
}

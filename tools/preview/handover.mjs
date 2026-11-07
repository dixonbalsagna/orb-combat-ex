// The handover (the EP, 2026-11-01, item 10 of docs/ep/first-press-list.md): Orb gets exactly the build that passed, kept untouched.
//
//   node tools/preview/handover.mjs --dir <the built web folder> [--out <a folder>] [--repo <the repository, when run from a copy of the tools>] [--serve [--port 8766]]
//   --out defaults to <repository>/homework/Files/builds, the one place inside the repository a copy may go (git-ignored, under homework/.gdignore): Orb's rule, 2026-11-01, that everything for the project stays inside its folder. Any other folder inside the repository is refused (a landing, a checkout or a clean could touch it); one outside it is allowed.
//
// It copies the web folder to <out>/orb-first-play-<commit8>-<build key 8>/web (the commit and the key are read from the page itself: the black box stamps them into index.html as window.__build and into every saved match file as `build`),
// checks the copy byte for byte against the source, marks every file read-only, and writes a README.txt beside it. Nothing in the copy is ever rebuilt or swapped: land anything you like in the repository afterwards, the copy stays the
// build Orb played, so Orb's first match stays a watchable clip (blackbox-clip.mjs --dir <that web folder>). --serve then serves the copy on 127.0.0.1 (the same local server as the page; no watch, no rebuild).
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync, chmodSync } from 'node:fs';
import { join, resolve, sep } from 'node:path';
import { spawnSync } from 'node:child_process';
import { serveLocal } from './preview.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir');
if (opt('--serve-only')) {   // serve a kept copy again, as it is: no copy, no watch, no rebuild
  const server = await serveLocal(resolve(opt('--serve-only')), Number(opt('--port', 8766)), { strict: true });
  console.log(`serving ${resolve(opt('--serve-only'))} at http://127.0.0.1:${server.address().port}/index.html (Ctrl-C stops it)`);
  await new Promise(() => {});
}
if (!DIR) { console.error('usage: node tools/preview/handover.mjs --dir <built web folder> [--out <folder>] [--repo <repository>] [--serve [--port 8766]]'); process.exit(2); }
const repo = resolve(opt('--repo') || decodeURIComponent(new URL('../..', import.meta.url).pathname).replace(/^\/([A-Za-z]:)/, '$1'));   // decoded: the folder "Claude Proj" has a space, and an encoded %20 made the homework check refuse a copy from the repository's own tools (2026-11-07)
const BUILDS = join(repo, 'homework', 'Files', 'builds');
const out = resolve(opt('--out') || BUILDS);
if (out === repo || out.startsWith(repo + sep)) {
  // the one allowed place inside the repository: homework/Files/builds, if git ignores it and a .gdignore keeps Godot out of it
  const ignored = spawnSync('git', ['check-ignore', '-q', join(BUILDS, 'x', 'web', 'index.pck')], { cwd: repo }).status === 0;
  if (out !== BUILDS || !ignored || !existsSync(join(repo, 'homework', '.gdignore'))) { console.error(`refused: inside the repository only ${BUILDS} may hold a copy, and only while git ignores it and homework/.gdignore exists (a landing, a checkout or a clean could touch any other)`); process.exit(2); }
}
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
// the tree of the build, kept with it (the EP's rule of 2026-11-02): <build>/replay-tree (written by stack-preview.mjs), or the folder named by --tree; refused without one unless --no-tree
const treeSrc = opt('--tree') ? resolve(opt('--tree')) : join(resolve(src, '..'), 'replay-tree');
const noTree = argv.includes('--no-tree');
if (!noTree && !existsSync(join(treeSrc, 'sim'))) { console.error(`refused: this build has no replay tree (${treeSrc}). Build it again with the current stack-preview.mjs, or name a tree with --tree <folder>, or --no-tree to leave it out (a saved match could then not be replayed exactly)`); process.exit(2); }
mkdirSync(join(dest, 'web'), { recursive: true });
cpSync(src, join(dest, 'web'), { recursive: true });
if (!noTree) { cpSync(treeSrc, join(dest, 'tree'), { recursive: true }); }
const walk = (d) => readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(join(d, e.name)) : [join(d, e.name)]));
const a = walk(src), b = walk(join(dest, 'web'));
let bad = a.length === b.length ? 0 : 1;
for (let i = 0; i < a.length && !bad; i++) { if (statSync(a[i]).size !== statSync(b[i]).size || !readFileSync(a[i]).equals(readFileSync(b[i]))) bad++; }
if (bad) { console.error('the copy differs from the source: refused'); process.exit(1); }
for (const f of b) { try { chmodSync(f, 0o444); } catch { /* read-only is a courtesy on Windows */ } }
if (!noTree) {   // the kept tree: the same byte check, the same read-only
  const ta = walk(treeSrc), tb = walk(join(dest, 'tree'));
  let tbad = ta.length === tb.length ? 0 : 1;
  for (let i = 0; i < ta.length && !tbad; i++) { if (statSync(ta[i]).size !== statSync(tb[i]).size || !readFileSync(ta[i]).equals(readFileSync(tb[i]))) tbad++; }
  if (tbad) { console.error('the tree copy differs from the source: refused'); process.exit(1); }
  for (const f of tb) { try { chmodSync(f, 0o444); } catch { /* a courtesy */ } }
}
// The copy serves itself: a standalone server (node's own modules only, no repository file) and the window that runs it, next to the web folder, so the game never depends on the repository's tools or state.
writeFileSync(join(dest, 'serve.mjs'), [
  "// Serves the web folder next to this file on 127.0.0.1 only. Node's own modules only. Usage: node serve.mjs [port]   (default 8766)",
  "import { createServer } from 'node:http';",
  "import { existsSync, readFileSync, statSync } from 'node:fs';",
  "import { dirname, extname, join, resolve, sep } from 'node:path';",
  "import { fileURLToPath } from 'node:url';",
  "const base = resolve(dirname(fileURLToPath(import.meta.url)), 'web');",
  "const port = Number(process.argv[2] || 8766);",
  "const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.json': 'application/json', '.css': 'text/css', '.ico': 'image/x-icon', '.webmanifest': 'application/manifest+json' };",
  "const server = createServer((req, res) => {",
  "  let p; try { p = decodeURIComponent(new URL(req.url, 'http://x').pathname); } catch { res.writeHead(400); res.end(); return; }",
  "  if (p.endsWith('/')) p += 'index.html';",
  "  const file = resolve(join(base, p));",
  "  if (!(file === base || file.startsWith(base + sep)) || !existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); res.end('not found'); return; }",
  "  res.writeHead(200, { 'content-type': MIME[extname(file)] || 'application/octet-stream', 'content-length': statSync(file).size, 'cache-control': 'no-store' });",
  "  res.end(readFileSync(file));",
  "});",
  "server.on('error', (e) => { console.error(e.code === 'EADDRINUSE' ? `Port ${port} is already in use: the game may already be running at http://127.0.0.1:${port}/index.html` : String(e.message || e)); process.exit(1); });",
  "server.listen(port, '127.0.0.1', () => console.log(`Serving ${base} at http://127.0.0.1:${port}/index.html (Ctrl-C or closing this window stops it; nothing is built or changed here)`));",
  '',
].join('\n'));
writeFileSync(join(dest, 'serve.cmd'), [
  '@echo off',
  "title Orb Combat EX - the game server: KEEP THIS WINDOW OPEN while you play",
  'echo This window serves the kept build to your browser. Closing it stops the game. Nothing is built here.',
  'echo Kept build: %~dp0web',
  'node "%~dp0serve.mjs" 8766',
  'echo.',
  'echo The server stopped. If you did not close it, the line above says why.',
  'pause',
  '',
].join('\r\n'));
writeFileSync(join(dest, 'README.txt'), [
  `The build Orb played: commit ${build.commit} ${build.subject || ''}`,
  `Made ${new Date().toISOString()} from the stack of ${build.parks ? build.parks.length : '?'} parks (key ${build.stackKey}); folder name in the tools' cache: ${build.folder || '?'}.`,
  `${a.length} files, checked byte for byte against the source. Untouched since: never rebuild, swap or edit this folder.`,
  '',
  'To play: double-click serve.cmd (or run node serve.mjs 8766), then open http://127.0.0.1:8766/index.html?planet=7&meteor=loud&tiles=1&go=1&blackbox=1 . serve.cmd and serve.mjs use only node, no repository file.',
  ...(noTree ? [] : ['The tree of this build (sim, data with the page switches flipped, net, project.godot) is in tree/: a saved match of this build replays exactly with', '  node tools/preview/blackbox-verify.mjs <orb-first-play-....json> --tree "<this folder>/tree"', '']),
  'To serve this copy again from the repository tools, as it is (no watch, no rebuild):   node tools/preview/handover.mjs --serve-only "<this folder>/web" --port 8766',
  'To watch a saved match file as a clip:   node tools/preview/blackbox-clip.mjs --file <the saved json> --dir "<this folder>/web" --out <a folder>',
  'The saved file names this build in its `build` field.',
].join('\n') + '\n');
console.log(`copied to ${dest}\\web: ${a.length} files, identical to the source, read-only; commit ${build.commit}, ${build.parks ? build.parks.length : '?'} parks`);
if (argv.includes('--serve')) {
  const port = Number(opt('--port', 8766));
  const server = await serveLocal(join(dest, 'web'), port, { strict: true });
  console.log(`serving the copy at http://127.0.0.1:${server.address().port}/index.html (Ctrl-C stops it; nothing watches or rebuilds it)`);
}

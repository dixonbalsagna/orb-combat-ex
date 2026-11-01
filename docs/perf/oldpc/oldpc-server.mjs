#!/usr/bin/env node
// The old-PC test's server (Performance and Platform, 2026-11-01; homework/2 Up Next/10). Serves the test page and ONE built copy of the game to ONE other computer on the home network, takes the page's
// report back as a file, and stops itself. Node 24 built-ins only. It changes nothing in the project and uploads nothing anywhere.
//
//   node docs/perf/oldpc/oldpc-server.mjs --site <the stack's web build folder>            show the plan; listens on nothing (a dry run)
//   node docs/perf/oldpc/oldpc-server.mjs --site <folder> --bind 10.0.0.135 --go           listen on that one address only (the PC's address on the home network)
//   node docs/perf/oldpc/oldpc-server.mjs --site <folder> --bind 127.0.0.1 --go            listen on this PC alone (for trying the page; nothing leaves the PC)
//   options: --port 8780   --minutes 45 (it stops itself after this long)   --out <folder for the reports>   --alias oldpc.test (the name the printed address uses; for a local trial only)
//
// What it serves (and nothing else; any other path is a 404):
//   /oldpc/            the test page (docs/perf/oldpc/page.html)
//   /game/...          the files of --site, read only, never cached
//   POST /oldpc/report the page's result, kept as report-<time>.json and .txt in --out (at most 4 MB)
// Who may ask: this PC, and computers whose address shares the first three numbers of --bind (the same home network, /24). A request from anywhere else is refused with 403. It listens on the ONE address
// it is given, never on all addresses: a ZeroTier or VPN adapter of this PC does not see it. Windows Firewall: see docs/perf/oldpc-test-2026-11-01.md (on this PC node.exe already has an Allow rule for the Public
// profile, so no prompt is expected; the report says what was and was not tried).
import { createServer } from 'node:http';
import { createReadStream, existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { networkInterfaces } from 'node:os';
import { dirname, extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SITE = opt('--site') ? resolve(opt('--site')) : null;
const PORT = Number(opt('--port', 8780));
const MINUTES = Number(opt('--minutes', 45));
const OUT = resolve(opt('--out', join(HERE, 'reports')));
const ALIAS = opt('--alias', '');
const GO = argv.includes('--go');
let BIND = opt('--bind', '');

const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json', '.css': 'text/css', '.webmanifest': 'application/manifest+json', '.svg': 'image/svg+xml', '.ogg': 'audio/ogg', '.wav': 'audio/wav', '.mp3': 'audio/mpeg' };

// the candidate home-network addresses of this PC: private IPv4, not loopback, not link-local
const cands = [];
for (const [name, list] of Object.entries(networkInterfaces())) for (const a of list || []) {
  if (a.family !== 'IPv4' || a.internal) continue;
  const [p, q] = a.address.split('.').map(Number);
  const priv = p === 10 || (p === 172 && q >= 16 && q <= 31) || (p === 192 && q === 168);
  if (priv) cands.push({ name, address: a.address, netmask: a.netmask });
}
console.log('This PC\'s private addresses:');
for (const c of cands) console.log(`  ${c.address.padEnd(16)} ${c.name}${/zerotier|vpn|virtual|vethernet|tailscale|hamachi/i.test(c.name) ? '   <- an overlay or virtual adapter: not the home network' : ''}`);

if (!SITE || !existsSync(join(SITE, 'index.html'))) { console.error('\n--site <folder with the game\'s index.html> is required'); process.exit(2); }
if (!BIND) {
  const homes = cands.filter((c) => !/zerotier|vpn|virtual|vethernet|tailscale|hamachi/i.test(c.name));
  if (homes.length === 1) BIND = homes[0].address;
  else { console.error(`\n--bind <address> is required (${homes.length} home-network candidates): pick the one the old PC can reach`); process.exit(2); }
}
const bindInfo = cands.find((c) => c.address === BIND);
const isLoop = BIND === '127.0.0.1';
if (!isLoop && !bindInfo) { console.error(`\n${BIND} is not an address of this PC`); process.exit(2); }
const prefix = isLoop ? '127.' : BIND.split('.').slice(0, 3).join('.') + '.';
const shown = ALIAS || BIND;
console.log(`\nPlan: ${GO ? 'LISTEN' : 'dry run (add --go to listen)'} on ${BIND}:${PORT} only; allowed callers ${isLoop ? 'this PC' : `${prefix}0/24 and this PC`}; stops after ${MINUTES} min.`);
console.log(`Address for the old PC's browser:  http://${shown}:${PORT}/oldpc/`);
if (!GO) process.exit(0);

mkdirSync(OUT, { recursive: true });
const allowed = (ip) => { const a = String(ip || '').replace(/^::ffff:/, ''); return a === '127.0.0.1' || a === '::1' || a.startsWith(prefix); };
const log = (ip, msg) => console.log(`${new Date().toTimeString().slice(0, 8)} ${String(ip).replace(/^::ffff:/, '').padEnd(15)} ${msg}`);
let reported = 0;

const server = createServer((req, res) => {
  const ip = req.socket.remoteAddress;
  if (!allowed(ip)) { log(ip, `403 ${req.method} ${req.url.slice(0, 80)} (not on the home network)`); res.writeHead(403); res.end('no'); return; }
  let p;
  try { p = decodeURIComponent(new URL(req.url, 'http://x').pathname); } catch { res.writeHead(400); res.end(); return; }
  const send = (file, type) => {
    if (!existsSync(file) || !statSync(file).isFile()) { log(ip, `404 ${p}`); res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, { 'content-type': type, 'content-length': statSync(file).size, 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' });
    if (req.method === 'HEAD') { res.end(); return; }
    createReadStream(file).pipe(res);
    if (!/\.(wasm|pck|png|js)$/.test(p)) log(ip, `200 ${p}`);
  };
  if (req.method === 'POST' && p === '/oldpc/report') {
    const chunks = []; let n = 0;
    req.on('data', (c) => { n += c.length; if (n > 4e6) { res.writeHead(413); res.end(); req.destroy(); } else chunks.push(c); });
    req.on('end', () => {
      if (n > 4e6) return;
      const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      let text = Buffer.concat(chunks).toString('utf8'), j = null;
      try { j = JSON.parse(text); } catch { /* keep the text */ }
      const base = join(OUT, `report-${stamp}-${String(ip).replace(/^::ffff:/, '').replace(/[^0-9.a-f:]/gi, '_').replace(/:/g, '_')}`);
      writeFileSync(base + '.json', j ? JSON.stringify(j, null, 1) : text);
      if (j && j.text) writeFileSync(base + '.txt', String(j.text));
      reported++;
      log(ip, `report kept: ${base}.json (${n} bytes)`);
      if (j && j.text) console.log('\n' + String(j.text).split('\n').map((l) => '    ' + l).join('\n') + '\n');
      res.writeHead(200, { 'content-type': 'application/json' }); res.end('{"ok":true}');
      if (reported >= 1) setTimeout(() => { console.log('A report is in. Stopping.'); server.close(); process.exit(0); }, 90000).unref();
    });
    return;
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') { log(ip, `405 ${req.method} ${p}`); res.writeHead(405); res.end(); return; }
  if (p === '/oldpc' || p === '/oldpc/') { send(join(HERE, 'page.html'), MIME['.html']); return; }
  if (p === '/oldpc/ping') { res.writeHead(200, { 'content-type': 'text/plain', 'cache-control': 'no-store' }); res.end('ok'); return; }
  if (p.startsWith('/game/')) {
    let rel = p.slice('/game/'.length); if (rel === '') rel = 'index.html';
    const file = resolve(join(SITE, rel));
    if (!(file === SITE || file.startsWith(SITE + sep))) { log(ip, `403 ${p}`); res.writeHead(403); res.end(); return; }
    send(file, MIME[extname(file).toLowerCase()] || 'application/octet-stream'); return;
  }
  log(ip, `404 ${p}`); res.writeHead(404); res.end('not found');
});
server.on('error', (e) => { console.error('server error: ' + e.message); process.exit(1); });
server.listen(PORT, BIND, () => console.log(`Listening on ${BIND}:${PORT}. Ctrl-C stops it.`));
setTimeout(() => { console.log(`${MINUTES} minutes are up. Stopping.`); server.close(); process.exit(0); }, MINUTES * 60000).unref();
process.on('SIGINT', () => { server.close(); process.exit(0); });

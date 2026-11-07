// Pad lab's tiny static server: node tools/padlab/serve.mjs [--port=8790]
// Serves only index.html and core.js of this folder, on 127.0.0.1 (this computer only). It prints the address and does NOT open a browser.
// The Gamepad API needs a "secure context"; http://127.0.0.1 counts as one.
import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const FILES = { '/index.html': ['index.html', 'text/html; charset=utf-8'], '/core.js': ['core.js', 'text/javascript; charset=utf-8'] };

/** Starts the server; port 0 picks a free one. Resolves with the node http server (listening on 127.0.0.1). */
export function startServer({ port = 8790 } = {}) {
  const server = createServer((req, res) => {
    let p = '/';
    try { p = new URL(req.url, 'http://x').pathname; } catch { /* bad url: 404 below */ }
    if (p === '/') p = '/index.html';
    if (p === '/favicon.ico') { res.writeHead(204); res.end(); return; }
    const hit = FILES[p];
    if (!hit) { res.writeHead(404, { 'content-type': 'text/plain' }); res.end('not found'); return; }
    res.writeHead(200, { 'content-type': hit[1], 'cache-control': 'no-store' });
    res.end(readFileSync(join(here, hit[0])));
  });
  return new Promise((ok, fail) => {
    server.once('error', fail);
    server.listen(port, '127.0.0.1', () => ok(server));
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const arg = process.argv.find((a) => a.startsWith('--port='));
  const port = arg ? Number(arg.slice(7)) : Number(process.env.PADLAB_PORT || 8790);
  startServer({ port }).then((s) => {
    console.log(`Pad lab is ready. Open this address in Chrome or Edge:  http://127.0.0.1:${s.address().port}/`);
    console.log('Nothing is sent anywhere. Press Ctrl+C here to stop the server.');
  }).catch((e) => {
    console.error(e.code === 'EADDRINUSE' ? `Port ${port} is already in use. Pick another with --port=8791` : `Could not start: ${e.message}`);
    process.exit(1);
  });
}

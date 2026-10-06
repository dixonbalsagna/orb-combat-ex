// Checks a built site against tools/site.json: with "offline": true the site directory must hold NO game (no .wasm, no .pck, no script, no manifest, no icon, nothing but the notice pages)
// and each notice page must be exactly the plain page of tools/site-notice.json (no <script>, no external address, noindex, no description, keywords, og: or twitter: tag). With
// "offline": false it only says so and passes.
//   node tools/check-site-offline.mjs --site <site dir> [--config <site.json>]
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve, relative, sep } from 'node:path';
import { siteNotice } from './site-notice.mjs';

const args = process.argv.slice(2);
const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
const site = opt('--site');
if (!site) { console.error('usage: node tools/check-site-offline.mjs --site <site dir> [--config <site.json>]'); process.exit(2); }
const root = resolve(site);
const config = JSON.parse(readFileSync(resolve(opt('--config') || join(import.meta.dirname, 'site.json')), 'utf8'));
if (!config.offline) { console.log('site check: tools/site.json is online; nothing to check here'); process.exit(0); }

const problems = [];
const walk = (d) => readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(join(d, e.name)) : [join(d, e.name)]));
const files = existsSync(root) ? walk(root).map((f) => relative(root, f).split(sep).join('/')) : [];
const PAGES = ['index.html', 'play/index.html', 'bench/index.html', 'band/index.html', '404.html'];
for (const f of files) {
  if (!PAGES.includes(f)) problems.push(`${f} is in an offline site (only ${PAGES.join(', ')} may be)`);
  if (/\.(wasm|pck|js|mjs|webmanifest|png|ico|json|worklet)$/i.test(f)) problems.push(`${f} is a game or app file`);
}
for (const p of PAGES) if (!files.includes(p)) problems.push(`${p} is missing: an old link would not land on the notice`);
const expect = siteNotice(JSON.parse(readFileSync(join(import.meta.dirname, 'site-notice.json'), 'utf8')));
for (const p of PAGES) {
  if (!files.includes(p)) continue;
  const html = readFileSync(join(root, p), 'utf8');
  if (html !== expect) problems.push(`${p} is not the notice page of tools/site-notice.json`);
  if (/<script/i.test(html)) problems.push(`${p} has a script`);
  if (/(https?:)?\/\/[a-z0-9]/i.test(html.replace(/<!doctype[^>]*>/i, ''))) problems.push(`${p} names an external address`);
  if (!html.includes('<meta name="robots" content="noindex">')) problems.push(`${p} is not noindex`);
  if (/<meta[^>]+(name|property)="(description|keywords|og:[^"]*|twitter:[^"]*)"/i.test(html)) problems.push(`${p} has a description, keywords or social-card tag`);
}
const total = files.reduce((n, f) => n + statSync(join(root, f)).size, 0);
if (problems.length) { for (const p of problems) console.error(`site check FAILED: ${p}`); process.exit(1); }
console.log(`site check ok: offline, ${files.length} files (${total} bytes), no .wasm, no .pck, no script, the notice at /, /play/, /bench/, /band/ and /404.html`);

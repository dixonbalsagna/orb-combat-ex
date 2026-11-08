// The take-down that needs no game job (corrective directive CD-02). It writes the offline notice of tools/site-notice-offline.json (Legal RL-171's words) at /, /play/, /bench/,
// /band/ and /404.html, the same page build-site.mjs writes when tools/site.json is offline, but it needs no Godot web export, so .github/workflows/takedown.yml can publish it
// on its own while every other job is red.
//   node tools/site-takedown.mjs --out <site dir>
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { siteNotice } from './site-notice.mjs';

const i = process.argv.indexOf('--out');
const outDir = i > 0 ? process.argv[i + 1] : '';
if (!outDir) {
  console.error('usage: node tools/site-takedown.mjs --out <site dir>');
  process.exit(2);
}
const page = siteNotice(JSON.parse(readFileSync(join(import.meta.dirname, 'site-notice-offline.json'), 'utf8')));
for (const where of ['index.html', 'play/index.html', 'bench/index.html', 'band/index.html', '404.html']) {
  mkdirSync(join(outDir, where, '..'), { recursive: true });
  writeFileSync(join(outDir, where), page);
}
console.log(`take-down site written in ${outDir}: the offline notice at /, /play/, /bench/, /band/ and /404.html, no game files`);

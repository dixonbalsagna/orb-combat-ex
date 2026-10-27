#!/usr/bin/env node
// Builds the phone block of the web export's html/head_include (docs/perf/web-shell/) and puts it into export_presets.cfg.
// Node built-ins only. Deterministic: the output depends only on the files in docs/perf/web-shell/ and the existing line.
//
//   node docs/perf/tools/web-head.mjs --check            exit 1 if export_presets.cfg does not hold the current block
//   node docs/perf/tools/web-head.mjs --write            rewrite the Web preset's html/head_include (only the marked block)
//   node docs/perf/tools/web-head.mjs --write --crumbs   also add the freeze breadcrumbs (web-shell/ocx-crumbs.js; a park: off by default)
//   node docs/perf/tools/web-head.mjs --write --manifest also link manifest.webmanifest (do this only together with the
//                                                        build-site patch that ships the file, see docs/perf/phone-web-fullscreen.md)
//   node docs/perf/tools/web-head.mjs --print            print the block
//   --build "<short hash> <YYYY-MM-DD>"   the report's build line (else env OCX_BUILD, else build_info.json beside the preset, else git there, else unknown); only with --crumbs
//   --cfg <file>   work on another copy of export_presets.cfg (for a scratch export)
//
// The block sits between <!--ocx:begin--> and <!--ocx:end-->. Everything outside it (Tools' key guard, long-press
// block and scroll lock) is left exactly as it is.
import { readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..', '..', '..');
const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
const val = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
const cfgPath = resolve(val('--cfg') || join(root, 'export_presets.cfg'));
const BEGIN = '<!--ocx:begin-->', END = '<!--ocx:end-->';

// The CSS: lock the page to the screen (no rubber-band bounce, no pull-to-refresh, no page scroll), black behind the canvas, no tap flash.
const css = [
  'html,body{position:fixed;top:0;left:0;right:0;bottom:0;width:100%;height:100%;margin:0;overflow:hidden;overscroll-behavior:none;background:#000;touch-action:none}',
  'html{-webkit-tap-highlight-color:transparent;-webkit-text-size-adjust:100%}',
].join('');

// The meta tags. theme-color paints the Android address bar black. The two capable tags make a Home Screen launch open without browser bars
// (iOS 26 does that for every Home Screen site anyway; the tags cover older iOS and Android).
const metas = [
  "<meta name='theme-color' content='#000000'>",
  "<meta name='mobile-web-app-capable' content='yes'>",
  "<meta name='apple-mobile-web-app-capable' content='yes'>",
];

function stripScript(src, file = 'ocx-shell.js') {
  const lines = src.split(/\r?\n/);
  const out = [];
  lines.forEach((raw, i) => {
    const t = raw.trim();
    if (t === '' || t.startsWith('//')) return;
    if (t.includes('"') || t.includes('\\') || t.includes('`') || t.includes('//') || t.includes('$GODOT'))
      throw new Error(`${file} line ${i + 1}: a double quote, backslash, backtick, double slash or $GODOT would break the one-line cfg string`);
    if (!/[;{}(,]$/.test(t) && !/^[)}\]]/.test(t) && !/[{(\[,:?&|+-]$/.test(t))
      throw new Error(`${file} line ${i + 1}: a line must end in ; { } ( or , so joining lines is safe: ${t}`);
    out.push(t);
  });
  return out.join(' ');
}

// The build line of the breadcrumbs' report: the commit's short hash and the build's OWN date (the commit's date), never the visitor's clock. From --build "<hash> <YYYY-MM-DD>", else the environment's OCX_BUILD,
// else the build_info.json beside the preset (tools/write-build-info.mjs writes it, the export packs it, the feedback report reads it: {commit, date}), else git in the preset's folder, else unknown.
function buildId() {
  const i = process.argv.indexOf('--build');
  let v = i >= 0 ? process.argv[i + 1] : process.env.OCX_BUILD;
  if (!v) {
    try {
      const bi = JSON.parse(readFileSync(join(dirname(resolve(cfgPath)), 'build_info.json'), 'utf8'));
      v = String(bi.commit) + ' ' + String(bi.date);
    } catch { v = ''; }
  }
  if (!v) {
    try {
      const dir = dirname(resolve(cfgPath));
      const h = execFileSync('git', ['-C', dir, 'rev-parse', '--short', 'HEAD'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
      const d = execFileSync('git', ['-C', dir, 'log', '-1', '--format=%cs'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
      v = h + ' ' + d;
    } catch { v = ''; }
  }
  return /^[0-9a-f]{4,40} [0-9]{4}-[0-9]{2}-[0-9]{2}$/.test(v || '') ? v : 'unknown';
}

function block(withManifest, withCrumbs) {
  const js = stripScript(readFileSync(join(here, '..', 'web-shell', 'ocx-shell.js'), 'utf8'));
  const link = withManifest ? "<link rel='manifest' href='manifest.webmanifest'>" : '';
  const crumbs = withCrumbs ? '<script>' + stripScript(readFileSync(join(here, '..', 'web-shell', 'ocx-crumbs.js'), 'utf8').split('@@BUILD@@').join(buildId()), 'ocx-crumbs.js') + '</script>' : '';   // the freeze breadcrumbs (a park: only with --crumbs)
  return BEGIN + metas.join('') + link + '<style>' + css + '</style><script>' + js + '</script>' + crumbs + END;
}

const cfg = readFileSync(cfgPath, 'utf8');
const eol = cfg.includes('\r\n') ? '\r\n' : '\n';
const lines = cfg.split(/\r?\n/);
// The head_include line that belongs to the Web preset.
let inWeb = false, idx = -1;
lines.forEach((l, i) => {
  if (/^\[preset\.\d+\]$/.test(l)) inWeb = false;
  if (/^platform="Web"$/.test(l)) inWeb = true;
  if (inWeb && l.startsWith('html/head_include=')) idx = i;
});
if (idx < 0) { console.error('error: no html/head_include in the Web preset of ' + cfgPath); process.exit(1); }
const m = /^html\/head_include="(.*)"$/.exec(lines[idx]);
if (!m) { console.error('error: the head_include line is not a plain one-line string'); process.exit(1); }
let cur = m[1];
const a = cur.indexOf(BEGIN), b = cur.indexOf(END);
const rest = a >= 0 && b > a ? cur.slice(0, a) + cur.slice(b + END.length) : cur;
const withManifest = flag('--manifest') || (a >= 0 && cur.includes("rel='manifest'") && !flag('--no-manifest'));
const withCrumbs = flag('--crumbs') || (a >= 0 && cur.includes('ocx.crumbs.v1') && !flag('--no-crumbs'));
const next = rest + block(withManifest, withCrumbs);

if (flag('--print')) { console.log(block(withManifest, withCrumbs)); process.exit(0); }
if (flag('--check')) {
  if (next === cur) { console.log('head_include is current (' + next.length + ' characters)'); process.exit(0); }
  console.error('head_include is out of date: run node docs/perf/tools/web-head.mjs --write');
  process.exit(1);
}
if (flag('--write')) {
  lines[idx] = 'html/head_include="' + next + '"';
  writeFileSync(cfgPath, lines.join(eol));
  console.log('wrote html/head_include (' + next.length + ' characters, manifest link ' + (withManifest ? 'on' : 'off') + ') to ' + cfgPath);
  process.exit(0);
}
console.error('usage: node docs/perf/tools/web-head.mjs --check | --write [--manifest|--no-manifest] | --print  [--cfg <file>]');
process.exit(2);

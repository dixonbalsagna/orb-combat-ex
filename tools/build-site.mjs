// Assembles the GitHub Pages site. Node built-ins only; deterministic (no clock, no random).
//   node tools/build-site.mjs --web <dir with the Godot web export> --out <site dir> [--commit <sha>] [--band <dir>] [--config <site.json>] [--local]
// OFFLINE SWITCH: tools/site.json {"offline": true} (Orb's order, 2026-10-06) makes the site the plain notice of tools/site-notice-offline.json and nothing else: /, /play/, /bench/, /band/ and
// /404.html are that one static page and no game file is copied. The export is still required and checked, so a broken export still fails CI. Set it to false to publish as below.
// INTERIM SWITCH: tools/site.json {"offline": false, "approved": "<date>", "interim": {"legal": "RL-<n>", "approved": "<date>", "expires": "<date>", "notice": "site-interim.json"}} builds the playable
// site under Legal's interim terms in place of a recorded full-set pass: /play/ is the Godot export behind a click-through (the engine starts only from its button, no autoplay), and
// /, /bench/, /band/, /404.html and /about/ are static pages that lead to it and hold no game. tools/check-site-interim.mjs gates the result in CI. Without "interim" the full-set
// path below is unchanged. Docs: docs/tools/site-interim.md
// Layout of <site dir>:
//   index.html               landing page linking to the Godot build
//   play/                    the Godot web export (index.html, .js, .wasm, .pck, ...)
//   bench/index.html         a one-click benchmark: the same export (loaded from ../play/) with the bench arguments
//                            baked in, a results panel and a "copy result" button. Not linked from the landing page.
//   band/                    (only with --band <dir>) the research band prototype's web export. When its engine files are
//                            byte-identical to /play/'s (the same Godot version and templates) only its index.html and
//                            index.pck are shipped and the engine is loaded from ../play/ (no second 39 MB wasm); otherwise
//                            the whole export is copied. Not linked from the landing page.
// The original prototype (prototype/index.html) is not published: it still shows placeholder names and "AI" to a player (Legal's hold). The file
// stays in the repo, untouched.
// Docs: docs/tools/README.md
import { createHash } from 'node:crypto';
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { siteNotice } from './site-notice.mjs';
import { verify as verifyReleasePass, interimOf } from './flash/release-pass.mjs';
import { aboutPage, gateOverlay, GATE_SCRIPT } from './site-interim.mjs';

const args = process.argv.slice(2);
const opt = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};
const web = opt('--web');
const commit = (opt('--commit') || 'unknown').slice(0, 7);
const out = opt('--out');
if (!web || !out) {
  console.error('usage: node tools/build-site.mjs --web <godot web export dir> --out <site dir>');
  process.exit(2);
}
const webDir = resolve(web);
const outDir = resolve(out);

if (!existsSync(join(webDir, 'index.html')) || !readdirSync(webDir).some((f) => f.endsWith('.wasm'))) {
  console.error(`error: ${webDir} does not look like a Godot web export (needs index.html and a .wasm)`);
  process.exit(1);
}

const configFile = resolve(opt('--config') || join(import.meta.dirname, 'site.json'));
const config = JSON.parse(readFileSync(configFile, 'utf8'));
if (typeof config.offline !== 'boolean') {
  console.error(`error: ${configFile} needs "offline": true or false`);
  process.exit(1);
}

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

if (config.offline) {
  // The notice, and no game: no wasm, pck, script, manifest or icon of the export, and no /bench/ or /band/ build either (the bench runs a match with no gate; the band is playable).
  // the offline words (Legal RL-171: "The playable build is offline for now.", "... they are not fixed yet."): tools/site-notice-offline.json, whatever the interim's holding page says
  const page = siteNotice(JSON.parse(readFileSync(join(import.meta.dirname, 'site-notice-offline.json'), 'utf8')));
  for (const where of ['index.html', 'play/index.html', 'bench/index.html', 'band/index.html', '404.html']) {
    mkdirSync(join(outDir, where, '..'), { recursive: true });
    writeFileSync(join(outDir, where), page);
  }
  console.log(`site built in ${outDir}: OFFLINE (tools/site.json): the notice at /, /play/, /bench/, /band/ and /404.html, no game files`);
  process.exit(0);
}

// INTERIM: Legal's interim terms (RL-136, docs/legal/photosensitivity-note.md addendum 8): the playable build behind a click-through, no autoplay, the finding stated, seven days.
// It does not need the whole set to pass, but it needs Orb's word (approved), Legal's ruling (legal), an expiry, Legal's words (site-interim.json is not a draft) and a recorded
// pass FOR THIS COMMIT with the interim and its waivers in it (tools/flash/release-pass.json; the published build is the measured commit). --local skips the record, not on Actions.
if (config.interim) {
  const problems = [];
  const I = config.interim;
  const dateOk = (d) => typeof d === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(d);
  if (config.offline !== false) problems.push('"interim" needs "offline": false');
  if (!dateOk(config.approved)) problems.push("tools/site.json has no \"approved\" date: the site goes online only on Orb's word, recorded there");
  // OWNER-APPROVED (Orb's order, 2026-10-18): interim.owner names who decided. The build then needs no Legal ruling id, no expiry and no recorded run: the record's verdicts are printed, report only.
  const owner = typeof I.owner === 'string' && I.owner.trim() ? I.owner.trim() : null;
  if (!owner && !(typeof I.legal === 'string' && /^RL-\d+/.test(I.legal))) problems.push("\"interim.legal\" is not a Legal ruling id (RL-<n>): the interim terms are Legal's (or \"interim.owner\" names the owner who decided)");
  if (!dateOk(I.approved)) problems.push('"interim.approved" is not a date');
  if (!owner && !dateOk(I.expires)) problems.push('"interim.expires" is not a date: an interim build has a time limit');
  if (owner && I.expires !== undefined && I.expires !== null && !dateOk(I.expires)) problems.push('"interim.expires" is not a date');
  const noticeFile = resolve(import.meta.dirname, I.notice || 'site-interim.json');
  let text = null;
  try { text = JSON.parse(readFileSync(noticeFile, 'utf8')); } catch (e) { problems.push(`the interim words ${noticeFile} could not be read: ${e.message}`); }
  if (text && text.draft !== false) problems.push(`${noticeFile} is still a draft: Legal's text replaces it and "draft" goes to false`);
  let lic = null;
  try { lic = JSON.parse(readFileSync(join(import.meta.dirname, 'site-licences.json'), 'utf8')); } catch (e) { problems.push(`tools/site-licences.json could not be read (run tools/site_licences.gd): ${e.message}`); }
  // the measured commit: the recorded pass holds for this commit's content, with the interim and its waivers, and agrees with site.json
  const verifyInterimRecord = () => {
    const out = [];
    try { out.push(...verifyReleasePass(undefined, opt('--commit') || 'HEAD')); } catch (e) { out.push(`the recorded pass could not be checked: ${e.message}`); }
    const rec = interimOf();
    if (!rec) out.push('tools/flash/release-pass.json has no "interim" block: the interim is recorded in the pass file with its waivers and its expiry');
    else {
      if (rec.legal !== I.legal) out.push(`the pass file's interim is ${rec.legal}, tools/site.json's is ${I.legal}`);
      if (rec.expires !== I.expires) out.push(`the pass file's interim expires ${rec.expires}, tools/site.json's ${I.expires}`);
    }
    return out;
  };
  if (owner) {
    // report only: what the recorded run says about this commit is printed, and never stops the build
    let rep = [];
    try { rep = verifyReleasePass(undefined, opt('--commit') || 'HEAD'); } catch (e) { rep = [`the recorded pass could not be checked: ${e.message}`]; }
    console.log(`OWNER-APPROVED (${owner}): no recorded run is required; report only, the record says ${rep.length ? rep.length + ' thing(s):' : 'nothing against this commit'}`);
    for (const r of rep.slice(0, 12)) console.log(`  report-only: ${r}`);
  } else if (!args.includes('--local') || process.env.GITHUB_ACTIONS) problems.push(...verifyInterimRecord());
  if (problems.length) {
    console.error('error: the interim playable site is not allowed online:');
    for (const p of problems) console.error(`  ${p}`);
    process.exit(1);
  }
  const shell = resolve(import.meta.dirname, '..', 'docs', 'perf', 'web-shell');
  for (const f of ['manifest.webmanifest', 'icons/icon-192.png', 'icons/icon-512.png']) {
    if (!existsSync(join(shell, f))) { console.error(`error: ${join(shell, f)} is missing`); process.exit(1); }
  }
  cpSync(webDir, join(outDir, 'play'), { recursive: true });
  cpSync(join(shell, 'manifest.webmanifest'), join(outDir, 'play', 'manifest.webmanifest'));
  cpSync(join(shell, 'icons'), join(outDir, 'play', 'icons'), { recursive: true });
  // /play/index.html: the export's page, noindex, with the engine's start moved behind the gate's button
  let play = readFileSync(join(webDir, 'index.html'), 'utf8');
  play = replaceOnce(play, '<title>Orb Combat EX</title>', '<title>Orb Combat EX</title>\n\t\t<meta name="robots" content="noindex">');
  play = replaceOnce(play, "\t\tsetStatusMode('progress');\n\t\tengine.startGame({", "\t\twindow.__startGame = function () {\n\t\tsetStatusMode('progress');\n\t\tengine.startGame({");
  play = replaceOnce(play, '\t\t}, displayFailureNotice);\n\t}\n}());', '\t\t}, displayFailureNotice);\n\t\t};\n\t}\n}());');
  play = replaceOnce(play, '\t<body>\n', `\t<body>\n${gateOverlay(text, { holding: '../', about: '../about/' })}\n`);
  play = replaceOnce(play, '\t</body>', `\t\t${GATE_SCRIPT}\n\t</body>`);
  writeFileSync(join(outDir, 'play', 'index.html'), play);
  const put = (where, html) => { mkdirSync(join(outDir, where, '..'), { recursive: true }); writeFileSync(join(outDir, where), html); };
  // the holding page (the plain notice) is /, /bench/, /band/ and /404.html: no game, no link, and where "Not now" goes
  const holding = siteNotice(JSON.parse(readFileSync(join(import.meta.dirname, 'site-notice.json'), 'utf8')));
  for (const where of ['index.html', 'bench/index.html', 'band/index.html', '404.html']) put(where, holding);
  put('about/index.html', aboutPage(text, lic, { play: '../play/' }));
  console.log(`site built in ${outDir}: INTERIM (${owner ? 'owner-approved: ' + owner + (I.expires ? ', until ' + I.expires : ', no expiry') : I.legal + ', until ' + I.expires}): /play/ behind the click-through; /, /bench/, /band/ and /404.html are the holding page; /about/ has the notices`);
  process.exit(0);
}

// GOING ONLINE: the playable site is published only with Orb's word (site.json "approved": a date) and a recorded full-set pass of the pixel check that matches the commit being
// published (tools/flash/release-pass.json: tools/flash/release-pass.mjs says what makes it stale). --local skips both for a local test build and is refused on GitHub Actions.
if (!args.includes('--local') || process.env.GITHUB_ACTIONS) {
  const problems = [];
  if (!(typeof config.approved === 'string' && /^\d{4}-\d{2}-\d{2}/.test(config.approved))) problems.push('tools/site.json has no "approved" date: the site goes online only on Orb\'s word, recorded there');
  try { problems.push(...verifyReleasePass(undefined, opt('--commit') || 'HEAD')); } catch (e) { problems.push(`the recorded pass could not be checked: ${e.message}`); }
  if (problems.length) {
    console.error('error: the playable site is not allowed online:');
    for (const p of problems) console.error(`  ${p}`);
    console.error('(set "offline": true in tools/site.json to publish the notice instead)');
    process.exit(1);
  }
}

mkdirSync(join(outDir, 'bench'), { recursive: true });
cpSync(webDir, join(outDir, 'play'), { recursive: true });

// Phone web-app files (docs/perf/web-shell/): the manifest and its icons ship in /play/ next to index.html, where the page's manifest link points.
const shell = resolve(import.meta.dirname, '..', 'docs', 'perf', 'web-shell');
for (const f of ['manifest.webmanifest', 'icons/icon-192.png', 'icons/icon-512.png']) {
  if (!existsSync(join(shell, f))) {
    console.error(`error: ${join(shell, f)} is missing; run node docs/perf/tools/make-placeholder-icons.mjs or restore docs/perf/web-shell/`);
    process.exit(1);
  }
}
cpSync(join(shell, 'manifest.webmanifest'), join(outDir, 'play', 'manifest.webmanifest'));
cpSync(join(shell, 'icons'), join(outDir, 'play', 'icons'), { recursive: true });

// ---- /bench/: the exported page, retargeted at ../play/ and given the bench arguments and a results panel ----
function replaceOnce(text, from, to) {
  if (!text.includes(from)) {
    console.error(`error: the Godot page no longer contains ${JSON.stringify(from)}; update tools/build-site.mjs`);
    process.exit(1);
  }
  return text.replace(from, () => to);
}
let bench = readFileSync(join(webDir, 'index.html'), 'utf8');
// The bench page is not an installable app: drop the manifest link (it would 404 at /bench/).
bench = bench.replace("<link rel='manifest' href='manifest.webmanifest'>", '');
for (const file of ['index.icon.png', 'index.apple-touch-icon.png', 'index.png', 'index.js']) bench = replaceOnce(bench, `"${file}"`, `"../play/${file}"`);
bench = replaceOnce(bench, '"executable":"index"', '"executable":"../play/index"');
bench = replaceOnce(bench, '"args":[]', '"args":benchArgs()');
bench = replaceOnce(bench, '<title>Orb Combat EX</title>', '<title>Orb Combat EX bench</title>\n\t\t<meta name="robots" content="noindex">');
bench = replaceOnce(bench, '<script src="../play/index.js"></script>', `<script src="../play/index.js"></script>
		<script>
// Bench arguments: fixed 60 Hz steps, seed 4, 2400 frames, vsync off. Add ?nosplit, ?novfx, ?noragdoll (the animation
// overhaul off), ?noclouds (the sky bare) to the URL to switch those off, ?anim-quality=high|medium|low|minimal to pick an
// animation quality level, and ?frames=N to change the length.
function benchArgs() {
  const q = new URLSearchParams(location.search);
  const frames = Math.max(300, Math.min(20000, parseInt(q.get('frames') || '2400', 10) || 2400));
  const args = ['--fixed-fps', '60', '--', '--seed=4', '--frames=' + frames, '--bench'];
  if (q.has('nosplit')) args.push('--nosplit');
  if (q.has('novfx')) args.push('--novfx');
  if (q.has('noragdoll')) args.push('--noragdoll');
  if (q.has('noclouds')) args.push('--noclouds');
  const aq = q.get('anim-quality');
  if (aq && /^(high|medium|low|minimal)$/.test(aq)) args.push('--anim-quality=' + aq);
  return args;
}
</script>`);
bench = replaceOnce(bench, '</body>', `		<div id="bench-panel" style="position:fixed;left:12px;bottom:12px;max-width:min(560px,calc(100vw - 24px));padding:10px 12px;background:rgba(20,22,28,.92);color:#e8ecf2;font:13px/1.4 system-ui,sans-serif;border:1px solid #4a5160;border-radius:8px;z-index:10">
			<div id="bench-status">Benchmark running. Keep this tab visible and wait; a slow computer can take a few minutes.</div>
			<textarea id="bench-text" readonly rows="12" style="display:none;width:100%;box-sizing:border-box;margin-top:8px;font:12px/1.35 ui-monospace,monospace"></textarea>
			<button id="bench-copy" style="display:none;margin-top:8px;padding:6px 12px;font:inherit;cursor:pointer">Copy result</button>
		</div>
		<script>
(function () {
  const BUILD = ${JSON.stringify(commit)};
  function machine() {
    const out = [];
    let renderer = 'unavailable', vendor = 'unavailable';
    try {
      const gl = document.createElement('canvas').getContext('webgl2') || document.createElement('canvas').getContext('webgl');
      const ext = gl && gl.getExtension('WEBGL_debug_renderer_info');
      if (ext) { renderer = gl.getParameter(ext.UNMASKED_RENDERER_WEBGL); vendor = gl.getParameter(ext.UNMASKED_VENDOR_WEBGL); }
    } catch (e) { /* keep the defaults */ }
    out.push('browser: ' + navigator.userAgent);
    out.push('cores: ' + navigator.hardwareConcurrency);
    out.push('memory (GB, rounded down by the browser): ' + (navigator.deviceMemory === undefined ? 'unavailable' : navigator.deviceMemory));
    out.push('screen: ' + screen.width + 'x' + screen.height + ' at device pixel ratio ' + window.devicePixelRatio);
    out.push('window: ' + window.innerWidth + 'x' + window.innerHeight);
    out.push('webgl renderer: ' + renderer);
    out.push('webgl vendor: ' + vendor);
    return out;
  }
  function report(result) {
    const lines = ['Orb Combat EX web bench', 'build: ' + BUILD, 'page arguments: ' + (location.search || '(default)'), '', '--- result'];
    for (const k of Object.keys(result)) lines.push(k + ': ' + (typeof result[k] === 'object' ? JSON.stringify(result[k]) : result[k]));
    lines.push('', '--- this computer', ...machine());
    return lines.join('\\n');
  }
  const status = document.getElementById('bench-status');
  const box = document.getElementById('bench-text');
  const copy = document.getElementById('bench-copy');
  const started = performance.now();
  const timer = setInterval(function () {
    if (window.__benchResult) {
      clearInterval(timer);
      box.value = report(window.__benchResult);
      box.style.display = 'block';
      copy.style.display = 'inline-block';
      status.textContent = 'Done. Press "Copy result" and paste the text into your message.';
    } else if (performance.now() - started > 300000) {
      status.textContent = 'Still running after 5 minutes. This computer is slow: keep waiting, or close the tab and say so.';
    }
  }, 500);
  copy.addEventListener('click', function () {
    box.select();
    const done = function () { copy.textContent = 'Copied'; };
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(box.value).then(done, function () { document.execCommand('copy'); done(); });
    else { document.execCommand('copy'); done(); }
  });
})();
		</script>
	</body>`);
writeFileSync(join(outDir, 'bench', 'index.html'), bench);

// ---- /band/: Research's band prototype, reusing /play/'s engine files when they are identical ----
const bandArg = opt('--band');
let bandMode = '';
if (bandArg) {
  const bandDir = resolve(bandArg);
  if (!existsSync(join(bandDir, 'index.html')) || !existsSync(join(bandDir, 'index.pck'))) {
    console.error(`error: ${bandDir} does not look like a Godot web export (needs index.html and index.pck)`);
    process.exit(1);
  }
  const sha = (file) => (existsSync(file) ? createHash('sha256').update(readFileSync(file)).digest('hex') : null);
  const sameEngine = ['index.wasm', 'index.js'].every((f) => sha(join(bandDir, f)) !== null && sha(join(bandDir, f)) === sha(join(webDir, f)));
  if (sameEngine) {
    mkdirSync(join(outDir, 'band'), { recursive: true });
    let band = readFileSync(join(bandDir, 'index.html'), 'utf8');
    for (const file of ['index.icon.png', 'index.apple-touch-icon.png', 'index.png', 'index.js']) band = replaceOnce(band, `"${file}"`, `"../play/${file}"`);
    // engine files (wasm, audio worklets) load from ../play/index.*; the pack stays the band's own
    band = replaceOnce(band, '"executable":"index"', '"executable":"../play/index","mainPack":"index.pck"');
    writeFileSync(join(outDir, 'band', 'index.html'), band);
    cpSync(join(bandDir, 'index.pck'), join(outDir, 'band', 'index.pck'));
    bandMode = 'engine shared with /play/';
  } else {
    cpSync(bandDir, join(outDir, 'band'), { recursive: true });
    bandMode = 'full copy (its engine files differ from /play/)';
  }
}

writeFileSync(
  join(outDir, 'index.html'),
  `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Orb Combat EX</title>
<style>
  body { font: 16px/1.5 system-ui, sans-serif; max-width: 34rem; margin: 3rem auto; padding: 0 1rem; }
  li { margin: .5rem 0; }
</style>
</head>
<body>
<h1>Orb Combat EX</h1>
<p>Free to play. The build runs in your browser. Built with AI tools under one person's direction; license not chosen yet, all rights reserved for now.</p>
<ul>
  <li><a href="play/">Play the Godot build</a> (work in progress)</li>
</ul>
<p><a href="https://github.com/dixonbalsagna/orb-combat-ex">Source code</a></p>
</body>
</html>
`,
);

const files = readdirSync(outDir, { recursive: true }).length;
console.log(`site built in ${outDir}: /, /play/, /bench/${bandMode ? `, /band/ (${bandMode})` : ''} (${files} entries)`);

// Self-test of the interim playable site (Legal's RL-136): a stub export is built with tools/build-site.mjs under an interim config, then tools/check-site-interim.mjs must pass it and
// must fail each way the interim's conditions can be broken; the placeholder-name scan reads a synthetic pack; the kill switch (tools/site-offline.mjs) is run once for real and its
// result built and checked. No browser, no Godot, no network. CI runs it.
//   node tools/site-interim-selftest.mjs
import { spawnSync } from 'node:child_process';
import { cpSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { INTERIM_WAIVES } from './flash/release-pass.mjs';
import { scanPack, unallowed } from './site-name-scan.mjs';

const here = import.meta.dirname;
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const env = { ...process.env, GITHUB_ACTIONS: '' };   // the build's --local is refused on Actions; the test is not a publication
const node = (script, args) => spawnSync(process.execPath, [join(here, script), ...args], { encoding: 'utf8', env });

const tmp = mkdtempSync(join(tmpdir(), 'site-interim-'));
// a stub of the Godot export page: the lines tools/build-site.mjs looks for are the template's own
const exportHtml = `<!doctype html>
<html><head>
\t\t<meta name="viewport" content="width=device-width, user-scalable=no">
\t\t<title>Orb Combat EX</title>
</head>
\t<body>
\t\t<canvas id="canvas">Your browser does not support the canvas tag.</canvas>
\t\t<div id="status"><progress id="status-progress"></progress><div id="status-notice"></div></div>
\t\t<script src="index.js"></script>
\t\t<script>
const engine = new Engine({});
(function () {
\tconst statusOverlay = document.getElementById('status');
\tlet initializing = true;
\tfunction setStatusMode(mode) { if (mode === 'hidden') { statusOverlay.remove(); initializing = false; } }
\tfunction displayFailureNotice(err) { console.error(err); }
\tconst missing = [];
\tif (missing.length !== 0) {
\t\tdisplayFailureNotice('missing');
\t} else {
\t\tsetStatusMode('progress');
\t\tengine.startGame({
\t\t\t'onProgress': function (current, total) {},
\t\t}).then(() => {
\t\t\tsetStatusMode('hidden');
\t\t}, displayFailureNotice);
\t}
}());
\t\t</script>
\t</body>
</html>
`;
const web = join(tmp, 'web');
mkdirSync(web, { recursive: true });
writeFileSync(join(web, 'index.html'), exportHtml);
for (const f of ['index.js', 'index.wasm', 'index.pck']) writeFileSync(join(web, f), 'x');

// the interim words of the test: the real file (a copy, so the real one is never touched)
// tools/site-interim.json holds no flash words any more (Legal RL-171 retired the RL-136 text: "we are fixing them" is untrue while flash work is paused), and is a draft; the ruling-based path
// (no interim.owner) is still exercised, so the test brings its OWN copy of the old words as a fixture. It is never published.
const RULING_WORDS = {
  "gateP": "This game contains flashing effects, and our own automated check found scenes that reach the recommended limit of three flashes a second, and a few that go over it on stricter readings. We are fixing them, and no independent analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version.",
  "under": "Reduce flashing is on. It lowers some effects but does not remove the flagged scenes.",
  "aboutP": "This game contains flashing effects, and our own automated check found scenes that reach the recommended limit of three flashes a second, and a few that go over it on stricter readings. We are fixing them, and no independent analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version. Reduce flashing is on by default. It lowers some effects but does not remove the flagged scenes."
};
const real = JSON.parse(readFileSync(join(here, 'site-interim.json'), 'utf8'));
const words = { ...real, draft: false, gate: { ...real.gate, blocks: [{ p: RULING_WORDS.gateP }], under: RULING_WORDS.under }, about: { ...real.about, blocks: [...real.about.blocks.slice(0, 4), { h2: 'Flashing effects' }, { p: RULING_WORDS.aboutP + ' Reduce flashing is on by default. It lowers some effects but does not remove the flagged scenes.' }, ...real.about.blocks.slice(4)] } };
const wordsFile = join(tmp, 'words.json');
writeFileSync(wordsFile, JSON.stringify(words));
const cfg = (over = {}) => ({ offline: false, approved: '2026-10-14', interim: { legal: 'RL-136', approved: '2026-10-14', expires: '2026-10-22', notice: wordsFile, ...over } });
const cfgFile = join(tmp, 'site.json');
const writeCfg = (c) => writeFileSync(cfgFile, JSON.stringify(c));
const recordFile = join(tmp, 'release-pass.json');
const writeRecord = (over = {}) => writeFileSync(recordFile, JSON.stringify({ interim: { legal: 'RL-136', from: '2026-10-15', expires: '2026-10-22', waives: INTERIM_WAIVES, ...over } }));
writeRecord();
const build = (out, c, extra = ['--local']) => { writeCfg(c); return node('build-site.mjs', ['--web', web, '--out', out, '--config', cfgFile, ...extra]); };

// a repo root of the shipped prefs and feedback target the checker reads
function prefsRoot(name, { options = true, feature = true, hud = true, target = 'none', lock = true } = {}) {
  const r = join(tmp, name);
  mkdirSync(join(r, 'ui/data'), { recursive: true });
  mkdirSync(join(r, 'ui/hud'), { recursive: true });
  writeFileSync(join(r, 'ui/data/options.json'), JSON.stringify({ schema: 1, options: { reduce_flashing: { default: options } } }));
  writeFileSync(join(r, 'ui/data/features.json'), JSON.stringify({ schema: 1, features: { reduce_flashing: feature, lock_reduce_flashing: lock } }));
  writeFileSync(join(r, 'ui/data/send.json'), JSON.stringify({ schema: 1, _target: target }));
  writeFileSync(join(r, 'ui/hud/ui_hud.gd'), `var opts: Dictionary = {\n\t"reduce_flashing": ${hud},\n}\n`);
  return r;
}
const goodRoot = prefsRoot('root-good');
const verify = (siteDir, c, root = goodRoot, extra = []) => { writeCfg(c); return node('check-site-interim.mjs', ['--site', siteDir, '--config', cfgFile, '--root', root, '--record', recordFile, '--today', '2026-10-16', '--no-pack-scan', ...extra]); };
let copies = 0;
const fresh = () => { const d = join(tmp, 'copy-' + (++copies)); cpSync(join(tmp, 'site-good'), d, { recursive: true }); return d; };
const edit = (d, p, fn) => { const f = join(d, p); writeFileSync(f, fn(readFileSync(f, 'utf8'))); };

try {
  const b = build(join(tmp, 'site-good'), cfg());
  check('the interim site builds from a stub export under a complete interim config', b.status === 0, (b.stderr || b.stdout).slice(0, 300));
  const good = join(tmp, 'site-good');
  const r0 = verify(good, cfg());
  check('the checker passes the built interim site', r0.status === 0, (r0.stderr || r0.stdout).slice(0, 500));
  // the freeze breadcrumbs (tools/site-crumbs.mjs): /play/ carries them exactly when tools/site.json says "crumbs": true, and their script (the real park's, from web-head.mjs) makes no network call
  {
    const head = spawnSync(process.execPath, [join(here, '..', 'docs', 'perf', 'tools', 'web-head.mjs'), '--print', '--crumbs'], { encoding: 'utf8' });
    check('web-head prints the head block with the real breadcrumbs park', head.status === 0 && head.stdout.includes('ocx.crumbs.v1') && head.stdout.includes('<!--ocx:begin-->'), (head.stderr || '').slice(0, 200));
    const webC = join(tmp, 'web-crumbs');
    mkdirSync(webC, { recursive: true });
    writeFileSync(join(webC, 'index.html'), exportHtml.replace('<title>Orb Combat EX</title>', '<title>Orb Combat EX</title>' + head.stdout.trim()));
    for (const f of ['index.js', 'index.wasm', 'index.pck']) writeFileSync(join(webC, f), 'x');
    const on = { ...cfg(), crumbs: true };
    writeCfg(on);
    const bc = node('build-site.mjs', ['--web', webC, '--out', join(tmp, 'site-crumbs'), '--config', cfgFile, '--local']);
    check('an interim site builds from an export that carries the breadcrumbs', bc.status === 0, (bc.stderr || bc.stdout).slice(0, 300));
    const sc = join(tmp, 'site-crumbs');
    check('"crumbs": true and the breadcrumbs on /play/: the checker passes', verify(sc, on).status === 0, (verify(sc, on).stderr || '').slice(0, 300));
    const off = verify(sc, cfg());
    check('breadcrumbs on /play/ with no "crumbs": true: the checker fails (a switched park must not ride in the preset)', off.status === 1 && /does not say "crumbs": true/.test(off.stderr), off.stderr.slice(0, 200));
    const miss = verify(good, on);
    check('"crumbs": true but /play/ has none: the checker fails', miss.status === 1 && /does not carry the freeze breadcrumbs/.test(miss.stderr), miss.stderr.slice(0, 200));
    check('"crumbs": false or absent with a plain page passes (the default)', verify(good, { ...cfg(), crumbs: false }).status === 0 && verify(good, cfg()).status === 0);
    let n = 0;
    for (const [what, inject] of [['a fetch', "fetch('x');"], ['an XMLHttpRequest', 'new XMLHttpRequest();'], ['sendBeacon', "navigator.sendBeacon('x');"], ['a WebSocket', "new WebSocket('x');"], ['a URL', "var u = 'https://example.com';"], ['an image src', 'var i = new Image();']]) {
      const d = join(tmp, 'crumbs-bad-' + (++n));
      cpSync(sc, d, { recursive: true });
      edit(d, 'play/index.html', (t) => t.replace("KEY = 'ocx.crumbs.v1',", () => "KEY = 'ocx.crumbs.v1', zz = (function () { " + inject + " }()),"));
      check(`(the edit for ${what} landed)`, readFileSync(join(d, 'play/index.html'), 'utf8').includes('zz = (function'));
      const r = verify(d, on);
      check(`breadcrumbs whose script has ${what}: the checker fails`, r.status === 1 && /nothing may be sent off the device/.test(r.stderr), r.stderr.slice(0, 200));
    }
  }
  const playHtml = readFileSync(join(good, 'play/index.html'), 'utf8');
  check('the gate is first in the body, "Not now" goes to ../ and the page is noindex', /<body>\n<div id="gate"/.test(playHtml) && /<a id="gate-notnow" href="\.\.\/"/.test(playHtml) && playHtml.includes('<meta name="robots" content="noindex">'));
  check('/, /bench/, /band/ and /404.html are the one holding page and hold no script or game file', ['index.html', 'bench/index.html', 'band/index.html', '404.html'].every((p) => readFileSync(join(good, p), 'utf8') === readFileSync(join(good, 'index.html'), 'utf8') && !/<script/i.test(readFileSync(join(good, p), 'utf8'))) && !existsSync(join(good, 'bench/index.pck')));

  // the build's own refusals
  check('the build refuses an interim without a Legal ruling id', build(join(tmp, 'o1'), cfg({ legal: 'pending' })).status === 1);
  check('the build refuses an interim without an expiry', build(join(tmp, 'o2'), cfg({ expires: null })).status === 1);
  check("the build refuses words that are still a draft (Legal's text has not replaced them)", (() => {
    const f = join(tmp, 'draft.json');
    writeFileSync(f, JSON.stringify({ ...words, draft: true }));
    return build(join(tmp, 'o3'), cfg({ notice: f })).status === 1;
  })());
  check("the build refuses an interim with no approved date (Orb's word)", build(join(tmp, 'o4'), { ...cfg(), approved: null }).status === 1);
  check('the build, not --local, refuses an interim with no recorded pass for the commit (the published build is the measured commit)', build(join(tmp, 'o5'), cfg(), []).status === 1);

  // the checker's refusals, each on a copy of the good site
  const fail = (name, mutate, c = cfg(), root = goodRoot, extra = []) => {
    const d = fresh();
    mutate(d);
    const r = verify(d, c, root, extra);
    check(name, r.status === 1, `exit ${r.status}: ${(r.stderr || r.stdout).slice(0, 200)}`);
  };
  fail('the check fails when the engine starts outside the gate (autoplay)', (d) => edit(d, 'play/index.html', (t) => t.replace('window.__startGame = function () {\n', 'engine.startGame({});\n\t\twindow.__startGame = function () {\n')));
  fail('the check fails when the page calls the start itself on load', (d) => edit(d, 'play/index.html', (t) => t.replace('\t</body>', '\t\t<script>window.__startGame();</script>\n\t</body>')));
  fail('the check fails when the gate is removed', (d) => edit(d, 'play/index.html', (t) => t.replace(/<div id="gate"[\s\S]*?<\/div>\n<\/div>\n/, '')));
  fail("the check fails when the gate's button does not start the game through the handler", (d) => edit(d, 'play/index.html', (t) => t.replace("if (typeof window.__startGame === 'function') window.__startGame();", '')));
  fail('the check fails when "Not now" does not go to the holding page', (d) => edit(d, 'play/index.html', (t) => t.replace('id="gate-notnow" href="../"', 'id="gate-notnow" href="./"')));
  fail('the check fails when "Not now" is missing', (d) => edit(d, 'play/index.html', (t) => t.replace(/<a id="gate-notnow"[^>]*>[^<]*<\/a>/, '')));
  fail('the check fails when /play/ is not noindex', (d) => edit(d, 'play/index.html', (t) => t.replace('<meta name="robots" content="noindex">', '')));
  fail('the check fails when /play/ carries a social card', (d) => edit(d, 'play/index.html', (t) => t.replace('<title>', '<meta property="og:title" content="x"><title>')));
  fail('the check fails when the gate lacks the AI line', (d) => edit(d, 'play/index.html', (t) => t.replace('Nothing in the game is generated by AI while you play', 'Nothing')));
  fail("the check fails when the gate's first sentence is the old one (RL-137 changed it)", (d) => edit(d, 'play/index.html', (t) => t.replace('scenes that reach the recommended limit of three flashes a second, and a few that go over it on stricter readings', 'scenes that reach or go over the recommended limit of three flashes a second')));
  fail("the check fails when About's paragraph has the old first sentence (RL-137)", (d) => edit(d, 'about/index.html', (t) => t.replace('scenes that reach the recommended limit of three flashes a second, and a few that go over it on stricter readings', 'scenes that reach or go over the recommended limit of three flashes a second')));
  fail('the check fails when the gate lacks the finding against three flashes a second', (d) => edit(d, 'play/index.html', (t) => t.replace('three flashes a second', 'a limit')));
  fail('the check fails when a page links to the game with a query (a skip)', (d) => edit(d, 'about/index.html', (t) => t.replace('href="../play/"', 'href="../play/?nointro=1"')));
  fail("the check fails when a page links to the game's files", (d) => edit(d, 'about/index.html', (t) => t.replace('</body>', '<a href="../play/index.pck">pack</a>\n</body>')));
  fail('the check fails when a page links away from the site', (d) => edit(d, 'about/index.html', (t) => t.replace('</body>', '<a href="https://example.com/">x</a>\n</body>')));
  fail('the check fails when a holding page carries a script', (d) => edit(d, 'band/index.html', (t) => t.replace('</body>', '<script>location.href="../play/"</script>\n</body>')));
  fail('the check fails when a holding page is not the holding page', (d) => edit(d, 'bench/index.html', (t) => t.replace('</body>', '<p>hello</p>\n</body>')));
  fail('the check fails when an ungated copy of the game page is in the site', (d) => writeFileSync(join(d, 'play/raw.html'), exportHtml));
  fail('the check fails when the interim has expired', () => {}, cfg({ expires: '2026-10-15' }));
  fail('the check fails when Reduce flashing is not on by default in the options data', () => {}, cfg(), prefsRoot('root-opt', { options: false }));
  fail('the check fails when the Reduce flashing row is not enabled', () => {}, cfg(), prefsRoot('root-feat', { feature: false }));
  fail('the check fails when the export does not lock Reduce flashing on (lock_reduce_flashing is not true: full effects would be offered, Legal RL-156)', () => {}, cfg(), prefsRoot('root-nolock', { lock: false }));
  fail('the check fails when the HUD default is off', () => {}, cfg(), prefsRoot('root-hud', { hud: false }));
  fail('the check fails when the feedback target is not the one the privacy line was written for', () => {}, cfg(), prefsRoot('root-target', { target: 'github' }));
  fail('the check fails when About lacks the privacy line', (d) => edit(d, 'about/index.html', (t) => t.replace('nothing is sent by the game', 'something is sent')));
  fail('the check fails when About lacks the Godot notice line', (d) => edit(d, 'about/index.html', (t) => t.replace('Juan Linietsky, Ariel Manzur. Released', 'Released')));
  fail('the check fails when About lacks the Open Sans notice line', (d) => edit(d, 'about/index.html', (t) => t.replace('Open Sans: Copyright 2020', 'Open Sans: Copyright')));
  fail('the check fails when a page uses a forbidden word', (d) => edit(d, 'about/index.html', (t) => t.replace('</body>', '<p>This build is safe.</p>\n</body>')));
  fail('the check fails when a page shows a placeholder name (KAI)', (d) => edit(d, 'about/index.html', (t) => t.replace('</body>', '<p>KAI fights VORR.</p>\n</body>')));
  // the pass file
  const withRecord = (name, over, c = cfg()) => { writeRecord(over); const d = fresh(); const r = verify(d, c); writeRecord(); return r; };
  check('the check fails when the pass file records another ruling', withRecord('rec-1', { legal: 'RL-135' }).status === 1);
  check('the check fails when the pass file records another expiry', withRecord('rec-2', { expires: '2026-10-29' }).status === 1);
  check('the check fails when the pass file does not name all three waivers', withRecord('rec-3', { waives: ['whole-set-combined-rule'] }).status === 1);
  check('the check fails when the pass file has no interim block', (() => { writeFileSync(recordFile, '{}'); const r = verify(fresh(), cfg()); writeRecord(); return r.status === 1; })());
  // the words file: a word Legal forbids, a draft
  const dirty = { ...words, gate: { ...words.gate, blocks: [...words.gate.blocks, { p: 'This game has been tested for photosensitivity.' }] } };
  const dirtyFile = join(tmp, 'dirty.json');
  writeFileSync(dirtyFile, JSON.stringify(dirty));
  fail('the check fails when the interim words use a word Legal forbids', () => {}, cfg({ notice: dirtyFile }));
  // ---- OWNER-APPROVED mode (Orb's decision, 2026-10-18; Legal's addendum 11): the same gate and safeguards, but no recorded run is required and the verdicts are report-only
  {
    const ownerWords = join(tmp, 'owner-words.json');
    writeFileSync(ownerWords, readFileSync(join(here, 'site-interim-owner.json'), 'utf8'));
    const ownerCfg = (over = {}) => ({ offline: false, approved: '2026-10-18', interim: { owner: 'Orb 2026-10-18', approved: '2026-10-18', expires: '2026-10-25', notice: ownerWords, ...over } });
    // a record that would fail everything (empty): the build and the check must not need it
    writeFileSync(recordFile, '{}');
    const ob = build(join(tmp, 'site-owner'), ownerCfg(), []);
    check('the owner-approved site builds from a stub export WITHOUT a recorded run (not --local)', ob.status === 0, (ob.stderr || ob.stdout).slice(0, 400));
    check('the build says it is owner-approved and prints the record as report only', /OWNER-APPROVED \(Orb 2026-10-18\)/.test(ob.stdout) && /report-only:/.test(ob.stdout), ob.stdout.slice(0, 400));
    const goodO = join(tmp, 'site-owner');
    const verifyO = (d, c = ownerCfg(), root = goodRoot) => { writeCfg(c); return node('check-site-interim.mjs', ['--site', d, '--config', cfgFile, '--root', root, '--record', recordFile, '--today', '2026-10-19', '--no-pack-scan']); };
    const r1 = verifyO(goodO);
    check('the checker passes the owner-approved site with an empty pass file', r1.status === 0, (r1.stderr || r1.stdout).slice(0, 500));
    const gateO = readFileSync(join(goodO, 'play/index.html'), 'utf8');
    check("the owner-approved gate carries Legal's addendum 11 words and the lock line", gateO.includes('some scenes that go over the recommended limit of three flashes a second, and they are not fixed yet. No independent analyzer has been run.') && gateO.includes('Reduce flashing is on and cannot be turned off in this version.'));
    // Legal's fixed lines word for word (docs/legal/page-fixed-lines.md, RL-166, 2026-10-22), on the gate and on the About page; American spelling throughout
    const FIXED_FLASH = "This game contains flashing effects. Our own automated check found some scenes that go over the recommended limit of three flashes a second, and they are not fixed yet. No independent analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version.";
    const FIXED_LOCK = "Reduce flashing is on and cannot be turned off in this version. It lowers some effects but does not remove the flagged scenes.";
    const txt = (h) => h.replace(/<pre>[\s\S]*?<\/pre>/g, ' ').replace(/<style>[\s\S]*?<\/style>/g, ' ').replace(/<script>[\s\S]*?<\/script>/g, ' ').replace(/<[^>]+>/g, ' ').replace(/&quot;/g, '"').replace(/&amp;/g, '&').replace(/\s+/g, ' ');
    check("the owner-approved gate and About carry Legal's flash notice and lock line word for word", txt(gateO).includes(FIXED_FLASH) && txt(gateO).includes(FIXED_LOCK) && txt(readFileSync(join(goodO, 'about/index.html'), 'utf8')).includes(FIXED_FLASH) && txt(readFileSync(join(goodO, 'about/index.html'), 'utf8')).includes(FIXED_LOCK));
    check('no page of the owner-approved site promises a fix or uses a British spelling', !/working to fix them|we are fixing them/i.test(txt(gateO)) && ![...readdirSync(goodO, { recursive: true })].filter((x) => /\.html$/.test(x)).some((x) => /\b(colour|behaviour|grey|centre|artefact|programme|catalogue|neighbour|organis|recognis|licence|analyser)/i.test(txt(readFileSync(join(goodO, x), 'utf8')).replace(/<ul class="small">[\s\S]*?<\/ul>/g, ' '))));
    check('the owner-approved build has no expiry when none is set', build(join(tmp, 'site-owner-open'), ownerCfg({ expires: undefined }), []).status === 0);
    check('an interim with a blank owner and no Legal ruling is refused', build(join(tmp, 'site-owner-blank'), ownerCfg({ owner: '  ' }), []).status === 1);
    check('an owner-approved build still needs the owner\'s date', build(join(tmp, 'site-owner-nodate'), { ...ownerCfg(), approved: null }, []).status === 1);
    check('an owner-approved build still refuses words that are a draft', (() => { const f = join(tmp, 'owner-draft.json'); writeFileSync(f, JSON.stringify({ ...JSON.parse(readFileSync(ownerWords, 'utf8')), draft: true })); return build(join(tmp, 'site-owner-draft'), ownerCfg({ notice: f }), []).status === 1; })());
    let oc = 0;
    const freshO = () => { const d = join(tmp, 'owner-copy-' + (++oc)); cpSync(goodO, d, { recursive: true }); return d; };
    const failO = (name, mutate, c = ownerCfg(), root = goodRoot) => { const d = freshO(); mutate(d); const r = verifyO(d, c, root); check(name, r.status === 1, `exit ${r.status}: ${(r.stderr || r.stdout).slice(0, 200)}`); };
    failO('owner mode: the check still fails when the engine starts outside the gate (autoplay)', (d) => edit(d, 'play/index.html', (t) => t.replace('window.__startGame = function () {\n', 'engine.startGame({});\n\t\twindow.__startGame = function () {\n')));
    failO('owner mode: the check still fails when /play/ is not noindex', (d) => edit(d, 'play/index.html', (t) => t.replace('<meta name="robots" content="noindex">', '')));
    failO('owner mode: the check still fails when "Not now" is missing', (d) => edit(d, 'play/index.html', (t) => t.replace(/<a id="gate-notnow"[^>]*>[^<]*<\/a>/, '')));
    failO('owner mode: the check still fails when the gate lacks the AI line', (d) => edit(d, 'play/index.html', (t) => t.replace('Nothing in the game is generated by AI while you play', 'Nothing')));
    failO('owner mode: the check still fails when the gate lacks the advice for photosensitive epilepsy', (d) => edit(d, 'play/index.html', (t) => t.replace('photosensitive epilepsy, please do not play this version', 'epilepsy')));
    failO('owner mode: the check still fails when the gate does not say no independent analyzer has been run', (d) => edit(d, 'play/index.html', (t) => t.replace('No independent analyzer has been run.', '')));
    failO('owner mode: the check fails when the gate promises a fix (the old "working to fix them" sentence)', (d) => edit(d, 'play/index.html', (t) => t.replace('and they are not fixed yet.', 'and we are working to fix them.')));
    failO('owner mode: the check fails when the gate\'s flash notice differs by a word from Legal\'s fixed line', (d) => edit(d, 'play/index.html', (t) => t.replace('some scenes that go over', 'a few scenes that go over')));
    failO('owner mode: the check fails when About promises a fix', (d) => edit(d, 'about/index.html', (t) => t.replace('and they are not fixed yet.', 'and we are working to fix them.')));
    failO('owner mode: the check fails when About\'s lock line differs from Legal\'s', (d) => edit(d, 'about/index.html', (t) => t.replace('does not remove the flagged scenes.', 'does not remove the flagged scenes at all.')));
    failO('owner mode: the check fails on a British spelling on the gate (licence)', (d) => edit(d, 'play/index.html', (t) => t.replace('I understand, start</button>', 'I understand, start</button><p>Licences</p>')));
    failO('owner mode: the check fails on a British spelling on About (analyser)', (d) => edit(d, 'about/index.html', (t) => t.replace('</body>', '<p>An independent analyser.</p>\n</body>')));
    failO('owner mode: the check fails on a British spelling on the holding page (colour)', (d) => edit(d, 'index.html', (t) => t.replace('</body>', '<p>colour</p>\n</body>')));
    failO('owner mode: the check fails when the gate lacks the line that Reduce flashing cannot be turned off', (d) => edit(d, 'play/index.html', (t) => t.replace('and cannot be turned off in this version', 'by default')));
    failO('owner mode: the check still fails when the export does not lock Reduce flashing on', () => {}, ownerCfg(), prefsRoot('root-owner-nolock', { lock: false }));
    failO('owner mode: the check still fails when Reduce flashing is not on by default', () => {}, ownerCfg(), prefsRoot('root-owner-opt', { options: false }));
    failO('owner mode: the check still fails when About lacks the AI line', (d) => edit(d, 'about/index.html', (t) => t.replace('Nothing in the game is generated by AI while you play', 'Nothing')));
    failO('owner mode: the check still fails when a page uses a forbidden word', (d) => edit(d, 'about/index.html', (t) => t.replace('</body>', '<p>This build is safe.</p>\n</body>')));
    failO('owner mode: the check still fails when a page links to the game with a query (a skip)', (d) => edit(d, 'about/index.html', (t) => t.replace('href="../play/"', 'href="../play/?nointro=1"')));
    failO('owner mode: an expiry that is set is still enforced', () => {}, ownerCfg({ expires: '2026-10-18' }));
    writeRecord();
  }
  // no interim: nothing to check, passes
  writeCfg({ offline: true, approved: null, interim: null });
  const none = node('check-site-interim.mjs', ['--site', good, '--config', cfgFile, '--root', goodRoot]);
  check('without an interim block the checker passes and says so', none.status === 0 && /nothing to check/.test(none.stdout));

  // the name scan of a pack: a synthetic Godot pack (format 4) with two files
  const pack = (files) => {
    const header = 104;
    let data = Buffer.alloc(0);
    const dir = [];
    for (const [path, text] of files) {
      const body = Buffer.from(text, 'latin1');
      dir.push({ path, offset: data.length, size: body.length });
      data = Buffer.concat([data, body]);
    }
    const dirBuf = [];
    const count = Buffer.alloc(4); count.writeUInt32LE(dir.length); dirBuf.push(count);
    for (const d of dir) {
      const p = Buffer.from(d.path + '\0\0', 'utf8');
      const plen = Math.ceil(p.length / 4) * 4;
      const e = Buffer.alloc(4 + plen + 8 + 8 + 16 + 4);
      e.writeUInt32LE(plen, 0); p.copy(e, 4);
      e.writeBigUInt64LE(BigInt(d.offset), 4 + plen); e.writeBigUInt64LE(BigInt(d.size), 12 + plen);
      dirBuf.push(e);
    }
    const h = Buffer.alloc(header);
    h.write('GDPC', 0, 'latin1'); h.writeUInt32LE(4, 4); h.writeUInt32LE(4, 8); h.writeUInt32LE(7, 12); h.writeUInt32LE(2, 16); h.writeUInt32LE(2, 20);
    h.writeBigUInt64LE(BigInt(header), 24); h.writeBigUInt64LE(BigInt(header + data.length), 32);
    return Buffer.concat([h, data, ...dirBuf]);
  };
  const scan = scanPack(pack([['ui/data/terms.json', '{"name": "Orb Combat EX"}'], ['data/combat/recipes.json', 'note: KAI and VORR still draw'], ['ui/core/ui_text.gd', 'Calamity Wave']]));
  check('the pack scan reads a pack\'s directory and finds the placeholder names by file', scan.files === 3 && scan.hits.length === 3 && scan.hits.some((h) => h.word === 'Calamity' && h.path === 'ui/core/ui_text.gd'));
  const allow = { allow: [{ path: 'data/combat/recipes.json', why: 'a note' }] };
  check('a hit in an allowlisted file is allowed and one in a UI file is not', unallowed(scan.hits, allow).length === 1 && unallowed(scan.hits, allow)[0].path === 'ui/core/ui_text.gd');
  check('a word that only contains a name (Kaikai, Meridiana) is not a hit', scanPack(pack([['x.txt', 'Kaikai Meridiana VORRX']])).hits.length === 0);
  // the whole scan inside the checker, with a pack in the site
  {
    const d = fresh();
    writeFileSync(join(d, 'play/index.pck'), pack([['ui/core/ui_text.gd', 'Meridian Warden']]));
    writeCfg(cfg());
    const r = node('check-site-interim.mjs', ['--site', d, '--config', cfgFile, '--root', goodRoot, '--record', recordFile, '--today', '2026-10-16']);
    check('the check fails when the game pack holds a placeholder name in a file that is not allowlisted', r.status === 1 && /Meridian/.test(r.stderr));
    const d2 = fresh();
    writeFileSync(join(d2, 'play/index.pck'), pack([['sim/core/test/frozen/golden-js.json', 'Meridian Warden Calamity Sovereign KAI VORR'], ['ui/data/terms.json', '{}']]));
    const r2 = node('check-site-interim.mjs', ['--site', d2, '--config', cfgFile, '--root', goodRoot, '--record', recordFile, '--today', '2026-10-16']);
    check('a pack whose hits are all on the allowlist passes', r2.status === 0, (r2.stderr || r2.stdout).slice(0, 300));
  }

  // the kill switch, once for real: one command takes an interim config offline, and the next build is the holding page and passes the offline check
  {
    const f = join(tmp, 'kill.json');
    writeFileSync(f, JSON.stringify(cfg(), null, 2) + '\n');
    const before = node('site-offline.mjs', ['--config', f, '--check']);
    check('the kill switch reports an interim config as online', before.status === 1 && /ONLINE/.test(before.stdout));
    const k = node('site-offline.mjs', ['--config', f]);
    const after = JSON.parse(readFileSync(f, 'utf8'));
    check('one command sets offline true, approved null and interim null', k.status === 0 && after.offline === true && after.approved === null && after.interim === null, k.stdout + k.stderr);
    check('the kill switch is idempotent and reports offline', node('site-offline.mjs', ['--config', f]).status === 0 && node('site-offline.mjs', ['--config', f, '--check']).status === 0);
    const out = join(tmp, 'site-off');
    const bo = node('build-site.mjs', ['--web', web, '--out', out, '--config', f]);
    const co = node('check-site-offline.mjs', ['--site', out, '--config', f]);
    check('the build after the kill switch is the holding page alone and passes the offline check', bo.status === 0 && co.status === 0 && !existsSync(join(out, 'play/index.pck')), (bo.stderr || co.stderr).slice(0, 300));
    const page = existsSync(join(out, 'index.html')) ? readFileSync(join(out, 'index.html'), 'utf8') : '';
    check('after the kill switch the holding page says the build is offline again (Legal RL-171: "The playable build is offline for now." and "they are not fixed yet.")', page.includes('The playable build is offline for now.') && page.includes('they are not fixed yet.') && page.includes('There is no date for its return.') && !/fix them|fixing them/.test(page) && !page.includes('limited test build'));
    check('the shipped words file is an empty draft, so a build from it is refused (the RL-136 text must not be used by accident)', real.draft === true && real.gate.blocks.length === 0 && !JSON.stringify(real).includes('fixing them') && build(join(tmp, 'site-realwords'), cfg({ notice: join(here, 'site-interim.json') }), []).status === 1);
    check('the same holding page is /bench/, /band/, /404.html and /play/ (no game, no link)', ['bench/index.html', 'band/index.html', '404.html', 'play/index.html'].every((p) => existsSync(join(out, p)) && readFileSync(join(out, p), 'utf8') === page));
  }
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
console.log(failed ? `interim site self-test FAILED: ${failed} of ${ran} checks` : `interim site self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

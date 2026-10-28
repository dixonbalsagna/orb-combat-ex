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
import { CRUMBS_PRIVACY } from './site-crumbs.mjs';

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
const OLD_PRIVACY = 'This game collects and sends no personal data. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button copies a report to your clipboard for you to paste to Orb; nothing is sent by the game.';
// the game's own notice strings as Legal's RL-192 addendum gives them (docs/legal/page-fixed-lines.md), written out here on purpose: a drift in the checker's copy must show
const GAME_PROMPT = {
  photo_title: 'This game contains flashing effects.',
  photo_body_a: 'Our own automated check has found some scenes, such as a camera fly-past of collapsing buildings and some beam impacts, that flash more often than the recommended limit of three times a second, and they are not fixed yet.',
  photo_body_b: 'No independent photosensitivity analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version.',
  menu_notice: 'This game contains flashing effects. Our own automated check found some scenes that go over the recommended limit of three flashes a second, and they are not fixed yet. No independent analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version.',
  menu_rf_locked: 'Reduce flashing is on and cannot be turned off in this version. It lowers some effects but does not remove the flagged scenes.',
};
const GAME_SETTINGS_HELP = 'The notice shown when the game starts: it contains flashing effects, what Reduced motion does and does not change, and that no independent photosensitivity analyzer has been run.';
// the GDScript the routes scan reads (tools/site-routes.mjs, Legal's RL-195 condition (b)): the smallest good tree; each test breaks one door of it
const GOOD_UI_DATA = ['class_name UiData', '', 'static func feature(key: String) -> bool:', '\treturn false', '', '', 'static func rf_locked() -> bool:', '\treturn feature("lock_reduce_flashing")', '', '', 'static func set_feature(key: String, value) -> void:', '\tpass', ''].join('\n');
const GOOD_HUD_FUNCS = ['', '', 'func settings_set(key: String, value) -> void:', '\tif key == "reduce_flashing" and UiData.rf_locked():', '\t\tvalue = true', '\tset_option(key, value)', '', '', 'func load_saved_options() -> void:', '\tfor k in saved:', '\t\tvar sv = saved[k]', '\t\tif k == "reduce_flashing" and UiData.rf_locked():', '\t\t\tsv = true', '\t\tset_option(k, sv)', ''].join('\n');
const GOOD_MAIN = ['const LOCAL_ONLY_ARGS: Array = ["study", "flashcap", "nointro", "staticsky", "sky", "skymood"]', 'const URL_ARGS: Array = ["nointro", "skyreact", "study", "flashcap", "panhaze", "nopanhaze", "staticsky", "sky", "skymood", "keyhelp"]', '', 'var flash_legacy: bool = false', '', '', 'func _ready() -> void:', '\tif args.has("flashcap") and (UiData.feature("capture_hook") or not UiData.rf_locked()):', '\t\tflashcap = FlashCapture.new(self)', '', '', 'func _unhandled_input(e: InputEvent) -> void:', '\tif code == "F8" and not UiData.rf_locked():', '\t\tflash_legacy = not flash_legacy', ''].join('\n');
function prefsRoot(name, { options = true, feature = true, hud = true, target = 'none', lock = true, howto = OLD_PRIVACY, build = null } = {}) {
  const r = join(tmp, name);
  mkdirSync(r, { recursive: true });
  if (build) writeFileSync(join(r, 'build_info.json'), JSON.stringify({ commit: build.split(' ')[0], date: build.split(' ')[1] }));
  mkdirSync(join(r, 'ui/data'), { recursive: true });
  mkdirSync(join(r, 'ui/hud'), { recursive: true });
  writeFileSync(join(r, 'ui/data/options.json'), JSON.stringify({ schema: 1, options: { reduce_flashing: { default: options }, colour_vision: { default: 'off', label: 'Color-blind mode', help: 'Swaps the colors that carry meaning.' } } }));
  writeFileSync(join(r, 'ui/data/terms.json'), JSON.stringify({ schema: 1, note: 'Every word, as data. Colour notes stay.', prompt: { ...GAME_PROMPT } }));
  writeFileSync(join(r, 'ui/data/settings.json'), JSON.stringify({ schema: 1, sections: [{ id: 'access', title: 'Accessibility', items: ['colour_vision', { action: 'photo_notice', label: 'Flashing effects notice', value: 'Read', help: GAME_SETTINGS_HELP }] }] }));
  writeFileSync(join(r, 'ui/data/features.json'), JSON.stringify({ schema: 1, features: { reduce_flashing: feature, lock_reduce_flashing: lock, capture_hook: false } }));
  writeFileSync(join(r, 'ui/data/send.json'), JSON.stringify({ schema: 1, _target: target }));
  writeFileSync(join(r, 'ui/data/howto.json'), JSON.stringify({ pages: [{ rows: [{ icon: 'about_privacy_none', col: 1, text: howto }, { icon: 'about_privacy_github', col: 1, text: 'x' }] }] }));
  writeFileSync(join(r, 'ui/hud/ui_hud.gd'), `var opts: Dictionary = {\n\t"reduce_flashing": ${hud},\n}\n` + GOOD_HUD_FUNCS);
  mkdirSync(join(r, 'ui/core'), { recursive: true });
  writeFileSync(join(r, 'ui/core/ui_data.gd'), GOOD_UI_DATA);
  mkdirSync(join(r, 'render/core'), { recursive: true });
  writeFileSync(join(r, 'render/core/main.gd'), GOOD_MAIN);
  return r;
}
const goodRoot = prefsRoot('root-good');
// no run uses the real tools/site-ui-excuse.json (it names the live pin, and a stale file is itself a failure): a run that wants an excuse passes its own --ui-excuse
const NO_EXCUSE = join(tmp, 'no-ui-excuse.json');
const verify = (siteDir, c, root = goodRoot, extra = []) => { writeCfg(c); return node('check-site-interim.mjs', ['--site', siteDir, '--config', cfgFile, '--root', root, '--record', recordFile, ...(extra.includes('--today') ? [] : ['--today', '2026-10-16']), '--no-pack-scan', ...(extra.includes('--ui-excuse') ? [] : ['--ui-excuse', NO_EXCUSE]), ...extra]); };
let copies = 0;
const fresh = () => { const d = join(tmp, 'copy-' + (++copies)); cpSync(join(tmp, 'site-good'), d, { recursive: true }); return d; };
const edit = (d, p, fn) => { const f = join(d, p); writeFileSync(f, fn(readFileSync(f, 'utf8'))); };
let copies2 = 0;
const fresh2 = (src) => { const d = join(tmp, 'copy2-' + (++copies2)); cpSync(src, d, { recursive: true }); return d; };

try {
  const b = build(join(tmp, 'site-good'), cfg());
  check('the interim site builds from a stub export under a complete interim config', b.status === 0, (b.stderr || b.stdout).slice(0, 300));
  const good = join(tmp, 'site-good');
  const r0 = verify(good, cfg());
  check('the checker passes the built interim site', r0.status === 0, (r0.stderr || r0.stdout).slice(0, 500));
  // the freeze breadcrumbs (tools/site-crumbs.mjs): /play/ carries them exactly when tools/site.json says "crumbs": true, and their script (the real park's, from web-head.mjs) makes no network call
  {
    // a copy of Performance's tool and park: the note-slot patch (docs/tools/pending/ocx-note-slot.patch) is applied to the copy when the park does not use the gate's slot yet, so this test holds before and after it lands
    const perf = join(tmp, 'perf-copy');
    cpSync(join(here, '..', 'docs', 'perf', 'tools', 'web-head.mjs'), join(perf, 'docs/perf/tools/web-head.mjs'));
    cpSync(join(here, '..', 'docs', 'perf', 'web-shell'), join(perf, 'docs/perf/web-shell'), { recursive: true });
    cpSync(join(here, '..', 'export_presets.cfg'), join(perf, 'export_presets.cfg'));
    const shellJs = join(perf, 'docs/perf/web-shell/ocx-crumbs.js');
    if (!readFileSync(shellJs, 'utf8').includes('ocx-note-slot')) { const ap = spawnSync('git', ['apply', join(here, '..', 'docs', 'tools', 'pending', 'ocx-note-slot.patch')], { cwd: perf, encoding: 'utf8' }); check('the note-slot patch applies to the park', ap.status === 0, ap.stderr.slice(0, 200)); }
    const BUILD = 'abc1234 2026-10-26';
    const head = spawnSync(process.execPath, [join(perf, 'docs/perf/tools/web-head.mjs'), '--print', '--crumbs', '--build', BUILD], { encoding: 'utf8' });
    check('web-head prints the head block with the real breadcrumbs park', head.status === 0 && head.stdout.includes('ocx.crumbs.v1') && head.stdout.includes('<!--ocx:begin-->'), (head.stderr || '').slice(0, 200));
    const webC = join(tmp, 'web-crumbs');
    mkdirSync(webC, { recursive: true });
    const finalWords = head.stdout.trim();   // Performance's finished words (Legal's, docs/legal/crumbs-screen.md)
    writeFileSync(join(webC, 'index.html'), exportHtml.replace('<title>Orb Combat EX</title>', '<title>Orb Combat EX</title>' + finalWords));
    check('the real park carries Legal\'s words: no PLACEHOLDER and neither of the two struck claims', !head.stdout.includes('PLACEHOLDER') && !head.stdout.includes('prepared once') && !head.stdout.includes('it is still working'));
    check('the real park\'s build line is the one passed (never unknown)', head.stdout.includes(`BUILD = '${BUILD}'`) && !head.stdout.includes('@@BUILD@@'));
    check('the real park uses the gate\'s note slot', head.stdout.includes('ocx-note-slot'));
    for (const f of ['index.js', 'index.wasm', 'index.pck']) writeFileSync(join(webC, f), 'x');
    const on = { ...cfg(), crumbs: true };
    writeCfg(on);
    const bc = node('build-site.mjs', ['--web', webC, '--out', join(tmp, 'site-crumbs'), '--config', cfgFile, '--local']);
    check('an interim site builds from an export that carries the breadcrumbs', bc.status === 0, (bc.stderr || bc.stdout).slice(0, 300));
    const sc = join(tmp, 'site-crumbs');
    const rootOn = prefsRoot('root-crumbs', { howto: CRUMBS_PRIVACY, build: BUILD });
    check('"crumbs": true and the breadcrumbs on /play/: the checker passes', verify(sc, on, rootOn).status === 0, (verify(sc, on, rootOn).stderr || '').slice(0, 300));
    const off = verify(sc, cfg());
    check('breadcrumbs on /play/ with no "crumbs": true: the checker fails (a switched park must not ride in the preset)', off.status === 1 && /does not say "crumbs": true/.test(off.stderr), off.stderr.slice(0, 200));
    const miss = verify(good, on, rootOn);
    check('"crumbs": true but /play/ has none: the checker fails', miss.status === 1 && /does not carry the freeze breadcrumbs/.test(miss.stderr), miss.stderr.slice(0, 200));
    check('"crumbs": false or absent with a plain page passes (the default)', verify(good, { ...cfg(), crumbs: false }).status === 0 && verify(good, cfg()).status === 0);
    for (const claim of ['prepared once', 'it is still working']) { const dq = join(tmp, 'crumbs-claim-' + claim.length); cpSync(sc, dq, { recursive: true }); edit(dq, 'play/index.html', (x) => x.replace('KEY = ', () => "var zz = '" + claim + "'; KEY = ")); const rq = verify(dq, on, rootOn); check(`the start line that says "${claim}" (Legal took it out): the checker fails`, rq.status === 1 && rq.stderr.includes(claim), rq.stderr.slice(0, 200)); }
    { const dp = join(tmp, 'crumbs-placeholder'); cpSync(sc, dp, { recursive: true }); edit(dp, 'play/index.html', (x) => x.replace("start_line: '", "start_line: 'PLACEHOLDER ")); const rp = verify(dp, on, rootOn); check('breadcrumbs that still carry PLACEHOLDER words: the checker fails', rp.status === 1 && /PLACEHOLDER words/.test(rp.stderr), rp.stderr.slice(0, 200)); }
    // the build line and the note's slot (the hand-off: the gate provides the slot, the park puts its note there)
    {
      const gateHtml = readFileSync(join(sc, 'play/index.html'), 'utf8');
      check('with the switch on the gate has the note slot, after its words and buttons and inside it', /id="ocx-note-slot"/.test(gateHtml) && gateHtml.indexOf('id="gate-start"') < gateHtml.indexOf('id="ocx-note-slot"') && gateHtml.indexOf('id="ocx-note-slot"') < gateHtml.indexOf('</div>\n</div>', gateHtml.indexOf('id="gate"')) + 20);
      check('with the switch off the gate is as it was: no slot', !/ocx-note-slot/.test(readFileSync(join(good, 'play/index.html'), 'utf8')));
      const variants = [['the build line reads unknown', (x) => x.replace("BUILD = '" + BUILD + "'", "BUILD = 'unknown'"), /build line reads "unknown"/], ['the build token is still unfilled', (x) => x.replace("BUILD = '" + BUILD + "'", "BUILD = '@@BUILD@@'"), /build line reads "@@BUILD@@"/], ['the build line is not the exported tree\'s own', (x) => x.replace("BUILD = '" + BUILD + "'", "BUILD = 'fffffff 2026-10-26'"), /not the exported tree's own/], ['the build line has no date', (x) => x.replace("BUILD = '" + BUILD + "'", "BUILD = 'abc1234'"), /build line reads "abc1234"/], ['the gate has no note slot', (x) => x.replace('<div id="ocx-note-slot"></div>', ''), /no note slot/], ['the park does not use the slot', (x) => x.split('ocx-note-slot').join('ocx-no-slot').replace('<div id="ocx-no-slot"></div>', '<div id="ocx-note-slot"></div>'), /does not use the gate's note slot/]];
      // Legal's conditions for the note inside the click-through (RL-190): (1) outside the notice's words, (2) never above or over the warning and buttons, (3) Dismiss and Copy never change the gate's state
      const SLOT = '<div id="ocx-note-slot"></div>';
      variants.push(
        ['(1) the slot sits above the buttons, inside the notice', (x) => x.replace('\n' + SLOT, '').replace('</h1>', '</h1>' + SLOT), /(straight after the About paragraph|not after the gate's heading)/],
        ['(1) the slot is inside the About paragraph', (x) => x.replace('\n' + SLOT, '').replace('</a></p>\n</div>', '</a>' + SLOT + '</p>\n</div>'), /straight after the About paragraph/],
        ['(1) the slot is not empty (words of its own in the notice)', (x) => x.replace(SLOT, '<div id="ocx-note-slot">words</div>'), /straight after the About paragraph/],
        ['(1) the gate has two slots', (x) => x.replace(SLOT, SLOT + SLOT), /exactly one note slot/],
        ['(1) the script restyles the gate\'s slot', (x) => x.replace("var slot = d.getElementById('ocx-note-slot');", "var slot = d.getElementById('ocx-note-slot'); slot.style.margin = '0';"), /more to the gate's slot than append/],
        ['(2) the note\'s style in the gate is position:fixed', (x) => x.replace("slot ? '", "slot ? 'position:fixed;"), /not plain flow/],
        ['(2) the note\'s style in the gate has a layer', (x) => x.replace("slot ? '", "slot ? 'z-index:9;"), /not plain flow/],
        ['(2) the note\'s style in the gate has a negative margin', (x) => x.replace("slot ? '", "slot ? 'margin-top:-40px;"), /not plain flow/],
        ['(2) the gate is no longer a fixed box', (x) => x.replace('aria-labelledby="gate-title" style="position:fixed', 'aria-labelledby="gate-title" style="position:absolute'), /no longer a fixed, scrolling, topmost box/],
        ['(2) the gate no longer scrolls', (x) => x.replace('z-index:100000;overflow:auto', 'z-index:100000;overflow:hidden'), /no longer a fixed, scrolling, topmost box/],
        ['(3) the script names the gate', (x) => x.replace("var slot = d.getElementById('ocx-note-slot');", "var slot = d.getElementById('ocx-note-slot'); var g = d.getElementById('gate');"), /names the gate or its start function/],
        ['(3) the script calls the start function', (x) => x.replace("var slot = d.getElementById('ocx-note-slot');", "var slot = d.getElementById('ocx-note-slot'); var s = w.__startGame;"), /names the gate or its start function/],
        ['(3) the script clicks something', (x) => x.replace("var slot = d.getElementById('ocx-note-slot');", "var slot = d.getElementById('ocx-note-slot'); slot.click();"), /names the gate or its start function/],
        ['(3) the script looks up an element that is not its own', (x) => x.replace("var slot = d.getElementById('ocx-note-slot');", "var slot = d.getElementById('ocx-note-slot'); var o = d.getElementById('game-ok');"), /looks up #game-ok/],
        ['(3) the script listens for clicks on the whole page', (x) => x.replace("var slot = d.getElementById('ocx-note-slot');", "var slot = d.getElementById('ocx-note-slot'); d.addEventListener('click', function () { });"), /listens for clicks on the whole page/],
        ['(3) the gate\'s start is bound to the gate, not its button', (x) => x.replace("button.addEventListener('click'", "gate.addEventListener('click'"), /not bound to its own button/],
      );
      let vn = 0;
      for (const [what, fn, re] of variants) { const dv = join(tmp, 'crumbs-var-' + (++vn)); cpSync(sc, dv, { recursive: true }); edit(dv, 'play/index.html', fn); const rv = verify(dv, on, rootOn); check(`${what}: the checker fails`, rv.status === 1 && re.test(rv.stderr), rv.stderr.slice(0, 220)); }
    }
    let n = 0;
    for (const [what, inject] of [['a fetch', "fetch('x');"], ['an XMLHttpRequest', 'new XMLHttpRequest();'], ['sendBeacon', "navigator.sendBeacon('x');"], ['a WebSocket', "new WebSocket('x');"], ['a URL', "var u = 'https://example.com';"], ['an image src', 'var i = new Image();']]) {
      const d = join(tmp, 'crumbs-bad-' + (++n));
      cpSync(sc, d, { recursive: true });
      edit(d, 'play/index.html', (t) => t.replace("KEY = 'ocx.crumbs.v1',", () => "KEY = 'ocx.crumbs.v1', zz = (function () { " + inject + " }()),"));
      check(`(the edit for ${what} landed)`, readFileSync(join(d, 'play/index.html'), 'utf8').includes('zz = (function'));
      const r = verify(d, on, rootOn);
      check(`breadcrumbs whose script has ${what}: the checker fails`, r.status === 1 && /nothing may be sent off the device/.test(r.stderr), r.stderr.slice(0, 200));
    }
  }
  // Legal's switch-keyed privacy words (docs/legal/crumbs-screen.md, Q1, RL-188): ON, the new paragraph on About and in the game's own About line, today's line gone; OFF, today's line exactly
  {
    const legal = readFileSync(join(here, '..', 'docs', 'legal', 'crumbs-screen.md'), 'utf8');
    check('the constant is Legal\'s paragraph word for word (it is quoted in docs/legal/crumbs-screen.md)', legal.split(/\r?\n/).includes('> ' + CRUMBS_PRIVACY));
    const on = { ...cfg(), crumbs: true }, rootOn = prefsRoot('root-crumbs2', { howto: CRUMBS_PRIVACY, build: 'abc1234 2026-10-26' }), sc = join(tmp, 'site-crumbs');
    const aboutOn = readFileSync(join(sc, 'about/index.html'), 'utf8'), aboutOff = readFileSync(join(good, 'about/index.html'), 'utf8');
    const plain = (h) => h.replace(/<[^>]+>/g, ' ').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/\s+/g, ' ');
    check('with the switch on, the built About page carries Legal\'s paragraph and no longer today\'s line', plain(aboutOn).includes(CRUMBS_PRIVACY) && !plain(aboutOn).includes('collects and sends no personal data'));
    check('with the switch off, the built About page carries today\'s line exactly and not Legal\'s', plain(aboutOff).includes(OLD_PRIVACY) && !plain(aboutOff).includes('does not use trackers'));
    let r1 = verify(sc, on, prefsRoot('root-old-howto'));
    check('the switch is on but the game\'s own About line is still today\'s: the checker fails', r1.status === 1 && /game's own About line/.test(r1.stderr), r1.stderr.slice(0, 200));
    r1 = verify(good, cfg(), prefsRoot('root-new-howto', { howto: CRUMBS_PRIVACY }));
    check('the switch is off but the game\'s own About line is Legal\'s new paragraph: the checker fails', r1.status === 1 && /must stay exactly as it is/.test(r1.stderr), r1.stderr.slice(0, 200));
    let d = fresh2(sc); edit(d, 'about/index.html', (x) => x.replace(/This game sends no personal data and does not use trackers\./, 'This game collects and sends no personal data.'));
    r1 = verify(d, on, rootOn);
    check('the switch is on but About has lost Legal\'s paragraph: the checker fails', r1.status === 1 && /switch-on privacy paragraph word for word/.test(r1.stderr), r1.stderr.slice(0, 200));
    d = fresh2(sc); edit(d, 'about/index.html', (x) => x.replace('<h2>Privacy</h2>', '<h2>Privacy</h2><p>' + OLD_PRIVACY + '</p>'));
    r1 = verify(d, on, rootOn);
    check('the switch is on but About still has today\'s line beside the new one: the checker fails', r1.status === 1 && /still says "collects and sends no personal data"/.test(r1.stderr), r1.stderr.slice(0, 200));
    d = fresh2(good); edit(d, 'about/index.html', (x) => x.replace(OLD_PRIVACY, CRUMBS_PRIVACY.replace(/"/g, '&quot;')));
    r1 = verify(d, cfg(), goodRoot);
    check('the switch is off but About carries Legal\'s new paragraph: the checker fails', r1.status === 1 && /carries the switch-on privacy paragraph/.test(r1.stderr), r1.stderr.slice(0, 200));
    // no cookie anywhere on the site, with the switch on or off
    let c = 0;
    for (const [what, where, code] of [['a document.cookie assignment in the page', 'play/index.html', "document.cookie = 'a=1';"], ['a document.cookie assignment in an engine file', 'play/index.js', "document.cookie='a=1';"], ['a Cookie Store write', 'play/index.js', "cookieStore.set('a', '1');"], ['a Set-Cookie header in a script', 'play/index.audio.worklet.js', "var h = 'Set-Cookie: a=1';"]]) {
      d = join(tmp, 'cookie-' + (++c)); cpSync(sc, d, { recursive: true });
      if (where === 'play/index.html') edit(d, where, (x) => x.replace('</body>', '<script>' + code + '</script></body>')); else writeFileSync(join(d, where), code);
      r1 = verify(d, on, rootOn);
      check(`${what}: the checker fails (the page says it does not use trackers)`, r1.status === 1 && /sets a cookie/.test(r1.stderr), r1.stderr.slice(0, 200));
    }
    check('reading document.cookie is not a finding', (() => { const dd = join(tmp, 'cookie-read'); cpSync(sc, dd, { recursive: true }); edit(dd, 'play/index.html', (x) => x.replace('</body>', '<script>var c = document.cookie;</script></body>')); return verify(dd, on, rootOn).status === 0; })());
    check('the plain interim site and the switch-on site both set no cookie (the checker passes both with their own root)', verify(good, cfg()).status === 0 && verify(sc, on, rootOn).status === 0);
  }
  const playHtml = readFileSync(join(good, 'play/index.html'), 'utf8');
  check('the gate is next in the body after the phone note, which is hidden in the markup, "Not now" goes to ../ and the page is noindex', /<body>\n<div id="phone-note"[^>]*\shidden[\s\S]*?<\/div>\n<\/div>\n<div id="gate"/.test(playHtml) && /<a id="gate-notnow" href="\.\.\/"/.test(playHtml) && playHtml.includes('<meta name="robots" content="noindex">'));
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
  // the phone note (Legal's RL-201, ADR 0011): Legal's three lines word for word (written out here on purpose), before the notice, never in its place
  const NOTE_H = 'Best on a computer', NOTE_B = 'This demo is made for a computer with a keyboard or a controller. It may not run well on a phone.', NOTE_BTN = 'Continue anyway';
  check("the page carries Legal's RL-201 note word for word: heading, body, button", playHtml.includes('<h1 id="phone-note-title" style="font-size:1.5rem;line-height:1.25;margin:1rem 0 1.5rem">' + NOTE_H + '</h1>') && playHtml.includes('<p>' + NOTE_B + '</p>') && />Continue anyway<\/button>/.test(playHtml) && playHtml.indexOf('id="phone-note"') < playHtml.indexOf('id="gate"') && /<div id="phone-note"[^>]*\shidden/.test(playHtml));
  check('the flashing notice and the lock line are untouched in the gate under the note (the gate markup holds no trace of the note)', (() => { const g = playHtml.slice(playHtml.indexOf('id="gate"'), playHtml.indexOf('id="gate-start"') + 1200); return !g.includes('phone-note') && g.includes('This game contains flashing effects') && g.includes('Reduce flashing is on'); })());
  const noteEdit = (name, fn) => fail(name, (d) => edit(d, 'play/index.html', fn));
  const NOTE_BLOCK = /<div id="phone-note"[\s\S]*?<\/div>\n<\/div>\n/;
  noteEdit('the check fails when the phone note is missing', (x) => x.replace(NOTE_BLOCK, ''));
  noteEdit('the check fails when the note heading changes by one word', (x) => x.replace(NOTE_H + '</h1>', 'Better on a computer</h1>'));
  noteEdit('the check fails when the note body changes by one word', (x) => x.replace('may not run well', 'might not run well'));
  noteEdit('the check fails when the note button changes', (x) => x.replace('>Continue anyway<', '>Continue<'));
  noteEdit('the check fails when the note carries a word more (a promise about another platform or date)', (x) => x.replace('<p>' + NOTE_B + '</p>', '<p>' + NOTE_B + ' A phone version is coming soon.</p>'));
  noteEdit('the check fails when the note comes AFTER the gate', (x) => { const m = NOTE_BLOCK.exec(x)[0]; return x.replace(m, '').replace(/(<div id="gate"[\s\S]*?<\/div>\n<\/div>\n)/, '$1' + m); });
  noteEdit('the check fails when the note is not hidden in the markup (a computer would see it)', (x) => x.replace('aria-labelledby="phone-note-title" hidden', 'aria-labelledby="phone-note-title"'));
  noteEdit('the check fails when the note script starts the game (the note skips the notice)', (x) => x.replace("go.addEventListener('click', function () {", "go.addEventListener('click', function () {\n    window.__startGame();"));
  noteEdit('the check fails when the note script clicks the gate button (the note skips the notice)', (x) => x.replace('if (start) start.focus();', 'if (start) start.click();'));
  noteEdit('the check fails when the note script removes the gate (the note replaces the notice)', (x) => x.replace("if (gate) gate.removeAttribute('inert');", "if (gate) gate.remove();"));
  noteEdit('the check fails when the note script hides the gate (the note replaces the notice)', (x) => x.replace("if (gate) gate.removeAttribute('inert');", "if (gate) gate.style.display = 'none';"));
  noteEdit('the check fails when the note script leaves the page', (x) => x.replace("go.addEventListener('click', function () {", "go.addEventListener('click', function () {\n    location.href = '../';"));
  noteEdit('the check fails when the note script is for every device (no phone test: a computer would see the note)', (x) => x.replace("window.matchMedia('(pointer: coarse)').matches && Math.min(screen.width, screen.height) <= 500", 'true'));
  noteEdit('the check fails when the note script has no markers (its button would do nothing)', (x) => x.replace('/* phone note */', '').replace('/* end phone note */', ''));
  noteEdit('the check fails when the note holds a link to the game (a skip)', (x) => x.replace('<p>' + NOTE_B + '</p>', '<p>' + NOTE_B + '</p><a href="./?go=1">go</a>'));
  noteEdit('the check fails when the note takes over the gate button id', (x) => x.replace('id="phone-note-continue"', 'id="gate-start"'));
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
    const SIG_PIN = 'c'.repeat(40);
    const sigGate = join(tmp, 'signature-gate.json');
    const writeGate = (over = {}) => writeFileSync(sigGate, JSON.stringify({ commit: SIG_PIN, reduced: { primary: 2.5, area15: 3, twoSec: 2 }, normal: { primary: 3.5, area15: 5, twoSec: 3 }, ...over }));
    writeGate();
    const ownerCfg = (over = {}) => ({ offline: false, approved: '2026-10-18', pin: SIG_PIN, interim: { owner: 'Orb 2026-10-18', approved: '2026-10-18', expires: '2026-10-25', notice: ownerWords, ...over } });
    // a record that would fail everything (empty): the build and the check must not need it
    writeFileSync(recordFile, '{}');
    const ob = build(join(tmp, 'site-owner'), ownerCfg(), []);
    check('the owner-approved site builds from a stub export WITHOUT a recorded run (not --local)', ob.status === 0, (ob.stderr || ob.stdout).slice(0, 400));
    check('the build says it is owner-approved and prints the record as report only', /OWNER-APPROVED \(Orb 2026-10-18\)/.test(ob.stdout) && /report-only:/.test(ob.stdout), ob.stdout.slice(0, 400));
    const goodO = join(tmp, 'site-owner');
    const verifyO = (d, c = ownerCfg(), root = goodRoot, extra = []) => { writeCfg(c); return node('check-site-interim.mjs', ['--site', d, '--config', cfgFile, '--root', root, '--record', recordFile, ...(extra.includes('--today') ? [] : ['--today', '2026-10-19']), '--no-pack-scan', ...(extra.includes('--ui-excuse') ? [] : ['--ui-excuse', NO_EXCUSE]), ...(extra.includes('--signature-gate') ? [] : ['--signature-gate', sigGate]), ...extra]); };
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
    // the game's own strings (ui/data/*.json): Legal's RL-192 condition 2, the in-game notice word for word and the American-spelling scan over every file
    {
      let ur = 0;
      const uiRoot = (fn) => { const r = prefsRoot('root-ui-' + (++ur)); fn((f, g) => { const p = join(r, 'ui/data', f); const j = JSON.parse(readFileSync(p, 'utf8')); g(j); writeFileSync(p, JSON.stringify(j)); }, r); return r; };
      const rO = verifyO(goodO, ownerCfg(), goodRoot);
      check("owner mode: the game's own strings pass when they are Legal's RL-192 lines", rO.status === 0, (rO.stderr || rO.stdout).slice(0, 300));
      const OLD = {
        menu_notice: 'This game contains flashing effects, and our own automated check found scenes that reach the recommended limit of three flashes a second, and a few that go over it on stricter readings. We are fixing them, and no independent analyser has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version.',
        photo_body_a: 'Our own automated check has found some scenes, such as a camera fly-past of collapsing buildings and some beam impacts, that flash more often than the recommended limit of three times a second. We are fixing them.',
        photo_body_b: 'No independent photosensitivity analyser has been run. If you or someone in your family has photosensitive epilepsy, we recommend not playing this version.',
        menu_rf_locked: 'Reduce flashing is on. It lowers some effects but does not remove the flagged scenes.',
        photo_title: 'This game contains flashing effects',
      };
      for (const [k, old] of Object.entries(OLD)) failO(`owner mode: the check fails when terms.json prompt.${k} is the old, uncleared text`, () => {}, ownerCfg(), uiRoot((e) => e('terms.json', (j) => { j.prompt[k] = old; })));
      failO('owner mode: the check fails when the in-game notice differs by one word from Legal\'s', () => {}, ownerCfg(), uiRoot((e) => e('terms.json', (j) => { j.prompt.menu_notice = j.prompt.menu_notice.replace('some scenes', 'a few scenes'); })));
      failO('owner mode: the check fails when a prompt key is missing', () => {}, ownerCfg(), uiRoot((e) => e('terms.json', (j) => { delete j.prompt.menu_rf_locked; })));
      failO('owner mode: the check fails when terms.json is missing', () => {}, ownerCfg(), uiRoot((e, r) => rmSync(join(r, 'ui/data/terms.json'))));
      failO('owner mode: the check fails when the settings help still says "tested ... analyser"', () => {}, ownerCfg(), uiRoot((e) => e('settings.json', (j) => { j.sections[0].items[1].help = 'The notice shown when the game starts: it contains flashing effects, what Reduced motion does and does not change, and that the game has not yet been tested with a photosensitivity analyser.'; })));
      failO('owner mode: the check fails when the settings help says "tested" with the American spelling', () => {}, ownerCfg(), uiRoot((e) => e('settings.json', (j) => { j.sections[0].items[1].help = 'The notice shown when the game starts, and that the game has not yet been tested with a photosensitivity analyzer.'; })));
      failO('owner mode: the check fails when the settings row for the notice is gone', () => {}, ownerCfg(), uiRoot((e) => e('settings.json', (j) => { j.sections[0].items.pop(); })));
      failO('owner mode: the check fails when the label is still "Colour-blind mode"', () => {}, ownerCfg(), uiRoot((e) => e('options.json', (j) => { j.options.colour_vision.label = 'Colour-blind mode'; })));
      failO('owner mode: the check fails when any in-game string promises a fix', () => {}, ownerCfg(), uiRoot((e) => e('terms.json', (j) => { j.prompt.extra = 'We are fixing them.'; })));
      // the spelling scan runs in every mode, over every file of ui/data
      fail('the check fails on a British spelling in any in-game string (terms.json: centre)', () => {}, cfg(), uiRoot((e) => e('terms.json', (j) => { j.prompt.extra = 'The centre of the screen.'; })));
      fail('the check fails on a British spelling in a help text of another file (options.json: colour)', () => {}, cfg(), uiRoot((e) => e('options.json', (j) => { j.options.colour_vision.help = 'Swaps the colour that carries meaning.'; })));
      failO('owner mode: the check fails on a British spelling in howto.json (licence)', () => {}, ownerCfg(), uiRoot((e) => e('howto.json', (j) => { j.pages[0].rows[1].text = 'The licence is not chosen yet.'; })));
      failO('owner mode: the check fails on a British spelling in the notice (analyser) even if it were also word for word elsewhere', () => {}, ownerCfg(), uiRoot((e) => e('terms.json', (j) => { j.prompt.extra = 'No independent analyser has been run.'; })));
      // what it does not scan: keys and ids (internal), an _underscore note, a file's own top-level note, an id string
      const rId = uiRoot((e) => e('terms.json', (j) => { j._why = 'colour, grey and centre'; j.note = 'Colour notes for the team'; j.pages = [{ id: 'licences', title: 'Licenses' }]; j.colour_vision = { colour_grey: 'x' }; j.ids = ['colour_vision']; }));
      const rIdR = verifyO(goodO, ownerCfg(), rId);
      check('owner mode: the scan skips keys, ids, _underscore notes and a file\'s own top-level note', rIdR.status === 0, (rIdR.stderr || rIdR.stdout).slice(0, 300));
      // the allowlist: a British spelling UI has not swapped yet is let through only when it is listed by file and pointer
      const pending = uiRoot((e) => e('howto.json', (j) => { j.pages[0].rows[1].text = 'The licence is not chosen yet.'; }));
      const allowFile = join(tmp, 'ui-allow.json');
      writeFileSync(allowFile, JSON.stringify({ allow: [{ file: 'ui/data/howto.json', pointer: '/pages/0/rows/1/text', why: 'pending' }] }));
      const rA = verifyO(goodO, ownerCfg(), pending, ['--ui-allow', allowFile]);
      check('owner mode: a British spelling listed in the allowlist (by file and pointer) is let through', rA.status === 0, (rA.stderr || rA.stdout).slice(0, 300));
      writeFileSync(allowFile, JSON.stringify({ allow: [{ file: 'ui/data/howto.json', pointer: '/pages/0/rows/0/text', why: 'wrong pointer' }] }));
      const rB = verifyO(goodO, ownerCfg(), pending, ['--ui-allow', allowFile]);
      check('owner mode: an allowlist entry for another pointer lets nothing through', rB.status === 1 && /howto\.json \/pages\/0\/rows\/1\/text/.test(rB.stderr), (rB.stderr || rB.stdout).slice(0, 300));
      const rC = verifyO(goodO, ownerCfg(), goodRoot, ['--ui-allow', allowFile]);
      check('owner mode: an allowlist entry that no longer matches only prints a note (remove it)', rC.status === 0 && /no longer holds a British spelling/.test(rC.stdout), (rC.stderr || rC.stdout).slice(0, 300));
      const rD = verifyO(goodO, ownerCfg(), goodRoot, ['--ui-allow', join(tmp, 'no-such-allow.json')]);
      check('owner mode: a missing allowlist file is a failure, not a pass', rD.status === 1, (rD.stderr || rD.stdout).slice(0, 300));
      // the one pin whose strings predate RL-192's swap (tools/site-ui-excuse.json): excused for that commit, in that commit's exported tree, for the listed rule kinds only
      {
        const pinRoot = (build) => { const r = uiRoot((e) => { e('terms.json', (j) => { Object.assign(j.prompt, OLD); }); e('options.json', (j) => { j.options.colour_vision.label = 'Colour-blind mode'; }); }); if (build) writeFileSync(join(r, 'build_info.json'), JSON.stringify({ commit: build, date: '2026-10-20' })); return r; };
        const exFile = join(tmp, 'ui-excuse.json');
        const writeEx = (o) => writeFileSync(exFile, JSON.stringify({ commit: SIG_PIN, ruling: 'RL-test', until: '2026-11-01', rules: ['notice-lines', 'fix-promise', 'spelling'], ...o }));
        const ui = ['--ui-excuse', exFile];
        const verifyPin = (root, c = ownerCfg(), extra = ui) => verifyO(goodO, c, root, extra);
        const UI_LINES = /uses the British spelling|promises a fix|is not Legal's line word for word/;
        writeEx({});
        const oldTree = pinRoot(SIG_PIN.slice(0, 7));
        const rP = verifyPin(oldTree);
        check("the pin's own old strings pass with the excuse present, and the check names the ruling and the kinds", rP.status === 0 && /string rules \(spelling, fix-promise, notice-lines\) are not met by the strings of the pin cccccccc, which RL-test lets stay up/.test(rP.stdout), (rP.stderr || rP.stdout).slice(0, 300));
        check('each excused line is printed as a note, so the log shows what was let through', /note \(excused on cccccccc\): ui\/data\/terms\.json prompt\.menu_notice is not Legal's line word for word/.test(rP.stdout) && /note \(excused on cccccccc\): ui\/data\/options\.json options\.colour_vision\.label/.test(rP.stdout), rP.stdout.slice(0, 300));
        const rP2 = verifyPin(oldTree, ownerCfg(), ['--ui-excuse', join(tmp, 'no-such-excuse.json')]);
        check('without the excuse file the same tree fails exactly as before', rP2.status === 1 && UI_LINES.test(rP2.stderr), (rP2.stderr || rP2.stdout).slice(0, 300));
        writeEx({ commit: 'd'.repeat(40) });
        const rP3 = verifyPin(oldTree);
        check('an excuse for another commit excuses nothing', rP3.status === 1 && UI_LINES.test(rP3.stderr), (rP3.stderr || rP3.stdout).slice(0, 300));
        writeEx({});
        const rP4 = verifyPin(oldTree, { ...ownerCfg(), pin: 'e'.repeat(40) });
        check('a different pin is checked in full whatever the excuse says (the tree is not the excused commit either)', rP4.status === 1 && UI_LINES.test(rP4.stderr) && !/lets stay up/.test(rP4.stdout), (rP4.stderr || rP4.stdout).slice(0, 300));
        const rP5 = verifyPin(pinRoot('eeeeeee'));
        check("HEAD's own strings stay checked in full: a tree that is not the pin's (its build_info.json names another commit) is not excused though site.json still names the pin", rP5.status === 1 && UI_LINES.test(rP5.stderr) && !/lets stay up/.test(rP5.stdout), (rP5.stderr || rP5.stdout).slice(0, 300));
        const rP6 = verifyPin(pinRoot(null));
        check('a tree with no build_info.json (a working copy, not an exported pin) is not excused', rP6.status === 1 && UI_LINES.test(rP6.stderr), (rP6.stderr || rP6.stdout).slice(0, 300));
        writeEx({ rules: ['spelling'] });
        const rP7 = verifyPin(oldTree);
        check('the excuse covers only the kinds it lists: with spelling only, the old notice lines still fail', rP7.status === 1 && /is not Legal's line word for word/.test(rP7.stderr) && !/uses the British spelling/.test(rP7.stderr), (rP7.stderr || rP7.stdout).slice(0, 300));
        writeEx({});
        const rP8 = verifyPin(goodRoot);
        check('a tree that meets the rules passes with the excuse present and prints no excuse note', rP8.status === 0 && !/lets stay up/.test(rP8.stdout), (rP8.stderr || rP8.stdout).slice(0, 300));
        const rP9 = verifyPin(uiRoot((e, r) => { rmSync(join(r, 'ui/data/terms.json')); writeFileSync(join(r, 'build_info.json'), JSON.stringify({ commit: SIG_PIN.slice(0, 7), date: '2026-10-20' })); }));
        check('an unreadable or missing ui/data file is never excused', rP9.status === 1, (rP9.stderr || rP9.stdout).slice(0, 300));
        // RL-200: the excuse ends at the next pin move or on its date, whichever comes first, and the file present after either is a failure
        const LATE = ownerCfg({ expires: '2026-12-31' });   // the interim's own expiry is a separate check; keep it out of the way of the dates here
        const rD1 = verifyPin(oldTree, LATE, [...ui, '--today', '2026-11-01']);
        check('RL-200: on the last day of the excuse (until, inclusive) the pin still passes', rD1.status === 0, (rD1.stderr || rD1.stdout).slice(0, 300));
        const rD2 = verifyPin(oldTree, LATE, [...ui, '--today', '2026-11-02']);
        check('RL-200: the day after the date, the check fails: the excuse ended, the strings are checked in full and the file must go', rD2.status === 1 && /ended on 2026-11-01: remove the file/.test(rD2.stderr) && UI_LINES.test(rD2.stderr) && !/lets stay up/.test(rD2.stdout), (rD2.stderr || rD2.stdout).slice(0, 300));
        const rD3 = verifyPin(goodRoot, LATE, [...ui, '--today', '2026-11-02']);
        check('RL-200: a stale file fails even on a tree whose strings are right (it must be removed, not left behind)', rD3.status === 1 && /ended on 2026-11-01/.test(rD3.stderr), (rD3.stderr || rD3.stdout).slice(0, 300));
        writeEx({ until: undefined });
        const rD4 = verifyPin(oldTree);
        check('RL-200: an excuse with no "until" date excuses nothing and fails', rD4.status === 1 && /no valid "until" date/.test(rD4.stderr) && UI_LINES.test(rD4.stderr), (rD4.stderr || rD4.stdout).slice(0, 300));
        writeEx({ until: 'soon' });
        const rD5 = verifyPin(oldTree);
        check('RL-200: an "until" that is not a date excuses nothing and fails', rD5.status === 1 && /no valid "until" date/.test(rD5.stderr), (rD5.stderr || rD5.stdout).slice(0, 300));
        writeEx({});
        const rD6 = verifyPin(goodRoot, { ...ownerCfg(), pin: 'e'.repeat(40) });
        check('RL-200: a pin move that leaves the excuse file behind fails, even when the strings of the new pin are right', rD6.status === 1 && /the pin moved off cccccccc.*remove the file in the same commit as the pin move/.test(rD6.stderr), (rD6.stderr || rD6.stdout).slice(0, 300));
        const rD7 = verifyPin(oldTree, { ...ownerCfg(), pin: 'e'.repeat(40) });
        check('RL-200: a pin move without the swap fails in full: the old strings are failures, and so is the stale file', rD7.status === 1 && UI_LINES.test(rD7.stderr) && /the pin moved off/.test(rD7.stderr), (rD7.stderr || rD7.stdout).slice(0, 300));
        const lockOff = (() => { const r = pinRoot(SIG_PIN.slice(0, 7)); const f = join(r, 'ui/data/features.json'); const j = JSON.parse(readFileSync(f, 'utf8')); j.features.lock_reduce_flashing = false; writeFileSync(f, JSON.stringify(j)); return r; })();
        const rD8 = verifyPin(lockOff);
        check('RL-200: the excuse covers only the in-game string rules: an unlocked build on the same pin still fails', rD8.status === 1 && /lock_reduce_flashing is not true/.test(rD8.stderr), (rD8.stderr || rD8.stdout).slice(0, 300));
        const rPr = JSON.parse(readFileSync(new URL('./site-ui-excuse.json', import.meta.url), 'utf8'));
        check('the real excuse file names one full commit, RL-200, the end date 2026-11-01 and the rule kinds', /^[0-9a-f]{40}$/.test(rPr.commit) && rPr.ruling === 'RL-200' && rPr.until === '2026-11-01' && Array.isArray(rPr.rules) && rPr.rules.every((k) => ['notice-lines', 'fix-promise', 'spelling'].includes(k)));
      }
    }
    // normal mode unreachable by any route (Legal's RL-195 condition (b); tools/site-routes.mjs): each test breaks one door of the smallest good tree
    {
      let rr = 0;
      const routeRoot = (file, fn) => { const r = prefsRoot('root-route-' + (++rr)); const p = join(r, file); writeFileSync(p, fn(readFileSync(p, 'utf8'))); return r; };
      const add = (s) => (t) => t + s;
      const HUD = 'ui/hud/ui_hud.gd', DATA = 'ui/core/ui_data.gd', MAIN = 'render/core/main.gd';
      failO('owner mode: a production set_feature (an override of the lock flag) fails', () => {}, ownerCfg(), routeRoot(HUD, add('\nfunc dbg() -> void:\n\tUiData.set_feature("lock_reduce_flashing", false)\n')));
      failO('owner mode: rf_locked() reading another flag fails', () => {}, ownerCfg(), routeRoot(DATA, (t) => t.replace('feature("lock_reduce_flashing")', 'feature("lock_other")')));
      failO('owner mode: a URL-word style writer of the option with no lock check fails (set_option("reduce_flashing", false))', () => {}, ownerCfg(), routeRoot(HUD, add('\nfunc url_word() -> void:\n\tset_option("reduce_flashing", false)\n')));
      failO('owner mode: a writer through opts[...] with no lock check fails', () => {}, ownerCfg(), routeRoot(MAIN, add('\nfunc dbg() -> void:\n\tui_hud.opts["reduce_flashing"] = false\n')));
      failO('owner mode: the Settings screen\'s door without the lock check fails (settings_set)', () => {}, ownerCfg(), routeRoot(HUD, (t) => t.replace('if key == "reduce_flashing" and UiData.rf_locked():', 'if key == "reduce_flashing" and false:')));
      failO('owner mode: the saved setting\'s door without the lock check fails (load_saved_options)', () => {}, ownerCfg(), routeRoot(HUD, (t) => t.replace('if k == "reduce_flashing" and UiData.rf_locked():', 'if k == "reduce_flashing" and false:')));
      failO('owner mode: code that sets the register\'s reduced_flashing to false fails', () => {}, ownerCfg(), routeRoot(MAIN, add('\nfunc dbg() -> void:\n\thost.vfx.reduced_flashing = false\n')));
      failO('owner mode: code that sets the register by a negation fails (flash_calm = not ...)', () => {}, ownerCfg(), routeRoot(MAIN, add('\nfunc dbg() -> void:\n\tPaneWorld.flash_calm = not locked\n')));
      failO('owner mode: the F8 debug key (flash_legacy) with no lock check fails', () => {}, ownerCfg(), routeRoot(MAIN, (t) => t.replace(' and not UiData.rf_locked()', '')));
      failO('owner mode: the capture hook attached with no capture_hook feature fails (?flashcap=1)', () => {}, ownerCfg(), routeRoot(MAIN, (t) => t.replace('UiData.feature("capture_hook") or ', '')));
      failO('owner mode: the capture hook attached with no lock check fails (a locked export could attach it)', () => {}, ownerCfg(), routeRoot(MAIN, (t) => t.replace(' or not UiData.rf_locked()', '')));
      failO('owner mode: a URL word nobody reviewed that a public page honours fails (URL_ARGS minus LOCAL_ONLY_ARGS)', () => {}, ownerCfg(), routeRoot(MAIN, (t) => t.replace('"keyhelp"]', '"keyhelp", "nocover"]')));
      failO('owner mode: a bypass word that is not local-only fails (flashcap out of LOCAL_ONLY_ARGS)', () => {}, ownerCfg(), routeRoot(MAIN, (t) => t.replace('"study", "flashcap", "nointro", "staticsky"', '"study", "nointro", "staticsky"')));
      failO('owner mode: a bypass word that is not local-only fails (study out of LOCAL_ONLY_ARGS)', () => {}, ownerCfg(), routeRoot(MAIN, (t) => t.replace('["study", "flashcap"', '["flashcap"')));
      failO('owner mode: an export whose features.json sets capture_hook true fails', () => {}, ownerCfg(), (() => { const r = prefsRoot('root-route-hook'); const p = join(r, 'ui/data/features.json'); const j = JSON.parse(readFileSync(p, 'utf8')); j.features.capture_hook = true; writeFileSync(p, JSON.stringify(j)); return r; })());
      failO('owner mode: a tree with no ui_data.gd fails (the lock flag cannot be read)', () => {}, ownerCfg(), (() => { const r = prefsRoot('root-route-nodata'); rmSync(join(r, DATA)); return r; })());
      fail('the routes scan runs in every mode: a URL-word writer fails the Legal-ruling interim too', () => {}, cfg(), routeRoot(HUD, add('\nfunc url_word() -> void:\n\tset_option("reduce_flashing", false)\n')));
      // the one pin Legal ruled may stay up while the fix lands (RL-196): tools/site-routes-grandfather.json, for that commit only
      {
        const openRoot = routeRoot(MAIN, (t) => t.replace(' or not UiData.rf_locked()', ''));
        const gfFile = join(tmp, 'routes-grandfather.json');
        writeFileSync(gfFile, JSON.stringify({ commit: SIG_PIN, ruling: 'RL-196' }));
        const rG = verifyO(goodO, ownerCfg(), openRoot, ['--routes-grandfather', gfFile]);
        check('owner mode: the grandfathered pin is not failed for its open route, and the check says so (RL-196)', rG.status === 0 && /routes scan finds 1 open route on the pin cccccccc, which RL-196 lets stay up/.test(rG.stdout), (rG.stderr || rG.stdout).slice(0, 300));
        writeFileSync(gfFile, JSON.stringify({ commit: 'd'.repeat(40), ruling: 'RL-196' }));
        const rH = verifyO(goodO, ownerCfg(), openRoot, ['--routes-grandfather', gfFile]);
        check('owner mode: a grandfather record for another commit excuses nothing: a new pin passes the scan in full', rH.status === 1 && /normal mode is reachable/.test(rH.stderr), (rH.stderr || rH.stdout).slice(0, 300));
        const rI = verifyO(goodO, ownerCfg(), openRoot, ['--routes-grandfather', join(tmp, 'no-such-grandfather.json')]);
        check('owner mode: with no grandfather record the open route fails', rI.status === 1, (rI.stderr || rI.stdout).slice(0, 300));
        const rJ = verifyO(goodO, ownerCfg(), goodRoot, ['--routes-grandfather', gfFile]);
        check('owner mode: a clean tree passes whatever the grandfather record says', rJ.status === 0, (rJ.stderr || rJ.stdout).slice(0, 300));
      }
      const okRoot = routeRoot(HUD, add('\nfunc on() -> void:\n\tset_option("reduce_flashing", true)\n\n\nfunc guarded() -> void:\n\tif UiData.rf_locked():\n\t\treturn\n\tset_option("reduce_flashing", false)\n'));
      const rOk = verifyO(goodO, ownerCfg(), okRoot);
      check('owner mode: writing On, and a write behind the lock check, pass the routes scan', rOk.status === 0, (rOk.stderr || rOk.stdout).slice(0, 300));
      const toolRoot = routeRoot(MAIN, (t) => t);
      mkdirSync(join(toolRoot, 'render/tools'), { recursive: true });
      writeFileSync(join(toolRoot, 'render/tools/flash_capture.gd'), 'func begin() -> void:\n\tmain.ui_hud.opts["reduce_flashing"] = reduced\n\tUiData.set_feature("x", true)\n');
      const rTool = verifyO(goodO, ownerCfg(), toolRoot);
      check('owner mode: the tools folders are not a player\'s path: the hook\'s own writes do not fail the scan', rTool.status === 0, (rTool.stderr || rTool.stdout).slice(0, 300));
    }
    // the pin only moves to a commit whose signature clip, reduced, reads no worse than 2.5 / 3 / 2 (Legal's RL-195 condition (a); tools/flash/signature-gate.mjs)
    {
      const pass = (name, over, cfgOver) => { writeGate(over); const r = verifyO(goodO, cfgOver ? ownerCfg(cfgOver) : ownerCfg(), goodRoot); check(name, r.status === 0, (r.stderr || r.stdout).slice(0, 300)); };
      const refuse = (name, over, pin, re) => { writeGate(over); const c = ownerCfg(); if (pin !== undefined) c.pin = pin; const r = verifyO(goodO, c, goodRoot); check(name, r.status === 1 && re.test(r.stderr), (r.stderr || r.stdout).slice(0, 300)); };
      pass('owner mode: a record for the pin with reduced at 2.5 / 3 / 2 passes the signature gate', {});
      refuse('owner mode: a pin with no signature reading on record fails (the pin moved before the clip was read)', {}, 'd'.repeat(40), /signature reading on record is for cccccccc, the pin is dddddddd/);
      refuse('owner mode: reduced over 2.5 on the primary fails the gate', { reduced: { primary: 3, area15: 3, twoSec: 2 } }, undefined, /on the record: primary 3 \(over 2\.5\)/);
      refuse('owner mode: reduced over 3 on the area reading fails the gate', { reduced: { primary: 2.5, area15: 3.5, twoSec: 2 } }, undefined, /area15 3.5/);
      refuse('owner mode: reduced over 2 on the two-second memory fails the gate', { reduced: { primary: 2.5, area15: 3, twoSec: 2.5 } }, undefined, /twoSec 2.5/);
      refuse('owner mode: a reduced reading that is missing from the record fails the gate', { reduced: null }, undefined, /not read/);
      pass('owner mode: a grandfathered record (the pin Legal ruled on before the condition) passes though it reads worse', { grandfathered: true, reduced: { primary: 3, area15: 3, twoSec: 3 } });
      refuse('owner mode: a grandfathered record does not carry over to another pin', { grandfathered: true, reduced: { primary: 3, area15: 3, twoSec: 3 } }, 'd'.repeat(40), /is for cccccccc/);
      const rNo = verifyO(goodO, ownerCfg(), goodRoot, ['--signature-gate', join(tmp, 'no-such-gate.json')]);
      check('owner mode: a missing signature-gate file fails', rNo.status === 1 && /signature-gate.json is missing/.test(rNo.stderr), (rNo.stderr || rNo.stdout).slice(0, 300));
      writeGate({ reduced: { primary: 4, area15: 5, twoSec: 4 } });
      writeRecord();
      const rLeg = verify(good, cfg(), goodRoot);
      check('the Legal-ruling interim (no owner) does not read the signature gate', rLeg.status === 0, (rLeg.stderr || rLeg.stdout).slice(0, 300));
      writeGate();
    }
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
    const r = node('check-site-interim.mjs', ['--site', d, '--config', cfgFile, '--root', goodRoot, '--record', recordFile, '--today', '2026-10-16', '--ui-excuse', NO_EXCUSE]);
    check('the check fails when the game pack holds a placeholder name in a file that is not allowlisted', r.status === 1 && /Meridian/.test(r.stderr));
    const d2 = fresh();
    writeFileSync(join(d2, 'play/index.pck'), pack([['sim/core/test/frozen/golden-js.json', 'Meridian Warden Calamity Sovereign KAI VORR'], ['ui/data/terms.json', '{}']]));
    const r2 = node('check-site-interim.mjs', ['--site', d2, '--config', cfgFile, '--root', goodRoot, '--record', recordFile, '--today', '2026-10-16', '--ui-excuse', NO_EXCUSE]);
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

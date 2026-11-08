// Self-test of tools/preview (the private preview build, docs/tools/preview.md): the switch edits on fixture files, the cascade, the scratch patch, the whole build against a throwaway git
// repository with a stand-in for Godot (the repository's files must come out untouched, the build's tree flipped and patched), the local server, and, with a browser, the smoke check on a tiny page.
// No Godot. CI runs it; --require-browser makes a missing browser a failure.
//   node tools/preview/preview-selftest.mjs [--require-browser]
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { request } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { buildPreview, buildKey, serveLocal, checkTree, plan, overlayPaths, overlayFiles, applyPatchText } from './preview.mjs';
import * as BB from './blackbox.mjs';
import { rawPadProblems } from './blackbox-rawpad-check.mjs';
import { SWITCHES, KICK_SAMPLES, HITSTOP_SAMPLES, PEAK_SAMPLES, IDS, locate, flip, resolve, errorSwitch, patchMain, tableWith, loadPending, planetFunc, present, parts } from './switches.mjs';
const HELD = SWITCHES.filter((x) => x.held).map((x) => x.id);   // rows held off by default (the city rows): on the list, off, with their reason
const ON = IDS.filter((i) => !HELD.includes(i));
import { expectations, probeProblems } from './smoke.mjs';
import { browserExe } from '../machine/browser.mjs';
import { shellSnippet, injectShell } from '../lib/audio-shell.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const throws = (f) => { try { f(); return null; } catch (e) { return e.message; } };
const CR = String.fromCharCode(13);
const sw = (id) => SWITCHES.find((s) => s.id === id);

// ---- fixtures shaped like the real files (a comment string that mentions "enabled", the same key at several depths)
const WATER = JSON.stringify({ schema: 'biomes.water/1', _about: 'enabled: the whole model. surface: {"enabled": true} is a story.', enabled: false, table: { wetland: { depth: 6.0, near: false } }, near: { reach: 36 }, surface: { enabled: false, ticks: 30 }, floor: { enabled: false } }, null, 2);
const CLIMATE = JSON.stringify({ schema: 'biomes.climate/1', gen: 1, grid: { w: 192, h: 96 }, fine: [{ gen: 1 }] }, null, 2);
const BIOME = JSON.stringify({ schema: 'combat.launch_biome/1', _about: 'biome.enabled is behind it', biome: { enabled: false, rules: { a: 1 } }, other: { enabled: true } }, null, 2);
const RINGS = JSON.stringify({ schema: 'biomes.rings/1', sizes: { half: 76800 }, turn: { on: 0, maxTurns: 4, gapSeconds: 60.0, driftDeg: 40.0, _note: 'turn.on 0 is off' } }, null, 2);
const INTERRUPTS = JSON.stringify({ enabled: true, a: { enabled: true }, water: { enabled: false, surfaceTicks: 30, _note: 'water.enabled false' }, rally: { enabled: false }, calmTurn: { enabled: false, landedTicks: 45 } }, null, 2);
const MAIN = [
  'extends Node', 'const URL_ARGS: Array = ["nointro", "skyreact"]', 'var args: Dictionary = {}', 'var _planet_next: Dictionary = {}', 'var frames: int = 0', '',
  'func _match_setup(seed: int = 0) -> Dictionary:', '\tif manual or args.has("nointro"):', '\t\treturn _planet_next.duplicate()', '\tvar su: Dictionary = {"intro": 1}', '\tsu.merge(_planet_next)', '\treturn su', '',
  'func _on_menu_started(cfg: Dictionary) -> void:', '\tif bool(cfg.get("intros", true)):', '\t\tstart_match(1)', '\telse:', '\t\tvar su: Dictionary = _planet_next.duplicate()', '\t\tstart_match(1, {}, su)', '',
  'func _ready() -> void:', '	ui_hud.menu_changed.connect(_on_menu_changed)', '',
  'func _process(delta: float) -> void:', '\tvar n: int = host.advance(delta, vp.x, vp.y)', '\tframes += 1', '',
].join('\n');

// ---- locating and flipping
for (const [name, text, id] of [['water.json enabled (the first key of that name, the file also has nested ones)', WATER, 'water'], ['water.json surface.enabled', WATER, 'surface'], ['water.json floor.enabled', WATER, 'floor'], ['climate gen', CLIMATE, 'gen2'], ['launch_biome biome.enabled', BIOME, 'biome'], ['interrupts water.enabled (not the other enabled keys)', INTERRUPTS, 'interrupts']]) {
  const s = sw(id);
  const r = flip(text, s);
  const was = JSON.parse(text), now = JSON.parse(r.text);
  const at = (o) => s.path.reduce((v, k) => v[k], o);
  check(`flip ${name}`, at(was) === s.from && at(now) === s.to);
  // the rest of the file is as it was: the same text but for the one value
  const loc = locate(text, s.path);
  check(`flip ${name}: only that value changes`, r.text === text.slice(0, loc.start) + JSON.stringify(s.to) + text.slice(loc.end));
}
check('flip leaves the other enabled keys alone (water.json)', JSON.parse(flip(WATER, sw('water')).text).surface.enabled === false && JSON.parse(flip(WATER, sw('surface')).text).enabled === false);
check('flip leaves the other enabled keys alone (interrupts.json)', (() => { const j = JSON.parse(flip(INTERRUPTS, sw('interrupts')).text); return j.enabled === true && j.a.enabled === true && j.rally.enabled === false && j.water.enabled === true && j.calmTurn.enabled === false; })());
check('a string that looks like a key is not mistaken for it', JSON.parse(flip(BIOME, sw('biome')).text).biome.enabled === true && JSON.parse(flip(BIOME, sw('biome')).text).other.enabled === true);
check('CRLF files keep their line endings', flip(WATER.split('\n').join(CR + '\n'), sw('water')).text.split(CR + '\n').length === WATER.split('\n').length);
check('a byte order mark is kept and read past', flip(String.fromCharCode(0xfeff) + CLIMATE, sw('gen2')).text.charCodeAt(0) === 0xfeff);
check('a switch already on in the file is left on and reported as was', flip(CLIMATE.replace('"gen": 1', '"gen": 2'), sw('gen2')).was === '2');
check('a stale table (a value that is neither) throws and names the file', /climate\.json.*gen is 3/.test(throws(() => flip(CLIMATE.replace('"gen": 1', '"gen": 3'), sw('gen2'))) || ''));
check('a key that is not there throws and names the file', /water\.json: no key floor\.enabled/.test(throws(() => flip(JSON.stringify({ enabled: false }), sw('floor'))) || ''));
check('locate finds nothing in a file that is not an object', locate('[1,2]', ['a']) === null);

// ---- the cascade
const R = (...off) => resolve(off);
check('by default every switch is on', R().active.join() === ON.join() && R().cascaded.length === 0);
check('--off floor turns off only the floor', R('floor').active.join() === ON.filter((i) => i !== 'floor').join());
check('--off surface turns the floor off with it, and says why', R('surface').active.includes('floor') === false && R('surface').cascaded[0].id === 'floor' && R('surface').cascaded[0].because.join() === 'surface');
check('--off interrupts turns the floor off with it', !R('interrupts').active.includes('floor') && R('interrupts').active.includes('surface'));
check('--off gen2 turns nothing else off', R('gen2').cascaded.length === 0 && R('gen2').active.length === ON.length - 1);
check('swing (DirSwing) is a data flag of data/director/swing.json `enabled`, waits for the file and needs gen3; the top-level key is the one flipped, not the nested ones', (() => { const s = SWITCHES.find((x) => x.id === 'swing'); if (!s || s.file !== 'data/director/swing.json' || s.path.join() !== 'enabled' || !s.optional || s.needs.join() !== 'gen3') return false; const T = '{\n  "enabled": false,\n  "kinds": {\n    "launch": {\n      "enabled": true\n    }\n  },\n  "other": {\n    "enabled": false\n  }\n}\n'; const f = flip(T, s); return f.text === T.replace('"enabled": false,\n  "kinds"', '"enabled": true,\n  "kinds"'); })());
check('the city rows are held off by default, with their reason, and --on turns one on', HELD.join() === 'wallPush,wallPushAi,slamTurn,cityHold,aimCuts' && resolve([]).held.filter((h) => /QA city read/.test(h.why)).length === 4 && !resolve([]).held.some((h) => h.id === 'refusedCue')   /* ON since 2026-11-08: Encounter confirmed it is safe (stun_limit is gone) */ && resolve([]).held.filter((h) => /next batch/.test(h.why)).map((h) => h.id).join() === 'aimCuts' && resolve([], SWITCHES, ['wallPush']).active.includes('wallPush') && !resolve([], SWITCHES, ['wallPush']).active.includes('slamTurn') && resolve([], SWITCHES, ['wallPush']).held.length === HELD.length - 1);
{
  const fs = SWITCHES.find((x) => x.id === 'flightStrikes');
  const INT = JSON.stringify({ zip: { flightStrikes: { enabled: false } }, other: { enabled: false } }, null, 2);
  const TIM = JSON.stringify({ switches: { flightStrikeB: false, dodgeHeld: false, rightStick: false } }, null, 2);
  const ps = parts(fs);
  check('flightStrikes is one row of three keys over two files, needing rightStick and signatureRtOnly, ON by default (the EP, 2026-11-07)', ps.length === 2 && ps[0].file === 'data/director/interrupts.json' && ps[1].file === 'data/input/timing.json' && ps[1].sw.more.length === 1 && fs.needs.join() === 'rightStick,signatureRtOnly' && fs.held === undefined);
  const a = JSON.parse(flip(INT, ps[0].sw).text), b = JSON.parse(flip(TIM, ps[1].sw).text);
  check('flipping each part turns all three keys on and leaves the rest', a.zip.flightStrikes.enabled === true && a.other.enabled === false && b.switches.flightStrikeB === true && b.switches.dodgeHeld === true && b.switches.rightStick === false);
  check('a part whose key is missing is not present (the row waits)', present(INT, ps[0].sw) && !present(JSON.stringify({ switches: { dodgeHeld: false } }), ps[1].sw));
  check('a one-file row has one part (the city row, a plain row)', parts(SWITCHES.find((x) => x.id === 'cityHold')).length === 1 && parts(SWITCHES.find((x) => x.id === 'aimCuts')).length === 1);
  check('--on flightStrikes without rightStick off turns it on; with rightStick off it cascades off', resolve([], SWITCHES, ['flightStrikes']).active.includes('flightStrikes') && !resolve(['rightStick'], SWITCHES, ['flightStrikes']).active.includes('flightStrikes'));
}
check('a held row that needs another held row stays off with it (wallPushAi needs wallPush)', !resolve([], SWITCHES, ['wallPushAi']).active.includes('wallPushAi') && resolve([], SWITCHES, ['wallPush', 'wallPushAi']).active.includes('wallPushAi'));
check('an --on that names no row is unknown', resolve([], SWITCHES, ['nope']).unknown.join() === 'nope');
{
  const city = SWITCHES.find((x) => x.id === 'cityHold');
  const brunt = JSON.stringify({ lodgeHold: 'world', wallRebound: 0.25, wallStop: 1, wallDepthHold: 0, repeatMarks: 0, other: 5 }, null, 2);
  const f = flip(brunt, city);
  const v = JSON.parse(f.text);
  check('a row of several keys flips them all (cityHold: lodgeHold body, no rebound, no stop, depth hold, two marks) and leaves the rest', v.lodgeHold === 'body' && v.wallRebound === 0 && v.wallStop === 0 && v.wallDepthHold === 1 && v.repeatMarks === 2 && v.other === 5 && present(brunt, city) && !present(JSON.stringify({ lodgeHold: 'world' }), city));
  check('flipping a multi-key row twice reads the same (the second is already on)', flip(f.text, city).text === f.text);
}
{
  const { switchList } = await import('./stack-preview.mjs');
  const b = { table: tableWith([]), active: ON.filter((i) => i !== 'airBrake'), waiting: [{ id: 'airBrake', why: 'brake.json is not in this tree yet' }], held: resolve([]).held, cascaded: [] };
  const L = switchList(b);
  const line = (id) => L.find((x) => x.startsWith(id + ' '));
  check('the final switch list says ON, WAITING (with why) or OFF (with why) and the data key for every row', L.length === IDS.length && /^rightStick +ON +data\/input\/timing\.json switches\.rightStick/.test(line('rightStick')) && /WAITING \(brake\.json is not in this tree yet\)/.test(line('airBrake')) && /OFF \(waiting on QA city read\) +data\/biomes\/brunt\.json lodgeHold \(\+wallRebound, \+wallStop, \+wallDepthHold, \+repeatMarks\)/.test(line('cityHold')) && /ON +data\/director\/interrupts\.json zip\.flightStrikes\.enabled \(\+timing\.json switches\.flightStrikeB, \+timing\.json switches\.dodgeHeld\)/.test(line('flightStrikes')) && /\(page word\)/.test(line('tiles')));
}
{   // Audio's shell snippet is in the head of EVERY web build (the EP, 2026-11-07): the helper, and the three places that build pages call it
  const REPO_ROOT = decodeURIComponent(new URL('../..', import.meta.url).pathname).replace(/^\/([A-Za-z]:)/, '$1');
  const snip = shellSnippet(REPO_ROOT);
  const page = '<!DOCTYPE html>\n<html><head>\n<script src="index.js"></script></head><body></body></html>';
  const once1 = injectShell(page, 'var a = 1; /* </script> */');
  check('the audio shell snippet is in the repository (docs/audio/shell-snippet.js, or the park until it lands)', snip.length > 500 && /AudioContext/.test(snip));
  check('injectShell puts the snippet in its own marked script as the first thing in head, before the engine script, and a </script inside it cannot end it', /<head>\n<script data-orb-shell>\nvar a = 1;/.test(once1) && once1.indexOf('data-orb-shell') < once1.indexOf('index.js') && once1.includes('<\\/script') && once1.split('</script>').length === 3);
  check('injectShell twice is the same page, an empty snippet leaves the page as it was, and a head-less page gets it first', injectShell(once1, 'var b = 2;') === once1 && injectShell(page, '') === page && injectShell('<p>x</p>', 'var c;').startsWith('<script data-orb-shell>'));
  check('the black box places the same marker, so the snippet is never in a page twice', (() => { const o = BB.injectPage(page, null, 'var d = 1;'); return o.includes('data-orb-shell') && injectShell(o, 'var e = 1;') === o; })());
  const src = (f) => readFileSync(new URL(f, import.meta.url), 'utf8');
  check('the three builders call it: preview.mjs (preview pages), stack-preview.mjs (kept builds) and build-site.mjs (the public /play/ and /bench/)', /injectShell\(h0, snip\)/.test(src('./preview.mjs')) && /injectShell\(readFileSync\(ix, 'utf8'\), snip\)/.test(src('./stack-preview.mjs')) && (src('../build-site.mjs').match(/injectShell\((play|bench), SHELL\)/g) || []).length === 2);
}
{   // the Open shortcut's address: extra page words (Sunday: &travel=1.5), CRLF, the port
  const { shortcutText } = await import('./make-shortcuts.mjs');
  const plain = shortcutText({ kept: 'orb-first-play-aaaaaaaa-bbbbbbbb', port: 8768, title: 't', peak: false }), withTravel = shortcutText({ kept: 'orb-first-play-aaaaaaaa-bbbbbbbb', port: 8768, title: 't', peak: true, words: 'travel=1.5' });
  check('the Open shortcut carries the extra words on its address (travel=1.5), keeps CRLF, and is unchanged with no words', withTravel.includes('&audiolog=1&peak=1&travel=1.5"') && !plain.includes('travel') && withTravel.includes('\r\n') && /index\.html\?planet=7&meteor=loud&tiles=1&go=1&blackbox=1&audiolog=1"/.test(plain) && throws(() => shortcutText({ kept: 'k', port: 1, title: 't', words: 'a b' })) !== null);
}
{   // flickKeep flips flickKeep.enabled, pendFollow.enabled and (ifPresent) Controls' switches.flickKept: the row works before and after that key lands
  const fk = SWITCHES.find((x) => x.id === 'flickKeep');
  const ps = parts(fk);
  const STICK = JSON.stringify({ flickKeep: { enabled: false }, pendFollow: { enabled: false } }, null, 2);
  const TIM0 = JSON.stringify({ switches: { rightStick: false } }, null, 2), TIM1 = JSON.stringify({ switches: { rightStick: false, flickKept: false } }, null, 2);
  const f0 = flip(STICK, ps[0].sw), f1 = flip(TIM1, ps[1].sw);
  check('flickKeep is one row over two files: flickKeep.enabled and pendFollow.enabled in stick.json, switches.flickKept (ifPresent) in timing.json', ps.length === 2 && ps[0].file === 'data/director/stick.json' && ps[1].file === 'data/input/timing.json' && ps[1].sw.ifPresentPrimary === true && ps[0].sw.more.length === 1 && ps[0].sw.more[0].path.join('.') === 'pendFollow.enabled');
  check('before the 07:00 batch (no flickKept key): the row is present, flips both stick.json keys, and leaves timing.json exactly as it was', present(STICK, ps[0].sw) && present(TIM0, ps[1].sw) && JSON.parse(f0.text).flickKeep.enabled === true && JSON.parse(f0.text).pendFollow.enabled === true && flip(TIM0, ps[1].sw).text === TIM0);
  check('after it (the key is in timing.json): the same row turns switches.flickKept on and nothing else', JSON.parse(f1.text).switches.flickKept === true && JSON.parse(f1.text).switches.rightStick === false);
  check('a key that is not ifPresent still makes a row wait when it is missing (the rule is only for the keys that say so)', !present(JSON.stringify({ flickKeep: { enabled: false } }), ps[0].sw));
}
check('--off with a comma list and --off all', R('water,biome').active.join() === 'gen2,surface,interrupts,floor,calmTurn,turn,rightStick,quickRead,hapticLadder,specialsOff,signatureRtOnly,beamAim,hapticRefused,hapticIncoming,webRumble,settle,splitShare,chaseTap,chargeArmour,powerPace,waterWarm,chargeClose,pressWait,oneRuleB,beamAim2,nodeWarm,stickPend,joltYield,brawlShareCap,gen3,blackbox,go,meteor,tiles,swing,everywhere,arc,ending,follow,lightStops,grapple,driver,driverOnRb,beamMove,stallKeep,hapticImpact,dodgeHeld,hapticStages,refusedCue,strikeStages,beamMoveAi,pushMode,pushUi,pushUi2,flightStrikes,stickLungeLight,flickKeep,flickRun,fullSend,chordPick,airBrake,stances,phrases,craterlook,vsHuman,firstMeteor,beamFront,kick,mixed,struggle,soundTug,soundMoments,soundCarry' && R('all').active.length === 0);
check('an unknown id is reported, not ignored', R('watr').unknown.join() === 'watr');

// ---- error hints
check('a floor load error points at the floor', errorSwitch('water.json: the floor needs both halves of the surfacing rule') === 'floor');
check('a water.json error points at water', errorSwitch('water.json: fill.halfMax at least 4') === 'water');
check('an interrupts error points at interrupts', errorSwitch('interrupts.json: water is {enabled}') === 'interrupts');
check('a climate error points at gen 2, an unrelated line at nothing', errorSwitch('climate.json: gen is missing') === 'gen2' && errorSwitch('something else') === null);

// ---- the scratch patch
const P = patchMain(MAIN);
check('the patch routes the three planet reads through the entry', !/_planet_next\.duplicate\(\)\n/.test(P.split('func _preview_planet')[0]) && P.split('func _preview_planet')[0].split('_preview_planet()').length - 1 === 3);
check('the patch adds the per-frame probe call and both functions', /host\.advance\(delta, vp\.x, vp\.y\)\n\tif args\.has\("preview"\):\n\t\t_preview_probe\(\)/.test(P) && /func _preview_planet\(\)/.test(P) && /func _preview_probe\(\)/.test(P));
check('the patch keeps CRLF files CRLF throughout', (() => { const c = patchMain(MAIN.split('\n').join(CR + '\n')); return !/[^\r]\n/.test(c.replace(/^\n/, '')); })());
check('an anchor that is gone fails, naming it', /the menu start without intros: expected the line once, found it 0 times/.test(throws(() => patchMain(MAIN.replace('\t\tvar su: Dictionary = _planet_next.duplicate()\n', ''))) || ''));
check('an anchor that is there twice fails', /found it 2 times/.test(throws(() => patchMain(`${MAIN}\n${MAIN}`)) || ''));

// ---- the probe against the expectations
const okProbe = { tick: 900, fine: 4800, planetGen: 2, planet: true, dataGen: 2, biome: true, water: true, surface: true, floor: true, interrupts: true, turn: true, turns: 0, rightStick: true, meteor: true, errors: [], hp: [90, 80] };
check('a probe that matches passes', probeProblems(okProbe, expectations(IDS)).length === 0);
check('a switch that reads off in the running game is named', probeProblems({ ...okProbe, water: false }, expectations(IDS)).map((p) => p.sw).join() === 'water');
check('a gen 2 planet with no fine-biome columns is named',probeProblems({ ...okProbe, fine: 0 }, expectations(IDS.filter((i) => i !== 'gen3'))).some((p) => p.sw === 'gen2'));
check('gen 2 not in force is named', probeProblems({ ...okProbe, planetGen: 1 }, expectations(IDS)).some((p) => p.sw === 'gen2'));
check('with a switch off the probe must read it off', probeProblems({ ...okProbe, floor: true }, expectations(IDS.filter((i) => i !== 'floor'))).map((p) => p.sw).join() === 'floor');
check('the calm turn needs both halves (QA, 2026-10-31): calmTurn is interrupts.json calmTurn.enabled, turn needs it, and --off calmTurn turns turn off with it', sw('calmTurn').file === 'data/director/interrupts.json' && sw('calmTurn').path.join('.') === 'calmTurn.enabled' && sw('turn').needs.join() === 'calmTurn' && !R('calmTurn').active.includes('turn') && R('calmTurn').cascaded.some((c) => c.id === 'turn') && R('turn').active.includes('calmTurn'));
check('the calm turn is a switch: off by one flag, named when the running game reads it off', sw('turn').path.join('.') === 'turn.on' && sw('turn').from === 0 && sw('turn').to === 1 && probeProblems({ ...okProbe, turn: false }, expectations(IDS)).map((p) => p.sw).join() === 'turn' && probeProblems({ ...okProbe, turn: false }, expectations(IDS.filter((i) => i !== 'turn'))).length === 0 && errorSwitch('rings.json: bad bearing') === 'turn');
check('the water loader\'s own errors are failures that name a switch', probeProblems({ ...okProbe, errors: ['water.json: the floor needs both halves of the surfacing rule'] }, expectations(IDS)).some((p) => p.sw === 'floor'));
check('no probe at all is a failure', probeProblems(null, expectations(IDS)).length === 1);

// ---- the whole build, against a throwaway repository and a stand-in for Godot
const tmp = mkdtempSync(join(tmpdir(), 'preview-selftest-'));
const git = (cwd, ...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@example.invalid', '-c', 'commit.gpgsign=false', ...a], { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
try {
  const repo = join(tmp, 'repo');
  for (const d of ['data/biomes', 'data/combat', 'data/director', 'render/core', 'tools']) mkdirSync(join(repo, d), { recursive: true });
  const files = { 'data/biomes/climate.json': CLIMATE, 'data/biomes/water.json': WATER, 'data/combat/launch_biome.json': BIOME, 'data/director/interrupts.json': INTERRUPTS, 'data/biomes/rings.json': RINGS, 'render/core/main.gd': MAIN, 'tools/site.json': '{"offline": false, "template": "custom"}\n' };
  git(repo, 'init', '-q', '-b', 'main');
  git(repo, 'config', 'core.autocrlf', 'false');
  for (const [f, t] of Object.entries(files)) writeFileSync(join(repo, f), t);
  git(repo, 'add', '-A'); git(repo, 'commit', '-q', '-m', 'the fixture');
  const stub = join(tmp, 'godot-stub.mjs');
  writeFileSync(stub, [
    "import { readFileSync, writeFileSync, appendFileSync } from 'node:fs';",
    "import { join, dirname } from 'node:path';",
    "const a = process.argv.slice(2); const tree = a[a.indexOf('--path') + 1];",
    "if (a.includes('--export-release')) {",
    "  const out = a[a.indexOf('--export-release') + 2];",
    "  const j = (f) => JSON.parse(readFileSync(join(tree, f), 'utf8'));",
    "  const seen = { gen: j('data/biomes/climate.json').gen, water: j('data/biomes/water.json').enabled, floor: j('data/biomes/water.json').floor.enabled, surface: j('data/biomes/water.json').surface.enabled, biome: j('data/combat/launch_biome.json').biome.enabled, interrupts: j('data/director/interrupts.json').water.enabled, turn: j('data/biomes/rings.json').turn.on, rs: (() => { try { return j('data/input/timing.json').switches.rightStick; } catch { return null; } })(), host: readFileSync(join(tree, 'render/core/main.gd'), 'utf8').includes('_pad_stick_right'), probeRs: readFileSync(join(tree, 'render/core/main.gd'), 'utf8').includes('SimInputData.right_stick_on()'), pg3: readFileSync(join(tree, 'render/core/main.gd'), 'utf8').includes('\"planetGen\": 3'), patched: /_preview_probe/.test(readFileSync(join(tree, 'render/core/main.gd'), 'utf8')), buildInfo: j('build_info.json'), args: a };",
    "  writeFileSync(out, '<html>stub</html>'); writeFileSync(join(dirname(out), 'seen.json'), JSON.stringify(seen));",
    "  if (process.env.STUB_FAIL) { console.log('SCRIPT ERROR: stub failure line'); process.exit(3); }",
    "} else { console.log('import ok'); }",
  ].join('\n'));
  const out = join(tmp, 'out');
  const opts = { repo, rev: 'main', out, godotNode: stub, off: [], planet: 7 };
  const b = await buildPreview(opts);
  const seen = JSON.parse(readFileSync(join(b.web, 'seen.json'), 'utf8'));
  check('the build ends in index.html under the output folder', existsSync(join(b.web, 'index.html')) && b.web.startsWith(out));
  check('in the scratch tree every switch was on and main.gd patched', seen.gen === 2 && seen.water && seen.floor && seen.surface && seen.biome && seen.interrupts && seen.turn === 1 && seen.patched, JSON.stringify(seen));
  check('the export is the standard one: no template argument was passed', !seen.args.some((x) => /template/i.test(x)));
  check('build_info.json names the commit', seen.buildInfo.commit === git(repo, 'rev-parse', '--short=7', 'main').trim());
  check('it recorded the eight flips', b.flips.length === 8 && b.flips.every((f) => !f.alreadyOn));
  check('THE REPOSITORY IS UNTOUCHED: every file as committed and nothing new', git(repo, 'status', '--porcelain').trim() === '', git(repo, 'status', '--porcelain'));
  check('tools/site.json is byte for byte as it was', readFileSync(join(repo, 'tools/site.json'), 'utf8') === files['tools/site.json']);
  check('the scratch tree is removed after the export', !existsSync(join(b.dir, 'tree')));
  const again = await buildPreview(opts);
  check('the same command again is served from the cache', again.cached === true && again.web === b.web);
  const off = await buildPreview({ ...opts, off: ['surface'] });
  const seenOff = JSON.parse(readFileSync(join(off.web, 'seen.json'), 'utf8'));
  check('--off surface builds in another folder, with surface and floor off and the rest on', off.web !== b.web && seenOff.surface === false && seenOff.floor === false && seenOff.water === true && seenOff.gen === 2 && off.cascaded.length === 1);
  const plain = await buildPreview({ ...opts, off: ['all'] });
  const seenPlain = JSON.parse(readFileSync(join(plain.web, 'seen.json'), 'utf8'));
  check('--off all is the plain build: every data file as committed (the code patch still rides)', seenPlain.gen === 1 && !seenPlain.water && !seenPlain.floor && !seenPlain.surface && !seenPlain.biome && !seenPlain.interrupts && seenPlain.patched);
  check('the cache key tells the builds apart', buildKey('a'.repeat(40), ['gen2']) !== buildKey('a'.repeat(40), []) && buildKey('a'.repeat(40), ['gen2']) !== buildKey('b'.repeat(40), ['gen2']));
  const bad = await buildPreview({ ...opts, rebuild: true, off: ['water'] }).then(() => null, (e) => e.message);
  check('(a build that works can be rebuilt on request)', bad === null);
  process.env.STUB_FAIL = '1';
  const failMsg = await buildPreview({ ...opts, rebuild: true, off: ['biome'] }).then(() => '', (e) => e.message);
  delete process.env.STUB_FAIL;
  check('a failed export says so and shows the end of the log', /Godot --export-release Web exited 3/.test(failMsg) && /stub failure line/.test(failMsg), failMsg);
  check('an unknown switch refuses before any work', /unknown switch watr/.test(await buildPreview({ ...opts, off: ['watr'] }).then(() => '', (e) => e.message)));

  // ---- the right hand (the EP, 2026-10-31): a switch whose key is not in the tree WAITS; uncommitted work is overlaid; the host patch is applied; --check says what it did not check
  {
    const sha = git(repo, 'rev-parse', 'main').trim();
    const pendingText = JSON.stringify({ rows: [{ id: 'gen9', owner: 'World', what: 'planet generation 3' }, { id: 'tilx', owner: 'Rendering', what: 'tiles', file: 'data/x.json', path: ['tiles', 'on'], from: false, to: true }] });
    const pend = loadPending(pendingText);
    check('the pending rows load; a row with a key joins the table and a row without one never does', pend.problems.length === 0 && tableWith(pend.rows).some((s) => s.id === 'tilx' && s.optional && s.needs.length === 0) && !tableWith(pend.rows).some((s) => s.id === 'gen9'), JSON.stringify(pend.problems));
    const pbad = (rows) => loadPending(JSON.stringify({ rows })).problems.join(' | ');
    check('a pending row needs an id, a line of what and who, a path with its file, and an id nobody uses', /needs an id/.test(pbad([{ what: 'x', owner: 'y' }])) && /needs "what" and "owner"/.test(pbad([{ id: 'a1' }])) && /needs path/.test(pbad([{ id: 'a1', what: 'x', owner: 'y', file: 'f.json' }])) && /already a switch/.test(pbad([{ id: 'water', what: 'x', owner: 'y' }])) && /not JSON/.test(loadPending('{').problems.join()));
    const p0 = plan(repo, sha, { pending: pend.rows });
    check('a switch whose key is not in the tree WAITS: not on, with the reason; the others stay on', !p0.active.includes('rightStick') && p0.waiting.some((w) => w.id === 'rightStick' && /not in this tree yet/.test(w.why)) && p0.waiting.some((w) => w.id === 'tilx') && p0.active.includes('turn') && p0.active.includes('floor'), JSON.stringify(p0.waiting));
    check('--off still takes a waiting switch\'s id and a switch that waits is not "unknown"', plan(repo, sha, { off: ['rightStick'], pending: pend.rows }).unknown.length === 0);

    // a working tree with Controls' work in it, not committed
    const work = (p, text) => { mkdirSync(join(repo, p, '..'), { recursive: true }); writeFileSync(join(repo, p), text); };
    const mainBase = readFileSync(join(repo, 'render/core/main.gd'), 'utf8');
    writeFileSync(join(repo, 'render/core/main.gd'), mainBase.replace(/\s*$/, '\n') + 'var _pad_stick_right: Dictionary = {}\n');
    const hostText = git(repo, 'diff', 'render/core/main.gd');
    git(repo, 'checkout', 'render/core/main.gd');
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: false, other: true } }, null, 2) + '\n');
    work('sim/input/input_data.gd', 'static func right_stick_on() -> bool:\n\treturn false\n');
    work('docs/controls/pending/right-hand/right-hand-host.patch', hostText);
    const OV = ['data/input', 'sim/input', 'docs/controls/pending/right-hand'];
    const p1 = plan(repo, sha, { overlay: OV, pending: pend.rows });
    check('with the work overlaid the switch is on, needs the host patch (main.gd has not got it) and brings its probe field', p1.active.includes('rightStick') && p1.hostPatch === hostText && p1.probes.length === 4 && /right_stick_on/.test(p1.probes[3]) && !p1.waiting.some((w) => w.id === 'rightStick'), JSON.stringify(p1));
    check('the overlay is read from the working tree and the commit is not: without it the same switch waits', !plan(repo, sha, { pending: pend.rows }).active.includes('rightStick'));
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: false } }, null, 2) + '\n');
    const noPatch = plan(repo, sha, { overlay: ['data/input', 'sim/input'], pending: pend.rows });
    check('the pad\'s right stick unread and no host patch in the tree: the switch WAITS and says so, it is not turned on half-built', !noPatch.active.includes('rightStick') && noPatch.waiting.some((w) => w.id === 'rightStick' && /right-hand-host\.patch is not in it/.test(w.why)), JSON.stringify(noPatch.waiting));
    writeFileSync(join(repo, 'render/core/main.gd'), mainBase.replace(/\s*$/, '\n') + 'var _pad_stick_right: Dictionary = {}\n');
    const landed = plan(repo, sha, { overlay: ['data/input', 'sim/input', 'render/core/main.gd'], pending: pend.rows });
    check('a main.gd that already reads the right stick needs no patch', landed.active.includes('rightStick') && landed.hostPatch === null);
    git(repo, 'checkout', 'render/core/main.gd');
    // pushMode is on only with the host's line beside its data (Controls' host-push.patch): it can never turn on alone
    work('data/director/interrupts.json', JSON.stringify({ beamStruggle: { enabled: false, pushMode: { enabled: false } } }, null, 2) + '\n');
    const pm0 = plan(repo, sha, { overlay: ['data/director'], pending: pend.rows });
    check('pushMode waits, and says why, while the host has no pushModeOf line', !pm0.active.includes('pushMode') && pm0.waiting.some((w) => w.id === 'pushMode' && /pushModeOf/.test(w.why)), JSON.stringify(pm0.waiting.filter((w) => /push/.test(w.id))));
    work('render/core/sim_host.gd', 'func tick():\n\tvar stick = DirBeam.pushModeOf(S, f) == "stick"\n');
    const pm1 = plan(repo, sha, { overlay: ['data/director', 'render/core/sim_host.gd'], pending: pend.rows });
    check('with the host line in the tree pushMode is on, with struggle, and the two UI rows follow it only when the option is there to flip', pm1.active.includes('pushMode') && pm1.active.includes('struggle') && !pm1.active.includes('pushUi') && pm1.waiting.some((w) => w.id === 'pushUi'));
    for (const f of ['data/director/interrupts.json', 'render/core/sim_host.gd']) { try { git(repo, 'checkout', '--', f); } catch { rmSync(join(repo, f), { force: true }); } }
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: 7 } }, null, 2) + '\n');
    const stale = plan(repo, sha, { overlay: ['data/input', 'sim/input', 'docs/controls/pending/right-hand'], pending: pend.rows });
    check('a key that holds neither the old nor the new value is stale: it waits and the problem is named', !stale.active.includes('rightStick') && stale.stale.some((s) => /switches\.rightStick is 7/.test(s)), JSON.stringify(stale.stale));
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: false } }, null, 2) + '\n');

    // gen3: a key of the match's setup (planetGen 3, a whole ring), present when World's code is in the tree
    check('gen3 is a setup switch, not a data flag: no file, a setup, the file it waits for', sw('gen3').setup.planetGen === 3 && sw('gen3').file === undefined && sw('gen3').presentIf.file === 'sim/world/field.gd' && sw('gen3').optional === true);
    const g0 = plan(repo, sha, { pending: pend.rows });
    check('without World\'s code the gen3 switch WAITS and says so; nothing is added to the setup', !g0.active.includes('gen3') && g0.waiting.some((w) => w.id === 'gen3' && /sim\/world\/field\.gd is not in this tree yet/.test(w.why)) && Object.keys(g0.setup).length === 0, JSON.stringify(g0.waiting));
    work('sim/world/field.gd', 'extends RefCounted\n');
    const g1 = plan(repo, sha, { overlay: ['sim/world'], pending: pend.rows });
    check('with the file in the tree it is on, and the setup carries planetGen 3', g1.active.includes('gen3') && g1.setup.planetGen === 3 && !g1.waiting.some((w) => w.id === 'gen3'), JSON.stringify(g1));
    check('--off gen3 leaves the setup alone', plan(repo, sha, { overlay: ['sim/world'], off: ['gen3'], pending: pend.rows }).setup.planetGen === undefined);
    check('the scratch main.gd\'s planet entry carries the setup (planetGen 3), and not otherwise', /return \{"planet": int\(args\["planet"\]\), "touch": int\(args\.get\("touch", 3\)\), "planetGen": 3\}/.test(planetFunc([], { planetGen: 3 })) && !/"touch", 3\)\), "planetGen"/.test(planetFunc()) && patchMain(MAIN, [], { planetGen: 3 }).includes('"planetGen": 3') && patchMain(MAIN) === patchMain(MAIN, [], {}));
    check('?kick=1 wraps the planet entry (kick true; off or 0 false) only when the tree has Simulation\'s kick, and the setup still reaches the base entry', planetFunc([], { planetGen: 3 }, { kickWord: true }).includes('func _preview_planet_base() -> Dictionary:') && planetFunc([], {}, { kickWord: true }).includes('d["kick"] = str(args["kick"]) != "off" and str(args["kick"]) != "0"') && /"planetGen": 3\}/.test(planetFunc([], { planetGen: 3 }, { kickWord: true })) && !planetFunc([], {}).includes('_preview_planet_base'));
    check('the kick\'s takeoff words (instant, climbTicks) reach the setup with the same names, clamped, and four sample addresses are printed', (() => { const f = planetFunc([], {}, { kickWord: true }); return f.includes('d["instant"] = clampf(float(args["instant"]), 0.0, 1.0)') && f.includes('d["climbTicks"] = clampi(int(args["climbTicks"]), 0, 120)') && KICK_SAMPLES.length === 4 && KICK_SAMPLES.every((s) => s.add && s.label); })());
    check('the go word runs before the HUD loads its menu, on a local page only, and keeps what the player chose', (() => { const m = patchMain(MAIN); return m.includes('\t_preview_go()\n\tui_hud.menu_changed.connect(_on_menu_changed)') && m.includes('func _preview_go() -> void:') && m.includes('if not d.has("p1"):') && m.includes('if not d.has("intros"):') && m.includes("location.hostname === \'127.0.0.1\'"); })());
    check('?tier= becomes startTier only for a tree that knows it, and the kick lines only for a tree with the kick', (() => { const a = planetFunc([], {}, { tierWord: true }), b = planetFunc([], {}, { kickWord: true }), c = planetFunc([], {}, { kickWord: true, tierWord: true }); return a.includes('d["startTier"] = clampi(int(args["tier"]), 1, 4)') && !a.includes('d["kick"]') && b.includes('d["kick"]') && !b.includes('d["startTier"]') && c.includes('d["startTier"]') && c.includes('d["kick"]') && a.includes('func _preview_planet_base()'); })());
    check('?peak=1 puts startTier 4 in the setup (off by default, 0 or off cancels) and a second address is printed', (() => { const a = planetFunc([], {}, { tierWord: true }); return a.includes('if args.has("peak") and str(args["peak"]) != "0" and str(args["peak"]) != "off":') && a.includes('d["startTier"] = 4') && PEAK_SAMPLES.length === 1 && PEAK_SAMPLES[0].add === 'peak=1' && !planetFunc([], {}, { kickWord: true }).includes('args.has("peak")'); })());
    check('?hitstop= becomes the setup key hitstop only for a tree that has SimHitstop, and a sample address is printed', (() => { const a = planetFunc([], {}, { hitstopWord: true }), b = planetFunc([], {}, { kickWord: true }); return a.includes('d["hitstop"] = str(args["hitstop"]) != "off"') && a.includes('func _preview_planet_base()') && !b.includes('d["hitstop"]') && HITSTOP_SAMPLES.length === 1 && HITSTOP_SAMPLES[0].add === 'hitstop=1'; })());
    check('the black box hooks sim_host.gd in three places, once each, and only reads (the sim is stepped by the same call with the same inputs); a moved file is named', (() => { const HOST = ['extends RefCounted', 'func new_match(p_seed: int) -> void:', '\tsetup_used = su.duplicate(true)', '\t_started(su, remember)', 'func tick() -> void:', '\tif SimCore.step(S, inputs):', '\t\thub.consumed()', 'func toggle_ai(idx: int) -> void:', '\tSimCore.toggleAI(S, idx)', ''].join('\n'); const out = BB.patchHost(HOST); let named = ''; try { BB.patchHost(HOST.replace('\tif SimCore.step(S, inputs):', '\tif SimCore.step(S, inputs, 1):')); } catch (e) { named = e.message; } return out.includes('\t_bb_arm(seed, ai, su)') && out.includes('\tif _bb_step(inputs):') && out.includes('\t_bb_toggle(idx)\n\tSimCore.toggleAI(S, idx)') && out.includes('return SimCore.step(S, inputs)') && out.includes('var r: bool = SimCore.step(S, inputs)') && !/(^|\n)\s*S\.[A-Za-z_.]+\s*=[^=]/.test(out.slice(out.indexOf('func _bb_begin'))) && /the tick's one step/.test(named); })());
    { const rp = rawPadProblems(); check('the black box records the raw pad (every connected pad: buttons, triggers, left stick, a stuck button visible, only changes) and still saves nothing but a download', rp.length === 0, rp.join('; ')); }
    check('the black box page script has no network call and saves through a download', (() => { const s = BB.PAGE_SCRIPT; return !/fetch\(|XMLHttpRequest|sendBeacon|WebSocket|new Image|navigator\.send/.test(s) && /download/.test(s) && /localStorage/.test(s) && BB.injectPage('<html><body>x</body></html>').includes('orb-blackbox-last') && BB.injectPage(BB.injectPage('<body></body>')).split('orb-blackbox-last').length === BB.injectPage('<body></body>').split('orb-blackbox-last').length; })());
    check('a gen 3 probe reads 3 or the data\'s 2, and a field world may have no fine-biome columns: asked for, neither is a failure', probeProblems({ ...okProbe, planetGen: 3, fine: 0 }, expectations(IDS)).length === 0 && probeProblems({ ...okProbe, planetGen: 1, fine: 0 }, expectations(IDS)).some((p) => /planetGen reads 1, expected at least 2/.test(p.text)));
    const gb = await buildPreview({ ...opts, overlay: ['sim/world'], rebuild: true, pending: pend });
    const gs = JSON.parse(readFileSync(join(gb.web, 'seen.json'), 'utf8'));
    check('a build with World\'s code overlaid puts planetGen 3 in the scratch planet entry, and flips no file for it', gb.active.includes('gen3') && gs.pg3 === true && !gb.flips.some((x) => x.id === 'gen3'), JSON.stringify([gb.active, gs.pg3]));
    const gn = await buildPreview({ ...opts, rebuild: true, pending: pend });
    check('without it the entry has no setup key', JSON.parse(readFileSync(join(gn.web, 'seen.json'), 'utf8')).pg3 === false);

    // meteor: a page word (?meteor=loud by default, ?meteor=quiet beside it), present when VFX's data is in the tree
    check('meteor is a page word, not a data flag: the loud word by default, the quiet one as its alternative, the file it waits for, a probe field', sw('meteor').url === 'meteor=loud' && sw('meteor').alt.word === 'meteor=quiet' && sw('meteor').file === undefined && sw('meteor').presentIf.file === 'data/vfx/meteor.json' && sw('meteor').optional === true && /meteor_enabled/.test(sw('meteor').probe));
    const m0 = plan(repo, sha, { pending: pend.rows });
    check('without VFX\'s data the meteor switch WAITS and says so, and prints no word', !m0.active.includes('meteor') && m0.waiting.some((w) => w.id === 'meteor' && /not in this tree yet/.test(w.why)) && !m0.urlWords.includes('meteor=loud'), JSON.stringify(m0.waiting));
    work('data/vfx/meteor.json', '{}\n');
    work('render/vfx/vfx_hub.gd', 'var meteor_enabled: bool = VfxLook.METEOR_DEFAULT\n');
    const m1 = plan(repo, sha, { overlay: ['data/vfx', 'render/vfx'], pending: pend.rows });
    check('with its data in the tree it is on: the loud word is on the address, the quiet one is its alternative, and the probe field comes with it', m1.active.includes('meteor') && m1.urlWords.includes('meteor=loud') && m1.alts.length === 1 && m1.alts[0].to === 'meteor=quiet' && m1.probes.some((p) => /meteor_enabled/.test(p)), JSON.stringify(m1));
    check('--off meteor leaves no word and no alternative', (() => { const o = plan(repo, sha, { overlay: ['data/vfx', 'render/vfx'], off: ['meteor'], pending: pend.rows }); return !o.urlWords.includes('meteor=loud') && o.alts.length === 0; })());
    work('render/vfx/vfx_hub.gd', 'nothing about the meteor here\n');
    check('the probe field is added only when the hub has the field it reads', !plan(repo, sha, { overlay: ['data/vfx', 'render/vfx'], pending: pend.rows }).probes.some((p) => /meteor_enabled/.test(p)));
    work('render/vfx/vfx_hub.gd', 'var meteor_enabled: bool = VfxLook.METEOR_DEFAULT\n');
    check('a meteor expectation reads the probe: asked on, off in the game is named', probeProblems({ ...okProbe, meteor: false }, expectations(IDS)).some((p) => p.sw === 'meteor') && probeProblems({ ...okProbe, meteor: true }, expectations(IDS)).length === 0 && errorSwitch('meteor.gd:12 bad') === 'meteor');
    const mb = await buildPreview({ ...opts, overlay: ['data/vfx', 'render/vfx'], rebuild: true, pending: pend });
    check('a build with VFX\'s data overlaid reports the word and flips no file for it', mb.active.includes('meteor') && mb.urlWords.includes('meteor=loud') && !mb.flips.some((x) => x.id === 'meteor'), JSON.stringify([mb.active, mb.urlWords, mb.flips.filter((x) => x.id === 'meteor')]));

    // ?swings=off (Encounter's page word): in the scratch main.gd only when the tree has DirSwing.setForce
    check('the scratch main.gd gets the swings=off hook only with the option: before the match starts, on a local page, DirSwing.setForce(0)', (() => { const on = patchMain(MAIN, [], {}, { swingsOff: true }), off = patchMain(MAIN); return /func _preview_swings_off\(\) -> void:/.test(on) && /location\.hostname === '127\.0\.0\.1'/.test(on) && /swings=off/.test(on) && /DirSwing\.setForce\(0\)/.test(on) && /func _preview_planet\(\) -> Dictionary:\n\t_preview_swings_off\(\)/.test(on) && !/_preview_swings_off|DirSwing/.test(off) && off === patchMain(MAIN, [], {}, {}); })());
    work('sim/director/swing.gd', 'class_name DirSwing\n');
    check('without setForce in the tree plan says no and lists no address', plan(repo, sha, { overlay: ['sim/director'], pending: pend.rows }).swingsOff === false);
    work('sim/director/swing.gd', 'class_name DirSwing\nstatic func setForce(v: int) -> void:\n\tpass\n');
    const swOffPlan = plan(repo, sha, { overlay: ['sim/director'], pending: pend.rows });
    check('with setForce in the tree plan says yes and the address list gains the swings=off page word', swOffPlan.swingsOff === true && swOffPlan.alts.some((a) => a.add === 'swings=off'), JSON.stringify(swOffPlan.alts));
    check('the tiles row lists the fore tone\'s page word as an alternative address (nofore=1 added, on by default)', sw('tiles').alt && sw('tiles').alt.add === 'nofore=1');
    // tiles: a page word, present when Rendering's tile ground is in the tree, needs gen3
    check('tiles is a page word, not a data flag: no file, the word, the command-line form, the file it waits for, and it needs gen3', sw('tiles').url === 'tiles=1' && sw('tiles').cmd === '--tiles' && sw('tiles').file === undefined && sw('tiles').presentIf.file === 'render/core/tile_ground.gd' && sw('tiles').needs.join() === 'gen3' && sw('tiles').optional === true);
    work('render/core/tile_ground.gd', 'extends RefCounted\n');
    const t0 = plan(repo, sha, { overlay: ['render/core'], pending: pend.rows });
    check('the tile ground in the tree without World\'s code: tiles WAITS because gen3 does (what waits turns off what needs it), and no word is printed', !t0.active.includes('tiles') && t0.waiting.some((w) => w.id === 'tiles' && /needs gen3/.test(w.why)) && t0.urlWords.length === 0, JSON.stringify(t0.waiting));
    const t1 = plan(repo, sha, { overlay: ['render/core', 'sim/world'], pending: pend.rows });
    check('with both in the tree tiles is on and the word is carried on the address', t1.active.includes('tiles') && t1.urlWords.join() === 'tiles=1' && t1.setup.planetGen === 3, JSON.stringify(t1));
    check('--off tiles leaves no word', plan(repo, sha, { overlay: ['render/core', 'sim/world'], off: ['tiles'], pending: pend.rows }).urlWords.length === 0);
    check('the scratch main.gd\'s URL list is edited at the START of the list, so the tile park\'s own words first do not break the anchor', (() => { const m = MAIN.replace('const URL_ARGS: Array = ["nointro", ', 'const URL_ARGS: Array = ["tiles", "tilerate", "nointro", '); return patchMain(m).includes('const URL_ARGS: Array = ["planet", "touch", "preview", "reel", "sticks", "kick", "instant", "climbTicks", "go", "tier", "peak", "hitstop", "blackbox", "script", "replay", "audiolog", "splitshare", "power", "flatout", "travel", "circle", "nohud", "tiles", "tilerate", "nointro", ') && patchMain(MAIN).includes('const URL_ARGS: Array = ["planet", "touch", "preview", "reel", "sticks", "kick", "instant", "climbTicks", "go", "tier", "peak", "hitstop", "blackbox", "script", "replay", "audiolog", "splitshare", "power", "flatout", "travel", "circle", "nohud", "nointro", '); })());
    const tb = await buildPreview({ ...opts, overlay: ['render/core', 'sim/world'], rebuild: true, pending: pend });
    check('a build with both overlaid reports the word and flips no file for it', tb.active.includes('tiles') && tb.urlWords.join() === 'tiles=1' && !tb.flips.some((x) => x.id === 'tiles'), JSON.stringify([tb.active, tb.urlWords]));

    check('plan reads a tree that is not a commit (the stack\'s) through `read`: swing and gen3 are on when the files are there, swing waits and says so when gen3\'s code is not', (() => {
      const files = { 'sim/world/field.gd': 'x', 'data/director/swing.json': '{\n  "enabled": false\n}\n' };
      const on = plan(repo, sha, { read: (p) => (p in files ? files[p] : null) });
      const noField = plan(repo, sha, { read: (p) => (p === 'data/director/swing.json' ? files[p] : null) });
      return on.active.includes('swing') && on.active.includes('gen3') && on.setup.planetGen === 3 && !noField.active.includes('swing') && noField.waiting.some((w) => w.id === 'swing');
    })());
    // the overlay itself
    const bad = (x) => { try { overlayPaths(repo, [x]); return ''; } catch (e) { return e.message; } };
    check('an overlay is a path inside the repository that exists: no .., no absolute path, no .git, nothing missing', /inside the repository/.test(bad('../x')) && /inside the repository/.test(bad('C:/x')) && /inside the repository/.test(bad('/etc')) && /inside the repository/.test(bad('.git')) && /not in the working tree/.test(bad('data/nothing')) && bad('data/input') === '');
    const h1 = overlayFiles(repo, ['data/input']);
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: false, extra: 1 } }, null, 2) + '\n');
    check('the overlay lists its files and its hash follows the contents (the cache key)', h1.files.join() === 'data/input/timing.json' && h1.hash.length === 6 && overlayFiles(repo, ['data/input']).hash !== h1.hash);
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: false } }, null, 2) + '\n');

    // the host patch on a scratch tree
    const tree1 = mkdtempSync(join(tmpdir(), 'preview-host-test-'));
    mkdirSync(join(tree1, 'render/core'), { recursive: true });
    writeFileSync(join(tree1, 'render/core/main.gd'), mainBase);
    applyPatchText(tree1, hostText);
    check('the host patch is applied to the scratch main.gd and leaves nothing behind', readFileSync(join(tree1, 'render/core/main.gd'), 'utf8').includes('_pad_stick_right') && !existsSync(join(tree1, '.preview-host.patch')));
    writeFileSync(join(tree1, 'render/core/main.gd'), 'a different file\n');
    check('a host patch that does not fit says so', (() => { try { applyPatchText(tree1, hostText); return false; } catch (e) { return /does not fit this tree/.test(e.message); } })());
    rmSync(tree1, { recursive: true, force: true });

    // the extra probe field
    check('the probe gains a switch\'s field before the errors line, and only then', /"interrupts"[^\n]*\n\t\t"rightStick": SimInputData\.right_stick_on\(\),\n\t\t"errors"/.test(planetFunc(['"rightStick": SimInputData.right_stick_on()'])) && !/rightStick/.test(planetFunc()) && patchMain(MAIN, ['"rightStick": SimInputData.right_stick_on()']).includes('SimInputData.right_stick_on()') && patchMain(MAIN) === patchMain(MAIN, []));

    // the whole build with the work overlaid
    const ob = await buildPreview({ ...opts, overlay: OV, rebuild: true, pending: pend });
    const so = JSON.parse(readFileSync(join(ob.web, 'seen.json'), 'utf8'));
    check('the build copies the overlay over the scratch tree, turns the key on, applies the host patch and adds the probe field', ob.active.includes('rightStick') && ob.hostPatched === true && so.rs === true && so.host === true && so.probeRs === true && ob.overlay.length === 3 && ob.flips.some((x) => x.id === 'rightStick' && x.key === 'switches.rightStick'), JSON.stringify([so, ob.overlay]));
    check('the cache key tells an overlaid build from the plain one and says the host patch rode', /-ov[0-9a-f]{6}/.test(ob.key) && /-host$/.test(ob.key) && ob.web !== b.web);
    check('build_info.json lists the overlaid paths (a build of uncommitted work says so)', JSON.stringify(so.buildInfo.overlay) === JSON.stringify(OV), JSON.stringify(so.buildInfo));
    check('the committed tree is still untouched by the build (only the working files the test made are new)', git(repo, 'status', '--porcelain', '--untracked-files=no').trim() === '', git(repo, 'status', '--porcelain'));
    const ob2 = await buildPreview({ ...opts, overlay: OV, pending: pend });
    check('the same overlaid command again is served from the cache', ob2.cached === true && ob2.web === ob.web);
    const obOff = await buildPreview({ ...opts, overlay: OV, off: ['rightStick'], pending: pend });
    check('--off rightStick leaves the data as the working tree has it, the host patch unapplied', obOff.active.includes('rightStick') === false && JSON.parse(readFileSync(join(obOff.web, 'seen.json'), 'utf8')).rs === false && JSON.parse(readFileSync(join(obOff.web, 'seen.json'), 'utf8')).host === false);

    // --check: what it checked and what waits
    const notes = [];
    const probs = checkTree(repo, 'main', { overlay: OV, notes, pending: pend });
    check('--check passes with the work overlaid, says the host patch fits and that the work is uncommitted, and lists what waits', probs.length === 0 && notes.some((n) => /host patch fits/.test(n)) && notes.some((n) => /overlay from the working tree \(uncommitted\)/.test(n)) && notes.some((n) => /waiting, no key yet: gen9/.test(n)) && notes.some((n) => /waiting, not on: tilx/.test(n)), JSON.stringify([probs, notes]));
    const notes2 = [];
    check('--check without the work lists the right stick as waiting and is not an error', checkTree(repo, 'main', { notes: notes2, pending: pend }).length === 0 && notes2.some((n) => /waiting, not on: rightStick/.test(n)));
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: 7 } }, null, 2) + '\n');
    check('--check fails on a key that is there with a value the table does not know', checkTree(repo, 'main', { overlay: OV, pending: pend }).some((p) => /switches\.rightStick is 7/.test(p)));
    check('a missing or malformed pending file is reported by --check', checkTree(repo, 'main', { pending: loadPending('{"rows":[{"id":"gen9"}]}') }).some((p) => /switches-pending\.json/.test(p)));
    for (const d of ['data/input', 'sim', 'docs']) rmSync(join(repo, d), { recursive: true, force: true });
  }
  check('--check on the fixture repository finds every key and anchor', checkTree(repo, 'main').length === 0);
  check('--check says which file is out of date', checkTree(repo, 'main~0').length === 0 && (() => { writeFileSync(join(repo, 'data/biomes/water.json'), JSON.stringify({ enabled: false })); git(repo, 'commit', '-q', '-am', 'break'); return checkTree(repo, 'main').some((p) => /water\.json: no key surface\.enabled/.test(p)); })());

  // ---- the server
  mkdirSync(join(tmp, 'site'), { recursive: true });
  writeFileSync(join(tmp, 'site', 'index.html'), 'hello'); writeFileSync(join(tmp, 'site', 'a.wasm'), 'w'); writeFileSync(join(tmp, 'secret.txt'), 'no');
  const srv = await serveLocal(join(tmp, 'site'), 0, { strict: true });
  const port = srv.address().port;
  const get = (path) => new Promise((ok, fail) => { const r = request({ host: '127.0.0.1', port, path, method: 'GET', agent: false }, (res) => { let d = ''; res.on('data', (c) => { d += c; }); res.on('end', () => ok({ status: res.statusCode, type: res.headers['content-type'], cache: res.headers['cache-control'], body: d })); }); r.on('error', fail); r.end(); });
  check('the server listens on 127.0.0.1 only', srv.address().address === '127.0.0.1');
  const idx = await get('/index.html');
  check('it serves the page, uncached', idx.status === 200 && idx.body === 'hello' && idx.cache === 'no-store');
  check('it serves wasm with its type', (await get('/a.wasm')).type === 'application/wasm');
  check('it refuses a path outside the folder and a missing file', (await get('/..%2Fsecret.txt')).status === 404 && (await get('/nope')).status === 404);
  const second = await serveLocal(join(tmp, 'site'), port, { strict: false });
  check('a busy default port falls on to the next', second.address().port !== port);
  check('a busy port that was asked for is an error', await serveLocal(join(tmp, 'site'), port, { strict: true }).then(() => false, (e) => e.code === 'EADDRINUSE'));
  second.close(); srv.close();

  // ---- the smoke check on a tiny page (needs a browser)
  const exe = browserExe('chrome') || browserExe('edge');
  if (!exe) {
    check('a browser is installed (--require-browser)', !process.argv.includes('--require-browser'));
    console.log('  (no chrome or edge here: the smoke check\'s own test is skipped)');
  } else {
    const { smoke } = await import('./smoke.mjs');
    const page = (probe) => `<!doctype html><html><body><canvas width="64" height="64"></canvas><script>var t=0;setInterval(function(){t+=20;window.__preview=Object.assign({tick:t},${JSON.stringify(probe)});},100);</script></body></html>`;
    const site = (name, probe) => { const d = join(tmp, name); mkdirSync(d, { recursive: true }); writeFileSync(join(d, 'index.html'), page(probe)); return d; };
    const good = await smoke({ dir: site('good', { planetGen: 2, fine: 4800, dataGen: 2, planet: true, biome: true, water: true, surface: true, floor: true, interrupts: true, turn: true, turns: 0, rightStick: true, meteor: true, errors: [], hp: [100, 100] }), on: IDS, timeoutS: 90, session: 'tools-preview-selftest', exe });
    check('the smoke check passes a page that reads as asked', good.ok === true, JSON.stringify(good.problems));
    const wrong = await smoke({ dir: site('wrong', { planetGen: 2, fine: 4800, dataGen: 2, planet: true, biome: true, water: false, surface: true, floor: true, interrupts: true, errors: [], hp: [100, 100] }), on: IDS, timeoutS: 90, session: 'tools-preview-selftest', exe });
    check('it fails a page whose water reads off, and names water', wrong.ok === false && wrong.problems.some((p) => p.sw === 'water'), JSON.stringify(wrong.problems));
    const offOk = await smoke({ dir: site('off', { planetGen: 1, fine: 0, dataGen: 1, planet: true, biome: false, water: false, surface: false, floor: false, interrupts: false, turn: false, turns: -1, errors: [], hp: [100, 100] }), on: [], timeoutS: 90, session: 'tools-preview-selftest', exe });
    check('it passes a plain build\'s page when everything is asked off', offOk.ok === true, JSON.stringify(offOk.problems));
    const noProbe = await smoke({ dir: (() => { const d = join(tmp, 'blank'); mkdirSync(d, { recursive: true }); writeFileSync(join(d, 'index.html'), '<html><body><canvas></canvas></body></html>'); return d; })(), on: IDS, timeoutS: 8, session: 'tools-preview-selftest', exe });
    check('it fails a page that never publishes its state', noProbe.ok === false && /did not boot/.test(noProbe.problems[0].text), JSON.stringify(noProbe.problems));
  }
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
console.log(failed ? `preview self-test FAILED: ${failed} of ${ran} checks` : `preview self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

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
import { SWITCHES, IDS, locate, flip, resolve, errorSwitch, patchMain, tableWith, loadPending, planetFunc, present } from './switches.mjs';
import { expectations, probeProblems } from './smoke.mjs';
import { browserExe } from '../machine/browser.mjs';

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
check('by default every switch is on', R().active.join() === IDS.join() && R().cascaded.length === 0);
check('--off floor turns off only the floor', R('floor').active.join() === IDS.filter((i) => i !== 'floor').join());
check('--off surface turns the floor off with it, and says why', R('surface').active.includes('floor') === false && R('surface').cascaded[0].id === 'floor' && R('surface').cascaded[0].because.join() === 'surface');
check('--off interrupts turns the floor off with it', !R('interrupts').active.includes('floor') && R('interrupts').active.includes('surface'));
check('--off gen2 turns nothing else off', R('gen2').cascaded.length === 0 && R('gen2').active.length === IDS.length - 1);
check('swing (DirSwing) is a data flag of data/director/swing.json `enabled`, waits for the file and needs gen3; the top-level key is the one flipped, not the nested ones', (() => { const s = SWITCHES.find((x) => x.id === 'swing'); if (!s || s.file !== 'data/director/swing.json' || s.path.join() !== 'enabled' || !s.optional || s.needs.join() !== 'gen3') return false; const T = '{\n  "enabled": false,\n  "kinds": {\n    "launch": {\n      "enabled": true\n    }\n  },\n  "other": {\n    "enabled": false\n  }\n}\n'; const f = flip(T, s); return f.text === T.replace('"enabled": false,\n  "kinds"', '"enabled": true,\n  "kinds"'); })());
check('--off with a comma list and --off all', R('water,biome').active.join() === 'gen2,surface,interrupts,floor,calmTurn,turn,rightStick,gen3,meteor,tiles,swing' && R('all').active.length === 0);
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
    check('with the work overlaid the switch is on, needs the host patch (main.gd has not got it) and brings its probe field', p1.active.includes('rightStick') && p1.hostPatch === hostText && p1.probes.length === 1 && /right_stick_on/.test(p1.probes[0]) && !p1.waiting.some((w) => w.id === 'rightStick'), JSON.stringify(p1));
    check('the overlay is read from the working tree and the commit is not: without it the same switch waits', !plan(repo, sha, { pending: pend.rows }).active.includes('rightStick'));
    work('data/input/timing.json', JSON.stringify({ switches: { rightStick: false } }, null, 2) + '\n');
    const noPatch = plan(repo, sha, { overlay: ['data/input', 'sim/input'], pending: pend.rows });
    check('the pad\'s right stick unread and no host patch in the tree: the switch WAITS and says so, it is not turned on half-built', !noPatch.active.includes('rightStick') && noPatch.waiting.some((w) => w.id === 'rightStick' && /right-hand-host\.patch is not in it/.test(w.why)), JSON.stringify(noPatch.waiting));
    writeFileSync(join(repo, 'render/core/main.gd'), mainBase.replace(/\s*$/, '\n') + 'var _pad_stick_right: Dictionary = {}\n');
    const landed = plan(repo, sha, { overlay: ['data/input', 'sim/input', 'render/core/main.gd'], pending: pend.rows });
    check('a main.gd that already reads the right stick needs no patch', landed.active.includes('rightStick') && landed.hostPatch === null);
    git(repo, 'checkout', 'render/core/main.gd');
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
    check('a gen 3 probe reads 3 or the data\'s 2, and a field world may have no fine-biome columns: asked for, neither is a failure', probeProblems({ ...okProbe, planetGen: 3, fine: 0 }, expectations(IDS)).length === 0 && probeProblems({ ...okProbe, planetGen: 1, fine: 0 }, expectations(IDS)).some((p) => /planetGen reads 1, expected at least 2/.test(p.text)));
    const gb = await buildPreview({ ...opts, overlay: ['sim/world'], rebuild: true, pending: pend });
    const gs = JSON.parse(readFileSync(join(gb.web, 'seen.json'), 'utf8'));
    check('a build with World\'s code overlaid puts planetGen 3 in the scratch planet entry, and flips no file for it', gb.active.includes('gen3') && gs.pg3 === true && !gb.flips.some((x) => x.id === 'gen3'), JSON.stringify([gb.active, gs.pg3]));
    const gn = await buildPreview({ ...opts, rebuild: true, pending: pend });
    check('without it the entry has no setup key', JSON.parse(readFileSync(join(gn.web, 'seen.json'), 'utf8')).pg3 === false);

    // meteor: a constant in a script, flipped by its text
    const LOOK = 'const METEOR_DEFAULT: bool = false          # the meteor trail: off until Orb has seen it\nconst OTHER: bool = false\n';
    check('meteor is a constant switch: a text to replace, the file it waits for, a probe field', sw('meteor').replace.from === 'const METEOR_DEFAULT: bool = false' && sw('meteor').replace.to === 'const METEOR_DEFAULT: bool = true' && sw('meteor').file === 'render/vfx/vfx_look.gd' && sw('meteor').optional === true && /meteor_enabled/.test(sw('meteor').probe));
    const mf = flip(LOOK, sw('meteor'));
    check('its text is replaced once, the comment and the rest of the file untouched; on already is no change', mf.text === LOOK.replace('bool = false          #', 'bool = true          #') && mf.was === 'const METEOR_DEFAULT: bool = false' && flip(mf.text, sw('meteor')).text === mf.text && present(LOOK, sw('meteor')) && present(mf.text, sw('meteor')) && !present('nothing here', sw('meteor')));
    const mbad = (s) => { try { flip(s, sw('meteor')); return ''; } catch (e) { return e.message; } };
    check('the text twice, or neither, is refused and says the table is out of date', /there 2 times/.test(mbad(LOOK + LOOK)) && /there 0 times/.test(mbad('nothing')));
    const m0 = plan(repo, sha, { pending: pend.rows });
    check('without VFX\'s code the meteor switch WAITS and says so', !m0.active.includes('meteor') && m0.waiting.some((w) => w.id === 'meteor' && /not in this tree yet/.test(w.why)), JSON.stringify(m0.waiting));
    work('render/vfx/vfx_look.gd', LOOK);
    work('render/vfx/vfx_hub.gd', 'var meteor_enabled: bool = VfxLook.METEOR_DEFAULT\n');
    const m1 = plan(repo, sha, { overlay: ['render/vfx'], pending: pend.rows });
    check('with the files in the tree it is on, and its probe field comes with it (the hub has the field)', m1.active.includes('meteor') && m1.probes.some((p) => /meteor_enabled/.test(p)), JSON.stringify(m1));
    work('render/vfx/vfx_hub.gd', 'nothing about the meteor here\n');
    check('the probe field is added only when the hub has the field it reads', !plan(repo, sha, { overlay: ['render/vfx'], pending: pend.rows }).probes.some((p) => /meteor_enabled/.test(p)));
    work('render/vfx/vfx_hub.gd', 'var meteor_enabled: bool = VfxLook.METEOR_DEFAULT\n');
    check('a meteor expectation reads the probe: asked on, off in the game is named', probeProblems({ ...okProbe, meteor: false }, expectations(IDS)).some((p) => p.sw === 'meteor') && probeProblems({ ...okProbe, meteor: true }, expectations(IDS)).length === 0 && errorSwitch('meteor.gd:12 bad') === 'meteor');
    const mb = await buildPreview({ ...opts, overlay: ['render/vfx'], rebuild: true, pending: pend });
    check('a build with VFX\'s code overlaid flips the constant in the scratch copy and records it as a flip of text', mb.active.includes('meteor') && mb.flips.some((x) => x.id === 'meteor' && x.key === 'text' && /bool = true/.test(x.now)), JSON.stringify(mb.flips.filter((x) => x.id === 'meteor')));

    // tiles: a page word, present when Rendering's tile ground is in the tree, needs gen3
    check('tiles is a page word, not a data flag: no file, the word, the command-line form, the file it waits for, and it needs gen3', sw('tiles').url === 'tiles=1' && sw('tiles').cmd === '--tiles' && sw('tiles').file === undefined && sw('tiles').presentIf.file === 'render/core/tile_ground.gd' && sw('tiles').needs.join() === 'gen3' && sw('tiles').optional === true);
    work('render/core/tile_ground.gd', 'extends RefCounted\n');
    const t0 = plan(repo, sha, { overlay: ['render/core'], pending: pend.rows });
    check('the tile ground in the tree without World\'s code: tiles WAITS because gen3 does (what waits turns off what needs it), and no word is printed', !t0.active.includes('tiles') && t0.waiting.some((w) => w.id === 'tiles' && /needs gen3/.test(w.why)) && t0.urlWords.length === 0, JSON.stringify(t0.waiting));
    const t1 = plan(repo, sha, { overlay: ['render/core', 'sim/world'], pending: pend.rows });
    check('with both in the tree tiles is on and the word is carried on the address', t1.active.includes('tiles') && t1.urlWords.join() === 'tiles=1' && t1.setup.planetGen === 3, JSON.stringify(t1));
    check('--off tiles leaves no word', plan(repo, sha, { overlay: ['render/core', 'sim/world'], off: ['tiles'], pending: pend.rows }).urlWords.length === 0);
    check('the scratch main.gd\'s URL list is edited at the START of the list, so the tile park\'s own words first do not break the anchor', (() => { const m = MAIN.replace('const URL_ARGS: Array = ["nointro", ', 'const URL_ARGS: Array = ["tiles", "tilerate", "nointro", '); return patchMain(m).includes('const URL_ARGS: Array = ["planet", "touch", "preview", "tiles", "tilerate", "nointro", ') && patchMain(MAIN).includes('const URL_ARGS: Array = ["planet", "touch", "preview", "nointro", '); })());
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

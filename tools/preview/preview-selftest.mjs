// Self-test of tools/preview (the private preview build, docs/tools/preview.md): the switch edits on fixture files, the cascade, the scratch patch, the whole build against a throwaway git
// repository with a stand-in for Godot (the repository's files must come out untouched, the build's tree flipped and patched), the local server, and, with a browser, the smoke check on a tiny page.
// No Godot. CI runs it; --require-browser makes a missing browser a failure.
//   node tools/preview/preview-selftest.mjs [--require-browser]
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { request } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { buildPreview, buildKey, serveLocal, checkTree } from './preview.mjs';
import { SWITCHES, IDS, locate, flip, resolve, errorSwitch, patchMain } from './switches.mjs';
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
const INTERRUPTS = JSON.stringify({ enabled: true, a: { enabled: true }, water: { enabled: false, surfaceTicks: 30, _note: 'water.enabled false' }, rally: { enabled: false } }, null, 2);
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
check('flip leaves the other enabled keys alone (interrupts.json)', (() => { const j = JSON.parse(flip(INTERRUPTS, sw('interrupts')).text); return j.enabled === true && j.a.enabled === true && j.rally.enabled === false && j.water.enabled === true; })());
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
check('--off with a comma list and --off all', R('water,biome').active.join() === 'gen2,surface,interrupts,floor,turn' && R('all').active.length === 0);
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
const okProbe = { tick: 900, fine: 4800, planetGen: 2, planet: true, dataGen: 2, biome: true, water: true, surface: true, floor: true, interrupts: true, turn: true, turns: 0, errors: [], hp: [90, 80] };
check('a probe that matches passes', probeProblems(okProbe, expectations(IDS)).length === 0);
check('a switch that reads off in the running game is named', probeProblems({ ...okProbe, water: false }, expectations(IDS)).map((p) => p.sw).join() === 'water');
check('a gen 2 planet with no fine-biome columns is named',probeProblems({ ...okProbe, fine: 0 }, expectations(IDS)).some((p) => p.sw === 'gen2'));
check('gen 2 not in force is named', probeProblems({ ...okProbe, planetGen: 1 }, expectations(IDS)).some((p) => p.sw === 'gen2'));
check('with a switch off the probe must read it off', probeProblems({ ...okProbe, floor: true }, expectations(IDS.filter((i) => i !== 'floor'))).map((p) => p.sw).join() === 'floor');
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
    "  const seen = { gen: j('data/biomes/climate.json').gen, water: j('data/biomes/water.json').enabled, floor: j('data/biomes/water.json').floor.enabled, surface: j('data/biomes/water.json').surface.enabled, biome: j('data/combat/launch_biome.json').biome.enabled, interrupts: j('data/director/interrupts.json').water.enabled, turn: j('data/biomes/rings.json').turn.on, patched: /_preview_probe/.test(readFileSync(join(tree, 'render/core/main.gd'), 'utf8')), buildInfo: j('build_info.json'), args: a };",
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
  check('it recorded the seven flips', b.flips.length === 7 && b.flips.every((f) => !f.alreadyOn));
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
    const good = await smoke({ dir: site('good', { planetGen: 2, fine: 4800, dataGen: 2, planet: true, biome: true, water: true, surface: true, floor: true, interrupts: true, turn: true, turns: 0, errors: [], hp: [100, 100] }), on: IDS, timeoutS: 90, session: 'tools-preview-selftest', exe });
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

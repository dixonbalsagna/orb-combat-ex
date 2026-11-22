// Self-test of tools/lint-determinism.mjs: every kind of engine use is found, our own wrappers, comments, strings and definitions are not, and the waiver works.
//   node tools/lint-determinism-selftest.mjs
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { lintTree, loadAllow, scan } from './lint-determinism.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const found = (src) => scan(src).map((f) => f.rule);
const hits = (src, rule) => found(src).filter((r) => r === rule).length;

// found
for (const [src, rule] of [
  ['var a = sin(x)', 'engine-trig'], ['var a = cos(x) * 2', 'engine-trig'], ['return tan(x)', 'engine-trig'], ['var a = asin(x)', 'engine-trig'], ['var a = acos(x)', 'engine-trig'],
  ['var a = atan(x)', 'engine-trig'], ['var a = atan2(y, x)', 'engine-trig'], ['var r = deg_to_rad(d)', 'engine-trig'], ['var d = rad_to_deg(r)', 'engine-trig'], ['var a = sin (x)', 'engine-trig'],
  ['var a = float(d) * PI / 180.0', 'engine-pi'], ['return r - TAU * floorf(r)', 'engine-pi'], ['x = -PI', 'engine-pi'], ['y = 2.0*PI', 'engine-pi'],
  ['var r = randf()', 'engine-random'], ['var r = randi() % 4', 'engine-random'], ['var r = randf_range(0, 1)', 'engine-random'], ['randomize()', 'engine-random'], ['list.shuffle()', 'engine-random'],
  ['var x = list.pick_random()', 'engine-random'], ['var g = RandomNumberGenerator.new()', 'engine-random'],
  ['var t = Time.get_ticks_msec()', 'engine-clock'], ['var t = OS.get_ticks_msec()', 'engine-clock'], ['var t = OS.get_unix_time()', 'engine-clock'], ['var n = Engine.get_frames_drawn()', 'engine-clock'],
  ['var v = d.rotated(0.5)', 'engine-vector-trig'], ['var a = d.angle()', 'engine-vector-trig'], ['var a = lerp_angle(a, b, t)', 'engine-vector-trig'],
  ['func f(x): return sin(x)', 'engine-trig'],
]) check(`found: ${src}`, hits(src, rule) === 1, found(src).join(','));

// not found
for (const src of [
  'var a = SimDetMath.sin(x)', 'var a = SimDetMath.cos(x) + SimDetMath.atan2(y, x)', 'var p = SimMathx.PI', 'var r = rng.randf()', 'var r = SimRng.keyed(seed, "k", 3)', 'var a = WorldPlanet.acosf(x)', 'var a = asinf(x)',
  'var a = atanf(y / x)', 'var t = _PI * 2.0', 'var pi = 3', 'var spin = 1', 'var cost = 2', 'var tanned = 1', 'var randfoo = 1', 'var mess = "no sin( here, nor PI, nor randf()"', "var m = 'cos(x) and Time.get_ticks_msec()'",
  '# sin(x) PI randf() Time.now', 'var a = 1   # was sin(x) once', 'static func sin(x: float) -> float:', 'func cos(x) -> float:', 'func tan(x):', 'static func atan2(y: float, x: float) -> float:',
  'var timer = 0', 'var t = tick * DT', 'var a = d.length()', 'var ti = Mathx.PI', 'var x = self.sin_table[3]',
]) check(`not found: ${src}`, found(src).length === 0, found(src).join(','));

// the printf rule (Simulation, 2026-11-22: Windows printf rounds an exact half away from zero, Linux and the web to even)
for (const src of ['var s = "%.1f" % x', 'return "%+.2f %s" % [v, s]', 'var s = "%5.2f" % v', 'var p = "%.0f%%" % pct', "var s = '%.3f' % v", '_err("shares sum to %.3f, not 1" % share)']) check(`found: ${src}`, hits(src, 'sim-text-float') === 1, found(src).join(','));
for (const src of ['var s = SimMathx.fixed(v, 1)', 'var s = "%d" % n', 'var s = "%s and %s" % [a, b]', 'var s = "%05d" % n', 'var s = "%+d" % n', 'var c = x % 3', 'var c = x %3', 'var p = "50%"', '# "%.1f" % x', 'var a = 1   # was "%.2f" % x', 'static func f(v):']) check(`not found: ${src}`, hits(src, 'sim-text-float') === 0, found(src).join(','));
check('a det-ok waiver passes the printf rule too', hits('var s = "%.1f" % x   # det-ok: debug text, never hashed', 'sim-text-float') === 0);
check('the finding says what to use', scan('var s = "%.1f" % x')[0].use === 'SimMathx.fixed(v, n)');

// a string with an escaped quote does not leak its tail
check('an escaped quote does not end a string early', found('var m = "say \\"sin(x)\\" now"').length === 0);

// waivers
check('a det-ok waiver on the line passes', found('var a = sin(x)   # det-ok: debug label only, never hashed').length === 0);
check('a det-ok waiver on the line above passes', found('# det-ok: the picture only\nvar a = sin(x)').length === 0);
check('a det-ok waiver two lines above does not', found('# det-ok: far\n\nvar a = sin(x)').length === 1);
check('a det-ok waiver without a reason is a finding', hits('var a = 1   # det-ok:', 'waiver-reason') === 1);
check('a det-ok without a reason does not waive', hits('var a = sin(x)   # det-ok:', 'engine-trig') === 1);
check('findings carry the line number', scan('var a = 1\nvar b = 2\nvar c = sin(a)')[0].line === 3);

// the tree: scanned folders, skipped folders, the allow list
const root = mkdtempSync(join(tmpdir(), 'detlint-'));
try {
  const put = (rel, text) => { const p = join(root, rel); mkdirSync(join(p, '..'), { recursive: true }); writeFileSync(p, text); };
  put('sim/core/a.gd', 'var a = sin(x)\n');
  put('sim/director/b.gd', 'var a = SimDetMath.sin(x)\n');
  put('sim/world/c.gd', 'var a = PI\n');
  put('sim/input/d.gd', 'var t = Time.get_ticks_msec()\n');
  put('sim/core/tools/e.gd', 'var a = sin(x)\n');
  put('sim/world/test/f.gd', 'var a = cos(x)\n');
  put('render/g.gd', 'var a = sin(x)\n');
  const all = lintTree(root);
  check('the four sim folders are scanned (core, world, input; director is clean)', all.map((f) => f.file).join(',') === 'sim/core/a.gd,sim/world/c.gd,sim/input/d.gd', all.map((f) => f.file).join(','));
  check('tools/ and test/ folders and render/ are not scanned by default', !all.some((f) => /tools|test|render/.test(f.file)));
  check('--all scans tools/ and test/ too', lintTree(root, { all: true }).length === 5);
  check('an allowed file is skipped', lintTree(root, { allow: [{ path: 'sim/core/a.gd', why: 'x' }] }).length === 2);
} finally { rmSync(root, { recursive: true, force: true }); }

// the allow list: an entry may name one rule (a list for an owner to clear), and a rule that does not exist is refused
const root2 = mkdtempSync(join(tmpdir(), 'detlint2-'));
try {
  const p = join(root2, 'sim/core/h.gd'); mkdirSync(join(p, '..'), { recursive: true }); writeFileSync(p, 'var s = "%.2f" % v\nvar a = sin(x)\n');
  const rules = (allow) => lintTree(root2, { allow }).map((f) => f.rule).sort().join(',');
  check('both findings without an allow entry', rules([]) === 'engine-trig,sim-text-float', rules([]));
  check('a rule-scoped entry allows that rule in that file and nothing else', rules([{ path: 'sim/core/h.gd', rule: 'sim-text-float', why: 'x' }]) === 'engine-trig', rules([{ path: 'sim/core/h.gd', rule: 'sim-text-float', why: 'x' }]));
  check('an entry for another rule allows neither', rules([{ path: 'sim/core/h.gd', rule: 'engine-pi', why: 'x' }]) === 'engine-trig,sim-text-float');
  check('an entry for another file allows nothing here', rules([{ path: 'sim/core/z.gd', rule: 'sim-text-float', why: 'x' }]) === 'engine-trig,sim-text-float');
  check('an entry with no rule still allows the whole file', rules([{ path: 'sim/core/h.gd', why: 'x' }]) === '');
  const af = join(root2, 'allow.json');
  writeFileSync(af, JSON.stringify({ files: [{ path: 'sim/core/h.gd', rule: 'sim-text-floot', why: 'x' }] }));
  let refused = false; try { loadAllow(af); } catch (e) { refused = /does not exist: sim-text-floot/.test(e.message); }
  check('an allow entry naming a rule that does not exist is refused', refused);
  writeFileSync(af, JSON.stringify({ files: [{ path: 'sim/core/h.gd', rule: 'sim-text-float', why: 'x' }] }));
  check('an allow entry naming a real rule is read', loadAllow(af).length === 1);
} finally { rmSync(root2, { recursive: true, force: true }); }

if (failed) { console.error(`determinism lint self-test FAILED: ${failed} of ${ran} checks`); process.exit(1); }
console.log(`determinism lint self-test ok: ${ran} checks`);

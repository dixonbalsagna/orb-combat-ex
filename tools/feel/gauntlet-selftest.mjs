// Self-test of the scheme gauntlet (docs/tools/feel.md): the parsers and the reading (no Godot), then on the kept build orb-first-play-10d8b8cf-68ee07cc, headless Godot, one match a cell:
//   - every arm (stick-only, masher, timing, beam-first, circle-first) plays a match through the hub and reports presses;
//   - the same seeds under a scheme equal to the shipped value give exactly the shipped result (the comparison is paired and deterministic);
//   - a scheme that changes a rule changes the result, so the scheme really reached the tree the match ran on.
// Skips the Godot part, saying so, when the kept build is not on this PC (it is git-ignored) or with --no-e2e.   node tools/feel/gauntlet-selftest.mjs [--no-e2e]
import { existsSync, writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { ROOT, OutputKeeper, runGd, godotExe } from './lib.mjs';
import { parseScheme, schemesFromFile, wilson, readCell, table, gauntlet, ARMS } from './gauntlet.mjs';

let fails = 0;
const ok = (c, m) => { console.log(`${c ? 'ok  ' : 'FAIL'} ${m}`); if (!c) fails++; };

const s = parseScheme('hand=data/input/timing.json:switches.signatureRtOnly=false;data/director/interrupts.json:brawl.heldPressTicks=4');
ok(s.name === 'hand' && s.overrides.length === 2 && s.overrides[1].value === 4 && s.overrides[0].value === false, 'a scheme parses: a name and its overrides');
ok(parseScheme('shipped=').overrides.length === 0, 'a scheme with no override is the shipped one');
let bad = false; try { parseScheme('nonsense'); } catch { bad = true; }
ok(bad, 'a malformed scheme is refused');
const d = mkdtempSync(join(tmpdir(), 'meridian-gt-'));
try {
  writeFileSync(join(d, 's.json'), JSON.stringify({ a: [{ file: 'x.json', path: 'k.v', value: 1 }], b: { 'y.json:p.q': 2 } }));
  const fs_ = schemesFromFile(join(d, 's.json'));
  ok(fs_.length === 2 && fs_[0].overrides[0].path.join('.') === 'k.v' && fs_[1].overrides[0].file === 'y.json' && fs_[1].overrides[0].value === 2, 'a schemes file reads both of its shapes');
} finally { rmSync(d, { recursive: true, force: true }); }
ok(wilson(5, 10) >= 25 && wilson(5, 10) <= 35 && wilson(0, 0) === 0, 'the interval says how little ten matches can say (about +/-31 points at 50%)');
const c = readCell({ done: 10, won: 4, lost: 6, draws: 0, timeouts: 0, capped: 0, presses: 200, refused: 30, noControl: 7200, ticks: 36000, beams: 5, medianSec: 60, refusedBy: { 'stick/late': 20, 'press_refused/x': 10 } });
ok(c.winPct === 40 && c.refusalsPer100 === 15 && c.noControlPerMin === 12 && c.beamsPerMatch === 0.5 && /stick\/late 20/.test(c.topRefusal), 'a cell is read as win percent, refusals per 100 presses, seconds without control a minute and beams a match');
const t = table({ 'shipped|stick|easy': c, 'rh|stick|easy': { ...c, winPct: 50, refusalsPer100: 5 } }, ['shipped', 'rh'], ['stick'], ['easy']);
ok(/stick-only\s+easy/.test(t) && /\(-10\)/.test(t) && /\(\+10\)/.test(t), 'the table puts a scheme next to the shipped one with the change');
ok(ARMS.join() === 'stick,masher,timing,beam,circle', 'the five arms are named');

// 2026-11-14: the output of a run is kept in bounds, and a run that prints script errors stops at the first (the heap out-of-memory of 9 November: about 22 MB of one repeated error for 16 minutes)
{
  const k = new OutputKeeper();
  const line = 'SCRIPT ERROR: Parse Error: Could not find type "Brawl" in the current scope.' + String.fromCharCode(10);
  const big = Buffer.from(line.repeat(20000));
  let first = null, firstAt = -1;
  for (let i = 0; i < 200; i++) { const e = k.push(big); if (e && first === null) { first = e; firstAt = i; } }   // about 300 MB offered in 1.5 MB chunks
  k.push('FEEL {"ok":1}' + String.fromCharCode(10));
  ok(k.bytes > 290e6 && k.head.length <= 16 * 1024 && k.tail.length <= 64 * 1024 && k.text().length < 200 * 1024, `300 MB of one error is kept in bounds (text ${k.text().length} bytes of ${k.bytes})`);
  ok(first !== null && firstAt === 0 && /Could not find type "Brawl"/.test(first), 'the first script error is named, in the first chunk that carried it');
  ok(k.line('FEEL ') === 'FEEL {"ok":1}' && /FEEL \{"ok":1\}/.test(k.text()), 'the result line survives a flood (kept apart from the tail)');
  ok(/most repeated script errors:/.test(k.text()) && /300000 x SCRIPT ERROR|\d+ x SCRIPT ERROR/.test(k.text()), 'the text says how often the most repeated error came');
  const small = new OutputKeeper(); small.push('hello' + String.fromCharCode(10) + 'GAUNTLET {}' + String.fromCharCode(10));
  ok(small.text().includes('GAUNTLET {}') && small.firstError === null, 'a short quiet run is returned whole, with no error named');
  const split = new OutputKeeper(); split.push('SCRIPT ERR'); const e2 = split.push('OR: x' + String.fromCharCode(10));
  ok(e2 === 'SCRIPT ERROR: x', 'an error line split across two chunks is still found');
  // the real thing: godot on a scratch project whose script floods script errors; runGd must stop it at the first
  let godot = null; try { godot = godotExe(); } catch { /* none here */ }
  if (godot && !process.argv.includes('--no-e2e')) {
    const dd = mkdtempSync(join(tmpdir(), 'meridian-gt-flood-'));
    try {
      writeFileSync(join(dd, 'project.godot'), 'config_version=5' + String.fromCharCode(10) + '[application]' + String.fromCharCode(10) + 'config/name="flood"' + String.fromCharCode(10));
      writeFileSync(join(dd, 'flood.gd'), 'extends SceneTree' + String.fromCharCode(10) + 'func _initialize() -> void:' + String.fromCharCode(10) + '\tfor i in range(200000):' + String.fromCharCode(10) + '\t\tcall("no_such_function_here")' + String.fromCharCode(10) + '\tprint("FEEL {}")' + String.fromCharCode(10) + '\tquit()' + String.fromCharCode(10));
      const t0 = Date.now();
      const r = await runGd(dd, [], { godot, limitMs: 60000, script: join(dd, 'flood.gd') });
      ok(r.killedOn !== null && r.bytes < 5e6 && Date.now() - t0 < 30000, `runGd stopped a run at its first script error, by its own PID (${r.bytes} bytes printed, ${Date.now() - t0} ms): ${String(r.killedOn).slice(0, 80)}`);
      const r2 = await runGd(dd, [], { godot, limitMs: 8000, script: join(dd, 'flood.gd'), failFast: false });
      ok(r2.killedOn === null && r2.text.length < 200 * 1024 && /SCRIPT ERROR/.test(r2.text), `with failFast off the same run (Godot hangs after a script error until the time limit) is stopped by the limit and its output kept (text ${r2.text.length} bytes)`);
    } finally { rmSync(dd, { recursive: true, force: true }); }
  } else console.log('skip the flood run (no Godot here, or --no-e2e)');
}

const kept = join(ROOT, 'homework', 'Files', 'builds', 'orb-first-play-10d8b8cf-68ee07cc', 'tree');
if (process.argv.includes('--no-e2e')) console.log('skip the Godot checks (--no-e2e)');
else if (!existsSync(join(kept, 'project.godot'))) console.log('skip the Godot checks: the kept build is not on this PC (homework/ is git-ignored)');
else {
  const schemes = [
    parseScheme('same=data/director/interrupts.json:brawl.heldPressTicks=10'),
    parseScheme('changed=data/director/interrupts.json:brawl.heldPressTicks=0;data/director/interrupts.json:press.enabled=false'),
  ];
  const r = await gauntlet({ tree: kept, schemes, arms: ARMS, levels: ['easy'], n: 1, seed: 3, jobs: 3 });
  ok(r.failed.length === 0, `every cell ran (${Object.keys(r.cells).length} of ${(schemes.length + 1) * ARMS.length}${r.failed.length ? '; failed: ' + r.failed.map((f) => f.s + '/' + f.a + ': ' + f.why).join(' | ') : ''})`);
  ok(ARMS.every((a) => r.raw[`shipped|${a}|easy`] && r.raw[`shipped|${a}|easy`].presses > 20 && r.raw[`shipped|${a}|easy`].done === 1), 'every arm played a match and made presses on the hub');
  ok(ARMS.every((a) => JSON.stringify(r.raw[`shipped|${a}|easy`]) === JSON.stringify(r.raw[`same|${a}|easy`])), 'a scheme equal to the shipped value gives exactly the shipped result, arm by arm (paired seeds)');
  ok(ARMS.some((a) => JSON.stringify(r.raw[`shipped|${a}|easy`]) !== JSON.stringify(r.raw[`changed|${a}|easy`])), 'a scheme that changes a rule changes at least one arm result (the override reached the tree)');
  ok(r.raw['shipped|beam|easy'].beams >= 0 && r.raw['shipped|timing|easy'].refusedBy !== undefined, 'the beam and timing arms report beams and refusals by reason');
}
console.log(fails ? `gauntlet self-test FAILED: ${fails} check(s)` : 'gauntlet self-test ok');
process.exit(fails ? 1 : 0);

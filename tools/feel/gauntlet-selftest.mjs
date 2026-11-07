// Self-test of the scheme gauntlet (docs/tools/feel.md): the parsers and the reading (no Godot), then on the kept build orb-first-play-10d8b8cf-68ee07cc, headless Godot, one match a cell:
//   - every arm (stick-only, masher, timing, beam-first, circle-first) plays a match through the hub and reports presses;
//   - the same seeds under a scheme equal to the shipped value give exactly the shipped result (the comparison is paired and deterministic);
//   - a scheme that changes a rule changes the result, so the scheme really reached the tree the match ran on.
// Skips the Godot part, saying so, when the kept build is not on this PC (it is git-ignored) or with --no-e2e.   node tools/feel/gauntlet-selftest.mjs [--no-e2e]
import { existsSync, writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { ROOT } from './lib.mjs';
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

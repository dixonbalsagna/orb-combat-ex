// Self-test of the feel replays and the refusal ledger (docs/tools/feel.md): the parsers and tables (no Godot), then on the kept build orb-first-play-10d8b8cf-68ee07cc, headless Godot, one match of Orb's:
//   - the baseline REPRODUCES the saved final hash with forks taken (so a snapshot restore leaves the real timeline alone);
//   - a rule that equals the shipped value changes nothing, in the forks or the whole match;
//   - a real rule (brawl.heldPressTicks 0) changes the whole match;
//   - the ledger lists presses, its verdict counts add up and every refused row has a reason.
// Skips the Godot part, saying so, when the kept build or the match files are not on this PC (they are git-ignored) or with --no-e2e.   node tools/feel/feel-selftest.mjs [--no-e2e]
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { ROOT, parseOverride, parseSwitch, overridesFromFile, SUPPORTED_FILES, keptTreeOf, readMatch } from './lib.mjs';
import { table, pressChanges, feelReplay, report } from './feel.mjs';
import { ledger, summarise, text, mmss } from './ledger.mjs';

let fails = 0;
const ok = (c, m) => { console.log(`${c ? 'ok  ' : 'FAIL'} ${m}`); if (!c) fails++; };

const o1 = parseOverride('data/input/timing.json:switches.quickRead=false');
ok(o1.file === 'data/input/timing.json' && o1.path.join('.') === 'switches.quickRead' && o1.value === false, 'an override parses (file, dotted path, JSON value)');
ok(parseOverride('data/director/interrupts.json:brawl.heldPressTicks=4').value === 4 && parseOverride('x.json:a.b=text').value === 'text', 'a number and a plain word parse');
const sw = parseSwitch('signatureRtOnly');
ok(sw.file === 'data/input/timing.json' && sw.path.join('.') === 'switches.signatureRtOnly' && sw.value === true, 'a switch is an override of timing.json switches (true when no value)');
let bad = false; try { parseOverride('nonsense'); } catch { bad = true; }
ok(bad, 'a malformed override is refused');
ok(SUPPORTED_FILES.includes('data/input/timing.json') && SUPPORTED_FILES.includes('data/director/interrupts.json'), 'the two forkable files are named');
const t = table('T', { beams: 1, refused: 3, 'refused:stick/taken': 3, noControl: 120 }, { beams: 3, refused: 1, 'refused:stick/taken': 1, noControl: 60 });
ok(/beams fired\s+1\s+3\s+\+2/.test(t) && /seconds without control\s+2\s+1\s+-1/.test(t) && /stick\/taken\s+3\s+1\s+-2/.test(t), 'the before/after table shows beams, seconds without control (ticks / 60) and reasons');
const pc = pressChanges([{ base: { refused: 1 }, cand: { beams: 1 } }, { base: { beams: 1 }, cand: { refused: 1 } }, { base: {}, cand: {} }]);
ok(pc.refusedToFired === 1 && pc.firedToRefused === 1 && pc.presses === 3, 'press changes count refused to fired and fired to refused');
ok(mmss(3700) === '1:01.7', 'the ledger time reads minutes and seconds');
const fake = { presses: [{ t: 1, press: 'sig', verdict: 'refused', reasons: ['press_stunned/b'] }, { t: 2, press: 'sig', verdict: 'honoured', reasons: [] }, { t: 3, press: 'dodge', verdict: 'silent', reasons: [] }], match: 'm', tree: 't', ticks: 60, recorded: { checked: false } };
const sm = summarise(fake);
ok(sm.total === 3 && sm.notHonoured === 2 && sm.byPress.sig.refused === 1 && sm.byReason['press_stunned/b'] === 1, 'the ledger counts by press and reason');
ok(/not honoured \(67%\)/.test(text(fake)) && /no answer at all/.test(text(fake)), 'the ledger text names the share and the silent presses');

const kept = join(ROOT, 'homework', 'Files', 'builds', 'orb-first-play-10d8b8cf-68ee07cc', 'tree');
const m1956 = join(ROOT, 'homework', 'Files', 'orb-first-play-20261106-1934.json');   // a match that reproduces exactly on its kept tree
const m0352 = join(ROOT, 'homework', 'Files', 'orb-first-play-20261102-0352.json');
if (process.argv.includes('--no-e2e')) console.log('skip the Godot checks (--no-e2e)');
else if (!existsSync(join(kept, 'project.godot')) || !existsSync(m1956) || !existsSync(m0352)) console.log('skip the Godot checks: the kept build or the saved matches are not on this PC (homework/ is git-ignored)');
else {
  ok(keptTreeOf(readMatch(m1956).doc) === kept || keptTreeOf(readMatch(m1956).doc).replace(/\\/g, '/') === kept.replace(/\\/g, '/'), 'the match file names its kept tree');
  const none = await feelReplay({ match: m1956, overrides: [parseOverride('data/director/interrupts.json:brawl.heldPressTicks=10')], maxForks: 6 });
  ok(none.recorded.checked && none.recorded.exact, 'the baseline reproduces the saved final hash, with forks taken (snapshot restore leaves the timeline alone)');
  ok(none.forks.count >= 3, `forks were taken (${none.forks.count})`);
  ok(JSON.stringify(Object.entries(none.forks.baseline).sort()) === JSON.stringify(Object.entries(none.forks.candidate).sort()), 'a rule equal to the shipped value changes nothing in the forks');
  ok(none.candidateFinal === none.recorded.got, 'and nothing in the whole match (the final state is identical)');
  ok(/NOTHING CHANGED/.test(report(none)), 'the report says so when nothing changed');
  const real = await feelReplay({ match: m0352, overrides: [parseOverride('data/director/interrupts.json:brawl.heldPressTicks=0')], maxForks: 6 });
  ok(real.candidateFinal !== real.recorded.got, 'a real rule (brawl.heldPressTicks 0) changes the whole match');
  ok(JSON.stringify(real.forks.baseline) !== JSON.stringify(real.forks.candidate), 'and the forked presses');
  ok(real.forks.rows.every((r) => r.base.ticks === 240 && r.cand.ticks === 240), 'every fork played its 240 ticks, on both sides');
  const lg = await ledger({ match: m0352 });
  const s = summarise(lg);
  ok(s.total > 100 && Object.values(s.byPress).every((b) => b.total === b.honoured + b.refused + b.partly + b.silent), `the ledger lists the presses (${s.total}) and its verdicts add up`);
  ok(lg.presses.filter((p) => p.verdict === 'refused').every((p) => p.reasons.length > 0), 'every refused press has a reason');
  ok(lg.presses.every((p, i) => i === 0 || lg.presses[i - 1].t <= p.t), 'the ledger is in time order');
}
console.log(fails ? `feel self-test FAILED: ${fails} check(s)` : 'feel self-test ok');
process.exit(fails ? 1 : 0);

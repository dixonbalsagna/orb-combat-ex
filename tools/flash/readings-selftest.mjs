// Self-test of tools/flash/readings.mjs: the four readings of a clip and the worst of them (Legal RL-209). Node built-ins only.
import { SIZES, STAGED_TRIGGER, parseSize, defaultScale, scalesFor, numbers, verdictOn, worstOf, readClip } from './readings.mjs';

let failed = 0;
const check = (name, ok, detail) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok || !detail ? '' : '\n     ' + detail}`); if (!ok) failed++; };
const res = (primary, red, lower, stricter, tick = 100) => ({
  general: { flashes: primary, atTick: tick, atFrame: tick - 1 }, red: { flashes: red },
  combined: { verdict: 'PASS', lower, higher: lower, stricter, primary: Math.max(primary, red) }, cross: { general: { flashes: stricter }, red: { flashes: 0 } },
  params: { maxFlashes: 3, gate: 2.5 }, pass: true, dips: { list: [] },
});
const rd = (size, scale, r) => ({ size, scale, result: r });

check('the two sizes are 16:9 first, then the standard\'s reference', SIZES.join() === '960x540,1024x768');
check('a size is parsed, and a malformed one refused', parseSize('960x540').w === 960 && parseSize('960x540').h === 540 && (() => { try { parseSize('960*540'); return false; } catch { return true; } })());
check('the analyser\'s default scale is the smallest that brings the width to 640 or under', defaultScale(960) === 2 && defaultScale(1024) === 2 && defaultScale(640) === 1 && defaultScale(1920) === 3);
check('a size is analysed at full size and at its default, once when they are the same', scalesFor(960).join() === '1,2' && scalesFor(1024).join() === '1,2' && scalesFor(640).join() === '1');
check('the numbers of a result: primary, red, area-15%, the longer memory', JSON.stringify(numbers(res(3, 1, 2.5, 2))) === JSON.stringify({ primary: 3, red: 1, area15: 2.5, twoSec: 2 }));

const a = res(3, 0, 3, 3, 426), b = res(2.5, 0, 3.5, 2, 69);
const inputs = [rd('960x540', 1, a), rd('960x540', 2, b)];
const before = JSON.stringify(inputs);
const w = worstOf(inputs);
check('the worst of two takes the largest of each number, not the worst reading\'s numbers', w.general.flashes === 3 && w.combined.lower === 3.5 && w.combined.stricter === 3 && w.combined.primary === 3);
check('the verdict is the combined rule\'s on those numbers (3.5 on the area reading is FAIL) with the reason', w.combined.verdict === 'FAIL' && w.pass === false && /area threshold 15% lower it counts 3\.5/.test(w.combined.reasons.join(' ')), JSON.stringify(w.combined));
check('the inputs are not changed', JSON.stringify(inputs) === before);
check('every reading is listed with its size, scale and numbers, and the worst one is named', w.worstOf === 2 && w.readings.length === 2 && w.readings[1].size === '960x540' && w.readings[1].scale === 2 && w.readings[1].area15 === 3.5 && w.worst.scale === 2, JSON.stringify(w.worst));
check('the primary reading\'s tick is the worst primary reading\'s', w.general.atTick === 426);
check('four readings that all pass are PASS; a primary of 3 is OVER GATE, not PASS', worstOf([rd('960x540', 1, res(2, 0, 2.5, 1)), rd('960x540', 2, res(2.5, 0, 2.5, 2)), rd('1024x768', 1, res(1.5, 0, 2, 1)), rd('1024x768', 2, res(2, 0, 2, 1))]).combined.verdict === 'PASS'
  && worstOf([rd('960x540', 1, res(3, 0, 3, 3))]).combined.verdict === 'OVER GATE');
check('a red count over 3 is FAIL', worstOf([rd('960x540', 1, res(1, 3.5, 1, 1))]).combined.verdict === 'FAIL');
check('a clip with no longer-memory reading keeps it null, not 0', worstOf([rd('960x540', 1, res(1, 0, 1, null))]).combined.stricter === null);
check('the pin\'s collapse-normal at 960x540 (3.5 / 3.5 / 1 and 2.5 / 3.5 / 2) with the 1024x768 ones (2 / 3.5 / 1) reads 3.5 / 3.5 / 2', (() => { const x = worstOf([rd('960x540', 1, res(3.5, 0, 3.5, 1)), rd('960x540', 2, res(2.5, 0, 3.5, 2)), rd('1024x768', 1, res(2, 0, 3.5, 1)), rd('1024x768', 2, res(2, 0, 3.5, 1))]); return x.general.flashes === 3.5 && x.combined.lower === 3.5 && x.combined.stricter === 2 && x.worst.size === '960x540' && x.worst.scale === 1; })());
check('nothing to read is refused', (() => { try { worstOf([]); return false; } catch { return true; } })());

// the loop, with a stand-in for the capture and the analysis
{
  const calls = [];
  const table = { '960x540:1': res(3, 0, 3, 3), '960x540:2': res(3, 0, 3, 3), '1024x768:1': res(3.5, 0, 3.5, 3), '1024x768:2': res(2, 0, 3, 2) };
  const r = await readClip({
    job: { id: 'signature-reduced' },
    capture: async (job, size) => { calls.push(`capture ${size.text}`); return { dir: `d-${size.text}`, clip: { framesPerSecond: 9 } }; },
    analyse: async (dir, scale, size) => { calls.push(`analyse ${size.text} ${scale}`); return table[`${size.text}:${scale}`]; },
  });
  check('a clip is captured at each size, in order, and each capture analysed at its scales', calls.join('|') === 'capture 960x540|analyse 960x540 1|analyse 960x540 2|capture 1024x768|analyse 1024x768 1|analyse 1024x768 2', calls.join('|'));
  check('the result is the worst of the four, with the captures listed', r.readings.length === 4 && r.result.general.flashes === 3.5 && r.result.worst.size === '1024x768' && r.captures.length === 2 && r.captures[0].dir === 'd-960x540');
  let msg = '';
  try { await readClip({ job: { id: 'x' }, sizes: ['960x540'], capture: async () => { throw new Error('no page'); }, analyse: async () => null }); } catch (e) { msg = e.message; }
  check('a capture that fails names the clip and the size', /x at 960x540: no page/.test(msg), msg);
  const one = await readClip({ job: { id: 'y' }, sizes: ['640x360'], capture: async () => ({ dir: 'd', clip: {} }), analyse: async () => res(1, 0, 1, 1) });
  check('a width of 640 is analysed once', one.readings.length === 1);
}

// the staged reading of an AI-seed clip (Legal, 2026-10-30)
{
  const make = (table) => { const calls = []; return { calls, args: { job: { id: 'ai-1-reduced' }, staged: true, capture: async (job, size) => { calls.push('capture ' + size.text); return { dir: 'd-' + size.text, clip: {} }; }, analyse: async (dir, scale, size) => { calls.push('analyse ' + size.text + ' ' + scale); return table[size.text + ':' + scale] || res(1, 0, 1, 1); } } }; };
  check('the trigger is a primary of 2.5', STAGED_TRIGGER === 2.5);
  let m = make({ '960x540:1': res(2, 0, 3.5, 3) });
  let r = await readClip(m.args);
  check('a seed clip whose 16:9 full-size primary is under 2.5 is read once: one capture, one analysis, whatever its other numbers', r.readings.length === 1 && r.captures.length === 1 && m.calls.join('|') === 'capture 960x540|analyse 960x540 1' && r.staged === true && r.result.worstOf === 1, m.calls.join('|'));
  m = make({ '960x540:1': res(2.5, 0, 2, 1), '960x540:2': res(2, 0, 2, 1), '1024x768:1': res(3.5, 0, 3.5, 3), '1024x768:2': res(2, 0, 2, 1) });
  r = await readClip(m.args);
  check('at 2.5 the other readings are added, in order: the other scale, then the other size at both', m.calls.join('|') === 'capture 960x540|analyse 960x540 1|analyse 960x540 2|capture 1024x768|analyse 1024x768 1|analyse 1024x768 2' && r.readings.length === 4, m.calls.join('|'));
  check('and the worst of the four counts', r.result.general.flashes === 3.5 && r.result.worst.size === '1024x768' && r.staged === true);
  m = make({ '960x540:1': res(1, 2.5, 1, 1) });
  r = await readClip(m.args);
  check('a red count of 2.5 triggers it too', r.readings.length === 4);
  m = make({ '960x540:1': res(3, 0, 3, 3) });
  m.args.staged = false;
  r = await readClip(m.args);
  check('a fixed clip (staged off) is always read four times', r.readings.length === 4 && r.staged === false);
}

console.log(failed ? `readings self-test FAILED (${failed})` : 'readings self-test passed');
process.exit(failed ? 1 : 0);

// Self-test of tools/flash/window-check.mjs: a window that holds passes; the faults it exists for are found; the real windows file names what each clip holds.   node tools/flash/window-check-selftest.mjs
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runFileOf, ticksOf, windowProblems } from './window-check.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const run = { marks: { 'beam_outcome:CLASH': [140, 1140], building_fall: [93, 93, 543], shot_hit: [760] } };
const w = { skip: 1010, ticks: 240, holds: ['beam_outcome:CLASH'] };
check('a window with the event in its counted part holds', windowProblems('clash-normal', w, run).length === 0);
check('the fault of the clash nights: the window has no clash, and the ticks where it does happen are said', /no beam_outcome:CLASH in the counted part .*ticks 1011 to 1120.*140, 1140/.test(windowProblems('clash-normal', { skip: 950, ticks: 170, holds: ['beam_outcome:CLASH'] }, run).join()));
check('an event inside the window but within its first 60 frames does not count', windowProblems('x-normal', { skip: 1100, ticks: 200, holds: ['beam_outcome:CLASH'] }, run).length === 1 && windowProblems('x-normal', { skip: 1079, ticks: 200, holds: ['beam_outcome:CLASH'] }, run).length === 0);
check('every named event is asked for', windowProblems('x-normal', { skip: 0, ticks: 200, holds: ['building_fall', 'shot_hit'] }, run).length === 1);
check('"beam_outcome" takes any outcome and not another name that starts alike', ticksOf({ 'beam_outcome:HIT': [95], beam_outcomes: [1] }, 'beam_outcome').join() === '95');
check('no holds, no run file and a run with no marks are failures', [windowProblems('a-normal', { skip: 0, ticks: 100 }, run), windowProblems('a-normal', w, null), windowProblems('a-normal', w, {})].every((p) => p.length === 1));
const sources = JSON.parse(readFileSync(join(HERE, 'sources.json'), 'utf8'));
check('a night clip reads its base scene\'s run', runFileOf('clash-night-reduced', sources) === 'flash-clash-reduced.json' && runFileOf('collapse-normal', sources) === 'flash-collapse-normal.json' && runFileOf('nomode', sources) === null);
const windows = JSON.parse(readFileSync(join(HERE, 'nightly-windows.json'), 'utf8')).clips;
check('every nightly window names what it holds and is longer than the uncounted part', Object.entries(windows).every(([, x]) => Array.isArray(x.holds) && x.holds.length && x.ticks > 61), Object.entries(windows).filter(([, x]) => !x.holds).map(([k]) => k).join());
check('the clash windows hold a clash and the collapse windows a fall', ['clash-normal', 'clash-reduced', 'clash-night-normal', 'clash-night-reduced'].every((k) => windows[k].holds.includes('beam_outcome:CLASH')) && ['collapse-normal', 'collapse-reduced'].every((k) => windows[k].holds.includes('building_fall')));
const gd = readFileSync(join(HERE, 'flash_worst.gd'), 'utf8');
check('flash_worst.gd records the marks and writes them', gd.includes('marks.clear()') && gd.includes('"marks": marks.duplicate(true)') && ['"building_fall"', '"shot_hit"', '"beam_outcome:%s"', '"sig"'].every((x) => gd.includes(x)));
console.log(failed ? `window check self-test FAILED: ${failed} of ${ran}` : `window check self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

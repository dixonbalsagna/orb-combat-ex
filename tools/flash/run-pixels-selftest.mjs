// Self-test of tools/flash/run-pixels.mjs's four readings (Legal RL-209): the real run-pixels.mjs, in a scratch copy of tools/flash whose capture-web.mjs and analyse-frames.js are stand-ins, so no
// browser and no frames are needed. Node built-ins only.
import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
let failed = 0;
const check = (name, ok, detail) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok || !detail ? '' : '\n     ' + detail}`); if (!ok) failed++; };

const root = mkdtempSync(join(tmpdir(), 'run-pixels-'));
const d = join(root, 'tools', 'flash');   // clips.mjs reads data/fighters/roster.json two folders up
try {
  mkdirSync(d, { recursive: true }); mkdirSync(join(root, 'data', 'fighters'), { recursive: true });
  copyFileSync(join(here, '..', '..', 'data', 'fighters', 'roster.json'), join(root, 'data', 'fighters', 'roster.json'));
  for (const f of readdirSync(here)) if (/\.(mjs|js|json)$/.test(f) && !/selftest/.test(f)) copyFileSync(join(here, f), join(d, f));
  // a capture that writes a clip.json and one frame; it fails when STUB_FAIL names its size
  writeFileSync(join(d, 'capture-web.mjs'), [
    "import { mkdirSync, writeFileSync } from 'node:fs'; import { join } from 'node:path';",
    "const a = process.argv.slice(2); const o = (n) => a[a.indexOf(n) + 1];",
    "const w = Number(o('--width')), h = Number(o('--height')), out = o('--out');",
    "if (process.env.STUB_FAIL === w + 'x' + h) { console.error('[capture-web] FAILED: the stand-in refuses ' + w + 'x' + h); process.exit(1); }",
    "mkdirSync(out, { recursive: true }); writeFileSync(join(out, 'frame-000001.png'), 'x');",
    "writeFileSync(join(out, 'clip.json'), JSON.stringify({ width: w, height: h, reduced: a.includes('--reduced'), ticks: Number(o('--ticks')), framesPerSecond: w === 960 ? 9 : 7, loadBefore: 50, loadAfter: 60, mode: { reduce_flashing: a.includes('--reduced') }, probe: {}, guard: { tag: 'stub' } }));",
  ].join('\n'));
  // an analysis whose numbers depend on the size and scale: 960x540 full 3 / 3.5 / 2, 960x540 half 2.5 / 3 / 2.5, 1024x768 full 2 / 2.5 / 1, 1024x768 half 3.5 / 3 / 1
  writeFileSync(join(d, 'analyse-frames.js'), [
    "const fs = require('fs'), path = require('path');",
    "const a = process.argv.slice(2); const o = (n) => a[a.indexOf(n) + 1];",
    "const clip = JSON.parse(fs.readFileSync(path.join(a[0], 'clip.json'), 'utf8'));",
    "const t = (process.env.STUB_LOW === '1' ? { '960:1': [2, 3.5, 2], '960:2': [2, 3, 2], '1024:1': [2, 2.5, 1], '1024:2': [3.5, 3, 1] } : { '960:1': [3, 3.5, 2], '960:2': [2.5, 3, 2.5], '1024:1': [2, 2.5, 1], '1024:2': [3.5, 3, 1] })[clip.width + ':' + o('--scale')];",
    "const [p, l, s] = t;",
    "const r = { frames: 1, width: clip.width, height: clip.height, general: { flashes: p, atFrame: 9, atTick: 10, worstSecond: [], marginal: 0 }, red: { flashes: 0, atTick: 0, worstSecond: [], marginal: 0 }, dips: { list: [] },",
    "  combined: { verdict: 'X', lower: l, higher: l, stricter: s, primary: p }, cross: { general: { flashes: s }, red: { flashes: 0 } }, params: { maxFlashes: 3, gate: 2.5 }, pass: true };",
    "fs.writeFileSync(o('--json'), JSON.stringify([{ clip: a[0], result: r }]));",
  ].join('\n'));

  const run = (extra, env = {}, clip = 'signature-reduced') => spawnSync(process.execPath, [join(d, 'run-pixels.mjs'), '--dir', d, '--out', join(d, 'out'), '--clip', clip, '--jobs', '1', ...extra], { encoding: 'utf8', env: { ...process.env, ...env, MSYS_NO_PATHCONV: '1' } });
  const summary = () => JSON.parse(readFileSync(join(d, 'out', 'summary.json'), 'utf8'))[0];

  let r = run(['--keep']);
  const s = summary();
  check('a clip is captured at both sizes and read at both scales of each: four readings', s.readings && s.readings.length === 4 && s.sizes.join() === '960x540,1024x768', JSON.stringify(s.readings));
  check('the result is the worst of the four, number by number (3.5 / 3.5 / 2.5), and says which reading is the worst', s.result.general.flashes === 3.5 && s.result.combined.lower === 3.5 && s.result.combined.stricter === 2.5 && s.result.worstOf === 4 && s.result.worst.size === '1024x768', JSON.stringify(s.result.worst));
  check('its verdict is the combined rule\'s on those numbers: FAIL, so the run exits 1', s.result.combined.verdict === 'FAIL' && r.status === 1 && /worst of 4 readings/.test(r.stdout), r.stdout);
  check('the first size keeps the clip\'s folder and the others are <id>@<size>', existsSync(join(d, 'out', 'signature-reduced', 'clip.json')) && existsSync(join(d, 'out', 'signature-reduced@1024x768', 'clip.json')));
  check('analysis.json (what margins.mjs reads) is in the primary folder', existsSync(join(d, 'out', 'signature-reduced', 'analysis.json')));
  check('the capture condition is the slowest capture\'s, and each capture is listed', s.guard.framesPerSecond === 7 && s.captures.length === 2 && s.captures[0].size === '960x540' && s.captures[0].framesPerSecond === 9, JSON.stringify(s.guard));
  check('--keep keeps the frames of every size', existsSync(join(d, 'out', 'signature-reduced', 'frame-000001.png')) && existsSync(join(d, 'out', 'signature-reduced@1024x768', 'frame-000001.png')));

  rmSync(join(d, 'out'), { recursive: true, force: true });
  r = run(['--sizes', '960x540']);
  const one = summary();
  check('--sizes 960x540 is two readings (full size and the width\'s default), the old single-size run being one of them', one.readings.length === 2 && one.result.general.flashes === 3 && one.result.combined.lower === 3.5, JSON.stringify(one.readings));

  rmSync(join(d, 'out'), { recursive: true, force: true });
  r = run(['--clip', 'signature-reduced'], { STUB_FAIL: '1024x768' });
  check('a capture that fails at the second size is reported with the clip and the size, and the run exits 1', r.status === 1 && /signature-reduced at 1024x768/.test(r.stdout + r.stderr) && /CAPTURE FAILED/.test(r.stdout), r.stdout + r.stderr);

  rmSync(join(d, 'out'), { recursive: true, force: true });
  r = run(['--capture-only']);
  check('--capture-only captures every size and reads nothing', r.status === 0 && existsSync(join(d, 'out', 'signature-reduced', 'clip.json')) && existsSync(join(d, 'out', 'signature-reduced@1024x768', 'clip.json')) && !existsSync(join(d, 'out', 'signature-reduced', 'analysis.json')), r.stdout + r.stderr);

  // the AI-seed clips are staged (Legal, 2026-10-30): 16:9 full size first, the rest of the four only from a primary of 2.5
  rmSync(join(d, 'out'), { recursive: true, force: true });
  r = run(['--keep'], { STUB_LOW: '1' }, 'ai-4-reduced');
  const low = summary();
  check('an AI-seed clip whose 16:9 full-size primary is under 2.5 is read once: one reading, one capture, no second folder', low.readings.length === 1 && low.result.worstOf === 1 && low.captures.length === 1 && !existsSync(join(d, 'out', 'ai-4-reduced@1024x768')), JSON.stringify(low.readings));
  rmSync(join(d, 'out'), { recursive: true, force: true });
  r = run(['--keep'], {}, 'ai-4-reduced');
  const hi = summary();
  check('one at 2.5 or more gets the other readings added: four readings, two captures, the worst counts', hi.readings.length === 4 && hi.captures.length === 2 && hi.result.general.flashes === 3.5, JSON.stringify(hi.readings));
  rmSync(join(d, 'out'), { recursive: true, force: true });
  r = run(['--keep', '--all-readings'], { STUB_LOW: '1' }, 'ai-4-reduced');
  check('--all-readings reads an AI-seed clip four times too', summary().readings.length === 4);

  r = run(['--sizes', '960by540']);
  check('a malformed size is refused before anything runs', r.status !== 0 && /a size looks like/.test(r.stdout + r.stderr), r.stdout + r.stderr);
} finally { rmSync(root, { recursive: true, force: true }); }

console.log(failed ? `run-pixels self-test FAILED (${failed})` : 'run-pixels self-test passed');
process.exit(failed ? 1 : 0);

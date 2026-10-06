// End-to-end self-test of the pixel half: headless Chrome plays the mock page (tools/flash/mock-page/) that flashes on purpose, tools/flash/capture-web.mjs
// captures one PNG a tick, tools/flash/analyse-frames.js reads them. Each scene has a known answer; a wrong one fails. Needs Chrome or Edge (--require-browser makes
// its absence a failure; otherwise it says so and exits 0). No game, no Godot.
//   node tools/flash/pixel-selftest.mjs [--require-browser] [--browser-path <exe>]
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const bp = argv.indexOf('--browser-path') >= 0 ? ['--browser-path', argv[argv.indexOf('--browser-path') + 1]] : [];
const tmp = mkdtempSync(join(tmpdir(), 'flash-pix-'));
let failed = 0;
const cases = [
  { scene: 'steady', general: 0, pass: true, what: 'a still frame' },
  { scene: 'strobe3', general: 3, pass: false, what: 'the whole frame black and white 3 times a second (within the standard, over our gate of 2.5)' },
  { scene: 'strobe4', general: 4, pass: false, what: 'the same 4 times a second' },
  { scene: 'corner2', general: 0, pass: true, what: 'a 2.25% corner at 10 a second (under a quarter of a 341 x 256 window)' },
  { scene: 'corner4', general: 10, pass: false, what: 'a 4% corner at 10 a second (over it)' },
  { scene: 'redgrey', general: 0, pass: false, red: 10, what: 'red against grey at 10 a second (a red flash, not a general one)' },
];
try {
  for (const c of cases) {
    const out = join(tmp, c.scene);
    const cap = spawnSync(process.execPath, [join(here, 'capture-web.mjs'), '--mock', '--scenario', c.scene, '--ticks', '120', '--out', out, ...bp], { encoding: 'utf8' });
    if (cap.status === 2 && /no (chrome|edge) executable/.test(cap.stderr)) {
      if (argv.includes('--require-browser')) { console.log('pixel self-test FAILED: no browser found'); process.exit(1); }
      console.log('pixel self-test skipped: no Chrome or Edge found (pass --browser-path, or --require-browser to make it a failure)');
      process.exit(0);
    }
    if (cap.status !== 0) { console.log(`  FAIL ${c.scene}: capture failed: ${cap.stderr || cap.stdout}`); failed++; continue; }
    const json = join(tmp, `${c.scene}.json`);
    const an = spawnSync(process.execPath, [join(here, 'analyse-frames.js'), out, '--json', json], { encoding: 'utf8' });
    const r = JSON.parse(readFileSync(json, 'utf8'))[0].result;
    const ok = r.general.flashes === c.general && (c.red === undefined || r.red.flashes === c.red) && r.pass === c.pass && (an.status === 0) === c.pass;
    if (!ok) failed++;
    console.log(`  ${ok ? 'ok  ' : 'FAIL'} ${c.what}: ${r.general.flashes} general and ${r.red.flashes} red flashes, ${r.pass ? 'no failure found' : 'fails'} (expected ${c.general}, ${c.pass ? 'no failure' : 'fails'})`);
  }
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
console.log(failed ? `pixel self-test FAILED: ${failed} of ${cases.length}` : `pixel self-test ok: ${cases.length} scenes through headless Chrome, the capture driver and the analyser`);
process.exit(failed ? 1 : 0);

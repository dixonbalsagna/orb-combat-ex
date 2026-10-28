// Self-test of tools/flash/compare-frames.mjs (Legal's RL-199 item 1): identical frames, a difference within noise, a difference beyond it, the noise capture's bound, the pixel tolerance, a size
// change, folders with nothing in common, two different matches refused, and the command's exit codes and JSON. Frames are made with the analyser's own PNG writer; no browser, no Godot.
//   node tools/flash/compare-frames-selftest.mjs
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createRequire } from 'node:module';
import { compareImages, compareFolders, verdict, DEFAULT_FLOOR, NOISE_FACTOR } from './compare-frames.mjs';
const { encodePng } = createRequire(import.meta.url)('./wcag.js');

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const here = import.meta.dirname;
const W = 100, H = 100;   // 10,000 pixels: 1 pixel is 0.01%

/** An RGBA image of one grey, with `n` pixels set to another grey from the top-left (row by row). */
const img = (grey, n = 0, other = 255) => { const d = new Uint8ClampedArray(W * H * 4); for (let i = 0; i < W * H; i++) { const v = i < n ? other : grey; d[i * 4] = v; d[i * 4 + 1] = v; d[i * 4 + 2] = v; d[i * 4 + 3] = 255; } return d; };
const png = (data, w = W, h = H) => encodePng(w, h, data);

const tmp = mkdtempSync(join(tmpdir(), 'compare-frames-'));
try {
  const dir = (name, frames, clip = { scenario: 'mash', seed: 12345, seedPlayed: 12345, slots: null, pairing: 'default', variant: 0 }) => {
    const d = join(tmp, name); mkdirSync(d, { recursive: true });
    frames.forEach((f, i) => writeFileSync(join(d, `frame-${String(i + 1).padStart(6, '0')}.png`), f));
    if (clip) writeFileSync(join(d, 'clip.json'), JSON.stringify(clip));
    return d;
  };
  const base = [png(img(40)), png(img(90)), png(img(200))];

  // the pixel comparison
  const a = { w: W, h: H, data: img(40) };
  check('two equal images differ in no pixel', compareImages(a, { w: W, h: H, data: img(40) }).diffPx === 0);
  check('a difference up to the tolerance (8 of 255) does not count, one past it does', compareImages(a, { w: W, h: H, data: img(48) }).diffPx === 0 && compareImages(a, { w: W, h: H, data: img(49) }).diffPx === W * H);
  const c = compareImages(a, { w: W, h: H, data: img(40, 50, 200) });
  check('50 changed pixels of 10,000 are 0.5% and the largest step is read', c.diffPx === 50 && Math.abs(c.fraction - 0.005) < 1e-9 && c.maxDiff === 160);
  check('images of another size are a difference of every pixel', compareImages(a, { w: 50, h: 50, data: new Uint8ClampedArray(50 * 50 * 4) }).sizeDiffers === true);

  // the folders and the verdict
  const dStd = dir('std', base), dSame = dir('same', base);
  const rowsSame = compareFolders(dStd, dSame);
  check('identical folders: every frame identical, none beyond noise', rowsSame.length === 3 && rowsSame.every((r) => r.identical) && verdict(rowsSame, null).beyondNoise === 0 && verdict(rowsSame, null).identical === 3);
  // 5 pixels (0.05%) differ in frame 2: under the floor (0.1%)
  const dTiny = dir('tiny', [base[0], png(img(90, 5, 200)), base[2]]);
  const vTiny = verdict(compareFolders(dStd, dTiny), null);
  check('a difference of 0.05% of the pixels is within noise (the floor is 0.1%, above the 0.078% Performance measured)', vTiny.identical === 2 && vTiny.withinNoise === 1 && vTiny.beyondNoise === 0 && DEFAULT_FLOOR === 0.001);
  // 50 pixels (0.5%): beyond the floor
  const dBig = dir('big', [base[0], png(img(90, 50, 200)), base[2]]);
  const vBig = verdict(compareFolders(dStd, dBig), null);
  check('a difference of 0.5% is beyond noise when there is no noise capture, and the frame is named', vBig.beyondNoise === 1 && vBig.beyondFrames[0] === 'frame-000002.png' && vBig.withinNoise === 0);
  // the noise capture: a second standard capture that differs from the first by 0.5% in one frame raises the bound to 0.625%
  const dNoise = dir('noise', [base[0], png(img(90, 50, 200)), base[2]]);
  const noiseRows = compareFolders(dStd, dNoise);
  check('a noise capture that differs by 0.5% raises the bound to 1.25 times that', Math.abs(verdict(compareFolders(dStd, dBig), noiseRows).limit - 0.005 * NOISE_FACTOR) < 1e-9 && verdict(compareFolders(dStd, dBig), noiseRows).beyondNoise === 0);
  const dHuge = dir('huge', [base[0], png(img(90, 200, 200)), base[2]]);
  check('a difference of 2% is still beyond that bound', verdict(compareFolders(dStd, dHuge), noiseRows).beyondNoise === 1);
  check('a frame of another size is beyond noise whatever the bound', (() => { const d = dir('size', [base[0], png(new Uint8ClampedArray(50 * 50 * 4), 50, 50), base[2]]); return verdict(compareFolders(dStd, d), noiseRows).beyondNoise === 1; })());
  check('only the frames the two folders share are compared', (() => { const d = dir('short', [base[0], base[1]]); return compareFolders(dStd, d).length === 2 && compareFolders(d, dStd).length === 2; })());

  // the command
  const run = (args) => spawnSync(process.execPath, [join(here, 'compare-frames.mjs'), ...args], { encoding: 'utf8' });
  const r1 = run(['--standard', dStd, '--custom', dSame]);
  check('the command exits 0 for identical clips and says so', r1.status === 0 && /3 frames: 3 identical, 0 within noise, 0 beyond/.test(r1.stdout), r1.stdout + r1.stderr);
  const jf = join(tmp, 'out.json');
  const r2 = run(['--standard', dStd, '--custom', dTiny, '--json', jf]);
  check('a difference within noise exits 0 and the JSON records the counts (the record\'s measured.frames)', r2.status === 0 && (() => { const j = JSON.parse(readFileSync(jf, 'utf8')); return j.frames === 3 && j.identical === 2 && j.withinNoise === 1 && j.beyondNoise === 0 && j.limit === 0.001; })(), r2.stdout + r2.stderr);
  const r3 = run(['--standard', dStd, '--custom', dBig]);
  check('a frame beyond noise exits 1 and says the full set is needed', r3.status === 1 && /BEYOND NOISE: frame-000002\.png/.test(r3.stderr) && /full flash set/.test(r3.stderr), r3.stderr);
  const r4 = run(['--standard', dStd, '--custom', dBig, '--noise', dNoise]);
  check('with the noise capture the same difference exits 0', r4.status === 0, r4.stdout + r4.stderr);
  const r5 = run(['--standard', dStd, '--custom', dir('other-seed', base, { scenario: 'mash', seed: 7, seedPlayed: 7, slots: null, pairing: 'default', variant: 0 })]);
  check('two different matches are refused (a frame difference between them says nothing about the template)', r5.status === 2 && /not the same match/.test(r5.stderr), r5.stderr);
  const r6 = run(['--standard', dStd, '--custom', dir('other-seed2', base, { scenario: 'mash', seed: 7, seedPlayed: 7, slots: null, pairing: 'default', variant: 0 }), '--allow-different']);
  check('--allow-different compares them anyway', r6.status === 1 || r6.status === 0, r6.stderr);
  const empty = join(tmp, 'empty'); mkdirSync(empty);
  check('folders with no frame in common are an error, not a pass', run(['--standard', dStd, '--custom', empty]).status === 2);
  check('a missing folder or option is a usage error', run(['--standard', dStd]).status === 2 && run(['--standard', dStd, '--custom', join(tmp, 'nope')]).status === 2);
} finally { rmSync(tmp, { recursive: true, force: true }); }

console.log(failed ? `compare-frames self-test FAILED: ${failed} of ${ran}` : `compare-frames self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

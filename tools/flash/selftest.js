// Self-test of the flash analysers: synthetic frames with a known answer, and a log with a known answer. CI runs it; it needs no build and no browser.
//   node tools/flash/selftest.js
'use strict';
const zlib = require('zlib');
const W = require('./wcag.js');
const L = require('./check-log.js');

let failed = 0, ran = 0;
function check(name, ok, extra) { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } }

const WID = 96, HEI = 72;   // 4:3, so the area threshold is the same fraction as at 1024x768 (0.111)

/** A frame: bg everywhere, fg inside the rectangle (x0,y0,x1,y1) in fractions of the frame (or the whole frame). */
function frame(bg, fg, rect) {
  const data = new Uint8Array(WID * HEI * 4);
  for (let y = 0; y < HEI; y++) for (let x = 0; x < WID; x++) {
    const inside = rect && x >= rect[0] * WID && x < rect[2] * WID && y >= rect[1] * HEI && y < rect[3] * HEI;
    const c = inside ? fg : bg;
    const p = (y * WID + x) * 4;
    data[p] = c[0]; data[p + 1] = c[1]; data[p + 2] = c[2]; data[p + 3] = 255;
  }
  return { w: WID, h: HEI, data };
}

/** `seconds` of frames (60 a second) alternating every `half` frames: the whole frame between a and b, or with `rect` only that rectangle between a and b on a steady a. */
function strobe(a, b, half, seconds, rect) {
  const states = rect ? [frame(a, a, rect), frame(a, b, rect)] : [frame(a, a), frame(b, b)];
  const out = [];
  for (let i = 0; i < Math.round(60 * seconds); i++) out.push(states[Math.floor(i / half) % 2]);
  return out;
}

const BLACK = [0, 0, 0], WHITE = [255, 255, 255], GREY = [128, 128, 128];
const run = (frames, o) => W.analyse(frames, o);

// ---- luminance and the PNG codec
check('relative luminance of white is 1', Math.abs(W.relLum(255, 255, 255) - 1) < 1e-9);
check('relative luminance of black is 0', W.relLum(0, 0, 0) === 0);
check('relative luminance of mid grey (sRGB 128) is 0.2159', Math.abs(W.relLum(128, 128, 128) - 0.2159) < 5e-4, String(W.relLum(128, 128, 128)));
check('(200,0,0) is a saturated red and (110,110,110) is not', W.isSatRed(200, 0, 0, 0.8, 'either') && !W.isSatRed(110, 110, 110, 0.8, 'either'));
check('a dark red (200,30,30) is a saturated red on the linear values only, so "either" takes it and "stored" does not', W.isSatRed(200, 30, 30, 0.8, 'either') && !W.isSatRed(200, 30, 30, 0.8, 'stored'));
check('uv of white is the D65 point (0.1978, 0.4683)', Math.abs(W.uv(255, 255, 255)[0] - 0.1978) < 5e-4 && Math.abs(W.uv(255, 255, 255)[1] - 0.4683) < 5e-4, JSON.stringify(W.uv(255, 255, 255)));
check('uv of black is given the white point (no light has no chromaticity)', W.uv(0, 0, 0)[0] === W.uv(255, 255, 255)[0] || Math.abs(W.uv(0, 0, 0)[0] - 0.19784) < 1e-9);
{
  const f = frame(BLACK, WHITE, [0, 0, 0.5, 1]);
  const back = W.decodePng(W.encodePng(f.w, f.h, f.data));
  check('a PNG written and read back is the same frame', back.w === f.w && back.h === f.h && Buffer.compare(Buffer.from(back.data), Buffer.from(f.data)) === 0);
}
{
  // every PNG row filter (sub, up, average, paeth), written here and read by the decoder
  const f = frame(BLACK, [200, 90, 30], [0.2, 0.2, 0.8, 0.8]);
  const stride = f.w * 4, rows = [];
  for (let y = 0; y < f.h; y++) {
    const ft = 1 + (y % 4);
    const row = Buffer.alloc(stride + 1); row[0] = ft;
    for (let x = 0; x < stride; x++) {
      const cur = f.data[y * stride + x];
      const a = x >= 4 ? f.data[y * stride + x - 4] : 0, b = y > 0 ? f.data[(y - 1) * stride + x] : 0, c = x >= 4 && y > 0 ? f.data[(y - 1) * stride + x - 4] : 0;
      const pr = ft === 1 ? a : ft === 2 ? b : ft === 3 ? (a + b) >> 1 : (() => { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); return pa <= pb && pa <= pc ? a : pb <= pc ? b : c; })();
      row[1 + x] = (cur - pr) & 255;
    }
    rows.push(row);
  }
  const png = W.encodePng(f.w, f.h, f.data);
  // swap the IDAT for the filtered rows: rebuild the file with the same chunks but this payload
  const idatAt = png.indexOf('IDAT') - 4;
  const idatLen = png.readUInt32BE(idatAt);
  const z = zlib.deflateSync(Buffer.concat(rows));
  const head = png.subarray(0, idatAt), tail = png.subarray(idatAt + 12 + idatLen);
  const chunk = Buffer.alloc(12 + z.length);
  chunk.writeUInt32BE(z.length, 0); chunk.write('IDAT', 4, 'latin1'); z.copy(chunk, 8);
  chunk.writeUInt32BE(0, 8 + z.length);   // the decoder does not check the CRC
  const back = W.decodePng(Buffer.concat([head, chunk, tail]));
  check('a PNG with sub, up, average and paeth rows decodes to the same frame', Buffer.compare(Buffer.from(back.data), Buffer.from(f.data)) === 0);
}

// ---- the general flash
const full3 = run(strobe(BLACK, WHITE, 10, 3));
check('a full-frame black/white strobe at 3 a second is 3 flashes and passes', full3.general.flashes === 3 && full3.pass, JSON.stringify(full3.general));
const full4 = run(strobe(BLACK, WHITE, 7.5, 3));
check('the same strobe at 4 a second is 4 flashes and fails', full4.general.flashes >= 4 && !full4.pass, JSON.stringify(full4.general));
check('a full-frame strobe at 10 a second fails', !run(strobe(BLACK, WHITE, 3, 2)).pass);
{
  // the frame here is 96 x 72, so the window is 32 x 24 = 768 px and a quarter of it is 192 px (2.78% of the frame)
  const r = run(strobe(BLACK, WHITE, 3, 2, [0.0, 0.0, 0.15, 0.15]));   // 15 x 11 = 165 px: under a quarter of the window
  check('a 2.4% corner strobing 10 a second is under a quarter of a window and passes', r.pass && r.general.flashes === 0 && r.thresholdPx === 192, JSON.stringify([r.general, r.thresholdPx]));
}
{
  const r = run(strobe(BLACK, WHITE, 3, 2, [0.0, 0.0, 0.2, 0.2]));    // 20 x 15 = 300 px: over it
  check('a 4.3% corner strobing 10 a second is over a quarter of a window and fails', !r.pass && r.general.flashes > 3, JSON.stringify(r.general));
}
check('a 9% corner strobing 10 a second fails (it passed under the lenient total-area reading)', !run(strobe(BLACK, WHITE, 3, 2, [0.0, 0.0, 0.3, 0.3])).pass);
{
  // the window is slid, and only one window counts: two blobs far apart, each under the threshold, pass; the same pixels together fail
  const two = (n) => {
    const st = [], a = frame(BLACK, BLACK), b = frame(BLACK, BLACK);
    for (let y = 0; y < HEI; y++) for (let x = 0; x < WID; x++) { const in1 = x < 0.15 * WID && y < 0.15 * HEI, in2 = x >= 0.85 * WID && y >= 0.85 * HEI; if (in1 || in2) { const p = (y * WID + x) * 4; b.data[p] = b.data[p + 1] = b.data[p + 2] = 255; } }
    for (let i = 0; i < n; i++) st.push(Math.floor(i / 3) % 2 ? b : a);
    return st;
  };
  const r = run(two(120));
  check('two 2.4% blobs at opposite corners (4.8% together) strobing 10 a second pass: no one window holds a quarter of its pixels', r.pass && r.general.flashes === 0, JSON.stringify(r.general));
  // a thin strip across the whole frame: 0.9 x 0.05 of it is 4.5% of the frame, over the lenient total but only 15% of any window
  const strip = run(strobe(BLACK, WHITE, 3, 2, [0.05, 0.45, 0.95, 0.5]));
  check('a thin strip across the frame (4.5% of it, 15% of a window) strobing 10 a second passes under the window test', strip.pass && strip.general.flashes === 0, JSON.stringify(strip.general));
}
check('a swing of 0.08 (under the 10% step) at 10 a second passes', run(strobe([128, 128, 128], [140, 140, 140], 3, 2)).general.flashes === 0);
check('a swing between two states both at or above 0.80 passes', run(strobe([235, 235, 235], [255, 255, 255], 3, 2)).pass);
check('the same swing from just below 0.80 fails (darker state under it)', !run(strobe([225, 225, 225], [255, 255, 255], 3, 2)).pass);
{
  // slow ramps: black to white over 30 frames and back, twice, are one change each: 4 changes in 2 seconds
  const fr = [];
  for (let i = 0; i < 120; i++) { const t = i % 60; const v = Math.round(255 * (t < 30 ? t / 29 : (59 - t) / 29)); fr.push(frame([v, v, v], [v, v, v])); }
  const r = run(fr);
  check('a slow ramp up and down (30 frames each) is a pass', r.pass && r.general.flashes <= 1, JSON.stringify(r.general));
}
check('a still image has no flashes', run([frame(GREY, GREY), frame(GREY, GREY), frame(GREY, GREY)]).general.flashes === 0);
check('the flashes are counted in any one second, not over the whole clip: 3 a second for 10 seconds passes', run(strobe(BLACK, WHITE, 10, 10)).pass);
{
  // 3 flashes in the first second then a pause then 3 more in the next: a window of one second never holds more than 3
  const fr = [];
  for (let i = 0; i < 240; i++) fr.push(i < 60 ? [frame(BLACK, BLACK), frame(WHITE, WHITE)][Math.floor(i / 10) % 2] : i < 120 ? frame(BLACK, BLACK) : i < 180 ? [frame(BLACK, BLACK), frame(WHITE, WHITE)][Math.floor((i - 120) / 10) % 2] : frame(BLACK, BLACK));
  check('two bursts of 3 flashes a second apart pass', run(fr).pass);
}

// ---- the red flash
{
  const r = run(strobe([200, 0, 0], [110, 110, 110], 3, 2));   // luminance steps by 0.03 only; the chromaticity steps by 0.26 in uv and one state is a saturated red
  check('a red to grey strobe at 10 a second is a red flash and not a general flash', r.red.flashes > 3 && r.general.flashes === 0 && !r.pass, JSON.stringify([r.general, r.red]));
}
check('a green to blue strobe at 10 a second is not a red flash (no saturated red)', run(strobe([60, 130, 60], [40, 40, 200], 3, 2)).red.flashes === 0);
check('red to a state 0.15 away in uv is not a red flash (under 0.2)', run(strobe([200, 0, 0], [150, 80, 40], 3, 2)).red.flashes === 0);
check('a grey strobe has no red flash', run(strobe([200, 200, 200], [128, 128, 128], 3, 2)).red.flashes === 0);
check('a slow red pulse (once a second) passes', run(strobe([200, 0, 0], [110, 110, 110], 30, 3)).pass);
check('the red flash is subject to the same area window: a 2.4% corner of it passes', run(strobe([200, 0, 0], [110, 110, 110], 3, 2, [0, 0, 0.15, 0.15])).red.flashes === 0);

// ---- dips
{
  // a whole-frame dip 0.8 -> 0.3 in one frame and back over 4, three times, 20 frames apart: three dips, shortest gap 20 frames
  const fr = [];
  for (let i = 0; i < 100; i++) { const t = i % 20; const v = t === 5 ? 90 : t === 6 ? 130 : t === 7 ? 170 : t === 8 ? 210 : 235; const l = i >= 5 && i < 65 ? v : 235; fr.push(frame([l, l, l], [l, l, l])); }
  const r = run(fr);
  check('whole-screen dips are listed with their frame, depth and the gap between them', r.dips.list.length === 3 && r.dips.shortestGapFrames === 20 && r.dips.list[0].tick === 6 && r.dips.list[0].drop > 0.3, JSON.stringify(r.dips));
}

// ---- the parameters are real parameters
check('the frame rate is a parameter: the same 180 frames read as 120 a second hold 6 flashes in a second and fail', run(strobe(BLACK, WHITE, 10, 3), { fps: 120 }).general.flashes === 6);
check('a larger share of the window lets the 4.3% corner through (300 of 768 px is 39%, so 50% passes it)', run(strobe(BLACK, WHITE, 3, 2, [0, 0, 0.2, 0.2]), { areaShare: 0.5 }).pass);
check('a fade over 4 frames is pooled into one change: black to white over 4 frames and back, twice a second, over the whole frame, is 2 flashes a second', run((() => { const o = []; for (let i = 0; i < 120; i++) { const t = (i % 30); const v = t < 4 ? [0, 85, 170, 255][t] : t < 15 ? 255 : t < 19 ? [170, 85, 0, 0][t - 15] : 0; o.push(frame([v, v, v], [v, v, v])); } return o; })()).general.flashes === 2);

// ---- the register log
const row = (now, source, granted, why, inw) => [now, now, source, granted, why, inw];
{
  const good = { scenario: 't', reduced: false, rows: [row(1, 'explosion', true, 'ok', 1), row(20, 'energy', true, 'ok', 2), row(40, 'transform', true, 'ok', 3), row(50, 'block', false, 'cap', 3), row(70, 'explosion', true, 'ok', 3)], cap: 3 };
  const r = L.checkRun(good);
  check('a log with 3 granted in a window passes, and its worst is 3', r.pass && r.worst === 3, JSON.stringify(r));
  const bad = { scenario: 't', reduced: false, rows: [row(1, 'explosion', true, 'ok', 1), row(10, 'energy', true, 'ok', 2), row(20, 'transform', true, 'ok', 3), row(30, 'explosion', true, 'ok', 4)], cap: 3 };
  check('a log with 4 granted in 60 ticks fails (counted from the rows, not from the running figure)', !L.checkRun(bad).pass && L.checkRun(bad).worst === 4);
  const sl = { scenario: 't', reduced: false, rows: [row(1, 'explosion', true, 'ok', 1), row(30, 'explosion', true, 'ok', 2), row(60, 'explosion', true, 'ok', 3), row(61, 'explosion', true, 'ok', 3), row(62, 'explosion', true, 'ok', 3)], cap: 3 };
  check('the window is 60 ticks: grants at 1, 30, 60, 61, 62 put 4 in [30,89] and fail, though no 3 are more than 59 apart from the first', L.checkRun(sl).worst === 4 && !L.checkRun(sl).pass, JSON.stringify(L.checkRun(sl)));
  const edge = { scenario: 't', reduced: false, rows: [row(1, 'explosion', true, 'ok', 1), row(20, 'energy', true, 'ok', 2), row(40, 'transform', true, 'ok', 3), row(61, 'explosion', true, 'ok', 3)], cap: 3 };
  check('a grant exactly 60 ticks after the first is outside its window (the register slides at now - 60)', L.checkRun(edge).pass && L.checkRun(edge).worst === 3);
  const red = { scenario: 't', reduced: false, rows: [row(1, 'explosion', true, 'ok', 1), row(2, 'explosion', false, 'cap', 1)], cap: 3 };
  check('a refused ask is not counted', L.checkRun(red).worst === 1);
  const rd = { scenario: 't', reduced: true, rows: [row(1, 'explosion', true, 'ok', 1), row(30, 'transform', true, 'ok', 2)], cap: 1 };
  check('under reduced flashing two granted in a second fails (the cap is 1)', !L.checkRun(rd).pass && L.checkRun(rd).worst === 2);
  const un = { scenario: 't', reduced: false, rows: [row(1, 'body_hit', true, 'unregulated', 1)], cap: 3 };
  check('an unregulated note counts as a flash (the register does not refuse it)', L.checkRun(un).worst === 1);
  const unk = { scenario: 't', reduced: false, rows: [row(1, 'brand_new_source', true, 'ok', 1)], cap: 3 };
  check('a source the list does not know is reported', L.checkRun(unk).unknownSources.includes('brand_new_source'));
  const full = { scenario: 't', reduced: false, rows: new Array(2400).fill(0).map((_, i) => row(i * 100, 'explosion', true, 'ok', 1)), cap: 3, asked: 2600 };
  check('a log that is full (the register keeps the last 2,400) is reported as truncated', L.checkRun(full).truncated === true);
}


// ---- drift: the staging exists twice (tools/flash/flash_worst.gd here, render/tools/flash_capture.gd in Rendering's export), and tick and seed counts live in sources.json too
{
  const fs = require('fs'), path = require('path');
  const root = path.join(__dirname, '..', '..');
  const read = (f) => fs.readFileSync(path.join(root, f), 'utf8');
  const slots = (txt) => {
    const m = txt.match(/const AI_SLOTS: Dictionary = \{([^\n]*)\}/);
    if (!m) return null;
    const o = {};
    for (const x of m[1].matchAll(/"(\w+)":\s*\[(true|false),\s*(true|false)\]/g)) o[x[1]] = [x[2], x[3]].join(',');
    return o;
  };
  const list = (txt) => { const m = txt.match(/const SCENARIOS: Array = \[([^\]]*)\]/); return m ? [...m[1].matchAll(/"(\w+)"/g)].map((x) => x[1]) : null; };
  const nums = (txt, name) => {
    const m = txt.match(new RegExp('const ' + name + ': Dictionary = \\{([^\\n]*)\\}'));
    if (!m) return null;
    const o = {};
    for (const x of m[1].matchAll(/"(\w+)":\s*(\[[^\]]*\]|\d+)/g)) o[x[1]] = JSON.parse(x[2]);
    return o;
  };
  const mine = read('tools/flash/flash_worst.gd');
  const src = L.loadSources();
  const ticks = nums(mine, 'TICKS'), seeds = nums(mine, 'SEEDS');
  check('sources.json and flash_worst.gd agree on every scenario\'s ticks and seeds', src.scenarios.every((s) => ticks && seeds && ticks[s.id] === s.ticks && JSON.stringify(seeds[s.id]) === JSON.stringify(s.seeds)), JSON.stringify({ ticks, seeds }));
  check('flash_worst.gd names exactly the scenarios of sources.json', JSON.stringify(list(mine)) === JSON.stringify(src.scenarios.map((s) => s.id)), JSON.stringify(list(mine)));
  let theirs = null;
  try { theirs = read('render/tools/flash_capture.gd'); } catch { /* an export without it */ }
  if (theirs) {
    check('Rendering\'s capture hook has the same scenarios as flash_worst.gd', JSON.stringify(list(theirs)) === JSON.stringify(list(mine)), JSON.stringify(list(theirs)));
    check('Rendering\'s capture hook has the same human and AI slots as flash_worst.gd', JSON.stringify(slots(theirs)) === JSON.stringify(slots(mine)), JSON.stringify([slots(theirs), slots(mine)]));
  }
}

console.log(failed ? `flash self-test FAILED: ${failed} of ${ran} checks` : `flash self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

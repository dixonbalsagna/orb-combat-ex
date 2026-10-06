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
check('the red measure is 0 for a pixel that is not a saturated red', W.redMeasure(200, 100, 100, 0.8) === 0 && W.redMeasure(0, 0, 0, 0.8) === 0);
check('the red measure of (255,0,0) is 320', Math.abs(W.redMeasure(255, 0, 0, 0.8) - 320) < 1e-9);
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
  const r = run(strobe(BLACK, WHITE, 3, 2, [0.0, 0.0, 0.3, 0.3]));   // 9% of the frame, under 11.1%
  check('a 9% strobe at 10 a second is under the area and passes', r.pass && r.general.flashes === 0, JSON.stringify(r.general));
}
{
  const r = run(strobe(BLACK, WHITE, 3, 2, [0.0, 0.0, 0.4, 0.4]));   // 16%, over it
  check('a 16% strobe at 10 a second is over the area and fails', !r.pass && r.general.flashes > 3, JSON.stringify(r.general));
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
  const r = run(strobe([200, 0, 0], [128, 0, 0], 3, 2));   // luminance steps by 0.08 only; the red measure steps by 90
  check('a red-to-dark-red strobe at 10 a second is a red flash and not a general flash', r.red.flashes > 3 && r.general.flashes === 0 && !r.pass, JSON.stringify([r.general, r.red]));
}
check('a grey strobe has no red flash', run(strobe([200, 200, 200], [128, 128, 128], 3, 2)).red.flashes === 0);
check('a slow red pulse (once a second) passes', run(strobe([200, 0, 0], [128, 0, 0], 30, 3)).pass);

// ---- the parameters are real parameters
check('the frame rate is a parameter: the same 180 frames read as 120 a second hold 6 flashes in a second and fail', run(strobe(BLACK, WHITE, 10, 3), { fps: 120 }).general.flashes === 6);
check('a larger area threshold lets the 16% strobe through', run(strobe(BLACK, WHITE, 3, 2, [0, 0, 0.4, 0.4]), { areaFrac: 0.2 }).pass);

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

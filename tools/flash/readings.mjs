// The four readings of a clip (Legal RL-209 (a), 2026-10-30): the same clip is captured at two frame sizes, 960x540 (16:9, the primary size) and 1024x768 (the standard's reference), and each
// capture is analysed at two scales, the full-size one and the analyser's default for that width (a box average down to 640 or under). The WORST of the four counts, for the gate and for the interim's
// trigger alike: a clip reads what its worst reading reads. A reading is { size: '960x540', scale: 1, result } with `result` the analyser's (tools/flash/wcag.js analyse).
//
//   worstOf(readings)  -> one result in the analyser's own shape (so every consumer reads it as before: general.flashes, red.flashes, combined.*, cross.general.flashes, dips, worstSecond ...)
//                         whose numbers are the largest of the readings', whose verdict is the combined rule's on those numbers, and which also carries `readings` (each reading's numbers) and `worst`.
//   readClip(...)      -> the loop that captures a clip at every size and analyses every capture at every scale (the capture and the analysis are passed in, so a self-test can stand in for them).
export const SIZES = ['960x540', '1024x768'];   // the primary size first
export const STAGED_TRIGGER = 2.5;   // an AI-seed clip's primary (or red) reading, at the first size and full size, from which the other readings are added (Legal, 2026-10-30)
const num = (v) => typeof v === 'number' && Number.isFinite(v);
const max = (...v) => { const n = v.filter(num); return n.length ? Math.max(...n) : null; };

export function parseSize(text) {
  const m = /^(\d+)x(\d+)$/.exec(String(text));
  if (!m) throw new Error(`a size looks like 960x540, not ${text}`);
  return { w: Number(m[1]), h: Number(m[2]), text: `${Number(m[1])}x${Number(m[2])}` };
}
/** The analyser's default scale for a width: the smallest box average that brings the width to 640 or under (tools/flash/analyse-frames.js). */
export const defaultScale = (w) => Math.max(1, Math.ceil(w / 640));
/** The scales a size is analysed at: full size, and the default for its width (the same one when the width is 640 or under). */
export const scalesFor = (w) => [...new Set([1, defaultScale(w)])];

/** The three numbers and the red count of a result. */
export function numbers(r) {
  return { primary: r.general.flashes, red: r.red ? r.red.flashes : 0, area15: r.combined.lower, twoSec: num(r.combined.stricter) ? r.combined.stricter : null };
}
const score = (n) => [max(n.primary, n.red, n.area15, n.twoSec), n.primary];

/** The combined rule's verdict on four numbers (tools/flash/wcag.js: FAIL over 3 on the primary, area-15% or two-second reading; OVER GATE over 2.5 on the primary). */
export function verdictOn(n, p = {}) {
  const maxFlashes = num(p.maxFlashes) ? p.maxFlashes : 3, gate = num(p.gate) ? p.gate : 2.5;
  const reasons = [];
  if (n.primary > maxFlashes || n.red > maxFlashes) reasons.push(`the primary reading counts ${max(n.primary, n.red)} (over ${maxFlashes})`);
  if (n.area15 > maxFlashes) reasons.push(`with the area threshold 15% lower it counts ${n.area15} (over ${maxFlashes})`);
  if (n.twoSec !== null && n.twoSec > maxFlashes) reasons.push(`with a longer memory it counts ${n.twoSec} (over ${maxFlashes})`);
  const verdict = reasons.length ? 'FAIL' : n.primary > gate ? 'OVER GATE' : 'PASS';
  if (verdict === 'OVER GATE') reasons.push(`the primary reading counts ${n.primary} (over our gate of ${gate})`);
  return { verdict, reasons };
}

export function worstOf(readings) {
  if (!readings.length) throw new Error('worstOf needs at least one reading');
  const rows = readings.map((x) => ({ size: x.size, scale: x.scale, ...numbers(x.result), atTick: x.result.general.atTick, verdict: x.result.combined.verdict }));
  let bi = 0;
  rows.forEach((r, i) => { const a = score(r), b = score(rows[bi]); if (a[0] > b[0] || (a[0] === b[0] && a[1] > b[1])) bi = i; });
  const base = readings[bi].result;
  const r = JSON.parse(JSON.stringify(base));
  const W = { primary: max(...rows.map((x) => x.primary)), red: max(...rows.map((x) => x.red)), area15: max(...rows.map((x) => x.area15)), twoSec: max(...rows.map((x) => x.twoSec)) };
  // the largest of each, set where every consumer reads it
  const atMax = (k) => readings[rows.findIndex((x) => x[k] === W[k])].result;
  r.general.flashes = W.primary; r.general.atTick = atMax('primary').general.atTick; r.general.atFrame = atMax('primary').general.atFrame;
  if (r.red) r.red.flashes = W.red;
  r.combined.primary = max(W.primary, W.red); r.combined.lower = W.area15;
  r.combined.higher = max(...readings.map((x) => x.result.combined.higher));
  r.combined.stricter = W.twoSec;
  if (r.cross && r.cross.general) { r.cross.general.flashes = max(...readings.map((x) => (x.result.cross && x.result.cross.general ? x.result.cross.general.flashes : null))); if (r.cross.red) r.cross.red.flashes = max(...readings.map((x) => (x.result.cross && x.result.cross.red ? x.result.cross.red.flashes : null))); }
  const v = verdictOn({ primary: r.combined.primary, red: W.red || 0, area15: W.area15, twoSec: W.twoSec }, r.params || {});
  r.combined.verdict = v.verdict; r.combined.reasons = v.reasons;
  r.pass = v.verdict === 'PASS';
  r.worst = { size: rows[bi].size, scale: rows[bi].scale };
  r.worstOf = rows.length;
  r.readings = rows;
  return r;
}

/**
 * Captures `job` at every size and analyses each capture at each of that size's scales. `capture(job, size)` -> { dir, clip } (the capture's folder and its clip.json); `analyse(dir, scale)` ->
 * the analyser's result. Returns { readings, captures: [{ size, dir, clip }], result }, `result` being worstOf(readings). A capture that fails throws with its size named.
 * `staged` (the AI-seed clips): read the first size at full size only; when that reading's primary or red count is under STAGED_TRIGGER that is the clip's reading, otherwise the rest of the four are added.
 */
export async function readClip({ job, sizes = SIZES, capture, analyse, staged = false }) {
  const readings = [], captures = [];
  let first = true;
  for (const text of sizes) {
    const size = parseSize(text);
    let cap;
    try { cap = await capture(job, size); } catch (e) { throw new Error(`${job.id} at ${size.text}: ${e.message}`); }
    captures.push({ size: size.text, dir: cap.dir, clip: cap.clip });
    const scales = scalesFor(size.w);
    if (staged && first) {
      const one = { size: size.text, scale: scales[0], result: await analyse(cap.dir, scales[0], size) };
      readings.push(one);
      const n = numbers(one.result);
      if (!(n.primary >= STAGED_TRIGGER || n.red >= STAGED_TRIGGER)) return { readings, captures, result: worstOf(readings), staged: true };
      for (const scale of scales.slice(1)) readings.push({ size: size.text, scale, result: await analyse(cap.dir, scale, size) });
    } else for (const scale of scales) readings.push({ size: size.text, scale, result: await analyse(cap.dir, scale, size) });
    first = false;
  }
  return { readings, captures, result: worstOf(readings), staged };
}

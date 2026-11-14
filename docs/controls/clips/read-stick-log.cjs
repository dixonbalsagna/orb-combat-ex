// Reads a black-box first-play file (rawRightStick + the replay's stick words) the way the strike reader sees them. node docs/controls/clips/read-stick-log.cjs <file.json>. Prints counts only; the file stays private.
const fs = require("fs");
const d = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const S = d.rawRightStick.samples;   // [tick, ms, x, y]
const mag = (x, y) => Math.hypot(x, y);
// excursions: out while raw magnitude >= 0.25 (the dead zone); the closing sample is the first one under it
const ex = [];
let cur = null;
for (const [t, ms, x, y] of S) {
  const m = mag(x, y);
  if (m >= 0.25) {
    if (!cur) cur = { t0: t, ms0: ms, peak: 0, peakT: t, peakXY: [x, y], cross: null, samples: [] };
    cur.samples.push([t, m, x, y]);
    if (m > cur.peak) { cur.peak = m; cur.peakT = t; cur.peakXY = [x, y]; }
    if (cur.cross === null && m >= 0.70) cur.cross = t;
    cur.t1 = t; cur.ms1 = ms;
  } else if (cur) { cur.tEnd = t; ex.push(cur); cur = null; }
}
if (cur) { cur.tEnd = cur.t1; ex.push(cur); }
// replay word 2
const W = [];
for (const r of d.replay.inputs) if (r.length >= 5) {
  const w = r[4];
  W.push({ t: r[0], held: w & 1, start: (w >> 1) & 1, rel: (w >> 2) & 1, cancel: (w >> 3) & 1, dir: (w >> 4) & 7, level: (w >> 7) & 3, mask: (w >> 9) & 15, aim: (w >> 13) & 31, lag: (w >> 18) & 15, brace: (w >> 22) & 1 });
}
const starts = W.filter((x) => x.start), rels = W.filter((x) => x.rel), cancels = W.filter((x) => x.cancel);
console.log("raw samples", S.length, "excursions (raw >= 0.25):", ex.length);
const dur = (e) => e.tEnd - e.t0;
const reached = ex.filter((e) => e.cross !== null);
const never = ex.filter((e) => e.cross === null);
console.log("reached the request line (raw 0.70):", reached.length, " never reached it:", never.length);
const hist = (arr, edges) => { const h = new Array(edges.length + 1).fill(0); for (const v of arr) { let i = 0; while (i < edges.length && v >= edges[i]) i++; h[i]++; } return h; };
console.log("peak of the excursions that never reached 0.70, bins <0.35,<0.45,<0.55,<0.65,<0.70:", hist(never.map((e) => e.peak), [0.35, 0.45, 0.55, 0.65, 0.70]).slice(0, 5).join(" "));
console.log("durations of those that reached it (ticks out, bins <6,<12,<24,<30,<50,<90,more):", hist(reached.map(dur), [6, 12, 24, 30, 50, 90]).join(" "));
// match each reached excursion to a replay start inside [cross-1, tEnd+2]
let matched = 0, unmatched = [];
for (const e of reached) {
  const s = starts.filter((x) => x.t >= e.cross - 1 && x.t <= e.tEnd + 12);
  e.start = s[0] || null; e.rel = rels.filter((x) => x.t >= e.cross && x.t <= e.tEnd + 14)[0] || null;
  if (e.start) matched++; else unmatched.push(e);
}
console.log("reached excursions with a request (rsStart) in the replay:", matched, " without:", unmatched.length);
console.log("starts", starts.length, "releases", rels.length, "cancels", cancels.length, "(word-2 rows", W.length + ")");
// by layer
const byMask = {};
for (const s of starts) byMask[s.mask] = (byMask[s.mask] || 0) + 1;
console.log("starts by layer mask (0 none, 1 LB, 2 RB, 8 LT, 10 kite):", JSON.stringify(byMask));
// holds: reached excursions out longer than 12 ticks, by layer, whether a release followed and at what level
const holds = reached.filter((e) => dur(e) > 12 && e.start);
const rows = holds.map((e) => ({ layer: e.start.mask, out: dur(e), release: e.rel ? { level: e.rel.level, t: e.rel.t - e.start.t } : null }));
const sum = {};
for (const r of rows) { const k = "layer " + r.layer; sum[k] = sum[k] || { n: 0, released: 0, levels: [0, 0, 0, 0], outs: [] }; sum[k].n++; if (r.release) { sum[k].released++; sum[k].levels[r.release.level]++; } sum[k].outs.push(r.out); }
for (const k in sum) console.log(k, "holds", sum[k].n, "with a release edge", sum[k].released, "release levels 0/1/2/3:", sum[k].levels.join("/"), "ticks out:", sum[k].outs.sort((a, b) => a - b).join(","));
// flicks: reached, out <= 12
const flicks = reached.filter((e) => dur(e) <= 12);
console.log("flicks (out 12 ticks or less):", flicks.length, " with a request:", flicks.filter((e) => e.start).length, " layers:", JSON.stringify(flicks.reduce((a, e) => { const m = e.start ? e.start.mask : "none"; a[m] = (a[m] || 0) + 1; return a; }, {})));
// timing: ticks from first sample over 0.25 to crossing, and crossing to start
const ramp = reached.map((e) => e.cross - e.t0).sort((a, b) => a - b);
const lat = reached.filter((e) => e.start).map((e) => e.start.t - e.cross).sort((a, b) => a - b);
const q = (a, p) => a[Math.min(a.length - 1, Math.floor(p * a.length))];
console.log("ticks from leaving the dead zone to the request line: median", q(ramp, 0.5), "p90", q(ramp, 0.9), " | crossing to rsStart: median", q(lat, 0.5), "max", lat[lat.length - 1]);
// releases: ticks from the stick returning (below dead zone) to the release edge
const relLat = reached.filter((e) => e.rel).map((e) => e.rel.t - e.tEnd).sort((a, b) => a - b);
console.log("stick back under the dead zone to the release edge (ticks): median", q(relLat, 0.5), "min", relLat[0], "max", relLat[relLat.length - 1], "n", relLat.length);
// unmatched detail
console.log("excursions that reached the line but made no request: (t, out, peak):", unmatched.slice(0, 20).map((e) => [e.t0, dur(e), +e.peak.toFixed(2)].join("/")).join("  "));
// near misses
console.log("near misses (peak 0.55 to 0.70, no request line): ", never.filter((e) => e.peak >= 0.55).length, "of", never.length, "; with out > 6 ticks:", never.filter((e) => e.peak >= 0.55 && dur(e) > 6).length);
// directions of reached excursions (screen quadrants)
const quad = (x, y) => (Math.abs(y) >= Math.abs(x)) ? (y > 0 ? "up" : "down") : (x > 0 ? "right" : "left");
console.log("peak direction of the reached ones (y as logged):", JSON.stringify(reached.reduce((a, e) => { const k = quad(e.peakXY[0], e.peakXY[1]); a[k] = (a[k] || 0) + 1; return a; }, {})));
// rest drift
const rest = S.filter((s) => mag(s[2], s[3]) < 0.25);
console.log("rest samples:", rest.length, "max magnitude at rest", Math.max(...rest.map((s) => mag(s[2], s[3]))).toFixed(3), "mean", (rest.reduce((a, s) => a + mag(s[2], s[3]), 0) / rest.length).toFixed(3));
// pad answers: counts of rs releases by level and mask
const rl = {};
for (const r of rels) { const k = "mask" + r.mask + " level" + r.level; rl[k] = (rl[k] || 0) + 1; }
console.log("release edges by layer and level:", JSON.stringify(rl));
console.log("--- timeline of the stick (seconds into the match, layer, ticks out, peak, release level) ---");
for (const e of reached) console.log((e.t0 / 60).toFixed(0).padStart(4) + "s  layer " + String(e.start ? e.start.mask : "-").padEnd(2) + " out " + String(dur(e)).padStart(3) + "  peak " + e.peak.toFixed(2) + "  release " + (e.rel ? "level " + e.rel.level : "none"));
const ticksTotal = d.replay.ticks;
console.log("match ticks", ticksTotal, "(" + (ticksTotal / 3600).toFixed(1) + " min)");
console.log("--- excursions with more than one request, or a release before the stick came back ---");
for (const e of reached) {
  const ss = starts.filter((x) => x.t >= e.t0 && x.t <= e.tEnd + 2);
  const rr = rels.filter((x) => x.t >= e.t0 && x.t <= e.tEnd + 3);
  // dips: samples between cross and end with magnitude < 0.51 but >= 0.25
  const dips = e.samples.filter((s) => s[0] > e.cross && s[1] < 0.51).length;
  if (ss.length > 1 || rr.length > 1 || dips > 0 && dur(e) > 12) console.log("t=" + (e.t0 / 60).toFixed(1) + "s out " + dur(e) + " starts " + ss.length + " releases " + rr.length + " ticks under raw 0.51 inside: " + dips + " layer " + (e.start ? e.start.mask : "-"));
}
const tot = reached.reduce((a, e) => a + starts.filter((x) => x.t >= e.t0 && x.t <= e.tEnd + 2).length, 0);
console.log("starts inside the excursions:", tot, "of", starts.length);

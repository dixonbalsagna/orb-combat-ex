// Reads a black-box first-play file for the beam's aim and charge feel: how still the aim is while the stick is held at the rim, what the
// release does to it, how fast the stick springs back, and how long the charge held in ticks against milliseconds.
// node docs/controls/clips/read-orb-aim.cjs <file.json>. Prints counts only (nothing of the samples is written); the file stays private.
const fs = require("fs");
const d = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const S = d.rawRightStick.samples;          // [tick, ms, x, y]  (y as the pad reports it: down is positive)
const DEAD = 0.25, ON = 0.6, OFF = 0.35, QUANT = 16;
const mag = (a) => Math.hypot(a[2], a[3]);
const defl = (m) => (m <= DEAD ? 0 : Math.round(Math.min(1, (m - DEAD) / (1 - DEAD)) * QUANT) / QUANT);
const ang = (a) => Math.atan2(-a[3], a[2]) * 180 / Math.PI;          // y up, degrees, counter-clockwise from right
const wrap = (x) => ((x + 540) % 360) - 180;
const cmean = (arr) => { let sx = 0, sy = 0; for (const a of arr) { sx += Math.cos(a * Math.PI / 180); sy += Math.sin(a * Math.PI / 180); } return Math.atan2(sy, sx) * 180 / Math.PI; };
const sdev = (arr, m) => Math.sqrt(arr.reduce((t, a) => t + wrap(a - m) ** 2, 0) / arr.length);
const q = (a, p) => { a = a.filter((v) => v != null).sort((x, y) => x - y); return a.length ? a[Math.min(a.length - 1, Math.floor(p * a.length))] : null; };
const f1 = (v) => (v == null ? "-" : (+v).toFixed(1));
// holds as the strike reader sees them: down at deflection >= ON, up under OFF
const holds = []; let cur = null, down = false;
for (let i = 0; i < S.length; i++) {
  const a = S[i], r = defl(mag(a));
  const was = down;
  if (!down && r >= ON) down = true; else if (down && r < OFF) down = false;
  if (down && !was) cur = { i0: i, pts: [a], t0: a[0], ms0: a[1] };
  else if (down && cur) cur.pts.push(a);
  else if (!down && was && cur) { cur.i1 = i; cur.t1 = a[0]; cur.ms1 = a[1]; cur.after = a; holds.push(cur); cur = null; }
}
// the replay's stick words (pack2 rows only exist where it changed)
const W = [];
for (const r of d.replay.inputs) if (r.length >= 5) {
  const w = r[4];
  W.push({ t: r[0], held: w & 1, start: (w >> 1) & 1, rel: (w >> 2) & 1, cancel: (w >> 3) & 1, dir: (w >> 4) & 7, level: (w >> 7) & 3, mask: (w >> 9) & 15, aim: (w >> 13) & 31 });
}
console.log("holds (raw 0.70 up to 0.51 down):", holds.length, " replay stick rows:", W.length, " starts", W.filter((x) => x.start).length, "releases", W.filter((x) => x.rel).length, "cancels", W.filter((x) => x.cancel).length);
// ticks against ms
const tickms = holds.map((h) => ({ ticks: h.t1 - h.t0, ms: h.ms1 - h.ms0 }));
const ratio = tickms.filter((x) => x.ms > 200).map((x) => (x.ticks * 16.667) / x.ms);
console.log("ticks*16.67 / ms over the holds longer than 200 ms: p10", f1(q(ratio, 0.1)), "p50", f1(q(ratio, 0.5)), "p90", f1(q(ratio, 0.9)), "(1.0 means the sim ran in step with the clock; lower means the sim ticked slower than real time)");
// the rim: the plateau, the samples at 0.85 of the hold's own rim, after the first 40 ms
const rows = [];
for (const h of holds) {
  const ms = h.pts.map(mag), rim = q(ms, 0.8);
  const plat = h.pts.filter((a) => mag(a) >= 0.85 * rim && a[1] - h.ms0 >= 40);
  if (plat.length < 8) { rows.push({ h, short: true, dur: h.ms1 - h.ms0 }); continue; }
  const as = plat.map(ang), m = cmean(as);
  const early = cmean(as.slice(0, Math.max(1, Math.floor(plat.length / 4)))), late = cmean(as.slice(-Math.max(1, Math.floor(plat.length / 4))));
  let rangeLo = 0, rangeHi = 0; for (const a of as) { const dd = wrap(a - m); if (dd < rangeLo) rangeLo = dd; if (dd > rangeHi) rangeHi = dd; }
  // sector changes: raw 32 sectors, and with a hysteresis that needs a quarter of a sector past the boundary
  const sec = (a) => Math.floor((((a % 360) + 360) % 360) / 11.25 + 0.5) % 32;
  let flipsRaw = 0, flipsHys = 0, sh = sec(as[0]), sr = sec(as[0]);
  for (const a of as) {
    const s = sec(a); if (s !== sr) { flipsRaw++; sr = s; }
    if (Math.abs(wrap(a - sh * 11.25)) > 11.25 / 2 + 11.25 * 0.25) { sh = s; flipsHys++; }
  }
  const lastPlat = plat[plat.length - 1];
  const retMs = h.after[1] - lastPlat[1];
  const angAtOff = ang(h.after), angBeforeOff = ang(h.pts[h.pts.length - 1]);
  // bounce: after crossing under OFF, within 200 ms, any sample past 0.15 leaning away from the rim direction
  let bounce = 0;
  for (let k = h.i1; k < S.length && S[k][1] - h.after[1] < 200; k++) { const mm = mag(S[k]); if (mm > 0.15 && Math.cos((ang(S[k]) - m) * Math.PI / 180) < -0.3) bounce = Math.max(bounce, mm); }
  rows.push({ h, plat: plat.length, dur: h.ms1 - h.ms0, ticks: h.t1 - h.t0, sd: sdev(as, m), range: rangeHi - rangeLo, drift: wrap(late - early), flipsRaw, flipsHys, retMs, errOff: wrap(angAtOff - m), errBefore: wrap(angBeforeOff - m), rim, bounce, m });
}
const good = rows.filter((r) => !r.short);
console.log("holds with a steady rim phase:", good.length, " (too short for one:", rows.length - good.length + ")");
const dist = (name, key) => console.log(name.padEnd(56), [0.1, 0.5, 0.9, 1].map((p) => f1(q(good.map((r) => key(r)), p))).join(" / "));
console.log("-- p10 / p50 / p90 / max --");
dist("rim magnitude (raw, p80 of the hold)", (r) => r.rim);
dist("hold length, ms", (r) => r.dur);
dist("aim sd on the rim phase, degrees", (r) => r.sd);
dist("aim range on the rim phase (hi - lo), degrees", (r) => r.range);
dist("aim drift early to late, degrees (abs)", (r) => Math.abs(r.drift));
dist("raw 32-sector changes while the rim is held", (r) => r.flipsRaw);
dist("... with a quarter-sector hysteresis", (r) => r.flipsHys);
dist("ms from the last rim sample to under OFF (spring back)", (r) => r.retMs);
dist("angle error of the sample that falls under OFF, deg", (r) => Math.abs(r.errOff));
dist("angle error of the last sample still down, deg", (r) => Math.abs(r.errBefore));
console.log("holds with a bounce past the centre (> 0.15 leaning away within 200 ms):", good.filter((r) => r.bounce > 0).length, "of", good.length, " biggest", f1(Math.max(0, ...good.map((r) => r.bounce))));
console.log("holds whose aim moved more than 20 deg on the rim (a re-aim):", good.filter((r) => r.range > 20).length, " more than 45:", good.filter((r) => r.range > 45).length);
console.log("holds with any raw sector change on the rim:", good.filter((r) => r.flipsRaw > 0).length, " with hysteresis:", good.filter((r) => r.flipsHys > 0).length);
// the ladder: holds that reached each rung in the sim's tick count and by the clock
console.log("holds reaching 12 / 30 / 54 ticks:", [12, 30, 54].map((t) => rows.filter((r) => (r.h.t1 - r.h.t0) >= t).length).join(" / "), "  by the clock (200 / 500 / 900 ms):", [200, 500, 900].map((m) => rows.filter((r) => r.dur >= m).length).join(" / "));
const tk = rows.map((r) => r.h.t1 - r.h.t0), bins = [0, 6, 12, 20, 30, 42, 54, 72, 100, 1e9];
const hh = Array(bins.length - 1).fill(0); for (const v of tk) for (let i = 0; i < bins.length - 1; i++) if (v >= bins[i] && v < bins[i + 1]) hh[i]++;
console.log("hold length in ticks, bins", bins.slice(0, -1).join("/"), "=>", hh.join(" "));
// the replay's aim at the release against the rim direction
const errs = []; let matched = 0;
for (const r of good) {
  const rel = W.find((x) => x.rel && x.t >= r.h.t1 - 3 && x.t <= r.h.t1 + 8);
  if (!rel) continue; matched++;
  errs.push(Math.abs(wrap(rel.aim * 11.25 - r.m)));
}
console.log("releases matched to a hold:", matched, " |aim in the release row - rim direction| deg p10/50/90/max:", [0.1, 0.5, 0.9, 1].map((p) => f1(q(errs, p))).join(" / "));
const cancels = W.filter((x) => x.cancel).length, starts = W.filter((x) => x.start).length, rels = W.filter((x) => x.rel).length;
console.log("starts", starts, "releases", rels, "cancels", cancels, " => started and neither thrown nor cancelled:", starts - rels - cancels);

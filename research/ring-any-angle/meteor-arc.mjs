// The meteor's arc, as closed forms: the reference for docs/world/ring-any-angle/meteor-arc.md and for proto v2's arcBuild, arcClock, arcQ and arcAt.
// node research/ring-any-angle/meteor-arc.mjs           the table by tier, the shape's numbers, the checks
// Nothing here needs more than + - * / sqrt, sin, cos and atan2, so it ports to the sim's float64 maths. Heights are above sea level; the plane is the great circle's, its origin the planet's centre.

const CIRC = 153600, RP = CIRC / (2 * Math.PI), RAD = Math.PI / 180;

// The path: a quadratic Bezier, which is exactly a parabola, from the launcher's ground to the landing's ground.
export function build(D, top, g0, gL, lean = 0, R = RP) {
  const ph = D / R, a0 = R + g0, a1 = R + gL, bx = Math.sin(ph / 2), by = Math.cos(ph / 2), x1 = a1 * Math.sin(ph), y1 = a1 * Math.cos(ph), mx = x1 / 2, my = (a0 + y1) / 2, at = mx * bx + my * by, up = 2 * (R + g0 + top) - at - at;
  return { y0: a0, cx: mx + up * bx + x1 * lean / 2, cy: my + up * by + (y1 - a0) * lean / 2, x1, y1, ph, R };
}
export const leaves = (c) => Math.atan2(c.cy - c.y0, c.cx) / RAD;
export function arrives(c) { const dx = c.x1 - c.cx, dy = c.y1 - c.cy, sn = Math.sin(c.ph), cs = Math.cos(c.ph); return Math.atan2(-(dx * sn + dy * cs), dx * cs - dy * sn) / RAD; }
// The carry that makes him leave at `deg` above the ground. Solved once per tier, in data; the sim needn't run this.
export function carryFor(top, g0, deg, lean = 0, R = RP) { let lo = 0.02 * top, hi = 8 * top; for (let i = 0; i < 40; i++) { const m = (lo + hi) / 2; if (leaves(build(m, top, g0, g0, lean, R)) > deg) lo = m; else hi = m; } return (lo + hi) / 2; }
// The clock: a cubic from q 0 to q 1, leaving at slope s0, through q 0.5 at `crest`, arriving at whatever slope that gives, kept to where a cubic can't run backward (s0^2 + s1^2 <= 9). q linear in time would be a thrown ball.
export function clock(s0, crest) { const a = crest ** 3 - 2 * crest ** 2 + crest, b = -2 * crest ** 3 + 3 * crest ** 2, c = crest ** 3 - crest ** 2; return { s0, s1: Math.max(0.2, Math.min(Math.sqrt(9 - s0 * s0), (0.5 - a * s0 - b) / c)) }; }
export const q = (k, t) => (t ** 3 - 2 * t ** 2 + t) * k.s0 + (-2 * t ** 3 + 3 * t ** 2) + (t ** 3 - t ** 2) * k.s1;
export const dq = (k, t) => (3 * t ** 2 - 4 * t + 1) * k.s0 + (-6 * t ** 2 + 6 * t) + (3 * t ** 2 - 2 * t) * k.s1;
export function at(c, u) { const v = 1 - u, x = 2 * v * u * c.cx + u * u * c.x1, y = v * v * c.y0 + 2 * v * u * c.cy + u * u * c.y1; return { x, y, s: Math.atan2(x, y) * c.R, h: Math.hypot(x, y) - c.R }; }

const TIERS = [['1', 700, 1.28], ['2', 2500, 2.42], ['3', 5000, 3.42], ['4, not a meteor', 9900, 4.81], ['4, the meteor', 16400, 6.2]];
const LEAVE = 1.25, CREST = 3.5 / 6.2;

function speeds(c, k, secs) { const d = (t) => { const e = 1e-4, a = at(c, q(k, t - e)), b = at(c, q(k, t + e)); return Math.hypot(b.x - a.x, b.y - a.y) / (2 * e * secs); }; let min = 1e9, tMin = 0; for (let i = 1; i < 620; i++) { const t = i / 620, v = d(t); if (v < min) { min = v; tMin = t; } } return { leave: d(1e-3), slowest: min, at: tMin * secs, arrive: d(1 - 1e-3) }; }

if (process.argv[1] && process.argv[1].replace(/\\/g, '/').endsWith('meteor-arc.mjs')) {
  console.log('| Lower tier | Apex | Carry | Round a Whole ring | Time | Leaves at | Comes in at | Leaves at u/s | Slowest u/s | Arrives at u/s |\n| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
  for (const [n, top, secs] of TIERS) { const D = carryFor(top, 0, 60), c = build(D, top, 0, 0), k = clock(LEAVE, CREST), v = speeds(c, k, secs); console.log(`| ${n} | ${top.toLocaleString()} | ${Math.round(D).toLocaleString()} | ${(D / CIRC * 360).toFixed(1)}° | ${secs} s | ${leaves(c).toFixed(0)}° | ${arrives(c).toFixed(0)}° | ${Math.round(v.leave).toLocaleString()} | ${Math.round(v.slowest).toLocaleString()} | ${Math.round(v.arrive).toLocaleString()} |`); }
  const D = carryFor(16400, 0, 60), c = build(D, 16400, 0, 0), k = clock(LEAVE, CREST);
  console.log('\nThe clock: s0', k.s0, 's1', k.s1.toFixed(3));
  console.log('Time above a share of the height, top row:'); for (const share of [0.5, 0.9, 0.99]) { let n = 0; for (let i = 0; i < 6200; i++) if (at(c, q(k, i / 6200)).h >= share * 16400) n++; console.log(`  ${share}: ${(n / 1000).toFixed(2)} s`); }
  // Checks: one curve, whatever the sliders say
  let fails = 0; const ok = (b, w) => { if (!b) { fails++; console.log('FAIL', w); } };
  for (const top of [700, 2500, 5000, 9900, 16400, 24000]) for (const deg of [45, 60, 75, 85]) for (const lean of [-0.3, 0, 0.3]) for (const [s0, cr] of [[0.8, 2.6 / 6.2], [1.25, CREST], [2, 4.4 / 6.2], [1.25, 2.6 / 6.2], [2, 2.6 / 6.2]]) for (const g of [[0, 0], [900, 0], [0, 900]]) {
    const D2 = carryFor(top, g[0], deg, lean), c2 = build(D2, top, g[0], g[1], lean), k2 = clock(s0, cr); let last = at(c2, 0), lastDir = null, maxTurn = 0, rev = false;
    for (let i = 1; i <= 600; i++) { const p = at(c2, q(k2, i / 600)); const dx = p.x - last.x, dy = p.y - last.y; if (p.s < last.s - 1e-6) rev = true; if (dq(k2, i / 600) <= 0) rev = true; const dir = Math.atan2(dy, dx); if (lastDir !== null && Math.hypot(dx, dy) > 1e-6) { let a = Math.abs(dir - lastDir); if (a > Math.PI) a = 2 * Math.PI - a; maxTurn = Math.max(maxTurn, a); } lastDir = dir; last = p; }
    ok(!rev, `doubles back: top ${top} deg ${deg} lean ${lean} s0 ${s0} crest ${cr}`);
    ok(Math.abs(last.s - D2) < 1e-6 * Math.max(1, D2) + 1e-6 && Math.abs(last.h - g[1]) < 1e-6, `misses its landing: top ${top} deg ${deg}`);
    ok(maxTurn / RAD < 10, `turns ${(maxTurn / RAD).toFixed(1)} deg in a step: top ${top} deg ${deg} lean ${lean} s0 ${s0} crest ${cr}`);
  }
  console.log(fails ? `${fails} checks failed` : 'checks pass: lands exactly, never doubles back, no corner, on every slider setting tried');
  // Today's law, for the record: gravity 1,000, sideways speed times 0.55 a second and none on the climb, flat along the line (sim/core/fighter.gd stepLaunched); launchTravel scales the carry and doesn't change the shares. Share of the carry spent by the apex, and how he comes in
  console.log('\nToday\'s law:'); for (const [v, deg] of [[6600, 60], [7000, 60], [7000, 45], [5000, 45]]) { let x = 0, y = 0, vx = v * Math.cos(deg * RAD), vy = v * Math.sin(deg * RAD), xA = 0, peak = 0; const dt = 1 / 60, tr = []; for (let i = 0; i < 4000; i++) { vy -= 1000 * dt; vx *= Math.pow(0.55, dt); x += vx * dt; y += vy * dt; if (y > peak) { peak = y; xA = x; } tr.push(x); if (y <= 0 && i > 2) break; } console.log(`  ${v} at ${deg}: apex ${Math.round(peak)}, carry ${Math.round(x)}, ${Math.round(100 * xA / x)}% of the carry by the apex, comes in at ${Math.round(Math.atan2(-vy, vx) / RAD)}°`); }
  process.exit(fails ? 1 : 0);
}

// The quality range's crux, measured on gen 2: how far a drawn ground at one spacing sits from a sim ground at another. Reads planet 7's real gen 2
// ground at 64 units (gen2-p7-1352.bin, written by gen2_dump.gd.txt in a scratch copy) and resamples it to each spacing, as point samples at that grid's
// texels, then compares bilinear reads at random points on the planet. 64 is the finest here, so steps finer than that are missing: the worst cases are a floor.
// Also writes gen2-p7.pack, the same data small enough to inline in the proto.
//   node research/ring-any-angle/levels.mjs [bin]     (the bin isn't kept in the repo; levels.json holds the results)
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
const D = new URL('./', import.meta.url), BIN = process.argv[2] || new URL('gen2-p7-1352.bin', D);
if (!existsSync(BIN)) { console.log('no bin: bake it with gen2_dump.gd.txt'); process.exit(1); }
const raw = readFileSync(BIN), N0 = 1352, h0 = new Float64Array(N0 * N0), b0 = new Uint8Array(N0 * N0);
for (let o = 0; o < N0 * N0; o++) { h0[o] = raw.readInt16LE(o * 2); b0[o] = raw[N0 * N0 * 2 + o]; }
const octDec = (u, v) => { let x = u * 2 - 1, y = v * 2 - 1; const z = 1 - Math.abs(x) - Math.abs(y), t = Math.max(-z, 0); x += x >= 0 ? -t : t; y += y >= 0 ? -t : t; const l = Math.hypot(x, y, z); return [x / l, y / l, z / l]; };
const octEnc = (d) => { const s = Math.abs(d[0]) + Math.abs(d[1]) + Math.abs(d[2]); let x = d[0] / s, y = d[1] / s; if (d[2] < 0) { const ox = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1), oy = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1); x = ox; y = oy; } return [x * 0.5 + 0.5, y * 0.5 + 0.5]; };
function bil(H, N, d) { const e = octEnc(d), fx = e[0] * N - 0.5, fy = e[1] * N - 0.5, i = Math.max(0, Math.min(N - 2, Math.floor(fx))), j = Math.max(0, Math.min(N - 2, Math.floor(fy))), a = Math.min(1, Math.max(0, fx - i)), b = Math.min(1, Math.max(0, fy - j)), o = j * N + i; return (H[o] * (1 - a) + H[o + 1] * a) * (1 - b) + (H[o + N] * (1 - a) + H[o + N + 1] * a) * b; }
const RP = 153600 / (2 * Math.PI), SP = [64, 128, 256, 512], NS = { 64: 1352, 128: 676, 256: 338, 512: 169 }, MAPS = {};
for (const s of SP) { const N = NS[s]; if (N === N0) { MAPS[s] = h0; continue; } const H = new Float64Array(N * N); for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) H[j * N + i] = bil(h0, N0, octDec((i + 0.5) / N, (j + 0.5) / N)); MAPS[s] = H; }
let seed = 12345; const rnd = () => { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 4294967296; };
const norm = (a) => { const l = Math.hypot(a[0], a[1], a[2]); return [a[0] / l, a[1] / l, a[2] / l]; };
const pct = (a, q) => { const s = Float64Array.from(a).sort(); return s[Math.min(s.length - 1, Math.floor(q * s.length))]; };
const bioAt = (d) => { const e = octEnc(d), i = Math.max(0, Math.min(N0 - 1, Math.floor(e[0] * N0))), j = Math.max(0, Math.min(N0 - 1, Math.floor(e[1] * N0))); return b0[j * N0 + i]; };
// points: land only, ice apart (an ice edge would be a record, on any level). Each with a neighbour 300 units off (two fighters in a brawl) and 170 (a flat-out tick)
const pts = []; while (pts.length < 120000) { const q = norm([rnd() - 0.5, rnd() - 0.5, rnd() - 0.5]); if (bil(h0, N0, q) <= 0) continue; const a = norm([rnd() - 0.5, rnd() - 0.5, rnd() - 0.5]), t = norm([a[1] * q[2] - a[2] * q[1], a[2] * q[0] - a[0] * q[2], a[0] * q[1] - a[1] * q[0]]); const at = (u) => norm([q[0] + t[0] * u / RP, q[1] + t[1] * u / RP, q[2] + t[2] * u / RP]); const b = bioAt(q); pts.push({ q, near: at(300), step: at(170), ice: b === 5 || b === 6, mtn: b === 4 }); }
const out = { points: pts.length, table: {} };
for (const sim of SP) for (const view of SP) {
  if (sim === view) continue;
  const A = MAPS[sim], B = MAPS[view], NA = NS[sim], NB = NS[view], dl = (d) => bil(B, NB, d) - bil(A, NA, d);
  const row = (flt) => { const e = [], rel = [], st = []; for (const p of pts) { if (!flt(p)) continue; const v = dl(p.q); e.push(Math.abs(v)); rel.push(Math.abs(v - dl(p.near))); st.push(Math.abs(v - dl(p.step))); } const rms = (x) => Math.sqrt(x.reduce((s, y) => s + y * y, 0) / x.length); return { n: e.length, rms: rms(e), p99: pct(e, 0.99), worst: Math.max(...e), over75: e.filter((x) => x > 75).length / e.length, gap300rms: rms(rel), gap300p99: pct(rel, 0.99), tickRms: rms(st), tickP99: pct(st, 0.99) }; };
  out.table[`sim ${sim} view ${view}`] = { land: row((p) => !p.ice), mountains: row((p) => p.mtn), ice: row((p) => p.ice) };
}
writeFileSync(new URL('levels.json', D), JSON.stringify(out, null, 1));
const f = (x, d = 1) => x.toFixed(d).padStart(7);
console.log('how far the drawn ground sits from the sim ground, units; land, no ice (a fighter is 75 tall)\n' + 'pair'.padEnd(22) + '   rms    p99  worst  >75 |  across 300 u: rms p99 | per flat-out tick: rms p99 | mountains rms p99 worst | ice rms worst');
for (const [k, r] of Object.entries(out.table)) console.log(k.padEnd(22) + f(r.land.rms) + f(r.land.p99, 0) + f(r.land.worst, 0) + (r.land.over75 * 100).toFixed(2).padStart(6) + '%' + ' |' + f(r.land.gap300rms) + f(r.land.gap300p99, 0) + '        |' + f(r.land.tickRms) + f(r.land.tickP99, 0) + '          |' + f(r.mountains.rms) + f(r.mountains.p99, 0) + f(r.mountains.worst, 0) + '   |' + f(r.ice.rms) + f(r.ice.worst, 0));
// the pack: heights as row deltas, biomes as they are, gzip
const d = Buffer.alloc(N0 * N0 * 2); for (let o = 0; o < N0 * N0; o++) { const v = o % N0 === 0 ? h0[o] : h0[o] - h0[o - 1]; d.writeInt16LE(v, o * 2); }
const hi = Buffer.alloc(N0 * N0), lo = Buffer.alloc(N0 * N0); for (let o = 0; o < N0 * N0; o++) { hi[o] = d[o * 2 + 1]; lo[o] = d[o * 2]; }
const pack = gzipSync(Buffer.concat([lo, hi, raw.subarray(N0 * N0 * 2)]), { level: 9 });
writeFileSync(new URL('gen2-p7.pack', D), pack); console.log('pack', Math.round(pack.length / 1024), 'KB');

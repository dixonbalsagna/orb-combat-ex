// Frames of a raw reel file (press_lab.gd, strike_lab.gd, tools/anim_reel.gd) tiled into one PNG grid, to read a motion at a glance.
//   node render/anim/tools/rgb_sheet.mjs out.png in.rgb --cols 5 0 8 16 24 32 ...      (frame numbers; with --every N: every Nth frame from 0)
// A second input (--vs other.rgb) puts the same frame numbers of that clip under each row, for a before and after.
import { readFileSync, writeFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';
const a = process.argv.slice(2);
const out = a[0];
const inp = a[1];
let cols = 5, every = 0, vs = '';
const fr = [];
for (let i = 2; i < a.length; i++) {
  if (a[i] === '--cols') cols = Number(a[++i]);
  else if (a[i] === '--every') every = Number(a[++i]);
  else if (a[i] === '--vs') vs = a[++i];
  else fr.push(Number(a[i]));
}
const b = readFileSync(inp);
const w = b.readInt32LE(0), h = b.readInt32LE(4), n = b.readInt32LE(8);
const b2 = vs ? readFileSync(vs) : null;
const idx = every > 0 ? Array.from({ length: Math.ceil(n / every) }, (_, k) => k * every) : fr.filter(f => f < n);
const rows = Math.ceil(idx.length / cols);
const rowH = h * (b2 ? 2 : 1);
const W = w * cols, H = rowH * rows;
const raw = Buffer.alloc((W * 3 + 1) * H, 0);
for (let y = 0; y < H; y++) raw[y * (W * 3 + 1)] = 0;
const put = (src, f, cx, cy) => {
  for (let y = 0; y < h; y++) {
    const o = (cy * rowH + y) * (W * 3 + 1) + 1 + cx * w * 3;
    src.copy(raw, o, 12 + (f * h + y) * w * 3, 12 + (f * h + y + 1) * w * 3);
  }
};
idx.forEach((f, k) => {
  const cx = k % cols, cy = Math.floor(k / cols);
  put(b, f, cx, cy);
  if (b2) {
    const f2 = Math.min(f, b2.readInt32LE(8) - 1);
    for (let y = 0; y < h; y++) {
      const o = (cy * rowH + h + y) * (W * 3 + 1) + 1 + cx * w * 3;
      b2.copy(raw, o, 12 + (f2 * h + y) * w * 3, 12 + (f2 * h + y + 1) * w * 3);
    }
  }
});
const crcT = new Int32Array(256).map((_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c; });
const crc = buf => { let c = -1; for (const x of buf) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ -1) >>> 0; };
const chunk = (t, d) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([l, td, c]); };
const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 2;
writeFileSync(out, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
console.log(out, W + 'x' + H, idx.length + ' frames');

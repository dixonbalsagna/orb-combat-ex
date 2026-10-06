#!/usr/bin/env node
// Writes PLACEHOLDER Home Screen icons (192 and 512 pixels, plain PNG) to docs/perf/web-shell/icons/.
// A functional stand-in only: a dark tile with a ring (the planet) and one arc across it. Art replaces these; the manifest only needs the two files to exist at
// these names. Node built-ins only, deterministic (no clock, no random).
//   node docs/perf/tools/make-placeholder-icons.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { deflateSync } from 'node:zlib';

const out = join(dirname(fileURLToPath(import.meta.url)), '..', 'web-shell', 'icons');
mkdirSync(out, { recursive: true });

const crcTable = new Uint32Array(256).map((_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc = (buf) => { let c = 0xffffffff; for (const b of buf) c = crcTable[(c ^ b) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const c = Buffer.alloc(4); c.writeUInt32BE(crc(body));
  return Buffer.concat([len, body, c]);
}
function png(size, px) {
  const raw = Buffer.alloc((size * 3 + 1) * size);
  for (let y = 0; y < size; y++) {
    raw[y * (size * 3 + 1)] = 0;
    for (let x = 0; x < size; x++) { const [r, g, b] = px(x, y); const o = y * (size * 3 + 1) + 1 + x * 3; raw[o] = r; raw[o + 1] = g; raw[o + 2] = b; }
  }
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4); ihdr[8] = 8; ihdr[9] = 2;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}
// Everything stays inside the central 80% so a round or squircle mask cannot cut it.
function tile(size) {
  const c = size / 2, R = size * 0.34, T = size * 0.045;
  return (x, y) => {
    const dx = x + 0.5 - c, dy = y + 0.5 - c, d = Math.hypot(dx, dy);
    const bg = [11, 15, 26];
    if (Math.abs(d - R) < T) return [232, 236, 242];
    const onBand = Math.abs(dy + dx * 0.18) < T * 0.7 && d < R * 1.25 && d > R * 0.6;
    return onBand ? [255, 176, 64] : bg;
  };
}
for (const s of [192, 512]) writeFileSync(join(out, `icon-${s}.png`), png(s, tile(s)));
console.log('wrote icon-192.png and icon-512.png to ' + out);

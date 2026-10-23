// A tiny RGB image with a PNG writer (node:zlib only) and a 5x7 bitmap font for labels. Rendering only: nothing here
// feeds a generator.
import { deflateSync } from 'node:zlib';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const CRC = new Uint32Array(256);
for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; CRC[n] = c >>> 0; }
function crc32(buf) { let c = 0xffffffff; for (let i = 0; i < buf.length; i++) c = CRC[(c ^ buf[i]) & 0xff] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}

export class Img {
  constructor(w, h, bg = [0, 0, 0]) {
    this.w = w; this.h = h; this.d = new Uint8Array(w * h * 3);
    if (bg) this.fill(0, 0, w, h, bg);
  }
  set(x, y, c) {
    x |= 0; y |= 0;
    if (x < 0 || y < 0 || x >= this.w || y >= this.h) return;
    const i = (y * this.w + x) * 3; this.d[i] = c[0]; this.d[i + 1] = c[1]; this.d[i + 2] = c[2];
  }
  blend(x, y, c, a) {
    x |= 0; y |= 0;
    if (x < 0 || y < 0 || x >= this.w || y >= this.h) return;
    const i = (y * this.w + x) * 3;
    for (let k = 0; k < 3; k++) this.d[i + k] = Math.round(this.d[i + k] + (c[k] - this.d[i + k]) * a);
  }
  get(x, y) { const i = (y * this.w + x) * 3; return [this.d[i], this.d[i + 1], this.d[i + 2]]; }
  fill(x0, y0, w, h, c) { for (let y = y0; y < y0 + h; y++) for (let x = x0; x < x0 + w; x++) this.set(x, y, c); }
  blit(src, ox, oy) {
    for (let y = 0; y < src.h; y++) for (let x = 0; x < src.w; x++) {
      const X = ox + x, Y = oy + y;
      if (X < 0 || Y < 0 || X >= this.w || Y >= this.h) continue;
      const i = (y * src.w + x) * 3, j = (Y * this.w + X) * 3;
      this.d[j] = src.d[i]; this.d[j + 1] = src.d[i + 1]; this.d[j + 2] = src.d[i + 2];
    }
  }
  // Downscale by an integer factor (box filter), for contact sheets.
  shrink(f) {
    const o = new Img(Math.floor(this.w / f), Math.floor(this.h / f), null);
    for (let y = 0; y < o.h; y++) for (let x = 0; x < o.w; x++) {
      let r = 0, g = 0, b = 0;
      for (let dy = 0; dy < f; dy++) for (let dx = 0; dx < f; dx++) { const i = ((y * f + dy) * this.w + x * f + dx) * 3; r += this.d[i]; g += this.d[i + 1]; b += this.d[i + 2]; }
      const n = f * f; o.set(x, y, [r / n, g / n, b / n]);
    }
    return o;
  }
  text(x, y, str, scale = 2, c = [255, 255, 255]) {
    let cx = x;
    for (const ch of String(str).toUpperCase()) {
      const g = GLYPH[ch] || GLYPH['?'];
      for (let r = 0; r < 7; r++) for (let b = 0; b < 5; b++)
        if (g[r] & (16 >> b)) this.fill(cx + b * scale, y + r * scale, scale, scale, c);
      cx += 6 * scale;
    }
    return cx;
  }
  save(path) {
    mkdirSync(dirname(path), { recursive: true });
    const raw = Buffer.alloc((this.w * 3 + 1) * this.h);
    for (let y = 0; y < this.h; y++) {
      raw[y * (this.w * 3 + 1)] = 0;
      Buffer.from(this.d.buffer, y * this.w * 3, this.w * 3).copy(raw, y * (this.w * 3 + 1) + 1);
    }
    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(this.w, 0); ihdr.writeUInt32BE(this.h, 4); ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
    writeFileSync(path, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]));
  }
}
export function textWidth(str, scale = 2) { return String(str).length * 6 * scale; }

const B = (s) => s.split(',').map((r) => parseInt(r, 2));
const GLYPH = {
  A: B('01110,10001,10001,11111,10001,10001,10001'), B: B('11110,10001,10001,11110,10001,10001,11110'),
  C: B('01110,10001,10000,10000,10000,10001,01110'), D: B('11100,10010,10001,10001,10001,10010,11100'),
  E: B('11111,10000,10000,11110,10000,10000,11111'), F: B('11111,10000,10000,11110,10000,10000,10000'),
  G: B('01110,10001,10000,10111,10001,10001,01111'), H: B('10001,10001,10001,11111,10001,10001,10001'),
  I: B('01110,00100,00100,00100,00100,00100,01110'), J: B('00111,00010,00010,00010,00010,10010,01100'),
  K: B('10001,10010,10100,11000,10100,10010,10001'), L: B('10000,10000,10000,10000,10000,10000,11111'),
  M: B('10001,11011,10101,10101,10001,10001,10001'), N: B('10001,10001,11001,10101,10011,10001,10001'),
  O: B('01110,10001,10001,10001,10001,10001,01110'), P: B('11110,10001,10001,11110,10000,10000,10000'),
  Q: B('01110,10001,10001,10001,10101,10010,01101'), R: B('11110,10001,10001,11110,10100,10010,10001'),
  S: B('01111,10000,10000,01110,00001,00001,11110'), T: B('11111,00100,00100,00100,00100,00100,00100'),
  U: B('10001,10001,10001,10001,10001,10001,01110'), V: B('10001,10001,10001,10001,10001,01010,00100'),
  W: B('10001,10001,10001,10101,10101,10101,01010'), X: B('10001,10001,01010,00100,01010,10001,10001'),
  Y: B('10001,10001,10001,01010,00100,00100,00100'), Z: B('11111,00001,00010,00100,01000,10000,11111'),
  0: B('01110,10001,10011,10101,11001,10001,01110'), 1: B('00100,01100,00100,00100,00100,00100,01110'),
  2: B('01110,10001,00001,00010,00100,01000,11111'), 3: B('11111,00010,00100,00010,00001,10001,01110'),
  4: B('00010,00110,01010,10010,11111,00010,00010'), 5: B('11111,10000,11110,00001,00001,10001,01110'),
  6: B('00110,01000,10000,11110,10001,10001,01110'), 7: B('11111,00001,00010,00100,01000,01000,01000'),
  8: B('01110,10001,10001,01110,10001,10001,01110'), 9: B('01110,10001,10001,01111,00001,00010,01100'),
  ' ': B('0,0,0,0,0,0,0'), '.': B('0,0,0,0,0,01100,01100'), ',': B('0,0,0,0,01100,00100,01000'),
  ':': B('0,01100,01100,0,01100,01100,0'), '%': B('11000,11001,00010,00100,01000,10011,00011'),
  '-': B('0,0,0,11111,0,0,0'), '(': B('00010,00100,01000,01000,01000,00100,00010'),
  ')': B('01000,00100,00010,00010,00010,00100,01000'), '/': B('0,00001,00010,00100,01000,10000,0'),
  '+': B('0,00100,00100,11111,00100,00100,0'), '=': B('0,0,11111,0,11111,0,0'),
  '>': B('01000,00100,00010,00001,00010,00100,01000'), '<': B('00010,00100,01000,10000,01000,00100,00010'),
  '#': B('01010,01010,11111,01010,11111,01010,01010'), '?': B('01110,10001,00001,00010,00100,0,00100'),
  "'": B('00100,00100,01000,0,0,0,0'), ';': B('0,01100,01100,0,01100,00100,01000'), '&': B('01100,10010,10100,01000,10101,10010,01101'),
};

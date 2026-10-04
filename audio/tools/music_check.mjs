#!/usr/bin/env node
// Checks a finished music file before it goes into the game (docs/audio/suno-direction.md, section 6).
//
//   node audio/tools/music_check.mjs FILE.wav [--bars 8] [--target -16] [--json] [--write-sidecar]
//
// Reads a WAV (PCM 16, 24 or 32 bit, or 32-bit float; mono or stereo; any sample rate) and reports:
//   * the format (a dev check that the file matches the hand-back spec),
//   * integrated loudness in LUFS (ITU-R BS.1770-4 K-weighting with the two gates) and the gain that would bring it to
//     the target (default -16 LUFS), plus an approximate true peak (4x oversampling),
//   * the tempo, estimated from the onset pattern (the half and double readings are shown, because they are easy to
//     mix up), and how steady it is across the file,
//   * the best loop points on the bar grid: a downbeat offset, and a loop of N bars whose end meets its start with
//     the smallest jump.
//   * a SHA-256 checksum of the file exactly as it is on disk (the record of the original download), and the list of
//     chunks in it, so we can see whether the download's metadata (LIST, id3 and similar) is present. The tool never
//     writes to the audio file. With --write-sidecar it adds the checksum and the check date to the sidecar text file
//     next to it (FILE.txt), inside a marked block that it replaces on each run (Legal's origin record, RL-071). The block
//     also copies the original's metadata (LIST/INFO tags, id3 and any other chunk), because the shipped copy may not carry it.
// It is a dev tool: standard library only, nothing ships, and every number is an estimate to check by ear. MP3 is not
// read; export WAV from Suno.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { createHash } from "node:crypto";

const args = process.argv.slice(2);
const file = args.find((a) => !a.startsWith("--") && !/^-?\d/.test(a));
const opt = (name, def) => {
  const i = args.indexOf("--" + name);
  return i >= 0 && args[i + 1] !== undefined ? Number(args[i + 1]) : def;
};
const asJson = args.includes("--json");
const writeSidecar = args.includes("--write-sidecar");
if (!file) {
  console.error("usage: node audio/tools/music_check.mjs FILE.wav [--bars 8] [--target -16] [--json]");
  process.exit(2);
}

// ---- WAV
function readWav(path) {
  const b = readFileSync(path);
  if (b.toString("ascii", 0, 4) !== "RIFF" || b.toString("ascii", 8, 12) !== "WAVE") throw new Error("not a RIFF/WAVE file (export WAV, not MP3)");
  let pos = 12, fmt = null, data = null;
  const chunks = [];
  const meta = [];
  while (pos + 8 <= b.length) {
    const id = b.toString("ascii", pos, pos + 4), size = b.readUInt32LE(pos + 4), body = pos + 8;
    chunks.push(`${id}:${size}`);
    if (id !== "fmt " && id !== "data") meta.push({ id, body: b.subarray(body, Math.min(body + size, b.length)) });
    if (id === "fmt ") {
      fmt = { tag: b.readUInt16LE(body), ch: b.readUInt16LE(body + 2), rate: b.readUInt32LE(body + 4), bits: b.readUInt16LE(body + 14) };
      if (fmt.tag === 0xfffe && size >= 26) fmt.tag = b.readUInt16LE(body + 24);
    } else if (id === "data") {
      data = b.subarray(body, Math.min(body + size, b.length));
    }
    pos = body + size + (size & 1);
  }
  if (!fmt || !data) throw new Error("no fmt or data chunk");
  const bps = fmt.bits / 8, n = Math.floor(data.length / (bps * fmt.ch));
  const ch = Array.from({ length: fmt.ch }, () => new Float32Array(n));
  for (let i = 0; i < n; i++) {
    for (let c = 0; c < fmt.ch; c++) {
      const o = (i * fmt.ch + c) * bps;
      let v;
      if (fmt.tag === 3) v = fmt.bits === 32 ? data.readFloatLE(o) : data.readDoubleLE(o);
      else if (fmt.bits === 16) v = data.readInt16LE(o) / 32768;
      else if (fmt.bits === 24) v = data.readIntLE(o, 3) / 8388608;
      else if (fmt.bits === 32) v = data.readInt32LE(o) / 2147483648;
      else throw new Error("unsupported bit depth " + fmt.bits);
      ch[c][i] = v;
    }
  }
  return { fmt, ch, n, rate: fmt.rate, chunks, bytes: b, meta };
}

// The original's metadata, as text for the sidecar (Legal, RL-071: the shipped copy may not carry it, so the record must).
// LIST/INFO sub-chunks are listed as key=value; any other chunk (id3, bext, iXML and so on) is kept as its printable text
// and as base64 of the whole chunk (up to 64 KB), so nothing is lost.
function metadataText(meta) {
  const lines = [];
  for (const m of meta) {
    if (m.id === "LIST" && m.body.length >= 4) {
      const type = m.body.toString("ascii", 0, 4);
      lines.push(`chunk LIST/${type}:`);
      let p = 4;
      while (p + 8 <= m.body.length) {
        const k = m.body.toString("ascii", p, p + 4), n = m.body.readUInt32LE(p + 4);
        lines.push(`  ${k}=${m.body.toString("utf8", p + 8, p + 8 + n).replace(/\0+$/, "")}`);
        p += 8 + n + (n & 1);
      }
    } else {
      const printable = (m.body.toString("latin1").match(/[\x20-\x7e]{4,}/g) || []).join(" | ");
      lines.push(`chunk ${m.id.trim()} (${m.body.length} bytes): ${printable.slice(0, 600)}`);
      lines.push(`  base64: ${m.body.subarray(0, 65536).toString("base64")}`);
    }
  }
  return lines;
}

// ---- loudness, BS.1770-4
function biquad(x, b0, b1, b2, a1, a2) {
  const y = new Float64Array(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const v = b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = v; y[i] = v;
  }
  return y;
}
function kWeight(x, fs) {
  let K = Math.tan(Math.PI * 1681.974450955533 / fs), Q = 0.7071752369554196;
  const Vh = Math.pow(10, 3.999843853973347 / 20), Vb = Math.pow(Vh, 0.4996667741545416);
  let a0 = 1 + K / Q + K * K;
  let y = biquad(x, (Vh + Vb * K / Q + K * K) / a0, 2 * (K * K - Vh) / a0, (Vh - Vb * K / Q + K * K) / a0, 2 * (K * K - 1) / a0, (1 - K / Q + K * K) / a0);
  K = Math.tan(Math.PI * 38.13547087602444 / fs); Q = 0.5003270373238773;
  a0 = 1 + K / Q + K * K;
  return biquad(y, 1, -2, 1, 2 * (K * K - 1) / a0, (1 - K / Q + K * K) / a0);
}
function loudness(w) {
  const wch = w.ch.map((c) => kWeight(c, w.rate));
  const blk = Math.round(0.4 * w.rate), hop = Math.round(0.1 * w.rate);
  const z = [];
  for (let s = 0; s + blk <= w.n; s += hop) {
    let sum = 0;
    for (const c of wch) { let m = 0; for (let i = s; i < s + blk; i++) m += c[i] * c[i]; sum += m / blk; }
    z.push(sum);
  }
  const lk = (e) => -0.691 + 10 * Math.log10(e);
  const abs = z.filter((e) => lk(e) > -70);
  if (!abs.length) return { lufs: -Infinity, lra: 0, shortTermMax: -Infinity };
  const rel = lk(abs.reduce((a, b) => a + b, 0) / abs.length) - 10;
  const gated = abs.filter((e) => lk(e) > rel);
  const lufs = lk(gated.reduce((a, b) => a + b, 0) / gated.length);
  const mom = z.map(lk).filter((v) => v > -70).sort((a, b) => a - b);
  return { lufs, momentaryMax: mom[mom.length - 1] };
}
function truePeak(w) {
  // 4x oversampling with a windowed-sinc low-pass; an estimate, within about 0.5 dB of a reference meter
  const taps = 16, L = 4;
  const h = [];
  for (let k = -taps * L; k <= taps * L; k++) {
    const x = k / L, s = x === 0 ? 1 : Math.sin(Math.PI * x) / (Math.PI * x);
    h.push(s * (0.5 + 0.5 * Math.cos(Math.PI * k / (taps * L))));
  }
  let peak = 0, samplePeak = 0;
  for (const c of w.ch) {
    for (let i = 0; i < w.n; i++) samplePeak = Math.max(samplePeak, Math.abs(c[i]));
    // only check around loud samples, for speed
    for (let i = taps; i < w.n - taps; i++) {
      if (Math.abs(c[i]) < samplePeak * 0.5) continue;
      for (let ph = 1; ph < L; ph++) {
        let v = 0;
        for (let t = -taps + 1; t <= taps; t++) v += c[i + t] * h[(-t) * L + ph + taps * L] || 0;
        peak = Math.max(peak, Math.abs(v));
      }
    }
  }
  return { true: Math.max(peak, samplePeak), sample: samplePeak };
}

// ---- tempo and loop points
function mono(w) {
  const m = new Float32Array(w.n);
  for (const c of w.ch) for (let i = 0; i < w.n; i++) m[i] += c[i] / w.ch.length;
  return m;
}
function onsetEnvelope(m, rate, frameRate = 200) {
  const hop = Math.round(rate / frameRate), frames = Math.floor(m.length / hop);
  // a crude spectral flux: the positive rise in short-term energy of a high-passed signal
  const hp = new Float32Array(m.length);
  let p = 0;
  for (let i = 0; i < m.length; i++) { hp[i] = m[i] - p; p = m[i]; }
  const e = new Float64Array(frames);
  for (let f = 0; f < frames; f++) { let s = 0; for (let i = f * hop; i < (f + 1) * hop; i++) s += hp[i] * hp[i]; e[f] = Math.sqrt(s / hop); }
  const o = new Float64Array(frames);
  for (let f = 1; f < frames; f++) o[f] = Math.max(0, e[f] - e[f - 1]);
  const mean = o.reduce((a, b) => a + b, 0) / frames;
  for (let f = 0; f < frames; f++) o[f] = Math.max(0, o[f] - mean);
  return { o, frameRate: rate / hop };
}
function acf(o, lag) { let s = 0; for (let i = 0; i + lag < o.length; i++) s += o[i] * o[i + lag]; return s / (o.length - lag); }
function estimateTempo(m, rate) {
  const { o, frameRate } = onsetEnvelope(m, rate);
  const out = [];
  for (let bpm = 60; bpm <= 260; bpm += 0.5) out.push({ bpm, s: acf(o, Math.round(frameRate * 60 / bpm)) + 0.5 * acf(o, Math.round(frameRate * 120 / bpm)) });
  const max = Math.max(...out.map((x) => x.s)) || 1;
  const peaks = out.filter((x, i) => i > 0 && i < out.length - 1 && x.s > out[i - 1].s && x.s >= out[i + 1].s && x.s > 0.35 * max).sort((a, b) => b.s - a.s);
  const top = [];
  for (const p of peaks) if (top.every((t) => Math.abs(t.bpm - p.bpm) > 4)) top.push({ bpm: p.bpm, strength: +(p.s / max).toFixed(2) });
  return { best: top[0]?.bpm ?? null, candidates: top.slice(0, 4), o, frameRate };
}
function steadiness(m, rate, bpm) {
  // tempo in the first, middle and last third: a drift of more than about 2% will make a loop or a crossfade slip
  const third = Math.floor(m.length / 3), out = [];
  if (third < rate * 8) return null;
  for (let t = 0; t < 3; t++) {
    const seg = m.subarray(t * third, (t + 1) * third);
    const { o, frameRate } = onsetEnvelope(seg, rate);
    let best = { bpm: bpm, s: -1 };
    for (let b = bpm * 0.94; b <= bpm * 1.06; b += 0.25) { const s = acf(o, Math.round(frameRate * 60 / b)); if (s > best.s) best = { bpm: b, s }; }
    out.push(+best.bpm.toFixed(1));
  }
  return out;
}
function loopPoints(m, rate, bpm, bars, o, frameRate) {
  const beat = 60 / bpm, bar = 4 * beat, barN = Math.round(bar * rate);
  // downbeat offset: the phase (within one bar) whose beat grid collects the most onset energy, downbeats counted double
  let best = { off: 0, s: -1 };
  for (let off = 0; off < barN; off += Math.round(rate / frameRate)) {
    let s = 0;
    for (let k = 0; k * beat * rate + off < m.length; k++) {
      const f = Math.round((off / rate + k * beat) * frameRate);
      if (f < o.length) s += o[f] * (k % 4 === 0 ? 2 : 1);
    }
    if (s > best.s) best = { off, s };
  }
  const win = Math.round(0.03 * rate), cands = [];
  const loopN = bars * barN;
  for (let k = 0; best.off + (k + 1) * barN + loopN <= m.length && k < 16; k++) {
    const start = best.off + k * barN, end = start + loopN;
    let d = 0, e = 0;
    for (let i = 0; i < win; i++) {
      const a = m[end - win + i], b = start - win + i >= 0 ? m[start - win + i] : 0;
      d += (a - b) * (a - b); e += a * a + 1e-12;
    }
    cands.push({ start, end, bars, seconds: +(loopN / rate).toFixed(3), seam: +Math.sqrt(d / e).toFixed(3) });
  }
  cands.sort((a, b) => a.seam - b.seam);
  return { downbeatOffsetSamples: best.off, downbeatOffsetSeconds: +(best.off / rate).toFixed(3), best: cands.slice(0, 3) };
}

// ---- run
const w = readWav(file);
const target = opt("target", -16), bars = opt("bars", 8);
const L = loudness(w), tp = truePeak(w), m = mono(w);
const tempo = estimateTempo(m, w.rate);
const report = {
  file,
  format: { container: "WAV", encoding: w.fmt.tag === 3 ? `${w.fmt.bits}-bit float` : `${w.fmt.bits}-bit PCM`, channels: w.fmt.ch, sampleRate: w.rate, seconds: +(w.n / w.rate).toFixed(2) },
  loudness: { integratedLUFS: +L.lufs.toFixed(1), gainToTargetDb: +(target - L.lufs).toFixed(1), targetLUFS: target, momentaryMaxLUFS: +L.momentaryMax.toFixed(1) },
  peak: { samplePeakDbFS: +(20 * Math.log10(tp.sample)).toFixed(1), truePeakDbTP: +(20 * Math.log10(tp.true)).toFixed(1), truePeakAfterGainDbTP: +(20 * Math.log10(tp.true) + target - L.lufs).toFixed(1) },
  tempo: { estimateBpm: tempo.best, candidates: tempo.candidates, thirds: tempo.best ? steadiness(m, w.rate, tempo.best) : null },
  loop: tempo.best && w.n / w.rate > bars * 4 * 60 / tempo.best + 2 ? loopPoints(m, w.rate, tempo.best, bars, tempo.o, tempo.frameRate) : "too short for a loop of that many bars",
  original: {
    sha256: createHash("sha256").update(w.bytes).digest("hex"),
    bytes: w.bytes.length,
    chunks: w.chunks,
    metadata: metadataText(w.meta),
    metadataChunks: w.chunks.map((c) => c.split(":")[0]).filter((c) => !["fmt ", "data", "fact", "bext"].includes(c) || c === "bext"),
  },
  notes: [],
};
if (![44100, 48000].includes(w.rate)) report.notes.push(`sample rate ${w.rate} Hz: the hand-back spec asks for 44.1 or 48 kHz`);
if (w.fmt.ch !== 2) report.notes.push("not stereo");
if (report.peak.truePeakAfterGainDbTP > -1) report.notes.push("true peak after normalising would exceed -1 dBTP: lower the gain, do not limit");
const th = report.tempo.thirds;
if (th && Math.max(...th) - Math.min(...th) > 0.02 * tempo.best) report.notes.push("tempo drifts across the file: pick a steadier take, or loop only a short steady section");
if (report.original.metadataChunks.length === 0) report.notes.push("no metadata chunks in this file (Suno downloads normally carry some): if this is the original download, say so in the sidecar; if it is a converted copy, the metadata was lost");
if (writeSidecar) {
  const side = file.replace(/\.[^.]+$/, ".txt");
  const begin = "--- music_check (do not edit) ---", end = "--- end music_check ---";
  const block = [begin, `checksum_sha256: ${report.original.sha256}`, `file_bytes: ${report.original.bytes}`, `chunks: ${report.original.chunks.join(" ")}`, `metadata_original_copied: ${report.original.metadata.length ? "yes (below)" : "none to copy"}`, ...report.original.metadata.map((l) => "  " + l), `metadata_kept: ${report.original.metadataChunks.length ? "yes (" + report.original.metadataChunks.join(", ") + " present in the original)" : "NO METADATA CHUNKS FOUND"}`, `checked_on: ${new Date().toISOString().slice(0, 10)}`, `measured: ${report.format.sampleRate} Hz, ${report.format.channels} ch, ${report.format.seconds} s, ${report.loudness.integratedLUFS} LUFS, tempo ${report.tempo.estimateBpm} BPM`, end].join("\n");
  let text = existsSync(side) ? readFileSync(side, "utf8") : "";
  const a = text.indexOf(begin), z = text.indexOf(end);
  if (a >= 0 && z > a) text = text.slice(0, a) + block + text.slice(z + end.length);
  else text = text.replace(/\s*$/, text ? "\n\n" : "") + block;
  writeFileSync(side, text.endsWith("\n") ? text : text + "\n");
  report.notes.push(`sidecar updated: ${side}`);
}
if (asJson) console.log(JSON.stringify(report, null, 1));
else {
  const f = report.format, l = report.loudness, p = report.peak, t = report.tempo;
  console.log(`${file}`);
  console.log(`  format    ${f.container} ${f.encoding}, ${f.channels} ch, ${f.sampleRate} Hz, ${f.seconds} s`);
  console.log(`  loudness  ${l.integratedLUFS} LUFS integrated (momentary max ${l.momentaryMaxLUFS}); gain to ${l.targetLUFS} LUFS: ${l.gainToTargetDb > 0 ? "+" : ""}${l.gainToTargetDb} dB`);
  console.log(`  peak      sample ${p.samplePeakDbFS} dBFS, true (approx.) ${p.truePeakDbTP} dBTP, after gain ${p.truePeakAfterGainDbTP} dBTP`);
  console.log(`  original  sha256 ${report.original.sha256}, ${report.original.bytes} bytes, chunks ${report.original.chunks.join(" ")}`);
  console.log(`  tempo     ${t.estimateBpm} BPM (candidates ${t.candidates.map((c) => `${c.bpm} @${c.strength}`).join(", ")}); first, middle, last third: ${t.thirds ? t.thirds.join(", ") : "n/a"}`);
  if (typeof report.loop === "string") console.log(`  loop      ${report.loop}`);
  else {
    console.log(`  loop      downbeat at ${report.loop.downbeatOffsetSeconds} s; best ${bars}-bar loops (seam 0 = perfect, over 0.5 = audible jump):`);
    for (const c of report.loop.best) console.log(`            start ${c.start}  end ${c.end}  (${c.seconds} s, seam ${c.seam})`);
  }
  for (const n of report.notes) console.log(`  note      ${n}`);
}

// What of export_presets.cfg the flash set and the release pass care about (Legal's RL-197, 2026-10-27): the WEB preset's own block (its [preset.N] section and its [preset.N.options]) and
// every line outside any preset. A change to another preset (the Windows or Linux build's) does not change what the web page shows, so it leaves the content hash alone and asks for no set.
// The Web preset's index is part of its block (the header line is kept): moving it to another index is a change. Any other change to the Web block, or to a line outside the presets, is as
// before: a full set. A shipped Linux or Windows build still gets its own flash reading when it ships (docs/tools/flash-check.md).
import { createHash } from 'node:crypto';

/** The parts of an export_presets.cfg that count: { outside: [lines], web: [[lines of each Web preset's block]] }. Line endings are normalised first. */
export function presetParts(text) {
  const lines = String(text).replace(/\r\n/g, '\n').split('\n');
  const outside = [];
  const blocks = new Map();   // preset index -> its lines (the header of [preset.N], the [preset.N.options] header, the keys of both)
  let cur = null;
  for (const l of lines) {
    const m = /^\[preset\.(\d+)(\.options)?\]\s*$/.exec(l);
    if (m) { cur = m[1]; if (!blocks.has(cur)) blocks.set(cur, []); blocks.get(cur).push(l); continue; }
    if (/^\[/.test(l)) { cur = null; outside.push(l); continue; }   // any other section is outside every preset
    (cur === null ? outside : blocks.get(cur)).push(l);
  }
  const web = [...blocks.values()].filter((ls) => ls.some((l) => /^platform="Web"\s*$/.test(l)));
  return { outside, web };
}

/** The text that is hashed for a file: the lines outside any preset, then the Web preset's block(s). Two files with the same view need the same flash set. */
export function webPresetView(text) {
  const { outside, web } = presetParts(text);
  return `outside\n${outside.join('\n')}\nweb\n${web.length ? web.map((ls) => ls.join('\n')).join('\n--\n') : 'none'}\n`;
}

/** The hash of the view (sha-256, hex). */
export function webPresetHash(text) { return createHash('sha256').update(webPresetView(text)).digest('hex'); }

/** Whether the Web preset or a line outside the presets differs between two versions of the file (null on either side means "no file": a difference unless both are). */
export function webPresetChanged(a, b) {
  if (a == null && b == null) return false;
  if (a == null || b == null) return true;
  return webPresetView(a) !== webPresetView(b);
}

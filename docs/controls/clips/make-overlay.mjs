// Turns the clip's input script (hitstop-ab.json) into what the clip tool needs to DRAW the inputs at the frame's edge: per tick, which controls are held and where the right stick is.
//   node docs/controls/clips/make-overlay.mjs > docs/controls/clips/hitstop-ab.overlay.json
// Output: { ticks, segments, frames: [ { t, held: ["X", "RB"], rs: [x, y] | null, press: ["X"] (pressed on this tick), segment } ] }. The segment names are the script's.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const script = JSON.parse(readFileSync(join(here, 'hitstop-ab.json'), 'utf8'));
const NAMES = { west: 'X', north: 'Y', east: 'B', south: 'A', lb: 'LB', rb: 'RB', l3: 'L3', r3: 'R3' };
const held = new Set();
let rs = [0, 0];
let ls = [0, 0];
const lt = { lt: 0, rt: 0 };
const frames = [];
const byTick = new Map();
for (const e of script.events) { if (!byTick.has(e[0])) byTick.set(e[0], []); byTick.get(e[0]).push(e); }
const total = script.scene.ticks;
let segIdx = 0;
for (let t = 0; t < total; t++) {
  const pressed = [];
  for (const e of byTick.get(t) ?? []) {
    if (e[1] === 'b') { const n = NAMES[e[2]] ?? e[2]; if (e[3]) { if (!held.has(n)) pressed.push(n); held.add(n); } else held.delete(n); }
    else if (e[1] === 't') { lt[e[2]] = e[3]; const n = e[2].toUpperCase(); if (e[3] > 0.5) { if (!held.has(n)) pressed.push(n); held.add(n); } else held.delete(n); }
    else if (e[1] === 'rs') rs = [e[2], e[3]];
    else if (e[1] === 'ls') ls = [e[2], e[3]];
  }
  while (segIdx + 1 < script.segments.length && t >= script.segments[segIdx + 1].from) segIdx++;
  frames.push({ t, held: [...held], rs: (rs[0] !== 0 || rs[1] !== 0) ? rs : null, ls: (ls[0] !== 0 || ls[1] !== 0) ? ls : null, press: pressed, segment: script.segments[segIdx].name });
}
process.stdout.write(JSON.stringify({ ticks: total, segments: script.segments, frames }, null, 0) + '\n');

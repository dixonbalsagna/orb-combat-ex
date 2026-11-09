// The button strip of a LAN clip, read from a replay's own recorded intents (Tools, 2026-11-08; docs/tools/lan-report.md).
// A native LAN match has no browser pad log, so the strip is decoded from what the sim was fed: replay.inputs, entries [tick, slot, low, high, word2?],
// one only where a slot's intent changed (sim/core/replay.gd; SimIntent.pack and pack2, sim/input/intent.gd, intent version 4). The decoded intent becomes
// the same row the capture hook logs, [tick, slot, stick x 100, stick y 100, flags, rsDir, rsLevel, stanceMask], so tools/clips/make.mjs stripStates draws
// the same words (tap, hold, mash) for the same controls. Reads only; nothing here steps a sim.
import { stripStates } from '../clips/make.mjs';

const bit = (p, n) => Number((p >> BigInt(n)) & 1n) === 1;
// PAD_BIT in make.mjs: light0 heavy1 sig2 dodge3 guardPress4 lightHeld5 heavyHeld6 sigHeld7 rsHeld8 rsStart9 guard10 sprint11 power12 context13 contextHeld14 special15 powerPress16 transform17

/** One recorded entry as a hook-shaped row, or null for "no intent" (an AI body, or a slot with none). */
export function rowOf(tick, slot, low, high, word2) {
  if (low === null || low === undefined || high === null || high === undefined) return [tick, slot, 0, 0, 0, 0, 0, 0];
  const p = BigInt(low) | (BigInt(high) << 32n);
  const w = BigInt(word2 || 0);
  const k = (n) => Number((p >> BigInt(n)) & 0xFFn);
  const mx = (k(0) - 127) / 127, my = (k(8) - 127) / 127;
  let f = 0;
  const on = (cond, b) => { if (cond) f |= 1 << b; };
  on(bit(p, 30), 0); on(bit(p, 31), 1); on(bit(p, 32), 2); on(bit(p, 25), 3); on(bit(p, 24), 4);
  on(bit(p, 40), 5); on(bit(p, 41), 6); on(bit(p, 52), 7);
  on(bit(w, 0), 8); on(bit(w, 1), 9);
  on(bit(p, 23), 10); on(bit(p, 26), 11); on(bit(p, 27), 12); on(bit(p, 33), 13); on(bit(p, 51), 14);
  on(Number((p >> 20n) & 7n) !== 0, 15); on(bit(p, 28), 16); on(bit(p, 34), 17);
  const mask = Number((p >> 47n) & 15n);
  const rsDir = Number((w >> 4n) & 7n), rsLevel = Number((w >> 7n) & 3n);
  return [tick, slot, Math.round(mx * 100), Math.round(my * 100), f, rsDir, rsLevel, mask];
}

/** Hook-shaped rows for `slot`, one per tick in [from, to]: a recorded intent holds until the next entry for that slot changes it. */
export function rowsFromInputs(inputs, slot, from, to) {
  const mine = (inputs || []).filter((e) => Number(e[1]) === slot).sort((a, b) => a[0] - b[0]);
  const rows = [];
  let ei = 0, cur = [0, slot, 0, 0, 0, 0, 0, 0], curE = null;
  for (let t = 0; t <= to; t++) {
    while (ei < mine.length && mine[ei][0] <= t) { curE = mine[ei]; ei++; cur = rowOf(t, slot, curE[2], curE[3], curE[4]); }
    if (t >= from) rows.push([t, slot, cur[2], cur[3], cur[4], cur[5], cur[6], cur[7]]);
  }
  return rows;
}

/** The ticks of the pictures a blackbox-clip run takes with these settings (its own rule: every EVERY-th tick from FROM, and the last). */
export function pictureTicks(from, to, every) {
  const out = [];
  for (let i = 1; i <= to; i++) if ((i % every === 0 || i === to) && i >= from) out.push(i);
  return out;
}

/** The strip states for the pictures of a clip: one object per picture, the shape tools/clips/make.mjs draws. */
export function stripFor(inputs, slot, from, to, every) {
  const ticks = pictureTicks(from, to, every);
  const rows = rowsFromInputs(inputs, slot, Math.max(0, from - 300), to);
  return { ticks, frames: stripStates(rows, ticks, slot, every) };
}

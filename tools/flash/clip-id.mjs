// Which match a captured clip is: its scenario, seed, pairing and variant, as capture-web.mjs records them in clip.json, and the comparison two clips must pass before a compare step shows them side by side.
// Why it exists: a capture with no --seed plays the hook's own default seed (SEED in render/tools/flash_capture.gd) on the default pair, which is no seed of the flash set (sources.json), so two clips of
// "the same scene" can be two different matches without anything saying so (2026-10-27: a divergence check that compared two different matches).
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/** The seed the hook plays when a capture asks for none (or for 0): render/tools/flash_capture.gd `const SEED`. clip-id-selftest.mjs holds the two equal. */
export const DEFAULT_SEED = 12345;

/** The seed a capture played: the one asked for, or the hook's default. */
export const playedSeed = (asked) => (asked === null || asked === undefined || asked === 0 || Number.isNaN(asked) ? DEFAULT_SEED : asked);

/** The pairing as text: "default" (the roster's first two) or the two ids. */
export const pairingText = (slots) => (slots && slots.length ? slots.join(',') : 'default');

/** What capture-web.mjs writes into clip.json about the match: the seed asked for (null when none), the seed played, the pairing (null for the default) and the variant. */
export function matchRecord({ scenario, seed, slots, variant }) {
  const asked = seed === undefined ? null : seed;
  return { scenario, seed: asked, seedPlayed: playedSeed(asked), slots: slots && slots.length ? slots : null, pairing: pairingText(slots), variant: variant || 0 };
}

/** One line for a log or a label: "seed 12345 (the hook's default), pairing default, variant 0". */
export function matchText(m) {
  return `seed ${m.seedPlayed}${m.seed === null ? " (the hook's default)" : ''}, pairing ${m.pairing}, variant ${m.variant}`;
}

/** The match record of a clip folder, or null with the reason when the folder has none (an older clip carries no seedPlayed: it is derived, and marked). */
export function readMatch(dir) {
  const f = join(dir, 'clip.json');
  if (!existsSync(f)) return { match: null, why: `${dir} has no clip.json` };
  let c;
  try { c = JSON.parse(readFileSync(f, 'utf8')); } catch (e) { return { match: null, why: `${f} does not parse: ${e.message}` }; }
  if (c.seedPlayed !== undefined) return { match: matchRecord({ scenario: c.scenario, seed: c.seed, slots: c.slots, variant: c.variant }) , why: null };
  // a clip from before the record: the seed asked for is all it kept, and the pairing was not recorded
  if (!('seed' in c)) return { match: null, why: `${f} records no seed` };
  return { match: { ...matchRecord({ scenario: c.scenario, seed: c.seed, slots: null, variant: c.variant }), pairing: 'not recorded', derived: true }, why: null };
}

/** What differs between two matches (empty: the same match). Compares scenario, played seed, pairing and variant; a pairing that was not recorded is not compared. */
export function differences(a, b) {
  const out = [];
  if (a.scenario !== b.scenario) out.push(`scenario ${a.scenario} against ${b.scenario}`);
  if (a.seedPlayed !== b.seedPlayed) out.push(`seed ${a.seedPlayed} against ${b.seedPlayed}`);
  if (a.pairing !== 'not recorded' && b.pairing !== 'not recorded' && a.pairing !== b.pairing) out.push(`pairing ${a.pairing} against ${b.pairing}`);
  if (a.variant !== b.variant) out.push(`variant ${a.variant} against ${b.variant}`);
  return out;
}

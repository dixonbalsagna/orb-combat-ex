// The required set of pixel clips, from tools/flash/sources.json: the five fixed cases and, for `ai`, every pairing at every seed, each in normal and reduced mode. One list for
// run-pixels.mjs (what to capture) and release-pass.mjs (what a recorded pass must cover). A clip's id is scenario[-pairing][-seed]-mode, e.g. collapse-normal, ai-12345-reduced.
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));

/** [{ id, scenario, seed, reduced, ticks, multi, slots (null for the default pair), label, words? (extra page words, a night clip's) }] in the order of sources.json. */
export function requiredClips(sources, roster) {
  const src = sources || JSON.parse(readFileSync(join(here, 'sources.json'), 'utf8'));
  const ros = roster || JSON.parse(readFileSync(join(here, '..', '..', 'data', 'fighters', 'roster.json'), 'utf8'));
  const jobs = [];
  for (const sc of src.scenarios) {
    // `pairings`: the AI-match set; `slotsList`: the scene's own lists of fighters (a dummy scene per fighter, a ring of three to five bodies), one seed each; else the default pair
    const runs = sc.pairings ? src.pairings.map((p) => ({ slots: p.slots, seeds: p.seeds })) : sc.slotsList ? sc.slotsList.map((s) => ({ slots: s, seeds: [12345] })) : [{ slots: null, seeds: [12345] }];
    for (const r of runs) {
      const dflt = !r.slots || (r.slots.length === 2 && r.slots[0] === ros[0] && r.slots[1] === ros[1]);
      const label = dflt ? '' : '-' + r.slots.join('-');
      for (const seed of r.seeds) for (const reduced of [false, true]) {
        const id = `${sc.id}${label}${r.seeds.length > 1 ? '-' + seed : ''}-${reduced ? 'reduced' : 'normal'}`;
        jobs.push({ id, scenario: sc.id, seed, reduced, ticks: sc.ticks, multi: r.seeds.length > 1, slots: dflt ? null : r.slots, label });
      }
    }
  }
  // `nightClips` (CD-09 item 5, 2026-11-14): a scene of the list above played under other page words, both modes, one seed each. The beam clash under the night key of the sky (`sky=night`): the brightest
  // thing in the game against the darkest sky. Not in `scenarios`: the headless register run and check-log.js know scenes, not page words.
  for (const nc of src.nightClips || []) for (const reduced of [false, true]) jobs.push({ id: `${nc.id}-${reduced ? 'reduced' : 'normal'}`, scenario: nc.base, seed: nc.seed || 12345, reduced, ticks: nc.ticks, multi: false, slots: null, label: '', words: nc.words });
  return jobs;
}

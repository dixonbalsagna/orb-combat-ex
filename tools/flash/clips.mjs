// The required set of pixel clips, from tools/flash/sources.json: the five fixed cases and, for `ai`, every pairing at every seed, each in normal and reduced mode. One list for
// run-pixels.mjs (what to capture) and release-pass.mjs (what a recorded pass must cover). A clip's id is scenario[-pairing][-seed]-mode, e.g. collapse-normal, ai-12345-reduced.
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));

/** [{ id, scenario, seed, reduced, ticks, multi, slots (null for the default pair), label }] in the order of sources.json. */
export function requiredClips(sources, roster) {
  const src = sources || JSON.parse(readFileSync(join(here, 'sources.json'), 'utf8'));
  const ros = roster || JSON.parse(readFileSync(join(here, '..', '..', 'data', 'fighters', 'roster.json'), 'utf8'));
  const jobs = [];
  for (const sc of src.scenarios) {
    const runs = sc.pairings ? src.pairings.map((p) => ({ slots: p.slots, seeds: p.seeds })) : [{ slots: null, seeds: [12345] }];
    for (const r of runs) {
      const dflt = !r.slots || (r.slots[0] === ros[0] && r.slots[1] === ros[1]);
      const label = dflt ? '' : '-' + r.slots.join('-');
      for (const seed of r.seeds) for (const reduced of [false, true]) {
        const id = `${sc.id}${label}${r.seeds.length > 1 ? '-' + seed : ''}-${reduced ? 'reduced' : 'normal'}`;
        jobs.push({ id, scenario: sc.id, seed, reduced, ticks: sc.ticks, multi: r.seeds.length > 1, slots: dflt ? null : r.slots, label });
      }
    }
  }
  return jobs;
}

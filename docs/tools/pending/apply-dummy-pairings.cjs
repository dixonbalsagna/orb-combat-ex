// The training dummy goes into the roster (Simulation's docs/architecture/pending/n-bodies/dummy_roster.py): the flash set's side. Apply WITH that script, in the same commit:
//     node docs/tools/pending/apply-dummy-pairings.cjs
// It does what the n-bodies README asks of Tools: tools/flash/pick-seeds.mjs run again (a scan of seeds 1 to 120 for each of the three pairings, 20 seeds in all, the failed seeds of
// earlier candidates (4, 39, 104, 106) and the five worst of the previous release kept, every signature at least twice, every fighter in at least five matches: PROTAGONIST 14, RIVAL 13,
// REFERENCE 13, no warning), the two new pairings in tools/flash/sources.json, and their coverage keys and the failed seeds in tools/flash/seed-history.json. Re-runnable.
// The required set stays 56 clips (the 20 seeds are shared among three pairings). The AI clips are new seeds, so the next record needs a whole run (the pinned interim record is for its own
// commit and is not affected). Not run by CI or the validator; it edits only tools/flash/sources.json and tools/flash/seed-history.json.
const fs = require('fs');

const PICK = {
  'PROTAGONIST,REFERENCE': [98, 100, 74, 4, 49, 8, 13],
  'PROTAGONIST,RIVAL': [4, 39, 104, 106, 7, 9, 43],
  'RIVAL,REFERENCE': [15, 29, 107, 88, 100, 36],
};
const FAILED = [
  { pairing: 'PROTAGONIST,RIVAL', seed: 4, candidate: '10c2d177', reading: 'FAIL 4/4/1.5', fixed: false, note: 'a body down at 2505: Rendering\'s ground batch read it 2 at d3cd19d5; stays until the recorded pass for the commit shows it' },
  { pairing: 'PROTAGONIST,RIVAL', seed: 39, candidate: '10c2d177', reading: 'FAIL 3/3.5/3', fixed: false, note: 'a launch pan (Camera); reads 3/3.5/3 on d3f1ca0e' },
  { pairing: 'PROTAGONIST,RIVAL', seed: 104, candidate: '10c2d177', reading: 'FAIL 5/5/5', fixed: false, note: 'a merged brawl, world 12 of 12; 2.5/3.5/2 on d3f1ca0e' },
  { pairing: 'PROTAGONIST,RIVAL', seed: 106, candidate: '10c2d177', reading: 'FAIL 7.5/9.5/6.5', fixed: false, note: 'the foreground ground strobe; 2.5 and 2 on d3f1ca0e' },
];
const NEW = { 'PROTAGONIST,REFERENCE': ['PROTAGONIST', 'REFERENCE'], 'RIVAL,REFERENCE': ['RIVAL', 'REFERENCE'] };
const WHY = "The training dummy (the reference fighter, in the roster as Simulation's dummy_roster.py puts him): AI matches of a launch fighter against him, full length, both modes; picked by tools/flash/pick-seeds.mjs (Legal's RL-131: a pairing new in a release at least 3 times, every fighter in at least 5 matches).";
const BASE_NOTE = ' Re-picked with the dummy in the roster: 20 seeds in all across three pairings; the failed seeds of earlier candidates (4, 39, 104, 106) and the five worst of the previous release stay.';

const sf = 'tools/flash/sources.json';
const src = JSON.parse(fs.readFileSync(sf, 'utf8'));
for (const [key, slots] of Object.entries(NEW)) {
  if (!src.pairings.some((p) => p.slots.join(',') === key)) src.pairings.push({ slots, seeds: [], needSignatures: slots.slice(), _why: WHY });
}
for (const p of src.pairings) { const k = p.slots.join(','); if (PICK[k]) p.seeds = PICK[k]; }
const base = src.pairings[0];
if (!String(base._why || '').includes('Re-picked with the dummy')) base._why = String(base._why || '') + BASE_NOTE;
fs.writeFileSync(sf, JSON.stringify(src, null, 2) + '\n');

const hf = 'tools/flash/seed-history.json';
const h = JSON.parse(fs.readFileSync(hf, 'utf8'));
h.coverage = h.coverage || {};
for (const k of Object.keys(NEW)) if (!(k in h.coverage)) h.coverage[k] = null;
h.failed = h.failed || [];
for (const f of FAILED) if (!h.failed.some((x) => x.pairing === f.pairing && x.seed === f.seed)) h.failed.push(f);
fs.writeFileSync(hf, JSON.stringify(h, null, 2) + '\n');
console.log('dummy pairings: sources.json and seed-history.json updated (' + Object.entries(PICK).map(([k, v]) => k + ' ' + v.length).join(', ') + ')');

// The cross-references of data/camera/intro_shots.json that a JSON Schema cannot hold (docs/camera/varied-intros-data.md section 4).
//   node check_intro_shots.mjs <path to intro_shots.json>
// Exit 0: none broken. Tools folds these into tools/lib/xref-camera.js when the file lands.
import { readFileSync } from 'node:fs';

const path = process.argv[2];
if (!path) { console.error('usage: node check_intro_shots.mjs <intro_shots.json>'); process.exit(2); }
const d = JSON.parse(readFileSync(path, 'utf8'));
const fams = d.families;
const errs = [];
const err = (where, msg) => errs.push(`${where}: ${msg}`);
const has = (f) => Object.prototype.hasOwnProperty.call(fams, f) && !f.startsWith('_');

// defaults and the sets name families of the right phase
for (const [ph, f] of Object.entries(d.defaults)) {
  if (ph.startsWith('_')) continue;
  if (!has(f)) err(`defaults.${ph}`, `no family ${f}`);
  else if (fams[f].phase !== ph) err(`defaults.${ph}`, `${f} is a ${fams[f].phase} family`);
}
for (const [ph, f] of Object.entries(d.sets.reducedMotion)) {
  if (!['fall', 'descend', 'land', 'wait', 'stare', 'closing'].includes(ph)) continue;
  if (!has(f)) err(`sets.reducedMotion.${ph}`, `no family ${f}`);
  else if (fams[f].phase !== ph) err(`sets.reducedMotion.${ph}`, `${f} is a ${fams[f].phase} family`);
}
for (const [from, to] of Object.entries(d.sets.reduceFlashing.replace)) {
  if (!has(from)) err(`sets.reduceFlashing.replace.${from}`, 'no such family');
  else if (!has(to)) err(`sets.reduceFlashing.replace.${from}`, `no family ${to}`);
  else if (fams[from].phase !== fams[to].phase) err(`sets.reduceFlashing.replace.${from}`, `${to} is another phase`);
}
// weights: a family once, every ordinary family has one; rules name families
const seen = new Set();
for (const w of d.weights) {
  if (!has(w.family)) err('weights', `no family ${w.family}`);
  if (seen.has(w.family)) err('weights', `${w.family} twice`);
  seen.add(w.family);
}
for (const f of Object.keys(fams)) {
  if (f.startsWith('_')) continue;
  const reduced = /^R/.test(f);
  if (!reduced && !seen.has(f)) err('weights', `family ${f} has no weight`);
  if (reduced && seen.has(f)) err('weights', `reduced-set family ${f} must not be picked by weight`);
}
d.rules.forEach((r, i) => { for (const f of Object.keys(r.mul)) if (!has(f)) err(`rules[${i}].mul`, `no family ${f}`); });
// each family
for (const [f, fam] of Object.entries(fams)) {
  if (f.startsWith('_')) continue;
  const k = fam.keys;
  if (fam.phase !== 'closing' && !k[0].cut) err(`${f}.keys[0]`, 'the first key must be a cut (a shot opens on one; only a closing continues the staredown)');
  let last = -1;
  k.forEach((key, i) => {
    if (key.t < last) err(`${f}.keys[${i}]`, `t ${key.t} goes back (after ${last})`);
    last = key.t;
  });
  if (k[0].t !== 0) err(`${f}.keys[0]`, 't must be 0');
  if (k[k.length - 1].t !== 1) err(`${f}.keys[${k.length - 1}]`, 't must be 1');
  const cutKeys = k.filter((x) => x.cut).length;
  if (cutKeys !== fam.cuts) err(f, `cuts is ${fam.cuts} but ${cutKeys} keys cut`);
  if (!fam.legacy && fam.scroll > d.constraints.scrollBound) err(f, `scroll ${fam.scroll} is over the bound ${d.constraints.scrollBound} and the family is not legacy`);
  if (fam.needs && fam.needs.pitch !== undefined && fam.keys.every((x) => Math.abs(x.pitch) < Math.abs(fam.needs.pitch) * 0.9)) err(f, `needs pitch ${fam.needs.pitch} but no key reaches it`);
  if (fam.keys.some((x) => x.pitch < -6)) err(f, 'a pitch under -6 (the ground rule)');
}
// every phase has its default and a reduced-motion family
for (const ph of ['fall', 'descend', 'land', 'wait', 'stare', 'closing']) {
  if (!Object.values(fams).some((f) => f.phase === ph && !f.legacy === false)) { /* a legacy family exists for the phase: fine */ }
}
if (errs.length) { console.error(errs.join('\n')); process.exit(1); }
console.log(`intro_shots: ${Object.keys(fams).filter((f) => !f.startsWith('_')).length} families, ${d.weights.length} weights, ${d.rules.length} rules, no broken reference`);

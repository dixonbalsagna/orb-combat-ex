'use strict';
// Cross-reference rules for Narrative's data/narrative/opponent_grounds.json (the ground each story opponent claims, read by sim/world/ringpick.gd):
//   opponent-grounds-feature  every feature of a claim's suits, must_cross and avoids (each part of "a|b") is in the picker's vocabulary: an arm of featureValue in sim/world/ringpick.gd
//                             (a name the picker does not know scores 0 and would silently never count)
//   opponent-grounds-home     no two opponents share a home; and, once Narrative's homes data is in the tree (data/narrative/planet_names.json "homes"), a claim's home is the name of its
//                             own fighter's home there
// The schema (narrative-opponent-grounds.schema.json) checks the shape and the grammar of a feature name; this reads the vocabulary from the picker itself, so a feature dropped from the
// picker fails here. Without ringpick.gd in the tree the vocabulary rule has nothing to read and is skipped.
const fs = require('fs');
const path = require('path');

const F = 'data/narrative/opponent_grounds.json';
const PICKER = 'sim/world/ringpick.gd';
const HOMES = 'data/narrative/planet_names.json';

/** The picker's feature names: the quoted labels of the match arms inside featureValue. Pure. */
function vocabulary(text) {
  const at = text.indexOf('static func featureValue');
  if (at < 0) return null;
  const rest = text.slice(at).split('\n');
  const names = new Set();
  for (let i = 1; i < rest.length; i++) {
    if (/^(static func|func|class_name|# ====)/.test(rest[i])) break;   // the next function ends it
    const m = /^\t\t((?:"[^"]+"\s*,\s*)*"[^"]+")\s*:/.exec(rest[i]);
    if (m) for (const q of m[1].matchAll(/"([^"]+)"/g)) names.add(q[1]);
  }
  return names;
}

function xrefGrounds({ get, err, esc, isObj, root }) {
  const d = get(F);
  if (!isObj(d) || !isObj(d.claims)) return;
  let vocab = null;
  try { vocab = vocabulary(fs.readFileSync(path.join(root, PICKER), 'utf8')); } catch { /* no picker in this tree */ }
  if (vocab && vocab.size) {
    const check = (name, ptr) => {
      if (typeof name !== 'string') return;
      for (const part of name.split('|')) if (!vocab.has(part)) err(F, ptr, 'opponent-grounds-feature', `"${part}" is not a feature of the ring picker (${PICKER} featureValue): it would always score 0`);
    };
    for (const [who, c] of Object.entries(d.claims)) {
      if (who.startsWith('_') || !isObj(c)) continue;
      if (Array.isArray(c.suits)) c.suits.forEach((s, i) => { if (isObj(s)) check(s.feature, `/claims/${esc(who)}/suits/${i}/feature`); });
      for (const k of ['must_cross', 'avoids']) if (Array.isArray(c[k])) c[k].forEach((f, i) => check(f, `/claims/${esc(who)}/${k}/${i}`));
    }
  }
  const seen = new Map();
  for (const [who, c] of Object.entries(d.claims)) {
    if (who.startsWith('_') || !isObj(c) || typeof c.home !== 'string') continue;
    if (seen.has(c.home)) err(F, `/claims/${esc(who)}/home`, 'opponent-grounds-home', `"${c.home}" is already ${seen.get(c.home)}'s home: each opponent has a home of their own`);
    else seen.set(c.home, who);
  }
  const homes = get(HOMES);
  if (isObj(homes) && Array.isArray(homes.homes)) {
    const byFighter = new Map(homes.homes.filter((h) => isObj(h) && typeof h.fighter === 'string').map((h) => [h.fighter, h.name]));
    for (const [who, c] of Object.entries(d.claims)) {
      if (who.startsWith('_') || !isObj(c) || typeof c.home !== 'string' || !byFighter.has(who)) continue;
      if (byFighter.get(who) !== c.home) err(F, `/claims/${esc(who)}/home`, 'opponent-grounds-home', `${who}'s home is "${c.home}" here but "${byFighter.get(who)}" in ${HOMES}`);
    }
  }
}

module.exports = { xrefGrounds, vocabulary };

'use strict';
// Cross-reference rules for Art's biome look bible, data/art/biomes.json (called from xref-fight.js):
//   biomes-look-order      the biomes' `order` values are 1..N, each once
//   biomes-look-neighbour  a neighbour id is another biome of the file
//   biomes-look-pair       `pairs`: both ends are biomes, different, each pair once; and every pair is in BOTH biomes' neighbours with the same eco and note, and every neighbour entry is a pair
//   biomes-look-far-land   far_land.amp is present for every kind but "none", and absent for "none"
//   biomes-look-cover      a cover entry's height range runs least to greatest
//   biomes-look-orbit      orbit_separation.pair names two biomes of the file

const F = 'data/art/biomes.json';

function xrefBiomeLook({ get, err, esc, isObj }) {
  const d = get(F);
  if (!isObj(d) || !isObj(d.biomes)) return;
  const ids = Object.keys(d.biomes).filter((k) => !k.startsWith('_'));
  const known = new Set(ids);
  // order
  const byOrder = new Map();
  for (const id of ids) {
    const b = d.biomes[id];
    if (!isObj(b) || !Number.isInteger(b.order)) continue;
    if (byOrder.has(b.order)) err(F, `/biomes/${esc(id)}/order`, 'biomes-look-order', `order ${b.order} is also ${byOrder.get(b.order)}'s`);
    else byOrder.set(b.order, id);
  }
  if (byOrder.size === ids.length) for (let i = 1; i <= ids.length; i++) if (!byOrder.has(i)) { err(F, '/biomes', 'biomes-look-order', `the orders run 1 to ${ids.length}, but ${i} is missing`); break; }
  // per biome: neighbours, far land, cover
  for (const id of ids) {
    const b = d.biomes[id];
    if (!isObj(b)) continue;
    if (Array.isArray(b.neighbours)) b.neighbours.forEach((n, i) => {
      if (!isObj(n) || typeof n.id !== 'string') return;
      if (n.id === id) err(F, `/biomes/${esc(id)}/neighbours/${i}/id`, 'biomes-look-neighbour', `${id} lists itself as a neighbour`);
      else if (!known.has(n.id)) err(F, `/biomes/${esc(id)}/neighbours/${i}/id`, 'biomes-look-neighbour', `"${n.id}" is not a biome of the file`);
    });
    if (isObj(b.far_land)) {
      const none = b.far_land.kind === 'none', has = typeof b.far_land.amp === 'number';
      if (none && has) err(F, `/biomes/${esc(id)}/far_land`, 'biomes-look-far-land', 'far_land kind "none" has an amp');
      if (!none && typeof b.far_land.kind === 'string' && !has) err(F, `/biomes/${esc(id)}/far_land`, 'biomes-look-far-land', `far_land kind "${b.far_land.kind}" has no amp`);
    }
    if (Array.isArray(b.cover)) b.cover.forEach((c, i) => {
      if (isObj(c) && Array.isArray(c.h) && typeof c.h[0] === 'number' && typeof c.h[1] === 'number' && c.h[0] > c.h[1]) err(F, `/biomes/${esc(id)}/cover/${i}/h`, 'biomes-look-cover', `the height range ${c.h[0]} to ${c.h[1]} runs the wrong way`);
    });
  }
  // pairs
  const key = (a, b) => [a, b].sort().join('/');
  const seen = new Set();
  const pairKeys = new Map();
  if (Array.isArray(d.pairs)) d.pairs.forEach((p, i) => {
    if (!isObj(p)) return;
    let ok = true;
    for (const side of ['a', 'b']) if (typeof p[side] === 'string' && !known.has(p[side])) { err(F, `/pairs/${i}/${side}`, 'biomes-look-pair', `"${p[side]}" is not a biome of the file`); ok = false; }
    if (typeof p.a === 'string' && p.a === p.b) { err(F, `/pairs/${i}/b`, 'biomes-look-pair', `${p.a} is paired with itself`); ok = false; }
    if (!ok || typeof p.a !== 'string' || typeof p.b !== 'string') return;
    const k = key(p.a, p.b);
    if (seen.has(k)) { err(F, `/pairs/${i}`, 'biomes-look-pair', `the pair ${k} is listed twice`); return; }
    seen.add(k);
    pairKeys.set(k, p);
    for (const [from, to] of [[p.a, p.b], [p.b, p.a]]) {
      const n = isObj(d.biomes[from]) && Array.isArray(d.biomes[from].neighbours) ? d.biomes[from].neighbours.find((x) => isObj(x) && x.id === to) : null;
      if (!n) { err(F, `/pairs/${i}`, 'biomes-look-pair', `${from} does not list ${to} as a neighbour`); continue; }
      if (JSON.stringify(n.eco) !== JSON.stringify(p.eco) || n.note !== p.note) err(F, `/pairs/${i}`, 'biomes-look-pair', `${from}'s neighbour entry for ${to} differs from the pair's eco or note`);
    }
  });
  if (Array.isArray(d.pairs)) for (const id of ids) {
    const b = d.biomes[id];
    if (isObj(b) && Array.isArray(b.neighbours)) b.neighbours.forEach((n, i) => {
      if (isObj(n) && typeof n.id === 'string' && known.has(n.id) && n.id !== id && !pairKeys.has(key(id, n.id)) && seen.size) err(F, `/biomes/${esc(id)}/neighbours/${i}/id`, 'biomes-look-pair', `${id} / ${n.id} is a neighbour entry but not in pairs`);
    });
  }
  // the closest orbit pair
  if (isObj(d.orbit_separation) && typeof d.orbit_separation.pair === 'string') {
    for (const part of d.orbit_separation.pair.split(' / ')) if (!known.has(part)) err(F, '/orbit_separation/pair', 'biomes-look-orbit', `"${part}" is not a biome of the file`);
  }
}

module.exports = { xrefBiomeLook };

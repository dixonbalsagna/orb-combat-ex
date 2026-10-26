'use strict';
// Cross-reference rules for Audio's audio/data/world_cues.json (called from xref-fight.js):
//   world-cues-default  default_biome is a key of biomes
//   world-cues-bed      each biome's `bed` is a key of beds, and every bed is played by some biome
//   world-cues-soil     each soil key is a biome and each soil value is a surface
//   world-cues-ground   each ground key is a biome and each ground value is a surface
//   world-cues-water    each water sound (fill, seep, wave, douse) is a sound of `sounds`, and counts as used
//   world-cues-surface  each surface's hit and slide are sounds, and every sound belongs to some surface or to `water`

const F = 'audio/data/world_cues.json';

function xrefWorldCues({ get, err, esc, isObj }) {
  const d = get(F);
  if (!isObj(d)) return;
  const keys = (o) => (isObj(o) ? Object.keys(o).filter((k) => !k.startsWith('_')) : []);
  const biomes = keys(d.biomes), beds = new Set(keys(d.beds)), sounds = new Set(keys(d.sounds)), surfaces = new Set(keys(d.surfaces));
  if (typeof d.default_biome === 'string' && biomes.length && !biomes.includes(d.default_biome)) err(F, '/default_biome', 'world-cues-default', `"${d.default_biome}" is not a biome of \`biomes\``);
  const usedBeds = new Set();
  for (const b of biomes) {
    const e = d.biomes[b];
    if (!isObj(e) || typeof e.bed !== 'string') continue;
    usedBeds.add(e.bed);
    if (beds.size && !beds.has(e.bed)) err(F, `/biomes/${esc(b)}/bed`, 'world-cues-bed', `${b} plays the bed "${e.bed}", which is not in \`beds\``);
  }
  for (const b of beds) if (biomes.length && !usedBeds.has(b)) err(F, `/beds/${esc(b)}`, 'world-cues-bed', `the bed "${b}" is played by no biome`);
  for (const [k, v] of Object.entries(isObj(d.soil) ? d.soil : {})) {
    if (k.startsWith('_')) continue;
    if (biomes.length && !biomes.includes(k)) err(F, `/soil/${esc(k)}`, 'world-cues-soil', `"${k}" is not a biome of \`biomes\``);
    if (typeof v === 'string' && surfaces.size && !surfaces.has(v)) err(F, `/soil/${esc(k)}`, 'world-cues-soil', `${k} lies on "${v}", which is not a surface of \`surfaces\``);
  }
  for (const [k, v] of Object.entries(isObj(d.ground) ? d.ground : {})) {
    if (k.startsWith('_')) continue;
    if (biomes.length && !biomes.includes(k)) err(F, `/ground/${esc(k)}`, 'world-cues-ground', `"${k}" is not a biome of \`biomes\``);
    if (typeof v === 'string' && surfaces.size && !surfaces.has(v)) err(F, `/ground/${esc(k)}`, 'world-cues-ground', `${k} is "${v}", which is not a surface of \`surfaces\``);
  }
  const usedSounds = new Set();
  for (const s of surfaces) {
    const e = d.surfaces[s];
    if (!isObj(e)) continue;
    for (const part of ['hit', 'slide']) {
      if (typeof e[part] !== 'string') continue;
      usedSounds.add(e[part]);
      if (sounds.size && !sounds.has(e[part])) err(F, `/surfaces/${esc(s)}/${part}`, 'world-cues-surface', `${s}'s ${part} sound "${e[part]}" is not in \`sounds\``);
    }
  }
  for (const [k, e] of Object.entries(isObj(d.water) ? d.water : {})) {
    if (k.startsWith('_') || !isObj(e)) continue;
    for (const part of ['sound', 'seep']) {
      if (typeof e[part] !== 'string') continue;
      usedSounds.add(e[part]);
      if (sounds.size && !sounds.has(e[part])) err(F, `/water/${esc(k)}/${part}`, 'world-cues-water', `water ${k}'s ${part} sound "${e[part]}" is not in \`sounds\``);
    }
  }
  for (const s of sounds) if (surfaces.size && !usedSounds.has(s)) err(F, `/sounds/${esc(s)}`, 'world-cues-surface', `the sound "${s}" belongs to no surface`);
}

module.exports = { xrefWorldCues };

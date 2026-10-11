'use strict';
// Cross-reference rules for Audio's audio/data/brawl_cues.json, copied to tools/lib/xref-brawl-cues.js by docs/tools/pending/apply-audio-brawl-cues.cjs and called from xref-fight.js:
//   brawl-cue-sound  every sound (and a bolt's lite sound and a landing's own sound) is synthesised in audio/data/impacts.json `sounds`
//   brawl-cue-bus    every bus (launcher.bus, charge.full.bus, every duck entry) is a bus of audio/data/mix.json
//   brawl-cue-order  hit pitch_min <= pitch_max and gain_db_min <= gain_db_max; windup and energy.gather pitch_min <= pitch_max; strength.fallback_amounts medium_from < heavy_from;
//                    windup.classes[].max_ticks strictly rise

const CUES = 'audio/data/brawl_cues.json';

function xrefBrawlCues({ get, err, esc, isObj }) {
  const d = get(CUES);
  if (!isObj(d)) return;
  const impacts = get('audio/data/impacts.json');
  const mix = get('audio/data/mix.json');
  const sounds = isObj(impacts) && isObj(impacts.sounds) ? new Set(Object.keys(impacts.sounds).filter((k) => !k.startsWith('_'))) : null;
  const buses = isObj(mix) && Array.isArray(mix.buses) ? new Set(mix.buses.map((b) => b && b.name)) : null;
  const walk = (o, path) => {
    if (Array.isArray(o)) { o.forEach((x, i) => walk(x, `${path}/${i}`)); return; }
    if (!isObj(o)) return;
    for (const [k, v] of Object.entries(o)) {
      if (k.startsWith('_')) continue;
      const here = `${path}/${esc(k)}`;
      if ((k === 'sound' || k === 'lite') && typeof v === 'string' && sounds && !sounds.has(v)) err(CUES, here, 'brawl-cue-sound', `sound "${v}" is not synthesised in audio/data/impacts.json`);
      if (k === 'bus' && typeof v === 'string' && buses && !buses.has(v)) err(CUES, here, 'brawl-cue-bus', `bus "${v}" is not a bus of audio/data/mix.json (${[...buses].join(', ')})`);
      walk(v, here);
    }
  };
  walk(d, '');
  const lt = (a, b, ptr, label) => { if (typeof a === 'number' && typeof b === 'number' && a > b) err(CUES, ptr, 'brawl-cue-order', label); };
  if (isObj(d.hit)) {
    lt(d.hit.pitch_min, d.hit.pitch_max, '/hit/pitch_min', `hit pitch_min ${d.hit.pitch_min} is above pitch_max ${d.hit.pitch_max}`);
    lt(d.hit.gain_db_min, d.hit.gain_db_max, '/hit/gain_db_min', `hit gain_db_min ${d.hit.gain_db_min} is above gain_db_max ${d.hit.gain_db_max}`);
  }
  if (isObj(d.windup)) {
    lt(d.windup.pitch_min, d.windup.pitch_max, '/windup/pitch_min', `windup pitch_min ${d.windup.pitch_min} is above pitch_max ${d.windup.pitch_max}`);
    if (Array.isArray(d.windup.classes)) {
      for (let i = 1; i < d.windup.classes.length; i++) {
        const a = d.windup.classes[i - 1], b = d.windup.classes[i];
        if (isObj(a) && isObj(b) && typeof a.max_ticks === 'number' && typeof b.max_ticks === 'number' && b.max_ticks <= a.max_ticks) err(CUES, `/windup/classes/${i}/max_ticks`, 'brawl-cue-order', `wind-up class max_ticks ${b.max_ticks} must be above the one before (${a.max_ticks})`);
      }
    }
  }
  if (isObj(d.energy) && isObj(d.energy.gather)) lt(d.energy.gather.pitch_min, d.energy.gather.pitch_max, '/energy/gather/pitch_min', `gather pitch_min ${d.energy.gather.pitch_min} is above pitch_max ${d.energy.gather.pitch_max}`);
  if (isObj(d.strength) && isObj(d.strength.fallback_amounts)) {
    const f = d.strength.fallback_amounts;
    if (typeof f.medium_from === 'number' && typeof f.heavy_from === 'number' && f.medium_from >= f.heavy_from) err(CUES, '/strength/fallback_amounts/medium_from', 'brawl-cue-order', `medium_from ${f.medium_from} must be below heavy_from ${f.heavy_from}`);
  }
}

module.exports = { xrefBrawlCues };

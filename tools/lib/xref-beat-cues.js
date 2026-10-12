'use strict';
// Cross-reference rules for Audio's audio/data/beat_cues.json, copied to tools/lib/xref-beat-cues.js by docs/tools/pending/apply-audio-beat-cues.cjs and called from xref-fight.js:
//   beat-cue-sound  every sound a cue names (a `sound`, `close`, `spark` or `note` value of the chain's blocks, `by_strength.*`, `grind.sound`, `rest.sound`, `charge_y.*.sound`) is synthesised in
//                   audio/data/impacts.json `sounds`
//   beat-cue-bus    every bus (perfect.bus, charge_y.full.bus) is a bus of audio/data/mix.json
//   beat-cue-order  the chord ratios of perfect.own and perfect.foe rise strictly; spark_clear.ticks is at most spark_clear.max_wait

const CUES = 'audio/data/beat_cues.json';
const SOUND_KEYS = new Set(['sound', 'close', 'spark']);

function xrefBeatCues({ get, err, esc, isObj }) {
  const d = get(CUES);
  if (!isObj(d)) return;
  const impacts = get('audio/data/impacts.json');
  const mix = get('audio/data/mix.json');
  const sounds = isObj(impacts) && isObj(impacts.sounds) ? new Set(Object.keys(impacts.sounds).filter((k) => !k.startsWith('_'))) : null;
  const buses = isObj(mix) && Array.isArray(mix.buses) ? new Set(mix.buses.map((b) => b && b.name)) : null;
  const checkSound = (v, ptr) => { if (typeof v === 'string' && sounds && !sounds.has(v)) err(CUES, ptr, 'beat-cue-sound', `sound "${v}" is not synthesised in audio/data/impacts.json`); };
  const walk = (o, path, inStrength) => {
    if (!isObj(o)) return;
    for (const [k, v] of Object.entries(o)) {
      if (k.startsWith('_')) continue;
      if (k === 'cls') continue;   // class names (the voice-limit groups), not sounds
      const here = `${path}/${esc(k)}`;
      if (inStrength) checkSound(v, here);
      else if (SOUND_KEYS.has(k)) checkSound(v, here);
      else if (k === 'note' && path.endsWith('/foe')) checkSound(v, here);   // the opponent's note: this key names a sound there
      if (k === 'bus' && typeof v === 'string' && buses && !buses.has(v)) err(CUES, here, 'beat-cue-bus', `bus "${v}" is not a bus of audio/data/mix.json (${[...buses].join(', ')})`);
      if (isObj(v)) walk(v, here, k === 'by_strength');
    }
  };
  walk(d, '', false);
  const rise = (arr, ptr) => {
    if (!Array.isArray(arr)) return;
    for (let i = 1; i < arr.length; i++) {
      if (typeof arr[i] === 'number' && typeof arr[i - 1] === 'number' && arr[i] <= arr[i - 1]) err(CUES, `${ptr}/${i}`, 'beat-cue-order', `ratio ${arr[i]} must be above the one before (${arr[i - 1]}): the chain's notes rise`);
    }
  };
  if (isObj(d.perfect)) {
    if (isObj(d.perfect.own)) rise(d.perfect.own.ratios, '/perfect/own/ratios');
    if (isObj(d.perfect.foe)) rise(d.perfect.foe.ratios, '/perfect/foe/ratios');
    const sc = d.perfect.spark_clear;
    if (isObj(sc) && typeof sc.ticks === 'number' && typeof sc.max_wait === 'number' && sc.ticks > sc.max_wait) err(CUES, '/perfect/spark_clear/ticks', 'beat-cue-order', `ticks ${sc.ticks} is above max_wait ${sc.max_wait}`);
  }
}

module.exports = { xrefBeatCues };

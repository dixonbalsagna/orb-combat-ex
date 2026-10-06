'use strict';
// Cross-reference rules for Art's two data files, copied to tools/lib/xref-art.js by docs/tools/pending/apply-art-sky-colour.cjs and called from xref-fight.js:
// data/art/sky.json (sky-key-id, sky-key-phase, sky-start-key, sky-anchor-order, sky-transitions, sky-time, sky-rate-limit, sky-lane-colours) and
// data/art/colour-vision.json (colour-vision-fighters, colour-vision-body). The rules are described in the script's header and in docs/tools/README.md.

const SKY = 'data/art/sky.json';
const CVF = 'data/art/colour-vision.json';
const BANDS = ['horizon', 'lower', 'upper', 'top'];
const VISIONS = ['protan', 'deutan', 'tritan'];
const NOT_FIGHTER = ['chosen_by', 'measured_dE00_under_this_vision'];

function xrefArt({ get, err, esc, isObj }) {
  xrefUiColour({ get, err, esc, isObj });
  const sky = get(SKY);
  const cv = get(CVF);
  if (isObj(sky)) {
    const keys = Array.isArray(sky.keys) ? sky.keys : [];
    const ids = new Set();
    keys.forEach((k, i) => {
      if (!isObj(k)) return;
      if (typeof k.id === 'string') {
        if (ids.has(k.id)) err(SKY, `/keys/${i}/id`, 'sky-key-id', `key id "${k.id}" is used twice`);
        ids.add(k.id);
      }
      if (i > 0 && isObj(keys[i - 1]) && typeof k.phase === 'number' && typeof keys[i - 1].phase === 'number' && k.phase <= keys[i - 1].phase) {
        err(SKY, `/keys/${i}/phase`, 'sky-key-phase', `phase ${k.phase} must be above the one before (${keys[i - 1].phase})`);
      }
    });
    if (isObj(sky.start) && typeof sky.start.key === 'string' && ids.size && !ids.has(sky.start.key)) {
      err(SKY, '/start/key', 'sky-start-key', `start key "${sky.start.key}" is not a key id (${[...ids].join(', ')})`);
    }
    const an = sky.anchors_half_screens;
    if (isObj(an)) {
      for (let i = 1; i < BANDS.length; i++) {
        if (typeof an[BANDS[i]] === 'number' && typeof an[BANDS[i - 1]] === 'number' && an[BANDS[i]] <= an[BANDS[i - 1]]) {
          err(SKY, `/anchors_half_screens/${BANDS[i]}`, 'sky-anchor-order', `${BANDS[i]} (${an[BANDS[i]]}) must be above ${BANDS[i - 1]} (${an[BANDS[i - 1]]})`);
        }
      }
    }
    if (isObj(sky.blend) && Array.isArray(sky.blend.transitions) && keys.length >= 2) {
      const tr = sky.blend.transitions;
      keys.forEach((k, i) => {
        const next = keys[(i + 1) % keys.length];
        if (!isObj(k) || !isObj(next) || typeof k.id !== 'string') return;
        const at = tr.findIndex((x) => isObj(x) && x.from === k.id);
        if (at < 0) err(SKY, '/blend/transitions', 'sky-transitions', `no transition leaves key "${k.id}"`);
        else if (tr[at].to !== next.id) err(SKY, `/blend/transitions/${at}/to`, 'sky-transitions', `the transition from "${k.id}" goes to "${tr[at].to}", the next key is "${next.id}"`);
      });
      tr.forEach((x, i) => {
        if (isObj(x) && typeof x.from === 'string' && tr.findIndex((y) => isObj(y) && y.from === x.from) !== i) err(SKY, `/blend/transitions/${i}/from`, 'sky-transitions', `two transitions leave "${x.from}"`);
      });
      if (tr.length !== keys.length) err(SKY, '/blend/transitions', 'sky-transitions', `${tr.length} transitions for ${keys.length} keys`);
    }
    const tm = sky.time;
    if (isObj(tm) && typeof tm.cycles_per_minute === 'number' && typeof tm.cycle_minutes === 'number' && tm.cycles_per_minute > 0 && Math.abs(tm.cycle_minutes * tm.cycles_per_minute - 1) > 0.01) {
      err(SKY, '/time/cycle_minutes', 'sky-time', `cycle_minutes ${tm.cycle_minutes} is not 1 / cycles_per_minute (${(1 / tm.cycles_per_minute).toFixed(2)})`);
    }
    const rl = sky.rate_limit;
    if (isObj(rl)) {
      for (const k of ['total', 'place_and_time', 'mood']) {
        if (isObj(rl[k]) && typeof rl[k].mean === 'number' && typeof rl[k].band === 'number' && rl[k].mean > rl[k].band) err(SKY, `/rate_limit/${k}/mean`, 'sky-rate-limit', `${k} mean ${rl[k].mean} is above its band ${rl[k].band}`);
      }
      if (isObj(rl.total) && typeof rl.total.band === 'number') {
        for (const k of ['place_and_time', 'mood']) {
          if (isObj(rl[k]) && typeof rl[k].band === 'number' && rl[k].band > rl.total.band) err(SKY, `/rate_limit/${k}/band`, 'sky-rate-limit', `${k} band ${rl[k].band} is above the total band ${rl.total.band}`);
        }
      }
      if (isObj(rl.weights)) {
        const s = BANDS.reduce((a, b) => a + (typeof rl.weights[b] === 'number' ? rl.weights[b] : 0), 0);
        if (Math.abs(s - 1) > 0.001) err(SKY, '/rate_limit/weights', 'sky-rate-limit', `the band weights sum to ${s.toFixed(3)}, not 1`);
      }
    }
    if (isObj(sky.readability) && isObj(sky.readability.lane_colours) && isObj(cv) && isObj(cv.default)) {
      for (const [lane, who] of [['P', 'protagonist'], ['A', 'rival']]) {
        const a = sky.readability.lane_colours[lane];
        const b = isObj(cv.default[who]) ? cv.default[who].aura : undefined;
        if (typeof a === 'string' && typeof b === 'string' && a.toLowerCase() !== b.toLowerCase()) err(SKY, `/readability/lane_colours/${lane}`, 'sky-lane-colours', `lane colour ${a} is not the default aura of ${who} in ${CVF} (${b})`);
      }
    }
  }
  if (isObj(cv) && isObj(cv.default) && isObj(cv.presets)) {
    const roster = get('data/fighters/roster.json');
    // the self-test runs against the validator's fixture roster (FIXTURE_HERO and the like), which no live file names: the roster half of the rule is skipped there, as finisher-fighter does
    const rosterLive = Array.isArray(roster) && !roster.every((x) => typeof x === 'string' && x.startsWith('FIXTURE_'));
    const fighters = Object.keys(cv.default).filter((k) => !k.startsWith('_'));
    for (const p of VISIONS) {
      const pr = cv.presets[p];
      if (!isObj(pr)) continue;
      for (const id of fighters) if (!isObj(pr[id])) err(CVF, `/presets/${p}`, 'colour-vision-fighters', `the ${p} preset has no colours for "${id}", who has default colours`);
      for (const id of Object.keys(pr)) {
        if (!id.startsWith('_') && !NOT_FIGHTER.includes(id) && !fighters.includes(id)) err(CVF, `/presets/${p}/${esc(id)}`, 'colour-vision-fighters', `the ${p} preset names "${id}", who has no default colours`);
      }
      for (const id of fighters) {
        const a = pr[id], d = cv.default[id];
        if (isObj(a) && isObj(d) && typeof a.col === 'string' && typeof d.col === 'string' && a.col.toLowerCase() !== d.col.toLowerCase()) {
          err(CVF, `/presets/${p}/${esc(id)}/col`, 'colour-vision-body', `the ${p} preset changes ${id}'s body colour (${a.col}, the default is ${d.col}): a preset remaps only the aura`);
        }
      }
    }
    if (rosterLive) {
      const ids = roster.map((x) => String(x).toLowerCase());
      for (const id of ids) if (!fighters.includes(id)) err(CVF, '/default', 'colour-vision-fighters', `roster fighter "${id}" has no colours`);
      for (const f of fighters) if (!ids.includes(f)) err(CVF, `/default/${esc(f)}`, 'colour-vision-fighters', `"${f}" is not a roster fighter (${ids.join(', ')})`);
    }
  }
}

// UI's colour-blind presets (ui/data/colour_vision.json): the choices and the presets agree, the lanes are Art's auras, the alias names an Art fighter.
function xrefUiColour({ get, err, esc, isObj }) {
  const UI = 'ui/data/colour_vision.json';
  const ui = get(UI);
  if (!isObj(ui)) return;
  const presets = isObj(ui.presets) ? ui.presets : {};
  const choices = Array.isArray(ui.choices) ? ui.choices : [];
  if (choices.length && !choices.includes('off')) err(UI, '/choices', 'ui-colour-choices', 'choices must hold "off"');
  for (const c of choices) if (c !== 'off' && !isObj(presets[c])) err(UI, '/choices', 'ui-colour-choices', `choice "${c}" has no preset`);
  for (const p of Object.keys(presets)) if (!p.startsWith('_') && choices.length && !choices.includes(p)) err(UI, `/presets/${esc(p)}`, 'ui-colour-choices', `preset "${p}" is not one of the choices (${choices.join(', ')})`);
  const art = get('data/art/colour-vision.json');
  if (!isObj(art) || !isObj(art.presets) || !isObj(art.default)) return;
  for (const [p, pr] of Object.entries(presets)) {
    if (p.startsWith('_') || !isObj(pr) || !isObj(pr.lanes) || !isObj(art.presets[p])) continue;
    for (const [id, hex] of Object.entries(pr.lanes)) {
      if (id.startsWith('_') || typeof hex !== 'string') continue;
      const a = isObj(art.presets[p][id]) ? art.presets[p][id].aura : undefined;
      if (typeof a !== 'string') err(UI, `/presets/${esc(p)}/lanes/${esc(id)}`, 'ui-colour-lanes', `"${id}" has no aura in the ${p} preset of data/art/colour-vision.json`);
      else if (a.toLowerCase() !== hex.toLowerCase()) err(UI, `/presets/${esc(p)}/lanes/${esc(id)}`, 'ui-colour-lanes', `lane colour ${hex} is not Art's ${p} aura for ${id} (${a})`);
    }
  }
  if (isObj(ui.fighter_alias)) for (const [k, v] of Object.entries(ui.fighter_alias)) if (!k.startsWith('_') && typeof v === 'string' && !isObj(art.default[v])) err(UI, `/fighter_alias/${esc(k)}`, 'ui-colour-alias', `"${k}" is aliased to "${v}", who is not a fighter of data/art/colour-vision.json`);
}

module.exports = { xrefArt, xrefUiColour };

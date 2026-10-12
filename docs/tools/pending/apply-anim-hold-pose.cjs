// Animation's press-styles additions of 2026-10-12 (the charged medium and heavy's held look and the plain light's pin): data/anim/press_styles.json gains
//   styles.<style>.hold.pose   optional: a map of fighter (a fighter of data/anim/fighters.json) to the pose the hold is held in (a pose of poses.json or a wave's poses file): rule pressstyles-hold
//   beat.plain_light.pin_ticks required: the ticks a plain light's pose is pinned (an integer 0 to 60)
//   beat.bolt_recover_add      required (Animation's follow-up, 2026-10-12; added optional by the EP in 115ee361): an integer 0 to 8, the ticks added to a bolt's return
// NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands the data:
//     node docs/tools/pending/apply-anim-hold-pose.cjs
// It does NOT edit data/. It edits tools/schemas/anim-press-styles.schema.json, tools/lib/xref-fight.js (the hold loop of the press-styles block), tools/fixtures/cases.json and
// docs/tools/README.md. Re-runnable (a second run changes nothing). Every case sets its own whole block.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const clone = (o) => JSON.parse(JSON.stringify(o));
const D = 'data/anim/press_styles.json';
const live = rj(D);
if (!live.beat || !live.beat.plain_light) throw new Error('data/anim/press_styles.json has no beat.plain_light yet: run this in the commit that lands it');

{
  const f = 'tools/schemas/anim-press-styles.schema.json';
  const s = rj(f);
  const styleProps = s.properties.styles.properties;
  const poseMap = clone(s.properties.styles.properties.burst.properties.set.properties.pose);
  poseMap.description = 'A fighter of fighters.json to the pose the hold is held in (rule pressstyles-hold: a fighter of fighters.json and a real pose).';
  for (const k of Object.keys(styleProps)) {
    const h = styleProps[k].properties && styleProps[k].properties.hold;
    if (h && h.properties && !h.properties.pose) h.properties.pose = poseMap;
  }
  const beat = s.properties.beat;
  if (!beat.properties.plain_light) {
    beat.properties.plain_light = {
      type: 'object',
      required: ['pin_ticks'],
      description: 'A plain light (no beat, no grade): its pose is pinned for this many ticks at the contact.',
      properties: { pin_ticks: { type: 'integer', minimum: 0, maximum: 60, description: 'Ticks the pose is pinned.' } },
      additionalProperties: false,
      patternProperties: { '^_': true },
    };
    if (!beat.required.includes('plain_light')) beat.required.push('plain_light');
  }
  if (beat.properties.bolt_recover_add && !beat.required.includes('bolt_recover_add')) beat.required.push('bolt_recover_add');
  wj(f, s);
}
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  if (!t.includes("'pressstyles-hold', `hold pose")) {
    const a = "      if (typeof st.hold.from === 'number' && typeof st.hold.to === 'number' && st.hold.from >= st.hold.to) err(PS, `/styles/${esc(sid)}/hold/from`, 'pressstyles-hold', `hold from ${st.hold.from} must be below to ${st.hold.to}`);\n";
    if (!t.includes(a)) throw new Error('hold anchor');
    t = t.replace(a, () => a + [
      "      if (isObj(st.hold.pose)) {",
      "        const fgsHold = get('data/anim/fighters.json');",
      "        const fidsHold = isObj(fgsHold) && isObj(fgsHold.fighters) ? Object.keys(fgsHold.fighters).filter((k) => !k.startsWith('_')) : [];",
      "        for (const [fk, pid] of Object.entries(st.hold.pose)) {",
      "          if (fk.startsWith('_')) continue;",
      "          if (fidsHold.length && !fidsHold.includes(fk)) err(PS, `/styles/${esc(sid)}/hold/pose/${esc(fk)}`, 'pressstyles-hold', `hold pose names \"${fk}\", who is not a fighter of fighters.json (${fidsHold.join(', ')})`);",
      "          if (typeof pid === 'string' && allPosesPs.size && !allPosesPs.has(pid)) err(PS, `/styles/${esc(sid)}/hold/pose/${esc(fk)}`, 'pressstyles-hold', `hold pose \"${pid}\" is not in poses.json nor a wave's poses`);",
      "        }",
      "      }",
      "",
    ].join('\n'));
    if (crlf) t = t.replace(/\n/g, '\r\n');
    fs.writeFileSync(f, t);
  }
}
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const out = [];
  const holdStyle = ['medium', 'super'].find((k) => live.styles[k] && live.styles[k].hold && live.styles[k].hold.pose);
  const H = live.styles[holdStyle].hold;
  const fighters = Object.keys(H.pose);
  const f0 = fighters[0];
  const hc = (n, tweak, expect) => { const h = clone(H); tweak(h); out.push({ id: 'anim-press-styles-hold-pose-' + n, schema: 'anim-press-styles.schema.json', mutate: [{ file: D, set: { [`/styles/${holdStyle}/hold`]: h } }], expect }); };
  const hp = `/styles/${holdStyle}/hold/pose`;
  hc('valid', () => {}, null);
  hc('absent-ok', (h) => { delete h.pose; }, null);
  hc('empty', (h) => { h.pose = {}; }, { rule: 'minProperties', pointer: hp });
  hc('type', (h) => { h.pose = 'ch.y_p.load'; }, { rule: 'type', pointer: hp });
  hc('pose-id-shape', (h) => { h.pose[f0] = 'Load Pose'; }, { rule: 'pattern', pointer: `${hp}/${f0}` });
  hc('pose-id-type', (h) => { h.pose[f0] = 5; }, { rule: 'type', pointer: `${hp}/${f0}` });
  hc('fighter-key-shape', (h) => { h.pose['Not A Fighter'] = h.pose[f0]; }, { rule: 'propertyNames', pointer: `${hp}/Not A Fighter` });
  hc('fighter-unknown', (h) => { h.pose.nobody = h.pose[f0]; }, { rule: 'xref:pressstyles-hold', pointer: `${hp}/nobody` });
  hc('pose-unknown', (h) => { h.pose[f0] = 'ch.nowhere.load'; }, { rule: 'xref:pressstyles-hold', pointer: `${hp}/${f0}` });
  hc('note-key-ok', (h) => { h.pose._why = 'a note'; }, null);
  const bc = (n, set, del, expect) => out.push({ id: 'anim-press-styles-beat-' + (n.startsWith('bolt-') ? '' : 'plain-light-') + n, schema: 'anim-press-styles.schema.json', mutate: [{ file: D, ...(set ? { set } : {}), ...(del ? { del } : {}) }], expect });
  const PL = '/beat/plain_light';
  bc('required', null, [PL], { rule: 'required', pointer: '/beat' });
  bc('type', { [PL]: 6 }, null, { rule: 'type', pointer: PL });
  bc('pin-ticks-required', null, [`${PL}/pin_ticks`], { rule: 'required', pointer: PL });
  bc('unknown-key', { [`${PL}/hold_ticks`]: 6 }, null, { rule: 'additionalProperties', pointer: `${PL}/hold_ticks` });
  bc('note-key-ok', { [`${PL}/_why`]: 'a note' }, null, null);
  bc('pin-ticks-negative', { [`${PL}/pin_ticks`]: -1 }, null, { rule: 'minimum', pointer: `${PL}/pin_ticks` });
  bc('pin-ticks-above-max', { [`${PL}/pin_ticks`]: 61 }, null, { rule: 'maximum', pointer: `${PL}/pin_ticks` });
  bc('pin-ticks-integer', { [`${PL}/pin_ticks`]: 5.5 }, null, { rule: 'type', pointer: `${PL}/pin_ticks` });
  bc('pin-ticks-type', { [`${PL}/pin_ticks`]: 'six' }, null, { rule: 'type', pointer: `${PL}/pin_ticks` });
  bc('pin-ticks-zero-ok', { [`${PL}/pin_ticks`]: 0 }, null, null);
  bc('pin-ticks-max-ok', { [`${PL}/pin_ticks`]: 60 }, null, null);
  const BR = '/beat/bolt_recover_add';
  bc('bolt-recover-add-required', null, [BR], { rule: 'required', pointer: '/beat' });
  bc('bolt-recover-add-type', { [BR]: 'three' }, null, { rule: 'type', pointer: BR });
  bc('bolt-recover-add-integer', { [BR]: 2.5 }, null, { rule: 'type', pointer: BR });
  bc('bolt-recover-add-negative', { [BR]: -1 }, null, { rule: 'minimum', pointer: BR });
  bc('bolt-recover-add-above-max', { [BR]: 9 }, null, { rule: 'maximum', pointer: BR });
  bc('bolt-recover-add-zero-ok', { [BR]: 0 }, null, null);
  bc('bolt-recover-add-max-ok', { [BR]: 8 }, null, null);
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`anim press styles hold pose and plain light applied (${n} new or changed cases)`);
}
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  const lines = t.split('\n');
  const i = lines.findIndex((l) => l.includes('`pressstyles-hold`'));
  if (i >= 0 && !/hold pose/.test(lines[i])) {
    lines[i] = lines[i].replace(/ \|$/, ' (a hold\'s `pose` map names fighters of fighters.json and real poses) |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}

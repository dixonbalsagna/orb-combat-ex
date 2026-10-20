// ci.cjs: the camera-intent feed (docs/director/camera-intent.md section 2), a render-only cue stream behind
// data/director/interrupts.json cameraIntent.enabled (false). It writes cues only, so with it on or off play and the
// golden don't move.
//   node ci.cjs <checkout root> [--check]
// Copies files/sim/director/camintent.gd (DirCamIntent) and its .uid when present, and hooks it in:
//   exchange.gd   a planned exchange's plan (beats, contacts, pauses, spans not to cut, story), once dressed
//   brawl.gd      each blow the director decides, at its throw; the AI's string as it starts it; the double hit
//   melee.gd      the send, from the plan
//   interrupt.gd  a perfect block marked at the guard press
//   grapple.gd    the clinch's tie-up
//   interrupts.json and its schema (Tools'): cameraIntent.enabled
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ci.cjs <checkout root> [--check]');
const check = opts.includes('--check');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
    t = t.replace(a, () => b);
  };
  fn(rep, t);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
if (!fs.existsSync(path.join(root, 'sim/director/grapple.gd'))) throw new Error('the grapple G1 first');
for (const f of ['camintent.gd', 'camintent.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}

edit('sim/director/exchange.gd', rep => {
  rep('\tDirRecipe.dress(S, ex)   # the alchemist: each strike of the plan takes a piece from the pool its fighter\'s style calls\n',
      '\tDirRecipe.dress(S, ex)   # the alchemist: each strike of the plan takes a piece from the pool its fighter\'s style calls\n' +
      '\tDirCamIntent.exchange(S, ex)   # the camera-intent feed: the planned beats and their climax (render-only)\n');
});
edit('sim/director/brawl.gd', rep => {
  rep('\t_s(f, LINE, 1)\n\t_s(f, KIND, kind)\n\t_s(f, CONTACT, now + lead)\n',
      '\tDirCamIntent.blow(S, f, o, args, S.tick + lead)   # the camera-intent feed: a close or a launcher, known at its throw\n' +
      '\t_s(f, LINE, 1)\n\t_s(f, KIND, kind)\n\t_s(f, CONTACT, now + lead)\n');
  rep('\t_s(ex.A, DBL_AT, _now(S) + lead)\n',
      '\t_s(ex.A, DBL_AT, _now(S) + lead)\n\tDirCamIntent.doubleHit(S, ex, S.tick + lead)\n');
  rep('\t_aiPress(S, f, i, _aiPick(S, ex, f, bl), bl)\n\t_aiNudge(S, ex, f, true)\n',
      '\t_aiPress(S, f, i, _aiPick(S, ex, f, bl), bl)\n\t_aiNudge(S, ex, f, true)\n' +
      '\tDirCamIntent.aiString(S, f, o, _g(f, AI_LEFT) + 1, _g(f, AI_GAP), int(c.light.contactTicks))   # the camera-intent feed: the AI\'s string, as it starts it\n');
});
edit('sim/director/melee.gd', rep => {
  rep('\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n',
      '\tDirCamIntent.launch(S, att, tgt, r.best)   # the camera-intent feed: the send\'s plan (render-only)\n' +
      '\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n');
});
edit('sim/director/launch.gd', rep => {
  // the prediction's touchdown, beside its rest point, for the camera (the planner reads neither new field)
  rep('## and never writes state. Returns {"x": landing x, "travel": horizontal distance, "water": ends in the sea}.\n',
      '## and never writes state. Returns {"x": landing x, "travel": horizontal distance, "water": ends in the sea}, with "t"\n' +
      '## the time to the first touchdown, "land" its x and "slide" what a knock-back slide adds after it (the camera-intent feed).\n');
  rep('\t\t\t\treturn {"x": x, "travel": absf(travel), "water": true, "t": t}\n',
      '\t\t\t\treturn {"x": x, "travel": absf(travel), "water": true, "t": t, "land": x}\n');
  rep('\t\t\t\treturn {"x": x, "travel": absf(travel), "water": sea, "t": t}\n',
      '\t\t\t\treturn {"x": x, "travel": absf(travel), "water": sea, "t": t, "land": x}\n');
  rep('\t\t\treturn {"x": SimWrap.wrap(x + dir * d), "travel": absf(travel) + d, "water": false, "t": t}\n',
      '\t\t\treturn {"x": SimWrap.wrap(x + dir * d), "travel": absf(travel) + d, "water": false, "t": t, "land": x, "slide": d}\n');
  rep('\treturn {"x": x, "travel": absf(travel), "water": y < 0.0 and WorldTerrain.seaAt(S, x), "t": t}\n',
      '\treturn {"x": x, "travel": absf(travel), "water": y < 0.0 and WorldTerrain.seaAt(S, x), "t": t, "land": x}\n');
});
edit('sim/director/interrupt.gd', rep => {
  rep('\telse:\n\t\tb.args.o["perfect"] = true\n\treturn true\n',
      '\telse:\n\t\tb.args.o["perfect"] = true\n\tDirCamIntent.read(S, f, S.dirS.ex, b)   # the camera-intent feed: who wins the read\n\treturn true\n');
});
edit('sim/director/grapple.gd', rep => {
  rep('\te.n = S.tick\n\tSimEvents.feed(S, "CLINCH", f.name + " ties up "',
      '\te.n = S.tick\n\tDirCamIntent.clinch(S, f, o, S.tick, int(c.max), int(c.pulse))   # the camera-intent feed: the clinch\'s clock\n\tSimEvents.feed(S, "CLINCH", f.name + " ties up "');
});
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "cameraIntent": {\n    "_note": "The camera-intent feed (sim/director/camintent.gd; docs/director/camera-intent.md): render-only cam_intent cues of what the director has decided ahead (a planned exchange\'s beats and climax, a brawl\'s close and launcher, the send\'s plan, a perfect block\'s read, the clinch\'s clock). enabled false: no cue. It writes cues only, so play is the same either way.",\n    "enabled": false\n  },\n  "grapple": {\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.cameraIntent) throw new Error('director-interrupts schema: cameraIntent exists already');
  s.properties.cameraIntent = { type: 'object', description: 'The camera-intent feed: render-only cues of what the director has decided ahead.',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: no cue.' } }, required: ['enabled'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: cameraIntent' + (check ? ' (checked)' : ''));
}

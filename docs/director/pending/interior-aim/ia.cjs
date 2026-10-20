// ia.cjs: the interior aim (World's finding; docs/director/camera-intent.md section 5), behind
// data/director/launch.json interiorAim.enabled (false). The planner's sends into a tower fly at 3 to 22 degrees, where
// the interior chain starts at 15 to 60. With it on and World's interior chain on, each building the planner can aim at
// also offers a send aimed inside the gate (World's aimInside, a grant), scored as any building send plus
// interiorAim.score by personality. Off: no candidate and no draw, so the golden doesn't move.
//   node ia.cjs <checkout root> [--check]
// Needs World's grant (grant_world.cjs: WorldBrunt.aimInside); without it the planner offers nothing new.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ia.cjs <checkout root> [--check]');
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
  fn(rep);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
edit('sim/director/launch.gd', rep => {
  rep('\t\t\t\tplan.s += float(town.get("bruntPrefer", 0.0))   # a building on the line, no stick held: preferred from this tier\n\t\t\tc.append(plan)\n',
      '\t\t\t\tplan.s += float(town.get("bruntPrefer", 0.0))   # a building on the line, no stick held: preferred from this tier\n\t\t\tc.append(plan)\n' +
      '\t\tvar ip = _insideAim(S, A, D, S.buildings[bi], force * (DirBrawl.freshMul(S, D, 4) if fresh else 1.0), tierF, longOnly, plan)\n' +
      '\t\tif ip != null and not (fwdOnly and float(ip.ux) * f < 0.0):\n' +
      '\t\t\thadBrunt = true\n' +
      '\t\t\tip.s = bruntScore(S, A, ip) + _insideScore(A)\n' +
      '\t\t\tif tilt == 0 and not town.is_empty() and A.tier >= float(town.get("bruntFromTier", 99.0)):\n' +
      '\t\t\t\tip.s += float(town.get("bruntPrefer", 0.0))\n' +
      '\t\t\tc.append(ip)\n');
  rep('static func bruntScore(S: SimState, A, plan: Dictionary) -> float:\n',
      '## The interior aim (launch.json interiorAim; World\'s finding, camera-intent.md section 5): with it on and World\'s interior\n' +
      '## chain on, a send into b aimed inside the chain\'s gate (WorldBrunt.aimInside over interiorAim.uy), when the low aim\n' +
      '## (low, aim\'s plan or null) would not start the chain itself. Null otherwise, and always with it off.\n' +
      'static func _insideAim(S: SimState, A, D, b, force: float, tierF: float, special: bool, low):\n' +
      '\tvar ia: Dictionary = data().get("interiorAim", {})\n' +
      '\tif not bool(ia.get("enabled", false)) or not WorldInterior.on(S):\n' +
      '\t\treturn null\n' +
      '\tif low != null and bool(low.brunt.hit.get("ok", false)) and WorldInterior.fits(S, b, float(low.brunt.hit.vx) / WorldSlide.launchTravel(float(low.ux), float(low.uy)), float(low.brunt.hit.vy)):\n' +
      '\t\treturn null   # the low aim already starts it\n' +
      '\tvar ai := Callable(WorldBrunt, "aimInside")\n' +
      '\tif not ai.is_valid():\n' +
      '\t\treturn null   # World\'s grant is not in\n' +
      '\treturn ai.call(S, A, D, b, force, tierF, special, ia.uy)\n\n\n' +
      '## What a send inside a tower is worth to him (interiorAim.score): by his care\'s sign, or his role at care 0 (hero;\n' +
      '## villain or rival), as the AI\'s launcher aim reads it. The Anti-hero seeks the chain; the hero avoids it.\n' +
      'static func _insideScore(A) -> float:\n' +
      '\tvar sc: Dictionary = data().get("interiorAim", {}).get("score", {})\n' +
      '\tvar pers: String = "hero" if A.care > 0.0 else ("villain" if A.care < 0.0 else "")\n' +
      '\tif pers == "":\n' +
      '\t\tvar dd = FighterData.def(A.id)\n' +
      '\t\tvar role: String = String(dd.get("role", "")) if dd is Dictionary else ""\n' +
      '\t\tpers = "hero" if role == "hero" else ("villain" if (role == "villain" or role == "rival") else "")\n' +
      '\treturn float(sc.get(pers, 0.0))\n\n\n' +
      'static func bruntScore(S: SimState, A, plan: Dictionary) -> float:\n');
});
edit('data/director/launch.json', rep => {
  rep('\n  "knockBack": {\n',
      '\n  "interiorAim": {\n    "_note": "The interior aim (sim/director/launch.gd _insideAim; docs/director/camera-intent.md section 5, World\'s finding): the planner\'s sends into a tower fly at 3 to 22 degrees, where World\'s interior chain starts at 15 to 60 (brunt.json interiorTanMin and interiorTanMax). With enabled and World\'s interiorChain on, each building also offers a send aimed inside the gate: World\'s aimInside over uy (each a send\'s upward part against its forward one), the first whose arrival fits. It is scored as any building send plus score by personality (hero, villain: the care\'s sign, or the role at care 0). Off: no candidate and no draw.",\n    "enabled": false,\n    "uy": [0.3, 0.45, 0.65, 0.9],\n    "score": {"hero": -8, "villain": 8}\n  },\n  "knockBack": {\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-launch.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.interiorAim) throw new Error('director-launch schema: interiorAim exists already');
  const out = {};
  for (const [k, v] of Object.entries(s.properties)) {
    if (k === 'knockBack') out.interiorAim = { type: 'object', description: 'The interior aim: a send aimed inside the interior chain\'s gate, offered beside the low one.',
      properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: no candidate.' },
        uy: { type: 'array', items: { type: 'number', exclusiveMinimum: 0 }, minItems: 1, description: 'The upward parts tried, in order.' },
        score: { type: 'object', properties: { hero: { type: 'number' }, villain: { type: 'number' } }, required: ['hero', 'villain'], additionalProperties: false, description: 'Added to its score by personality.' } },
      required: ['enabled', 'uy', 'score'], additionalProperties: false };
    out[k] = v;
  }
  if (!out.interiorAim) throw new Error('director-launch schema: no knockBack to precede');
  s.properties = out;
  if (s.required && !Array.isArray(s.required)) throw new Error('director-launch schema: odd required');
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-launch.schema.json: interiorAim' + (check ? ' (checked)' : ''));
}

// grant_world.cjs: World's part of the interior aim, for World's OK (sim/world/brunt.gd is World's). The planner's sends
// into a tower fly at 3 to 22 degrees (aim takes the first uy of AIM_UY that hits), where the interior chain starts at
// 15 to 60. aimInside gives the planner a send into b that arrives inside WorldInterior's band: the first of the
// planner's uys whose flight enters b as aim's does and fits. aim itself is unchanged (both share one loop).
//   node grant_world.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node grant_world.cjs <checkout root> [--check]');
const check = opts.includes('--check');
const rel = 'sim/world/brunt.gd';
const p = path.join(root, rel);
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const rep = (a, b) => {
  const n = t.split(a).length - 1;
  if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
  t = t.replace(a, () => b);
};
if (t.includes('static func aimInside')) throw new Error(rel + ': aimInside exists already');
rep('static func aim(S: SimState, A, D, b, force: float, tierF: float, special: bool = false):\n' +
    '\tvar sign_: float = 1.0 if SimWrap.sdx(D.x, b.x) >= 0.0 else -1.0\n' +
    '\tfor uy in AIM_UY:\n' +
    '\t\tvar trav: float = WorldSlide.launchTravel(sign_, uy)\n' +
    '\t\tvar fr: Dictionary = flightTo(S, D.x, D.y, WorldSlide.launchVX(sign_, uy, force * tierF), uy * force * tierF, trav, b, D.z)\n' +
    '\t\tif fr.ok and fr.spN >= AIM_MIN_SP:\n' +
    '\t\t\tvar chain: Array = chainPlan(S, tierOf(A, D), special, b, fr, trav)\n' +
    '\t\t\tvar edge: float = SimWrap.wrap(b.x - sign_ * b.w * 0.5)\n' +
    '\t\t\treturn {"ux": sign_, "uy": uy, "fm": 1.0, "name": "BUILDING SMASH",\n' +
    '\t\t\t\t"brunt": {"b": b.idx, "hit": fr, "chain": chain, "deaths": chainDeaths(chain), "z1": faceZ(b), "aimD": absf(SimWrap.sdx(D.x, edge))}}\n' +
    '\treturn null\n',
    'static func aim(S: SimState, A, D, b, force: float, tierF: float, special: bool = false):\n' +
    '\treturn _aimBy(S, A, D, b, force, tierF, special, AIM_UY, false)\n\n\n' +
    '## The planner\'s send aimed inside the interior chain\'s gate (sim/director/launch.gd interiorAim; World\'s finding of\n' +
    '## 2026-10-19): as aim, over the planner\'s uys, and only a flight whose arrival fits WorldInterior\'s angle band.\n' +
    '## Its "brunt" carries "inside": true. Null when none does.\n' +
    'static func aimInside(S: SimState, A, D, b, force: float, tierF: float, special: bool, uys: Array):\n' +
    '\treturn _aimBy(S, A, D, b, force, tierF, special, uys, true)\n\n\n' +
    'static func _aimBy(S: SimState, A, D, b, force: float, tierF: float, special: bool, uys: Array, inside: bool):\n' +
    '\tvar sign_: float = 1.0 if SimWrap.sdx(D.x, b.x) >= 0.0 else -1.0\n' +
    '\tfor uy in uys:\n' +
    '\t\tvar trav: float = WorldSlide.launchTravel(sign_, uy)\n' +
    '\t\tvar fr: Dictionary = flightTo(S, D.x, D.y, WorldSlide.launchVX(sign_, uy, force * tierF), uy * force * tierF, trav, b, D.z)\n' +
    '\t\tif fr.ok and fr.spN >= AIM_MIN_SP and (not inside or WorldInterior.fits(S, b, fr.vx / trav, fr.vy)):\n' +
    '\t\t\tvar chain: Array = chainPlan(S, tierOf(A, D), special, b, fr, trav)\n' +
    '\t\t\tvar edge: float = SimWrap.wrap(b.x - sign_ * b.w * 0.5)\n' +
    '\t\t\tvar plan := {"ux": sign_, "uy": float(uy), "fm": 1.0, "name": "BUILDING SMASH",\n' +
    '\t\t\t\t"brunt": {"b": b.idx, "hit": fr, "chain": chain, "deaths": chainDeaths(chain), "z1": faceZ(b), "aimD": absf(SimWrap.sdx(D.x, edge))}}\n' +
    '\t\t\tif inside:\n\t\t\t\tplan.brunt["inside"] = true\n' +
    '\t\t\treturn plan\n' +
    '\treturn null\n');
if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log(rel + (check ? ': anchors ok' : ': aimInside (aim unchanged)'));

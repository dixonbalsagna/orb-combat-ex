// grant_world.cjs: World's part of the wall kick, for World's OK (sim/world/brunt.gd is World's). Applies with the wall
// kick park (wk.cjs: DirWallKick) and after the recoil flips' grant (WorldContact.brakeEnd takes a kind).
// At a face that holds (WorldBrunt.hit, the wall slam), World asks DirWallKick.atWall before the fighter's damage. When the
// kick takes the contact: the slam's damage to him is DirWallKick.damageMul of it (both parts), there is no hold, no
// rebound and no stagger, and his journey ends at the face (journey_end kind "kick"); the face takes its hit as ever.
// Off (wallKick.enabled false), atWall is false and the hit is today's.
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
if (!fs.existsSync(path.join(root, 'sim/director/wallkick.gd')) && !check) throw new Error('the wall kick park (wk.cjs) first');
if (!fs.readFileSync(path.join(root, 'sim/world/contact.gd'), 'utf8').includes('static func brakeEnd(S: SimState, f, kind: String = "brake")')) throw new Error('the recoil flips\' World grant first (brakeEnd takes a kind)');
if (t.includes('DirWallKick')) throw new Error(rel + ': the wall kick is in already');
rep('\t# --- the fighter ---\n\tSimDamage.hurt(S, f, spN * FIGHTER_DMG, by)\n',
    '\t# --- the fighter ---\n' +
    '\t# The wall kick (Encounter\'s DirWallKick; rulings-2026-10-22 2b): an armed kick takes a face that holds. Its slam\n' +
    '\t# is damageMul of a slam; no hold, rebound or stagger; his journey ends here.\n' +
    '\tvar kicked: bool = not passes and not inside and DirWallKick.atWall(S, f, b, edge, dir, spN)\n' +
    '\tvar km: float = DirWallKick.damageMul() if kicked else 1.0\n' +
    '\tSimDamage.hurt(S, f, spN * FIGHTER_DMG * km, by)\n');
rep('\tif not passes:\n\t\t_hold(S, f, lodgeSeconds(tierB, f.launchSpecial))   # held at the wall for the lodge\'s seconds, then he comes off it\n',
    '\tif not passes:\n\t\tif not kicked:\n\t\t\t_hold(S, f, lodgeSeconds(tierB, f.launchSpecial))   # held at the wall for the lodge\'s seconds, then he comes off it\n');
rep('\t\t\tSimDamage.hurt(S, f, spN * FIGHTER_DMG * slam, by)\n',
    '\t\t\tSimDamage.hurt(S, f, spN * FIGHTER_DMG * slam * km, by)\n');
rep('\telse:\n\t\t# a rebound: a quarter of the speed backward, outside the near face; the chain ends\n',
    '\telif kicked:\n' +
    '\t\t# the kick-off is the director\'s (his rush or his push, set in atWall): the journey ends at the face\n' +
    '\t\tif S.contactOn:\n' +
    '\t\t\tWorldContact.brakeEnd(S, f, "kick")\n' +
    '\t\telse:\n' +
    '\t\t\tf.state = "free"\n\t\t\tf.stateT = 0.0\n\t\t\tf.launchBy = null\n\t\t\tf.launchT = 1.0\n\t\t\tf.launchSpecial = false\n\t\t\tendFlight(S, f)\n' +
    '\telse:\n\t\t# a rebound: a quarter of the speed backward, outside the near face; the chain ends\n');
if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log(rel + (check ? ': anchors ok' : ': the wall kick at a face that holds'));

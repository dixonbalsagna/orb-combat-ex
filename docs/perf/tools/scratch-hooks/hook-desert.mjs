// SCRATCH HOOK (scratch export only): a scene `desert`, both fighters idle on the keyboard's slots (no input) at the middle of the hand-made world's desert (x = 6,000 times the planet scale,
// 100 units apart), so the camera has one view of the desert's ground and nothing moves but the sky and the crowd. For benches of the ground's look (Rendering's biome look, 22n).
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
s = s.replace('"mashdummy", "ring"', '"desert", "mashdummy", "ring"');
s = s.replace('"mashdummy": [false, true]', '"desert": [false, false], "mashdummy": [false, true]');
const a1 = '\t\t"ai":           # the real AI match, forms readied at 300 and 1500, a tier raised at 900';
if (!s.includes(a1)) throw new Error('anchor ai scenario');
s = s.replace(a1, '\t\t"desert":\n\t\t\tif t == 0:\n\t\t\t\tfor i in range(2):\n\t\t\t\t\tvar f = S.fighters[i]\n\t\t\t\t\tf.x = SimWrap.wrap(6000.0 * WorldBiomes.P + 100.0 * float(i))\n\t\t\t\t\tf.y = WorldTerrain.groundY(S, f.x) + 10.0\n\t\t\t\t\tf.vx = 0.0\n\t\t\t\t\tf.vy = 0.0\n' + a1);
writeFileSync(p, s); console.log('desert hook applied');

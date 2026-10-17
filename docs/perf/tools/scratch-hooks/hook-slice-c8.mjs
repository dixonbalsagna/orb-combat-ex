// Scratch: add the coarse variants (_c8: the planet function every 8th column, the columns between interpolated) to the slice bench.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const a = '\tvar v := Vector3(0, 0, 1) if mode == "equator" else Vector3(0, 1, 0)\n';
if (!s.includes(a)) throw new Error('anchor a');
s = s.replace(a, '\tvar c8: bool = mode.ends_with("_c8")\n\tvar v := Vector3(0, 0, 1) if mode.begins_with("equator") else Vector3(0, 1, 0)\n');
const b = '\t\tfor i in range(4800):\n\t\t\tvar p: Vector3 = P.rot(u, v, float(i) * 32.0 / P.R)\n\t\t\tvar sf: Array = P.surf(p)\n\t\t\ths[i] = sf[0] + (P.fbm(p, 1500.0, 3, P.seed + 777) - 0.5) * 300.0\n\t\t\tP.biome(p, sf[0])\n';
if (!s.includes(b)) throw new Error('anchor b');
s = s.replace(b, '\t\tif c8:\n\t\t\tvar prev: float = 0.0\n\t\t\tfor k in range(0, 4801, 8):\n\t\t\t\tvar pc: Vector3 = P.rot(u, v, float(k) * 32.0 / P.R)\n\t\t\t\tvar sc: Array = P.surf(pc)\n\t\t\t\tvar hc: float = sc[0] + (P.fbm(pc, 1500.0, 3, P.seed + 777) - 0.5) * 300.0\n\t\t\t\tP.biome(pc, sc[0])\n\t\t\t\tif k > 0:\n\t\t\t\t\tfor j in range(1, 9):\n\t\t\t\t\t\tif k - 8 + j < 4800:\n\t\t\t\t\t\t\ths[k - 8 + j] = lerpf(prev, hc, float(j) / 8.0)\n\t\t\t\tprev = hc\n\t\telse:\n' + b.split('\n').map((l) => l ? '\t' + l : l).join('\n'));
writeFileSync(p, s);
console.log('c8 hook applied');

// SCRATCH HOOK: times Camera's cut dissolve (render/camera/split_view.gd _dissolve: the root viewport's get_image, the RGB8 convert, the ImageTexture upload) into PaneWorld.PT
// as "dissolve_readback", so a run of the "prof" variants shows what each cut costs and on which frames. Apply after hook-prof.mjs. Only for a revision that has the dissolve (f15d7de3 and later).
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/camera/split_view.gd';
let s = readFileSync(p, 'utf8');
const a = '\t\tvar img: Image = get_viewport().get_texture().get_image()\n';
if (!s.includes(a)) throw new Error('anchor: this revision has no cut dissolve');
s = s.replace(a, '\t\tvar _tdis: int = Time.get_ticks_usec()\n' + a);
const b = '\t\t\t_xf_start = now_t\n';
if (!s.includes(b)) throw new Error('anchor b');
s = s.replace(b, b + '\t\tPaneWorld._pt("dissolve_readback", _tdis)\n');
writeFileSync(p, s); console.log('dissolve timer applied');

// Scratch: page flag aura=1 turns VFX's 3D aura on (its transient burst rules); auradem=1 also sets aura3d_demo (both shells at full level the whole time: the steady worst case).
// Needs VFX's docs/vfx/pending/aura3d patches applied first (set_aura3d lives in vfx_hub.gd there).
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const re = /(\tmain\.start_match\([^\n]*\n)/;
if (!re.test(s)) throw new Error('anchor');
s = s.replace(re, (m) => m + '\tif _page_flag("aura"):\n\t\tmain.host.vfx.set_aura3d(true)\n\t\tmain.host.vfx.aura3d_demo = _page_flag("auradem")\n');
writeFileSync(p, s); console.log('aura hook applied');

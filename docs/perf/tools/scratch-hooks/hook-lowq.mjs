// SCRATCH HOOK: a page flag lowq=1 starts the staged scene at VFX quality low with the automatic step off (Animation's layers follow VFX's quality in main.frame()). It is the "reduced effects"
// mode Orb accepts for old laptops and phones, so the audit can say what it buys. Apply hook-depth.mjs first (it makes the start_match line this one follows).
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const re = /(\tmain\.start_match\(seed if seed != 0 else SEED, ai_set, su\)[^\n]*\n)/;
if (!re.test(s)) throw new Error('anchor: apply hook-depth.mjs first');
s = s.replace(re, (m) => m + '\tif _page_flag("lowq"):\n\t\tmain.host.vfx.quality = VfxLook.Q_LOW\n\t\tmain.host.vfx.auto_quality = false\n');
writeFileSync(p, s); console.log('low quality hook applied');

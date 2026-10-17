// Scratch: a page flag depth=1 turns fight-lane depth on for the staged scene (the lobby only runs with depth on).
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const a = '\tmain.start_match(seed if seed != 0 else SEED, ai_set, {} if slots.size() < 2 else {"slots": slots})';
if (!s.includes(a)) throw new Error('anchor');
s = s.replace(a, '\tvar su: Dictionary = {} if slots.size() < 2 else {"slots": slots}\n\tif _page_flag("depth"):\n\t\tsu["depth"] = true\n\tmain.start_match(seed if seed != 0 else SEED, ai_set, su)');
writeFileSync(p, s); console.log('depth hook applied');

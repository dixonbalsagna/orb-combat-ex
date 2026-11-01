// Verifies a black box file through the project's own replay path (the EP, 2026-11-01): re-runs it headless with SimReplay.play on a stack tree (the tree the page was built from: switches flipped, parks applied) and says whether it reproduces.
//
//   node tools/preview/blackbox-verify.mjs <orb-first-play-....json | replay.json> --tree <stack tree folder> [--godot <exe>]
//
// The file is either the saved match file ({ kind: 'orb-first-play', replay: {...} }) or a bare replay. The tree is kept by `node tools/preview/stack.mjs --keep-tree`. Output: BLACKBOX OK ticks=N final=<hash>, or BLACKBOX FAILED with the reason
// (format, data, checkpoint, final). A match cut short has no final hash: it is replayed to its last tick and only the checkpoints are compared. Godot runs headless, below-normal, under a time limit.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { godotExe, runGodot } from './preview.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const file = argv.find((a) => !a.startsWith('--') && a !== opt('--tree') && a !== opt('--godot'));
const tree = opt('--tree');
if (!file || !tree) { console.error('usage: node tools/preview/blackbox-verify.mjs <file.json> --tree <stack tree folder>'); process.exit(2); }
const doc = JSON.parse(readFileSync(file, 'utf8'));
const rp = doc.replay || doc;
const toolDir = join(resolve(tree), 'sim', 'core', 'tools');
mkdirSync(toolDir, { recursive: true });
const rpPath = join(resolve(tree), 'blackbox_replay.json');
writeFileSync(rpPath, JSON.stringify(rp));
writeFileSync(join(toolDir, 'blackbox_verify.gd'), [
  'extends SceneTree',
  '## Scratch (Tools): replays a black box file through SimReplay.play.',
  'func _init() -> void:',
  '\tSimInputData.load_and_apply()',
  '\tvar f := FileAccess.open("res://blackbox_replay.json", FileAccess.READ)',
  '\tvar rp = JSON.parse_string(f.get_as_text())',
  '\tif not (rp is Dictionary):',
  '\t\tprint("BLACKBOX FAILED: the file is not a replay")',
  '\t\tquit(1)',
  '\t\treturn',
  '\tvar r: Dictionary = SimReplay.play(rp)',
  '\tif r.ok:',
  '\t\tif String(rp.get("final", "")) == "" and rp.get("checkpoints", []).size() == 0:',
  '\t\t\tprint("BLACKBOX OK-UNCHECKED ticks=%d: it replays to its last tick, but the match was left before its KO, so it has no final hash and no checkpoint to compare" % int(rp.ticks))',
  '\t\telse:',
  '\t\t\tprint("BLACKBOX OK ticks=%d final=%s" % [int(rp.ticks), r.final])',
  '\t\tquit(0)',
  '\telse:',
  '\t\tprint("BLACKBOX FAILED: reason=%s firstBadTick=%d" % [r.reason, r.firstBadTick])',
  '\t\tquit(1)',
  '',
].join('\n'));
const godot = godotExe(opt('--godot'));
const log = join(resolve(tree), 'blackbox_verify.log');
const code = await runGodot({ godot }, ['--headless', '--path', resolve(tree), '--script', 'res://sim/core/tools/blackbox_verify.gd'], log, 10 * 60 * 1000);
const text = existsSync(log) ? readFileSync(log, 'utf8') : '';
const line = text.split(/\r?\n/).find((l) => l.startsWith('BLACKBOX')) || `BLACKBOX FAILED: no verdict (Godot exited ${code}; see ${log})`;
console.log(line);
process.exit(line.startsWith('BLACKBOX OK') ? 0 : 1);

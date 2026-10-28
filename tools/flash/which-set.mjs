// Which flash set a change needs (Legal's addendum 6, RL-128: "re-run the whole set whenever a change touches the camera, lighting, scenery contrast, an effect or the crowd";
// docs/tools/release-set-plan.md). Reads the files a commit range changes and says FULL, AI or NONE, with the reasons.
//
//   node tools/flash/which-set.mjs [<base>..<head>]        default: HEAD~1..HEAD (a range of git revisions)
//   node tools/flash/which-set.mjs --files a.gd b.json     the same, for a list of paths
// FULL: something the screen shows changed (render/, art/, ui/, data/biomes/, data/anim/, the shaders, the flash and look data): the whole required set, both modes, in the release pass.
// AI:   only the simulation, the director or the fighters' data changed: the fixed clips are unaffected but the AI matches are different matches, so the AI seeds are re-run.
// NONE: docs, tools, qa, research, prototype and the repository's text files change no pixel.
// Exit 0 always; the answer is the first line.
import { execFileSync } from 'node:child_process';
import { webPresetChanged } from './web-preset.mjs';

// export_presets.cfg is not here: the Web preset's block and the lines outside every preset decide it (setFor, Legal's RL-197)
const FULL = [/^render\//, /^art\//, /^ui\//, /^data\/biomes\//, /^data\/anim\//, /^data\/input\/layouts\.json$/, /^audio\/data\/flash/, /^project\.godot$/, /^data\/fight\/mood\.json$/];
const AI = [/^sim\//, /^data\/director\//, /^data\/combat\//, /^data\/fight\//, /^data\/fighters\//, /^data\/input\//, /^data\//];
const NONE = [/^docs\//, /^tools\//, /^qa\//, /^research\//, /^prototype\//, /^\.github\//, /^[A-Za-z]+\.md$/, /^\.git/];

/** { set: 'FULL' | 'AI' | 'NONE', why: [{ file, set }] } for a list of changed paths. `opts.presetsChanged`: whether the Web preset or a line outside the presets differs in export_presets.cfg
 *  (Legal's RL-197: a change to another preset, the Windows or Linux build's, is NONE); not given, the file is FULL, as it was. */
export function setFor(files, opts = {}) {
  const rank = { NONE: 0, AI: 1, FULL: 2 };
  let set = 'NONE';
  const why = [];
  for (const f of files) {
    const p = f.replace(/\\/g, '/');
    const s = p === 'export_presets.cfg' ? (opts.presetsChanged === false ? 'NONE' : 'FULL') : FULL.some((r) => r.test(p)) ? 'FULL' : NONE.some((r) => r.test(p)) ? 'NONE' : AI.some((r) => r.test(p)) ? 'AI' : 'AI';
    why.push({ file: p, set: s });
    if (rank[s] > rank[set]) set = s;
  }
  return { set, why };
}

if (process.argv[1] && process.argv[1].endsWith('which-set.mjs')) {
  const argv = process.argv.slice(2);
  let files;
  if (argv[0] === '--files') files = argv.slice(1);
  else {
    const range = argv[0] || 'HEAD~1..HEAD';
    files = execFileSync('git', ['diff', '--name-only', range], { encoding: 'utf8' }).split('\n').filter(Boolean);
  }
  // export_presets.cfg: the Web preset's block and the lines outside every preset decide (RL-197); only a range lets the two versions be read, so --files stays FULL for it
  let presetsChanged;
  if (argv[0] !== '--files' && files.includes('export_presets.cfg')) {
    const m = /^(.+?)\.{2,3}(.+)$/.exec(argv[0] || 'HEAD~1..HEAD');
    if (m) {
      const at = (rev) => { try { return execFileSync('git', ['show', `${rev}:export_presets.cfg`], { encoding: 'utf8', maxBuffer: 1 << 26 }); } catch { return null; } };
      presetsChanged = webPresetChanged(at(m[1]), at(m[2]));
    }
  }
  const r = setFor(files, { presetsChanged });
  console.log(r.set);
  const top = r.why.filter((w) => w.set === r.set).slice(0, 12);
  for (const w of top) console.log(`  ${w.set} ${w.file}`);
  if (r.why.filter((w) => w.set === r.set).length > top.length) console.log(`  ... and ${r.why.filter((w) => w.set === r.set).length - top.length} more`);
}

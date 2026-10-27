// The PINNED deploy: when the site is online (an interim, or a full release pass), the published /play/ is built from the commit that was MEASURED, not from the branch tip, so main
// can keep moving while the demo stays what Legal ruled on and the pixel check measured. CI's other jobs test HEAD as usual.
//
//   node tools/site-pin.mjs [--config <site.json>] [--record <release-pass.json>]
//        prints the full SHA the site's /play/ is built from, or nothing when the site is offline (the holding page needs no game: HEAD's export is still built and checked, as before);
//        exit 1, with the reasons on stderr, when the site is online and there is no usable record.
//   node tools/site-pin.mjs --export <web dir> [--tree <scratch dir>] [--godot <exe>] [--godot-node <script>] [same options]
//        exports the pinned commit's Web build the way CI exports HEAD's (git archive of the commit into a scratch tree, Godot import, export-release "Web") into <web dir>.
//        $GODOT is the executable when --godot is not given; --godot-node runs a node script as the exporter (the self-test's stub).
//
// The pin is the record's own `commit` (tools/flash/release-pass.json: written by release-pass.mjs --record for the commit measured). tools/site.json may also carry "pin": "<sha>";
// if it does it must equal the record's, so pointing the site at a new run is one change: record the run, then set the new SHA here (or leave "pin" out and follow the record).
import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { applyCrumbs, applyPrivacy, crumbsOn } from './site-crumbs.mjs';

const HERE = import.meta.dirname;
const REPO = resolve(HERE, '..');

/** The pin of a site: { pin: '' | '<40 hex>', problems: [...] }. Pure but for reading the files. */
export function pinOf(config, recordFile) {
  const problems = [];
  if (config.offline === true) return { pin: '', problems };
  // OWNER-APPROVED (Orb's order, 2026-10-18): the pin is site.json's own "pin" (a full SHA); no recorded pass is read or required
  if (config.interim && typeof config.interim.owner === 'string' && config.interim.owner.trim()) {
    if (!/^[0-9a-f]{40}$/.test(String(config.pin))) problems.push('the owner-approved site needs "pin": the full SHA of the commit to publish, in tools/site.json');
    return { pin: problems.length ? '' : config.pin, problems, owner: true };
  }
  let rec = null;
  try { rec = JSON.parse(readFileSync(recordFile, 'utf8')); } catch (e) { problems.push(`the recorded pass ${recordFile} could not be read: ${e.message}`); }
  const commit = rec && rec.commit;
  if (rec && !/^[0-9a-f]{40}$/.test(String(commit))) problems.push('the recorded pass has no full commit SHA: the site would be built from nothing it measured');
  if (config.pin !== undefined && config.pin !== null && rec && config.pin !== commit) problems.push(`tools/site.json "pin" is ${config.pin} but the recorded pass is for ${commit}: record the run for the commit to publish, or point "pin" at the recorded one`);
  return { pin: problems.length ? '' : commit, problems };
}

function git(args, cwd = REPO) { return execFileSync('git', args, { cwd, encoding: 'utf8', maxBuffer: 1 << 28 }).trim(); }

/** Exports the pinned commit's Web build into webDir. Returns the scratch tree. */
export function exportPinned(pin, webDir, o = {}) {
  const repo = o.repo || REPO;   // the repository holding the commit (the self-test's throwaway one)
  const tree = resolve(o.tree || join(tmpdir(), `site-pinned-${pin.slice(0, 8)}`));
  try { git(['cat-file', '-e', `${pin}^{commit}`], repo); } catch {
    // a shallow CI checkout does not hold the recorded commit: fetch just it (GitHub allows a fetch by SHA)
    git(['fetch', '--no-tags', '--depth=1', 'origin', pin], repo);
  }
  rmSync(tree, { recursive: true, force: true });
  mkdirSync(tree, { recursive: true });
  mkdirSync(webDir, { recursive: true });
  const tar = execFileSync('git', ['archive', pin], { cwd: repo, maxBuffer: 1 << 30 });
  const r = spawnSync('tar', ['-x'], { input: tar, cwd: tree });   // cwd, not -C: a drive letter in the path is a host name to GNU tar
  if (r.status !== 0) throw new Error(`tar failed: ${r.stderr}`);
  // build_info.json (git-ignored, packed by the export's include_filter): the pinned commit's own short SHA and date, as tools/write-build-info.mjs writes them
  const date = git(['log', '-1', '--format=%cs', pin], repo) || 'unknown';
  writeFileSync(join(tree, 'build_info.json'), `${JSON.stringify({ commit: pin.slice(0, 7), date })}
`);
  const run = (args) => {
    const cmd = o.godotNode ? process.execPath : o.godot;
    const a = o.godotNode ? [o.godotNode, ...args] : args;
    const s = spawnSync(cmd, a, { cwd: tree, stdio: 'inherit' });
    if (s.status !== 0) throw new Error(`${cmd} ${args.join(' ')} exited ${s.status}`);
  };
  // the interim's export locks Reduce flashing on (docs/ui/reduce-flashing-lock.md, Legal RL-156): one word in the export's features.json, set here so the pinned commit need not carry it
  if (o.lock) {
    const ff = join(tree, 'ui', 'data', 'features.json');
    const nl = String.fromCharCode(10), cr = String.fromCharCode(13);
    const txt = readFileSync(ff, 'utf8');
    if (!/"lock_reduce_flashing"\s*:/.test(txt)) throw new Error('ui/data/features.json has no lock_reduce_flashing: the pinned commit is older than UI\'s rf-lock');
    writeFileSync(ff, txt.replace(/"lock_reduce_flashing"\s*:\s*false/, '"lock_reduce_flashing": true'));
    void nl; void cr;
  }
  // the freeze breadcrumbs (tools/site-crumbs.mjs, off unless tools/site.json says "crumbs": true): folded into THIS tree's Web preset only, by the repository's own web-head.mjs, so the pinned
  // commit need not carry them and the committed preset never does
  if (o.crumbs) {   // the report's build line is the pin's short hash and its commit date; the game's own About line says what the page says (Legal's switch-on words)
    applyCrumbs(join(tree, 'export_presets.cfg'), `${pin.slice(0, 7)} ${date}`);
    applyPrivacy(tree);
  }
  run(['--headless', '--path', tree, '--import']);
  run(['--headless', '--path', tree, '--export-release', 'Web', join(webDir, 'index.html')]);
  if (!existsSync(join(webDir, 'index.html'))) throw new Error('the pinned export produced no index.html');
  return tree;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
  const config = JSON.parse(readFileSync(resolve(opt('--config') || join(HERE, 'site.json')), 'utf8'));
  const record = resolve(opt('--record') || join(HERE, 'flash', 'release-pass.json'));
  const { pin, problems } = pinOf(config, record);
  if (problems.length) { for (const p of problems) console.error(`site pin: ${p}`); process.exit(1); }
  if (args.includes('--export')) {
    const web = opt('--export');
    if (!pin) { console.error('site pin: the site is offline: there is no pinned commit to export'); process.exit(2); }
    try {
      const godot = opt('--godot') || process.env.GODOT;
      const tree = exportPinned(pin, resolve(web), { tree: opt('--tree'), godot, godotNode: opt('--godot-node'), lock: !!config.interim, crumbs: crumbsOn(config) });
      console.log(`pinned ${pin.slice(0, 8)} exported to ${web} (tree ${tree})`);
    } catch (e) { console.error(`site pin: ${e.message}`); process.exit(1); }
  } else {
    console.log(pin);
  }
}

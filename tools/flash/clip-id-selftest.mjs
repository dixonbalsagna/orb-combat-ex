// Self-test of tools/flash/clip-id.mjs and what uses it: a clip records which match it is (scenario, seed asked and played, pairing, variant), capture-web.mjs prints it in its start line, and
// side-by-side.mjs refuses to put two different matches side by side. Frames are made here (4x4 PNGs); the capture half needs Chrome or Edge (--require-browser makes its absence a failure).
//   node tools/flash/clip-id-selftest.mjs [--require-browser] [--browser-path <exe>]
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DEFAULT_SEED, playedSeed, matchRecord, matchText, readMatch, differences } from './clip-id.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const { encodePng } = createRequire(import.meta.url)('./wcag.js');
const argv = process.argv.slice(2);
const bp = argv.indexOf('--browser-path') >= 0 ? ['--browser-path', argv[argv.indexOf('--browser-path') + 1]] : [];
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const tmp = mkdtempSync(join(tmpdir(), 'clip-id-'));
try {
  // the default is the hook's own
  const hook = readFileSync(join(here, '..', '..', 'render', 'tools', 'flash_capture.gd'), 'utf8');
  check('DEFAULT_SEED is the seed render/tools/flash_capture.gd plays when a capture asks for none', Number((/const SEED: int = (\d+)/.exec(hook) || [])[1]) === DEFAULT_SEED);
  check('no seed and seed 0 are the default seed; any other seed is itself', playedSeed(null) === DEFAULT_SEED && playedSeed(undefined) === DEFAULT_SEED && playedSeed(0) === DEFAULT_SEED && playedSeed(4) === 4 && playedSeed(104) === 104);
  const rec = (o) => matchRecord({ scenario: 'ai', seed: null, slots: null, variant: 0, ...o });
  check('a capture with no --seed is recorded as the default seed, said so, never blank', rec({}).seedPlayed === DEFAULT_SEED && rec({}).seed === null && /seed 12345 \(the hook's default\), pairing default/.test(matchText(rec({}))));
  check('a capture with --seed 4 --slots A,B records them', matchText(rec({ seed: 4, slots: ['A', 'B'] })) === 'seed 4, pairing A,B, variant 0');
  check('the same match differs in nothing', differences(rec({ seed: 4 }), rec({ seed: 4 })).length === 0);
  check('the default seed and the same seed asked for are the same match', differences(rec({}), rec({ seed: DEFAULT_SEED })).length === 0);
  check('seeds 4 and 39 differ', /seed 4 against 39/.test(differences(rec({ seed: 4 }), rec({ seed: 39 })).join()));
  check('the default seed and seed 4 differ (the 2026-10-27 case)', differences(rec({}), rec({ seed: 4 })).length === 1);
  check('the default pair and an asked pair differ; two asked pairs differ; the same pair does not', differences(rec({}), rec({ slots: ['A', 'B'] })).length === 1 && differences(rec({ slots: ['A', 'B'] }), rec({ slots: ['A', 'C'] })).length === 1 && differences(rec({ slots: ['A', 'B'] }), rec({ slots: ['A', 'B'] })).length === 0);
  check('a different scenario or variant differs', differences(rec({}), rec({ scenario: 'mash' })).length === 1 && differences(rec({}), rec({ variant: 1 })).length === 1);

  // clip folders
  const frames = (dir, clip) => {
    mkdirSync(dir, { recursive: true });
    const px = new Uint8Array(4 * 4 * 4).fill(255);
    for (let t = 1; t <= 3; t++) writeFileSync(join(dir, `frame-${String(t).padStart(6, '0')}.png`), encodePng(4, 4, px));
    if (clip !== undefined) writeFileSync(join(dir, 'clip.json'), JSON.stringify(clip));
  };
  const clip = (o) => ({ ...rec(o), reduced: false, fps: 60, ticks: 3 });
  frames(join(tmp, 'a'), clip({ seed: 4 }));
  frames(join(tmp, 'a2'), clip({ seed: 4 }));
  frames(join(tmp, 'b'), clip({ seed: 39 }));
  frames(join(tmp, 'dflt'), clip({}));
  frames(join(tmp, 'pair'), clip({ seed: 4, slots: ['A', 'B'] }));
  frames(join(tmp, 'old4'), { scenario: 'ai', seed: 4, reduced: false, fps: 60, ticks: 3 });   // a clip from before the record
  frames(join(tmp, 'oldnull'), { scenario: 'ai', seed: null, reduced: false, fps: 60, ticks: 3 });
  frames(join(tmp, 'bare'));   // frames and no clip.json
  const sbs = (l, r, out, ...more) => spawnSync(process.execPath, [join(here, 'side-by-side.mjs'), '--left', join(tmp, l), '--right', join(tmp, r), '--out', join(tmp, out), '--stills', '1', '--from', '1', '--to', '3', '--step', '1', ...more], { encoding: 'utf8' });
  const same = sbs('a', 'a2', 'o-same');
  check('the same match goes through, with both sides printed', same.status === 0 && /left: seed 4, pairing default/.test(same.stdout) && /right: seed 4, pairing default/.test(same.stdout), same.stderr.slice(0, 200));
  const man = existsSync(join(tmp, 'o-same', 'side-by-side-clips.json')) ? JSON.parse(readFileSync(join(tmp, 'o-same', 'side-by-side-clips.json'), 'utf8')) : null;
  check('the output records each side\'s match and that they are the same', !!man && man.left.seedPlayed === 4 && man.right.seedPlayed === 4 && man.sameMatch === true);
  check('the stills and the GIF are still made', existsSync(join(tmp, 'o-same', 'side-by-side.gif')) && existsSync(join(tmp, 'o-same', 'side-by-side-t00002.png')));
  const diffSeed = sbs('a', 'b', 'o-diff');
  check('seeds 4 and 39 are refused, nothing is written', diffSeed.status === 1 && /REFUSED.*seed 4 against 39/.test(diffSeed.stderr) && !existsSync(join(tmp, 'o-diff')), diffSeed.stderr.slice(0, 200));
  const dflt = sbs('a', 'dflt', 'o-dflt');
  check('seed 4 against a capture that asked for no seed (the default 12345) is refused', dflt.status === 1 && /seed 4 against 12345/.test(dflt.stderr));
  check('the pair mismatch is refused', sbs('a', 'pair', 'o-pair').status === 1 && /pairing default against A,B/.test(sbs('a', 'pair', 'o-pair').stderr));
  const allow = sbs('a', 'b', 'o-allow', '--allow-different');
  check('--allow-different shows them with a warning, and the manifest says they differ', allow.status === 0 && /WARNING.*not the same match/.test(allow.stderr) && JSON.parse(readFileSync(join(tmp, 'o-allow', 'side-by-side-clips.json'), 'utf8')).sameMatch === false);
  const old = sbs('old4', 'a', 'o-old');
  check('an older clip.json (seed only) is compared on the seed and says the pairing was not recorded', old.status === 0 && /derived from an older clip.json/.test(old.stdout));
  check('an older clip with the seed 4 against a clip of seed 39 is refused', sbs('old4', 'b', 'o-old2').status === 1);
  check('an older clip with no seed (the default) against seed 4 is refused', sbs('oldnull', 'a', 'o-old3').status === 1);
  const bare = sbs('bare', 'a', 'o-bare');
  check('a side with no clip.json is shown with a warning (nothing to compare)', bare.status === 0 && /no match record/.test(bare.stdout) && /WARNING: a side has no match record/.test(bare.stderr));
  check('readMatch says why when there is no record', /no clip.json/.test(readMatch(join(tmp, 'bare')).why || ''));

  // capture-web: the start line and clip.json, through headless Chrome on the mock page
  const cap = (out, ...more) => spawnSync(process.execPath, [join(here, 'capture-web.mjs'), '--mock', '--scenario', 'steady', '--ticks', '3', '--out', join(tmp, out), '--session', 'tools', '--time-limit', '180', ...bp, ...more], { encoding: 'utf8' });
  const c1 = cap('cap-dflt');
  if (c1.status === 2 && /no (chrome|edge) executable/.test(c1.stderr)) {
    if (argv.includes('--require-browser')) { console.log('clip id self-test FAILED: no browser found'); process.exit(1); }
    console.log(`clip id self-test: ${ran - failed} of ${ran} checks passed; the capture half was skipped: no Chrome or Edge found (pass --browser-path, or --require-browser to make it a failure)`);
    process.exit(failed ? 1 : 0);
  }
  check('capture-web prints the seed and pairing in its start line (no --seed: the default, said so)', c1.status === 0 && /\[capture-web\] .*steady.*; seed 12345 \(the hook's default\), pairing default, variant 0/.test(c1.stdout), (c1.stderr || c1.stdout).slice(0, 300));
  const j1 = existsSync(join(tmp, 'cap-dflt', 'clip.json')) ? JSON.parse(readFileSync(join(tmp, 'cap-dflt', 'clip.json'), 'utf8')) : {};
  check('clip.json records seed null, seedPlayed 12345, no pairing', j1.seed === null && j1.seedPlayed === 12345 && j1.slots === null && j1.pairing === 'default' && j1.scenario === 'steady');
  const c2 = cap('cap-pair', '--seed', '4', '--slots', 'A,B');
  const j2 = existsSync(join(tmp, 'cap-pair', 'clip.json')) ? JSON.parse(readFileSync(join(tmp, 'cap-pair', 'clip.json'), 'utf8')) : {};
  check('--seed 4 --slots A,B: the start line and clip.json say so', c2.status === 0 && /; seed 4, pairing A,B, variant 0/.test(c2.stdout) && j2.seed === 4 && j2.seedPlayed === 4 && j2.pairing === 'A,B' && Array.isArray(j2.slots) && j2.slots.join() === 'A,B', (c2.stderr || c2.stdout).slice(0, 300));
  check('two real captures of different seeds are refused by side-by-side', sbs('cap-dflt', 'cap-pair', 'o-cap').status === 1);
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
console.log(failed ? `clip id self-test FAILED: ${failed} of ${ran}` : `clip id self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

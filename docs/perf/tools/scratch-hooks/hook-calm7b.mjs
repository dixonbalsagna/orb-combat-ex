// SCRATCH HOOK (scratch export only): applies Encounter's parked calm-7b (docs/director/pending/calm-7b/c7.cjs: a landing's moment from the journey's end, and a set piece's end is a
// calm moment too) to the scratch tree, because on main alone the AI's matches almost never make a calm moment that turns the ring (6 Half-ring matches, 0 asks, native). Reads the
// park from the REPO (never writes there); writes only into the scratch root it is given.
import { spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..', '..', '..');
const root = resolve(process.argv[2]);
if (root === repo) throw new Error('refusing to run against the repo root');
const r = spawnSync(process.execPath, [join(repo, 'docs/director/pending/calm-7b/c7.cjs'), root], { encoding: 'utf8' });
if (r.status) throw new Error('c7.cjs: ' + (r.stderr || r.stdout));
console.log('calm-7b applied to the scratch tree:', (r.stdout || '').trim().split('\n').slice(-2).join(' | '));

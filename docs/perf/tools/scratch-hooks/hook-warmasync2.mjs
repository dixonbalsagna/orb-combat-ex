// SCRATCH HOOK (scratch export only): applies Audio's re-cut park docs/audio/pending/warm-async-2 to the scratch tree with its own apply.py (a --check first, then the apply), run from the park folder as
// its README says. The tree must already hold the first park (HEAD from 1b3f5a29 does). Never against the repo root (the hook refuses it).
import { spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..', '..', '..');
const root = resolve(process.argv[2]);
if (root === repo) throw new Error('refusing to run against the repo root');
const park = join(repo, 'docs', 'audio', 'pending', 'warm-async-2');
for (const extra of [['--check'], []]) {
  const r = spawnSync('python', ['apply.py', root, ...extra], { cwd: park, encoding: 'utf8' });
  if (r.status) throw new Error('apply.py ' + extra.join(' ') + ': ' + (r.stderr || r.stdout).slice(0, 400));
  console.log('warm-async-2 ' + (extra[0] || 'applied') + ': ' + (r.stdout || '').trim().split('\n').slice(-2).join(' | '));
}

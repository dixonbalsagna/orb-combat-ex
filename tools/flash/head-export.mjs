// Unpacks the tree of a git revision (HEAD by default) into a folder: the clean copy the clip re-run and the other "prove it on HEAD" tools export from (tools/flash/check-clip.mjs --head).
//
// It goes through a tar FILE next to the destination, not a pipe: the whole project is over half a gigabyte, and a pipe through spawnSync's buffer (the earlier code) fails on a repository
// that has grown past the buffer, on a tar that does not read standard input, and, worse, said only "git archive HEAD failed" with the reason thrown away. Every failure here names the
// command, its exit code or error and the first lines of what it wrote to stderr.
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, rmSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';

const why = (cmd, r) => `${cmd} ${r.error ? `could not run (${r.error.code || r.error.message})` : r.signal ? `was stopped by ${r.signal}` : `exited ${r.status}`}${r.stderr && String(r.stderr).trim() ? `: ${String(r.stderr).trim().split('\n').slice(0, 3).join(' | ')}` : ''}`;

/** Exports `rev` of the repository at `root` into `dest` (created). Returns { ok: true } or { ok: false, message }. The tar file is removed either way. */
export function exportRevision(root, dest, rev = 'HEAD') {
  const repo = resolve(root), out = resolve(dest);
  if (!existsSync(repo)) return { ok: false, message: `${repo} does not exist` };
  mkdirSync(out, { recursive: true });
  const tarName = `${basename(out)}.${process.pid}.tar`, tarFile = join(dirname(out), tarName);
  try {
    const ar = spawnSync('git', ['archive', '--format=tar', '-o', tarFile, rev], { cwd: repo, encoding: 'utf8' });
    if (ar.status !== 0 || ar.error) return { ok: false, message: `git archive ${rev} failed in ${repo}: ${why('git', ar)}${/not a git repository/i.test(String(ar.stderr)) ? ' (run it from a git checkout of the project, not a copy without .git)' : ''}` };
    // relative names with the tar's own working directory: GNU tar reads a "C:" in -f as a remote host, and reads a backslash in -C as an escape (0bff52c in a scratchpad path became a character)
    const tar = spawnSync('tar', ['-xf', tarName, '-C', basename(out)], { cwd: dirname(out), encoding: 'utf8' });
    if (tar.status !== 0 || tar.error) return { ok: false, message: `unpacking the archive of ${rev} into ${out} failed: ${why('tar', tar)}` };
    return { ok: true };
  } finally {
    rmSync(tarFile, { force: true });
  }
}

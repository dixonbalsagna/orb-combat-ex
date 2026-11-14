// Does every file a workflow names exist in git? (2026-11-14: ci.yml was committed naming tools/version.mjs and tools/version-selftest.mjs, files that existed on the author's PC and not in git, so the
// data job went red on the runner at "Cannot find module". Nothing on the author's PC could say so: the files were there.) This reads the workflow and action files, takes every repository path
// they name (tools/..., sim/..., docs/..., res://... and so on, with a file extension), and fails on one that git does not track. It reads the INDEX (`git ls-files`), so a file that is only on disk
// counts as missing, and a file added with `git add` counts as present. Text after a `#` comment mark is ignored; a path with a wildcard or a placeholder (`*`, `<`, `$`, `{`) is skipped.
// Paths a run writes itself, or that a person commits on purpose later, are listed below with their reasons.
//   node tools/check-workflow-paths.mjs [--root <dir>]      exit 0 when every named path is tracked, 1 with the missing ones named
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/** Paths a workflow names that are not files in git on purpose: path -> why. */
export const ALLOWED = {
  'docs/ep/approvals/desktop-test-builds.txt': "Orb's recorded yes (RL-203/RL-263): the EP commits it when Orb says yes, and the desktop workflow's job is to refuse without it",
};

const EXT = 'mjs|cjs|json|js|gd|md|cfg|sh|txt|yml|yaml|tscn|tres|html|css|ps1|py';
const PATH_RE = new RegExp(`(?<![A-Za-z0-9_./-])(?:res://)?((?:tools|sim|render|ui|audio|net|qa|docs|data|prototype|art|research|\\.github)/[A-Za-z0-9_./*<>$\\{\\}-]+?\\.(?:${EXT}))(?![A-Za-z0-9_])`, 'g');

/** The repository paths a YAML text names (comments stripped, wildcards and placeholders skipped): a sorted array of { path, line }. Pure. */
export function namedPaths(text) {
  const out = [];
  text.split(/\r?\n/).forEach((raw, i) => {
    const l = raw.replace(/(^|\s)#.*$/, '$1');
    for (const m of l.matchAll(PATH_RE)) {
      const p = m[1];
      if (/[*<>${}]/.test(p)) continue;
      out.push({ path: p, line: i + 1 });
    }
  });
  return out;
}

/** The problems: [{ file, line, path }] for each named path not in `tracked`. Pure. */
export function missingPaths(files, tracked, allowed = ALLOWED) {
  const out = [];
  for (const f of files) for (const n of namedPaths(f.text)) if (!tracked.has(n.path) && !(n.path in allowed)) out.push({ file: f.name, line: n.line, path: n.path });
  return out;
}

function filesUnder(root, d) {
  const dir = join(root, d);
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? filesUnder(root, `${d}/${e.name}`) : /\.ya?ml$/.test(e.name) ? [`${d}/${e.name}`] : []));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const i = a.indexOf('--root');
  const root = i >= 0 ? resolve(a[i + 1]) : resolve(fileURLToPath(new URL('..', import.meta.url)));
  let tracked;
  try { tracked = new Set(execFileSync('git', ['ls-files', '-z'], { cwd: root, encoding: 'utf8', maxBuffer: 1 << 28 }).split('\0').filter(Boolean)); } catch { console.log('check-workflow-paths: not a git checkout, skipped'); process.exit(0); }
  const files = [...filesUnder(root, '.github/workflows'), ...filesUnder(root, '.github/actions')].map((name) => ({ name, text: readFileSync(join(root, name), 'utf8') }));
  const bad = missingPaths(files, tracked);
  for (const b of bad) console.error(`${b.file}:${b.line}: names ${b.path}, which git does not have`);
  console.log(bad.length ? `check-workflow-paths FAILED: ${bad.length} named path(s) are not in git` : `check-workflow-paths ok: every file the ${files.length} workflow and action files name is in git`);
  process.exit(bad.length ? 1 : 0);
}

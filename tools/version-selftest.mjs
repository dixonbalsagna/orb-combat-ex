// Self-test of tools/version.mjs (A-TOOLS-07): the number, the changelog entry, the check and the whole --next command on a throwaway copy of the files. Node and git only. CI runs it.
//   node tools/version-selftest.mjs
import { execFileSync, spawnSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PLACEHOLDER, entriesOf, entryText, problems, versionOf, windowsOf, withEntry } from './version.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const v = { major: 0, minor: 1, build: 7 };
check('the number is major.minor.build and the Windows form has a fourth 0', versionOf(v) === '0.1.7' && windowsOf(v) === '0.1.7.0');
const e1 = entryText({ version: '0.1.1', date: '2026-11-14', commit: '59c6b195932e62bfaf56a3c22bd6405d64b1bed0', subjects: ['one', 'two'] });
check('an entry has the heading with the date and the short commit, the players\' placeholder and the team\'s subjects', /^## 0\.1\.1 \(2026-11-14, 59c6b195\)\n\nFor players\n\(to be written/.test(e1) && /For the team\n- one\n- two\n$/.test(e1), e1);
check('an entry with more than 40 commits says how many more', /- \.\.\.and 5 more/.test(entryText({ version: '0.1.2', date: 'd', commit: '', subjects: Array.from({ length: 45 }, (_, i) => `c${i}`) })));
check('an entry with no commits says so', /no commits since the last entry/.test(entryText({ version: '0.1.3', date: 'd', commit: '', subjects: [] })));
const head = '# Changelog\n\nSome words.\n\n';
let log = withEntry(head, e1);
check('the first entry goes under the header', log.startsWith(head) && log.includes('## 0.1.1'));
log = withEntry(log, entryText({ version: '0.1.2', date: '2026-11-15', commit: 'abcdef12', subjects: ['three'] }));
const es = entriesOf(log);
check('a new entry goes above the older one; the entries read back, top first, with their parts', es.length === 2 && es[0].version === '0.1.2' && es[1].version === '0.1.1' && es[0].commit === 'abcdef12' && es[0].players === PLACEHOLDER && es[0].team === '- three' && es[1].date === '2026-11-14', JSON.stringify(es));
check('the header text is kept above the entries', log.startsWith(head));
check('build 0 needs no entry', problems({ major: 0, minor: 1, build: 0 }, head).length === 0);
check('the counter and the top entry agree: no problem', problems({ major: 0, minor: 1, build: 2 }, log).length === 0);
check('the counter ahead of the changelog is a problem naming the fix', problems({ major: 0, minor: 1, build: 3 }, log).some((p) => /top entry .* is 0\.1\.2, tools\/version\.json says 0\.1\.3/.test(p)));
check('a counter with no entry at all is a problem', problems({ major: 0, minor: 1, build: 1 }, head).some((p) => /has no entry/.test(p)));
check('--ready: an entry still holding the placeholder is a problem; one written is not', problems({ major: 0, minor: 1, build: 2 }, log, { ready: true }).some((p) => /no line for players yet/.test(p)) && problems({ major: 0, minor: 1, build: 2 }, log.replace(PLACEHOLDER, 'You can now start a match from the new menu.'), { ready: true }).length === 0);
check('a version twice in the changelog is a problem', problems({ major: 0, minor: 1, build: 2 }, log + '\n' + e1).some((p) => /twice/.test(p)));
check('a counter that is not a whole number is a problem', problems({ major: 0, minor: 'x', build: 2 }, log).some((p) => /minor is not a whole number/.test(p)));

// the command, on a throwaway repository with copies of the tool and its two files
const d = mkdtempSync(join(tmpdir(), 'version-'));
try {
  mkdirSync(join(d, 'tools')); mkdirSync(join(d, 'docs', 'tools'), { recursive: true });
  copyFileSync(join(here, 'version.mjs'), join(d, 'tools', 'version.mjs'));
  writeFileSync(join(d, 'tools', 'version.json'), JSON.stringify({ major: 0, minor: 1, build: 0 }));
  writeFileSync(join(d, 'docs', 'tools', 'changelog.md'), head);
  const git = (...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false', ...a], { cwd: d, encoding: 'utf8' }).trim();
  git('init', '-q'); writeFileSync(join(d, 'a.txt'), 'a'); git('add', '-A'); git('commit', '-q', '-m', 'first commit');
  const run = (...a) => spawnSync(process.execPath, [join(d, 'tools', 'version.mjs'), ...a], { encoding: 'utf8' });
  check('the command prints the version', run().stdout.trim() === '0.1.0');
  let r = run('--next');
  check('--next raises the counter and writes the entry with the commit subject', r.status === 0 && JSON.parse(readFileSync(join(d, 'tools', 'version.json'), 'utf8')).build === 1 && /^## 0\.1\.1 \(\d{4}-\d{2}-\d{2}, [0-9a-f]{8}\)/m.test(readFileSync(join(d, 'docs', 'tools', 'changelog.md'), 'utf8')) && readFileSync(join(d, 'docs', 'tools', 'changelog.md'), 'utf8').includes('- first commit'), r.stdout + r.stderr);
  check('--check agrees at once; --check --ready does not until the line for players is written', run('--check').status === 0 && run('--check', '--ready').status === 1);
  writeFileSync(join(d, 'a.txt'), 'b'); git('add', '-A'); git('commit', '-q', '-m', 'second commit');
  r = run('--next');
  const text = readFileSync(join(d, 'docs', 'tools', 'changelog.md'), 'utf8');
  check('a second --next lists only the commits since the first entry', /^## 0\.1\.2/m.test(text) && text.indexOf('## 0.1.2') < text.indexOf('## 0.1.1') && /## 0\.1\.2[\s\S]*- second commit[\s\S]*## 0\.1\.1/.test(text) && !/## 0\.1\.2[\s\S]{0,300}- first commit[\s\S]*## 0\.1\.1/.test(text), text);
  check('--windows prints the four-number form', run('--windows').stdout.trim() === '0.1.2.0');
} finally { rmSync(d, { recursive: true, force: true }); }

console.log(failed ? `version self-test: ${failed} of ${ran} FAILED` : `version self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

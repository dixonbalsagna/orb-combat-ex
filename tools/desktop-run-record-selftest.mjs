// Self-test of the pure parts of tools/desktop-run-record.mjs (Tools, 2026-11-23). node tools/desktop-run-record-selftest.mjs
import { logLines, hashesOf, packagesOf, recordText } from './desktop-run-record.mjs';
let bad = 0, n = 0;
const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const T = '2026-11-23T21:03:00.1234567Z';
const B = String.fromCharCode(92);
const log = [
  `Desktop builds\tBench\t${T} gameplay hash at tick 2400: 9d323c7f64c75955`,
  `Desktop builds\tBench\t${T} echo "gameplay hash at tick N: x"`,
  `Windows build\tbench\t${T} gameplay hash at tick 2400: 9d323c7f64c75955`,
  `Windows build\tbench\t${T} gameplay hash at tick 2400: 9d323c7f64c75955`,
  `Desktop builds\tPack\t${T} ${'a'.repeat(64)}  ./orb-combat-ex-linux-x86_64.tar.gz`,
  `Desktop builds\tPack\t${T} -rw-r--r-- 1 runner runner 34758997 Nov 23 21:03 orb-combat-ex-linux-x86_64.tar.gz`,
  `Desktop builds\tPack\t${T} ${'b'.repeat(64)}  ./orb-combat-ex-windows-x86_64.zip`,
  `Windows build\tstart\t${T} the program did not stay up in C:${B}Users${B}someone${B}AppData${B}Local${B}Temp${B}x`,
].join('\n');
const lines = logLines(log);
check('log lines are read with job, step and text', lines.length === 8 && lines[0].job === 'Desktop builds' && lines[0].step === 'Bench' && lines[0].text.startsWith('gameplay hash'));
check('hash lines are found once per job, the echo of a command is not one', hashesOf(lines).length === 2 && hashesOf(lines).every((h) => /9d323c7f64c75955$/.test(h.line)));
const pk = packagesOf(lines);
check('packages: name, SHA-256 and size where the listing has it', pk.length === 2 && pk[0].size === 34758997 && pk[0].sha256 === 'a'.repeat(64) && pk[1].size === null);
const run = { databaseId: 1, url: 'https://example/1', workflowName: 'Desktop builds', event: 'workflow_dispatch', headSha: 'c'.repeat(40), headBranch: 'main', createdAt: '2026-11-23T21:01:11Z', updatedAt: '2026-11-23T21:07:00Z', conclusion: 'failure', status: 'completed', jobs: [
  { name: 'Desktop builds', conclusion: 'success', startedAt: '2026-11-23T21:01:20Z', completedAt: '2026-11-23T21:04:20Z', steps: [] },
  { name: 'Windows build', conclusion: 'failure', startedAt: '2026-11-23T21:04:30Z', completedAt: '2026-11-23T21:06:30Z', steps: [{ name: 'start', conclusion: 'failure' }] }] };
const t = recordText({ run, lines, artifacts: 0, note: 'A try.' });
check('the page has the run, the jobs with times, the failed step with its log, the hashes, the packages and the artifact count', /run \[1\]/.test(t) && /\| Desktop builds \| success \| 3 min 00 s \|/.test(t) && /What failed/.test(t) && /the program did not stay up/.test(t) && /All 2 agree/.test(t) && /34,758,997 bytes/.test(t) && /Artifacts: 0/.test(t) && /A try\./.test(t), t);
check('folder paths are taken out of the page', !/someone/.test(t) && /<scratch>/.test(t));
const t2 = recordText({ run, lines: logLines(log.replace(/9d323c7f64c75955\n/, '1111111111111111\n')), artifacts: null });
check('hashes that differ are said not to agree, and an unread artifact count is not called 0', /do not agree/.test(t2) && /not read/.test(t2));
console.log(`desktop-run-record selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);

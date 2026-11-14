// Self-test of tools/check-workflow-paths.mjs (Tools, 2026-11-14): a named file that git lacks is found; comments, wildcards, placeholders and the allowed paths are not.  node tools/check-workflow-paths-selftest.mjs
import { namedPaths, missingPaths, ALLOWED } from './check-workflow-paths.mjs';
let bad = 0, n = 0;
const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const tracked = new Set(['tools/a.mjs', 'sim/core/tools/parity.gd', 'docs/x.md']);
const f = (text) => [{ name: 'w.yml', text }];
check('a named file that git has passes', missingPaths(f('run: node tools/a.mjs'), tracked).length === 0);
check('a named file that git lacks is found, with its line', (() => { const m = missingPaths(f('a: 1\nrun: node tools/version.mjs --check'), tracked); return m.length === 1 && m[0].path === 'tools/version.mjs' && m[0].line === 2; })());
check('a res:// path is read as the path', missingPaths(f('run: godot --script res://sim/core/tools/parity.gd'), tracked).length === 0 && missingPaths(f('run: godot --script res://sim/core/tools/missing.gd'), tracked).length === 1);
check('text after a comment mark is ignored', missingPaths(f('run: node tools/a.mjs # not tools/b.mjs'), tracked).length === 0 && missingPaths(f('# tools/b.mjs\nrun: x'), tracked).length === 0);
check('a wildcard or a placeholder is skipped', missingPaths(f('run: ls tools/*.mjs docs/<x>.md tools/${X}.mjs'), tracked).length === 0);
check('every allowed path is skipped', Object.keys(ALLOWED).every((p) => missingPaths(f(`run: test -f ${p}`), tracked).length === 0));
check('a .json file is not read as .js (the extension is whole)', namedPaths('run: node tools/version.json').map((x) => x.path).join() === 'tools/version.json');
check('an artifact name that is not a repo path is not read', namedPaths('name: orb-combat-ex-windows-x86_64\npath: ${{ runner.temp }}/dist/a.zip').length === 0);
check('two paths on one line are both found', namedPaths('run: node tools/a.mjs docs/x.md').length === 2);
console.log(`check-workflow-paths selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);

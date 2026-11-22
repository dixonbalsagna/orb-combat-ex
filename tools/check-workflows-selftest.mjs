// Self-test of tools/check-workflows.mjs: the YAML a workflow file may hold passes, and each way a workflow file breaks is found at its line. The first fixture is the step that broke ci.yml on
// 2026-10-27 (an unquoted ": " in a step name). No dependency.
//   node tools/check-workflows-selftest.mjs
import { lintJobs, lintYaml } from './check-workflows.mjs';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const L = (lines) => lines.join('\n') + '\n';
const lines = (text) => lintYaml(text).map((p) => p.line);

const GOOD = L([
  'name: CI',
  'on:',
  '  push:',
  '    branches: [main]',
  '  workflow_dispatch:',
  'env:',
  '  GODOT: "4.7.2"   # a comment: with a colon',
  'jobs:',
  '  data:',
  '    runs-on: ubuntu-24.04',
  '    steps:',
  '      - uses: actions/checkout@v7',
  '        with:',
  '          fetch-depth: 0',
  '      - name: "Moveset generator tests: the parts, the identity"',
  '        run: node tools/gate.mjs -- godot --headless',
  '      - name: Plain name without a colon',
  '        run: |',
  '          echo "a: b"',
  '          if [ -n "$X" ]; then',
  '            echo yes: no',
  '          fi',
  '      - name: Folded',
  '        run: >-',
  '          node a.mjs',
  '          --flag: x',
  '        env:',
  '          URL: https://example.com/a:b',
  '          TOKEN: ${{ secrets.TOKEN }}',
  "          QUOTED: 'it''s: fine'",
  '  other:',
  '    needs: [data, build]',
  '    steps:',
  '      -',
  '        run: echo hi',
  '',
]);
check('the shapes a workflow file holds pass: maps, sequences of maps, flow lists, block scalars with colons in them, quoted colons, comments, URLs', lintYaml(GOOD).length === 0, JSON.stringify(lintYaml(GOOD)));

const broken = (what, text, wantLine, re) => {
  const p = lintYaml(text);
  check(`${what}: found${wantLine ? ` at line ${wantLine}` : ''}`, p.length > 0 && (!wantLine || p.some((x) => x.line === wantLine)) && (!re || p.some((x) => re.test(x.message))), JSON.stringify(p));
};
broken('an unquoted ": " in a step name (the 2026-10-27 break)', L(['jobs:', '  data:', '    steps:', '      - name: Moveset generator tests: the parts', '        run: node x']), 4, /holds ": "/);
broken('an unquoted ": " in the value of a mapping key', L(['env:', '  A: one: two']), 2, /holds ": "/);
broken('a plain value that ends in a colon', L(['a:', '  b: value:']), 2, /ends in ":"/);
broken('a tab in the indentation', 'a:\n\tb: 1\n', 2, /tab/);
broken('a key repeated in one mapping', L(['a:', '  b: 1', '  b: 2']), 3, /repeated/);
broken('the same key in two different mappings is fine, so only the one mapping is flagged', L(['a:', '  b: 1', 'c:', '  b: 2', '  b: 3']), 5, /repeated/);
broken('an unclosed double quote', L(['a:', '  b: "open']), 2, /unclosed/);
broken('an unclosed single quote', L(['a:', "  b: 'open"]), 2, /unclosed/);
broken('an unclosed flow list', L(['a:', '  b: [x, y']), 2, /unclosed/);
broken('a mapping key at the indentation of a sequence item', L(['steps:', '  - a: 1', '  b: 2']), 3, /mixed/);
broken('a stray indent where nothing opened a block', L(['a: 1', '  b: 2']), 2, /goes deeper/);
broken('a continuation line of a plain value', L(['a:', '  run: echo one', '    two']), 3, /goes deeper/);
check('a repeated key in a block scalar is content, not a key', lintYaml(L(['run: |', '  a: 1', '  a: 2', 'next: x'])).length === 0);
check('a colon-space inside a comment or after one is ignored', lintYaml(L(['a: x # b: c', '# d: e: f', 'g: y'])).length === 0);
check('windows line endings are read as the same file', lintYaml(GOOD.replace(/\n/g, '\r\n')).length === 0);
// the job checks (run 45058728995, 2026-11-22: GitHub refused the whole of ci.yml, "Job 'deploy' depends on unknown job 'net-b-4'", after a script mangled a needs list; the YAML was fine, so the text checks passed)
const jobs = (lines) => lintJobs(L(lines)).map((p) => p.message);
const J = (needs) => ['jobs:', '  net:', '    runs-on: x', '  net-b:', '    runs-on: x', '  net-4:', '    runs-on: x', '  deploy:', ...needs, '    runs-on: x'];
check('needs that name real jobs pass (inline list, a lone name, a block list)', jobs(J(['    needs: [net, net-b, net-4]'])).length === 0 && jobs(J(['    needs: net-4'])).length === 0 && jobs(J(['    needs:', '      - net', '      - net-b'])).length === 0);
check('the 2026-11-22 break: a needs list with net, net-b-4 and no net-4 is refused, naming the unknown job and the repeated one',
  (() => { const m = jobs(J(['    needs: [net, net-b, net, net-b-4]'])); return m.some((x) => /unknown job 'net-b-4'/.test(x)) && m.some((x) => /lists 'net' twice/.test(x)); })());
check('a block-list needs naming an unknown job is refused', jobs(J(['    needs:', '      - net', '      - nope'])).some((x) => /unknown job 'nope'/.test(x)));
check('a lone needs naming an unknown job is refused, with the line of the needs', (() => { const p = lintJobs(L(J(['    needs: nope']))); return p.length === 1 && p[0].line === 9; })());
check('a job that needs itself is refused', jobs(J(['    needs: [deploy]'])).some((x) => /needs itself/.test(x)));
check('a cycle between two jobs is refused', jobs(['jobs:', '  a:', '    needs: [b]', '    runs-on: x', '  b:', '    needs: [a]', '    runs-on: x']).some((x) => /cycle/.test(x)));
check('a matrix expression in a job with no strategy is refused (in a name, a run and an if)', jobs(['jobs:', '  a:', '    name: A ${{ matrix.shard }}', '    runs-on: x']).length === 1 && jobs(['jobs:', '  a:', '    runs-on: x', '    steps:', '      - run: echo ${{ matrix.set }}']).length === 1 && jobs(['jobs:', '  a:', '    runs-on: x', '    steps:', '      - if: matrix.shard == 1', '        run: x']).length === 1);
check('the same expressions in a job that has a strategy pass', jobs(['jobs:', '  a:', '    name: A ${{ matrix.shard }}', '    runs-on: x', '    strategy:', '      matrix:', '        shard: [1, 2]', '    steps:', '      - if: matrix.shard == 1', '        run: x']).length === 0);
check('a text with no jobs is not a workflow: no job problems', lintJobs(L(['name: x', 'runs:', '  using: composite'])).length === 0);
check('a comment that names a missing job or a matrix is ignored', jobs(['jobs:', '  a:', '    runs-on: x   # needs: nope, ${{ matrix.x }}', '  b:', '    needs: [a]   # not nope', '    runs-on: x']).length === 0);

// the real files of the repository
const root = join(import.meta.dirname, '..');
for (const f of ['.github/workflows/ci.yml']) if (existsSync(join(root, f))) check(`${f} has no job problems (every needs names a job, no cycle, matrix only under a strategy)`, lintJobs(readFileSync(join(root, f), 'utf8')).length === 0, JSON.stringify(lintJobs(readFileSync(join(root, f), 'utf8')).slice(0, 3)));
for (const f of ['.github/workflows/ci.yml']) if (existsSync(join(root, f))) check(`${f} parses`, lintYaml(readFileSync(join(root, f), 'utf8')).length === 0, JSON.stringify(lintYaml(readFileSync(join(root, f), 'utf8')).slice(0, 3)));

console.log(failed ? `check-workflows self-test FAILED: ${failed} of ${ran}` : `check-workflows self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

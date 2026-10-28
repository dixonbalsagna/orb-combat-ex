// Self-test of tools/check-workflows.mjs: the YAML a workflow file may hold passes, and each way a workflow file breaks is found at its line. The first fixture is the step that broke ci.yml on
// 2026-10-27 (an unquoted ": " in a step name). No dependency.
//   node tools/check-workflows-selftest.mjs
import { lintYaml } from './check-workflows.mjs';
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
// the real files of the repository
const root = join(import.meta.dirname, '..');
for (const f of ['.github/workflows/ci.yml']) if (existsSync(join(root, f))) check(`${f} parses`, lintYaml(readFileSync(join(root, f), 'utf8')).length === 0, JSON.stringify(lintYaml(readFileSync(join(root, f), 'utf8')).slice(0, 3)));

console.log(failed ? `check-workflows self-test FAILED: ${failed} of ${ran}` : `check-workflows self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

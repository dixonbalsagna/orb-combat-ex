// Self-test of tools/world-checks.mjs --shard (Tools, 2026-11-22): the world job runs three shards, and a check lost between them would never run. Node built-ins only; no Godot.
//   node tools/world-checks-selftest.mjs
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { shardOf } from './world-checks.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let n = 0, bad = 0;
const check = (name, ok, why = '') => { n++; if (!ok) { bad++; console.log(`  FAIL ${name}${why ? ': ' + why : ''}`); } };
const list = JSON.parse(readFileSync(join(here, 'world-checks.json'), 'utf8')).run;

for (const N of [1, 2, 3, 4, 7]) {
  const parts = Array.from({ length: N }, (_, i) => shardOf(list, i + 1, N));
  const all = parts.flat();
  check(`${N} shard(s) together run every listed check exactly once`, all.length === list.length && new Set(all).size === list.length && list.every((c) => all.includes(c)), `${all.length} of ${list.length}`);
  check(`${N} shard(s) are within one check of each other in size`, Math.max(...parts.map((p) => p.length)) - Math.min(...parts.map((p) => p.length)) <= 1);
}
check('shard 1 of 1 is the whole list, in order', JSON.stringify(shardOf(list, 1, 1)) === JSON.stringify(list));
check('a shard outside 1..N is refused (null)', shardOf(list, 0, 3) === null && shardOf(list, 4, 3) === null && shardOf(list, 1, 0) === null && shardOf(list, 1.5, 3) === null);
check('a small list: two checks in three shards leave the third empty, nothing lost', JSON.stringify([1, 2, 3].map((k) => shardOf(['a', 'b'], k, 3))) === JSON.stringify([['a'], ['b'], []]));

const cli = (args) => spawnSync(process.execPath, [join(here, 'world-checks.mjs'), ...args], { encoding: 'utf8' });
const s1 = cli(['--list', '--shard', '1/3']), s2 = cli(['--list', '--shard', '2/3']), s3 = cli(['--list', '--shard', '3/3']);
const got = [s1, s2, s3].flatMap((r) => r.stdout.split('\n').filter(Boolean));
check('the command prints the three shards, which together are the list', [s1, s2, s3].every((r) => r.status === 0) && got.length === list.length && new Set(got).size === list.length);
check('the command refuses a bad shard (exit 2, a message)', cli(['--list', '--shard', '4/3']).status === 2 && cli(['--run', '--shard', 'x']).status === 2 && /K\/N/.test(cli(['--list', '--shard', '0/3']).stderr));
check('--list without --shard is still the whole list', cli(['--list']).stdout.split('\n').filter(Boolean).length === list.length);

console.log(bad ? `world-checks self-test FAILED: ${bad} of ${n}` : `world-checks self-test ok: ${n} checks`);
process.exit(bad ? 1 : 0);

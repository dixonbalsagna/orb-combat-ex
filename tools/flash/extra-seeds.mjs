// The nightly-style seeds of a return (Legal RL-156, addendum 10): seeds 1008 and 1009 and 20 fresh ones, printed as a comma list for `run-pixels.mjs --seeds`:
//   node tools/flash/extra-seeds.mjs [--count 20]
// The 20 come from nextSeeds (tools/flash/nightly-seeds.mjs) from 1010 up, skipping the seeds of the recorded set (tools/flash/sources.json) and the ones the nightly history has read.
// (This was an inline node -e in interim-run.sh until the rehearsal of 2026-10-18, whose quotes the shell ate: the list came out empty and run-pixels then ran the whole set again.)
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { nextSeeds } from './nightly-seeds.mjs';

const here = import.meta.dirname;
const argv = process.argv.slice(2);
const i = argv.indexOf('--count');
const count = i >= 0 ? Number(argv[i + 1]) : 20;
const src = JSON.parse(readFileSync(join(here, 'sources.json'), 'utf8'));
const recorded = new Set((src.pairings || []).flatMap((p) => p.seeds || []));
const hf = join(here, 'nightly-seeds.json');
const hist = existsSync(hf) ? JSON.parse(readFileSync(hf, 'utf8')) : { runs: [] };
const used = hist.runs.flatMap((r) => r.seeds).filter((s) => s !== 1008 && s !== 1009);
const list = [1008, 1009, ...nextSeeds(count, 1010, recorded, used).filter((s) => s !== 1008 && s !== 1009)];
console.log(list.join(','));

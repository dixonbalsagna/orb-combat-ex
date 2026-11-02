#!/usr/bin/env node
// Sets two result files of the old-PC kit side by side (Performance and Platform, 2026-11-01): the two-processor check and the speed ratio.
//   node docs/perf/oldpc/kit/compare-results.mjs <result A.json> <result B.json>      (for example the main PC's and the old PC's; both from RUN-TEST.cmd)
//   node docs/perf/oldpc/kit/compare-results.mjs --orb [--main <file>] [--project <kit>/project] [--root <repo>]   (Orb's file: the newest oldpc-result-*.json in homework/1 Urgent against the newest mainpc-result-*.json in homework/Files, with the newest homework/Files/oldpc-kit-*/project for Netcode's compare)
//   node docs/perf/oldpc/kit/compare-results.mjs --selftest                           (proves the check can fail: a flipped hash is found at the right tick)
// Exit 0 when every match's gameplay hashes agree tick for tick; 1 when any differ or the files do not hold the same cases.
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const argv = process.argv.slice(2);
const load = (p) => JSON.parse(readFileSync(p, 'utf8'));
const med = (a) => { const s = [...a].sort((x, y) => x - y); return s[Math.floor(s.length / 2)]; };

export function compare(A, B) {
  const out = { lines: [], ok: true };
  const say = (l) => out.lines.push(l);
  if (!A.sim || !B.sim) { say('one of the files has no sim section (part 1 did not run there)'); out.ok = false; return out; }
  say(`A: ${A.cpu || A.sim.cpu} | ${A.sim.godot} | ${A.when}`);
  say(`B: ${B.cpu || B.sim.cpu} | ${B.sim.godot} | ${B.when}`);
  if (A.sim.ticks !== B.sim.ticks || A.sim.every !== B.sim.every || A.sim.cases.length !== B.sim.cases.length) { say('the two runs are not the same length or the same cases: not comparable'); out.ok = false; return out; }
  let checked = 0, differ = 0;
  A.sim.cases.forEach((ca, i) => {
    const cb = B.sim.cases[i];
    if (ca.planet !== cb.planet || ca.seed !== cb.seed) { say(`case ${i}: planet/seed differ (${ca.planet}:${ca.seed} against ${cb.planet}:${cb.seed})`); out.ok = false; return; }
    ca.matches.forEach((ma, j) => {
      const mb = cb.matches[j];
      const n = Math.min(ma.hashes.length, mb.hashes.length);
      let first = -1;
      for (let k = 0; k < n; k++) if (ma.hashes[k] !== mb.hashes[k]) { first = k; break; }
      checked += n + 1;
      const endSame = ma.final === mb.final && ma.end === mb.end;
      const tag = `planet ${ca.planet} seed ${ca.seed} ${j === 0 ? 'first match' : 'rematch'}`;
      if (first >= 0) { differ++; out.ok = false; say(`DIFFER  ${tag}: first different hash at tick ${(first + 1) * A.sim.every} (A ${ma.hashes[first].slice(0, 12)}, B ${mb.hashes[first].slice(0, 12)})`); }
      else if (!endSame) { differ++; out.ok = false; say(`DIFFER  ${tag}: every checkpoint agrees but the end differs (A ${ma.end}; B ${mb.end})`); }
      else say(`agree   ${tag}: ${n} checkpoints and the end`);
      say(`          speed A -> B: mean tick ${(ma.mean_us / 1000).toFixed(2)} -> ${(mb.mean_us / 1000).toFixed(2)} ms, p99 ${(ma.p99_us / 1000).toFixed(2)} -> ${(mb.p99_us / 1000).toFixed(2)}, max ${(ma.max_us / 1000).toFixed(1)} -> ${(mb.max_us / 1000).toFixed(1)}, over 16 ms ${ma.over16ms} -> ${mb.over16ms}, new match ${ma.new_ms} -> ${mb.new_ms} ms`);
    });
  });
  const mean = (R) => med(R.sim.cases.flatMap((c) => c.matches.map((m) => m.mean_us)));
  say(`fixed float64 job: ${A.sim.job_ms} -> ${B.sim.job_ms} ms (B is ${(B.sim.job_ms / A.sim.job_ms).toFixed(2)}x A);  median mean tick: ${(mean(A) / 1000).toFixed(2)} -> ${(mean(B) / 1000).toFixed(2)} ms (${(mean(B) / mean(A)).toFixed(2)}x)`);
  say(out.ok ? `SAME on both processors: ${checked} hashes compared, none differ.` : `NOT THE SAME: ${differ} match(es) differ.`);
  return out;
}

// --orb: find the two files and the kit's project folder inside the repo folder (nothing of the project lives outside it)
if (argv.includes('--orb')) {
  const o = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const root = resolve(o('--root', resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', '..')));
  const newest = (dir, re, want = 'file') => { if (!existsSync(dir)) return null; const c = readdirSync(dir).filter((f) => re.test(f)).map((f) => join(dir, f)).filter((f) => (want === 'dir' ? statSync(f).isDirectory() : statSync(f).isFile())).sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs); return c[0] || null; };
  const mine = o('--main', newest(join(root, 'homework', 'Files'), /^mainpc-result-.*\.json$/));
  const orbs = o('--orb-file', newest(join(root, 'homework', '1 Urgent'), /^oldpc-result-.*\.json$/));
  const kit = newest(join(root, 'homework', 'Files'), /^oldpc-kit-/, 'dir');
  const proj = o('--project', kit ? join(kit, 'project') : '');
  if (!mine || !orbs) { console.log(`--orb needs two files: the main PC's (${mine || 'none: homework/Files/mainpc-result-*.json'}) and Orb's (${orbs || 'none: homework/1 Urgent/oldpc-result-*.json'}); pass --main <file> and/or --orb-file <file>`); process.exit(2); }
  argv.length = 0; argv.push(mine, orbs, '--project', proj);
  if (o('--godot', '')) argv.push('--godot', o('--godot', ''));
  console.log(`main PC: ${mine}
Orb's:   ${orbs}
project: ${proj}
`);
}
if (argv[0] === '--selftest') {
  const mk = () => ({ cpu: 'x', when: 'now', sim: { godot: 'g', ticks: 600, every: 120, job_ms: 100, cases: [{ planet: 7, seed: 77, matches: [{ mean_us: 400, p99_us: 1200, max_us: 9000, over16ms: 0, new_ms: 1, final: 'abc', end: 'e', hashes: ['h1', 'h2', 'h3', 'h4', 'h5'] }] }] } });
  const a = mk(), b = mk();
  const same = compare(a, b);
  b.sim.cases[0].matches[0].hashes[2] = 'xx';
  const flipped = compare(a, b);
  const found = flipped.lines.some((l) => /first different hash at tick 360/.test(l));
  console.log(same.ok && !flipped.ok && found ? 'selftest OK (equal files agree; a flipped hash at the third checkpoint is reported at tick 360)' : 'selftest FAILED\n' + flipped.lines.join('\n'));
  process.exit(same.ok && !flipped.ok && found ? 0 : 1);
} else if (argv.filter((a, i) => !a.startsWith('--') && !(i > 0 && argv[i - 1].startsWith('--'))).length === 2) {
  const files = argv.filter((a, i) => !a.startsWith('--') && !(i > 0 && argv[i - 1].startsWith('--')));
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const A = load(files[0]), B = load(files[1]);
  const r = compare(A, B);
  console.log(r.lines.join('\n'));
  let code = r.ok ? 0 : 1;
  if (typeof A.twopc === 'string' && typeof B.twopc === 'string') {
    const dir = mkdtempSync(join(tmpdir(), 'oldpc-twopc-'));
    const fa = join(dir, 'report-A.txt'), fb = join(dir, 'report-B.txt');
    writeFileSync(fa, A.twopc); writeFileSync(fb, B.twopc);
    const project = opt('--project', ''), godot = opt('--godot', 'C:/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe');
    const cmd = [godot, '--headless', '--path', project || '<a tree with net/tools/two_pc_check.gd>', '--script', 'res://net/tools/two_pc_check.gd', '--', `--compare=${fa},${fb}`];
    if (!project) console.log("\nNetcode's two-PC reports are in both files. Compare them with:\n  " + cmd.map((x) => (/\s/.test(x) ? `"${x}"` : x)).join(' '));
    else {
      const res = spawnSync(cmd[0], cmd.slice(1), { encoding: 'utf8', windowsHide: true, timeout: 120000 });
      console.log("\nTwo-PC check (Netcode's compare), exit " + res.status + ':\n' + String(res.stdout).split('\n').filter((l) => /THE SAME|DIFFERENT|NOT COMPARABLE|tick_ms|snapshot/i.test(l)).join('\n'));
      code = Math.max(code, res.status === 0 ? 0 : res.status || 1);
    }
  } else console.log('\nOne of the files has no two-PC report (that part did not run there).');
  process.exit(code);
} else { console.log('usage: compare-results.mjs <A.json> <B.json> | --selftest'); process.exit(2); }

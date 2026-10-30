// Runs a command (a headless Godot gate) and FAILS when its output has SCRIPT ERROR lines, whatever the command's own exit code: a Godot script that hits a runtime error prints "SCRIPT ERROR:" and
// the run goes on, often exiting 0, so a gate can pass with the error hidden in its log (cue_check hid 650 that way, 2026-10-17).
//   node tools/gate.mjs [--allow <file>] [--max 0] -- <command> [args...]      run it, stream its output, fail on SCRIPT ERROR / Parse Error lines
//   node tools/gate.mjs [--allow <file>] [--max 0] --log <file>                 check a log that already exists (a run's saved output)
//   --verdict: also read the script's own verdict line ("NAME: N check(s) failed" or "NAME: N failed", the form World's *_check scripts end on) and fail when N is not 0 or when there is no such line.
//   World's checks end on a plain quit() (exit 0) whatever they found, so for them the verdict line IS the result; a run that quits early prints none and fails here too.
// Counted: lines that start (after spaces) with "SCRIPT ERROR:" or "Parse Error:", and "ERROR: Failed to load script". Not counted: warnings, "ERROR: ... resources still in use at exit" and the
// like, which Godot prints at exit. --allow names a JSON file { "allow": [ { "match": "<substring of the line>", "why": "<reason>" } ] } for the rare error that is known and accepted;
// default tools/gate-allow.json (none today). Exit: the command's exit code if it is not 0, else 1 when there are more counted lines than --max (default 0), else 0.
import { spawn } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const COUNTED = [/^\s*SCRIPT ERROR:/, /^\s*Parse Error:/, /^\s*ERROR: Failed to load script/];

/** The counted lines of a text, minus the allowed ones. Pure. */
export function scriptErrors(text, allow = []) {
  return String(text).split(/\r?\n/).filter((l) => COUNTED.some((re) => re.test(l)) && !allow.some((a) => a && a.match && l.includes(a.match)));
}

const VERDICT = /^\s*[A-Z][A-Z0-9 ]*: (\d+) (?:check\(s\) )?failed\s*$/;

/** Problems with a script's verdict lines: none printed, or one that counts failures. Pure. */
export function verdictProblems(text) {
  const lines = String(text).split(/\r?\n/).map((l) => VERDICT.exec(l)).filter(Boolean);
  if (!lines.length) return ['no verdict line ("NAME: N check(s) failed") in the output: the script may have quit before its checks finished'];
  return lines.filter((m) => Number(m[1]) > 0).map((m) => `verdict: ${m[0].trim()}`);
}

function loadAllow(file) {
  const f = file ? resolve(file) : join(import.meta.dirname, 'gate-allow.json');
  if (!existsSync(f)) { if (file) throw new Error(`${f} does not exist`); return []; }
  const j = JSON.parse(readFileSync(f, 'utf8'));
  return Array.isArray(j.allow) ? j.allow : [];
}

function report(errors, max, label) {
  if (errors.length > max) {
    console.error(`gate: ${label}: ${errors.length} SCRIPT ERROR line(s) in the output (allowed ${max}); the first:`);
    for (const l of errors.slice(0, 10)) console.error(`  ${l.trim().slice(0, 240)}`);
    return 1;
  }
  console.log(`gate: ${label}: no SCRIPT ERROR lines${errors.length ? ` (${errors.length} counted, ${max} allowed)` : ''}`);
  return 0;
}

function reportVerdict(text, label) {
  const bad = verdictProblems(text);
  if (bad.length) { console.error(`gate: ${label}: ${bad.join(' | ')}`); return 1; }
  console.log(`gate: ${label}: the verdict line reports no failures`);
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const dd = args.indexOf('--');
  const opts = dd >= 0 ? args.slice(0, dd) : args;
  const opt = (n, d) => { const i = opts.indexOf(n); return i >= 0 ? opts[i + 1] : d; };
  const max = Number(opt('--max', 0));
  const wantVerdict = opts.includes('--verdict');
  let allow = [];
  try { allow = loadAllow(opt('--allow')); } catch (e) { console.error(`gate: ${e.message}`); process.exit(2); }
  if (opt('--log')) {
    const text = readFileSync(resolve(opt('--log')), 'utf8');
    const lrc = report(scriptErrors(text, allow), max, opt('--log'));
    process.exit(lrc || (wantVerdict ? reportVerdict(text, opt('--log')) : 0));
  }
  if (dd < 0 || dd === args.length - 1) { console.error('usage: node tools/gate.mjs [--allow file] [--max N] [--verdict] -- <command> [args...]   |   --log <file>'); process.exit(2); }
  const [cmd, ...cargs] = args.slice(dd + 1);
  const child = spawn(cmd, cargs, { stdio: ['inherit', 'pipe', 'pipe'] });
  let buf = '';
  const tee = (stream, sink) => stream.on('data', (d) => { sink.write(d); buf += d.toString('utf8'); });
  tee(child.stdout, process.stdout); tee(child.stderr, process.stderr);
  child.on('error', (e) => { console.error(`gate: could not run ${cmd}: ${e.message}`); process.exit(2); });
  child.on('close', (code) => {
    const label = `${cmd} ${cargs.slice(-2).join(' ')}`.trim();
    const rc = report(scriptErrors(buf, allow), max, label);
    const vc = wantVerdict ? reportVerdict(buf, label) : 0;
    process.exit(code ? code : rc || vc);
  });
}

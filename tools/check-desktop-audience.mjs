// The desktop build's audience rule, checked on the workflow's text (Legal RL-262, docs/legal/desktop-build-rulings.md section 3; Tools, 2026-11-14).
//   node tools/check-desktop-audience.mjs [--file .github/workflows/desktop-builds.yml]      exit 0 when the rule holds, 1 with the problems named
// The rule: an owner-private run (the default audience) keeps NOTHING as a run file. So (1) the input `audience` exists with the two values and owner-private as its default; (2) every
// `actions/upload-artifact` step is gated by `if: inputs.audience == 'outside-testers'`, on the step or on its job; (3) every job that downloads an artifact (the Windows-runner jobs, which
// need the Windows zip an owner-private run never uploads) is gated the same way on the job; (4) the step that reads Orb's recorded yes is gated the same way; (5) no step publishes
// (a release, Pages or itch.io). A text check: the workflow is YAML and this reads its lines, with no parser (node built-ins only).
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const GATE = /inputs\.audience\s*==\s*'outside-testers'/;

/** Splits the jobs and steps out of a workflow's text: [{ job, header, steps: [{ text, line }] }]. Pure. */
export function jobsOf(text) {
  const lines = text.split(/\r?\n/);
  const out = [];
  let inJobs = false, cur = null, step = null;
  lines.forEach((l, i) => {
    if (/^jobs:\s*$/.test(l)) { inJobs = true; return; }
    if (!inJobs) return;
    const j = /^  ([A-Za-z][\w-]*):\s*$/.exec(l);
    if (j) { cur = { job: j[1], header: [], steps: [], line: i + 1 }; out.push(cur); step = null; return; }
    if (!cur) return;
    if (/^    steps:\s*$/.test(l)) { cur.inSteps = true; return; }
    if (cur.inSteps && /^      - /.test(l)) { step = { text: l, line: i + 1 }; cur.steps.push(step); return; }
    if (cur.inSteps && step) step.text += '\n' + l;
    else if (!cur.inSteps) cur.header.push(l);
  });
  return out;
}

/** Problems with the audience rule in a workflow's text (empty when it holds). Pure. */
export function problems(text) {
  const out = [];
  // 1. the input
  const inp = /^      audience:\s*\n((?:        .*\n?)+)/m.exec(text);
  if (!inp) out.push('there is no `audience` input');
  else {
    const b = inp[1];
    if (!/type:\s*choice/.test(b) || !/- owner-private/.test(b) || !/- outside-testers/.test(b)) out.push('the `audience` input is not a choice of owner-private and outside-testers');
    if (!/default:\s*owner-private/.test(b)) out.push('the `audience` input does not default to owner-private (the safe side)');
  }
  const jobs = jobsOf(text);
  if (!jobs.length) out.push('no jobs found in the workflow');
  for (const j of jobs) {
    const jobGated = j.header.some((l) => /^    if:/.test(l) && GATE.test(l));
    for (const s of j.steps) {
      const name = /name:\s*(.*)/.exec(s.text)?.[1] || (/uses:\s*(\S+)/.exec(s.text)?.[1] ?? 'a step');
      const stepGated = s.text.split('\n').some((l) => /^\s*(?:- )?if:/.test(l) && GATE.test(l));
      if (/uses:\s*actions\/upload-artifact@/.test(s.text) && !(stepGated || jobGated)) out.push(`${j.job} (line ${s.line}): an upload-artifact step is not gated by \`inputs.audience == 'outside-testers'\` (an owner-private run would keep a file)`);
      // an outside-testers package carries the site's active notice, never the owner's: `--notice` may be passed only inside an owner-private branch, and only with the owner notice file
      const code = s.text.split('\n').filter((l) => !/^\s*#/.test(l)).join('\n');
      for (const l of code.split(String.fromCharCode(10))) {
        const m = /--notice\s+(\S+)/.exec(l);
        if (!m) continue;
        if (m[1].replace(/[^A-Za-z0-9_.-]/g, '') !== 'site-interim-owner.json') out.push(`${j.job} (line ${s.line}): --notice names ${m[1]}, not the owner notice file (tools/site-interim-owner.json)`);
        if (!/"\$\{AUDIENCE\}"\s*=\s*"owner-private"/.test(l)) out.push(`${j.job} (line ${s.line}): --notice is passed on a line that does not test for owner-private (an outside-testers package must carry the site's active notice)`);
      }
      if (/Refuse without Orb's recorded yes/.test(s.text) && !(stepGated || jobGated)) out.push(`${j.job} (line ${s.line}): the recorded-yes step is not gated to outside-testers (an owner-private run has no approval file)`);
      if (/uses:\s*(softprops\/action-gh-release|actions\/deploy-pages|actions\/upload-pages-artifact|manleydev\/butler|josephbmanley\/butler)/.test(s.text) || /\bbutler push\b|gh release (create|upload)/.test(s.text)) out.push(`${j.job} (line ${s.line}): ${name}: a publishing step (release, Pages or itch.io) has no place in this workflow (RL-262)`);
    }
    if (j.steps.some((s) => /uses:\s*actions\/download-artifact@/.test(s.text)) && !jobGated) out.push(`${j.job}: the job downloads an artifact and is not gated by \`inputs.audience == 'outside-testers'\` (an owner-private run uploads none)`);
  }
  return out;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const i = argv.indexOf('--file');
  const file = i >= 0 ? resolve(argv[i + 1]) : join(dirname(fileURLToPath(import.meta.url)), '..', '.github', 'workflows', 'desktop-builds.yml');
  const p = problems(readFileSync(file, 'utf8'));
  for (const x of p) console.error('desktop audience check: ' + x);
  console.log(p.length ? `desktop audience check FAILED: ${p.length} problem(s)` : 'desktop audience check ok: owner-private is the default, every upload and download is gated to outside-testers, the recorded-yes step too, nothing publishes');
  process.exit(p.length ? 1 : 0);
}

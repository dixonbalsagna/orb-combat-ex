// The desktop build workflow keeps nothing and makes no testers' package, checked on its text (Legal RL-262; the EP's decision of 2026-11-25; Tools).
//   node tools/check-desktop-audience.mjs [--file .github/workflows/desktop-builds.yml]      exit 0 when the rule holds, 1 with the problems named
// The rule: a run file on a public repository is a public download, and the testers' report-channel line is kept out of git and out of repository secrets, so testers' packages are made on Orb's PC
// (tools/desktop-local-build.mjs --audience testers). So in this workflow: (1) the input `audience` has the one value owner-private; (2) no step uploads or downloads an artifact; (3) no step publishes (a release,
// Pages or itch.io); (4) nothing passes --testers or asks for Orb's yes, and --notice names only the owner notice. A text check: it reads the workflow's lines, with no parser (node built-ins only).
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

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

/** Problems with the rule in a workflow's text (empty when it holds). Pure. */
export function problems(text) {
  const out = [];
  const inp = /^      audience:\s*\n((?:        .*\n?)+)/m.exec(text);
  if (!inp) out.push('there is no `audience` input');
  else {
    const b = inp[1];
    const options = [...b.matchAll(/^          - (\S+)\s*$/gm)].map((m) => m[1]);
    if (!/type:\s*choice/.test(b) || options.join() !== 'owner-private') out.push(`the \`audience\` input is not a choice of owner-private alone (found: ${options.join(', ') || 'none'})`);
    if (!/default:\s*owner-private/.test(b)) out.push('the `audience` input does not default to owner-private');
  }
  const jobs = jobsOf(text);
  if (!jobs.length) out.push('no jobs found in the workflow');
  for (const j of jobs) {
    for (const s of j.steps) {
      const code = s.text.split('\n').filter((l) => !/^\s*#/.test(l)).join('\n');
      const at = `${j.job} (line ${s.line})`;
      if (/uses:\s*actions\/(upload|download)-artifact@/.test(code)) out.push(`${at}: an artifact step: this workflow keeps nothing (RL-262; testers' packages are made on Orb's PC)`);
      if (/uses:\s*(softprops\/action-gh-release|actions\/deploy-pages|actions\/upload-pages-artifact|manleydev\/butler|josephbmanley\/butler)/.test(code) || /\bbutler push\b|gh release (create|upload)/.test(code)) out.push(`${at}: a publishing step`);
      // the words "--audience testers" in a message that says where the testers' package is made are not the flag
      if (/(^|\s|=\()--testers(\s|\)|$)/m.test(code)) out.push(`${at}: --testers: a testers' package is never made by this workflow`);
      if (/orbs_yes|ORBS_YES/.test(code)) out.push(`${at}: Orb's yes is asked for here: the testers' route is the local build`);
      for (const l of code.split('\n')) {
        const m = /--notice\s+(\S+)/.exec(l);
        if (m && m[1].replace(/[^A-Za-z0-9_.-]/g, '') !== 'site-interim-owner.json') out.push(`${at}: --notice names ${m[1]}, not the owner notice file (tools/site-interim-owner.json)`);
      }
    }
  }
  return out;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const i = argv.indexOf('--file');
  const file = i >= 0 ? resolve(argv[i + 1]) : join(dirname(fileURLToPath(import.meta.url)), '..', '.github', 'workflows', 'desktop-builds.yml');
  const p = problems(readFileSync(file, 'utf8'));
  for (const x of p) console.error('desktop audience check: ' + x);
  console.log(p.length ? `desktop audience check FAILED: ${p.length} problem(s)` : 'desktop audience check ok: owner-private is the only audience, nothing is uploaded, downloaded or published, and no testers\' package is made here');
  process.exit(p.length ? 1 : 0);
}

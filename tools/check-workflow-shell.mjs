// Do the shell scripts in the workflow files parse? (2026-11-14: desktop-builds run 43582095368 failed on a runner at "The commit being built" with `unexpected EOF while looking for matching '` because an
// apostrophe sat inside ${VAR:+...} in a double-quoted echo. check-workflows.mjs reads the YAML and skips every block scalar, so a script nobody had run could carry a shell syntax error to a runner.)
// This reads each `run:` of every workflow and action file (a block scalar or a one-line value), replaces every ${{ expression }} with a placeholder word, and asks bash to parse it (`bash -n`: it
// parses, it runs nothing). A step with `shell: pwsh`, `powershell`, `cmd` or `python` is skipped (it is not bash). Node built-ins and bash only.
//   node tools/check-workflow-shell.mjs [<file or folder>...]     default: .github/workflows and .github/actions
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/** The run scripts of a YAML text: [{ line, script, shell }]. Pure. A block scalar's indentation is removed; ${{ ... }} becomes GHX. */
export function runScripts(text) {
  const lines = text.split(/\r?\n/);
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const m = /^(\s*)(?:- )?run:\s*(.*)$/.exec(lines[i]);
    if (!m) continue;
    const ind = m[1].length + (/^\s*- run:/.test(lines[i]) ? 2 : 0);
    let script = '';
    const rest = m[2].replace(/\s+#.*$/, '').trim();
    if (/^[|>][+-]?\d*$/.test(rest)) {
      const body = [];
      let j = i + 1, base = -1;
      for (; j < lines.length; j++) {
        const l = lines[j];
        if (l.trim() === '') { body.push(''); continue; }
        const li = /^(\s*)/.exec(l)[1].length;
        if (base < 0) base = li;
        if (li < base || li <= ind) break;
        body.push(l.slice(base));
      }
      script = body.join('\n');
    } else if (rest.startsWith("'") && rest.endsWith("'") && rest.length >= 2) script = rest.slice(1, -1).replace(/''/g, "'");
    else if (rest.startsWith('"') && rest.endsWith('"') && rest.length >= 2) script = rest.slice(1, -1).replace(/\\"/g, '"').replace(/\\\\/g, '\\');
    else script = rest;
    // the shell of the step: a `shell:` key at the same indent, above or below
    let shell = '';
    for (let k = i - 1; k >= 0; k--) { const s = /^(\s*)(?:- )?shell:\s*(\S+)/.exec(lines[k]); if (s && s[1].length === ind) { shell = s[2]; break; } if (/^\s*- /.test(lines[k]) && /^\s*- /.exec(lines[k])[0] && (/^(\s*)- /.exec(lines[k])[1].length < ind)) break; }
    for (let k = i + 1; k < lines.length && !shell; k++) { const s = /^(\s*)shell:\s*(\S+)/.exec(lines[k]); if (s && s[1].length === ind) { shell = s[2]; break; } if (/^\s*- /.test(lines[k]) && /^(\s*)- /.exec(lines[k])[1].length < ind + 1) break; if (lines[k].trim() && /^(\s*)/.exec(lines[k])[1].length < ind) break; }
    out.push({ line: i + 1, script: script.replace(/\$\{\{[\s\S]*?\}\}/g, 'GHX'), shell });
  }
  return out;
}

/** Problems of one YAML text: [{ line, message }]. Skips non-bash steps. */
export function shellProblems(text, bash = 'bash') {
  const out = [];
  const dir = mkdtempSync(join(tmpdir(), 'wf-shell-'));
  try {
    let n = 0;
    for (const r of runScripts(text)) {
      if (/^(pwsh|powershell|cmd|python)$/.test(r.shell) || !r.script.trim()) continue;
      const f = join(dir, `s${n++}.sh`);
      writeFileSync(f, r.script + '\n');
      const p = spawnSync(bash, ['-n', f], { encoding: 'utf8' });
      if (p.error) { out.push({ line: r.line, message: `bash could not be started: ${p.error.message}` }); continue; }
      if (p.status !== 0) out.push({ line: r.line, message: (p.stderr || '').trim().split(/\r?\n/).map((x) => x.replace(/^.*[\\/]s\d+\.sh: /, '')).join(' | ') });
    }
  } finally { rmSync(dir, { recursive: true, force: true }); }
  return out;
}

function filesUnder(p) {
  if (!existsSync(p)) return [];
  if (statSync(p).isFile()) return [p];
  return readdirSync(p, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? filesUnder(join(p, e.name)) : /\.ya?ml$/.test(e.name) ? [join(p, e.name)] : []));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
  const args = process.argv.slice(2);
  const targets = args.length ? args.map((a) => resolve(a)) : [join(root, '.github', 'workflows'), join(root, '.github', 'actions')];
  let bad = 0, scripts = 0, files = 0;
  for (const f of targets.flatMap(filesUnder)) {
    files++;
    const text = readFileSync(f, 'utf8');
    scripts += runScripts(text).length;
    for (const p of shellProblems(text)) { bad++; console.error(`${f.replace(root + '\\', '').replace(root + '/', '')}:${p.line}: shell syntax: ${p.message}`); }
  }
  console.log(bad ? `check-workflow-shell FAILED: ${bad} script(s) do not parse` : `check-workflow-shell ok: ${scripts} run scripts in ${files} files parse (bash -n)`);
  process.exit(bad ? 1 : 0);
}

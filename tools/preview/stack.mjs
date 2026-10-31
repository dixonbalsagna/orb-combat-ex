// The stack: HEAD plus an ordered list of parks (what the directors have parked and not yet landed) in ONE scratch export, so the integration is seen before anyone lands anything. The EP's work order of
// 2026-10-31 (Orb's playable). It applies each park in order, says the FIRST CONFLICT by file and owner, turns every switch on, runs validate, imports the project and plays a smoke match headless, and prints
// what each park needs that is not there. Never touches the repository (it reads files from it and writes only under a scratch folder; it refuses to run in the repository root).
//
//   node tools/preview/stack.mjs [--rev main] [--only id,id] [--skip id,id] [--include-unready] [--no-godot] [--no-smoke] [--ticks 900] [--out <scratch base>] [--state <file>] [--force] [--keep-tree] [--list]
//   --list          the parks of tools/preview/stack.json, in order, with their owners and whether they are ready
//   --no-godot      stop after the apply, the switches and validate (fast: a few seconds; for the hourly look)
//   --force         run again although nothing the stack is made of has changed since the last run
//   exit 0: every park applied, validate clean, the import and the smoke match clean; 1 otherwise (the report says what); 2 bad usage.
//
// The manifest (tools/preview/stack.json) lists the parks in the order they must land. A park's `steps` are `patch` (git apply, a path in the working tree), `copy` ({from, to}), `overlay` (working-tree paths laid over
// the scratch copy: work an owner has in their own folders and not committed yet) and `manual` (a note, never run). A park that ships an install script gets a `script` step: it runs ONLY when the file is exactly the one Tools reviewed (its sha1 is in the manifest), with the scratch tree as its one argument; any other apply script is never executed. `needs` says what the park wants that may be missing:
// {park}, {file}, {grep: {in, text}} or {note, owner} (a gap that is known and not in the tree: shown as missing until the manifest says otherwise). `ready: false` parks are left out unless --include-unready.
import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { tmpdir } from 'node:os';
import { dirname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { exportRevision } from '../flash/head-export.mjs';
import { scriptErrors } from '../gate.mjs';
import { godotExe, readPending, runGodot } from './preview.mjs';
import { SWITCHES, flip, locate, present, tableWith } from './switches.mjs';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const REPO = resolve(HERE, '..', '..');
export const MANIFEST = join(HERE, 'stack.json');

const sha1 = (...parts) => { const h = createHash('sha1'); for (const p of parts) h.update(p); return h.digest('hex'); };
const norm = (p) => String(p).replace(/\\/g, '/').replace(/^\.\//, '');

// ---------------------------------------------------------------------------------------------------- the manifest
/** Checks the manifest text. Returns { parks, problems }. */
export function loadManifest(text) {
  const problems = [];
  let doc;
  try { doc = JSON.parse(text); } catch (e) { return { parks: [], problems: [`stack.json is not JSON: ${e.message}`] }; }
  const parks = Array.isArray(doc.parks) ? doc.parks : [];
  const ids = new Set();
  parks.forEach((p, i) => {
    const at = `park ${i}${p && p.id ? ` (${p.id})` : ''}`;
    if (!p || typeof p.id !== 'string' || !/^[a-z0-9][a-z0-9-]*$/.test(p.id)) { problems.push(`${at}: needs an id of lower-case letters, digits and dashes`); return; }
    if (ids.has(p.id)) problems.push(`${at}: the id is used twice`);
    ids.add(p.id);
    if (typeof p.owner !== 'string' || !p.owner) problems.push(`${at}: needs an owner (a director's slug)`);
    if (!Array.isArray(p.steps) || !p.steps.length) problems.push(`${at}: needs steps`);
    (p.steps || []).forEach((s, j) => {
      const kinds = ['patch', 'copy', 'overlay', 'script', 'fixup', 'manual'].filter((k) => s && s[k] !== undefined);
      if (kinds.length !== 1) problems.push(`${at}, step ${j}: exactly one of patch, copy, overlay, script, fixup, manual`);
      else if (kinds[0] === 'fixup' && !(Array.isArray(s.fixup) && s.fixup.length && s.fixup.every((c) => c && typeof c.file === 'string' && typeof c.from === 'string' && c.from && typeof c.to === 'string') && typeof s.why === 'string' && s.why)) problems.push(`${at}, step ${j}: fixup is a list of {file, from, to, count?} and says why`);
      else if (kinds[0] === 'script' && !(typeof s.script === 'string' && /^[0-9a-f]{40}$/.test(String(s.sha1 || '')))) problems.push(`${at}, step ${j}: script is a path, and sha1 is the hash of the script as Tools reviewed it (an unreviewed or changed script is never run)`);
      else if (kinds[0] === 'patch' && typeof s.patch !== 'string') problems.push(`${at}, step ${j}: patch is a path`);
      else if (kinds[0] === 'patch' && s.exclude !== undefined && !(Array.isArray(s.exclude) && s.exclude.length && s.exclude.every((x) => typeof x === 'string') && typeof s.why === 'string' && s.why)) problems.push(`${at}, step ${j}: exclude is a list of paths and says why`);
      else if (kinds[0] === 'copy' && !(Array.isArray(s.copy) && s.copy.every((c) => c && typeof c.from === 'string' && typeof c.to === 'string'))) problems.push(`${at}, step ${j}: copy is a list of {from, to}`);
      else if (kinds[0] === 'overlay' && !(Array.isArray(s.overlay) && s.overlay.length && s.overlay.every((x) => typeof x === 'string'))) problems.push(`${at}, step ${j}: overlay is a list of paths`);
    });
    (p.needs || []).forEach((n, j) => { if (!n || !(n.park || n.file || n.grep || n.note)) problems.push(`${at}, need ${j}: park, file, grep or note`); });
  });
  for (const p of parks) for (const n of p.needs || []) if (n.park && !ids.has(n.park)) problems.push(`park ${p.id}: needs the park ${n.park}, which is not in the manifest`);
  return { parks, problems, doc };
}

/** The files a patch touches (the b side of every `diff --git`). Pure. */
export function patchFiles(text) {
  const git = [...new Set([...String(text).matchAll(/^diff --git a\/(.+?) b\/(.+)$/gm)].map((m) => m[2]))];
  if (git.length) return git;
  // a plain unified diff (no `diff --git` lines): the +++ lines name the files
  return [...new Set([...String(text).matchAll(/^\+\+\+ (?:b\/)?([^\t\n]+)/gm)].map((m) => m[1].trim()).filter((p) => p && p !== '/dev/null'))];
}

/** Who owns a path, from the charters' `owns:` lines ({ prefix -> slug }); the longest prefix wins. Pure. */
export function ownerOfPath(path, owners) {
  const p = norm(path);
  let best = null;
  for (const [prefix, slug] of Object.entries(owners)) if (p === prefix.replace(/\/$/, '') || p.startsWith(prefix)) if (!best || prefix.length > best[0].length) best = [prefix, slug];
  return best ? best[1] : null;
}

/** The owners map from a folder of charters (docs/directors/<slug>.md, line `owns: \`a/, b/\``). */
export function readOwners(dir) {
  const out = {};
  if (!existsSync(dir)) return out;
  for (const f of readdirSync(dir)) {
    if (!f.endsWith('.md')) continue;
    const m = /owns:\s*`([^`]+)`/.exec(readFileSync(join(dir, f), 'utf8').split('\n').slice(0, 8).join('\n'));
    if (!m) continue;
    for (const part of m[1].split(',').map((s) => s.trim()).filter(Boolean)) out[norm(part)] = f.replace(/\.md$/, '');
  }
  return out;
}

// ---------------------------------------------------------------------------------------------------- applying
/** git apply on a scratch tree. Returns { ok, already, files, error, failedFiles }. `already`: the patch is in the tree as it stands (it reverses cleanly), which is not a conflict. */
export function tryApply(tree, text, exclude = []) {
  const name = '.stack-step.patch';
  writeFileSync(join(tree, name), text);
  const git = (extra) => spawnSync('git', ['-c', 'core.autocrlf=false', '-c', 'core.eol=lf', 'apply', '--ignore-whitespace', ...exclude.map((x) => `--exclude=${x}`), ...extra, name], { cwd: tree, encoding: 'utf8' });
  try {
    const files = patchFiles(text).filter((x) => !exclude.includes(x));
    const chk = git(['--check']);
    if (chk.status === 0) { const r = git([]); return { ok: r.status === 0, already: false, files, error: r.status === 0 ? '' : String(r.stderr).trim(), failedFiles: [] }; }
    if (git(['-R', '--check']).status === 0) return { ok: true, already: true, files, error: '', failedFiles: [] };
    const err = String(chk.stderr || chk.error || '').trim();
    const failed = [...new Set([...err.matchAll(/^error: (?:patch failed: )?(.+?)(?::\d+)?(?:: (?:patch does not apply|already exists in working directory|No such file or directory|does not exist in index))?$/gm)].map((m) => m[1]).filter((f) => f && !/^patch /.test(f)))];
    return { ok: false, already: false, files, error: err, failedFiles: failed.length ? failed : files.slice(0, 1) };
  } finally { rmSync(join(tree, name), { force: true }); }
}

/** { relative path -> "mtime:size" } of every file under a tree (stat only): what a script changed is what differs between two snapshots. */
export function snapshotTree(tree) {
  const out = new Map();
  const walk = (rel) => {
    for (const e of readdirSync(join(tree, rel), { withFileTypes: true })) {
      const r = rel ? `${rel}/${e.name}` : e.name;
      if (e.isDirectory()) { if (e.name !== '.git' && e.name !== '.godot') walk(r); } else { const st = statSync(join(tree, r)); out.set(r, `${st.mtimeMs}:${st.size}`); }
    }
  };
  walk('');
  return out;
}

let pythonCache = null;
/** The python to run an install script with: python3, python or `py -3` (the first that answers --version), or null. */
export function findPython() {
  if (pythonCache !== null) return pythonCache || null;
  for (const c of [['python3'], ['python'], ['py', '-3']]) {
    const r = spawnSync(c[0], [...c.slice(1), '--version'], { encoding: 'utf8' });
    if (r.status === 0 && /Python 3/.test(`${r.stdout}${r.stderr}`)) { pythonCache = c; return c; }
  }
  pythonCache = false;
  return null;
}

/** Runs a reviewed install script on the scratch tree: python -I script tree, cwd the tree, two minutes. Returns { ok, stderr, stdout, noPython }. */
export function runScript(file, tree) {
  const py = findPython();
  if (!py) return { ok: false, stderr: '', stdout: '', noPython: true };
  const r = spawnSync(py[0], [...py.slice(1), '-I', file, tree], { cwd: tree, encoding: 'utf8', timeout: 120000, maxBuffer: 1 << 26 });
  return { ok: r.status === 0, stderr: String(r.stderr || r.error || ''), stdout: String(r.stdout || '') };
}

const filesUnder = (dir, rel = '') => readdirSync(join(dir, rel), { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? filesUnder(dir, join(rel, e.name)) : [join(rel, e.name).split(sep).join('/')]));
const same = (a, b) => existsSync(a) && existsSync(b) && readFileSync(a).equals(readFileSync(b));

/**
 * Applies the parks in order to `tree`. `repo` is where the park files are read from (the working tree). Returns { parks: [{ id, owner, ready, status, steps: [...], files }], touched: Map(file -> park id),
 * firstConflict }. A park whose step conflicts is NOT applied (its earlier steps stay: they are reported) and the stack goes on with the next, so one report shows every conflict.
 */
export function applyStack({ repo, tree, parks, owners = {} }) {
  const touched = new Map();
  const results = [];
  const applied = new Set();
  let firstConflict = null;
  for (const park of parks) {
    const res = { id: park.id, owner: park.owner, status: 'applied', steps: [], files: [], notes: park.notes || '' };
    for (const [si, s] of park.steps.entries()) {
      const label = s.patch ? `patch ${s.patch}${s.exclude ? ` (EXCLUDING ${s.exclude.join(', ')})` : ''}` : s.copy ? `copy ${s.copy.map((c) => c.to).join(', ')}` : s.overlay ? `overlay ${s.overlay.join(', ')}` : s.script ? `script ${s.script}` : s.fixup ? `FIXUP ${s.fixup.map((c) => c.file).join(', ')}` : `manual: ${s.manual}`;
      const step = { label, state: 'applied', detail: '' };
      const conflict = (file, why) => {
        step.state = 'conflict'; step.detail = why;
        const earlier = touched.get(file) || null;
        step.conflict = { file, with: earlier || 'HEAD', fileOwner: ownerOfPath(file, owners), parkOwner: park.owner, why };
        if (!firstConflict) firstConflict = { park: park.id, step: label, ...step.conflict };
        res.status = 'conflict';
      };
      if (s.manual !== undefined) { step.state = 'manual'; step.detail = String(s.manual); res.steps.push(step); continue; }
      if (s.patch) {
        const f = join(repo, ...norm(s.patch).split('/'));
        if (!existsSync(f)) { step.state = 'missing'; step.detail = `${s.patch} is not in the working tree`; res.status = res.status === 'conflict' ? 'conflict' : 'missing'; res.steps.push(step); break; }
        const r = tryApply(tree, readFileSync(f, 'utf8'), s.exclude || []);
        if (s.exclude && r.ok) step.detail = `EXCLUDING ${s.exclude.join(', ')}: ${s.why}`;
        if (r.already) { step.state = 'already'; step.detail = 'already in the tree (it reverses cleanly): landed'; }
        else if (!r.ok) conflict(r.failedFiles[0], `does not apply: ${r.error.split('\n').slice(0, 2).join(' | ').slice(0, 220)}`);
        else for (const file of r.files) { touched.set(file, park.id); res.files.push(file); }
      } else if (s.fixup) {   // a bridge between two parks, until their owner re-cuts one: the text must be there exactly `count` times, and the report says FIXUP and why
        step.detail = `FIXUP: ${s.why}`;
        for (const c of s.fixup) {
          const file = join(tree, ...norm(c.file).split('/'));
          if (!existsSync(file)) { conflict(norm(c.file), `${c.file} is not in the tree for the fixup`); break; }
          const raw = readFileSync(file, 'utf8');
          const crlf = raw.includes('\r\n');
          const text = raw.split('\r\n').join('\n');
          const n = text.split(c.from).length - 1;
          if (n === 0 && text.includes(c.to)) { step.state = 'already'; continue; }
          if (n !== (c.count || 1)) { conflict(norm(c.file), `the fixup expects its text ${c.count || 1} time(s) in ${c.file} and finds it ${n} (${s.why})`); break; }
          const out = text.split(c.from).join(c.to);
          writeFileSync(file, crlf ? out.split('\n').join('\r\n') : out);
          touched.set(norm(c.file), park.id); res.files.push(norm(c.file));
        }
      } else if (s.copy) {
        for (const c of s.copy) {
          const from = join(repo, ...norm(c.from).split('/')), to = join(tree, ...norm(c.to).split('/'));
          if (!existsSync(from)) { step.state = 'missing'; step.detail = `${c.from} is not in the working tree`; res.status = res.status === 'conflict' ? 'conflict' : 'missing'; break; }
          if (existsSync(to) && same(from, to)) { step.state = 'already'; step.detail = `${c.to} is already the same`; continue; }
          if (existsSync(to) && !c.replace) { conflict(norm(c.to), `${c.to} exists and differs (add "replace": true to take the park's)`); break; }
          mkdirSync(dirname(to), { recursive: true });
          copyFileSync(from, to);
          touched.set(norm(c.to), park.id); res.files.push(norm(c.to));
        }
      } else if (s.overlay) {
        let n = 0;
        for (const p of s.overlay) {
          const src = join(repo, ...norm(p).split('/'));
          if (!existsSync(src)) { step.state = 'missing'; step.detail = `${p} is not in the working tree`; break; }
          const list = statSync(src).isDirectory() ? filesUnder(src).map((x) => `${norm(p)}/${x}`) : [norm(p)];
          for (const file of list) {
            const a = join(repo, ...file.split('/')), b = join(tree, ...file.split('/'));
            if (existsSync(b) && same(a, b)) continue;
            if (touched.has(file) && touched.get(file) !== park.id) { conflict(file, `the overlay's ${file} is the working tree's and would overwrite the change park ${touched.get(file)} made to it`); break; }
            mkdirSync(dirname(b), { recursive: true });
            copyFileSync(a, b);
            n++; touched.set(file, park.id); res.files.push(file);
          }
          if (step.state === 'conflict') break;
        }
        if (step.state === 'applied' && n === 0 && res.status === 'conflict') step.state = 'conflict';
        if (step.state === 'applied') step.detail = n ? `${n} files differ from the commit (uncommitted work laid over it)` : 'no file differs from the commit: landed';
        if (step.state === 'applied' && !n) step.state = 'already';
      } else if (s.script) {
        // an install script a park ships (Simulation's field-frame): run ONLY when it is the very file Tools reviewed (sha1 in the manifest), with the scratch tree as its one argument, python in isolated
        // mode, a time limit. Whatever it changed is read back by comparing the tree before and after. Any change to the script means it is not run until Tools has read it again.
        const f = join(repo, ...norm(s.script).split('/'));
        if (!existsSync(f)) { step.state = 'missing'; step.detail = `${s.script} is not in the working tree`; res.status = res.status === 'conflict' ? 'conflict' : 'missing'; }
        else if (sha1(readFileSync(f)) !== s.sha1) { step.state = 'unreviewed'; step.detail = `${s.script} is not the script Tools reviewed (its hash is ${sha1(readFileSync(f)).slice(0, 10)}, reviewed ${String(s.sha1).slice(0, 10)}): not run; Tools reads it again and updates stack.json`; res.status = 'unreviewed'; }
        else {
          const before = snapshotTree(tree);
          const r = runScript(f, tree);
          if (r.noPython) { step.state = 'missing'; step.detail = 'no python on this machine: the install script was not run'; res.status = res.status === 'conflict' ? 'conflict' : 'missing'; }
          else {
            const after = snapshotTree(tree);
            const changed = [...after.keys()].filter((p) => before.get(p) !== after.get(p));
            for (const p of changed) { touched.set(p, park.id); res.files.push(p); }
            if (!r.ok) {
              const failedFile = (/AssertionError: \('([^']+)'/.exec(r.stderr) || [])[1] || changed[0] || norm(s.script);
              conflict(failedFile, `the install script stopped: ${r.stderr.trim().split('\n').slice(-1)[0].slice(0, 200)}`);
              res.tainted = true;   // what it did before it stopped stays in the scratch tree
            } else step.detail = `${changed.length} files written or changed`;
          }
        }
      }
      res.steps.push(step);
      if (step.state === 'conflict' || step.state === 'missing' || step.state === 'unreviewed') { if (step.state === 'missing') res.status = res.status === 'conflict' ? 'conflict' : 'missing'; break; }
    }
    if (res.status === 'applied' && res.steps.length && res.steps.every((x) => x.state === 'already' || x.state === 'manual')) res.status = 'landed';
    if (res.status === 'applied' || res.status === 'landed') applied.add(park.id);
    results.push(res);
  }
  return { parks: results, touched, firstConflict, applied };
}

// ---------------------------------------------------------------------------------------------------- what is missing
/** For each park, what it needs that is not there: [{ need, why, owner }]. `tree` is the scratch tree after the apply. Pure apart from reading the tree. */
export function missingNeeds(parks, results, tree) {
  const status = new Map(results.parks.map((r) => [r.id, r.status]));
  const out = new Map();
  for (const p of parks) {
    const miss = [];
    for (const n of p.needs || []) {
      if (n.park) { const st = status.get(n.park); if (!(st === 'applied' || st === 'landed')) miss.push({ need: `the park ${n.park}`, why: st ? `it is ${st}` : 'it is not in this stack (left out or unready)', owner: (parks.find((x) => x.id === n.park) || {}).owner || null }); }
      else if (n.file) { if (!existsSync(join(tree, ...norm(n.file).split('/')))) miss.push({ need: n.file, why: 'not in the tree', owner: n.owner || null }); }
      else if (n.grep) {
        const f = join(tree, ...norm(n.grep.in).split('/'));
        if (!existsSync(f) || !readFileSync(f, 'utf8').includes(n.grep.text)) miss.push({ need: `"${n.grep.text}" in ${n.grep.in}`, why: 'not found', owner: n.owner || null });
      } else if (n.note) miss.push({ need: n.note, why: 'a known gap, not in the tree', owner: n.owner || null });
    }
    out.set(p.id, miss);
  }
  return out;
}

// ---------------------------------------------------------------------------------------------------- switches, validate, errors
/** Turns on every switch of the preview table, of the pending rows and of the parks (`switches` rows of the manifest) whose key is in the tree. Returns { on: [id], waiting: [{id, why}], problems }. */
export function flipAll(tree, extraRows = []) {
  const on = [], waiting = [], problems = [];
  const table = tableWith([...readPending().rows, ...extraRows]);
  for (const sw of table) {
    if (sw.setup || sw.url) {   // a key of the match's setup (gen3) or a page word (tiles): on when the tree has the code; the smoke match asks for it
      if (existsSync(join(tree, ...sw.presentIf.file.split('/')))) on.push(sw.id); else waiting.push({ id: sw.id, why: `${sw.presentIf.file} is not in the tree` });
      continue;
    }
    const f = join(tree, ...sw.file.split('/'));
    if (!existsSync(f)) { waiting.push({ id: sw.id, why: `${sw.file} is not in the tree` }); continue; }
    const text = readFileSync(f, 'utf8');
    if (!present(text, sw)) { waiting.push({ id: sw.id, why: `${sw.replace ? sw.replace.from : sw.path.join('.')} is not in ${sw.file}` }); continue; }
    try { const r = flip(text, sw); if (r.text !== text) writeFileSync(f, r.text); on.push(sw.id); } catch (e) { problems.push(e.message); waiting.push({ id: sw.id, why: 'its key holds neither value' }); }
  }
  for (const r of readPending().rows.filter((x) => !x.file)) waiting.push({ id: r.id, why: `no key yet (${r.owner})` });
  return { on, waiting, problems };
}

/** `node tools/validate.js` in the scratch tree: { ok, summary, findings: [{ level, file, pointer, rule }] }. */
export function runValidate(tree) {
  const r = spawnSync(process.execPath, ['tools/validate.js'], { cwd: tree, encoding: 'utf8', maxBuffer: 1 << 26 });
  const text = `${r.stdout || ''}\n${r.stderr || ''}`;
  const findings = [...text.matchAll(/^(error|warning)\s+(\S+?)(?::\d+)?\s+(\S+)\s+\[([^\]]+)\]/gm)].map((m) => ({ level: m[1], file: norm(m[2]), pointer: m[3], rule: m[4] }));
  const sum = /(\d+) files checked, (\d+) errors?, (\d+) warnings?/.exec(text);
  return { ok: r.status === 0, summary: sum ? { files: Number(sum[1]), errors: Number(sum[2]), warnings: Number(sum[3]) } : null, findings, tail: text.trim().split('\n').slice(-3).join(' | ').slice(0, 300) };
}

/** Which park a file belongs to in this stack (the last that touched it), or null: the commit's own. */
export const parkOf = (file, touched) => touched.get(norm(file)) || null;

/** The counted error lines of a Godot log, each with the `at: ...` line that follows it (where its res:// file is). */
export function errorBlocks(text) {
  const lines = String(text).split(/\r?\n/);
  const out = [];
  lines.forEach((l, i) => {
    if (!scriptErrors(l).length) return;
    const next = [lines[i + 1], lines[i + 2]].filter((x) => x !== undefined && (/^\s*at:/.test(x) || /res:\/\//.test(x)));
    out.push([l, ...next].join('\n'));
  });
  return out;
}

/** The `res://` files named by log lines that are errors, with the park each belongs to. Pure. */
export function attributeErrors(lines, touched, owners = {}) {
  const out = [];
  for (const line of lines) {
    const m = /res:\/\/([^\s:"')]+)/.exec(line);
    const file = m ? m[1] : null;
    out.push({ line: line.trim().split('\n')[0].slice(0, 240), file, park: file ? parkOf(file, touched) : null, fileOwner: file ? ownerOfPath(file, owners) : null });
  }
  return out;
}

// ---------------------------------------------------------------------------------------------------- the key, the change
/** A key of everything the stack is made of: the commit and the bytes of every park file it reads. Same key, same result: no work is done twice. */
export function stackKey(repo, sha, parks) {
  const h = createHash('sha1'); h.update(sha);
  for (const p of parks) {
    h.update(`|${JSON.stringify(p)}`);   // the park's whole entry (steps, needs, switches): a manifest edit is a change too
    for (const s of p.steps) {
      const paths = s.patch ? [s.patch] : s.copy ? s.copy.map((c) => c.from) : s.overlay ? s.overlay : s.script ? [s.script] : [];
      for (const path of paths) {
        const full = join(repo, ...norm(path).split('/'));
        if (!existsSync(full)) { h.update(`~${path}`); continue; }
        const files = statSync(full).isDirectory() ? filesUnder(full).map((x) => join(full, ...x.split('/'))) : [full];
        for (const f of files.sort()) { h.update(f.slice(repo.length)); h.update(readFileSync(f)); }
      }
    }
  }
  return h.digest('hex').slice(0, 12);
}

/** Does the tree declare this class (class_name X) in a script under sim/ or render/? */
function hasClass(tree, name) {
  const re = new RegExp('^class_name ' + name + '\\b', 'm');
  const walk = (d) => {
    let ents = [];
    try { ents = readdirSync(d, { withFileTypes: true }); } catch { return false; }
    for (const e of ents) {
      const p = join(d, e.name);
      if (e.isDirectory()) { if (walk(p)) return true; }
      else if (e.name.endsWith('.gd')) { try { if (re.test(readFileSync(p, 'utf8'))) return true; } catch { /* unreadable */ } }
    }
    return false;
  };
  return walk(join(tree, 'sim')) || walk(join(tree, 'render'));
}

/** What changed between two reports (the lines to send): the first conflict, each park's status, the validate count, the import and the smoke match. Pure. */
export function changesBetween(prev, now) {
  if (!prev) return ['first run of this stack'];
  const out = [];
  const fc = (r) => (r.firstConflict ? `${r.firstConflict.park}: ${r.firstConflict.file} (with ${r.firstConflict.with}; file owner ${r.firstConflict.fileOwner || '?'}, park owner ${r.firstConflict.parkOwner})` : 'none');
  if (fc(prev) !== fc(now)) out.push(`first conflict: ${fc(prev)} -> ${fc(now)}`);
  const ps = new Map(prev.parks.map((p) => [p.id, p.status]));
  for (const p of now.parks) if (ps.get(p.id) !== p.status) out.push(`park ${p.id}: ${ps.get(p.id) || 'new'} -> ${p.status}`);
  for (const p of prev.parks) if (!now.parks.some((x) => x.id === p.id)) out.push(`park ${p.id}: gone from the stack`);
  const ve = (r) => (r.validate && r.validate.summary ? `${r.validate.summary.errors} errors, ${r.validate.summary.warnings} warnings` : 'not run');
  if (ve(prev) !== ve(now)) out.push(`validate: ${ve(prev)} -> ${ve(now)}`);
  const imp = (r) => (r.import ? (r.import.ok ? 'clean' : `${r.import.errors.length} errors`) : 'not run');
  if (imp(prev) !== imp(now)) out.push(`import: ${imp(prev)} -> ${imp(now)}`);
  const sm = (r) => (r.smoke ? (r.smoke.ok ? 'ok' : `failed (${r.smoke.why})`) : 'not run');
  if (sm(prev) !== sm(now)) out.push(`smoke match: ${sm(prev)} -> ${sm(now)}`);
  const sm3 = (r) => (r.smoke3 ? (r.smoke3.ok ? 'ok' : `failed (${r.smoke3.why})`) : 'not run');
  if (sm3(prev) !== sm3(now)) out.push(`smoke match, gen 3 whole ring: ${sm3(prev)} -> ${sm3(now)}`);
  const smt = (r) => (r.smokeTiles ? (r.smokeTiles.ok ? 'ok' : `failed (${r.smokeTiles.why})`) : 'not run');
  if (smt(prev) !== smt(now)) out.push(`smoke match, tile ground: ${smt(prev)} -> ${smt(now)}`);
  const sws = (r) => (r.smokeSwing ? (r.smokeSwing.ok ? 'ok' : `failed (${r.smokeSwing.why})`) : 'not run');
  if (sws(prev) !== sws(now)) out.push(`swing probe: ${sws(prev)} -> ${sws(now)}`);
  const mc = (r) => Object.values(r.missing || {}).reduce((n, v) => n + v.length, 0);
  if (mc(prev) !== mc(now)) out.push(`things the parks still need: ${mc(prev)} -> ${mc(now)}`);
  return out;
}

// ---------------------------------------------------------------------------------------------------- the whole run
const git = (repo, args) => { const r = spawnSync('git', args, { cwd: repo, encoding: 'utf8' }); if (r.status !== 0) throw new Error(`git ${args.join(' ')} failed: ${String(r.stderr || r.error || '').trim().split('\n')[0]}`); return r.stdout.trim(); };

/** Refuses a scratch folder that is the repository or inside it. */
export function checkScratch(repo, dir) {
  const r = resolve(repo), d = resolve(dir);
  if (d === r || d.startsWith(r + sep) || r.startsWith(d + sep)) throw new Error(`the scratch folder ${d} is the repository or inside it: the stack writes only to a scratch folder`);
}

export async function runStack(o) {
  const repo = resolve(o.repo || REPO);
  const log = o.log || (() => {});
  const man = loadManifest(readFileSync(resolve(o.manifest || MANIFEST), 'utf8'));
  if (man.problems.length) throw new Error(`tools/preview/stack.json: ${man.problems.join('; ')}`);
  const only = new Set(o.only || []), skip = new Set(o.skip || []);
  const parks = man.parks.filter((p) => (!only.size || only.has(p.id)) && !skip.has(p.id) && (p.ready !== false || o.includeUnready));
  const left = man.parks.filter((p) => !parks.includes(p)).map((p) => `${p.id}${p.ready === false ? ' (unready)' : ''}`);
  const sha = git(repo, ['rev-parse', '--verify', `${o.rev || 'main'}^{commit}`]);
  const subject = git(repo, ['log', '-1', '--format=%s', sha]).slice(0, 100);
  const owners = readOwners(join(repo, 'docs', 'directors'));
  const key = stackKey(repo, sha, parks);
  const base = resolve(o.out || join(tmpdir(), 'meridian-stack'));
  checkScratch(repo, base);
  const stateFile = resolve(o.state || join(base, 'last.json'));
  let prev = null;
  try { prev = JSON.parse(readFileSync(stateFile, 'utf8')); } catch { /* none */ }
  if (prev && prev.key === key && !o.force && (o.noGodot || (prev.import && !prev.partial))) return { report: prev, changes: ['nothing the stack is made of has changed since the last run (--force to run again)'], unchanged: true, stateFile };
  const dir = join(base, `${sha.slice(0, 8)}-${key}`), tree = join(dir, 'tree');
  checkScratch(repo, tree);
  mkdirSync(dir, { recursive: true });
  rmSync(tree, { recursive: true, force: true });
  mkdirSync(tree, { recursive: true });
  log(`unpacking ${sha.slice(0, 8)} into ${tree}`);
  const ex = exportRevision(repo, tree, sha);
  if (!ex.ok) throw new Error(ex.message);
  const t0 = Date.now();
  const applied = applyStack({ repo, tree, parks, owners });
  const extraRows = parks.flatMap((p) => p.switches || []);
  const flips = flipAll(tree, extraRows);
  const missing = missingNeeds(parks, applied, tree);
  const report = {
    at: new Date().toISOString().slice(0, 16), key, commit: sha, subject, left, firstConflict: applied.firstConflict,
    parks: applied.parks.map((p) => ({ id: p.id, owner: p.owner, status: p.status, tainted: p.tainted || undefined, files: p.files.length, steps: p.steps.map((s) => ({ label: s.label, state: s.state, detail: s.detail, conflict: s.conflict })) })),
    missing: Object.fromEntries([...missing.entries()].filter(([, v]) => v.length)),
    switches: flips, validate: null, import: null, smoke: null, partial: false,
  };
  const stray = (f) => { const p = parkOf(f, applied.touched); return p ? `park ${p}` : 'the commit itself'; };
  const smokeSrc = join(HERE, 'smoke_match.gd');
  if (existsSync(smokeSrc)) { mkdirSync(join(tree, 'tools', 'preview'), { recursive: true }); copyFileSync(smokeSrc, join(tree, 'tools', 'preview', 'smoke_match.gd')); }
  if (existsSync(join(tree, 'tools', 'validate.js'))) {
    log('validate');
    const v = runValidate(tree);
    report.validate = { ok: v.ok, summary: v.summary, tail: v.tail, errors: v.findings.filter((f) => f.level === 'error').slice(0, 30).map((f) => ({ ...f, park: parkOf(f.file, applied.touched), fileOwner: ownerOfPath(f.file, owners) })) };
  }
  if (!o.noGodot) {
    const godot = o.godotNode ? null : godotExe(o.godot);
    const g = { godot, godotNode: o.godotNode };
    log('importing the project (Godot, below-normal priority)');
    const importLog = join(dir, 'import.log');
    const code = await runGodot(g, ['--headless', '--path', tree, '--import'], importLog, 25 * 60 * 1000);
    const text = (() => { try { return readFileSync(importLog, 'utf8'); } catch { return ''; } })();
    const errs = attributeErrors(errorBlocks(text).slice(0, 40), applied.touched, owners);
    report.import = { ok: code === 0 && errs.length === 0, code, errors: errs };
    if (!o.noSmoke && existsSync(join(tree, 'tools', 'preview', 'smoke_match.gd')) && code === 0) {
      const play = async (label, extra, logName) => {
        log(`playing a smoke match: ${label} (${o.ticks || 900} ticks, headless)`);
        const smokeLog = join(dir, logName);
        const sc = await runGodot(g, ['--headless', '--path', tree, '--script', 'res://tools/preview/smoke_match.gd', '--', `--ticks=${o.ticks || 900}`, ...extra], smokeLog, 20 * 60 * 1000);
        const st = (() => { try { return readFileSync(smokeLog, 'utf8'); } catch { return ''; } })();
        const serrs = attributeErrors(errorBlocks(st).slice(0, 40), applied.touched, owners);
        const line = (st.match(/^SMOKE .*$/m) || [''])[0];
        return { ok: sc === 0 && /^SMOKE ok/.test(line) && serrs.length === 0, code: sc, line, errors: serrs, why: serrs.length ? `${serrs.length} script errors` : !/^SMOKE/.test(line) ? `no SMOKE line (exit ${sc})` : !/^SMOKE ok/.test(line) ? 'the match stopped short' : '' };
      };
      report.smoke = await play('the planet as the data has it', [], 'smoke.log');
      // World's gen 3 (a field world: planetGen 3 on a whole ring, no arena key) when the tree has its code: the second match, named apart so a failure points at it
      if (existsSync(join(tree, 'sim', 'world', 'field.gd'))) report.smoke3 = await play('gen 3, a whole ring', ['--planet-gen=3'], 'smoke-gen3.log');
      // Rendering's tile ground (--tiles, a page word on the web) on that gen 3 whole ring, when the tree has it
      if (existsSync(join(tree, 'render', 'core', 'tile_ground.gd')) && existsSync(join(tree, 'sim', 'world', 'field.gd'))) report.smokeTiles = await play('the tile ground (--tiles) on gen 3', ['--planet-gen=3', '--tiles'], 'smoke-tiles.log');
      // Research's swing probe (a stand-in asking for a launch-sized swing every 300 ticks) when the tree has SimSwing and the live repo has the probe: copied into the scratch tree, never into the repo
      const probeSrc = join(repo, 'research', 'ring-any-angle', 'swing_smoke.gd.txt');
      if (existsSync(probeSrc) && hasClass(tree, 'SimSwing')) {
        log(`playing the swing probe (${o.ticks || 900} ticks, headless)`);
        copyFileSync(probeSrc, join(tree, 'tools', 'preview', 'swing_smoke.gd'));
        const swLog = join(dir, 'smoke-swing.log');
        const swc = await runGodot(g, ['--headless', '--path', tree, '--script', 'res://tools/preview/swing_smoke.gd', '--', `--ticks=${o.ticks || 900}`, '--gen=3'], swLog, 20 * 60 * 1000);
        const swt = (() => { try { return readFileSync(swLog, 'utf8'); } catch { return ''; } })();
        const swerrs = attributeErrors(errorBlocks(swt).slice(0, 40), applied.touched, owners);
        const swl = (swt.match(/^SWINGSMOKE .*$/gm) || []).join(' | ');
        report.smokeSwing = { ok: swc === 0 && /^SWINGSMOKE ok/.test(swl) && swerrs.length === 0, code: swc, line: swl, errors: swerrs, why: swerrs.length ? `${swerrs.length} script errors` : !/SWINGSMOKE/.test(swl) ? `no SWINGSMOKE line (exit ${swc})` : !/^SWINGSMOKE ok/.test(swl) ? 'the match stopped short' : '' };
      }
    }
  } else report.partial = true;
  report.seconds = Math.round((Date.now() - t0) / 1000);
  report.stray = undefined;
  if (!o.keepTree) rmSync(tree, { recursive: true, force: true });
  const changes = changesBetween(prev, report);
  mkdirSync(dirname(stateFile), { recursive: true });
  writeFileSync(stateFile, `${JSON.stringify(report, null, 2)}\n`);
  void stray;
  return { report, changes, unchanged: false, stateFile };
}

/** The report as text lines. */
export function describeReport(r) {
  const L = [];
  L.push(`Stack on ${r.commit.slice(0, 8)} (${r.subject}), ${r.at}${r.partial ? ', apply and validate only (--no-godot)' : ''}`);
  if (r.left.length) L.push(`  left out: ${r.left.join(', ')}`);
  for (const p of r.parks) {
    L.push(`  ${p.status.toUpperCase().padEnd(8)} ${p.id} (${p.owner}), ${p.files} files`);
    for (const s of p.steps.filter((x) => x.state !== 'applied' || /^FIXUP|EXCLUDING/.test(x.label))) L.push(`             ${s.state}: ${s.label}${s.detail ? ` — ${s.detail}` : ''}`);
    if (p.tainted) L.push(`             NOTE: ${p.id}'s install script stopped half-way and what it had done stays in the scratch tree: later parks may be affected (re-run with --skip ${p.id})`);
  }
  if (r.firstConflict) { const c = r.firstConflict; L.push(`FIRST CONFLICT: park ${c.park} (${c.parkOwner}), ${c.step}\n  file ${c.file}, in conflict with ${c.with === 'HEAD' ? 'the commit itself (HEAD moved since the park was made)' : `park ${c.with}`}; the file's owner is ${c.fileOwner || '?'}\n  ${c.why}`); }
  else L.push('First conflict: none');
  L.push(`Switches on: ${r.switches.on.join(', ') || '(none)'}`);
  for (const w of r.switches.waiting) L.push(`  waiting: ${w.id} (${w.why})`);
  for (const p of r.switches.problems) L.push(`  switch problem: ${p}`);
  if (r.validate) {
    const s = r.validate.summary;
    L.push(`Validate: ${s ? `${s.files} files, ${s.errors} errors, ${s.warnings} warnings` : `no summary (${r.validate.tail})`}`);
    for (const e of r.validate.errors.slice(0, 10)) L.push(`  ${e.file} ${e.pointer} [${e.rule}] ${e.park ? `park ${e.park}` : 'the commit'} (owner ${e.fileOwner || '?'})`);
  }
  if (r.import) {
    L.push(`Import: ${r.import.ok ? 'clean' : `${r.import.errors.length} script errors (exit ${r.import.code})`}`);
    for (const e of r.import.errors.slice(0, 8)) L.push(`  ${e.file || '?'}: ${e.park ? `park ${e.park}` : 'the commit'} (owner ${e.fileOwner || '?'}) ${e.line.slice(0, 120)}`);
  }
  for (const [key, label] of [['smoke', 'Smoke match'], ['smoke3', 'Smoke match, gen 3 whole ring'], ['smokeTiles', 'Smoke match, tile ground (--tiles)'], ['smokeSwing', 'Swing probe (Research\'s stand-in, a 30 degree swing every 300 ticks)']]) {
    const sm = r[key];
    if (!sm) continue;
    L.push(`${label}: ${sm.ok ? 'ok' : `FAILED (${sm.why})`} ${sm.line || ''}`);
    for (const e of sm.errors.slice(0, 8)) L.push(`  ${e.file || '?'}: ${e.park ? `park ${e.park}` : 'the commit'} (owner ${e.fileOwner || '?'}) ${e.line.slice(0, 120)}`);
  }
  const ids = Object.keys(r.missing);
  L.push(ids.length ? 'Missing, by park:' : 'Missing: nothing the manifest knows of');
  for (const id of ids) for (const m of r.missing[id]) L.push(`  ${id}: ${m.need} (${m.why}${m.owner ? `; ${m.owner}` : ''})`);
  return L;
}

async function main() {
  const a = process.argv.slice(2);
  const known = new Set(['--rev', '--only', '--skip', '--include-unready', '--no-godot', '--no-smoke', '--ticks', '--out', '--state', '--force', '--keep-tree', '--list', '--repo', '--manifest', '--godot', '--help']);
  for (const x of a) if (x.startsWith('--') && !known.has(x)) { console.error(`unknown option ${x}; node tools/preview/stack.mjs --help`); process.exit(2); }
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const has = (n) => a.includes(n);
  if (has('--help')) { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).slice(0, 18).map((l) => l.slice(3)).join('\n')); return; }
  const repo = resolve(opt('--repo', REPO));
  if (has('--list')) {
    const man = loadManifest(readFileSync(resolve(opt('--manifest', MANIFEST)), 'utf8'));
    for (const p of man.problems) console.error(`  ${p}`);
    man.parks.forEach((p, i) => console.log(`  ${String(i + 1).padStart(2)}. ${p.id.padEnd(26)} ${p.owner.padEnd(22)} ${p.ready === false ? 'UNREADY ' : 'ready   '} ${p.steps.map((s) => (s.patch ? 'patch' : s.copy ? 'copy' : s.overlay ? 'overlay' : s.script ? 'script' : 'manual')).join('+')}`));
    process.exit(man.problems.length ? 1 : 0);
  }
  let res;
  try {
    res = await runStack({ repo, manifest: opt('--manifest'), rev: opt('--rev', 'main'), only: opt('--only', '').split(',').filter(Boolean), skip: opt('--skip', '').split(',').filter(Boolean), includeUnready: has('--include-unready'), noGodot: has('--no-godot'), noSmoke: has('--no-smoke'), ticks: Number(opt('--ticks', 900)), out: opt('--out'), state: opt('--state'), force: has('--force'), keepTree: has('--keep-tree'), godot: opt('--godot'), log: (m) => console.error(`[stack] ${m}`) });
  } catch (e) { console.error(`stack: ${e.message}`); process.exit(2); }
  for (const l of describeReport(res.report)) console.log(l);
  console.log(res.changes.length ? `\nCHANGED since the last run:\n${res.changes.map((c) => `  - ${c}`).join('\n')}` : '\nNo change since the last run.');
  const r = res.report;
  const bad = r.firstConflict || r.parks.some((p) => p.status === 'missing' || p.status === 'unreviewed') || (r.validate && r.validate.summary && r.validate.summary.errors > 0) || (r.import && !r.import.ok) || (r.smoke && !r.smoke.ok) || (r.smoke3 && !r.smoke3.ok) || (r.smokeTiles && !r.smokeTiles.ok) || (r.smokeSwing && !r.smokeSwing.ok);
  process.exit(bad ? 1 : 0);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();

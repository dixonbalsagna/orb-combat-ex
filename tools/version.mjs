// The game's version number and its changelog (A-TOOLS-07, Tools, 2026-11-14).
//
//   node tools/version.mjs                       print the version ("0.1.7")
//   node tools/version.mjs --next [--commit <sha>]   a build is being made: add one to the build counter in tools/version.json and put a new entry at the top of docs/tools/changelog.md
//   node tools/version.mjs --check [--ready]      the counter and the changelog agree (the top entry is the current version); with --ready the entry's line for players is written (not the placeholder)
//   node tools/version.mjs --windows             the four-number form for a Windows exe's version fields ("0.1.7.0")
//
// The number is "<major>.<minor>.<build>": major and minor are tools/version.json's own (the project's), the build is a counter that goes up by one for every build handed to a person (a kept build, a desktop
// build, a test build), and only by `--next`, which is run in the commit that is built, so the number a build carries is in its own commit and a rebuild of the same commit is the same number (the build id
// of a page build, its commit and cache key, is a different thing: it names the files, the number names the release). tools/write-build-info.mjs puts the number into build_info.json; tools/desktop-package.mjs
// writes it into the Windows and macOS version fields of a desktop export; the game shows it (UI's line, docs/tools/version.md). Each changelog entry is written for TWO readers: "For players" in plain words (Orb
// reads it before it is used anywhere), and "For the team" (the commit subjects since the last entry, as git has them). Node built-ins and git only.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const FILE = join(ROOT, 'tools', 'version.json');
const LOG = join(ROOT, 'docs', 'tools', 'changelog.md');
export const PLACEHOLDER = '(to be written: plain words, what a player sees that is new)';

export const versionOf = (v) => `${v.major}.${v.minor}.${v.build}`;
export const windowsOf = (v) => `${v.major}.${v.minor}.${v.build}.0`;

/** The versions the changelog text has entries for, top first: [{ version, date, commit, players, team }]. Pure. */
export function entriesOf(text) {
  const out = [];
  const parts = text.replace(/\r\n/g, '\n').split(/^## /m).slice(1);
  for (const p of parts) {
    const head = p.split('\n')[0];
    const m = /^(\d+\.\d+\.\d+)(?: \((\d{4}-\d{2}-\d{2})(?:, ([0-9a-f]{7,40}))?\))?\s*$/.exec(head.trim());
    if (!m) continue;
    const players = (/^For players\s*\n([\s\S]*?)(?=\nFor the team|$)/m.exec(p) || [])[1];
    out.push({ version: m[1], date: m[2] || '', commit: m[3] || '', players: (players || '').trim(), team: ((/^For the team\s*\n([\s\S]*)$/m.exec(p) || [])[1] || '').trim() });
  }
  return out;
}

/** The text of one new entry. Pure. */
export function entryText({ version, date, commit, subjects }) {
  const L = [`## ${version} (${date}${commit ? ', ' + commit.slice(0, 8) : ''})`, '', 'For players', PLACEHOLDER, '', 'For the team'];
  if (!subjects.length) L.push('(no commits since the last entry)');
  for (const s of subjects.slice(0, 40)) L.push(`- ${s}`);
  if (subjects.length > 40) L.push(`- ...and ${subjects.length - 40} more`);
  return L.join('\n') + '\n';
}

/** The changelog text with `entry` put above the first entry (the header lines stay on top). Pure. */
export function withEntry(text, entry) {
  const t = text.replace(/\r\n/g, '\n');
  const i = t.search(/^## /m);
  return i < 0 ? t.replace(/\s*$/, '\n\n') + entry : t.slice(0, i) + entry + '\n' + t.slice(i);
}

/** The problems of the check, from version.json's content and the changelog text. Pure. */
export function problems(v, logText, { ready = false } = {}) {
  const out = [];
  for (const k of ['major', 'minor', 'build']) if (!Number.isInteger(v[k]) || v[k] < 0) out.push(`tools/version.json: ${k} is not a whole number`);
  const es = entriesOf(logText);
  if (v.build > 0) {
    if (!es.length) out.push('docs/tools/changelog.md has no entry');
    else if (es[0].version !== versionOf(v)) out.push(`the top entry of docs/tools/changelog.md is ${es[0].version}, tools/version.json says ${versionOf(v)}: \`node tools/version.mjs --next\` adds the entry and the counter together`);
    else if (ready && (!es[0].players || es[0].players === PLACEHOLDER)) out.push(`the entry for ${es[0].version} has no line for players yet (Orb reads it before any build is handed on)`);
  }
  const seen = new Set();
  for (const e of es) { if (seen.has(e.version)) out.push(`the changelog has ${e.version} twice`); seen.add(e.version); }
  return out;
}

function git(...a) { try { return execFileSync('git', ['-C', ROOT, ...a], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim(); } catch { return ''; } }

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  try {
    const v = JSON.parse(readFileSync(FILE, 'utf8'));
    if (a.includes('--windows')) console.log(windowsOf(v));
    else if (a.includes('--check')) {
      const ps = problems(v, readFileSync(LOG, 'utf8'), { ready: a.includes('--ready') });
      for (const p of ps) console.log(`version: ${p}`);
      console.log(ps.length ? `version: ${ps.length} problem(s)` : `version ok: ${versionOf(v)}, the changelog's top entry agrees`);
      process.exitCode = ps.length ? 1 : 0;
    } else if (a.includes('--next')) {
      const log = readFileSync(LOG, 'utf8');
      const prev = entriesOf(log)[0];
      const sha = (opt('--commit') || git('rev-parse', 'HEAD')).trim();
      const since = prev && prev.commit ? git('log', '--format=%s', `${prev.commit}..${sha || 'HEAD'}`) : git('log', '--format=%s', '-n', '40', sha || 'HEAD');
      const next = { ...v, build: v.build + 1 };
      const date = git('log', '-1', '--format=%cs', sha || 'HEAD') || new Date().toISOString().slice(0, 10);
      writeFileSync(FILE, JSON.stringify(next, null, 2) + '\n');
      writeFileSync(LOG, withEntry(log, entryText({ version: versionOf(next), date, commit: sha, subjects: since.split('\n').filter(Boolean) })));
      console.log(`version ${versionOf(v)} to ${versionOf(next)}: tools/version.json and a new entry at the top of docs/tools/changelog.md; write the entry's line for players (Orb reads it first)`);
    } else console.log(versionOf(v));
  } catch (e) { console.error(`version: ${e.message}`); process.exitCode = 2; }
}

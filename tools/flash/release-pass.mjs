// The recorded full-set pass that must exist before the site can go online (Legal's list, RL-121; the EP accepted the design, 2026-10-06).
//
//   node tools/flash/release-pass.mjs --record --summary <run-pixels summary.json> [--commit <sha>]    write tools/flash/release-pass.json from a full required-set run
//   node tools/flash/release-pass.mjs --verify [--commit <sha>]                                       check it against a commit (default HEAD); exit 1 with the reasons if it does not hold
//
// What the record holds, and what makes it stale:
//   contentHash      the git tree and blob ids of everything the player runs: every top-level entry of the commit except the ones export_presets.cfg excludes (prototype, qa, research,
//                    docs, tools, .github) and the repository's own text files (CLAUDE.md, DIRECTORS.md, README.md, dotfiles). A commit that changes only docs/, tools/, qa/, research/,
//                    prototype/, .github/ or those text files leaves it unchanged, so a docs-only commit does not invalidate a pass. Any change to render/, sim/, data/, ui/, audio/, art/,
//                    project.godot or export_presets.cfg does (art/ is hashed whole: conservative).
//   requiredSetHash  sha-256 of tools/flash/sources.json at the commit (the scenarios, seeds, pairings and lengths): a changed set needs a new run
//   analyserHash     sha-256 of tools/flash/wcag.js and verdict.js at the commit (the reading of the standard and the verdict rule), line endings normalised
//   hookHash         sha-256 of render/tools/flash_capture.gd at the commit (the staging the clips were captured with)
//   rows             one per clip of the required set: its verdict (PASS), the three runs' counts, the red count, the margin and the whole-screen dips
// --verify fails unless the file exists, the four hashes equal the commit's, the rows are exactly the required clips, every row is PASS and no two whole-screen dips of a clip are
// closer than DIP_GAP_TICKS (the cap on dips: the flash count already includes each dip, this keeps them from coming in a train).
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { requiredClips } from './clips.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(here, '..', '..');
export const RECORD = join(here, 'release-pass.json');
export const DIP_GAP_TICKS = 60;
const NOT_THE_PLAYER = new Set(['prototype', 'qa', 'research', 'docs', 'tools', '.github', '.git', 'CLAUDE.md', 'DIRECTORS.md', 'README.md', '.gitignore', '.gitattributes', '.gdignore', '.editorconfig', 'LICENSE', 'LICENSE.md']);

const git = (root, args) => execFileSync('git', args, { cwd: root, encoding: 'utf8', maxBuffer: 1 << 28 }).trim();
const sha256 = (text) => createHash('sha256').update(text).digest('hex');
/** The committed bytes of a file as text with LF line endings. */
const showAt = (root, sha, path) => execFileSync('git', ['show', `${sha}:${path}`], { cwd: root, encoding: 'utf8', maxBuffer: 1 << 28 }).replace(/\r\n/g, '\n');

/** The content hash of a commit: the ids of every top-level entry the player runs. Returns { hash, entries: ["name oid", ...] }. */
export function contentHash(root, sha) {
  const entries = git(root, ['ls-tree', sha]).split('\n').filter(Boolean).map((l) => {
    const m = /^\d+ \w+ ([0-9a-f]+)\t(.+)$/.exec(l);
    return { oid: m[1], name: m[2] };
  }).filter((e) => !NOT_THE_PLAYER.has(e.name)).map((e) => `${e.name} ${e.oid}`).sort();
  return { hash: sha256(entries.join('\n')), entries };
}

export function hashesAt(root, sha) {
  return {
    contentHash: contentHash(root, sha).hash,
    requiredSetHash: sha256(showAt(root, sha, 'tools/flash/sources.json')),
    analyserHash: sha256(showAt(root, sha, 'tools/flash/wcag.js') + '\n--\n' + showAt(root, sha, 'tools/flash/verdict.js')),
    hookHash: sha256(showAt(root, sha, 'render/tools/flash_capture.gd')),
  };
}

/** The reasons a record does not hold for the hashes of a commit and the required clip ids (an empty list: it holds). Pure, so it can be tested without git. */
export function problemsWith(record, now, ids) {
  const out = [];
  if (!record || typeof record !== 'object') return ['there is no recorded full-set pass (tools/flash/release-pass.json)'];
  for (const k of ['contentHash', 'requiredSetHash', 'analyserHash', 'hookHash']) {
    if (record[k] !== now[k]) out.push(`${k} differs: the pass was recorded for other ${{ contentHash: 'game content (what the player runs changed since)', requiredSetHash: 'required set (tools/flash/sources.json changed)', analyserHash: 'analyser (wcag.js or verdict.js changed)', hookHash: 'capture staging (render/tools/flash_capture.gd changed)' }[k]}`);
  }
  const rows = Array.isArray(record.rows) ? record.rows : [];
  const have = new Set(rows.map((r) => r.id));
  for (const id of ids) if (!have.has(id)) out.push(`the record has no row for required clip ${id}`);
  for (const r of rows) {
    if (!ids.includes(r.id)) out.push(`the record has a row for ${r.id}, which is not in the required set`);
    if (r.verdict !== 'PASS') out.push(`${r.id} is ${r.verdict}, not PASS`);
    if (typeof r.shortestDipGapTicks === 'number' && r.shortestDipGapTicks < DIP_GAP_TICKS) out.push(`${r.id} has two whole-screen dips ${r.shortestDipGapTicks} ticks apart (the cap is ${DIP_GAP_TICKS})`);
  }
  return out;
}

/** Verify the record file against a commit of a repository. Returns the list of problems. */
export function verify(root = REPO, sha = 'HEAD', file = RECORD) {
  if (!existsSync(file)) return ['there is no recorded full-set pass (tools/flash/release-pass.json)'];
  let record;
  try { record = JSON.parse(readFileSync(file, 'utf8')); } catch (e) { return [`tools/flash/release-pass.json is not valid JSON: ${e.message}`]; }
  const ids = requiredClips(JSON.parse(showAt(root, sha, 'tools/flash/sources.json')), JSON.parse(showAt(root, sha, 'data/fighters/roster.json'))).map((c) => c.id);
  return problemsWith(record, hashesAt(root, sha), ids);
}

/** A row of the record from one clip's analysis result (run-pixels summary.json: { id, result }). */
export function rowOf(entry) {
  const r = entry.result;
  const c = r.combined;
  return {
    id: entry.id, verdict: c.verdict, primary: r.general.flashes, red: r.red.flashes, areaLower: c.lower, stricter: c.stricter,
    marginal: `${r.general.marginal + r.red.marginal}/${r.general.worstSecond.length + r.red.worstSecond.length}`,
    dips: r.dips.list.map((d) => ({ tick: d.tick, areaOfFrame: Math.round(d.areaOfFrame * 100) / 100, drop: Math.round(d.drop * 1000) / 1000 })), shortestDipGapTicks: r.dips.shortestGapFrames,
  };
}

function main(argv) {
  const opt = (n) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
  const sha = opt('--commit') || 'HEAD';
  if (argv.includes('--verify')) {
    const problems = verify(REPO, sha);
    if (problems.length) { for (const p of problems) console.error(`release pass: ${p}`); return 1; }
    console.log(`release pass holds for ${sha}: the recorded full-set pass matches the game content, the required set, the analyser and the staging, and every clip is PASS`);
    return 0;
  }
  if (argv.includes('--record')) {
    const sum = opt('--summary');
    if (!sum) { console.error('usage: node tools/flash/release-pass.mjs --record --summary <summary.json> [--commit <sha>]'); return 2; }
    const entries = JSON.parse(readFileSync(sum, 'utf8'));
    const ids = requiredClips().map((c) => c.id);
    const rows = entries.filter((e) => !e.error).map(rowOf);
    const bad = [];
    for (const id of ids) if (!rows.some((r) => r.id === id)) bad.push(`no result for ${id}`);
    for (const e of entries) if (e.error) bad.push(`${e.id}: capture failed`);
    for (const r of rows) if (r.verdict !== 'PASS') bad.push(`${r.id} is ${r.verdict}`);
    if (bad.length) { console.error('not recorded: the summary is not a full passing run of the required set:'); for (const b of bad) console.error('  ' + b); return 1; }
    const full = git(REPO, ['rev-parse', sha]);
    const record = { _why: 'A recorded full-set pass of the pixel check (tools/flash/release-pass.mjs --record). tools/build-site.mjs refuses to publish the playable site unless this file matches the commit being published and every row is PASS. Do not edit by hand.', commit: full, recorded: new Date().toISOString().slice(0, 10), ...hashesAt(REPO, full), rows: ids.map((id) => rows.find((r) => r.id === id)) };
    writeFileSync(RECORD, JSON.stringify(record, null, 2) + '\n');
    console.log(`recorded a pass of ${ids.length} clips for ${full.slice(0, 8)} in tools/flash/release-pass.json`);
    return 0;
  }
  console.error('usage: node tools/flash/release-pass.mjs (--record --summary <summary.json> | --verify) [--commit <sha>]');
  return 2;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) process.exit(main(process.argv.slice(2)));

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
// A release pass is never "just under" (Legal's addendum 6, RL-128, 2026-10-12): besides the combined rule (primary at most 2.5, no sensitivity run above 3, so a clip at exactly 3 is not a pass),
//   a row whose three readings (primary, area-15%, stricter memory) differ by more than 1.0 is SENSITIVE and counts only with a `recapture` row at another seed or start that passes and is not itself
//   sensitive; and a row with a counted change within 15% above the area threshold in its worst second must total 2.0 or less there. Both modes are in the required set (every clip is captured
//   normal and reduced) and the pass is on the commit being published (the four hashes).
// RL-131 (addendum 7, 2026-10-12): a clip captured on a starved machine is void, so every row records the capture's condition (the guard: CPU cap, time limit, owner's tag; the
//   machine's load before and after; the rate) and a rate under 1 frame a second voids it; a clip whose worst second is above 2.0 needs a SECOND independent capture and the worse reading counts
//   (captures that differ by more than 0.5 are flagged and re-run); a sensitive clip's re-capture must be a different run (another seed or variant), never a later window of the same run;
//   the HUD's own rate is a separate line of the pass (hud_check against 3 a second); and the 20 seeds are listed with the rule that picked them (tools/flash/pick-seeds.mjs).
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
export const SENSITIVE_SPREAD = 1.0;   // readings of one clip's worst second that differ by more than this: sensitive, re-captured at another seed or start before it counts
export const SECOND_CAPTURE_ABOVE = 2.0;  // a worst second above this (and up to 3) needs a second independent capture
export const SECOND_DIFF = 0.5;           // two captures that differ by more than this are flagged and re-run
export const MIN_FRAMES_A_SECOND = 1.0;   // a capture slower than this ran on a starved machine: void
export const HUD_LIMIT = 3;               // the HUD's own flicker rate, a second, shown as its own line
export const CLEAR_SECOND = 2.0;        // a second with a change within 15% above the threshold must total no more than this
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

/** The most the three readings of a row's worst second differ by (primary, area-15%, stricter memory). */
export function spreadOf(r) {
  const v = [r.primary, r.areaLower, r.stricter].filter((x) => typeof x === 'number');
  return v.length ? Math.max(...v) - Math.min(...v) : 0;
}
/** How many of a row's worst-second changes sit within 15% above the area threshold. A row carries `marginalCount`, or the older "marginal/total" string. */
export function marginalCountOf(r) {
  if (typeof r.marginalCount === 'number') return r.marginalCount;
  const m = /^(\d+)\/(\d+)$/.exec(String(r.marginal || ''));
  return m ? Number(m[1]) : 0;
}
/** The combined rule on three readings: FAIL over 3 on any, OVER GATE over 2.5 on the primary, PASS. */
export function verdictOf(x) {
  const over3 = [x.primary, x.areaLower, x.stricter].some((v) => typeof v === 'number' && v > 3);
  if (over3) return 'FAIL';
  return typeof x.primary === 'number' && x.primary > 2.5 ? 'OVER GATE' : 'PASS';
}
/** The readings that count for a row: the worse of its capture and its second capture, reading by reading. */
export function effective(r) {
  const s = r.second && typeof r.second === 'object' ? r.second : null;
  const worse = (a, b) => (typeof a === 'number' && typeof b === 'number' ? Math.max(a, b) : (typeof a === 'number' ? a : b));
  return {
    primary: worse(r.primary, s && s.primary), areaLower: worse(r.areaLower, s && s.areaLower), stricter: worse(r.stricter, s && s.stricter),
    marginalCount: Math.max(marginalCountOf(r), s ? marginalCountOf(s) : 0),
  };
}
/** What RL-131 says about how a row was captured and whether it needs, and has, a second capture. */
export function captureProblems(r) {
  const out = [];
  const g = r.guard;
  if (!g || typeof g !== 'object') out.push(`${r.id} has no recorded capture condition (the guard, the machine's load before and after, the rate): RL-131`);
  else if (typeof g.framesPerSecond === 'number' && g.framesPerSecond < MIN_FRAMES_A_SECOND) out.push(`${r.id} was captured at ${g.framesPerSecond} frames a second: the machine was starved and the clip is void`);
  if (typeof r.primary === 'number' && r.primary > SECOND_CAPTURE_ABOVE && r.primary <= 3) {
    const s = r.second;
    if (!s || typeof s !== 'object') out.push(`${r.id} reads ${r.primary} in its worst second (above ${SECOND_CAPTURE_ABOVE}): it needs a second independent capture, and the worse reading counts`);
    else {
      if (s.guard && typeof s.guard.framesPerSecond === 'number' && s.guard.framesPerSecond < MIN_FRAMES_A_SECOND) out.push(`${r.id}: its second capture was taken on a starved machine and is void`);
      const d = Math.max(...['primary', 'areaLower', 'stricter'].map((k) => (typeof r[k] === 'number' && typeof s[k] === 'number' ? Math.abs(r[k] - s[k]) : 0)));
      if (d > SECOND_DIFF + 1e-9) out.push(`${r.id}: its two captures differ by ${d} (more than ${SECOND_DIFF}): flagged, re-run`);
      const v = verdictOf(effective(r));
      if (v !== 'PASS') out.push(`${r.id}: with its second capture the worse readings are ${v}, not PASS`);
    }
  }
  if (r.recapture && typeof r.recapture === 'object' && /^\s*skip\b/i.test(String(r.recapture.how || ''))) out.push(`${r.id}: a sensitive clip's re-capture must be a different run (another seed, or a variant: start position, distance, direction or camera phase), not a later window of the same run (${r.recapture.how})`);
  return out;
}

/** What the margin rules (RL-128) say about one row, alone. */
export function marginProblems(r) {
  const out = [];
  const sp = spreadOf(r);
  if (sp > SENSITIVE_SPREAD + 1e-9) {
    const rc = r.recapture;
    if (!rc || typeof rc !== 'object') out.push(`${r.id} is sensitive (its readings differ by ${sp}, over ${SENSITIVE_SPREAD}) and has no re-capture at another seed or start`);
    else if (rc.verdict !== 'PASS') out.push(`${r.id} is sensitive and its re-capture (${rc.how || 'another seed or start'}) is ${rc.verdict}, not PASS`);
    else if (spreadOf(rc) > SENSITIVE_SPREAD + 1e-9) out.push(`${r.id} is still sensitive after its re-capture (${rc.how || 'another seed or start'}): its readings differ by ${spreadOf(rc)}`);
    else if (marginalCountOf(rc) >= 1 && typeof rc.primary === 'number' && rc.primary > CLEAR_SECOND) out.push(`${r.id}: the re-capture has a change within 15% above the threshold in a second that totals ${rc.primary}`);
  }
  const e = effective(r);
  if (e.marginalCount >= 1 && typeof e.primary === 'number' && e.primary > CLEAR_SECOND) {
    out.push(`${r.id} has ${e.marginalCount} counted change${e.marginalCount === 1 ? '' : 's'} within 15% above the area threshold in its worst second, which totals ${e.primary} (it must total ${CLEAR_SECOND} or less)`);
  }
  return out;
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
    for (const m of marginProblems(r)) out.push(m);
    for (const m of captureProblems(r)) out.push(m);
    if (typeof r.shortestDipGapTicks === 'number' && r.shortestDipGapTicks < DIP_GAP_TICKS) out.push(`${r.id} has two whole-screen dips ${r.shortestDipGapTicks} ticks apart (the cap is ${DIP_GAP_TICKS})`);
  }
  // the HUD's own rate, a separate line of the pass (k06), and the seeds with the rule that picked them
  if (!record.hud || typeof record.hud.perSecond !== 'number') out.push('the record has no HUD line (the HUD\'s own flicker rate from hud_check, against ' + HUD_LIMIT + ' a second)');
  else if (record.hud.perSecond > HUD_LIMIT) out.push(`the HUD's own rate is ${record.hud.perSecond} a second (the limit is ${HUD_LIMIT})`);
  if (!record.seedPick || !Array.isArray(record.seedPick.seeds) || !record.seedPick.seeds.length) out.push('the record does not list the AI seeds and the rule that picked them (tools/flash/pick-seeds.mjs)');
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
    marginalCount: r.general.marginal + r.red.marginal, secondChanges: r.general.worstSecond.length + r.red.worstSecond.length,
    spread: Math.round(spreadOf({ primary: r.general.flashes, areaLower: c.lower, stricter: c.stricter }) * 100) / 100,
    guard: entry.guard || null,
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
    // clips re-captured at another seed or start (run-pixels summary.json of those clips; --how says how: "seed 7" or "skip 600")
    const rcs = opt('--recaptures');
    if (rcs) {
      const how = opt('--how');
      if (!how) { console.error('--recaptures needs --how "seed N" or "skip N"'); return 2; }
      for (const e of JSON.parse(readFileSync(rcs, 'utf8'))) {
        const base = rows.find((r) => r.id === e.id);
        if (base && !e.error) base.recapture = { ...rowOf(e), how };
      }
    }
    // second independent captures of the clips above 2.0 (a run-pixels summary of those clips, captured again; the worse reading counts)
    const sec = opt('--seconds');
    if (sec) for (const e of JSON.parse(readFileSync(sec, 'utf8'))) { const base = rows.find((r) => r.id === e.id); if (base && !e.error) base.second = { ...rowOf(e), how: 'second capture' }; }
    const hudRate = opt('--hud-rate');
    const hud = hudRate === undefined ? null : { perSecond: Number(hudRate), limit: HUD_LIMIT, source: opt('--hud-source') || 'ui/tools/hud_check.gd' };
    const pick = opt('--seed-pick');
    const seedPick = pick ? JSON.parse(readFileSync(pick, 'utf8')) : null;
    for (const id of ids) if (!rows.some((r) => r.id === id)) bad.push(`no result for ${id}`);
    for (const e of entries) if (e.error) bad.push(`${e.id}: capture failed`);
    for (const r of rows) if (r.verdict !== 'PASS') bad.push(`${r.id} is ${r.verdict}`);
    for (const r of rows) for (const m of marginProblems(r)) bad.push(m);
    for (const r of rows) for (const m of captureProblems(r)) bad.push(m);
    if (!hud) bad.push('no HUD line: pass --hud-rate <the HUD\'s own worst rate a second from hud_check>');
    else if (hud.perSecond > HUD_LIMIT) bad.push(`the HUD's own rate is ${hud.perSecond} a second`);
    if (!seedPick) bad.push('no seed pick: pass --seed-pick <the output of tools/flash/pick-seeds.mjs>');
    if (bad.length) { console.error('not recorded: the summary is not a full passing run of the required set:'); for (const b of bad) console.error('  ' + b); return 1; }
    const full = git(REPO, ['rev-parse', sha]);
    const record = { _why: 'A recorded full-set pass of the pixel check (tools/flash/release-pass.mjs --record). tools/build-site.mjs refuses to publish the playable site unless this file matches the commit being published and every row is PASS. Do not edit by hand.', commit: full, recorded: new Date().toISOString().slice(0, 10), ...hashesAt(REPO, full), rows: ids.map((id) => rows.find((r) => r.id === id)), hud, seedPick };
    writeFileSync(RECORD, JSON.stringify(record, null, 2) + '\n');
    console.log(`recorded a pass of ${ids.length} clips for ${full.slice(0, 8)} in tools/flash/release-pass.json`);
    return 0;
  }
  console.error('usage: node tools/flash/release-pass.mjs (--record --summary <summary.json> [--recaptures <summary.json> --how "seed N"] [--seconds <summary.json>] --hud-rate <n> [--hud-source <text>] --seed-pick <pick.json> | --verify) [--commit <sha>]');
  return 2;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) process.exit(main(process.argv.slice(2)));

// Builds docs/production/milestones.md (the page Orb opens) and docs/production/milestone-rows.md
// (the full table, every row) from:
//   - the audit's register and milestone list (docs/ep/alpha/audit-2026-11-13/)
//   - ../status.json   (status, evidence, counts: edited when the EP sends status)
//   - ./milestone-data.mjs (the path's goals and exit lines)
// Run:  node docs/production/tools/build-tracker.mjs          (rebuild and check)
//       node docs/production/tools/build-tracker.mjs --check  (check only, write nothing)
// No dependencies, no Godot, no browser. Exit code 1 if any check fails.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { MILESTONES, DECISIONS, GLOSSARY } from './milestone-data.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const prod = path.resolve(here, '..');
// STATUS_FILE (optional) points at another status file, for trying a change with --check before saving it.
const status = JSON.parse(fs.readFileSync(process.env.STATUS_FILE || path.join(prod, 'status.json'), 'utf8'));
const AUDIT = path.resolve(prod, '../ep/alpha/audit-2026-11-13');
const reg = JSON.parse(fs.readFileSync(path.join(AUDIT, '03-gap-register.json'), 'utf8'));
const placed = JSON.parse(fs.readFileSync(path.join(AUDIT, '04-milestone-rows.json'), 'utf8'));
const byId = new Map(reg.map(r => [r.id, r]));
const checkOnly = process.argv.includes('--check');

const EXPECTED = { A1: 77, A2: 41, A3: 27, A4: 19, A5: 16, A6: 0 };
const STATUSES = ['not started', 'briefed', 'reported', 'landed'];
// Words that must never reach a page written for Orb (rows kept to the full table; see the brief).
const HELD = /flash|photosens|seizure|strobe|epilep|wcag/i;

const checks = [];
const check = (name, ok, detail = '') => checks.push({ name, ok, detail });
const cell = s => String(s ?? '').replace(/\|/g, '/').replace(/\s+/g, ' ').trim();

function short(g, max = 120) {
  g = cell(g);
  const dot = g.search(/\. [A-Z]/);
  if (dot > 40 && dot < max + 20) g = g.slice(0, dot);
  if (g.length > max) g = g.slice(0, g.lastIndexOf(' ', max - 1)) + '…';
  return g;
}

// ---- row status ----
const windowOf = new Map();
for (const m of MILESTONES) for (const id of m.window.rows) windowOf.set(id, m.window.name.split(' ')[0]);

function rowInfo(id, ms) {
  const r = byId.get(id);
  const o = status.rows[id];
  const d = status.ownerDefaults[ms]?.[r.owner] ?? status.defaultStatus;
  const s = o ?? d;
  return { id, ms, r, status: s.status, ref: s.ref || '', note: o?.note || '' };
}
const rows = {};
for (const m of MILESTONES) rows[m.id] = (placed[m.id] || []).map(id => rowInfo(id, m.id));

// ---- checks on the inputs ----
const seen = new Map();
for (const m of Object.keys(placed)) for (const id of placed[m]) seen.set(id, (seen.get(id) || 0) + 1);
check('every placed id exists in the register', [...seen.keys()].every(id => byId.has(id)), [...seen.keys()].filter(id => !byId.has(id)).join(' '));
check('every placed row is placed exactly once', [...seen.values()].every(n => n === 1), [...seen].filter(([, n]) => n !== 1).map(([k]) => k).join(' '));
for (const [m, n] of Object.entries(EXPECTED)) check(`${m} has ${n} rows (the path's count)`, (placed[m] || []).length === n, `found ${(placed[m] || []).length}`);
check('180 rows placed in all', seen.size === 180, `found ${seen.size}`);
const badStatus = Object.values(rows).flat().filter(x => !STATUSES.includes(x.status)).map(x => x.id);
check('every row has a valid status', badStatus.length === 0, badStatus.join(' '));
check('every added item has a valid status', (status.added || []).every(x => STATUSES.includes(x.status) && MILESTONES.some(m => m.id === x.milestone)), '');
const strayOverrides = Object.keys(status.rows).filter(id => !seen.has(id));
check('every status override names a placed row', strayOverrides.length === 0, strayOverrides.join(' '));
const noRef = Object.values(rows).flat().filter(x => (x.status === 'landed' && !/^[0-9a-f]{7,40}$/.test(x.ref)) || (x.status === 'reported' && !x.ref)).map(x => `${x.id}(${x.status})`);
check('landed rows carry a commit id, reported rows a report or record', noRef.length === 0, noRef.join(' '));
for (const m of MILESTONES) {
  const flagged = (placed[m.id] || []).filter(id => byId.get(id).hash).sort().join(' ');
  check(`${m.id}: rows that change the fingerprint match the path's window list`, flagged === [...m.window.rows].sort().join(' '), `register says: ${flagged}`);
}
const led = new Set();
const dirA1 = path.join(AUDIT, '05-directives/A1');
for (const f of fs.readdirSync(dirA1)) {
  const t = fs.readFileSync(path.join(dirA1, f), 'utf8');
  for (const id of ((t.match(/^Leads:\s*(.*)$/m) || [])[1] || '').match(/A-[A-Z]+-\d+/g) || []) led.add(id);
}
check('every A1 row is led by a line in an A1 brief', placed.A1.every(id => led.has(id)), placed.A1.filter(id => !led.has(id)).join(' '));

// ---- text builders ----
const count = (list, s) => list.filter(x => x.status === s).length;
const owners = list => [...new Set(list.map(x => x.r.owner))].sort();
const table = (head, body) => [`| ${head.join(' | ')} |`, `| ${head.map(() => '---').join(' | ')} |`, ...body.map(b => `| ${b.map(cell).join(' | ')} |`)].join('\n');
const evidence = x => [x.ref, x.note].filter(Boolean).join(' — ');

const heldRows = id => byId.get(id).off_orb_page === true;
const orbList = ms => rows[ms].filter(x => !heldRows(x.id));
const orbRowText = x => HELD.test(x.r.gap) ? '(see the full table)' : short(x.r.gap);

function summaryTable() {
  const body = MILESTONES.map(m => {
    const l = rows[m.id];
    return [m.id + (m.id === status.current ? ' (now)' : ''), m.title, l.length, count(l, 'not started'), count(l, 'briefed'), count(l, 'reported'), count(l, 'landed'), m.tokens.split(' (')[0], m.weeks.split(/ \(|, /)[0]];
  });
  return table(['Milestone', 'What it proves', 'Rows', 'Not started', 'Briefed', 'Reported', 'Landed', 'Tokens (path)', 'Weeks (path)'], body);
}

function ownerSummary(ms) {
  const l = orbList(ms);
  return table(['Owner', 'Rows', 'Not started', 'Briefed', 'Reported', 'Landed'], owners(l).map(o => {
    const q = l.filter(x => x.r.owner === o);
    return [o, q.length, count(q, 'not started'), count(q, 'briefed'), count(q, 'reported'), count(q, 'landed')];
  }));
}

function rowsByOwner(ms, full) {
  const l = full ? rows[ms] : orbList(ms);
  const out = [];
  for (const o of owners(l)) {
    const q = l.filter(x => x.r.owner === o);
    if (full) {
      out.push(`**${o}** (${q.length})\n\n` + table(['Row', 'Size', 'Severity', 'Window', 'Needs', 'Status', 'Evidence', 'What it is'],
        q.map(x => [x.id + (x.r.alpha === 'nice' ? ' (nice)' : '') + (heldRows(x.id) ? ' †' : ''), x.r.cost, x.r.severity, windowOf.get(x.id) || '', (x.r.needs || []).join(' '), x.status, evidence(x), short(x.r.gap, 170)])));
    } else if (ms === 'A1') {
      out.push(`**${o}** (${q.length})\n\n` + table(['Row', 'What it is', 'Size', 'Window', 'Status', 'Evidence'],
        q.map(x => [x.id + (x.r.alpha === 'nice' ? ' (nice)' : ''), orbRowText(x), x.r.cost, windowOf.get(x.id) || '', x.status, evidence(x)])));
    } else {
      out.push(`- **${o}** (${q.length}): ${q.map(x => x.id + (x.status !== 'not started' ? ` [${x.status}]` : '')).join(', ')}`);
    }
  }
  return out.join(ms === 'A1' || full ? '\n\n' : '\n');
}

function decisionsFor(msId) {
  const l = DECISIONS.filter(d => d[3] === msId && !['answered', 'accepted', 'direction'].includes(status.decisions[d[0]].status));
  if (!l.length) return '_None open that this milestone needs._';
  return l.map(d => `- **${d[0]}.** ${d[1]} (needed before ${d[2]}) — ${status.decisions[d[0]].status}${status.decisions[d[0]].words ? ': ' + status.decisions[d[0]].words : ''}`).join('\n');
}

function milestoneSection(m) {
  const l = rows[m.id];
  const held = l.length - orbList(m.id).length;
  const parts = [];
  parts.push(`## ${m.id}. ${m.title}${m.id === status.current ? ' — the milestone the project is in' : ''}`);
  parts.push(`**Goal.** ${m.goal}\n\n**Why here.** ${m.why}\n\n**What Orb can play.** ${m.orbPlays}`);
  parts.push(`**Size (the path's estimate).** ${m.tokens}; ${m.weeks} weeks. **Rows:** ${l.length}: ${count(l, 'not started')} not started, ${count(l, 'briefed')} briefed, ${count(l, 'reported')} reported, ${count(l, 'landed')} landed.`);
  parts.push(`**Golden window.** ${m.window.name}${m.window.rows.length ? ` (${m.window.rows.length} rows: ${m.window.rows.join(', ')})` : ''}. ${m.window.note}`);
  parts.push(`**Directors active.** ${m.directors}`);
  parts.push(`**Exit lines**\n\n` + (m.exit.length ? table(['Line', 'Kind', 'What passes'], m.exit) : '_None._'));
  parts.push(`**Decisions still open that this milestone needs**\n\n${decisionsFor(m.id)}`);
  if (l.length) parts.push(`**Rows by owner**${m.id === 'A1' ? '' : ' (status in brackets once past "not started"; the full table has each row\'s text)'}\n\n${m.id === 'A1' ? ownerSummary(m.id) + '\n\n' : ''}${rowsByOwner(m.id, false)}${held ? `\n\n_${held} more row${held > 1 ? 's' : ''} of this milestone ${held > 1 ? 'are' : 'is'} listed only on the full table (milestone-rows.md); ${held > 1 ? 'they carry' : 'it carries'} no question for Orb._` : ''}${addedSection(m.id)}`);
  else parts.push('**Rows.** None: no register row closes here. The milestone is verification and people.');
  return parts.join('\n\n');
}

function addedSection(ms) {
  const a = (status.added || []).filter(x => x.milestone === ms);
  if (!a.length) return '';
  return `\n\n**Added since the path, outside the register** (${a.length} items; they have no register row, so they are listed apart and not counted in the ${rows[ms].length} rows above). They land as window GW1c, after GW1b.\n\n` +
    table(['Item', 'Owner', 'What', 'Status', 'Evidence', 'Where it came from'], a.map(x => [x.id, x.owner, x.what, x.status, x.ref, x.source]));
}

function switchSection() {
  const s = status.switchRows;
  const last = s[s.length - 1];
  const next = new Date(last.date + 'T00:00:00Z');
  next.setUTCDate(next.getUTCDate() + status.switchRowsEveryDays);
  return `**Switch rows still differing between main and the 9 November build: ${last.count} of ${last.of}** (${last.date}; ${last.note}). The Executive Producer reports this count every ${status.switchRowsEveryDays} days; the next is due ${next.toISOString().slice(0, 10)}. It must reach 0 for A-CODE-01 to close.\n\n` +
    table(['Date', 'Still differing', 'Of', 'Note'], s.map(x => [x.date, x.count, x.of, x.note]));
}

function backupSection() {
  const b = status.backup;
  return `## Orb's kept builds: the second copy\n\nThe builds, play files, reports and clips Orb keeps are ${b.size}; they are the only copies of what Orb played and the only way back to an earlier build, so a disk fault would lose them. Where the second copy lives: ${b.answered ? 'as Orb answered.' : 'not decided. The recommendation is ' + b.recommendation + '.'} Last copy made: ${b.lastCopy}. (Row A-TOOLS-09, Tools' row; this paragraph is updated when Orb answers and each time a copy is made.)`;
}

// ---- milestones.md (the page Orb opens) ----
const decRows = DECISIONS.map(d => [d[0], d[1], d[2], status.decisions[d[0]].status, status.decisions[d[0]].words]);
const a1 = rows.A1;
const notesText = (status.notes || []).map(n => '\n\n**Note.** ' + n).join('');
const orbPage = [
  `# Milestone tracker`,
  `_Live page. Last built from status.json for **${status.asOf}**. It is rebuilt every two days when the Executive Producer sends status (tools/build-tracker.mjs; nothing on this page is typed by hand except the words in status.json). Production Operations keeps it; the Executive Producer is the only source of status._`,
  `**Nothing on this page decides anything.** The path to Alpha (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md) is the audit's recommendation. Orb accepted the first group of the path's decisions on 2026-11-13 (table below); every other milestone, size and week range stays a recommendation until Orb approves it.`,
  `## Where the project is\n\n**Milestone A1, "${MILESTONES[0].title}".** ${a1.length} rows: ${count(a1, 'not started')} not started, ${count(a1, 'briefed')} briefed, ${count(a1, 'reported')} reported, ${count(a1, 'landed')} landed.\n\n**Budget.** ${status.budget.line}\n\n**Waves.** ${status.waves.wave1} ${status.waves.wave2}${notesText}\n\n${summaryTable()}\n\n${switchSection()}`,
  `## What could move the date\n\nThe three risks the path names (full list, owners, early signs and guards in risk-register.md):\n\n1. **Main cannot simply be made into the game Orb plays.** 69 of 87 data rows differ, patches that exist only in a preview tool and checks that have never run on the configuration Orb plays. If this takes three weeks instead of one and a half, everything moves by the difference. Watch: the count above, every two days.\n2. **The Steam Deck says no to something** (a graphics driver, a frame rate under 30, text too small, controls not arriving as a pad). Watch: spike S5 in A1, the first real session in A2.\n3. **The fight rework is a class bigger than estimated** (the beam, the signature inputs, the stamina loop and the gravity well all change the same code). Watch: spikes S1 and S2 in A1 and the stop rule at A3's midpoint.\n\nAlso watched: the wait for people (two friends, twice), the weekly token limit, one Executive Producer session holding the project's state, and the year-end holidays, which fall inside every range and are not counted.`,
  `## Orb's decisions, in the path's numbering\n\n${table(['#', 'Decision', 'Needed before', 'Status', 'Orb\'s words'], decRows.map(r => [r[0], r[1], r[2], r[3], r[4] || '(not answered yet)']))}`,
  `## Words used on this page\n\n${GLOSSARY.map(g => `- **${g[0]}:** ${g[1]}.`).join('\n')}\n\n**Status words.** _not started_: no brief has gone out. _briefed_: the director has the brief (or the Executive Producer is doing it). _reported_: the director has reported and the work is parked or the paper written, not yet on main. _landed_: on main, with the commit id shown. A status can be traced to a commit or a report: the Evidence column says which.`,
  backupSection(),
  `# The milestones`,
  ...MILESTONES.map(milestoneSection),
  `---\n_Source files: 03-gap-register.json and 04-milestone-rows.json in docs/ep/alpha/audit-2026-11-13/, status.json and tools/ here. The full table, every row of every milestone with what each needs, is milestone-rows.md. Method and the checks run: runs/ (the newest folder)._`,
].join('\n\n') + '\n';

// ---- milestone-rows.md (the full table) ----
const fullPage = [
  `# Milestone rows: the full table`,
  `_Built from status.json for ${status.asOf} by tools/build-tracker.mjs, with every row of milestones A1 to A6 (${seen.size} rows). This is the Executive Producer's table; milestones.md is the page for Orb and leaves out the rows marked †, which carry no question for Orb. Status words: not started, briefed, reported, landed (a landed row shows its commit). "Needs" lists the rows this row waits for. "Window" is the golden window the row lands in. Size: S about 0.25M tokens, M about 1.2M, L about 4M, XL about 8M (the register's classes)._`,
  ...MILESTONES.map(m => `## ${m.id}. ${m.title} — ${rows[m.id].length} rows\n\n${rows[m.id].length ? rowsByOwner(m.id, true) : '_No register row closes here._'}${addedSection(m.id)}`),
].join('\n\n') + '\n';

// ---- backlog-draft.md (row A-PROCESS-02, a draft for the EP): one table keyed by register id ----
const whereOf = new Map();
for (const m of Object.keys(placed)) for (const id of placed[m]) whereOf.set(id, m);
const whereLabel = r => whereOf.get(r.id) || (r.alpha === 'after' ? 'after Alpha' : 'pool');
const statusOf = r => whereOf.has(r.id) ? rowInfo(r.id, whereOf.get(r.id)).status : 'not placed';
const WORDER ={ A1: 1, A2: 2, A3: 3, A4: 4, A5: 5, A6: 6, pool: 7, 'after Alpha': 8 };
const cdIds = r => ((r.source_cd || '').toString().match(/CD-?\d+/g) || []).map(x => 'CD-' + x.replace(/\D/g, '').padStart(2, '0'));
const cdText = fs.readFileSync(path.resolve(prod, '../ep/corrective-plan-2026-11-07.md'), 'utf8');
const cds = [];
for (const line of cdText.split(/\r?\n/)) {
  const t = line.trim();
  if (!t.startsWith('|')) continue;
  const c = t.replace(/^\|/, '').replace(/\|$/, '').split('|').map(x => x.trim());
  const m = c.length === 6 && c[0].match(/^(\d\d) (.+)$/);
  if (m) cds.push({ id: 'CD-' + m[1], title: m[2].trim(), wave: c[1], owner: c[2], closing: c[5] });
}
const cdRows = id => reg.filter(r => cdIds(r).includes(id)).map(r => r.id);
const closedByEP = new Set(Object.keys(status.cdClosed || {}));
const closingKind = (c, id) => closedByEP.has(id) ? 'closed (has a commit or record)' : !c ? 'no closing entry' : /^open/i.test(c) ? 'open' : /owed|waits|after quiet/i.test(c) ? 'entry, with something still owed' : 'closed (has a commit or record)';
const backlogRows = [...reg].sort((a, b) => WORDER[whereLabel(a)] - WORDER[whereLabel(b)] || a.id.localeCompare(b.id));
const apart = cds.filter(c => closingKind(c.closing, c.id) !== 'closed (has a commit or record)' && cdRows(c.id).length === 0);
const pendingDirs = fs.readdirSync(path.resolve(prod, '..')).filter(d => fs.existsSync(path.resolve(prod, '..', d, 'pending')));
const countFiles = p => fs.readdirSync(p, { withFileTypes: true }).reduce((n, e) => n + (e.isDirectory() ? countFiles(path.join(p, e.name)) : 1), 0);
const pendingLine = pendingDirs.map(d => d + ' ' + countFiles(path.resolve(prod, '..', d, 'pending'))).join(', ') + ' (' + pendingDirs.reduce((n, d) => n + countFiles(path.resolve(prod, '..', d, 'pending')), 0) + ' files in all)';
const backlogPage = [
  `# Backlog (draft): one table keyed by register id`,
  `_Draft for the Executive Producer, who owns and commits it (row A-PROCESS-02; Production Operations drafts). Built for ${status.asOf} by tools/build-tracker.mjs from the audit's register (${reg.length} rows), the tracker's status and the corrective plan of 2026-11-07. Rows marked † are held to the EP's tables (see milestones.md). Status words as in the tracker; "not placed" is a row outside the milestones (the nice-to-have pool, or after Alpha)._`,
  `**What is still missing from this draft.** The sources the EP passes: the EP's owed-by-owner list, QA's bug list (the register notes it holds 1 of the 52 problems Orb reported from 2026-11-01 to 2026-11-09: row A-QA-03) and the list of parked folders (494 uncommitted paths under pending/). Anything in those that has no register row goes in the last table, with a source and an owner; nothing is dropped.`,
  `## A. The register, by milestone\n\n` + table(['Id', 'Where', 'Owner', 'Size', 'Severity', 'Status', 'Corrective item', 'What it is'],
    backlogRows.map(r => [r.id + (heldRows(r.id) ? ' †' : ''), whereLabel(r), r.owner, r.cost, r.severity, statusOf(r), cdIds(r).join(' '), (heldRows(r.id) || HELD.test(r.gap)) ? '(see the full table)' : short(r.gap, 110)])),
  `## B. The corrective plan of 2026-11-07, row by row (27 items)\n\nThe plan's own closing column, read as written; "register row" is the row the audit made from that item (the register's source field). Items titled with a held word show a neutral title.\n\n` + table(['CD', 'What it is', 'Plan\'s closing column', 'Register row(s)'],
    cds.map(c => [c.id, HELD.test(c.title) ? '(see the corrective plan)' : short(c.title, 90), closingKind(c.closing, c.id), cdRows(c.id).join(' ') || 'none'])),
  `## C. Items with no register row (listed apart)\n\n` + (apart.length
    ? `From the corrective plan: ${apart.map(c => c.id).join(', ')} (no closing entry or still owed, and no register row). Each needs an owner and a horizon from the EP, or a closing commit.\n\n` + table(['Source', 'Item', 'Owner', 'Horizon', 'Notes'], apart.map(c => ['corrective plan ' + c.id, HELD.test(c.title) ? '(see the corrective plan)' : short(c.title, 90), c.owner, '', closingKind(c.closing, c.id)]))
    : `From the corrective plan: none. Every item without a closing entry, or with an open one, has a register row.\n\n`) +
    `

**From the EP's owed list:** the EP's list is in memory and summarised in docs/ep/sprints/A1-sprint.md; items on it with a register id are already rows in table A. Anything without one is added here by the EP.

**From QA's bug list** (qa/known-bugs.md; the register's row A-QA-03 says it holds 1 of the 52 problems Orb reported from 2026-11-01 to 2026-11-09, so it is not the whole bug list). Entries: KB-001 to KB-006 (the pinned prototype, open as coded, no release blocked) and GB-001 to GB-009. Not closed: GB-003 camera jolt on a knock-away (with Camera), GB-004 a design call, GB-005 mountain tumbles (with World), GB-007 rocks round a fast fighter (not reproduced), GB-009 the blaster's balance. Fixed but not re-verified in play: GB-002, GB-006. None has a register row; they are listed apart until QA's rows A-QA-03 and A-QA-07 re-read the list against the played build.

**From the parked folders** (docs/*/pending, file counts read ${status.asOf}): ${pendingLine}. A parked folder is not proof of unlanded work (grep main first); the EP's A-PROCESS-03 sorts them by owner.`,
].join('\n\n') + '\n';

// ---- checks on the outputs ----
check('the backlog lists every register row exactly once', backlogRows.length === reg.length && new Set(backlogRows.map(r => r.id)).size === reg.length && reg.every(r => (backlogPage.match(new RegExp(`^\\| ${r.id}[ |]`, 'gm')) || []).length === 1), '');
check('the corrective plan has 27 rows, parsed', cds.length === 27, `parsed ${cds.length}`);
check('every corrective item without a closing entry or still open has a register row', cds.every(c => closingKind(c.closing, c.id) === 'closed (has a commit or record)' || cdRows(c.id).length > 0 || apart.includes(c)), '');
check('no held word appears in the backlog', !HELD.test(backlogPage), (backlogPage.match(HELD) || [''])[0]);
const idsIn = (text, list) => list.map(x => (text.match(new RegExp(`^\\| ${x.id}[ |]`, 'gm')) || []).length);
check('every A1 row appears exactly once in the full table', idsIn(fullPage, rows.A1).every(n => n === 1), rows.A1.filter((x, i) => idsIn(fullPage, rows.A1)[i] !== 1).map(x => x.id).join(' '));
check('every placed row appears exactly once in the full table', Object.values(rows).flat().every(x => idsIn(fullPage, [x])[0] === 1), '');
check('every A1 row appears exactly once on the page for Orb', idsIn(orbPage, rows.A1).every(n => n === 1), '');
check('Orb\'s page lists every row except the held ones (counts add up)', MILESTONES.every(m => orbList(m.id).length + rows[m.id].filter(x => heldRows(x.id)).length === rows[m.id].length), '');
check('no held word appears on the page for Orb', !HELD.test(orbPage), (orbPage.match(HELD) || [''])[0]);
check('the full table marks every held row', rows.A2.filter(x => heldRows(x.id)).every(x => new RegExp(`^\\| ${x.id}[^|]*†`, 'm').test(fullPage)), '');

// ---- write and report ----
if (!checkOnly) {
  fs.writeFileSync(path.join(prod, 'milestones.md'), orbPage);
  fs.writeFileSync(path.join(prod, 'milestone-rows.md'), fullPage);
  fs.writeFileSync(path.join(prod, 'backlog-draft.md'), backlogPage);
}
const failed = checks.filter(c => !c.ok);
console.log(`build-tracker: asOf ${status.asOf}; rows by milestone: ${Object.entries(rows).map(([k, v]) => `${k} ${v.length}`).join(', ')}; ${checkOnly ? 'check only, nothing written' : 'wrote milestones.md, milestone-rows.md and backlog-draft.md'}`);
for (const c of checks) console.log(`${c.ok ? 'PASS' : 'FAIL'}  ${c.name}${c.ok || !c.detail ? '' : '  -> ' + c.detail}`);
console.log(`${checks.length - failed.length} of ${checks.length} checks pass`);
process.exit(failed.length ? 1 : 0);

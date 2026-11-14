// Checks the hand-written pages in docs/production/ against the path to Alpha (acceptance criteria 1, 2 and 5 of
// Production Operations' A1 brief). Run: node docs/production/tools/check-pages.mjs   (exit code 1 on a failure).
// build-tracker.mjs checks the generated pages (criteria 3 and 4). No dependencies.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const prod = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = f => fs.readFileSync(path.join(prod, f), 'utf8');
const results = [];
const check = (name, ok, detail = '') => results.push({ name, ok, detail });
const cells = line => line.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map(x => x.trim());
const tableRows = (text, startsWith) => text.split(/\r?\n/).filter(l => l.startsWith('| ' + startsWith));

// ---- change-control.md (criterion 1) ----
const cc = read('change-control.md');
const steps = [...cc.matchAll(/^([1-6])\. \*\*/gm)].map(m => m[1]);
check('change-control: the six steps of the push are numbered 1 to 6', steps.slice(0, 6).join('') === '123456', steps.join(''));
for (const [label, re] of [['the rule for after A4', /## After A4/], ['the rule for after the freeze', /## After the freeze/], ['the standing exception', /## The standing exception/], ['the spike rule', /Each spike's page counts as a change request/], ['"now" needs all three conditions', /only if all three of these hold/], ['the playbook pointer is proposed, not made', /Proposed pointer for the playbook/]])
  check(`change-control: has ${label}`, re.test(cc));
check('change-control: points to the ideas log and the special-moves note', /ideas-log\.md/.test(cc) && /docs\/ep\/ideas\/special-moves\.md/.test(cc));

// ---- ideas-log.md (criterion 2) ----
const il = read('ideas-log.md');
const first = il.split('## B.')[0];
const seven = tableRows(first, 'ID-');
check('ideas-log: section A has exactly the path\'s seven first entries', seven.length === 7, `found ${seven.length}`);
const topics = [/LB guard and then timing hitting the energy RB/, /flinging debris/, /mid-combat event/, /Slipstream/, /right-stick flick/, /Wind-Up Throw/, /synergy abilities/];
check('ideas-log: the seven entries are the absorb, debris, power-up contest, slipstream, flick, wind-up throw and co-op synergy, in the path\'s order', topics.every((t, i) => t.test(seven[i] || '')), '');
check('ideas-log: every entry has date, who, words, EP\'s line, size, fingerprint and Orb\'s answer (8 cells)', tableRows(il, 'ID-').every(r => cells(r).length === 8) || tableRows(il, 'ID-').filter(r => cells(r).length !== 8 && cells(r).length !== 5).length === 0, '');
const lines = seven.map(r => cells(r)[4]);
check('ideas-log: the absorb\'s line is the path\'s (next milestone only if the stamina loop\'s first measurement is in, else after Alpha)', /next milestone, only if the stamina loop's first measurement is in; otherwise after Alpha/.test(lines[0]), lines[0]);
check('ideas-log: the other six lines are "After Alpha", as the path says', lines.slice(1).every(l => /^After Alpha/.test(l)), '');
check('ideas-log: Orb\'s answer is "Not asked yet" on every entry (nothing answered by the log)', seven.every(r => /Not asked yet/.test(cells(r)[7])), '');

// ---- risk-register.md (criterion 5) ----
const rr = read('risk-register.md');
const risks = tableRows(rr, 'R-');
check('risk-register: 24 live risks', risks.length === 24, `found ${risks.length}`);
const bad = risks.filter(r => { const c = cells(r); return c.length !== 7 || !c[3] || !c[4] || !c[5] || !c[6]; }).map(r => cells(r)[0]);
check('risk-register: every risk has an owner, an early sign, a guard and a standing', bad.length === 0, bad.join(' '));
const owners = risks.map(r => cells(r)[3]);
check('risk-register: every owner names a director or the EP', owners.every(o => /EP|Tools|Simulation|Camera|Encounter|Game Design|Performance|Netcode|Legal|Art|QA|Rendering/.test(o)), owners.join(' / '));
for (const [label, re] of [
  ['risk 1 of the path (main cannot be made the played game)', /Main cannot simply be made/],
  ['risk 2 of the path (the Steam Deck)', /Steam Deck says no/],
  ['risk 3 of the path (the fight rework)', /fight rework is a class bigger/],
  ['watched: the outside-tester gate list on the globe ground', /outside-tester gate list does not go green on the globe ground/],
  ['watched: the horde on a Deck', /The horde on a Deck/],
  ['watched: the wait for people', /The wait for people/],
  ['watched: the year-end holidays', /year-end holidays/],
  ['added: outside testers', /\*\*Outside testers:/],
  ['added: LAN', /\*\*LAN:/],
  ['added: the weekly token limit', /weekly token limit/],
  ['added: the single Executive Producer session', /One Executive Producer session holds/],
  ['happened: CI broken for 38 pushes', /38 pushes/],
]) check(`risk-register: has ${label}`, re.test(rr));
const old = tableRows(rr.split('## 5.')[1] || '', '').filter(r => /^\| \d+ \|/.test(r));
check('risk-register: all 11 old rows are kept with a fate, a date and a reason', old.length === 11 && old.every(r => cells(r).length === 5 && cells(r)[3] && cells(r)[4]), `found ${old.length}`);
const happened = tableRows(rr, 'H-');
check('risk-register: happened risks each say what changed', happened.length >= 5 && happened.every(r => cells(r).length === 3 && cells(r)[2].length > 20), `found ${happened.length}`);
check('risk-register: the old rows about parked mechanics (4 and 7) are closed with a date', /\| 4 \|[^\n]*\*\*Closed\*\* \| 2026-11-13/.test(rr) && /\| 7 \|[^\n]*\*\*Closed\*\* \| 2026-11-13/.test(rr));

// ---- all pages: held words and personal details ----
const HELD = /flash|photosens|seizure|strobe|epilep|wcag/i;
for (const f of ['change-control.md', 'ideas-log.md', 'risk-register.md', 'token-record.md', 'done-tests.md'])
  check(`${f}: no held word`, !HELD.test(read(f)), (read(f).match(HELD) || [''])[0]);

const failed = results.filter(r => !r.ok);
for (const r of results) console.log(`${r.ok ? 'PASS' : 'FAIL'}  ${r.name}${r.ok || !r.detail ? '' : '  -> ' + r.detail}`);
console.log(`${results.length - failed.length} of ${results.length} checks pass`);
process.exit(failed.length ? 1 : 0);

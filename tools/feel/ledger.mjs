// The refusal ledger (docs/tools/feel.md): from a saved match of Orb's, every press the game did not honour, with when and why.
//   node tools/feel/ledger.mjs <saved match.json> [--tree <tree folder>] [--all] [--json out.json] [--out ledger.txt] [--godot exe]
// The match is replayed on the tree it was recorded on and slot 0 (the pad) is read: each press of slot 0 (light, heavy, sig, special, dodge, guard, a right-stick start, transform, context, power) is looked at for 12 ticks after.
//   refused  the game said no and gave a reason (press_ack refused / double / zip / lapsed / stunned / chase_no_ki / chase_late, stick_refused with its reason, grapple_refused, driver_refused, answer_refused, mine_refused) and nothing else came of it
//   partly   a refusal, and something else happened too (a blow, a cue of his own)
//   silent   nothing at all answered the press: no cue, no blow, no refusal. These are the ones that felt like the game ignored him.
// "silent" is a read of the sim's cues, not a proof: a press that did its work without a cue of its own shows as silent. Check each silent row before changing a rule for it.
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { readMatch, treeFor, workCopy, runGd } from './lib.mjs';

export const mmss = (tick) => { const s = tick / 60; const m = Math.floor(s / 60); return `${m}:${(s - m * 60).toFixed(1).padStart(4, '0')}`; };

export async function ledger({ match, tree, slot, godot, limitMs }) {
  const { doc } = readMatch(match);
  const base = treeFor(doc, tree);
  const work = workCopy(base);
  const r = await runGd(work, [resolve(match), '--mode=ledger', ...(slot !== undefined ? [`--slot=${slot}`] : [])], { godot, limitMs });
  if (!r.line) throw new Error('the replay gave no result:\n' + r.text.split(/\r?\n/).slice(-12).join('\n'));
  return { match, tree: base, ...r.line };
}

/** Counts by press and verdict, and by reason. */
export function summarise(res) {
  const byPress = {}, byReason = {};
  for (const p of res.presses) {
    const b = (byPress[p.press] ||= { total: 0, honoured: 0, refused: 0, partly: 0, silent: 0 });
    b.total++; b[p.verdict]++;
    for (const why of p.reasons) byReason[why] = (byReason[why] || 0) + 1;
  }
  const total = res.presses.length;
  const not = res.presses.filter((p) => p.verdict !== 'honoured').length;
  // Encounter's press-answers (power_start, power_burst, the transform event, press_refused not_ready): the presses answered ONLY by them were silent before those cues existed
  const paOnly = res.presses.filter((p) => p.paOnly && p.verdict === 'honoured').length;
  const notReady = res.presses.filter((p) => p.notReady).length;
  return { total, notHonoured: not, byPress, byReason, paOnly, notReady, notHonouredOldRule: not + paOnly };
}

export function text(res, { all = false } = {}) {
  const s = summarise(res);
  const out = [];
  out.push(`REFUSAL LEDGER  ${res.match}`);
  out.push(`tree ${res.tree}; the pad is slot ${res.slot}`);
  out.push(`recorded match: ${!res.recorded.checked ? 'cut short (no final hash to compare)' : res.recorded.exact ? 'reproduced exactly' : 'NOT reproduced on this tree: the rows are the replay on this tree'}; ${res.ticks} ticks (${mmss(res.ticks)})`);
  out.push(`${s.total} presses of the pad; ${s.notHonoured} not honoured (${s.total ? Math.round((100 * s.notHonoured) / s.total) : 0}%)`);
  if (res.presses.length && typeof res.presses[0].paOnly === 'boolean') out.push(`counting rule (2026-11-08): power_start, power_burst, the transform event and press_refused not_ready count as answers to a power press or a transform (Encounter press-answers). ${s.paOnly} presses were answered ONLY by power_start, power_burst or a transform (honoured); ${s.notReady} presses got not_ready (a refusal with its reason, not silent). The build the 15% figure was read on (e80b8e3d) had none of these cues, so for a like-for-like reading take those ${s.paOnly} as not answered: ${s.notHonouredOldRule} not honoured (${s.total ? Math.round((100 * s.notHonouredOldRule) / s.total) : 0}%) under the old rule, ${s.notHonoured} (${s.total ? Math.round((100 * s.notHonoured) / s.total) : 0}%) with them`);
  if (typeof res.merged === 'number') out.push(`counting rule (2026-11-07): a press of one kind on consecutive ticks is ONE press (a hit-stop offers it again each tick): ${res.merged} such repeats were not counted as presses; a guard held up or a dodge open reads as honoured`);
  out.push('');
  out.push('by press:');
  for (const [k, v] of Object.entries(s.byPress)) out.push(`  ${k.padEnd(11)} ${String(v.total).padStart(4)} presses: ${v.honoured} honoured, ${v.refused} refused, ${v.partly} partly, ${v.silent} silent`);
  out.push('');
  out.push('by reason:');
  for (const [k, v] of Object.entries(s.byReason).sort((a, b) => b[1] - a[1])) out.push(`  ${String(v).padStart(4)}  ${k}`);
  out.push('');
  out.push(all ? 'every press:' : 'the presses not honoured (when, press, what it was, why):');
  for (const p of res.presses) {
    if (!all && p.verdict === 'honoured') continue;
    const rs = p.rs && p.rs.length ? ` rs dir ${p.rs[0]} level ${p.rs[1]}` : '';
    const why = p.reasons.length ? p.reasons.join(', ') : p.verdict === 'silent' ? 'no answer at all' : (p.cues || []).join(', ');
    out.push(`  ${mmss(p.t)}  t${String(p.t).padEnd(6)} ${p.press.padEnd(10)} ${p.verdict.padEnd(8)} in ${p.state}, ki ${p.ki}${rs}: ${why}`);
  }
  return out.join('\n');
}

async function main() {
  const argv = process.argv.slice(2);
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const flags = new Set(['--slot', '--tree', '--json', '--out', '--godot']);
  const match = argv.find((a, i) => !a.startsWith('--') && !flags.has(argv[i - 1]));
  if (!match) { console.error('usage: node tools/feel/ledger.mjs <saved match.json> [--tree <folder>] [--all] [--json out.json] [--out ledger.txt]'); process.exit(2); }
  const res = await ledger({ match, tree: opt('--tree'), slot: opt('--slot') !== undefined ? Number(opt('--slot')) : undefined, godot: opt('--godot') });
  const t = text(res, { all: argv.includes('--all') });
  console.log(t);
  if (opt('--json')) writeFileSync(opt('--json'), JSON.stringify(res, null, 1));
  if (opt('--out')) writeFileSync(opt('--out'), t + '\n');
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch((e) => { console.error('[ledger] FAILED: ' + e.message); process.exit(1); });

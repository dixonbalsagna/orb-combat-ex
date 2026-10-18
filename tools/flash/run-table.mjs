// The table of a full-set run against Legal's addendum 10 (RL-156): every clip and nightly-style seed, both modes, with the primary reading, the area-15% and 2 s-memory readings, red, the worst
// second and who caused it (the margins table's sources), and a verdict: OK (3 or under on the primary, red 0), RED (red above 0), OVER 3 (a fail, not a waiver). Used by tools/flash/interim-run.sh for a
// rehearsal (NO_RECORD=1) and by hand:
//   node tools/flash/run-table.mjs --set <clips summary.json> [--second <clips_second summary.json>] [--extra <clips_extra summary.json>] [--margins <margins.json>[,<more.json>]] [--md <out.md>]
// The worse of a clip and its second capture counts as the clip's primary. Prints the markdown; exit 1 when any row is not OK.
import { readFileSync, writeFileSync } from 'node:fs';

const argv = process.argv.slice(2);
const opt = (n) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
const rd = (p) => { if (!p) return []; try { return JSON.parse(readFileSync(p, 'utf8')); } catch { return []; } };

export function rowsOf(set, second, extra, margins) {
  const sec = new Map(second.filter((e) => !e.error && e.result).map((e) => [e.id, e]));
  const mar = new Map(margins.map((m) => [m.id, m]));
  const out = [];
  for (const [group, list] of [['set', set], ['seed', extra]]) {
    for (const e of list) {
      if (e.error || !e.result) { out.push({ id: e.id, group, verdict: 'NO RESULT', note: e.error || 'no result' }); continue; }
      const g = e.result.general, c = e.result.combined, s = sec.get(e.id);
      const primary = Math.max(g.flashes, s ? s.result.general.flashes : 0);
      const red = e.result.red.flashes;
      const m = mar.get(e.id);
      const verdict = primary > 3 ? 'OVER 3' : red > 0 ? 'RED' : 'OK';
      const why = [];
      if (c.lower > 3 || c.stricter > 3) why.push(`other readings ${c.lower}/${c.stricter}`);
      out.push({
        id: e.id, group, primary, second: s ? s.result.general.flashes : null, lower: c.lower, stricter: c.stricter, red, verdict, combined: c.verdict, at: g.atTick,
        sources: m ? Object.entries(m.sources || {}).map(([k, v]) => `${k} ${v}`).join(', ') : '', mode: e.mode ? (e.mode.reduce_flashing ? 'on' : 'off') : '?', fps: e.guard ? e.guard.framesPerSecond : null, note: why.join('; '),
      });
    }
  }
  return out.sort((a, b) => (a.group === b.group ? a.id.localeCompare(b.id) : a.group === 'set' ? -1 : 1));
}

export function markdown(rows) {
  const l = ['| clip | primary | area-15% | 2 s | red | Reduce flashing (read back) | worst second at | sources | verdict (addendum 10) | combined rule |', '|---|---|---|---|---|---|---|---|---|---|'];
  for (const r of rows) {
    if (!('primary' in r)) { l.push(`| ${r.id} | | | | | | | | ${r.verdict}: ${r.note} | |`); continue; }
    l.push(`| ${r.id}${r.group === 'seed' ? ' (nightly-style)' : ''} | ${r.primary}${r.second != null ? ` (second ${r.second})` : ''} | ${r.lower} | ${r.stricter} | ${r.red} | ${r.mode} | ${r.at} | ${r.sources} | ${r.verdict} | ${r.combined} |`);
  }
  const bad = rows.filter((r) => r.verdict !== 'OK');
  l.push('', `${rows.length} clips; ${rows.length - bad.length} OK; not OK: ${bad.length ? bad.map((r) => `${r.id} ${r.verdict}${'primary' in r ? ` (${r.primary})` : ''}`).join(', ') : 'none'}.`);
  return l.join('\n');
}

if (process.argv[1] && process.argv[1].endsWith('run-table.mjs')) {
  const rows = rowsOf(rd(opt('--set')), rd(opt('--second')), rd(opt('--extra')), (opt('--margins') || '').split(',').filter(Boolean).flatMap(rd));
  const md = markdown(rows);
  console.log(md);
  if (opt('--md')) writeFileSync(opt('--md'), md + '\n');
  process.exit(rows.some((r) => r.verdict !== 'OK') ? 1 : 0);
}

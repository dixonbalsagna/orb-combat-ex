// Keeping parts.json's copy of Legal's rows in step with docs/legal/movegen-banned.json (README section 3 of
// docs/combat/pending/movegen). The generator's --check fails when a row of a mirrored group is missing or differs; this
// brings the copy up to date without touching what Combat added to a row (its `kind`, filters and numbers).
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { dumps, eq, get, has } from './py.mjs';

/**
 * Returns { added, changed, text }: the rows added (a new row carries no `kind`, so it refuses nothing and is a condition for
 * its owner until Combat gives it a machine form), the rows whose words changed (their machine form needs a look), and the new
 * parts.json text (Python's indent 1, as the file is kept).
 */
export function mergeLegal(root, dir) {
  const partsPath = join(dir, 'parts.json');
  const parts = JSON.parse(readFileSync(partsPath, 'utf8'));
  const theirs = JSON.parse(readFileSync(join(root, 'docs', 'legal', 'movegen-banned.json'), 'utf8'));
  const lg = parts.legal;
  const added = [];
  const changed = [];
  for (const [group, rows] of Object.entries(theirs)) {
    if (['schema', '_about', 'banned', 'bannedSequences'].includes(group) || !has(get(lg, 'mirrored', []), group)) continue;
    if (!Array.isArray(rows)) {
      if (!eq(get(lg, group), rows)) {
        lg[group] = JSON.parse(JSON.stringify(rows));
        changed.push(group);
      }
      continue;
    }
    const mine = get(lg, group, []);
    const byId = new Map(mine.map((r) => [r.id, r]));
    for (const r of rows) {
      const m = byId.get(r.id);
      if (!m) {
        mine.push(JSON.parse(JSON.stringify(r)));
        added.push(`${r.id} (${group})`);
      } else if (!eq([get(m, 'rule'), get(m, 'why')], [get(r, 'rule'), get(r, 'why')])) {
        m.rule = r.rule;
        m.why = r.why;
        changed.push(`${r.id} (${group})`);
      }
    }
    lg[group] = mine;
  }
  return { added, changed, text: dumps(parts, { indent: 1, ensureAscii: false }) + '\n', write: (text) => writeFileSync(partsPath, text, 'utf8') };
}

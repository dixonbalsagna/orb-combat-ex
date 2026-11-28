// The shipped copy of the shader credits for the in-game licences screen (UI & UX, 2026-11-28; Legal RL-289, RL-295; docs/ui/third-party-notices.md).
// The source of truth is Tools' list, tools/third-party.json, and its words (tools/third-party.mjs noticeSection: the same words NOTICES.txt carries). tools/ is not packed into the game,
// so this writes ui/notices/third_party.json, which the game ships. A row is shown while it has a license and a shipped file still holds its code; a row with no known terms has no notice.
//   node ui/tools/third_party_notices.mjs --write    write the file
//   node ui/tools/third_party_notices.mjs --check    fail if the file is not what --write would make
// Run from the repo root.
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { inTree, loadSnippets, noticeSection } from '../../tools/third-party.mjs';

const ROOT = process.cwd();
const OUT = resolve(ROOT, 'ui/notices/third_party.json');

export function build() {
  const rows = loadSnippets(resolve(ROOT, 'tools/third-party.json'));
  const found = inTree(ROOT, rows);
  const held = rows.filter((r) => r.license && found.get(r.id).length > 0);
  // noticeSection's first line is its heading in capitals; the screen has its own heading.
  const text = noticeSection(held).split('\n').slice(1).join('\n').trim();
  return JSON.stringify({
    schema: 1,
    note: 'Written by node ui/tools/third_party_notices.mjs --write from tools/third-party.json (Tools). Do not edit by hand. Legal words: not translated.',
    title: 'Shader code by other people',
    text,
  }, null, 2) + '\n';
}

const args = new Set(process.argv.slice(2));
if (args.has('--write')) {
  mkdirSync(dirname(OUT), { recursive: true });
  writeFileSync(OUT, build());
  console.log('wrote ui/notices/third_party.json');
} else if (args.has('--check')) {
  const ok = existsSync(OUT) && readFileSync(OUT, 'utf8').split('\r').join('') === build();
  console.log(ok ? 'third-party notices are current' : 'third-party notices are stale: run node ui/tools/third_party_notices.mjs --write');
  process.exit(ok ? 0 : 1);
} else {
  console.log('usage: node ui/tools/third_party_notices.mjs --write | --check');
  process.exit(2);
}

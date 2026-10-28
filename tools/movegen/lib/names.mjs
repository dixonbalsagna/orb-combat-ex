// The names screen: every name the generator writes (a heavy's plain name, a special's id, words and looks, a fighter's key and
// any `name` his identity row gives) against Legal's word lists. The words are read from Legal's own files each run, never
// copied into Combat's data, so a word Legal adds is screened at once:
//   - docs/legal/movegen-banned.json: e11 (technique names never built on these words, nor led by these) and e14 (no 'X' in a name)
//   - docs/legal/never-use-words.md: the quoted words of "Franchise words" and "Our own working names"
//   - docs/legal/name-screening.md: stage 0's franchise words
// A source that yields no words is itself a finding: Legal's wording changed and the screen must be looked at.
// parts.json `nameScreen.allow` lists the phrases that are plain anatomy and not a technique's name ("ball of the foot"), each with why.
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { env, load } from './generator.mjs';
import { get, has, sorted } from './py.mjs';

const splitList = (s) => s.replace(/\([^)]*\)/g, ' ').split(/,\s*|\s+or\s+|\s+and\s+/).map((x) => x.replace(/["'.]/g, '').trim()).filter((x) => x && !/\bany\b/i.test(x));

/** Legal's words: { words: [{word, from}], leads: [{word, from}], problems: [string] }. */
export function legalWords(root = env.root) {
  const words = [];
  const leads = [];
  const problems = [];
  const add = (list, from, xs) => {
    if (!xs.length) problems.push(`the names screen found no words in ${from}: Legal's wording changed, look at tools/movegen/lib/names.mjs`);
    for (const x of xs) list.push({ word: x.toLowerCase(), from });
  };
  const banned = load(join(root, 'docs', 'legal', 'movegen-banned.json'));
  const rows = Object.fromEntries((banned.energy || []).map((r) => [r.id, r]));
  const e11 = get(get(rows, 'e11', {}), 'rule', '');
  const built = /technique names never built on ([^;]+?), nor lead with ([^;]+?)(?:;|$)/.exec(e11);
  add(words, 'e11 (built on)', built ? splitList(built[1]) : []);
  add(leads, 'e11 (lead with)', built ? splitList(built[2]) : []);
  const e14 = get(get(rows, 'e14', {}), 'rule', '');
  add(words, 'e14', [...e14.matchAll(/no '([^']+)' in a name/g)].map((m) => m[1]));
  const nu = join(root, 'docs', 'legal', 'never-use-words.md');
  if (existsSync(nu)) {
    const text = readFileSync(nu, 'utf8');
    for (const head of ['Franchise words', 'Our own working names']) {
      const sec = new RegExp(`## ${head}[^\\n]*\\n([\\s\\S]*?)(?=\\n## |$)`).exec(text);
      add(words, `never-use-words.md (${head})`, sec ? [...sec[1].matchAll(/"([^"]+)"/g)].map((m) => m[1]) : []);
    }
  } else problems.push('docs/legal/never-use-words.md is missing');
  const ns = join(root, 'docs', 'legal', 'name-screening.md');
  if (existsSync(ns)) {
    const line = /plays on a franchise word: ([^;]+);/.exec(readFileSync(ns, 'utf8'));
    add(words, 'name-screening.md (stage 0)', line ? splitList(line[1]) : []);
  } else problems.push('docs/legal/name-screening.md is missing');
  return { words, leads, problems };
}

const tokens = (s) => s.toLowerCase().match(/[a-z0-9]+/g) || [];

/** The words of Legal's lists that a name has, after the allowed phrases are taken out: [{word, from}]. */
export function screenName(text, lists, allow = []) {
  let s = ` ${tokens(text).join(' ')} `;
  for (const a of allow) s = s.split(` ${tokens(a.phrase).join(' ')} `).join(' ');
  const hits = [];
  for (const w of lists.words) {
    const t = tokens(w.word).join(' ');
    if (t && s.includes(` ${t} `)) hits.push(w);
  }
  const first = tokens(text)[0];
  for (const w of lists.leads) if (first && tokens(w.word)[0] === first) hits.push({ ...w, lead: true });
  return hits;
}

/** Every name a run writes, with where it is: [{who, where, text}]. */
export function namesOf(out, identity) {
  const got = [];
  for (const [who, doc] of Object.entries(out)) {
    got.push({ who, where: 'his key', text: who.replace(/_/g, ' ') });
    const row = get(identity.fighters, who, {});
    for (const k of ['name', 'title']) if (typeof get(row, k) === 'string') got.push({ who, where: `identity ${k}`, text: row[k] });
    for (const [cid, c] of Object.entries(doc.cells)) {
      if (c.kind === 'special' && typeof get(c, 'special') === 'string') {
        got.push({ who, where: `${cid} special`, text: c.special.replace(/[._]/g, ' ') });
        got.push({ who, where: `${cid} what`, text: c.what });
      }
      for (const m of get(c, 'moves', [])) {
        if (typeof get(m, 'name') === 'string') got.push({ who, where: m.id, text: m.name });
        if (has(m, 'look')) for (const v of Object.values(m.look)) got.push({ who, where: `${m.id} look`, text: String(v).replace(/_/g, ' ') });
      }
    }
  }
  return got;
}

/** Findings for --check and the refusal to write: a name with one of Legal's words, or a source that gave none. */
export function namesFindings(out, parts, identity) {
  const lists = legalWords(env.root);
  const allow = get(get(parts, 'nameScreen', {}), 'allow', []);
  const bad = [...lists.problems];
  for (const n of namesOf(out, identity)) {
    for (const h of screenName(n.text, lists, allow)) bad.push(`${n.who}: ${n.where} "${n.text}" ${h.lead ? 'leads with' : 'has'} "${h.word}" (${h.from})`);
  }
  return sorted([...new Set(bad)]);
}

'use strict';
// Fighters as data (docs/architecture/fighters-as-data.md, section 2): the game's wounds model and ladder are ONE shared file each, data/fight/wounds.json and data/fight/ladder.json,
// and a fighter's own file (data/fighters/<id>/wounds.json, ladder.json) is optional and holds only what differs for him. The loader lays his file over the shared one key by key:
// a dictionary is merged, a number, a word or a list replaces the shared one whole, a key the shared file does not have is refused, a `_` key is a note.
//
// This is that rule for the validator, done once before anything else reads the documents:
//   - the shared file is validated alone against the full schema (map.json names the same schema for it);
//   - a fighter's own file is validated against the same schema with nothing required (a difference file may hold any subset of keys) and its unknown keys are findings
//     (rule `shared-unknown-key`);
//   - what is validated against the full schema, and what the cross-references read, in the place of his file, is the MERGED result (his own file laid over the shared one, or
//     the shared one alone when he has none: a synthesized document that is not validated again, the shared file already was);
//   - a document that has no shared file beside it is left exactly as it was (a repository before the shared files, or a fixture without them).
// Pure: no file is read here. The documents are { value, lineOf } as core.js has them.

const isObj = (x) => x !== null && typeof x === 'object' && !Array.isArray(x);
const esc = (k) => String(k).replace(/~/g, '~0').replace(/\//g, '~1');
const clone = (x) => JSON.parse(JSON.stringify(x));

const KINDS = [
  { kind: 'wounds', shared: 'data/fight/wounds.json', own: /^data\/fighters\/([^/]+)\/wounds\.json$/, path: (id) => `data/fighters/${id}/wounds.json` },
  { kind: 'ladder', shared: 'data/fight/ladder.json', own: /^data\/fighters\/([^/]+)\/ladder\.json$/, path: (id) => `data/fighters/${id}/ladder.json` },
];

/** `over` laid over `base`: dictionaries merged key by key, everything else replaced whole. Unknown keys (not in base, not a `_` note) go to `unknown`. */
function merge(base, over, pointer, unknown) {
  if (!isObj(base) || !isObj(over)) return clone(over);
  const out = clone(base);
  for (const [k, v] of Object.entries(over)) {
    if (k.startsWith('_')) { out[k] = clone(v); continue; }
    const here = `${pointer}/${esc(k)}`;
    if (!(k in base)) { unknown.push(here); continue; }
    out[k] = isObj(base[k]) && isObj(v) ? merge(base[k], v, here, unknown) : clone(v);
  }
  return out;
}

/** The schema with every `required` list removed (a difference file has nothing required). */
function withoutRequired(s) {
  if (Array.isArray(s)) return s.map(withoutRequired);
  if (!isObj(s)) return s;
  const o = {};
  for (const [k, v] of Object.entries(s)) {
    if (k === 'required' && Array.isArray(v)) continue;
    o[k] = withoutRequired(v);
  }
  return o;
}

/**
 * docs: Map of path -> { value, lineOf }. ctx: { schemaNameFor, loadSchema, validate, closestLine }.
 * Returns { docs, findings, deps }: the documents with each fighter's file replaced by (or given) the merged result, the findings of the partial-file checks, and for each
 * merged path the files it depends on (so a self-test can tell which documents a mutation reaches).
 */
function mergeShared(docs, ctx) {
  const out = new Map(docs);
  const findings = [];
  const deps = new Map();
  const rosterDoc = docs.get('data/fighters/roster.json');
  const rv = rosterDoc ? rosterDoc.value : undefined;
  const ids = new Set(Array.isArray(rv) ? rv.filter((x) => typeof x === 'string') : []);
  for (const rel of docs.keys()) { const m = /^data\/fighters\/([^/]+)\/(fighter|meters|wounds|ladder)\.json$/.exec(rel); if (m) ids.add(m[1]); }
  for (const k of KINDS) {
    const shared = docs.get(k.shared);
    if (!shared || shared.value === undefined) continue;
    const name = ctx.schemaNameFor(k.path('X'));
    const full = name ? ctx.loadSchema(name) : undefined;
    const partial = full ? withoutRequired(full) : undefined;
    for (const id of [...ids].sort()) {
      const rel = k.path(id);
      const own = docs.get(rel);
      if (own && own.value !== undefined && isObj(own.value)) {
        const unknown = [];
        const value = merge(shared.value, own.value, '', unknown);
        if (partial) {
          for (const e of ctx.validate(partial, own.value, ctx.loadSchema)) {
            if (e.rule === 'additionalProperties' && unknown.includes(e.pointer)) continue;   // said once, by shared-unknown-key
            findings.push({ level: 'error', file: rel, line: own.lineOf ? ctx.closestLine(own.lineOf, e.pointer) : undefined, pointer: e.pointer, rule: e.rule, message: `${e.message} (a difference file: nothing required, the rest as in ${k.shared})` });
          }
        }
        for (const pointer of unknown) {
          findings.push({ level: 'error', file: rel, line: own.lineOf ? ctx.closestLine(own.lineOf, pointer) : undefined, pointer, rule: 'shared-unknown-key', message: `${pointer.split('/').pop()} is not a key of ${k.shared}: a fighter's file holds only differences from it, so a misspelt key cannot hide` });
        }
        out.set(rel, { value, lineOf: own.lineOf, merged: true });
        deps.set(rel, [rel, k.shared]);
      } else if (!own) {
        // no file of his own: he resolves to the shared one
        out.set(rel, { value: clone(shared.value), lineOf: shared.lineOf, merged: true, skipSchema: true });
        deps.set(rel, [k.shared]);
      }
    }
  }
  return { docs: out, findings, deps };
}

module.exports = { KINDS, merge, withoutRequired, mergeShared };

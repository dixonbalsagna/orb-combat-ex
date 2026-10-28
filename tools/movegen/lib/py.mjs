// Python's semantics where the moveset generator's output depends on them. The generator was written in Python
// (docs/combat/pending/movegen/gen_moveset.py, the reference) and its files are compared byte for byte, so the port keeps
// Python's JSON text, truthiness, equality, rounding and string words. Standard library only, no clock, no state.

const hasOwn = (o, k) => o !== null && typeof o === 'object' && Object.prototype.hasOwnProperty.call(o, k);

/** dict.get(k, dflt): a missing key is null (Python's None), never undefined. */
export function get(o, k, dflt = null) {
  return hasOwn(o, k) ? o[k] : dflt;
}

/** `k in d` for a dict, or `x in list` for a list. */
export function has(o, k) {
  if (Array.isArray(o)) return o.some((v) => eq(v, k));
  return hasOwn(o, k);
}

/** Python's == on JSON values: lists and dicts by value; True == 1. */
export function eq(a, b) {
  if (a === b) return true;
  if (a === undefined) a = null;
  if (b === undefined) b = null;
  if (a === null || b === null) return a === b;
  if (typeof a === 'boolean' && typeof b === 'number') return Number(a) === b;
  if (typeof b === 'boolean' && typeof a === 'number') return Number(b) === a;
  if (typeof a !== typeof b) return false;
  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
    return a.every((v, i) => eq(v, b[i]));
  }
  if (typeof a === 'object') {
    const ka = Object.keys(a);
    const kb = Object.keys(b);
    if (ka.length !== kb.length) return false;
    return ka.every((k) => hasOwn(b, k) && eq(a[k], b[k]));
  }
  return false;
}

/** Python truthiness: an empty list, dict or string, 0, None and False are false. */
export function truthy(v) {
  if (v === null || v === undefined || v === false || v === 0 || v === '') return false;
  if (Array.isArray(v)) return v.length > 0;
  if (v instanceof Set || v instanceof Map) return v.size > 0;
  if (typeof v === 'object') return Object.keys(v).length > 0;
  return true;
}

/** Python's ordering of tuples of strings, numbers and booleans (and nested tuples). */
export function cmp(a, b) {
  if (Array.isArray(a) && Array.isArray(b)) {
    const n = Math.min(a.length, b.length);
    for (let i = 0; i < n; i++) {
      const c = cmp(a[i], b[i]);
      if (c) return c;
    }
    return a.length - b.length;
  }
  if (typeof a === 'boolean') a = Number(a);
  if (typeof b === 'boolean') b = Number(b);
  if (a === null && b === null) return 0;
  return a < b ? -1 : a > b ? 1 : 0;
}

/** sorted(xs, key=f): stable, by Python's ordering of the keys. */
export function sorted(xs, key = (x) => x) {
  return xs
    .map((x, i) => [key(x), i, x])
    .sort((p, q) => cmp(p[0], q[0]) || p[1] - q[1])
    .map((p) => p[2]);
}

/** sorted(set(xs)) for strings and numbers. */
export function uniqSorted(xs) {
  return sorted([...new Set(xs)]);
}

/** str(x) as Python writes it in a join or a %s. */
export function str(x) {
  if (x === null || x === undefined) return 'None';
  if (x === true) return 'True';
  if (x === false) return 'False';
  return String(x);
}

/** str.capitalize(): the first character upper case and the rest lower case. */
export function capitalize(s) {
  s = str(s);
  return s.slice(0, 1).toUpperCase() + s.slice(1).toLowerCase();
}

/** round(x) to an int: ties to even, on the exact double. */
export function round(x) {
  const f = Math.floor(x);
  const d = x - f;
  if (d < 0.5) return f;
  if (d > 0.5) return f + 1;
  return f % 2 === 0 ? f : f + 1;
}

/** round(x, n) for the self-test's comparisons: near enough, since only equality with a short decimal is asked. */
export function roundTo(x, n) {
  return Number(x.toFixed(n));
}

/** "%.1f" % round(x, 1): the exact double rounded half to even (toFixed rounds an exact tie up; a tie at one decimal is x.25 or x.75). */
export function fixed1(x) {
  const q = x * 4;
  if (Number.isInteger(q) && q % 2 !== 0) {
    const lo = Math.floor(x * 10);   // exact: x is an odd number of quarters
    return ((lo % 2 === 0 ? lo : lo + 1) / 10).toFixed(1);
  }
  return x.toFixed(1);
}

/** "%g" for the short numbers the generator prints (1, 1.5, 2.5, 10). */
export function g(x) {
  return String(x);
}

/** "%02d" */
export const pad2 = (n) => String(n).padStart(2, '0');

// ---------------------------------------------------------------- json.dumps

function quote(s, ensureAscii) {
  let out = '"';
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === '"') out += '\\"';
    else if (ch === '\\') out += '\\\\';
    else if (ch === '\n') out += '\\n';
    else if (ch === '\r') out += '\\r';
    else if (ch === '\t') out += '\\t';
    else if (ch === '\b') out += '\\b';
    else if (ch === '\f') out += '\\f';
    else if (c < 0x20) out += '\\u' + c.toString(16).padStart(4, '0');
    else if (ensureAscii && c > 0x7e) {
      if (c > 0xffff) {
        const v = c - 0x10000;
        out += '\\u' + (0xd800 + (v >> 10)).toString(16) + '\\u' + (0xdc00 + (v & 0x3ff)).toString(16);
      } else out += '\\u' + c.toString(16).padStart(4, '0');
    } else out += ch;
  }
  return out + '"';
}

function num(x) {
  if (Number.isInteger(x)) return String(x);
  // Python's float repr: the shortest round trip, with an exponent from 1e16 up and under 1e-4
  const r = String(x);
  if (/e/.test(r)) {
    const [m, e] = r.split('e');
    const ex = Number(e);
    return `${m}e${ex < 0 ? '-' : '+'}${String(Math.abs(ex)).padStart(2, '0')}`;
  }
  return r;
}

/**
 * json.dumps(v, indent=None|n, sort_keys, ensure_ascii). Separators are Python's defaults: ", " and ": " with no indent,
 * "," and ": " with one. A number is an int unless it has a fraction (no output of the generator holds a float).
 */
export function dumps(v, { indent = null, sortKeys = false, ensureAscii = true } = {}) {
  const item = indent === null ? ', ' : ',';
  const walk = (x, level) => {
    if (x === null || x === undefined) return 'null';
    if (x === true) return 'true';
    if (x === false) return 'false';
    if (typeof x === 'number') return num(x);
    if (typeof x === 'string') return quote(x, ensureAscii);
    const nl = indent === null ? '' : '\n' + ' '.repeat(indent * (level + 1));
    const end = indent === null ? '' : '\n' + ' '.repeat(indent * level);
    if (Array.isArray(x)) {
      if (!x.length) return '[]';
      return '[' + nl + x.map((y) => walk(y, level + 1)).join(item + nl) + end + ']';
    }
    let keys = Object.keys(x);
    if (!keys.length) return '{}';
    if (sortKeys) keys = sorted(keys);
    return '{' + nl + keys.map((k) => quote(k, ensureAscii) + ': ' + walk(x[k], level + 1)).join(item + nl) + end + '}';
  };
  return walk(v, 0);
}

// The public-repo content screen (corrective directive CD-27, with CD-07 and CD-08; Tools, 2026-11-07). The repository is public: this fails a push that carries a user-profile path,
// a secret, a console SDK path, a franchise word in what ships, a gold-haired fighter (Legal RL-014) or a public sentence that is not true. Rules are data (tools/content-screen.json).
//   node tools/content-screen.mjs [--root <dir>] [--rules <file>] [--json]
// Files: `git ls-files -co --exclude-standard` in --root (the working tree: tracked and not-ignored files), or every file under --root when it is not a git checkout. Text files only.
// Output never repeats a secret or a personal name in full: a hit shows its rule, file, line and a masked excerpt. Exit 1 on a 'fail' hit, 0 otherwise (a 'warn' is printed and counted).
// Node built-ins only.
import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const SELF = new Set(['tools/content-screen.json', 'tools/content-screen.mjs', 'tools/content-screen-selftest.mjs']);

/** Every candidate file under root, as forward-slash relative paths. */
export function listFiles(root, rules) {
  const skipDirs = new Set(rules.skipDirs || []);
  try {
    const out = execFileSync('git', ['ls-files', '-co', '--exclude-standard', '-z'], { cwd: root, encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, stdio: ['ignore', 'pipe', 'ignore'] });
    return out.split('\0').filter(Boolean).filter((f) => !skipDirs.has(f.split('/')[0]));
  } catch { /* not a git checkout: walk it */ }
  const found = [];
  const walk = (d) => {
    for (const e of readdirSync(d, { withFileTypes: true })) {
      if (e.isDirectory()) { if (!skipDirs.has(e.name) && !(d === root && skipDirs.has(e.name))) walk(join(d, e.name)); } else found.push(relative(root, join(d, e.name)).split(sep).join('/'));
    }
  };
  walk(root);
  return found;
}

/** The text of a file, or null for a binary, a skipped extension or a file that is too large. */
export function readText(root, f, rules) {
  const ext = (f.split('.').pop() || '').toLowerCase();
  if ((rules.skipExt || []).includes(ext)) return null;
  const p = join(root, ...f.split('/'));
  let st; try { st = statSync(p); } catch { return null; }
  if (!st.isFile() || st.size > (rules.maxBytes || 4194304)) return null;
  const buf = readFileSync(p);
  if (buf.subarray(0, 4096).includes(0)) return null;
  return buf.toString('utf8');
}

/** A masked excerpt: keeps the shape, hides the secret. (A profile name is printed as <redacted>, a placeholder the screen itself allows, so a saved log of the screen never trips the screen.) */
const mask = (s) => (s.length <= 6 ? '*'.repeat(s.length) : `${s.slice(0, 3)}${'*'.repeat(Math.min(12, s.length - 3))}`);

const BS = String.fromCharCode(92);   // a backslash, built so no escaping layer can eat it

/** The user-profile regexes: the name capture is group 1. */
export function profileRegexes() {
  const sl = `[${BS}${BS}/]`;
  const nm = `([^${BS}${BS}/\\s"'<>|:*?\`]+)`;
  return [
    new RegExp(`[A-Za-z]:${sl}+Users${sl}+${nm}`, 'g'),            // C:\Users\name, C:/Users/name, C:\\Users\\name
    new RegExp(`(?<![A-Za-z0-9_.])/Users/${nm}`, 'g'),                // macOS
    new RegExp(`(?<![A-Za-z0-9_.])/home/${nm}`, 'g'),                 // Linux
    new RegExp(`Users(?:${sl}+|%5[cC])${nm}`, 'g'),                   // Users\name with no drive, or percent-encoded
  ];
}

function hairIsGold(hex) {
  const m = /^#?([0-9a-f]{6})$/i.exec(String(hex).trim());
  if (!m) return false;
  const n = parseInt(m[1], 16), r = ((n >> 16) & 255) / 255, g = ((n >> 8) & 255) / 255, b = (n & 255) / 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn;
  if (d === 0) return false;
  let h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
  h = (h * 60 + 360) % 360;
  const s = d / mx;
  return h >= 38 && h <= 65 && s > 0.45 && mx > 0.55;
}

/** Runs every rule over root. Returns { hits: [{ rule, severity, file, line, excerpt, why? }], files, scanned }. */
export function screen(root, rules) {
  const files = listFiles(root, rules);
  const hits = [];
  const add = (rule, severity, file, line, excerpt, why) => hits.push({ rule, severity, file, line, excerpt, ...(why ? { why } : {}) });
  const names = new Set((rules.profilePath.names || []).map((x) => x.toLowerCase()));
  const profRes = profileRegexes();
  const secRes = (rules.secrets.patterns || []).map((p) => ({ id: p.id, re: new RegExp(p.re, 'g') }));
  const sdkRe = new RegExp(rules.consoleSdk.re, 'g');
  const fr = rules.franchise;
  const frRe = new RegExp(`(?<![A-Za-z0-9_])(?:${fr.words.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')})(?![A-Za-z0-9_])`, 'gi');
  const inScope = (f, list) => list.some((s) => f === s || f.startsWith(s));
  const pubFiles = new Set(rules.publicWords.files);
  let scanned = 0;
  for (const f of files) {
    const text = readText(root, f, rules);
    if (text === null) continue;
    scanned++;
    const lines = text.split(/\r?\n/);
    const frOn = inScope(f, fr.scope) && !(fr.skip || []).includes(f);
    const self = SELF.has(f);   // the screen's own rule file, code and self-test name the words they hunt: only the franchise and console rules skip them
    for (let i = 0; i < lines.length; i++) {
      const ln = lines[i];
      if (ln.length > 20000) continue;   // a minified blob: the secret patterns below still run on the whole text? no: skipped lines are data dumps
      // profile paths (never print the name)
      let seen = false;
      for (const re of profRes) {
        re.lastIndex = 0;
        let m;
        while ((m = re.exec(ln)) !== null) {
          const name = m[1].replace(/[,.;:)\]}]+$/, '');   // a trailing punctuation mark is not part of a name
          if (!name) continue;
          if (names.has(name.toLowerCase()) || /^[<{%$]/.test(name)) continue;
          if (!seen) add('profile-path', rules.profilePath.severity, f, i + 1, `${m[0].slice(0, m[0].length - name.length)}<redacted>`);
          seen = true;
        }
      }
      for (const s of secRes) { s.re.lastIndex = 0; const m = s.re.exec(ln); if (m) add(`secret:${s.id}`, rules.secrets.severity, f, i + 1, mask(m[0])); }
      sdkRe.lastIndex = 0;
      if (!self) { const m = sdkRe.exec(ln); if (m) add('console-sdk', rules.consoleSdk.severity, f, i + 1, m[0].slice(0, 40)); }
      if (frOn) { frRe.lastIndex = 0; const m = frRe.exec(ln); if (m) add('franchise-word', fr.severity, f, i + 1, m[0], 'Legal never-use list: not in what ships or is shown'); }
      if (pubFiles.has(f)) {
        for (const p of rules.publicWords.phrases) { if (new RegExp(p.re, 'i').test(ln)) add(`public-words:${p.id}`, p.severity, f, i + 1, p.re, p.why); }
      }
    }
    // RL-014: the shipped fighter files' hair colour
    if (rules.rl014.files.some((p) => f.startsWith(p)) && f.endsWith('.json')) {
      for (let i = 0; i < lines.length; i++) {
        const m = new RegExp(`"${rules.rl014.key}"\\s*:\\s*"(#[0-9a-fA-F]{6})"`).exec(lines[i]);
        if (m && hairIsGold(m[1])) add('rl014-gold-hair', rules.rl014.severity, f, i + 1, `${rules.rl014.key} ${m[1]}`, 'Legal RL-014: no golden hair as a power cue');
      }
    }
  }
  // Legal RL-267, G22: no tester's raw file or name in the repository. Structural (a path or a saved match's own kind) everywhere; names only where the git-ignored list is present (Orb's PC).
  const notes = [];
  const tf = rules.testerFiles;
  if (tf) {
    const pathRes = (tf.pathRegexes || []).map((p) => ({ ...p, rx: new RegExp(p.re) }));
    const kinds = new Set(tf.savedKinds || []);
    for (const f of files) {
      for (const p of pathRes) if (p.rx.test(f)) add(`tester-file:${p.id}`, tf.severity, f, 0, f, p.why);
      if (f.endsWith('.json') && !SELF.has(f)) {
        const text = readText(root, f, rules);
        if (text !== null && /"kind"/.test(text)) {
          let d = null; try { d = JSON.parse(text); } catch { /* not a save */ }
          if (d && typeof d === 'object' && kinds.has(d.kind)) add('tester-file:saved-match', tf.severity, f, 0, `"kind": "${d.kind}"`, "a saved match is a tester's raw play file: it lives in .private/testers/, never in a tracked file");
        }
      }
    }
    let namesText = null; try { namesText = readFileSync(join(root, ...tf.namesFile.split('/')), 'utf8'); } catch { /* absent */ }
    const testerNames = namesText === null ? [] : namesText.split(/\r?\n/).map((x) => x.trim()).filter((x) => x && !x.startsWith('#'));
    if (namesText === null) notes.push(`tester names are not checked here: ${tf.namesFile} is not present (it is git-ignored and lives on Orb's PC); the path and saved-match rules ran`);
    else if (testerNames.length) {
      const esc = testerNames.map((n) => n.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
      const nameRe = new RegExp(`(?<![A-Za-z0-9_])(?:${esc.join('|')})(?![A-Za-z0-9_])`, 'i');
      let ncount = 0;
      for (const f of files) {
        if (f.startsWith('.private/') || SELF.has(f)) continue;
        const text = readText(root, f, rules);
        if (text === null) continue;
        const lines = text.split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) if (lines[i].length <= 20000 && nameRe.test(lines[i])) { add('tester-name', tf.severity, f, i + 1, '<a name from the tester list>', tf.why); ncount++; break; }
      }
      notes.push(`tester names checked against ${testerNames.length} name(s) from ${tf.namesFile}: ${ncount} file(s) carry one`);
    } else notes.push(`${tf.namesFile} is present and holds no names`);
  }
  // the public pages must carry Legal's words (a text that is not there is a hit)
  for (const m of rules.mustContain || []) {
    let body = null; try { body = readFileSync(join(root, ...m.file.split('/')), 'utf8'); } catch { /* missing */ }
    if (body === null) add('must-contain', m.severity || 'fail', m.file, 0, `the file is missing: ${m.text}`, m.why);
    else if (!body.includes(m.text)) add('must-contain', m.severity || 'fail', m.file, 0, `does not carry: ${m.text}`, m.why);
  }
  return { hits, files: files.length, scanned, notes };
}

export function loadRules(file = join(HERE, 'content-screen.json')) { return JSON.parse(readFileSync(file, 'utf8')); }

function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const root = resolve(opt('--root', join(HERE, '..')));
  const rules = loadRules(opt('--rules') ? resolve(opt('--rules')) : undefined);
  const r = screen(root, rules);
  const fails = r.hits.filter((h) => h.severity === 'fail'), warns = r.hits.filter((h) => h.severity !== 'fail');
  if (a.includes('--json')) { console.log(JSON.stringify(r, null, 1)); }
  else {
    for (const h of [...fails, ...warns]) console.log(`${h.severity === 'fail' ? 'FAIL' : 'warn'}  ${h.rule}  ${h.file}:${h.line}  ${h.excerpt}${h.why ? `  (${h.why})` : ''}`);
    for (const n of r.notes || []) console.log(`note  ${n}`);
    console.log(`content screen: ${r.scanned} text files of ${r.files} scanned, ${fails.length} failing hit(s), ${warns.length} warning(s)`);
  }
  process.exit(fails.length ? 1 : 0);
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();

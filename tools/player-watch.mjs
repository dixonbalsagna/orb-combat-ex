// The daily player watch (corrective directive CD-19; Tools, 2026-11-07): what players get, not what HEAD says. It reads the LIVE address, not the repository, and compares it with
// what the repository says the site should be: tools/site.json (offline or live, the pin, the interim's end), the custom engine allowance's end (tools/flash/signature-gate.json
// engineFlip.until) and the age of the nightly seed run (tools/flash/nightly-seeds.json, one row a night). A failure exits 1, so the scheduled run is red and GitHub says so.
//   node tools/player-watch.mjs [--base <https://.../>] [--today YYYY-MM-DD] [--json]
// Verdicts: OK / WARN / FAIL per line, then one summary line. Node built-ins only (global fetch).
//   FAIL  the live /play/ is not what the repository says (a game served while site.json is offline: the take-down did not take; a notice served while it says live; the address unreachable)
//   FAIL  a game is live and the interim, or the custom engine's allowance, has ended, or the nightly is older than the limit
//   WARN  an end date inside three days; the pin could not be read from the page; the nightly is old while the site is offline (not needed then)
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const DAY = 86400000;
export const daysBetween = (a, b) => Math.round((Date.parse(`${b}T00:00:00Z`) - Date.parse(`${a}T00:00:00Z`)) / DAY);

/** What a /play/ page body is: 'offline' (the notice: it names itself and holds no engine), 'game' (the engine's page), 'other'. */
export function classify(body) {
  const text = String(body || '');
  const engine = /index\.js|engine\.startGame|__startGame|\.wasm/.test(text);
  if (engine) return 'game';
  if (/offline for now/i.test(text)) return 'offline';
  return 'other';
}

/**
 * The reading, pure: every input is passed in. site: parsed tools/site.json; gate: signature-gate.json; nightly: nightly-seeds.json; live: { status, body, pck, error } of the live /play/ (pck: the status of /play/index.pck);
 * today: YYYY-MM-DD; cfg: { nightlyMaxDays, warnDays }; ciNightly (optional): the scheduled flash reading of main, { last: 'YYYY-MM-DD' of its last successful run or null, error? } (CD-09, 2026-11-14), absent when the
 * repository's runs could not be asked (a local run). Returns { lines: [{ level, text }], fail, state, expect }.
 */
export function reading({ site, gate, nightly, live, today, cfg = {}, ciNightly }) {
  const maxNight = cfg.nightlyMaxDays ?? 2, warnDays = cfg.warnDays ?? 3;
  const lines = [];
  const add = (level, text) => lines.push({ level, text });
  const expect = site && site.offline === false ? 'live' : 'offline';
  let state;
  if (live.error) state = 'unreachable';
  else if (live.status === 404) state = 'not published';
  else if (live.status >= 500 || live.status === 0) state = 'unreachable';
  else state = classify(live.body);
  if (state === 'game' && live.pck === 404) state = 'broken game page (no pack)';

  // 1. what /play/ serves, against what the repository says
  const label = `live /play/ reads "${state}"; tools/site.json says ${expect === 'live' ? 'live (offline: false)' : 'offline'}`;
  if (expect === 'offline') {
    if (state === 'offline') add('OK', `${label}: the take-down holds`);
    else if (state === 'not published') add('OK', `${label}: nothing is served (unpublished by hand)`);
    else if (state === 'game') add('FAIL', `${label}: A GAME IS SERVED while the repository says offline: the take-down did not take. Run takedown.yml (docs/tools/site-interim.md)`);
    else add('FAIL', `${label}: the page could not be read as the offline notice (${live.error || `HTTP ${live.status}`})`);
    if (state === 'offline' && live.pck !== undefined && live.pck !== 404 && live.pck !== 0) add('FAIL', `/play/index.pck answers HTTP ${live.pck} while the site reads offline: a game file is served`);
  } else {
    if (state === 'game') add('OK', label);
    else add('FAIL', `${label}: players get ${state === 'offline' ? 'the offline notice' : state}, not the playable build`);
  }

  // 2. the pin, when a game is served
  if (expect === 'live' && state === 'game') {
    const pin = String(site.pin || '');
    const body = String(live.body || '');
    if (pin && body.includes(pin.slice(0, 7))) add('OK', `the page names the pinned commit ${pin.slice(0, 7)}`);
    else if (pin) add('WARN', `the page does not name the pinned commit ${pin.slice(0, 7)}; the pin could not be read from it`);
  } else if (site && site.pin) add('OK', `the pin on record is ${String(site.pin).slice(0, 7)} (nothing is served from it while the site is ${expect === 'offline' ? 'offline' : state})`);

  // 3. the interim's end, and the custom engine's allowance
  const ends = [];
  if (site && site.interim && site.interim.expires) ends.push(['the interim', site.interim.expires]);
  if (gate && gate.engineFlip && gate.engineFlip.until) ends.push(['the custom engine allowance (RL-202)', gate.engineFlip.until]);
  if (!ends.length) add('OK', 'no interim and no allowance end date on record');
  for (const [what, date] of ends) {
    const left = daysBetween(today, date);
    if (expect === 'offline') add('OK', `${what} ends ${date} (${left >= 0 ? `${left} day(s) left` : `${-left} day(s) ago`}); the site is offline, so no game is exposed to it`);
    else if (left < 0) add('FAIL', `${what} ended ${date} (${-left} day(s) ago) and a game is live`);
    else if (left <= warnDays) add('WARN', `${what} ends ${date}: ${left} day(s) left`);
    else add('OK', `${what} ends ${date}: ${left} day(s) left`);
  }

  // 4. the nightly's age
  const runs = (nightly && nightly.runs) || [];
  const last = runs.length ? runs[runs.length - 1].date : null;
  if (!last) add(expect === 'live' ? 'FAIL' : 'WARN', 'the nightly seed run has no recorded night');
  else {
    const age = daysBetween(last, today);
    if (age <= maxNight) add('OK', `the last nightly is ${last} (${age} day(s) old)`);
    else if (expect === 'live') add('FAIL', `the last nightly is ${last}, ${age} day(s) old (the limit is ${maxNight}) and a game is live: the take-down trigger is not being read`);
    else add('WARN', `the last nightly is ${last}, ${age} day(s) old; not needed while the site is offline, needed again before it returns`);
  }
  // 5. the scheduled flash reading of main (.github/workflows/flash-nightly.yml, CD-09): the alarm is the same whether a game is live or not, because every outside tester's gate list needs a current reading
  if (ciNightly) {
    if (ciNightly.error) add('WARN', `the runs of the scheduled flash reading (flash-nightly.yml) could not be read: ${ciNightly.error}`);
    else if (!ciNightly.last) add('FAIL', 'the scheduled flash reading (flash-nightly.yml) has no successful run: no flash reading of main is being read on a schedule');
    else {
      const age = daysBetween(ciNightly.last, today);
      if (age <= maxNight) add('OK', `the last scheduled flash reading of main succeeded on ${ciNightly.last} (${age} day(s) old)`);
      else add('FAIL', `the last successful scheduled flash reading of main is ${ciNightly.last}, ${age} day(s) old (the limit is ${maxNight}): the flash reading is not being kept current`);
    }
  }
  return { lines, fail: lines.some((l) => l.level === 'FAIL'), state, expect };
}

/** The date of the last successful run of the scheduled flash reading, from GitHub's run list of the workflow (or { error }). Needs GITHUB_REPOSITORY; the token is optional (a public repository's list is open). */
export async function ciNightlyFrom(env = process.env, fetcher = fetch) {
  const repo = env.GITHUB_REPOSITORY;
  if (!repo) return undefined;   // not on GitHub: nothing to ask
  try {
    const r = await fetcher(`https://api.github.com/repos/${repo}/actions/workflows/flash-nightly.yml/runs?status=success&branch=main&per_page=1`, { headers: { accept: 'application/vnd.github+json', 'user-agent': 'orb-combat-ex-player-watch', ...(env.GITHUB_TOKEN ? { authorization: `Bearer ${env.GITHUB_TOKEN}` } : {}) } });
    if (r.status === 404) return { last: null };   // the workflow file is not on main yet: no run
    if (!r.ok) return { error: `HTTP ${r.status}` };
    const j = await r.json();
    const run = j && Array.isArray(j.workflow_runs) ? j.workflow_runs[0] : null;
    return { last: run && run.created_at ? String(run.created_at).slice(0, 10) : null };
  } catch (e) { return { error: String(e && e.message || e) }; }
}

async function get(url, method = 'GET', tries = 3) {
  let last = null;
  for (let i = 0; i < tries; i++) {
    try {
      const ctl = new AbortController(); const t = setTimeout(() => ctl.abort(), 20000);
      const r = await fetch(url, { method, redirect: 'follow', signal: ctl.signal, headers: { 'user-agent': 'orb-combat-ex-player-watch' } });
      clearTimeout(t);
      return { status: r.status, body: method === 'GET' ? await r.text() : '' };
    } catch (e) { last = e; await new Promise((r) => setTimeout(r, 1500)); }
  }
  return { status: 0, body: '', error: String(last && last.message || last) };
}

const json = (f, d = null) => { try { return JSON.parse(readFileSync(join(HERE, f), 'utf8')); } catch { return d; } };

async function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const cfg = json('player-watch.json', {});
  const base = (opt('--base', cfg.base) || '').replace(/\/?$/, '/');
  const today = opt('--today', new Date().toISOString().slice(0, 10));
  const play = await get(`${base}play/`);
  const pck = await get(`${base}play/index.pck`, 'HEAD', 2);
  const live = { status: play.status, body: play.body, error: play.error, pck: pck.error ? undefined : pck.status };
  const ciNightly = await ciNightlyFrom();
  const r = reading({ site: json('site.json', {}), gate: json('flash/signature-gate.json', {}), nightly: json('flash/nightly-seeds.json', {}), live, today, cfg, ciNightly });
  if (a.includes('--json')) console.log(JSON.stringify({ today, base, ...r }, null, 1));
  else {
    for (const l of r.lines) console.log(`${l.level.padEnd(4)}  ${l.text}`);
    console.log(`player watch ${today}: /play/ reads "${r.state}" (the repository says ${r.expect === 'live' ? 'live' : 'offline'}); ${r.fail ? 'FAILED' : 'ok'}${r.lines.some((l) => l.level === 'WARN') ? ' with warnings' : ''}`);
  }
  process.exitCode = r.fail ? 1 : 0;   // not process.exit(): on Windows an exit straight after fetch trips a libuv assertion (exit 127)
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();

// Self-test of tools/player-watch.mjs (CD-19): the reading is pure, so each way the live site can disagree with the repository is a fixture. No network. CI runs it.
//   node tools/player-watch-selftest.mjs
import { ciNightlyFrom, classify, daysBetween, reading } from './player-watch.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const NOTICE = '<h2>The playable build is offline for now.</h2><p>There is no date for its return.</p>';
const GAME = '<script src="index.js"></script><script>engine.startGame({})</script> build 257a766';
const GAME_NOPIN = '<script src="index.js"></script><script>engine.startGame({})</script>';
const off = { offline: true, pin: '257a766c26f8766fb09b063864c41c5d8ba64dc0', interim: null };
const live = { offline: false, pin: '257a766c26f8766fb09b063864c41c5d8ba64dc0', interim: { expires: '2026-11-15' } };
const gate = { engineFlip: { until: '2026-11-15' } };
const nightly = (d) => ({ runs: [{ date: d }] });
const R = (o) => reading({ today: '2026-11-08', gate, nightly: nightly('2026-11-07'), site: off, live: { status: 200, body: NOTICE, pck: 404 }, ...o });
const has = (r, level, re) => r.lines.some((l) => l.level === level && re.test(l.text));

check('classify: the notice is offline, the engine page is a game, anything else is other', classify(NOTICE) === 'offline' && classify(GAME) === 'game' && classify('<p>hi</p>') === 'other' && classify('') === 'other');
check('daysBetween counts calendar days', daysBetween('2026-11-08', '2026-11-15') === 7 && daysBetween('2026-11-15', '2026-11-08') === -7 && daysBetween('2026-10-30', '2026-11-08') === 9);

let r = R({});
check('offline repository and an offline notice: ok, the take-down holds', !r.fail && r.state === 'offline' && r.expect === 'offline' && has(r, 'OK', /take-down holds/));
r = R({ live: { status: 200, body: GAME, pck: 200 } });
check('offline repository but a game served: FAIL, says the take-down did not take', r.fail && has(r, 'FAIL', /A GAME IS SERVED/));
r = R({ live: { status: 200, body: NOTICE, pck: 200 } });
check('an offline notice with the pack still answering 200: FAIL', r.fail && has(r, 'FAIL', /index\.pck answers HTTP 200/));
r = R({ live: { status: 404, body: '', pck: 404 } });
check('nothing published (unpublished by hand) while the repository says offline: ok', !r.fail && has(r, 'OK', /unpublished by hand/));
r = R({ live: { status: 0, body: '', error: 'ENOTFOUND' } });
check('an unreachable address: FAIL', r.fail && r.state === 'unreachable');
r = R({ live: { status: 503, body: '', pck: undefined } });
check('a 5xx answer: FAIL', r.fail && r.state === 'unreachable');

r = R({ site: live, live: { status: 200, body: GAME, pck: 200 } });
check('live repository and a game that names the pin: ok, the pin is read from the page', !r.fail && has(r, 'OK', /names the pinned commit 257a766/));
r = R({ site: live, live: { status: 200, body: GAME_NOPIN, pck: 200 } });
check('a game that does not name the pin: a warning, not a fail', !r.fail && has(r, 'WARN', /pin could not be read/));
r = R({ site: live, live: { status: 200, body: NOTICE, pck: 404 } });
check('live repository but players get the notice: FAIL', r.fail && has(r, 'FAIL', /offline notice, not the playable build/));
r = R({ site: live, live: { status: 200, body: GAME, pck: 404 } });
check('a game page with no pack: FAIL', r.fail && r.state.startsWith('broken'));

r = reading({ today: '2026-11-16', gate, nightly: nightly('2026-11-15'), site: live, live: { status: 200, body: GAME, pck: 200 } });
check('a game live after the interim and the engine allowance ended: FAIL on both', r.fail && has(r, 'FAIL', /the interim ended 2026-11-15/) && has(r, 'FAIL', /custom engine allowance \(RL-202\) ended/));
r = reading({ today: '2026-11-13', gate, nightly: nightly('2026-11-12'), site: live, live: { status: 200, body: GAME, pck: 200 } });
check('two days before the end: a warning and no fail', !r.fail && has(r, 'WARN', /2 day\(s\) left/));
r = reading({ today: '2026-11-08', gate, nightly: nightly('2026-11-02'), site: live, live: { status: 200, body: GAME, pck: 200 } });
check('a nightly older than two days while a game is live: FAIL', r.fail && has(r, 'FAIL', /6 day\(s\) old/));
r = R({ nightly: nightly('2026-10-30') });
check('the same age while the site is offline: a warning only', !r.fail && has(r, 'WARN', /9 day\(s\) old; not needed while the site is offline/));
r = R({ nightly: { runs: [] } });
check('no recorded nightly while offline: a warning; while live it is a fail', !r.fail && has(r, 'WARN', /no recorded night/) && reading({ today: '2026-11-08', gate, nightly: { runs: [] }, site: live, live: { status: 200, body: GAME, pck: 200 } }).fail);
r = R({ site: off, gate: {}, live: { status: 200, body: NOTICE, pck: 404 } });
check('no end date on record: ok', !r.fail && has(r, 'OK', /no interim and no allowance end date/));

// ---- the scheduled flash reading of main (CD-09, 2026-11-14): its last successful run must be at most two days old, live or offline
{
  const CI = (o) => R({ ciNightly: o });
  let r2 = CI({ last: '2026-11-07' });
  check('a scheduled flash reading one day old is ok', !r2.fail && has(r2, 'OK', /scheduled flash reading of main succeeded on 2026-11-07 \(1 day\(s\) old\)/));
  r2 = CI({ last: '2026-11-06' });
  check('two days old is still ok (the limit is two)', !r2.fail && has(r2, 'OK', /2 day\(s\) old/));
  r2 = CI({ last: '2026-11-05' });
  check('three days old is a FAIL even while the site is offline', r2.fail && has(r2, 'FAIL', /3 day\(s\) old \(the limit is 2\)/));
  r2 = CI({ last: null });
  check('no successful run at all is a FAIL', r2.fail && has(r2, 'FAIL', /has no successful run/));
  r2 = CI({ error: 'HTTP 403' });
  check('runs that cannot be read are a warning, not a fail (the reading is not known to be old)', !r2.fail && has(r2, 'WARN', /could not be read: HTTP 403/));
  check('without the run list (a local run) the reading says nothing about it', !R({}).lines.some((l) => /scheduled flash reading/.test(l.text)));
}

// the run list of the scheduled flash reading, with a fake fetch (no network)
{
  const fake = (status, body) => async () => ({ status, ok: status >= 200 && status < 300, json: async () => body });
  check('no GITHUB_REPOSITORY (a local run): nothing is asked', (await ciNightlyFrom({}, fake(200, {}))) === undefined);
  const env = { GITHUB_REPOSITORY: 'o/r' };
  check('the last successful run gives its date', (await ciNightlyFrom(env, fake(200, { workflow_runs: [{ created_at: '2026-11-13T04:24:01Z' }] }))).last === '2026-11-13');
  check('a workflow with no run gives null', (await ciNightlyFrom(env, fake(200, { workflow_runs: [] }))).last === null);
  check('a 404 (the workflow file is not on main) gives null, a fail upstream', (await ciNightlyFrom(env, fake(404, {}))).last === null);
  check('another HTTP error is an error, not a date', (await ciNightlyFrom(env, fake(500, {}))).error === 'HTTP 500');
  check('a network failure is an error', (await ciNightlyFrom(env, async () => { throw new Error('offline'); })).error === 'offline');
}

console.log(failed ? `player watch self-test FAILED: ${failed} of ${ran} checks` : `player watch self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

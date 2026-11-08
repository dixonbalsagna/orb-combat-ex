// Self-test of tools/player-watch.mjs (CD-19): the reading is pure, so each way the live site can disagree with the repository is a fixture. No network. CI runs it.
//   node tools/player-watch-selftest.mjs
import { classify, daysBetween, reading } from './player-watch.mjs';

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

console.log(failed ? `player watch self-test FAILED: ${failed} of ${ran} checks` : `player watch self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);

#!/usr/bin/env node
// Self-test for the Godot QA tooling, no Godot needed: node qa/godot/selftest.js
// Feeds synthetic records to the acceptance-test skeletons and the band evaluator to prove that (1) a skeleton stays
// PENDING while its events are absent, (2) it PASSes on records that satisfy the spec and FAILs on records that break it
// once the events exist, so the wiring is known to work before the slices land.
const assert = require('assert');
const { runTests } = require('./pending-tests');
const { evaluate } = require('./bands');

let pass = 0, fail = 0;
const t = async (name, fn) => { try { await fn(); pass++; console.log('  ok    ' + name); } catch (e) { fail++; console.log('  FAIL  ' + name + '\n        ' + e.message.split('\n')[0]); } };

// A minimal record with the fields the tests read.
const rec = (o = {}) => ({ seed: 1, arm: 'default', names: ['PROTAGONIST', 'RIVAL'], timeout: false, winner: 0, koAt: 100, tierT: [0, -1, 20, 40, -1], maxTier: [3, 2], fronts: 0, wear: [null, null], events: [], fxCounts: {}, launches: {}, melee: {}, beams: [], parries: [0, 0], chains: [], hides: [0, 0], hiddenSec: [0, 0], fightSec: { plains: 10 }, exLens: [], exGaps: [], flights: [], underSec: 0, lowSec: 1, lowCas: 0, pop0: 425, civPct: 30, ambush: 0, rows: { 1: { lost: 10, n: 47 } }, menace: [0, 0], ...o });
const withEvents = (r, evs) => { const fx = { ...r.fxCounts }; for (const e of evs) fx[e.type] = (fx[e.type] || 0) + 1; return { ...r, events: evs, fxCounts: fx }; };
const byId = res => Object.fromEntries(res.map(r => [r.id, r]));
const ctx = A => ({ A, runRecords: async () => [rec()] });

(async () => {
  console.log('== godot qa selftest');
  await t('every slice-dependent skeleton is PENDING on records with no wounds or hazard events', async () => {
    const r = byId(await runTests(ctx({ default: [rec()] }), ['W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'H1', 'H2', 'H3', 'H4', 'H5']));
    assert.ok(Object.values(r).every(x => x.status === 'PENDING'), JSON.stringify(Object.values(r).map(x => x.id + ':' + x.status)));
  });
  await t('W2 passes when a KO follows brink_enter then finisher_start, and fails when there is no finisher', async () => {
    const ok = withEvents(rec(), [{ type: 'brink_enter', t: 50, actor: 1 }, { type: 'finisher_start', t: 60, actor: 0, target: 1 }, { type: 'ko', t: 62, winner: 0, loser: 1 }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [ok] }), ['W2'])).W2.status, 'PASS');
    const bad = withEvents(rec(), [{ type: 'brink_enter', t: 50, actor: 1 }, { type: 'finisher_start', t: 60, actor: 0, target: 0 }, { type: 'ko', t: 62, winner: 0, loser: 1 }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [bad] }), ['W2'])).W2.status, 'FAIL');
  });
  await t('W4 fails when a region is rallied twice, and when survival stays above 0 after a third rally', async () => {
    const twice = withEvents(rec(), [{ type: 'rally', t: 10, actor: 1, region: 'legs' }, { type: 'rally', t: 40, actor: 1, region: 'legs' }, { type: 'finisher_contest', t: 50, target: 1, chance: 0 }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [twice] }), ['W4'])).W4.status, 'FAIL');
    const three = withEvents(rec(), [{ type: 'rally', t: 10, actor: 1, region: 'legs' }, { type: 'rally', t: 40, actor: 1, region: 'arms' }, { type: 'rally', t: 70, actor: 1, region: 'head' }, { type: 'finisher_contest', t: 90, target: 1, chance: 0.1 }]);
    const r = byId(await runTests(ctx({ default: [three] }), ['W4'])).W4;
    assert.strictEqual(r.status, 'FAIL'); assert.ok(/survival|rallies per match/.test(r.detail), r.detail);
  });
  await t('H1 fails on a hazard-caused break; H2 fails on a tier-1 hazard casualty; H3 fails on 4 fronts in frame', async () => {
    const h1 = withEvents(rec(), [{ type: 'hazard_fire', t: 5, cause: 'fire', n: 0 }, { type: 'region_broken', t: 9, actor: 1, region: 'legs', cause: 'fire' }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [h1] }), ['H1'])).H1.status, 'FAIL');
    const h2 = withEvents(rec(), [{ type: 'hazard_fire', t: 5, cause: 'fire', n: 3 }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [h2] }), ['H2'])).H2.status, 'FAIL');
    assert.strictEqual(byId(await runTests(ctx({ default: [withEvents(rec(), [{ type: 'hazard_fire', t: 30, cause: 'fire', n: 3 }])] }), ['H2'])).H2.status, 'PASS');
    const h3 = withEvents(rec({ fronts: 4 }), [{ type: 'hazard_front', t: 5 }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [h3] }), ['H3'])).H3.status, 'FAIL');
  });
  await t('W3 stays PENDING until finisher_start exists; W5 reports INFO from S1 events and bands once S2 lands', async () => {
    const s1 = withEvents(rec({ dmgByRegion: { head: 10, core: 10, arms: 10, legs: 10 } }), [{ type: 'region_broken', t: 20, actor: 1, region: 'head' }, { type: 'brink_enter', t: 25, actor: 1 }]);
    const r = byId(await runTests(ctx({ default: [s1] }), ['W3', 'W5']));
    assert.strictEqual(r.W3.status, 'PENDING'); assert.strictEqual(r.W5.status, 'INFO');
    const s2 = withEvents(s1, [{ type: 'finisher_start', t: 30, actor: 0, target: 1 }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [s2] }), ['W5'])).W5.status, 'PASS');
    const skew = withEvents(rec({ dmgByRegion: { head: 90, core: 10, arms: 5, legs: 5 } }), [{ type: 'region_broken', t: 20, actor: 1, region: 'core' }, { type: 'finisher_start', t: 30, actor: 0, target: 1 }]);
    assert.strictEqual(byId(await runTests(ctx({ default: [skew] }), ['W5'])).W5.status, 'FAIL');   // one region takes over 45% of the damage
  });
  await t('C1 and C2 stay PENDING until an evacuation event exists, then fail on an over-budget window and an over-ceiling match', async () => {
    const tl = []; for (let i = 0; i <= 100; i++) tl.push([i, Math.min(0.5, i * 0.01), 1]);          // 1% a second at tier 1: far over 2% per minute and past the 10% ceiling
    const base = rec({ casTimeline: tl });
    const r0 = byId(await runTests(ctx({ default: [base] }), ['C1', 'C2']));
    assert.strictEqual(r0.C1.status, 'PENDING'); assert.strictEqual(r0.C2.status, 'PENDING');
    const r1 = byId(await runTests(ctx({ default: [withEvents(base, [{ type: 'evacuate', t: 5 }])] }), ['C1', 'C2']));
    assert.strictEqual(r1.C1.status, 'FAIL'); assert.strictEqual(r1.C2.status, 'FAIL');
    const ok = rec({ casTimeline: [[0, 0, 1], [30, 0.01, 1], [60, 0.015, 1], [90, 0.02, 2]] });
    const r2 = byId(await runTests(ctx({ default: [withEvents(ok, [{ type: 'evacuate', t: 5 }])] }), ['C1', 'C2']));
    assert.strictEqual(r2.C1.status, 'PASS'); assert.strictEqual(r2.C2.status, 'PASS');
  });
  await t('lock-break rows: one 2.5 s break passes, a 5 s break and a repeat inside 6 s fail; hazard_telegraph alone does not switch on the hazard tests', async () => {
    const mk = evs => evaluate({ default: [withEvents(rec(), evs)] });
    const ok = mk([{ type: 'searching', t: 9, actor: 0, target: 1, kind: 'sweep' }, { type: 'searching', t: 10, actor: 0, target: 1, kind: 'lock' }, { type: 'found', t: 12.5, actor: 1 }]);
    assert.strictEqual(ok.find(r => r.id === '8.lock.median').status, 'PASS'); assert.strictEqual(ok.find(r => r.id === '8.lock.max').status, 'PASS');
    const long = mk([{ type: 'searching', t: 10, actor: 0, target: 1 }, { type: 'found', t: 15, actor: 1 }]);
    assert.strictEqual(long.find(r => r.id === '8.lock.max').status, 'FAIL');
    const rep = mk([{ type: 'searching', t: 10, actor: 0, target: 1 }, { type: 'found', t: 12, actor: 1 }, { type: 'searching', t: 16, actor: 0, target: 1 }, { type: 'found', t: 18, actor: 1 }]);
    assert.strictEqual(rep.find(r => r.id === '8.lock.gap').status, 'FAIL');
    const tele = byId(await runTests(ctx({ default: [withEvents(rec(), [{ type: 'hazard_telegraph', t: 5 }])] }), ['H2', 'H3']));
    assert.strictEqual(tele.H2.status, 'PENDING'); assert.strictEqual(tele.H3.status, 'PENDING');
  });
  await t('Stage C: 22 script tests and 6 batch checks exist, PENDING without press_ack; with the event but no script file they stay PENDING', async () => {
    const { tests } = require('./pending-tests');
    assert.strictEqual(tests.filter(x => x.stageC).length, 22); assert.strictEqual(tests.filter(x => /^SB[1-6]$/.test(x.id)).length, 6);
    const ids = tests.filter(x => x.stageC || /^SB[1-6]$/.test(x.id)).map(x => x.id);
    const none = await runTests(ctx({ default: [rec()] }), ids);
    assert.ok(none.every(r => r.status === 'PENDING'));
    const ev = await runTests(ctx({ default: [withEvents(rec(), [{ type: 'press_ack', t: 1, actor: 0 }, { type: 'availability', t: 1, actor: 0 }])] }), tests.filter(x => x.stageC).map(x => x.id));
    assert.ok(ev.every(r => r.status === 'PENDING' && /not written yet/.test(r.detail)), JSON.stringify(ev.filter(r => r.status !== 'PENDING').map(r => r.id + ':' + r.status + ' ' + r.detail)));
  });
  await t('mood and style rows: PENDING without M1 events; with them the act, band and label maths give PASS on a good match and FAIL on a bad one', async () => {
    assert.strictEqual(evaluate({ default: [rec()] }).find(r => r.id === 'mood').status, 'PENDING');
    const good = withEvents(rec({ koAt: 400 }), [
      { type: 'mood_band', t: 100, kind: 'tense', n: 1 }, { type: 'act_change', t: 120, n: 2 }, { type: 'act_change', t: 200, n: 3 }, { type: 'act_change', t: 300, n: 4 },
      { type: 'mood_band', t: 310, kind: 'frenzied', n: 4 }, { type: 'mood_band', t: 360, kind: 'tense', n: 4 }, { type: 'brink_enter', t: 350, actor: 1 },
      { type: 'style_label', t: 40, actor: 0, kind: 'rusher', text: '' }, { type: 'style_label', t: 200, actor: 0, kind: '', text: 'rusher' }]);
    const r = Object.fromEntries(evaluate({ default: Array.from({ length: 60 }, () => good) }).map(x => [x.id, x]));
    assert.strictEqual(r['mood.act2'].status, 'PASS'); assert.strictEqual(r['mood.act3'].status, 'PASS'); assert.strictEqual(r['mood.act4'].status, 'PASS');
    assert.strictEqual(r['mood.act4beforeBrink'].status, 'PASS'); assert.strictEqual(r['mood.frenzied'].status, 'PASS');
    assert.strictEqual(r['style.entries'].status, 'PASS'); assert.strictEqual(r['style.shortest'].status, 'PASS');
    const bad = withEvents(rec({ koAt: 400 }), [{ type: 'act_change', t: 60, n: 2 }, { type: 'act_change', t: 70, n: 3 }, { type: 'mood_band', t: 80, kind: 'tense', n: 3 },
      { type: 'style_label', t: 10, actor: 0, kind: 'sniper', text: '' }, { type: 'style_label', t: 15, actor: 0, kind: '', text: 'sniper' }]);
    const b = Object.fromEntries(evaluate({ default: [bad] }).map(x => [x.id, x]));
    assert.strictEqual(b['mood.act2'].status, 'FAIL'); assert.strictEqual(b['style.shortest'].status, 'FAIL');
  });
  await t('a test with events present but no body stays PENDING, never PASS', async () => {
    const r = byId(await runTests(ctx({ default: [withEvents(rec(), [{ type: 'brunt_chain', t: 5 }])] }), ['H5'])).H5;
    assert.strictEqual(r.status, 'PENDING');
  });
  await t('the band evaluator marks the Protagonist below 45% as FAIL and 50% as PASS, and lists structures by row once rows exist', async () => {
    const mk = (protagonistWins, n) => Array.from({ length: n }, (_, i) => rec({ seed: i, winner: i < protagonistWins ? 0 : 1 }));
    const swapMk = (protagonistWins, n) => Array.from({ length: n }, (_, i) => rec({ seed: i, winner: i < protagonistWins ? 1 : 0 }));
    const low = evaluate({ default: mk(30, 100), swap: swapMk(30, 100) }).find(r => r.id === '1.protagonist');
    assert.strictEqual(low.status, 'FAIL');
    const mid = evaluate({ default: mk(200, 400), swap: swapMk(200, 400) }).find(r => r.id === '1.protagonist');
    assert.strictEqual(mid.status, 'PASS');
    const rows = evaluate({ default: Array.from({ length: 10 }, () => rec({ rows: { 1: { lost: 10, n: 47 }, 2: { lost: 20, n: 60 } } })) });
    assert.ok(rows.find(r => r.id === '4.struct.row2'), 'no per-row line');
    assert.ok(!rows.find(r => r.id === '4.struct.rows'), 'the pending row should be gone once rows exist');
  });
  await t('landing rows: the 19 bands judge slide, slam, caught, water, brunt; the 20 rows (bounce class, lips, bounces, tumbles) stay PENDING until the bounce, land, left_ground or tumble_end events exist, then judge', async () => {
    const lm = (landings, fx = {}, extra = {}) => rec({ koAt: 360, fxCounts: { slide: 4, ...fx }, slides: [], impactCraters: 0, skims: 0, launches: { 'DRIVE DOWN': 30, 'CRATER SLAM': 10, 'UPPERCUT': 30, 'BUILDING SMASH': 7, 'SMASH ACROSS': 23 }, landings, landingsAll: landings, slideShort: 0, slideShortPl: 0, journeys: { n: 0, bounced: 0, bounces: 0, tumbled: 0, lips: 0 }, ...extra });
    const good = { slide: 50, slam: 15, caught: 15, water: 10, brunt: 7, bounce: 0, other: 3 };
    const rows = evaluate({ default: Array.from({ length: 40 }, () => lm(good)) }), id = k => rows.find(r => r.id === k);
    assert.strictEqual(id('5c.mix.slide').status, 'PASS'); assert.strictEqual(id('5c.mix.slam').status, 'PASS'); assert.strictEqual(id('5c.mix.caught').status, 'PASS');
    assert.strictEqual(id('5c.mix.water').status, 'PASS'); assert.strictEqual(id('5c.mix.brunt').status, 'PASS'); assert.strictEqual(id('5c.slideOfGround').status, 'PASS');
    for (const k of ['5c.lip', '5c.bounces', '5c.tumble', '5c.tech']) assert.strictEqual(id(k).status, 'PENDING', k);
    const slammy = evaluate({ default: Array.from({ length: 40 }, () => lm({ slide: 25, slam: 55, caught: 10, water: 4, brunt: 4, bounce: 0, other: 2 })) });
    assert.strictEqual(slammy.find(r => r.id === '5c.mix.slide').status, 'FAIL'); assert.strictEqual(slammy.find(r => r.id === '5c.slideOfGround').status, 'FAIL');
    const g5 = { slide: 60, bounce: 0, slam: 10, caught: 15, water: 8, brunt: 7, other: 0 };
    const r5 = evaluate({ default: Array.from({ length: 40 }, () => lm(g5, { bounce: 4, left_ground: 3, land: 8, tumble_end: 8 }, { journeys: { n: 40, anyBounce: 20, bounced: 5, bounces: 8, tumbled: 18, lips: 3 }, lips: 3, firstContact: { slide: 50, bounce: 20, slam: 10 } })) }), id5 = k => r5.find(r => r.id === k);
    assert.strictEqual(id5('5c.mix.halt:').status, 'PASS'); assert.strictEqual(id5('5c.mix.slam:').status, 'PASS'); assert.strictEqual(id5('5c.bounced').status, 'PASS'); assert.strictEqual(id5('5c.firstContacts').status, 'PASS'); assert.strictEqual(id5('5c.lip').status, 'PASS');
    assert.strictEqual(id5('5c.bounces').status, 'PASS'); assert.strictEqual(id5('5c.tumble').status, 'PASS'); assert.strictEqual(id5('5c.tech').status, 'PENDING');
    const bad = evaluate({ default: Array.from({ length: 40 }, () => lm({ ...g5, slide: 40, slam: 25 }, { bounce: 4, land: 8 }, { journeys: { n: 40, anyBounce: 40, bounced: 5, bounces: 8, tumbled: 18, lips: 0 }, firstContact: { slide: 10, bounce: 30 } })) });
    assert.strictEqual(bad.find(r => r.id === '5c.bounced').status, 'FAIL'); assert.strictEqual(bad.find(r => r.id === '5c.firstContacts').status, 'FAIL'); assert.strictEqual(bad.find(r => r.id === '5c.mix.halt:').status, 'FAIL');
  });
  await t('journey_end rows (second landing ruling): halted, wall, slam, caught, bounced launches, bounces per journey, seen flights, capped and long journeys judge good and bad mixes', async () => {
    const jm = (landings, jr, extra = {}) => rec({ koAt: 360, fxCounts: { slide: 4, journey_end: 8, bounce: 2, land: 8, left_ground: 3 }, slides: [], impactCraters: 0, skims: 0, launches: { 'DRIVE DOWN': 40, 'CRATER SLAM': 10, 'UPPERCUT': 30, 'BUILDING SMASH': 7, 'SMASH ACROSS': 13 }, landings, landingsAll: landings, slideShort: 0, slideShortPl: 0, firstContact: { slide: 50, bounce: 20 }, lips: 3, liftsSeen: { lip: 6, crest: 12 }, journeys: { n: 0, anyBounce: 20, bounced: 0, bounces: 0, tumbled: 0, lips: 0, jn: 40, jbounced: 10, jbounces: 15, capped: 2, long: 5, tumbledEnd: 16, durSeen: true, halted: 40, tumbleSeen: 16, ...jr }, ...extra });
    const good = { slide: 34, wall: 14, slam: 14, caught: 20, water: 6, brunt: 12, bounce: 0, other: 0 };   // halted 34 of 62 ground endings: 55%, in 40 to 60
    const rows = evaluate({ default: Array.from({ length: 40 }, () => jm(good, {})) }), id = k => rows.find(r => r.id === k);
    for (const k of ['5c.mix.halted:', '5c.mix.against', '5c.mix.slam:', '5c.mix.caught', '5c.largest', '5c.bounced', '5c.bounces', '5c.lip', '5c.terrain', '5c.capped', '5c.long', '5c.tumble']) assert.strictEqual(id(k).status, 'PASS', k + ' ' + (id(k) && id(k).value));
    const bad = evaluate({ default: Array.from({ length: 40 }, () => jm({ slide: 22, wall: 38, slam: 12, caught: 17, water: 6, brunt: 5, bounce: 0, other: 0 }, { capped: 10, long: 20 })) }), idb = k => bad.find(r => r.id === k);
    assert.strictEqual(id('5c.haltOfGround').status, 'INFO'); assert.strictEqual(idb('5c.mix.halted:').status, 'FAIL');   // halted 22 of 72 ground endings: 31% assert.strictEqual(idb('5c.largest').status, 'FAIL'); assert.strictEqual(idb('5c.capped').status, 'FAIL'); assert.strictEqual(idb('5c.long').status, 'FAIL');
  });
  await t('exchange endings: the launch share is judged against 25 to 35%; the knock-back share is retired (reported only), continue stays PENDING until exchange_end events give it, then judges 40 to 50; the separating share waits for C2b', async () => {
    const er = (e, extra = {}) => rec({ exEnds: e, ...extra });
    const only = evaluate({ default: Array.from({ length: 40 }, () => er({ launch: 30, other: 70 })) }), id1 = k => only.find(r => r.id === k);
    assert.strictEqual(id1('10.end.launch').status, 'PASS'); assert.strictEqual(id1('10.end.knockback').status, 'INFO'); assert.strictEqual(id1('10.end.continue').status, 'PENDING');   // the knock-back share is retired (sixth round): reported only
    const hi = evaluate({ default: Array.from({ length: 40 }, () => er({ launch: 60, other: 40 })) });
    assert.strictEqual(hi.find(r => r.id === '10.end.launch').status, 'FAIL');
    const full = evaluate({ default: Array.from({ length: 40 }, () => er({ launch: 30, knockback: 25, continue: 45 })) }), id2 = k => full.find(r => r.id === k);
    assert.strictEqual(id2('10.end.launch').status, 'PASS'); assert.strictEqual(id2('10.end.knockback').status, 'INFO'); assert.strictEqual(id2('10.end.continue').status, 'PASS'); assert.strictEqual(id2('10.end.separating').status, 'PENDING');   // waits for C2b
  });
  await t('zip rows: PENDING without zip records; a good set judges clean 35 to 55, countered, caught, ki share, price, travel, exits, no brawl without a catch; a bad set fails the hard tests', async () => {
    const none = evaluate({ default: [rec()] });
    assert.strictEqual(none.find(r => r.id === 'zip').status, 'PENDING');
    // 60 matches of 2 zips each: 120 zips, 55 clean, 18 countered (15%), 30 caught (25%), the rest done without damage
    const zipOf = (i, end, dmg, over = {}) => ({ a: 0, t: 100 + i, kind: i % 3 === 0 ? 'heavy' : 'light', tell: i % 3 === 0 ? 10 : 6, in: 8, dur: i % 3 === 0 ? 53 : 33, d0: 8, price: i % 3 === 0 ? 30 : 20, dmg, guard: 0, out: 'home', outN: 10, exitBh: 8, wayBh: 8, inside: false, end, endTicks: 40, rinP: i % 3 === 0 ? 12 : 4, routP: i % 3 === 0 ? 10 : 6, rin: i % 3 === 0 ? 12 : 4, rout: i % 3 === 0 ? 10 : 6, reading: 0, ...over });
    const ends = [];
    for (let i = 0; i < 120; i++) ends.push(i < 55 ? ['done', 30] : i < 73 ? ['countered', 0] : i < 103 ? ['caught', 0] : ['done', 0]);
    const mkRec = (j, over) => rec({ seed: j, koAt: 300, kiSpent: [1500, 1500], zips: [0, 1].map(k => { const [e, d] = ends[j * 2 + k]; return zipOf(j * 2 + k, e, d, over || {}); }), zipBrawlViol: 0, drops: { start: 1, land: 1, end: 1 } });
    const good = evaluate({ default: Array.from({ length: 60 }, (_, j) => mkRec(j)) }), g = k => good.find(r => r.id === k);
    for (const k of ['zip.clean', 'zip.countered', 'zip.caught', 'zip.kiShare', 'zip.price', 'zip.table', 'zip.reach', 'zip.travel', 'zip.brawl']) assert.strictEqual(g(k).status, 'PASS', k + ' ' + g(k).value);
    assert.strictEqual(g('zip.exit').status, 'PENDING', 'only home exits: nothing to check yet');
    const bad = evaluate({ default: Array.from({ length: 60 }, (_, j) => ({ ...mkRec(j, { price: 25, in: 2, out: 'far', exitBh: 14, inside: true }), zipBrawlViol: 1 })) }), b = k => bad.find(r => r.id === k);
    for (const k of ['zip.price', 'zip.travel', 'zip.exit', 'zip.brawl']) assert.strictEqual(b(k).status, 'FAIL', k);
    const badReach = evaluate({ default: Array.from({ length: 60 }, (_, j) => mkRec(j, { rin: 9, reading: 1 })) });
    assert.strictEqual(badReach.find(r => r.id === 'zip.reach').status, 'FAIL', 'a strike in reach 9 ticks before its blow is off the table');
    const heldOk = evaluate({ default: Array.from({ length: 60 }, (_, j) => mkRec(j, { kind: 'light', tell: 6, dur: 33, price: 20, rinP: 4, routP: 6, rin: 8, rout: 6, reading: 2 })) });
    assert.strictEqual(heldOk.find(r => r.id === 'zip.reach').status, 'PASS', 'a held strike is in reach 8 ticks before its blow');
    // few zips: the rates wait for 40
    const few = evaluate({ default: Array.from({ length: 5 }, (_, j) => mkRec(j)) });
    assert.strictEqual(few.find(r => r.id === 'zip.clean').status, 'PENDING');
  });
  await t('double hit rows: PENDING without double hits; a good set judges 0.5 to 2 a match, 40 to 70% of matches, at most 4, both hit; a bad set fails the hard tests', async () => {
    assert.strictEqual(evaluate({ default: [rec()] }).find(r => r.id === 'double').status, 'PENDING');
    const dbl = (j, n, over = {}) => rec({ seed: j, koAt: 300, doubleHits: n, brawl: { ends: { double: n, knockback: 5 }, blows: {}, staggers: {}, tradeBreaks: 0, lens: [], nblows: [] }, doubles: Array.from({ length: n }, () => ({ t: 1, dur: 240, land: 9, dmgA: 12, dmgB: 12, sep0: 1, sep30: 11, ...over })) });
    const good = evaluate({ default: Array.from({ length: 100 }, (_, j) => dbl(j, j < 55 ? (j < 20 ? 2 : 1) : 0)) }), g = k => good.find(r => r.id === k);
    for (const k of ['double.max', 'double.cue', 'double.both', 'double.trade240']) assert.strictEqual(g(k).status, 'PASS', k + ' ' + g(k).value);
    for (const k of ['double.perMatch', 'double.matchesWith']) assert.strictEqual(g(k).status, 'INFO', k + ' is reported for the AI against itself');
    const bad = evaluate({ default: Array.from({ length: 100 }, (_, j) => ({ ...dbl(j, j < 55 ? 5 : 0, { dmgB: 0 }), doubleHits: j < 55 ? 4 : 0 })) }), b = k => bad.find(r => r.id === k);
    for (const k of ['double.max', 'double.cue', 'double.both']) assert.strictEqual(b(k).status, 'FAIL', k);
  });
  await t('C1 rows: PENDING on a build with no C1; a good set passes the centre, the walk-outs and the drop; a bad set fails the hard tests', async () => {
    const { masherRows } = require('./masher');
    const base = (pair, brawl) => ({ pair, n: 60, aWins: 30, bWins: 30, timeouts: 0, medianSec: 100, zips: 0, brawl });
    const noC1 = ['c1-drift-one', 'c1-walk-both', 'c1-walk-held'].map(p => base(p, { brawls: 50, ends: { knockback: 50 }, centre: { ticks: 0, over: 0 }, drift: { n: 0 }, walk: { brawls: 0, early: 0, n: 0 } }));
    for (const r of masherRows(noC1).filter(r => r.id.startsWith('c1.'))) assert.strictEqual(r.status, 'PENDING', r.id);
    const C = { ticks: 5000, speedTicks: 5000, over: 0, maxStepBh: 0.2, posMaxBh: 0.5, posOver: 1 }, D = { n: 55, latMax: 2, latMean: 1.2, rateBhPerSec: 2.4, maxStepBh: 0.2 };
    const good = masherRows([
      base('c1-drift-one', { brawls: 60, ends: { knockback: 60 }, centre: C, drift: D, walk: {} }),
      base('c1-walk-both', { brawls: 60, ends: { walk: 55, knockback: 5 }, centre: C, drift: { n: 0 }, walk: { brawls: 60, early: 0, lagMin: 12, lagMax: 20, n: 55 } }),
      base('c1-walk-held', { brawls: 60, ends: { idle: 20 }, centre: C, drift: { n: 0 }, walk: { brawls: 0, early: 0, n: 0 } }),
      { ...base('zip-hook', { brawls: 10, ends: {}, zipEnds: { down: 12, done: 100 }, drop: { start: 12, land: 12, end: 12, stateBad: 0, endBad: 0 } }), zips: 112 },
    ]), g = k => good.find(r => r.id === k);
    for (const k of ['c1.centre.latency', 'c1.centre.step.one', 'c1.walk.both', 'c1.walk.held', 'zip.drop']) assert.strictEqual(g(k).status, 'PASS', k + ' ' + g(k).value);
    const bad = masherRows([
      base('c1-drift-one', { brawls: 60, ends: {}, centre: { ticks: 5000, speedTicks: 5000, over: 3, maxStepBh: 0.4 }, drift: { ...D, latMax: 5 }, walk: {} }),
      base('c1-walk-both', { brawls: 60, ends: { walk: 55 }, centre: C, drift: { n: 0 }, walk: { brawls: 60, early: 4, lagMin: 6, lagMax: 20, n: 55 } }),
      base('c1-walk-one', { brawls: 60, ends: { walk: 3 }, centre: C, drift: { n: 0 }, walk: { brawls: 0, early: 0, n: 0 } }),
      { ...base('zip-hook', { brawls: 10, ends: {}, zipEnds: { down: 12 }, drop: { start: 9, land: 9, end: 9, stateBad: 1, endBad: 0 } }), zips: 112 },
    ]), b = k => bad.find(r => r.id === k);
    for (const k of ['c1.centre.latency', 'c1.centre.step.one', 'c1.walk.both', 'c1.walk.one', 'zip.drop']) assert.strictEqual(b(k).status, 'FAIL', k);
    const gap = masherRows([{ ...base('zip-turret', { brawls: 10, ends: {}, zipEnds: { done: 100 }, drop: {} }), zips: 100 }]);
    assert.strictEqual(gap.find(r => r.id === 'zip.drop.bolt').status, 'PENDING', 'no zip ended down: a coverage gap, never a pass');
  });
  await t('second-pass rows: dead stick and the held stick against the AI; perfect blocks by strength, energy share and wind-ups read from cues, PENDING without them', async () => {
    const { masherRows } = require('./masher');
    const base = (pair, brawl) => ({ pair, n: 60, aWins: 30, bWins: 30, timeouts: 0, medianSec: 100, zips: 0, brawl });
    const C = { ticks: 5000, speedTicks: 5000, over: 0, maxStepBh: 0.2, posMaxBh: 0.5, posOver: 1 };
    const good = masherRows([
      base('c1-hold-one', { brawls: 60, ends: {}, centre: C, hold: { ticks: 4000, dead: 0, deadStates: {} } }),
      base('c1-drift-one', { brawls: 60, ends: {}, centre: C, drift: { n: 55, latMax: 2, latMean: 1, rateBhPerSec: 2.0, maxStepBh: 0.2 } }),
      base('c1-drift-ai', { brawls: 60, ends: {}, centre: C, drift: { n: 50, latMax: 2, latMean: 1, rateBhPerSec: 1.6, maxStepBh: 0.2 } }),
    ]), g = k => good.find(r => r.id === k);
    assert.strictEqual(g('c1.dead').status, 'PASS', 'good dead ' + g('c1.dead').value);
    assert.strictEqual(g('c1.aistick').status, 'PASS', 'good aistick ' + g('c1.aistick').value);   // 1.6 over 2.0 is 0.8
    const bad = masherRows([
      base('c1-hold-one', { brawls: 60, ends: {}, centre: C, hold: { ticks: 4000, dead: 120, deadStates: { staggered: 120 } } }),
      base('c1-drift-one', { brawls: 60, ends: {}, centre: C, drift: { n: 55, latMax: 2, latMean: 1, rateBhPerSec: 2.0, maxStepBh: 0.2 } }),
      base('c1-drift-ai', { brawls: 60, ends: {}, centre: C, drift: { n: 50, latMax: 2, latMean: 1, rateBhPerSec: 1.0, maxStepBh: 0.2 } }),
    ]), b = k => bad.find(r => r.id === k);
    assert.strictEqual(b('c1.dead').status, 'FAIL', 'bad dead ' + b('c1.dead').value);
    assert.strictEqual(b('c1.aistick').status, 'FAIL', 'bad aistick ' + b('c1.aistick').value);   // 1.0 over 2.0 is 0.5
    // the rows read from the AI's records
    const none = evaluate({ default: [rec()] });
    for (const k of ['10.energy.share', '10.windup.perMin']) assert.strictEqual(none.find(r => r.id === k).status, 'PENDING', k);
    const mk = (j) => rec({ seed: j, koAt: 300, cues: { windup: 12 }, cueText: { 'windup:start': 12, 'pbstrength:light': 5, 'pbstrength:medium': 3 }, brawl: { ends: {}, blows: { light: 450, medium: 60, bolt: 30 }, staggers: {}, tradeBreaks: 0, lens: [1800, 1800], nblows: [] } });
    const rows = evaluate({ default: Array.from({ length: 50 }, (_, j) => mk(j)) }), r = k => rows.find(x => x.id === k);
    assert.strictEqual(r('10.energy.share').status, 'PASS', 'energy ' + r('10.energy.share').value);   // 30 over 540 is 5.6%
    assert.strictEqual(r('10.windup.perMin').status, 'PASS', 'windup ' + r('10.windup.perMin').value);  // 6 over 1 minute of brawl
    assert.ok(/medium/.test(r('7.pb.byStrength').value));
  });
  await t('three-strength and playtest rows: flurries, route, giving ground, energy, burst, the double hit presser; PENDING on a build without the cues, hard tests fail on a bad set', async () => {
    const { masherRows } = require('./masher');
    const base = (pair, brawl, over = {}) => ({ pair, n: 60, aWins: 40, bWins: 20, timeouts: 0, medianSec: 100, zips: 0, brawl, stats: [{ damagePerMatch: 7000 }, { damagePerMatch: 0 }], ...over });
    const old = ['fl-xy', 'route-medium', 'give-b-free', 'energy-x', 'burst-dummy', 'mash-dummy'].map(p => base(p, { brawls: 10, blows: { light: 100 }, ends: {} }));
    for (const r of masherRows(old).filter(r => /^(flurry|route|give|energy|burst)/.test(r.id))) assert.strictEqual(r.status, 'PENDING', r.id + ' ' + r.value);
    const three = { windupN: 50, blows: { light: 100, medium: 50, heavy: 30 }, ends: {}, brawls: 600 };
    const set = (over = {}) => [
      base('fl-xy', { ...three, firstCloser: [0, 0, 1, 0] }), base('fl-yb', { ...three, firstCloser: [0, 0, 0, 1, 0] }, { aWins: 36, bWins: 24 }), base('fl-bx', { ...three, firstCloser: [0, 0, 1, 0, 0] }, { aWins: 38, bWins: 22 }),
      base('route-medium', { ...three, launcher: { open: 80, used: 80, lapsed: 0, routeBy: Array(60).fill(6), routeOn: Array(60).fill(5), firstLaunchSec: Array(60).fill(12) } }),
      base('give-b-free', { ...three, give: { n: 40, latMax: 1, heavy: { n16: 30, m16: 30, nl: 10, ml: 2 }, medium: {}, missTexts: { gave_ground: 32 } } }),
      base('give-b-follow', { ...three, give: { n: 40, latMax: 1, heavy: { n16: 30, m16: 0, nl: 10, ml: 0 }, medium: {}, missTexts: {} } }),
      base('energy-x', { ...three, energy: { bolt: 100, blast: 0, announce: { 'bolt:2': 100 }, flashes: 40, flashMax60: 3, flashMinGap: 20, src: {} } }),
      base('energy-y', { ...three, energy: { bolt: 0, blast: 30, announce: {}, kb: [4, 4.01, 3.99], flashes: 0, src: {} } }),
      base('burst-dummy', { ...three, burst: { n: 10, blows: [8, 8] } }, { stats: [{ damagePerMatch: 6600 }, { damagePerMatch: 0 }] }),
      base('mash-dummy', three, { stats: [{ damagePerMatch: 7600 }, { damagePerMatch: 0 }] }),
      base('double-lights', { ...three, doubleHits: 60, doublePer: Array.from({ length: 60 }, (_, i) => (i < 30 ? 2 : 0)) }),
    ].map(r => ({ ...r, ...(over[r.pair] || {}), brawl: { ...r.brawl, ...((over[r.pair] || {}).brawl || {}) } }));
    const good = masherRows(set()), g = k => good.find(r => r.id === k);
    for (const k of ['flurry.yb', 'flurry.bx', 'route.medium', 'route.every.medium', 'route.first30', 'route.perMatch', 'give.lat.b-free', 'give.out.b', 'give.followed.b', 'energy.bolt', 'energy.flash', 'energy.blast', 'burst.share', 'double.presser.lights']) assert.ok(g(k) && g(k).status === 'PASS', k + ' ' + (g(k) && g(k).status + ' ' + g(k).value));
    assert.strictEqual(good.find(r => r.id === 'flurry.xy').status, 'INFO', 'X over Y is reported only');
    const bad = masherRows(set({
      'fl-yb': { brawl: { firstCloser: [1, 1, 1, 0, 1] } },
      'route-medium': { brawl: { launcher: { open: 80, used: 70, lapsed: 5, routeBy: Array(60).fill(6), routeOn: Array(60).fill(5), firstLaunchSec: Array(60).fill(12) } } },
      'give-b-free': { brawl: { give: { n: 40, latMax: 5, heavy: { n16: 30, m16: 20, nl: 10, ml: 2 }, medium: {}, missTexts: {} } } },
      'energy-x': { brawl: { energy: { bolt: 100, blast: 0, announce: { 'bolt:9': 100 }, flashes: 40, flashMax60: 5, flashMinGap: 10, src: {} } } },
      'energy-y': { brawl: { energy: { bolt: 0, blast: 30, announce: {}, kb: [3, 4], flashes: 0, src: {} } } },
    })), b = k => bad.find(r => r.id === k);
    for (const k of ['flurry.yb', 'route.every.medium', 'give.lat.b-free', 'give.out.b', 'energy.bolt', 'energy.flash', 'energy.blast']) assert.strictEqual(b(k).status, 'FAIL', k + ' ' + b(k).value);
  });
  await t('perfect blocks a minute: easy 0.5 to 2.5, hard 2 to 6.5, and the order hard 1.5 x medium, medium 1.2 x easy', async () => {
    const { levelRows } = require('./bands');
    const mk = pb => Array.from({ length: 10 }, () => rec({ koAt: 300, melee: { 'TRADE BLOWS': 20 }, cues: { perfect_block: pb }, brawl: { blows: { light: 500 } } }));
    const rows = levelRows({ easy: mk(15), hard: mk(15) }), id = k => rows.find(r => r.id === k);
    assert.strictEqual(id('7.pb.perMin.easy').status, 'FAIL');   // 150 over 50 minutes: 3 a minute is over easy's 2.5
    assert.strictEqual(id('7.pb.perMin.hard').status, 'PASS');   // and inside hard's 2 to 6.5
    assert.strictEqual(id('7.pb.easy').status, 'INFO');
    const ord = (e, m, h) => levelRows({ easy: mk(e), hard: mk(h) }, mk(m)).find(r => r.id === '7.pb.order').status;
    assert.strictEqual(ord(10, 15, 25), 'PASS');    // 2.0, 3.0, 5.0 a minute: 1.5 and 1.67
    assert.strictEqual(ord(10, 15, 20), 'FAIL');    // hard 4.0 is under 1.5 x 3.0
    assert.strictEqual(ord(13, 15, 25), 'FAIL');    // medium 3.0 is under 1.2 x 2.6
    assert.strictEqual(levelRows({ easy: mk(10), hard: mk(25) }).find(r => r.id === '7.pb.order').status, 'PENDING');
  });
  await t('crossing rows: bodies into buildings 4 to 8, wall slams 1 to 3, the depth rows PENDING while depth is off', async () => {
    const { crossingRows } = require('./bands');
    const mk = (b, w) => Array.from({ length: 20 }, () => rec({ koAt: 400, landingsAll: { brunt: b }, bh: w ? { wall: { n: w, amount: 1, spd: 1 } } : {} })), id = (rows, k) => rows.find(r => r.id === k);
    const good = crossingRows(mk(5, 2)), low = crossingRows(mk(2, 0));
    assert.strictEqual(id(good, 'x.bodies').status, 'PASS'); assert.strictEqual(id(good, 'x.wall').status, 'PASS');
    assert.strictEqual(id(low, 'x.bodies').status, 'FAIL'); assert.strictEqual(id(low, 'x.wall').status, 'FAIL');
    assert.strictEqual(id(good, 'x.depth.cap').status, 'PENDING'); assert.strictEqual(id(good, 'x.depth.streets').status, 'PENDING');
  });
  await t('eleventh-round rows: the newcomer inside 60 s (75% at medium), the return reported, charged blows perfect-blocked 2 to 5% at medium, the answers rise by level, no reaction to a release and no stale mark; the beam struggle PENDING; an invalid job is not a measurement', async () => {
    const { masherRows } = require('./masher');
    const nc = (firsts) => ({ pair: 'newcomer-medium', n: firsts.length, aWins: 60, bWins: 40, brawl: { launcher: { routeBy: firsts.map(() => 5), routeOn: firsts.map(() => 4), firstLaunchSec: firsts } } });
    const ch = (c, lv, rel, pb, over = {}) => ({ probe: 'charge', probeTag: `charge-${c}-${lv}`, cell: c, level: lv, n: 60, requested: 60, wallCapped: 0, releases: rel, perfect: pb, pressBefore: pb, pressAfter: 0, sameTick: 0, pressSameTick: 0, pressAfterRelease: 0, ...over });
    const rowsOf = rs => masherRows(rs), id = (rows, k) => rows.find(r => r.id === k);
    const good = rowsOf([nc(Array(100).fill(20)), { probe: 'ret', probeTag: 'ret-striker', n: 60, requested: 60, wallCapped: 0, launches: 150, returns: 110, unanswered: 107, guarded: 2, perfect: 0, playerFirst: 1, met: 0, noReturn: 0, ranged: 3, midTicks: { median: 23 } },
      ch('b', 'easy', 590, 35, { charges: 800, stopped: 10, gaveGround: 5, stale: 0 }), ch('b', 'medium', 700, 25, { charges: 900, stopped: 90, gaveGround: 40, stale: 0 }), ch('y', 'medium', 500, 10, { charges: 0 }), ch('b', 'hard', 600, 31, { charges: 800, stopped: 200, gaveGround: 100, stale: 0 })]);
    assert.strictEqual(id(good, 'newcomer.first60.medium').status, 'PASS');
    assert.strictEqual(id(good, 'return.unanswered.striker').status, 'INFO'); assert.ok(/107 of 110/.test(id(good, 'return.unanswered.striker').value));
    assert.strictEqual(id(good, 'charge.pb.medium').status, 'PASS');   // 35 of 1,200: 2.9%, in 2 to 5%
    assert.strictEqual(id(good, 'charge.answered.order').status, 'PASS');   // easy 50 of 800, medium 155 of 900, hard 331 of 800
    assert.strictEqual(id(good, 'charge.stale').status, 'PASS');
    assert.strictEqual(id(good, 'charge.pb.easy').status, 'INFO');
    assert.strictEqual(id(good, 'charge.noreact').status, 'PASS');
    assert.strictEqual(id(good, 'beam.struggle.more').status, 'PENDING');
    const slow = rowsOf([nc([...Array(70).fill(20), ...Array(30).fill(90)]), ch('b', 'medium', 700, 245, { pressAfterRelease: 3 }), ch('y', 'medium', 500, 5)]);
    assert.strictEqual(id(slow, 'newcomer.first60.medium').status, 'FAIL');   // 70% inside 60 s
    assert.strictEqual(id(slow, 'charge.pb.medium').status, 'FAIL');   // 250 of 1,200 is 20.8%
    assert.strictEqual(id(slow, 'charge.noreact').status, 'FAIL');
    const stale = rowsOf([ch('b', 'medium', 700, 30, { stale: 12 })]);
    assert.strictEqual(id(stale, 'charge.stale').status, 'FAIL');   // 12 of 30 blocks followed a press more than 14 ticks before the blow
    const inv = rowsOf([ch('b', 'medium', 700, 50, { wallCapped: 2, invalid: true }), ch('y', 'medium', 500, 40)]);
    assert.strictEqual(id(inv, 'charge.pb.medium').status, 'PENDING');
  });
  await t('2026-10-17 rows: the building and landing bands (4 to 15, halted of ground endings, long launches off buildings, lip 0.4), the full launches (route 4 to 12, on him 4 to 10, AI v AI 6 to 12), the design list as data', async () => {
    const { masherRows } = require('./masher');
    const lc = (by, on, fby, fon, has = true) => ({ pair: 'route-medium', n: 3, aWins: 2, bWins: 1, brawl: { launcher: { routeBy: by, routeOn: on, routeFullBy: fby, routeFullOn: fon, powHas: has, firstLaunchSec: [10, 20, 30] } } });
    const id = (rows, k) => rows.find(r => r.id === k);
    const ok = masherRows([lc([8, 9, 7], [9, 9, 9], [5, 6, 4], [6, 5, 7])]), low = masherRows([lc([8, 9, 7], [9, 9, 9], [1, 2, 1], [11, 12, 13])]), none = masherRows([lc([8, 9, 7], [9, 9, 9], [], [], false)]);
    assert.strictEqual(id(ok, 'design.L16.route').status, 'INFO'); assert.strictEqual(id(ok, 'design.L16.on').status, 'INFO');   // watched, not banded (2026-10-18)
    assert.strictEqual(id(low, 'design.L16.route').status, 'INFO'); assert.ok(/1\.33/.test(id(low, 'design.L16.route').value));
    assert.strictEqual(id(none, 'design.L16.route').status, 'PENDING');
    assert.strictEqual(id(ok, 'design.B11').status, 'INFO'); assert.strictEqual(id(ok, 'design.G4').status, 'INFO'); assert.strictEqual(id(ok, 'design.G3').status, 'PENDING'); assert.strictEqual(id(ok, 'design.L1').status, 'PENDING');
    assert.ok(ok.filter(r => r.id.startsWith('design.')).length >= 84);
    // the AI v AI full launches, from the default arm's records
    const ai = pw => evaluate({ default: Array.from({ length: 40 }, () => rec({ pow: pw })) }).find(r => r.id === 'design.L16.ai');
    assert.strictEqual(ai({ has: true, n: [6, 6], full: [4, 4] }).status, 'PASS'); assert.strictEqual(ai({ has: true, n: [3, 3], full: [1, 1] }).status, 'FAIL'); assert.strictEqual(ai(undefined).status, 'PENDING');
  });
  await t('2026-10-22 rulings: the spammer answered 50 to 80% and the string launcher 20 to 50% (1b), guard and grab at the brink in 30 to 70% of matches with 1.5 times the damage of guard only (2026-10-23), the clinch median 35 to 60, max 60, time-outs under 30%, throws 2 to 5 (1c), the route bands under launch anywhere (5e)', async () => {
    const { masherRows } = require('./masher');
    const lap = (mode, extra) => ({ probe: 'lap', probeTag: 'lap-' + mode, mode, n: 60, requested: 60, wallCapped: 0, anywhere: true, wins0: 10, launchers0: 100, bySafety0: { '2': 60, '3': 40 }, fate0: { launched: 30, not: 70 }, answeredShare0: 0.70, dmgTo1: 5000 * 60, ...extra });
    const gp = (mode, extra) => ({ probe: 'gp', probeTag: 'gp-' + mode, mode, n: 60, requested: 60, wallCapped: 0, matches: 60, wins0: 20, catch: { tell: 40 }, ends: { throw_down: 30, time: 5, tech: 20 }, clinches: 55, lenMedian: 45, lenMax: 58, tellsAMinute: 2, throwsAMatch: 3, openThrows: 30, openThenLaunch: 9, openThenLaunchShare: 0.3, steps0: 50, steps1: 40, brinkMatches: 20, dmgTo1: 9000, hard: { strayStep: 0, regrab: 0, aiTechSoon: 0 }, ...extra });
    const id = (rows, k) => rows.find(r => r.id === k);
    const good = masherRows([lap('spam'), lap('route', { wins0: 30, dmgTo1: 6500 * 60 }), lap('varied', { wins0: 33, dmgTo1: 6800 * 60 }), lap('string', { answeredShare0: 0.35 }), lap('ai', { answeredShare0: 0.45 }), gp('guardgrab', { wins0: 24, hpEnd: Array.from({ length: 60 }, (_, i) => [0, i < 24 ? 0 : 800]), dmgTo1: 12000 }), gp('guardonly', { wins0: 6, hpEnd: Array.from({ length: 60 }, () => [0, 1600]), dmgTo1: 5000 }), gp('ai'), gp('mash')]);
    for (const k of ['ruling.5a.answered', 'ruling.L13.spammer', 'ruling.L14.varied', 'ruling.1b.string', 'ruling.1b.ai', 'ruling.5c.guardgrab', 'ruling.5d.median', 'ruling.5d.max', 'ruling.5d.timeouts', 'ruling.G4.tells', 'ruling.G4.throws', 'ruling.G4.chain', 'ruling.grapple.hard']) assert.strictEqual(id(good, k).status, 'PASS', k + ' ' + (id(good, k) || {}).value);
    const bad = masherRows([lap('spam', { answeredShare0: 0.40, wins0: 40 }), lap('route', { wins0: 30, dmgTo1: 6500 * 60 }), lap('string', { answeredShare0: 0.69 }), gp('guardgrab', { wins0: 10, hpEnd: Array.from({ length: 60 }, (_, i) => [0, i < 10 ? 0 : 800]), dmgTo1: 5200 }), gp('guardonly', { wins0: 6, hpEnd: Array.from({ length: 60 }, () => [0, 1600]), dmgTo1: 5000 }), gp('ai', { lenMedian: 85, lenMax: 90, throwsAMatch: 1, ends: { time: 20, time_lead: 10, tech: 10 } }), gp('mash', { lenMax: 90, hard: { strayStep: 1, regrab: 0, aiTechSoon: 0 } })]);
    for (const k of ['ruling.5a.answered', 'ruling.L13.spammer', 'ruling.1b.string', 'ruling.5c.guardgrab', 'ruling.5d.median', 'ruling.5d.max', 'ruling.5d.timeouts', 'ruling.G4.throws', 'ruling.grapple.hard']) assert.strictEqual(id(bad, k).status, 'FAIL', k);
    // every script loses (rulings-2026-10-23 7c): the rows read the damage dealt a match
    const lose = masherRows([lap('spam', { wins0: 0 }), lap('route', { wins0: 0, dmgTo1: 6500 * 60 }), lap('varied', { wins0: 0, dmgTo1: 6800 * 60 })]);
    assert.strictEqual(id(lose, 'ruling.L13.spammer').status, 'PASS'); assert.strictEqual(id(lose, 'ruling.L14.varied').status, 'PASS');
    const lose2 = masherRows([lap('spam', { wins0: 0, dmgTo1: 7000 * 60 }), lap('route', { wins0: 0, dmgTo1: 6500 * 60 }), lap('varied', { wins0: 0, dmgTo1: 8000 * 60 })]);
    assert.strictEqual(id(lose2, 'ruling.L13.spammer').status, 'FAIL'); assert.strictEqual(id(lose2, 'ruling.L14.varied').status, 'FAIL');
    const off = masherRows([lap('spam', { anywhere: false, launchers0: 0 }), gp('guardgrab', { catch: {} }), gp('guardonly', { catch: {} })]);
    assert.strictEqual(id(off, 'ruling.5a.answered').status, 'PENDING'); assert.strictEqual(id(off, 'ruling.5c.guardgrab').status, 'PENDING');
    const route = (powHas, by, on) => masherRows([{ pair: 'route-medium', n: 3, aWins: 2, bWins: 1, brawl: { launcher: { routeBy: [by, by, by], routeOn: [on, on, on], routeFullBy: [3, 3, 3], routeFullOn: [4, 4, 4], powHas, firstLaunchSec: [5, 6, 7], used: 5, lapsed: 0, open: 6 } } }]);
    assert.strictEqual(id(route(true, 30, 20), 'route.perMatch').status, 'PASS'); assert.strictEqual(id(route(true, 9, 20), 'route.perMatch').status, 'FAIL'); assert.strictEqual(id(route(false, 9, 6), 'route.perMatch').status, 'PASS');
  });
  await t('recoil flips: 2 to 6 a minute from the recoil cue, counter-rushes reported, PENDING on a build without the cue', async () => {
    const mk = (flips, cr, rc = true) => Array.from({ length: 20 }, () => rec({ koAt: 300, cues: rc ? { recoil: flips + 1, counter_rush: cr } : {}, cueText: rc ? { 'recoil:flip': flips, 'recoil:flourish': 1 } : {} }));
    const f = (D) => evaluate({ default: D }), id = (rows, k) => rows.find(r => r.id === k);
    assert.strictEqual(id(f(mk(15, 8)), 'flip.perMin').status, 'PASS');   // 15 in 5 minutes: 3 a minute
    assert.strictEqual(id(f(mk(2, 1)), 'flip.perMin').status, 'FAIL');    // 0.4 a minute
    assert.strictEqual(id(f(mk(15, 8)), 'flip.counter').status, 'INFO');
    assert.strictEqual(id(f(mk(0, 0, false)), 'flip.perMin').status, 'PENDING');
  });
  await t('the chase and the wall kick: chases a match 1 to 4 and at least 60% catch; wall kicks 1 to 4; PENDING without the cues', async () => {
    const mk = (starts, catches, kicks, start = 'city') => Array.from({ length: 20 }, () => rec({ start, koAt: 300, cues: { ...(starts ? { chase: starts + catches } : {}), ...(kicks ? { wall_kick: kicks } : {}) }, cueText: { 'chase:start': starts, 'chase:catch': catches, 'wall_kick:rush': kicks, 'wall_kick:push': 0 }, bh: { wall: { n: 1 } } }));
    const f = D => evaluate({ default: D }), id = (rows, k) => rows.find(r => r.id === k);
    assert.strictEqual(id(f(mk(2, 2, 1)), 'chase.perMatch').status, 'PASS'); assert.strictEqual(id(f(mk(2, 2, 1)), 'chase.catch').status, 'PASS');
    assert.strictEqual(id(f(mk(2, 1, 1)), 'chase.catch').status, 'FAIL');
    assert.strictEqual(id(f(mk(2, 2, 1)), 'wallkick.perMatch').status, 'PASS'); assert.strictEqual(id(f(mk(2, 2, 1, '')), 'wallkick.perMatch').status, 'INFO'); assert.strictEqual(id(f(mk(2, 2, 3)), 'wallkick.perMatch').status, 'FAIL');   // 0.2 to 2 from a city start; watched from the default start (rulings-2026-10-23 11a)
     assert.strictEqual(id(f(mk(0, 0, 0)), 'wallkick.perMatch').status, 'PENDING'); assert.strictEqual(id(f(mk(0, 0, 0)), 'chase.perMatch').status, 'PENDING');
  });
  await t('L17: the lit-B newcomer wins 10 to 50% against medium and 50 to 95% against easy', async () => {
    const { masherRows } = require('./masher');
    const nc = (lv, w) => ({ pair: 'newcomer-' + lv, n: 100, aWins: w, bWins: 100 - w, brawl: { launcher: { routeBy: Array(100).fill(5), routeOn: Array(100).fill(5), firstLaunchSec: Array(100).fill(8) } } });
    const id = (rows, k) => rows.find(r => r.id === k), ok = masherRows([nc('medium', 40), nc('easy', 80)]), bad = masherRows([nc('medium', 100), nc('easy', 100)]);
    assert.strictEqual(id(ok, 'newcomer.wins.medium').status, 'PASS'); assert.strictEqual(id(ok, 'newcomer.wins.easy').status, 'PASS');
    assert.strictEqual(id(bad, 'newcomer.wins.medium').status, 'FAIL'); assert.strictEqual(id(bad, 'newcomer.wins.easy').status, 'FAIL');
    assert.strictEqual(id(masherRows([nc('medium', 5), nc('easy', 80)]), 'newcomer.wins.medium').status, 'FAIL');   // under 10% fails too (rulings-2026-10-23c item 13)
    assert.strictEqual(id(masherRows([nc('medium', 10), nc('easy', 80)]), 'newcomer.wins.medium').status, 'PASS');
    assert.strictEqual(id(ok, 'design.L17').status, 'INFO');
  });
  console.log(`godot qa selftest: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})();

# The travel budget in the ordinary mode (Camera, 2026-10-18)

Owner: Camera and Cinematography. The EP's overnight brief: Tools' dress rehearsal (docs/tools/rehearsal-f15d7de3.md) leaves four camera-led clips over 3 with full effects (Reduce flashing off): ai RIVAL,REFERENCE 36 normal 4.5, ai 1019 normal 3.5 (and reduced 3.5 at the rehearsal's build), ai 1022 normal 3.5, ai 9 normal 3.5. Find the smallest change that brings them under 3 without taking the punch out of the ordinary mode.

## 1. What the four are

Window captures (the clip's own sim, fast-forwarded to 100 ticks before the worst second, 200 ticks drawn, tick-stepped, the fixed hook, main 0eb99564) reproduce all four rehearsal readings to the digit, and the camera trace (`render/camera/tests/clip_digest.gd --trace`) says what each is:

| clip | worst second | what the camera does there |
| :--- | :--- | :--- |
| ai 36 normal | 2910 | a riposte strip opens (2908) on a launch, and the launch chase scrolls at 0.2 of the width a tick from 2917 to 2944 (four times the bound that the reduced mode keeps at 0.03), then the hold ends in a cut at 2926 |
| ai 9 normal | 2369 | a launch begins at 2368 and the chase jolts at 0.14 a tick at 2376 and 2377 |
| ai 1019 normal | 2456 | a solo shot gives the screen back to the split view (2462 to 2471) while both panes pan at 0.03 to 0.04 a tick across textured ground: about 40,000 counted pixels every tick, an event every few ticks |
| ai 1022 normal | 2437 | the transformation's 8% punch-in (z 0.628, 0.680, 0.630 over six ticks) in both split panes |

The reduced mode is calmer on the same camera only because its calm ground has no contrast to scroll over; the ordinary mode has, and the analyser counts the scenery's motion. (In my window capture at the current main, ai 1019 reduced reads 1.5, not the rehearsal's 3.5; Rendering's changes since f15d7de3 are the likely reason.)

## 2. What was tried (normal mode, each on the four windows; readings are primary / area-15% / 2 s)

| change | 36 | 9 | 1019 | 1022 |
| :--- | :--- | :--- | :--- | :--- |
| none (main) | 4.5 / 4.5 / 2.5 | 3.5 / 3.5 / 1.5 | 3.5 / 3.5 / 1.5 | 3.5 / 3.5 / 2.5 |
| a cross-dissolve of the cuts (as the reduced mode has) | same | same | same | same |
| feathered sweeps (the switch, always) | same | same | same | same |
| feathered sweeps, extended to the solo hand-back | | | same | |
| **the travel budget at 0.045** (the existing switch, `budget=1`) | 2.5 / 2.5 / 2.5 | 2.5 / 2.5 / 1.5 | 2.5 / 3.5 / 1.5 | 2.5 / 3.5 / 2.5 |
| the budget at 0.08 | 2.5 / 2.5 / 2.5 | 2.5 / 2.5 / 1.5 | 3.5 / 3.5 / 1.5 | 2.5 / 3.5 / 2.5 |
| the budget at 0.12 | 3.5 / 3.5 / 2.5 | 2.5 / 2.5 / 1.5 | 3.5 / 3.5 / 1.5 | 2.5 / 3.5 / 2.5 |
| the budget at 0.045 with the cuts dissolving | 2 / 2 / 2.5 | 2.5 / 2.5 / 1.5 | 2.5 / 3.5 / 1.5 | 2.5 / 3.5 / 2.5 |
| the budget at 0.04 | 2.5 / 2.5 / 2.5 | 2.5 / 2.5 / 2 | 1.5 / 2.5 / 0.5 | 2.5 / 3.5 / 1.5 |
| **the budget at 0.035** | 2 / 2 / 2.5 | 2.5 / 2.5 / 2 | 2.5 / 2.5 / 1.5 | 2.5 / 3 / 1 |
| the budget at 0.045 with the transformation punch halved | | | 3.5 (a different second) | 2.5 / 2.5 / 2.5 |

The dissolve and the feathering do nothing in the ordinary mode (the changes are the camera's travel, not its cuts or its divider). The one lever that moves all four is the budget: it limits what a pane's picture does in a tick, including the punch's zoom (the budget counts half the zoom's change), so the punch keeps its shape but is eased where it spends the most pixels, and the chase's 0.2 a tick becomes a bounded sweep with a cut after TRAVEL_WAIT where it cannot keep up. At 0.045 the four read 2.5 on the primary; at 0.035 they also read under 3 on the area-15% reading, which the combined rule asks.

## 3. The change (dead, 2026-10-30: never landed; the patch is in git at 39c5f404, docs/camera/pending/travel-ordinary.patch)

It is dead because it held the ordinary mode's chase to a budget and cut when the budget lost the fighter. Orb's later calls rule that out: the launched body chased at fight size with the background carrying the speed (2026-10-19), and cuts only with a cinematography reason (2026-10-22). The numbers below are kept as a record.


Three small things, all in the ordinary mode only (the reduced mode's camera is identical tick for tick, checked by digest over ai 36, 9, 1019, 1022, collapse, rushcity and signature):

1. **The travel budget runs in the ordinary mode** (`SplitRig.travel_budget_ordinary`, default on; `SplitView.set_travel_budget_ordinary(false)` restores today's). `CamParams.TRAVEL_MAX` 0.045 becomes 0.035: at 0.045 the four read 2.5 on the primary but two read 3.5 on the area-15% reading; at 0.04 one still did; at 0.035 all four are under 3 on every reading. The switch `travel_budget` keeps its meaning (the rule in every mode, 0.03 under Reduce flashing).
2. **A pane that is opening cuts at most once in 0.3 s, not 0.1** (`TRAVEL_COOL_MORPH`). With the budget on, ai 1022's pane opening at 569 for a fighter who was flying away cut four times in 12 ticks (a cut storm: each a cut and a dip) and read 3.5 where it had read 1.5. 0.5 s broke Legal's floor for the zipper (`zip far side, split closing at 49 degrees`: off the screen 8 ticks); 0.2 and 0.3 keep it; 0.3 leaves the two cuts of the two panes and no more.
3. **The transformation's punch-in in the ordinary mode is 6% where it was 8%** (`CamParams.LIVE_PUNCH_ORDINARY`; Reduce flashing and reduced motion keep 8%). With the budget alone ai 1022's punch (z 0.628 to 0.680 to 0.630 in six ticks) was still two counted changes on the area reading (2437 and 2442); at 75% it is none and the punch is plainly still a punch.

The sweep's `scroll governor fast` row moved its bound for a fighter off the screen from 77 to 132 ticks (the reduced mode's allowance; the same synthetic pursuit measures 115 at 0.035 and 87 at 0.04): the pane now waits out a pursuit faster than the budget, as it does under Reduce flashing.

## 4. Measured, full length (normal mode, tick-stepped captures on the fixed hook, one at a time; primary / area-15% / 2 s)

| clip | rehearsal (f15d7de3) | now | where its worst second is now |
| :--- | :--- | :--- | :--- |
| ai RIVAL,REFERENCE 36 | 4.5 / 4 / 4.5 (2910) | 3 / 3 / 3 | 1486, the same 3 on main without the change (world and camera before it; not the launch chase) |
| ai 9 | 3.5 / 3.5 / 2.5 (2373) | 2.5 / 2.5 / 2 PASS | |
| ai 1019 | 3.5 / 3.5 / 2.5 (2471) | 2.5 / 2.5 / 2.5 PASS | |
| ai 1022 | 3.5 / 3.5 / 2.5 (2437) | 2.5 / 2.5 / 2 PASS | |
| collapse (1,500 ticks) | 2 / 2 / 1 | 2 / 3 / 1 PASS | |

ai 1019 reduced reads 1.5 in a window capture on main (3.5 at the rehearsal's build; Rendering's changes since are the likely reason), and the camera in the reduced mode is unchanged by this patch.

**What it costs** (`clip_digest.gd`, first 3,000 ticks, cuts / fighter-ticks outside the picture of 6,000, with the patch against without): ai 36 6 / 259 against 4 / 191; ai 9 4 / 152 against 3 / 127; ai 1019 8 / 244 against 3 / 105; ai 1022 10 / 328 against 5 / 207. The ordinary camera lags a fast chase and cuts a little more; the HUD's edge arrow stays up for a fighter outside the picture, and the pane cuts to him after 0.6 s, at most once a second. In the ordinary mode the camera changes in 17 of the 18 clips digested (ai 4, 7, 39, 43, 104, 106, PR-8, R-107, clash, clashcity, collapse, launchai, mashcity, rushcity, signature, signaturecity, transform; mash alone is unchanged), so the whole normal set needs Tools' re-read; I captured only the five above.

## 5. Gates (scratch export of the patch on c3f305b2)

Split sweep (full, real match 3 included), seam sweep, pane check, determinism plain and `--intro`, depth check and flash check: all pass. The reduced camera is the same tick for tick (digest). The other 13 render gates of the EP's set were not run here.

## 6. What did not help (so nobody repeats it)

A cross-dissolve of the ordinary mode's cuts, the feathered sweeps (also extended to a solo shot's hand-back), a halved punch alone, a looser budget (0.08, 0.12): see section 2. The ordinary camera's trouble in these clips is scenery moving past at speed over contrasty ground, not its cuts.

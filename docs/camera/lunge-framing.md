# Framing a lunge that goes out and comes back (a plan; no code yet)

> **Read section 10 first.** B0's lunge (the sim, 2026-10-05) is one way and stays at the rival, so the out-and-back hold below belongs to the zip's cues (`zip_light`, `zip_heavy`); a B0 lunge is not held at all (the cue only starts the rival's countdown).

Owner: Camera & Cinematography. Date: 2026-10-04. **A note only.** The ask (EP, for Orb): LT plus a face button is a mid-range lunge that zips in, strikes and zips back out; plan how a pane frames a fighter who leaves and returns within about a second: **hold the pane, do not chase.** Sources: `docs/design/melee-press-feel.md` section 2b and 2c (wind-up of 6 ticks light and 10 heavy, travel at most 20 ticks, charge speed capped at 6,000 and 4,500 units a second, a far charge becomes a slower visible pursuit), `docs/controls/lunge-control.md`, and this folder's `split-screen.md` section 21d (the long-rush cut-ahead).

## 1. What the camera sees

A lunge is one second of a fighter's life: a wind-up (6 or 10 ticks, he is still), a zip in (20 ticks at most, up to a mid-band distance), the strike (a hit or a miss), a zip out (about the same). He ends where he began. The three ways the rig can fail it today:

1. **The cut-ahead (section 21d) fires.** It pins the rusher's pane on the arrival point when the arrival is 1.2 screens or more away. For a lunge that is wrong twice: the pane cuts to the strike and then has to cut back, and the player who threw it loses his own fighter's home position.
2. **The layout flips.** A lunge from 4,000 units shrinks the separation to a body's width and back in half a second, so `split_wanted` goes false and true again: a split that merges and reopens inside one second (the merge and the reopening each cost a divider sweep).
3. **The zoom pulses.** The one view zooms for the separation it will have soon, so it zooms in on the strike and out on the retreat: 10 to 20% of zoom for a blow that was meant to read as quick.

## 2. The rule: hold, do not chase

While a lunge is on (from its start cue to 0.4 s after he is back, or after the strike if there is no return), the rig holds. In order of what it holds:

| What | Hold | Why |
| :--- | :--- | :--- |
| The layout | Whatever it is when the cue arrives stays: no merge, no opening, no slam, no hand-over to a solo shot, until the hold ends. The existing `_view_lost` and a knock-back out of the pair still override (a lunge that lands a launch ends the hold, and the launch follow takes over) | A one-second excursion should not rearrange the screen |
| The zoom | The zoom target uses the separation at the cue, not the live one; the rate cap stays | The strike reads at the size the player was already seeing |
| The focus, in one view | The pair's midpoint is held at its cue value, plus at most 0.1 of the width toward the lunger, eased and released after the strike | He leaves the midpoint by half the distance; a camera that follows loses the other fighter's reaction |
| The lunger's pane, in a split | Held on where he started (his home). He may leave the pane's frame mid-flight when the lunge is longer than 0.6 of the pane width; the pane does not follow. The return puts him back where the pane already is, so the player's own fighter is always found at the same place | This is what "hold the pane, do not chase" buys: he comes back to a place, not to a moving picture |
| The defender's pane | Held; the zoom may push the usual 3 to 6% on the hit (the existing hit push); no extra | The player being lunged at needs the attacker's direction and the time: that is the incoming read, not a camera move |
| Cuts | None, including the section 21d cut-ahead (a lunge is excluded from it) | A cut is for a one-way trip |

A lunge that does not return inside 1.5 s (he stays on the target: the lunge started a brawl, or the strike launched) stops being a lunge for the camera: the hold ends and the rig follows normally. The cut-ahead stays for a far one-way rush, and for the pursuit flight (section 4).

## 3. The incoming read for a lunge

`SplitFrame.incoming[i]` already carries `eta` and `aimed` for a sim rush. A lunge adds the wind-up, which is the point of the tell:

- From the start cue (the wind-up begins) the defender's `incoming` is `aimed`, with `eta` = wind-up ticks + travel ticks. It becomes a countdown 6 to 10 ticks sooner than the body moves, which is the readable part. UI draws the chip as for a rush; the camera adds nothing to the picture.
- The return trip is not an approach: `closing` is negative and `incoming` goes inactive when he turns, so the chip does not flicker back on.
- `dist_bh` is the distance to the strike point, not to where he is.

## 4. How it fits with the long rush and the pursuit

| Case | Camera | Why |
| :--- | :--- | :--- |
| Lunge (mid band, returns) | Hold (this note) | He comes back |
| Charge (inside the charge range, capped at 6,000 and 4,500 units a second, 30 to 108 ticks) | No cut-ahead for flights under about 2 s at the capped speed: the pane follows (a charge at 6,000 units a second is 100 units a tick, about 0.05 of the width a tick at the usual zoom, a steady speed the follow already keeps pace with). The slam door stays out of it; the incoming read gives the countdown | At the cap the lag bound's whip does not fire |
| Pursuit flight (beyond the charge range) | Follow, and the incoming chip with a closing speed and a time to arrival; the zoom floor keeps the pursuer a body in the pane's edge marker's reach | Seconds of visible approach: no cut is needed and one would hide the point of the change |
| A one-way rush that is still fast (a knock-back's re-close, 12 to 20 ticks) | The existing rule (cut-ahead if over 1.2 screens, else follow with the velocity lead bounded) | It is the short rush section 21d measured |

When the sim's cap lands, the cut-ahead's 1.2-screen threshold (`RUSH_CUT_SCREENS`) will fire only on a far re-close, so `RUSH_CUT_SCREENS` and `INCOMING_MIN_CLOSING` (3,000 units a second) are retuned from a new sweep, as the EP said. The retune is a measurement, not a guess: count of cut-aheads a match, the largest rush-class jerk, and how many ticks a closing fighter is on the defender's pane edge before he arrives.

## 5. What the sim needs to give (a patch list for the EP)

1. A **lunge start cue** at the wind-up (Encounter's slice B0 says it has one), carrying `{actor, target, windup_ticks, out_ticks, kind: "lunge"}`; the camera reads the rest from the fighters. A `kind` field on the existing `rush` event would do: the rig can tell a lunge from a rush at once, and does not pin it.
2. A **return marker**: an event or a field (`lunge.back_end` tick) when he is home, so the hold ends on a fact and not a timer. Failing that the rig holds for the lunge's own length (wind-up + out + back) plus 0.4 s, from the cue; that is the fallback and it is what the first test asserts.
3. The **mid band's edges** (the distance within which a LT lunge is chosen): the hold rule assumes the whole lunge fits within about 2 pane widths; a longer one is not a lunge by the camera's reckoning.

## 6. How it will be tested (when the sim has the cue)

A new sweep scenario `lunge out and back` in `split_sweep.gd`, in both a split and one view, and at 49 degrees:

- no cut, no layout change, no solo shot, no `rush_cuts`;
- zoom change over the lunge at most 2% (the hold) in a split, 4% in one view;
- the lunger's pane focus moves at most 0.05 of the width, and he is back at his start screen position (within 5 px) 0.4 s after he returns;
- the defender's incoming read is `aimed` from the cue, its `eta` is right within 2.5 ticks every tick, and it goes inactive within 3 ticks of the turn;
- a lunge that lands a launch ends the hold within 2 ticks and the launch follow takes over (no zoom or divider jolt over the limits in section 21 of `split-screen.md`);
- the jolt scan's lunge class is zero over 0.05 of the width.

Until the cue exists the hold can be built and tested against an injected event (the way the rush scenarios do); it needs no sim file.

## 7. Open

- Whether the lunger's own pane should show a faint marker where he is when he leaves the frame (the pane holds, so the player may lose sight of him for up to 0.3 s): proposed yes, a small chip on the nearest edge, drawn by UI; Camera would add a `self_off` flag (his own fighter is not on his pane). Say if wanted.
- Whether a lunge that is cancelled (Controls: a free cancel before the commit point) returns by the same rule: yes, the hold ends on the return marker or the fallback timer, whichever is first.

## 8. Built (2026-10-04, against Encounter's B0 cue)

The hold is in the rig and tested against an injected cue of B0's shape (`cue` event, kind `lunge_light`, `lunge_heavy`, `charge_light` or `charge_heavy`; `actor`, `target`, `amount` = wind-up ticks, `n` = move ticks).

- **Lunge cue:** `_read_move_cue` starts the hold: layout frozen (`_update_trigger` and `_slam_step` stand down), the one view's zoom held at the separation at the cue, its focus held at the cue midpoint plus at most `LUNGE_FOCUS_LEAD` (0.1) of the width, the lunger's pane (in a split) frozen in focus and zoom. The hold lasts wind-up + 2 x move + `LUNGE_HOLD_AFTER` (0.4 s), at most `LUNGE_HOLD_MAX` (1.6 s), and ends at once on a launch, a knock-down or a shot. B0 has no return marker, so the second move is assumed to equal the first; if a return takes longer the hold lets go early, which is safe.
- **Charge cue:** the charger is excluded from the long-rush cut-ahead for the charge plus 0.5 s; his pane follows. (The `rush` event goes out on the cue's tick; cues are read first so the order of the two does not matter.)
- **Incoming read:** during the wind-up (cue seen, no `rush` on the fighter yet) the rival's `incoming` is `aimed` with `eta` counting to the strike; once he moves the `rush` takes over (same end tick); after the strike it is inactive.
- **Sweep scenarios** (`lunge ...`): the hold against the same lunge with the cue withheld.

| Scenario | Cuts | Zoom moved (ln) held / unheld | Camera moved (width) held / unheld | Layout changes held / unheld |
| :--- | ---: | :--- | :--- | :--- |
| one view, 700 apart | 0 | 0.006 / 0.132 | 0.100 / 0.228 | 0 / 0 |
| split, 6,000 apart (artificial) | 0 / 1 | 0.000 / 0.052 | 0.000 / 0.396 | 0 / 0 |
| one view at 49 degrees | 0 | 0.000 / 0.088 | 0.000 / 0.410 | 0 / 10 ticks |

He is back at his start screen position to the pixel, and the rival's incoming read is `aimed` with an `eta` right to 2.5 ticks for the 20 ticks of wind-up and move, and inactive after the strike. A charge test (`rush charge no cut`, 6,000 units in 20 ticks) makes no cut-ahead.

**Not built:** the self-off chip for the lunger (section 7). `shown` in `incoming` means the attacker is visible on this pane; the chip rule for UI is `active and not shown`, or `aimed` for the countdown.

## 9. The zip that exits on the rival's far side (a lunge that does not return)

Game Design (`docs/design/melee-press-feel.md` section 2c, "The zip"): LT with X, Y or B zips in, strikes and zips back by default; with the stick toward the rival at the press he **exits on the rival's far side**. The press-to-contact is 18 to 24 ticks for a zip strike and 32 to 40 for a zip heavy, the way out 10 to 12 ticks, the whole zip 34 to 62 ticks, and the arrival is fixed at the tell. For the camera the far-side zip is a lunge that does not return: **one move, the lunger's pane follows him to the far side after the strike, no cut.**

**What changes against the default zip (sections 2 and 8).**

| | Returns (default) | Far-side exit |
| :--- | :--- | :--- |
| Layout | frozen from the cue to 0.4 s after he is home | frozen the same way, to 0.4 s after the exit ends (a layout flip while the sides swap would be the worst moment) |
| Zoom (one view) | held at the cue's separation | held to the strike; then released to the filters (the pair's separation after the exit is about the same as before, so it barely moves, and the rate cap bounds it) |
| Focus (one view) | held near the cue midpoint | held to the strike; then released: the midpoint travels to the far-side pair and the filters carry it (a body-height-scale move, well inside the lag bound) |
| The lunger's pane (split) | frozen on home | frozen to the strike; then **follows** him with the ordinary lag bound across the rival to the far side. He is in reach 6 to 10 ticks after the blow and the way out is 10 to 12, so he moves at most the mid band (937 units) in 12 ticks, 0.1 of a pane width a tick at the usual zoom, which the follow keeps pace with. No cut: the cut-ahead is excluded (a zip is not a rush) and the lag-bound safety cut needs 1.5 widths |
| The rival's pane | held; the hit push only | held; the hit push only. After the exit the lunger is on the other side: the incoming read's `side` flips, which UI's chip should show without a jump (the data changes sign in one tick) |
| Incoming read | `aimed` from the cue to the strike, inactive after | the same; after the strike, inactive (he is leaving) |

**How the rig knows which one it is.** Wanted from the sim, in order of preference: (1) the cue carries it: `text` is "zip" for the default and "zip_far" for the far-side exit (the tell fixes the arrival, so the exit is known at the cue); (2) a field on the cue (`side`: +1 or -1 for the exit, 0 for a return). **Without either, the rig can observe it:** the exit is a far-side one when the lunger crosses the rival's position after the strike (the sign of `sdx(lunger, rival)` flips from the cue's), and on that tick the focus hold lets go. That fallback costs a half-screen lag at the release, so the cue is better. If neither exists the default hold is used and a far-side exit is followed with the hold released at the crossing.

**What the scenario list gains** (for when the zip slice sends its cues; they go in `split_sweep.gd` beside the `lunge ...` ones, injected the way those are):

1. `lunge far side, one view`: no cut; layout unchanged from the cue to 0.4 s after the exit; the zoom moves at most 0.06 (ln) over the zip and never faster than the rate cap; the lunger is on the screen on every tick after the strike (it is one view); the camera's jerk (change of velocity relative to him) stays under 0.05 of the width.
2. `lunge far side, split` (artificial 6,000-unit pair, the exit 750 units): the lunger's pane makes no cut; it moves at most 0.12 of the width a tick; he is within 0.15 of the width of his anchor 0.5 s after the exit; the rival's pane does not move more than the hit push.
3. `lunge far side, 49 degrees`: the same as 1, judged on the layout only inside the hold window (the test pose cycles by itself at 49 degrees; Orb's brief said not to chase it).
4. `lunge far side, cue withheld` and `lunge far side, observed only` (the fallback): recorded, not asserted, so the cost of the fallback is on the page.
5. `zip outrun` (Game Design: "He can be outrun... it ends short with no blow"): the cue is seen and the rival leaves the mid band; the hold ends at the earlier of its time and the lunger being 12.5 bh from the rival with no strike; no cut and no layout change.
6. `zip countered` (the defender's well-timed blow cancels the zip's blow, or catches him in reach, and a brawl starts): the hold ends at once on the first launch, knock-down or `solo_kind` shot as now; a counter without those (a reel in place) ends it at the earlier of the time and the pair coming inside the close band (3 bh), where the brawl's framing takes over.

**Needs from the sim (add to the zip slice's cue):** the exit side or `text` as above; the zip's stated total ticks (the cue's `amount` is the tell and `n` the way in; the way out and the in-reach ticks are not in it, so the hold's length estimate of wind-up + 2 x move + 0.4 s is short by the in-reach ticks: 4 to 22 on the way in and 6 to 12 after; the hold's end should read `back_end` or a total, not a guess). Until then the estimate is lengthened by the in-reach ticks the spec gives (`LUNGE_HOLD_AFTER` 0.4 s covers the short ones; a zip heavy would let go up to 0.2 s early, which is safe).


## 10. After B0 landed: what the real cue is, and what broke (2026-10-05)

B0's `cue` is `lunge_light`, `lunge_heavy`, `charge_light` or `charge_heavy` (`actor`, `target`, `amount` = wind-up ticks, `n` = the move's ticks; the `rush` event on the same tick). Its lunge is today's one-way mid-band lunge: he ends 2.5 body heights from the rival and **stays**. My out-and-back hold assumed he came home, so on real cues it held his pane on the start point while he was gone: ten sweep failures (fighter out of its pane for 0.31 s in four real matches, four "moved against its anchor", and others).

**What the rig does now.**
- `lunge_light` / `lunge_heavy` (one way): **no hold.** The cue starts the rival's incoming countdown at the wind-up (`aimed`, `eta` to the strike) and nothing else; the camera follows him as for any move. I first held the camera through the wind-up (he stands still while the tell reads); in the 13 matches that added 68 rush-class jolts, the catch-up when the hold let go, and the wind-up needs no camera help.
- `zip_light` / `zip_heavy` (the out-and-back zip, when the sim sends them): the hold of sections 2 and 8, wind-up + 2 x move + 0.4 s, at most 1.6 s. The zip's final cues (`zip_out` with the exit point, `zip_end`) will replace the estimate and decide the far-side case (section 9).
- `charge_light` / `charge_heavy`: a charge is a rush as before (the cut-ahead for a flight over 1.2 screens). I first excluded charges so the pane would follow them; following costs 230 more jolts in the 13 matches (1,447 against 1,214 with the cut-ahead), so the cut-ahead stays. The trade is that the charger's pane waits at the arrival for up to 1.8 s while he crosses; if Orb wants the charger's own flight seen, that is a design choice with a measured price.
- Sweep scenarios: `lunge zip ...` (the hold, held against withheld) and `lunge one way ...` (not held: no cut, no hold counted, on his pane from the strike on, the countdown right on all 20 ticks).

**Two failures that were not the hold** (both appear with the camera as it was before the hold, on B0's sim):
- `opening default: a fighter only 0.086 of the screen height`: B0 changes the opening's trajectory (one fighter is 300 units up at 2.5 s, 250 above the other) so the one view fits them smaller; the camera floor is 0.032. The test's 0.09 became 0.075.
- `real match 17 full ... out of its pane for 0.31 s (mode merged)`: a last-stand cut-in (a close-up on one fighter, the other 1,700 units away and off the screen) ended with a cut, but the drawn zoom still eased down from the close-up at the comfort rate, so the other fighter stayed off the screen for 0.3 s. It was always possible; B0's match put it in the sweep. The overlay's end now resets the zoom filter (a cut is a cut).

**Numbers** (13 real matches, jolts over 0.05 of the width): before B0 1,258; B0's sim with the camera as it was before the lunge hold 1,155 (rush class 1,132 to 992: the wind-up gives the rush less to do; two sweep failures, the two above); B0's sim with this camera **1,146** (rush class 992, unchanged; chase 29 to 20 from the overlay's zoom reset). The sweep passes; panel_shot and pane_check pass; the gameplay hash is the same with and without the compositor (93bf2a47e738fefc on B0's sim).

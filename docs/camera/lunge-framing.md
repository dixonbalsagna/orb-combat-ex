# Framing a lunge that goes out and comes back (a plan; no code yet)

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

- Whether the lunger's own pane should show a faint marker where he is when he leaves the frame (the pane holds, so the player may lose sight of him for up to 0.3 s): proposed yes, a small chip on the nearest edge, drawn by UI from `shown` of the lunger's own `incoming`-style record; Camera would add a `self_off` flag. Say if wanted.
- Whether a lunge that is cancelled (Controls: a free cancel before the commit point) returns by the same rule: yes, the hold ends on the return marker or the fallback timer, whichever is first.

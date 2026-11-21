# Parked: the arrival eases a tapped LT's slip, and holds a tap at striking distance as today

Encounter, 2026-11-09, for the next build (the EP's polish brief). It goes on top of Simulation's dash-slip park (`docs/architecture/pending/dash-slip/`).

**The problem.** Controls' matrix (`docs/controls/runs/592a807b/lt-tap-probe-slip-matrix-592a807b.txt`) shows the handover with the slip on is better far but worse close: a 1 to 3 tick tap at 5.3 bh carries him 4.6 to 5.3 bh past the rival. The arrival only ran while LT was held.

**The acceptance (EP):** the matrix is no worse than today at every range and press length, and better far. Today means the handover off and the slip off, so every tap is a 13-tick dash.

**No new switch.** It acts only with Simulation's slip on (`S.slipOn`: power.json `dash.slip`, by data or a setup's `"slip"`) and the arrival on (`bands.arrive`). With the slip off, nothing is read or written, so **the golden doesn't move.**

## What changes, with the slip on

1. **The slip's carry eases into striking distance** (`DirBands.slipCarry`). Once LT is let go, the arrival keeps easing:
   - during the slip's brake (`SimPower.slipping`);
   - after it, while he is faster than his own flight's top (`flightSpeed` without the dash, scaled by the stick's own size so a diagonal counts).
   - Plain flight is never faster than that, so it is untouched.
2. **The slip's hold** (`bands.arrive.slipHoldTicks` 13; 0 turns it off). From the dash's press until 13 ticks after it, the arrival eases him into striking distance even once LT is let go.
   - Near him, a tap is a step to the mark and a beat there. That's today's close behaviour, when every tap was a 13-tick dash.
   - Far from him it changes nothing, because the ease only bites in its last 1.5 bh.
   - State: one slot after DirPace's on `f.act.dirI` (the press tick plus 1), written only with the slip on.
   - **Why the hold is needed:** with the handover, letting go sooner starts the stick's own flight sooner, and in the matrix's 60 ticks with the stick held, that flight carries him on.
     - The carry alone left every close row 0.1 to 1.2 bh worse than today. Rows 6 to 12 at 400 apart were the same with the carry read or unread.
     - No rule that only eases the carry can meet "no worse".
3. **Underticks 12** (Simulation's line, `grant-simulation-undertick.patch`): presses up to 11 ticks slip.

A trap, noted in the code's order: `SimPower.slip` counts the brake down before the arrival reads it, so `slipping(f)` is false on the brake's last tick. The carry's speed test covers that tick and the coast after it.

## The matrix

Controls' probe through the real pad (Simulation's copy, `lt_tap_probe_slip.gd`, with every press from 1 to 12). The model is on with travel 1.5, plus the dash, the kick and the arrival. The rival stands still and the stick is held toward him for 60 ticks. Distance is in bh over 60 ticks.
- **Today:** the handover off, the slip off.
- **This park:** the handover on, the slip on, underTicks 12, the carry and the hold 13.
- **Carry only:** the same with hold 0.

| Press (ticks) | 3,000 apart: today | this park | 1,000 apart: today | this park | carry only | 400 apart: today | this park | carry only |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 31.23 | **9.88** | 14.98 | **9.88** | 9.88 | 6.57 | **6.57** | 7.24 |
| 2 | 31.23 | **10.95** | 14.98 | **10.92** | 10.92 | 6.57 | **6.57** | 7.20 |
| 3 | 31.23 | **12.06** | 14.98 | **11.80** | 11.80 | 6.57 | **6.57** | 7.76 |
| 4 | 31.23 | **13.20** | 14.98 | **13.07** | 13.07 | 6.57 | **6.57** | 7.20 |
| 5 | 31.23 | **14.38** | 14.98 | **13.83** | 13.83 | 6.57 | **6.57** | 7.20 |
| 6 | 31.23 | **15.59** | 14.98 | **14.61** | 14.61 | 6.57 | **6.57** | 7.76 |
| 7 | 31.23 | **16.84** | 14.98 | **14.96** | 15.22 | 6.57 | **6.57** | 7.58 |
| 8 | 31.23 | **18.12** | 14.98 | 14.98 | 15.08 | 6.57 | 6.57 | 7.14 |
| 9 | 31.23 | **19.46** | 14.98 | 14.98 | 15.08 | 6.57 | 6.57 | 7.02 |
| 10 | 31.23 | **20.75** | 14.98 | 14.98 | 15.08 | 6.57 | 6.57 | 6.90 |
| 11 | 31.23 | **22.04** | 14.98 | 14.98 | 15.08 | 6.57 | 6.57 | 6.78 |
| 12 | 31.23 | **30.22** | 14.98 | 14.98 | 15.08 | 6.57 | 6.57 | 6.67 |
| held | 37.50 | 37.50 | 10.83 | 10.83 | 10.83 | 2.83 | 2.83 | 2.83 |
| no LT | 4.98 | 4.98 | 4.98 | 4.98 | 4.98 | 4.98 | 4.98 | 4.98 |

- **No row is worse than today.**
- **Far is better:** presses 1 to 11 carry 9.9 to 22.0 bh instead of 31.2.
- **Mid-range:** presses 1 to 6 are 0.4 to 5.1 bh shorter, and the rest equal today.
- **Close:** every press equals today.
- The slip's own bound (1.5 bh) is still not met far away. That's Simulation's and Game Design's levers (`slip.speed`, the kick's first ticks), not the arrival's.

## The check

`arrive_check.gd` keeps its 4 checks and gains 9. The new rows run with the slip on (the model, the dash and the kick, travel 1.5), from 400 apart unless a row says otherwise. Except the last three, they run with the hold at its data value, 13.
- A tap of 1 to 5 with the stick let go never comes inside the mark or passes him: closest 187.5, the mark.
- With the stick held toward him, he crosses the mark no faster than his own flight.
- Far from him (3,000 apart), taps of 1, 2 and 5, holds of 6 and 60, and a dash held all the way at 400 move exactly as with the carry unread.
- Plain flight toward him (no LT), straight and on the diagonal, moves exactly as with the carry unread.
- With the slip off, a tap moves as with the carry unread.
- Negative control, the carry unread: a tap of 1 comes to 49.3 from him (the mark is 187.5).
- Hold 13: a press of 1 to 12 with the stick held travels exactly today's 13-tick dash, 6.57 bh.
- Hold 13: a tap of 1 to 5 with the stick let go stops on the mark.
- Negative control, hold 0: a press of 1 with the stick held travels 7.88 bh against today's 6.57.

Its exit prints the same "7 ObjectDB instances were leaked" warning as Simulation's `power_check` and `two_states` with a planet-7 setup (the field world's caches). Main's own `arrive_check`, with no planet setup, has none.

## Apply

On main 20713b02 after `../../../architecture/pending/dash-slip/` (its three patches):
`git -c core.autocrlf=false -c core.eol=lf apply slip-arrive.diff grant-simulation-undertick.patch`. Each applies alone too.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `slip-arrive.diff` (`sim/director/bands.gd`, `data/director/interrupts.json` with its schema, `sim/director/tools/arrive_check.gd`) | Encounter | 0c48a290d5109e77bb94e0307ee7f2cc72939635 |
| `grant-simulation-undertick.patch` (`data/fight/power.json` `dash.slip.underTicks` 6 to 12, one number; `power_check.gd`'s three held rows read `SimPower.slipUnder` instead of 6 and 8, so they still mean "held underTicks or longer") | Simulation | ae267726d64922c21e1bf5b7cd2af768151cd9db |

## Proof

The gates ran on main 20713b02, then dash-slip's three patches, then both of these. Records are in `docs/director/runs/20713b02/slip-arrive/`, and every output went through `tools/gate.mjs` with no SCRIPT ERROR.
- **Sim lane:**
  - golden check passed (the slip is off, so the golden doesn't move);
  - validate 0 errors; self-test 10,093 of 10,093;
  - ratchet 365;
  - these checks pass: `arrive_check`, `follow_check`, `chase_tap_check`, `walk_check`, `press_decides_check`, `stick_check`, `flight_strike_check`, `outside_check`, `ending_check`, `swing_check`, `carry_round_check` and `pace_check`;
  - the core checks `power_check` (0 failed with the grant's row fix), `kick_check`, `load_split` and `two_states` (with its slip setup) pass.
- **Render:** 15 of 15.
- **With the arrival on** (`bands.arrive.enabled` flipped in scratch): `two_states` and `arrive_check` pass.
  - `power_check` fails its 4 close-time rows ("close from 1,000 / 3,000 / 6,000 ... at most 0.4 / 0.8 / 1.4 s"). They fail the same with dash-slip alone and the arrival on, without this park: they time to 1.5 bh, and the arrival stops him at 2.5 bh. That's for Simulation and Game Design if those rows should run with the arrival on.
  - It also fails "held 12 ticks at 1,000 apart: the same as off". **That's the hold:** with the slip on, a 12-tick press near him is held at the mark to tick 13, as today. It's what keeps press 12 at 1,000 apart at today's 14.98 rather than 15.08.
- **The matrix:** no row worse than today (`slip_matrix.txt`).

## NEEDS FROM EP

- **Simulation:** approve the one-number grant (underTicks 12), cut here at the EP's word, not in Simulation's re-cut.
- **Tools:** the page row `slip` (in dash-slip's Tools grant) already needs `arrive`. Nothing more.
- **Controls:** re-run the matrix on the landed commit with the handover on.

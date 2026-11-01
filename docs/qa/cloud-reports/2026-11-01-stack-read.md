# The stack, read for the pad and the globe (QA, 2026-11-01)

Brief: the EP's, for Orb's order (versus on the globe, the pad layout fleshed out). **Stack:** main dafc348f, then in order `stick-acts`, `front-dodge`, `match-ending`, `far-follow`, Combat's `stick.json` data and schema with `directions.patch`, `stick-directions`, World's `meteor-crater`, `meteor-landing`, `driver`, Simulation's `kick-keep-top`. All ten applied clean with `git apply` on a clean `git archive`. Switches: `stick.lightStops` false, `bands.follow`, `grapple`, `ending` true, and for the stack `rightStick`, the meteor arc, the beam front, the Driver, the kick (keepTop true), biome, floor, plus QA's standing overlay (launch anywhere and its answer, water, rally). Gen 2 on the ten-planet list, four touches. Scratch only; `--jobs=3`, below-normal; machine load 10 to 60%, nothing wall-capped or timed out.

## One line per read, biggest risk first

1. **Stick-only loses almost everything, and the X mash wins** (40 matches a cell, one scripted pad on the real input hub, slot 0, no guard or dodge in any arm; wins):

   | Arm | easy | medium | hard |
   | :--- | ---: | ---: | ---: |
   | X mash (every 8 ticks) | **36** of 40 | **15** | 0 |
   | Stick-only (a flick every 8 to 24 ticks, four directions) | 1 | 0 | 0 |
   | Pad mix (X, Y, B, flick, RB + X) | 1 | 0 | 0 |
   | Buttons mix (X 60, Y 25, B 15) | not run | 0 | not run |

   Game Design's band is within 10 points of the X mash: stick-only is **87.5 points under on easy and 37.5 under on medium.** This is the read before the reel-and-run rule (Encounter's, not in the stack): re-read when it is in. The masher job as the suite runs it: 97 / 42 / 0 (in band). L17 newcomer: **95% against easy (top of the 50 to 95 band, above Game Design's 82 to 92; it was 87% on 10-30) and 32% against medium (was 26%).**
2. **Game Design's new stick rows** (medium AI, 40 matches): a bot flicking only as the foe's Y or B winds up: **87% clean** (814 stuns of 931 flicks; at least 50%: met). The "no light of his on the way" variant, with my proxy of no AI light in 20 ticks: 6% (484 of 8,534); the proxy is crude and I do not read it as a miss. Stick used freely: **3.2 stuns a minute** (stick-only; at least 1: met), 1.4 with the pad mix. LB + flick on a foe not guarding, 40 ticks after the last flick: **52% stun (9,291 of 17,963; at least 60%: missed)**, and it is the best stick play, winning 6 of 40 (15%) against medium. Closes on a stick player against one who is not (trade breaks the AI closes, a minute): stick 0.00 against X mash 0.14 on medium and 0.86 on hard: fewer, met. **L17, do beginners who mash lose too many closes? No:** the X mash closes about 2 a minute (442 in 219 minutes) and the AI 0.14.
3. **far-follow does not do what pursue did, but it lifts the newcomer.** Follow on against off, same stack: newcomer against easy **95% against 87%**, against medium 32% against 29%; the route against medium 67% against 71% (pair job) and 64.5% on 200 in both; route over its masher +18.5 against +15.5 points (band 0 to 25); the X masher against medium 46% against 49%. Pursue took the route to 82% and the masher to 43%. A lever if the newcomer's 95% is too high: easy's answer share (0.25 now) back toward 0.3; not run.
4. **`keepTop` shortens an approach by 0.75 to 1.3 s** (probe, kick on, flat out at an idle rival; ticks to 1,500 / to 300 units, with against without): 6,500 apart 55 / 91 against 100 / 168; 12,000 apart 61 / 75 against 137 / 205; 24,000 apart 131 / 144 against 205 / 274; 3,000 apart 39 / 97 against 51 / 119. The AI hardly flies flat out, so AI against AI does not move.
5. **Match length with the ending on is the same as with it off: all 200 finish at the same second** (median 374.1 s = 6.2 minutes, p10 302.2, p90 507.7, longest 668). No idle player and no one at 11:00, so the ending never acts. Encounter's 9.6-minute median is not this setup and not wear tuning; ask what their 16 fights ran.
6. **RL-219 rows 3, 4, 5 cannot be read yet:** with the relief on, all 200 records are identical to the relief off (every match ends at the same second, civilians 21.4% in both, band 12 to 30). The relief never fires, most likely because the placeholder heroes have care 0 and it comes on only for a hero with care. Row 4 passes vacuously. Row 3 (hero landings on populated ground below the villain's) needs a per-landing population in the records, and row 5 (fires the same number of times within one with the civilians removed) needs a cue or counter for a firing; `DirRelief.R_FIRED` is not sent. Both are Encounter's to expose.
7. **The Driver at range is not shown to be the best play:** a bot that holds level 3 (RB + B 90 ticks) standing off wins **4 of 30 (13%)** against medium, below the X mash's 37.5%. It charged to level 3 142 times and was hit out of it 262 times (`driver_drop`, taken) and **fired no shot in 30 matches (0 `driver_fire` cues)**, so the bot may be defective, not just beaten. No case for raising level 3 to 30 ki from this; a human who steps back and times it is not this bot.

## What I did not read

Swing and nudge rows (no `DirSwing` in this stack; the PENDING rows from 10-31 stand). Slot alternation for the stick bots (all in slot 0, alike across arms). The stick in AI against AI (the AI does not use it). Hash repeats on 5 seeds.

## Validity

Load between stages 10 to 60%; every stick cell ran 40 of 40 matches, none wall-capped, none budget-stopped; the sim is seeded and the bots draw from seeded RNG. The Driver bot's first runs used a stale copy of the script and were discarded; the numbers above are from the final script.

---

SUMMARY: On the stack the Driver is not shown to be free and the ending is inert in AI against AI, but stick-only loses badly to an X mash (87.5 points under on easy, 37.5 on medium), which is the rule Encounter is adding. far-follow lifts the newcomer to 95% against easy (+8) without pursue's strength. keepTop saves 0.75 to 1.3 s of approach. The relief never fires.

CHANGES: `qa/godot/stickplay.gd`, `qa/godot/approach.gd` (new), this report.

NEEDS FROM EP: Encounter: expose a relief firing (cue or counter) and the hero's care so rows 3 to 5 can read; the reel-and-run rule for a re-read. Game Design: confirm the first values in the stick rows (the 20 tick proxy, the 40 tick string gap).

RISKS: the bots are blind (no guard or dodge): their losses are a floor for the rule, not what a person does. Slot 0 only.

NEXT: Re-read stick-only against the X mash when the reel-and-run rule is in; the easy answer share at 0.3 on the stack if Game Design wants the newcomer under 92.

## Addendum: item 1 re-read with reel-and-run (HEAD 77d0f696 + Tools' re-cut stack, signatureRtOnly and driverOnRb on)

Same bots, same switches as above plus the two Controls switches; 30 matches a cell, slot 0, jobs=3 below-normal, nothing capped. Wins of 30:

| Arm | easy | medium |
| :--- | ---: | ---: |
| X mash | 28 (93%) | 7 (23%) |
| Stick-only | **6 (20%)** | 0 |
| Pad mix | 0 | 0 |

Before reel-and-run (40 a cell, the stack above): X mash 36 / 15, stick-only 1 / 0. Stick-only moves from 2.5% to 20% on easy and stays at 0 on medium; the gap to the X mash is still 73 points on easy and 23 on medium (band: within 10). **The AI's closes on the stick player rose from 0.00 to 4.53 a minute on easy and 2.32 on medium** (the X mash: 0.04 and 0.14), so "fewer closes on a stick player" is now reversed: the stick bot builds no run, and the AI wins every trade break. Stuns a minute: stick 1.3 easy, 2.3 medium (band at least 1: met). The X mash on medium fell from 15 of 40 to 7 of 30 with this stack (a different stack, so not only reel-and-run).

**The Driver bot is not defective in its input; it is cut off.** With `driverOnRb` on it charges to level 3 (18 `charge_full` in 4 matches) and fires none: 42 `driver_drop` with text `taken` in the same 4 matches. `DirDriver.tick` drops the charge whenever an exchange is open (`S.dirS.ex != null`), and the medium AI opens one while the bot stands off for its 90-tick hold. So holding level 3 at range against the AI is not a free play here, and I cannot yet say whether it fires against a passive foe; no `driver_fire` cue was seen in 10 matches.

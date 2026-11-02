# The beam struggle's meeting point: what it does today, and a crater beneath it (World, 2026-11-02)

The EP's order, from Orb's note on Camera's tight-then-pull-back clip: "the center where the beams collide would have the biggest shockwave, possibly causing a crater underneath", and in the clip a building by the fighter on the left collapsed instead. **This is a plan and a measurement. Nothing is built or changed.** Game Design rules the numbers; the sketch below puts them in the energy model's terms so they can be set in data.

## What a struggle does to the ground and buildings today (read from `sim/director/beam.gd`)

- **While it runs, nothing.** `startClash` (206) and `_startStruggle` (247) fire no beam: the two beams you see are the renderer's, drawn from `S.game.clash.mid`. The sim does no damage, digs nothing and raises no shockwave for the 15 pulses (about 5 s). No `S.beams` entry exists for either fighter.
- **It all lands at the end, in `_resolveStruggle` (389), by how it ends:**
  - *Overwhelm* (the point reaches a fighter, 400 to 427) and *let go* (also 400): the winner fires a real beam, `fireBeam` from his hand through the loser. It carves along its path from the winner's hand (`_sampleBeamRead`: scorch and `damageArea` every 36 units from s = 0), then `_blast` at the loser (`explode`: a crater only if the point is within the blast radius of the ground, then `damageArea` over 1.8 times that radius). Everything it does is **on the winner's side first and at the loser**, never at the meeting point.
  - *Detonate* (on time, within `drawBand` 0.1 of the middle, 428 to 440): `_blast` at the meeting point. This is the only ending that touches the middle: `explode` digs a special crater by the higher tier (`explodeEnergy(tier)` times `SPECIAL_E_MULT` 9: 18 at tier 1, radius 679 units; 43 at tier 2, radius 1,052) and levels buildings within 1.8 times (70 + 32 x tier) x 8 = 816 units at tier 1.
  - *Time, further over* (441 to 448): damage to the loser as a number, **no ground, no building, no crater, no beam.**
- The older non-struggle clash (`opClashResolve`, 453) is the overwhelm shape: the winner's beam and a blast at the loser. Neither path digs under the middle.

## Measured (AI against AI, HEAD, struggle on and beam fronts on, 40 matches, 89 struggles; scratch, not in the repo)

| End | Share | Buildings hurt in the 2 s after | Crater near the meeting point |
| :--- | ---: | :--- | :--- |
| Time (the point left in one half) | 60% (53) | none, in all 53 | none |
| Detonate | 37% (33) | 13 in all, 5 down; near the point or the loser | 27 of 33 (E 18 to 43, radius 679 to 1,052); the 6 with no crater had the point 845 to 3,423 units above the ground, past the blast radius |
| Overwhelm or let go | 3% (3) | 0 | 3, under the loser |

- **During the 89 struggles: 0 buildings hurt, 0 craters dug.**
- **The point's height above the ground:** median 189 (time) to 513 (detonate); a tenth of them over 1,000. With the fronts on, the fighters stand 634 to 852 apart (median 675); with them off, 58 to 372.
- **I did not reproduce the building by the shooter.** In the 8 struggles that had a beam in the air before they began (the beam fired, then answered), no building was hurt before the clash either. So I can't say from the sim which hit it. The candidates in the code: (1) a winner's beam after an overwhelm or let-go, which carves from his own hand outward, so a building beside the winner takes its first damage; (2) the beam before the answer: `DirBeamPlay.fire` (193) puts the real beam in `S.beams`, which carves along its path as its front travels (`beamStep`), until `_answerNow` removes it; both are on the shooter's side of the point. **Send me the clip's match seed or the tick of the collapse and I'll find which.**

So the picture Orb saw is the whole design today: the middle is dug in one ending in three; everything else lands at a fighter.

## The crater at the meeting point, on the energy model

The craters' energy scalar (`sim/world/crater.gd`): a bowl's radius is `R_BASE x sqrt(E)` with `R_BASE` 160 units, depth 0.22 R, a special mark (a signature, a finisher, a beam clash) times 9. Beams already have a scalar: `beamPower(A)` is P (tier at mid-band), and a beam's own strike crater is `beamStrikeEnergy(P) = 2 P (1 + 0.4 P)`. The meeting point is where **two** beams' energy arrives, so:

**E_meet = 9 x (strike(P_A) + strike(P_D)) x f_height x f_end**, dug under the point at the ground (`WorldCrater.dig`, special).

| Both at tier | strike A + D | E_meet at height 0 | Bowl radius | Today's detonate (E, radius) | A beam's own strike crater |
| :--- | ---: | ---: | ---: | :--- | :--- |
| 1 | 2.8 + 2.8 | 50 | 1,136 | 18, 679 | 25, 800 |
| 2 | 7.2 + 7.2 | 130 | 1,821 | 43, 1,052 | 65, 1,290 |
| 3 | 13.2 + 13.2 | 238 | 2,466 | 76, 1,391 | 119, 1,745 |
| 4 | 20.8 + 20.8 | 374 | 3,096 | 115, 1,717 | 187, 2,188 |

So the meeting crater is about 1.7 times the radius of today's detonate and 1.4 times a lone beam's strike: **the biggest mark of the exchange**, in the data's own scale (the largest bowl allowed, `R_MAX`, is 8,320).

- **`f_height`:** the point is in the air. A crater under it shrinks with height: `1 - h / heightReach` (clamped 0 to 1; reach about twice the blast radius, 1,600 at tier 1). Above that it is an air burst: the shockwave ring and a scorch on the ground, no bowl. Today about one in five detonates have the point past the radius, so this matters.
- **`f_end`:** by how it ended: detonate 1.0; time 0.6 (the beams ran out in one half, the point where it stood); overwhelm and let-go 0.5 (the winner's beam already digs the loser's end; this adds the point it passed through). It is the number that makes the 60% "time" endings do something. A longer struggle could add a little per pulse (data: `perPulse`).
- **The shockwave, to buildings:** the bowl's own block fall (`WorldStructures.levelIn`, the `crater-collapse` park: buildings in the bowl fall by their height and the bowl's depth, RL-232), with `damageArea` for the rim, as `explode` has it. Falloff is from the centre, so **the middle takes the most and a building beside a shooter takes less**, which is the order Orb described. Barred landmarks are spared (RL-242, RL-243).
- **During the struggle:** a per-pulse ground cue (`WorldCrater.scorch` under the point, dust and ring events) so the shockwave is seen building rather than all at the end. The point moves, so it draws a groove, a trench, as the "catch" mark Orb liked. This is optional and cheap; the crater is one dig at the end.
- **The shooters:** the bowl is wider than the gap between them (675), so it reaches the ground under both. They are in the air, so it only matters for buildings beside them, which fall in proportion to the falloff above. A cap by the gap would make it small (about 240 units); I recommend no cap and the falloff.

## What it takes

| | |
| :--- | :--- |
| **Mine** | `data/biomes/craters.json` `struggleMeet` (`enabled` false, `heightReach`, `fEnd` per ending, `perPulse`, `minE`), its schema, `WorldCraters.struggleMeet(S, mid, how, tiers)` in `sim/world/craters.gd`, `struggle_meet_check.gd` (`STRUGGLEMEET`), a doc. About 60 lines. |
| **Encounter's: a grant** | `sim/director/beam.gd` `_resolveStruggle`: one call at its top for any ending (about 3 lines), and a call in `clashTick` per pulse for the groove (3 lines). |
| **Hash** | moves every hash that holds a struggle (the ground and buildings change); off by default behind the data switch. |
| **Cost** | one special dig at the end, like `explode`'s today; `WorldCrater.relax` is now cheap (water-cost); no new per-tick cost. |
| **Look** | the shockwave ring and dust are VFX's and Rendering's; the crater and fall are the ground's. A change to what the player sees ships with the look-gate side-by-side. |

## Questions for Game Design (the numbers are theirs)

1. `f_end`: do a time ending and an overwhelm dig a crater under the point, and how much? (A "time" ending is 60% of struggles today.)
2. The scale: 1.7 times today's detonate radius at the same tiers, or smaller (the table's multiplier is `SPECIAL_E_MULT` on both beams)?
3. Height: how high above the ground still makes a bowl (`heightReach`)?
4. Should the winner's overwhelm still carve from his hand first (today) or from the meeting point outward?

## Legal

A bigger central blast, in a street, brings down more buildings with people in them: it goes through the same civilian rules as `explode` (RL-232 for the fall, RL-242 and RL-243 for protected places). **Legal should see it before it is built**, as with `crater-collapse`.

## Order I'd build in, once Game Design rules

1. The data switch and `struggleMeet` with the check, off. 2. The grant lines (Encounter). 3. The look-gate pair (a struggle ended by time and by detonate, before and after) with VFX. 4. The per-pulse groove, if Orb wants to see it build.

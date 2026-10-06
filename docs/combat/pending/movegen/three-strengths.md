# Three strengths: the martial movesets regenerated for X light, Y medium, B heavy

Owner: Combat and Choreography. Date: 2026-10-06. Status: parked, for the slice C2a. Nothing here is loaded or hashed.
Answers `docs/design/brawl-second-pass.md` as rewritten for three strengths (`972e598`), sections 2, 3 and 8, and Orb's words in `docs/ep/vision.md` (last section).

The generator is version 9. `--check` passes (files, Legal's rows, strings) and `--self-test` passes 58 cases. Every row below is in `review-sheet.md`, which is generated.

**Since this note was first written:** Legal passed all 41 rows with conditions, and the pools by button are in `../recipes.brawl.json`. Sections 8 and 9 have both.

## 1. What changed, in one table

| | Before | Now |
| :--- | :--- | :--- |
| **X** | 30 lights | The same 30, same ids. Each now says whether it fits inside the burst |
| **X held** | nothing | **The burst:** 5 strings of 8 a fighter, one for each lean of the stick, drawn from his 30 lights |
| **Y** | 16 heavies | The same 16, same ids, **re-tagged as mediums.** Each carries the rule that says how it reads on a 12-tick wind-up |
| **B** | a frame for his signature | **10 heavies a fighter, a new tier.** None is posed |
| **B, for today** | nothing | **Stand-ins:** 5 posed pieces a fighter, that can play on B until the tier is drawn |
| **RT + B** | his release | The signature frame, with the melee art that sat on B |

- No id changed and no strike changed shape. Outside the martial arts stance only the word changed: `heavy` is `medium` on one push each and on the blows of the manoeuvre Y.
- **Rows a fighter:** rival 120 (74 posed, 21 derived, 25 waiting); Protagonist 120 (69, 26, 25). The 100 of before, plus 10 heavies, 5 bursts and 5 stand-ins.

## 2. Today's heavies as mediums, on 12 ticks

A medium follows the first rule that fits it (`parts.json` `strike.windup`). The sheet has the rule on every row.

| Rule | Fits | On Y's wind-up | What changes, or why it is flagged | Rival | Protagonist |
| :--- | :--- | :--- | :--- | ---: | ---: |
| w1 | it leaps | **held only** | both feet leave together: the gather is the wind-up, and at 12 ticks it is a hop | 1 | 1 |
| w2 | a spin | **held only** | a whole turn comes before the contact: at 12 ticks the turn is all there is to see | 1 | 2 |
| w3 | two arms | **held only** | both arms gather first, so no arm is left to start the flurry's next blow | 2 | 2 |
| w4 | a dropping kick | quick | the knee lifts on the press and the leg falls from hip height: a chop of the leg, not the full swing | 1 | 2 |
| w5 | a dropping hand or elbow | quick | no raise of its own: the arm starts at shoulder height and the body drops under it | 2 | 1 |
| w6 | a line | quick | the step in is a half step: the body leans and does not travel | 3 | 1 |
| w7 | an arc | quick | the hips turn on the press and the chamber is cut to a third: a flatter, tighter arc | 3 | 4 |
| w8 | a rise | quick | no dip first. It no longer lifts by itself: the lift is the pair X+Y | 3 | 3 |

- **Quick:** 12 of the rival's 16 and 11 of the Protagonist's. These are the tap, the Y flurry and Y on the beat.
- **Flagged, not forced** (held Y only): the rival's double hammer, spinning elbow, crossed-arm ram and drop kick; the Protagonist's double palm, drop kick, crossed-arm ram, spinning back kick and spinning heel.
- **For all 16:** a medium doesn't knock back, charged or not. Its `sends` is only the way the reel leans. The forms `ender`, `break` and the lone lift are gone with their rules.
- **Thin spot:** the Protagonist has one quick medium for the toward lean (he is a kicker), and four for away. Y at 20 with a quota for each lean would fix it; that question is with Game Design.

## 3. The heavy tier

**What makes it a tier.** A heavy is a strike shape with a **drive**: what the whole body does behind the limb. The path decides the drive, so no heavy is a medium thrown slower.

| Path | Drive | The body | Its tell, in plain sight for most of 28 ticks |
| :--- | :--- | :--- | :--- |
| line | stepping | a full pace behind the blow: the whole body travels and arrives as it lands | the striking side drawn back at shoulder height, the other shoulder pointed at the rival |
| arc in | turning | hips and shoulders wind away and unwind through the target: half a turn | his back half turned, the limb carried behind the body |
| arc out | unwinding | he shows his far side and the blow comes back out: a backhand of the whole body | the limb crossed over his own centre, the chin over the lead shoulder |
| rise | heaving | he sinks deep and both legs drive it up. His feet keep their place: it is not a leap | sunk under the rival's guard, the limb loaded below the target |
| drop | falling | he rises over the target and comes down with his whole weight | risen above the rival, the limb at shoulder height until he starts down |
| spin | spinning | one whole turn in place; never two, never travelling | the shoulders turned away, the head already looking back |

Each drive also has an **end**, where it leaves the body. That is where a flurry's next blow starts, and the director picks by it (`links`).
The tier has no headbutt (a vicious blow, which waits), no blow to a shin, and no rising hand to the jaw or head (that is where a leap creeps in: Legal's b03).

**The ten, by name.** The first eight of each list are the floor (below).

| # | The rival: a show-off | Sends | The Protagonist: pointed, not cruel | Sends |
| ---: | :--- | :--- | :--- | :--- |
| 01 | stepping fist to the chest | across | spinning blade hand to the chest | turned |
| 02 | falling heel to the chest | down | falling palm to the chest | down |
| 03 | stepping knee to the gut | across | stepping edge of the foot to the gut | across |
| 04 | turning forearm plate to the head | turned | stepping blade hand to the jaw | across |
| 05 | turning fist to the jaw | turned | unwinding edge of the foot to the gut | turned |
| 06 | heaving elbow to the jaw | up | heaving palm to the chest | up |
| 07 | heaving fist to the gut | up | heaving ball of the foot to the gut | up |
| 08 | falling hammer fist to the head | down | falling hammer fist to the arm | down |
| 09 | stepping edge of the foot to the chest | across | turning knee to the legs | turned |
| 10 | falling forearm plate to the chest | down | turning elbow to the jaw | turned |

- **The rival** is fists, plates and lines, from the front and from above, at the head and chest where it is seen. He holds the tell open with his chin up and leaves the limb out for a beat.
- **The Protagonist** is open hands, the heel and arcs, through one point of the body or a limb. His tell is compact, the turn does the work, and he is back in his guard at once. He never brings a heavy down on a head (a `never` row).
- **01 and 02 of each are pinned:** they are the four pieces Animation is already studying on provisional poses (`su_ram`, `su_heel`; `su_turn`, `su_drive`).

**How many each fighter needs.** Measured on these ten, cut down:

| Heavies | After any two blows of a mix, heavies that may follow: fewest (rival, Protagonist) | Each way of sending | Each lean of the stick |
| ---: | :--- | :--- | :--- |
| 4 | 2, 2 | not all | thin: the Protagonist has none toward |
| 6 | 3, **2** | one or two | the Protagonist has none toward |
| **8** | 4, 3 | **two each** | the rival one away; the Protagonist none toward |
| **10** | 4, 5 | two or more | two each, but one for the Protagonist's no lean |

- **A flurry of three or four:** at two blows a second every blow is read, so the bar is no piece twice in a flurry. Four is enough for that and no more: it is the same four every time. **Eight is the floor:** any four in a row differ, the check's floor of 3 holds, and a flurry can be put together 1,340 ways for the rival and 1,008 for the Protagonist. Six fails the check for the Protagonist.
- **The charged heavy** is the same pieces, held. Its knock-back goes the way the piece sends, so it needs two for each of the four ways. The first eight are exactly that.
- **The full charge** adds nothing to draw: a launch is the same piece with the director's staging, and the lift with no stick is the two that send up (the heaving pair of each fighter).
- **So: 8 a fighter to ship the tier, 10 to give every lean two.** 16 or 20 new key sets in all.

## 4. Stand-ins: what B can throw today

A posed medium that is flagged (section 2) covers the heavy of its shape, and can play on B's 28-tick wind-up now.

| The rival: 5 | The Protagonist: 5 |
| :--- | :--- |
| `strike.double_hammer`, `strike.drop_kick`, `strike.cross_arm_ram`, `strike.spinning_elbow`, `strike.spinning_heel` | `strike.double_palm`, `strike.spinning_back_kick`, `strike.drop_kick`, `strike.spinning_elbow`, `strike.cross_arm_ram` |

- They are in their own cell (`martial.b.standin`), are not locked, and go as the tier is drawn. They are not among the ten: the tier is new looks.
- **Neither fighter's stand-ins run dry.** After any two blows at least one of his five may follow. The Protagonist's spinning heel was a sixth and is left out for this (the EP's ruling): with it, a chest blow and then the heel left nothing, as his others are chest blows or spins. The fallback of section 9 stays as the net.
- Most are also his held-Y pieces: 4 of each fighter's. In C2a only B shows them, as the holds come in C2b.

## 5. The burst

A held X throws eight lights. The first is the light the press threw. Each later blow is drawn by the class of the gap before it (`parts.json` `strike.burst`).

| Gap | Class | What fits | Rival | Protagonist |
| :--- | :--- | :--- | ---: | ---: |
| 4, 4, 5 ticks | fast | a hand, on a line, an arc or a rise: no raise and no turn | 11 | 11 |
| 6, 8 | mid | the same, or an elbow or a knee | 16 | 15 |
| 11, 15 | slow | any light: a kick or a dropping blow may close it | 30 | 30 |

**What keeps a 4-tick gap from reading as a stutter:**
1. Never the same limb, tip and path twice running.
2. Never the same place twice running, so the sparks don't stack on one point.
3. No more than two blows running on one path: three straights read as one blow played three times.
4. No piece twice in one burst.
5. The hands alternate, which Animation's speed look already does.
6. The blows grow as the gaps do: hands, then an elbow or a knee, then a kick. The rival closes on a straight, the Protagonist on an arc.

- **Every one of his 30 lights can open a whole burst,** and after any first blow at least 5 (rival) and 6 (Protagonist) lights may be the second. `--check` fails if that stops being true.
- The five strings a fighter are samples the director may play whole, and Animation can study. All their blows are posed or derived lights.

## 6. The string check, by machine

After any two blows of X, Y and B that Legal's string rules allow, counted across the buttons (f02):

| May follow | Rival | Protagonist |
| :--- | ---: | ---: |
| Lights, of 30: fewest, median | 19, 28 | 19, 28 |
| Quick mediums: fewest, median | 6, 11 of 12 | 4, 10 of 11 |
| Heavies, of 10: fewest, median | 4, 9 | 5, 9 |
| Two blows drawn blind that break a rule | 6.8% | 10.2% |

The floor is 3 for each button. Each burst string is checked too: Legal's rules and the burst's own.

## 7. What others need

**Animation**
- The tier: 16 key sets for the floor, 20 for the ten. For each: the tell (held in plain sight), the blow, and its end. Names as in section 3.
- The two provisional rows below are as they stand on disk today (`data/anim/waves/rival7`, `protag10`); the generator does not read them.
- **`ru.su_ram` carries the flags `hip_chamber` and `drawn_to_hip_then_thrust`.** Legal's b02 bans the second on any strike, and b12 the first on a charged one. The lunge's fist has to load at shoulder height (the stepping drive's tell).
- **`pu.su_drive` uses both palms from overhead.** This tier's falling palm is one arm, and the limb stays at shoulder height until he starts down. Both palms held overhead is what b09 and b12 are there to stop.
- `pu.su_turn` and `pu.su_drive` are shapes the old grammar didn't have (a spinning blade hand, a dropping palm). The heavy tier has them.
- The mediums re-timed to 12 ticks with the change of their rule (section 2). The flagged ones are not re-timed.
- The burst at its gaps: the first three blows land inside the 5 ticks of the carry.
- The stand-ins played at 28 ticks.

**Tools** (schema keys, all in the parked files)
- `parts.json` `strike`: `weights`, `animWeight`, `legalWeight`, `legalForm`; a form rule may carry `reads`; `windup` (`medium`: rules with `id`, `when`, `reads`, `change` or `why`); `heavy` (`tips`, `never`, `drive`, `words`, `standIn`); `burst` (`classes`, `noStutter`). `readings` is by button and press.
- `identity.json`: a `weightsBy` row may weight `target`, `path` and `limb`; `pinned`; `burst.close`; `manner`; `reuse.stand_in`.
- `cells.json`: a cell may hold `presses` (a sub-cell for each) and `standIn`; the kind `string` (`from`, `slots`, `leans`); on a strike cell `weights`, `spread`, `notLevels`, `only`, `temporary`.
- `combat.moveset/1`: a weight may be `medium`; a medium has `wind`; a heavy has `drive` and `name`; a `string` cell's rows have `lean`, `blows`, `slots`; a `temporary` cell; `review` may be `stand-in`; `keys.level` may be `stand_in`. Ids may have a third part: `mv.rival.martial.x.hold.01`, `mv.rival.martial.b.standin.01`.

**Legal**
- The list is the section "New looks for Legal: three strengths" of `review-sheet.md`: 41 rows when Legal screened it, 40 now that one stand-in is dropped. Six drives, 20 heavies, 11 stand-ins (now 10) on a longer wind-up, the burst, the mediums on 12 ticks, and how each fighter throws a heavy.
- **Rows written for two weights.** b12 names `heavy` and `held`. I apply it to mediums and heavies, and to the form `charged`, so nothing is loosened by the new words. Legal to confirm, or to re-word the rows.
- **Two conditions were mine, proposed:** W1 (a heavy's wind-up is judged as a held pose) and U1 (the burst). Legal adopted both (section 8).
- **To look at first:** the falling drive (the limb must not be held raised), the heaving elbow to the jaw (b03 names hands only), and the stepping blade hand to the jaw.

**Encounter**
- The stand-in fallback (section 4), and the count for s01 at run time, as before.
- The pools by button are in `../recipes.brawl.json` (section 9).

## 8. Legal's screen, carried in

Legal passed all 41 rows with conditions (`docs/legal/three-strengths-screen.md`, `bb6fc1e`). Its file is merged again, and no row of mine stopped passing.

| Legal's row | What it is | What the generator does |
| :--- | :--- | :--- |
| b12, reworded | names medium and heavy, held and charged | read as written; my alias for the old words is removed |
| b03, widened | a rising blow with a leap or a spin, now by hand, elbow or knee | **refuses a match.** The row still lists only a hand's tips, so I read it as binding an elbow or a knee whatever its tip. Stricter than the letter |
| h05 (my W1, adopted) | a wind-up of 12 ticks or more is a held pose: never at a hip for any hand state, never both hands together, no limb held raised | **refuses** a medium or a heavy whose key set carries one of those flags; the rest is the condition W1, now on every medium and heavy |
| h06 | the heaving drive's sink and the falling drive's rise | the conditions D4 and D5; both drives are **seen drawn first** |
| h07 | a manner is a way of throwing, not a gesture | in the rival's manner: the limb stays drawn back, and he leaves it out 12 ticks or fewer |
| f01, restated | ghosts by instant: at most 2 of any limb and 4 in all | a condition for VFX, in U1 |
| f04 | a gap under 6 ticks runs for 3 blows at most, in a burst's opening only | **checked:** no burst has more than three fast slots running |
| f05 (my U1, adopted) | the burst's rules | **checked:** the burst's four rules are the row's |

**Conditions on the rows, now in the sheet's Legal column:**
- D1, a stepping heavy: the lead hand open or in guard, never a pointing finger.
- D2, a turning heavy: half a turn, never more.
- D3, an unwinding heavy: one arm crosses his centre, never both.
- D4, a heaving heavy, and D5, a falling heavy: as h06. D5 also says one arm only, which is Legal's note on the Protagonist's falling palm.
- L1 now sits on every rising blow by hand, elbow or knee: no leap, no turn, the limb lowers at once. That covers the heaving palm, the heaving fist and the heaving elbow.
- L8 on the stepping blade hand to the jaw: a strike, never a grip. It was there already.
- B1, on every stand-in: a held pose on the longer wind-up. A double hammer or a double palm keeps its hands shoulder width apart and at or below the shoulder, with a raise overhead only in the last 6 ticks, **or it is dropped as a stand-in;** a crossed-arm ram crosses only for the strike; a spin is one turn in place.

**For Legal, one thing:** b03's `tip` list still names only fist, palm and heel. By the letter it cannot match an elbow or a knee. I read it the strict way; adding their tips to the row would make the file say it.

## 9. The pools by button, for Encounter

In `../recipes.brawl.json`, which is still the live recipes plus what is parked. The pools for Y and B come from the generated movesets, so they keep to each fighter's identity.

| Press | `brawl` key | Pool | Rival | Protagonist |
| :--- | :--- | :--- | ---: | ---: |
| X tapped; with the stick toward | `light`, `lightToward` | `combo.link`, `blur.toward` (live) | 18, 4 | 20, 4 |
| X mashed; on the beat | `flurry`; `skill`, `juggle` | `brawl.flurry`; `brawl.skill` | 9; 9 | 10; 10 |
| Y tapped, mashed, on the beat | `medium` | `brawl.medium`: the mediums that read on 12 ticks | 10 | 10 |
| Y held (C2b) | `mediumHeld` | `brawl.medium.held`: every medium | 14 | 14 |
| B tapped, mashed, on the beat, held | `heavy`, `heavyHeld` | `brawl.heavy`: **the stand-ins** | 5 | 5 |
| X+Y (C6a) | `lift` | `brawl.lift`: the rising mediums | 3 | 3 |
| X held | the `burst` block | `burst.fast`, `burst.mid`, `burst.slow` | 8, 13, 27 | 8, 12, 24 |

- The counts are posed strikes only. A derived move (a posed key set with another hand or aim) has no strike id of its own, so 2 mediums and 3 or 6 lights a fighter are not in these pools.
- 21 pieces rows are added for the strikes of Animation's later packs (`rival4`, `protag7`). One path was re-read from Animation: the crossed-arm ram travels a line.
- `brawl.break` and the ender are gone with their rules.
- **The burst:** `slots`, the pool for each class of gap, four `rules`, each fighter's `close`, and one sample for each lean. On the pieces table a row has no tip, so its first rule is "never the same limb on the same path twice running", which is stricter than f05. Every light a tap can throw can open a whole burst (16 for the rival, 20 for the Protagonist), and `--check` tests that and every sample.

**The fallback, stated in the file.** No press is silent. Three steps, in order:
1. `pool`: a piece of the press's pool, not one of his last two, inside Legal's string rules.
2. `repeat`: one of his last two again, the older first, when Legal's rules allow it. This is the EP's default.
3. `lower`: a piece of the pool one strength down, on this button's wind-up and at its worth. A medium for a heavy.

Legal's rules are never dropped.

**Where B runs dry on stand-ins: nowhere, now.**
- **Neither fighter's five run dry.** After any two blows of his three pools at least one stand-in may follow.
- **The Protagonist had a sixth, the spinning heel, and it is dropped** (the EP's ruling, both halves: drop it, and keep the fallback as the net). With it he had none in 13 of 1,200 histories and in 3 mashed-B strings: a double palm, a drop kick or a crossed-arm ram, then the heel. Both blows landed on the chest, and his others were chest blows or spins.
- Repeating did not save any of those: the repeat would have been a third blow to the chest (s02) or a spin after a spin (s04). That is why the third step exists, and why it stays.
- The tier's ten never run dry either: after any two blows at least 4 of the rival's and 5 of the Protagonist's may follow.

**For Tools,** beyond section 7: in `combat.recipes/1`, `brawl` gains the keys `medium`, `mediumHeld` and `heavyHeld` and loses `ender` and `break`; two new blocks, `burst` (`slots`, `pools`, `rules`, `close`, `samples`) and `fallback` (`steps`, `lower`, `heavyOnStandIns`); pool names may have three parts (`brawl.medium.held`).

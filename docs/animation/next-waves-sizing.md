# The next waves, sized (2026-10-06)

Owner: Animation. Two lists, as the EP asked: what Combat's generator needs from Animation for the other four stances (`docs/combat/pending/movegen/README.md` section 3 and `review-sheet.md`), and the ten gesture intents Narrative's intro plotlines need (`docs/narrative/dynamic-intros.md` section 11). **No build yet.** Sizes are counts of poses, code slices and review passes, not days: a pose is three lines of spec over an existing base, a slice is one change in `render/anim` with a test in `anim_check`, a review pass is a lab GIF and a pose lint. Every wave is parked like the rest (baked only with `--waves`), every pose is lint-clean and joint-limit-clean before it is reported, and nothing goes live without Legal's eye.

## 0. The look Combat asked for: rival X 20, the backfist re-aimed to the jaw

`art/animation/review/reaim-rival-x20-backfist-to-the-jaw.png` (the backfist at its own target, the head, above; to the jaw below, four frames each). It **lands** (gap 0.0, nothing clipping, no joint past its limit), the arm is a little lower and the chest turned a little more, and it reads as the same backhand. The `edge` mark is the arm's bend: more than 1.2 radians away from the authored one's change at the head, which is the number's job, not a break in the silhouette. **Keep it as a derived move**; no new key set.

## 1. List A: the other four stances

What is already posed and needs nothing: the 15 entries a fighter (`pe.*`, `w2.*`: dash, hop back, plant coil, coil spring, skid, spiral, arc dive, pivot, cartwheel step, air roll, rising and the rest), the strikes the zips and the specials land, the tackle, lift and throw (`pair2`), the reversal and the swat, the energy hands, the volley fan and brace, the pushed fighter's slide (`s3.shoved`), the mine lay and the shove.

| Need (stance, cell) | What exists | What is new | Size |
| :--- | :--- | :--- | :--- |
| **Dash, fade and lane step at zip speed, drawn the whole way** (manoeuvre X, Y) | the entries, as sequences of poses over 10 to 40 ticks | **code**: the zip's in and out phases play a named entry sequence over their ticks (`entry` and `exit` on the spec: `pe.spiral` in, `pe.pivot` out, as Combat's rows name them), through the entry layer that already compresses a sequence into a duration. **Review**: all 15 entries a fighter at 4 to 10 ticks, drawn on every tick (Legal's floor), re-timing any whose poses are too far apart to read in that time. No new pose expected; up to about 6 in-between poses if a few entries need them | 1 code slice, 1 review pass of 30 GIFs, 0 to 6 poses |
| **A pass to the far side** (manoeuvre X, Y) | the run, the facing turn, `arc_dive` and `air_roll` (over), `pivot` and the lane step (round) | the same code slice: a far-side exit plays an over or a round entry with the rival in view; nothing hides | in the slice above |
| **The snatch on the fly, the dive grab** (manoeuvre A) | the tackle pose, the lift | the grab family's reach and hold, from wave 4 (Combat's `wave4-grabs.md`: 16 pieces, **22 new poses**, 2 more held for the tail) | the grab wave below |
| **A braced pose for the short beam** (energy Y) | the beam charge and release poses, the aim layer | per fighter a braced hold (feet set, both arms forward, the body low) and its release: **4 poses**; a role `short_beam` in `pair_live.json` | 4 poses, 1 data row each |
| **The split's second release** (the rival's energy Y) | the release pose | a second release (the other hand) and the in-between: **2 poses** | 2 poses |
| **An aimed lob of a mine** (energy A) | `pg.lob`, `rw.lob` (a lob thrown ahead and down) | aimed through the aim layer already used for beams (the arm follows the sim's aim angle): **code**, no pose | 1 small code slice |
| **The Protagonist's flat palm as an energy hand** (energy) | `pn.hold.palm_thrust` and open hands everywhere | check only: the flat open palm on the three energy casts he uses, **0 to 2 poses** | 0 to 2 poses |
| **The guard layer a check is thrown over** (defensive X) | `stance.defensive`, the strike key sets | **code**: while a check plays, the non-striking arm holds the defensive stance's guard (a mask on the pose, the striking arm's chain free). No new pose | 1 code slice |
| **A push as a strike key set with no impact snap** (defensive Y) | the strike key sets a push reuses | **data**: a fourth press style `push` (no snap on contact, a long follow-through, a body drive); the beat's `style` names it. No pose | 1 data row, 1 small slice |
| **The guard throw** (defensive A) | none | the throw family of wave 4 serves it (a throw from a guard: a re-timed load) | the grab wave below |
| **Each special's cuts** (charging X, Y, A) | the entries, the strikes (haymaker, roundhouse, spinning heel and elbow), the volley fan and brace, the lob | the rival's three specials: the **cutting step** (a tell and a mark: **3 poses**), the **barrage** placements (in the air, skimming, braced off a wall: **3 poses**), the **grip and drag** (the drag and its dragged fighter, the pull-down, the spike: **5 poses**). The Protagonist's three **placeholders**: the turning step (the entries and blows exist: **1 pose**), the curving three (**2 poses**), the turn aside (the redirect and the passed fighter: **4 poses**). About **18 poses**, and the frame of each, **8 sequences** | 18 poses, 8 sequences, 2 waves |
| **A second look for each grab and throw** (martial A) | wave 4's specs (Combat) | the 22 poses above | the grab wave |

### The waves, in the order I would build them

| Wave | Holds | Poses (new) | Code | Needs first |
| :--- | :--- | ---: | :--- | :--- |
| **`pair3`** (shared, prefix `zq`) | the grab family: reach, lunge, hold, 7 throws, tackle variants, dive grab, reversal, the guard throw | 22 (24 with the tail) | the grab layer (a held fighter's pose and rise, as `zip_held` does now) | Orb on the tail |
| **`protag10`, `rival7`** (energy) | the braced short beam, the split's second release, the flat palm check | 6 to 8 | `short_beam` roles, the aimed lob | Simulation's short beam as a shot kind |
| **`protag11`, `rival8`** (charging) | each fighter's three specials' cuts | 18 | none beyond sequences | Game Design: which special on which button; the Protagonist's specials are placeholders |
| **the zip slice** | the entries at zip speed, the far-side pass | 0 to 6 | the entry slots on the zip spec; the push press style; the check's guard layer | nothing: it can go first |

About **46 to 56 poses** in all (about 20 ms of bake), **4 code slices**, and the grabs are half of it. Order: the zip slice first (nothing blocks it and it finishes the zip), then the grabs (they serve four cells), then the energy additions, then the specials once Game Design places them.

## 2. List B: the ten gesture intents (the intro plotlines)

A gesture intent is a meaning; each fighter plays it his own way, and a missing one is a silent skip. The launch pair, intent by intent (what plays today, and what is new):

| Intent | The Protagonist | The rival |
| :--- | :--- | :--- |
| **acknowledge** | `pg.taunt_nod`, at half weight (a slow nod, no challenge) | **new:** a short chin dip, eyes on the other |
| **appraise** | **new:** a slow head-to-toe look, the head pitching down and up | `rw.taunt_head_tilt` |
| **dismiss** | **new:** the head turned away and a small shake | `rw.taunt_back_turned` (or `taunt_dust_plate`) |
| **defer** | **new:** a short bow from the waist, hands open at his sides | **new:** a half bow, the plate hand laid across the coat |
| **brace** | `in.hold.tense` (the intro's tense hold) | `in.hold.tense` |
| **ease** | `pg.taunt_bounce` (the shoulders loosening), at half weight | `rw.taunt_dust_plate` |
| **claim** | **new:** the feet planted wide, the chest up, a breath | `rw.taunt_stillness` |
| **check** | **new:** a glance up and aside, the chin lifted | **new:** a glance down at the cuff, then up |
| **soften** | **new:** the shoulders dropping, both open palms turning up a little | **new:** the guard hand dropping, the head tilting back |
| **harden** | `pg.taunt_fist_palm` | `rw.drop_the_act` |

Four of the ten exist for the Protagonist and six for the rival (ten of the twenty, played as they are, some at a lower weight). **Ten are new: six for the Protagonist, four for the rival.** Each new one is a small motion of 12 to 24 ticks, two poses (the peak and the settle), played over whatever idle the fighter is standing in by a mask on the head, neck, spine and arms, so it works over every waiting idle (impatient, patient, bored) without redrawing the legs: **about 20 poses**, in `protag9` and `rival6`.

**Code:** one slice: `intro_gesture {actor, intent, at}` (Encounter's new event) starts the fighter's sequence for the intent from a table in `pair_live.json` (`gestures`: intent to sequence, per fighter); a fighter without the entry plays nothing. The sequence layer, the mask and the taunt gates already exist. **Review:** a GIF of each intent on each fighter over the three idles, and Legal's eye on `harden`, `claim` and `dismiss` (the stacking rule: no fist raised, no hand at the hip, no beckon, no crossed arms).

**For the other ten fighters:** each needs the same ten, and the table is the work list: with all twelve, 120 gestures. Reuse is the lever: eight of the intents (`acknowledge`, `appraise`, `defer`, `ease`, `claim`, `check`, `soften`, `brace`) are head, shoulder and hand motions that the body kit retargets by name across all humanoid builds (Orb: close to all humanoid), so a fighter's own version is a profile (a weight, a hand, a lean) and not a redraw; `harden` and `dismiss` carry a fighter's personality and are authored per fighter.

## 3. What I need to start

- **From Combat:** the specials' placement as Game Design rules it, and the grab list as it stands (the 16 pieces and the tail).
- **From Narrative and Encounter:** the gesture event and its timing points (`land_first`, `land_second`, `look_start`, `look_end`), and the ten intents as final.
- **From Game Design:** which special is on which button; the Protagonist's real specials.
- **From Orb:** the tail's ruling (it holds 2 grab poses), and a look at the ten gestures once drawn.

Idle until told which wave first; the zip slice can start at once.

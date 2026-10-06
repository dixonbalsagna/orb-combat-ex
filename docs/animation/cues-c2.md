# The next chain's cues, the closing rule and the held charge: what Animation built against Encounter's names (C2a and C2t)

Owner: Animation. Date: 2026-10-06. View only: the sim side does not exist yet, so every handler is tested with cues made in `anim_check` (`_test_c2_cues`). Names: `docs/director/brawl-plan.md` section 10.3. Render only; the gameplay hash is untouched.

## 1. Cues

| Cue | What the body does | Where |
| :--- | :--- | :--- |
| `launcher_open` (actor the fighter who may launch, target the staggered one, `n` the tick the stagger ends, text its kind) | The target plays a **plain stagger** for the ticks it lasts: the push (head snapped back, arms flung up for an instant), then doubled over and dazed, the arms hanging low in front a shoulder width apart, the head down, then the head lifting and the guard returning. A `fit` sequence of the wave `launch1`: `lq.open`. The actor carries `launcher` for VFX and the tools. | `AnimFighter.on_launcher_open` |
| `launcher_close` (text used or lapsed) | Clears the cue; on `used` the stagger look is dropped so the launch's tumble starts from the body as it is | `on_launcher_close` |
| `miss` (text gave_ground, reach or dodge; `n` the ticks he is open) | The attacker's blow goes through empty air and he is off balance and open for `n` ticks: a fit sequence of the wave `miss1`, one for each word (`mi.gave_ground`: stumbling on after a blow that fell short; `mi.reach`: the arm stretched at nothing, one foot lifting, the other arm out for balance; `mi.dodge`: carried on past him bent forward, the head turned back over the shoulder) | `on_miss` |
| `windup` (text start with `source`, `dur`, `n`; text end with `k` 1 thrown, 2 stopped, 3 lost, 4 miss) | Kept as `windup_cue` for VFX and the tools. The body already winds up from the blow's beat, and ends with it | `on_windup` |
| `double_hit` | Kept as `double_cue`. The two blows are ordinary strike beats (`double` true, `style` `tech`): two existing straight blows play until the double hit has poses of its own (**not posed**: both punching each other in the face is still to be drawn) | `on_double_hit` |
| `energy_reach`, `energy_land` | Kept as `energy_cue` for VFX; the blow itself is the key set the beat names (`pk.*`, `rk.*`) | `on_energy` |
| `blow` with `flurry` true and a `strength` | **A flurry blow's strength picks its style** (`data/anim/press_styles.json` `strength`: light to speed, medium to medium, heavy to super, bolt to speed, blast to medium); a beat with `burst` true plays the burst style. The text `flurry` is not read | `_press_style` |

The sequences are `fit` sequences: their phase weights divide the ticks the sim gives, so a 12-tick stagger and a 40-tick one both read.
`fighters.json` now names the tier and the energy waves in each fighter's `more` list (`protag10`, `protag11`; `rival7`, `rival8`) and `pair_live.json` shares `burst1`, `launch1` and `miss1`, so the pieces are baked in a live match and findable by the director's `piece` name (`su_*`, `bolt_*`, `blast_*`). They are kept **out of the random pick lists** (`AnimData.ensure_fighter`): a live match still picks the pieces it picked before.

## 2. The closing rule: what breaks (and what was changed)

Encounter's rule (the EP's message): a press from a gap g (bh beyond striking distance) is carried over d = min(4, ceil(2g)) ticks, at most 0.6 bh a tick; at contact the blow lands from where he stands if the rival is inside its reach: striking distance for a light, 0.5 bh more for a medium, 1 bh for a heavy, 1.5 for a charged heavy; the attacker is placed toward striking distance by at most 0.6 bh (45 units) on the tick.

**What the contact solve can bridge.** It reaches the target by the pose's own arm or leg, a lunge of the body (`lunge_max`) and a step of the whole body (`step_max`): all drawn, none moving the sim. Measured with the two staged farther apart than the piece's striking distance (`anim_check`, the "CLOSE" probe), the units the hand ends short at the contact, for a slack of +25, +37 (a medium's), +50, +75 (a heavy's, 1 bh = 75 units) and +112 (a charged heavy's):

| Blow | +25 | +37 | +50 | +75 | +112 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| a light (a hand) | 0 | 0 | 0 | 17 | 54 |
| a medium, a hand | 0 | 0 | 6 | 28 | 64 |
| a medium, a foot | 0 | 6 | 17 | 40 | 75 |
| a tier blow with a step (a fist, a palm) | 0 | 0 | 0 | 2 to 4 | 33 to 37 |
| a tier knee | 0 | 1 | 13 | 37 | 74 |
| a **planted** tier blow (the heaves: the feet keep their place) | 3 to 17 | 15 to 29 | 28 to 42 | 52 to 67 | 89 to 104 |
| a bolt (the sim closes it: step 4) | 11 | 23 | 36 | 61 | 98 |
| a blast | 0 | 3 | 16 | 41 | 77 |

**What I changed:** the limbs' own `step_max` in `data/anim/sockets.json` (foot, knee, elbow, head 10 to 22; hand 14 to 22): a render-only step of the body toward the target, used only when the target is beyond the lunge, so today (the sim places the attacker at striking distance in one tick) nothing changes. A medium's +37 is now covered but for a foot (6).

**What breaks, once the sim only places 45 units on the contact tick** (so the solve is left with the slack minus 45: 0 for a medium, 30 for a heavy, 67 for a charged heavy):
1. A **planted tier piece** (the four heaves, and the turning ones in place) cannot step: a heave left with 30 units to bridge ends 20 or more short, and 60 or more short on a charged heavy. **Either those pieces are chosen only when the rival is inside their own reach (the launcher's quarter aim picks the piece, so it can't), or their slack is cut (to about 10), or they may step a little (their `step_max` is 6 to 10 so that the feet keep their place: Legal's D4 says so, and I will not change it without Legal).**
2. A **charged heavy at 1.5 bh** with a 67-unit slack beyond the placement is short by about 35 for a knee and 60 for an elbow; the stepping and falling pieces that use a hand are within 4. A foot or a knee needs 30 more.
3. **Bolts** are drawn from a 4-unit step because the sim closes the gap first and I cut the lean for e09's head gap: a bolt on a rival 25 units beyond striking distance ends 11 short.
What does not break: the attacker is never snapped onto him; the sim's carried first `d` ticks are a rush with the rival as its target, which the body already draws as it draws any rush (the wind-up layer plays over it). **What I need from Encounter:** the reach each piece may land at as a number it reads from the key set (`range.offset` plus the slack of its class), so the slack is never more than the piece can bridge; a heave and any planted piece with a slack of at most 0.15 bh; the contact tick's separation is already read from the fighters' positions, so no new read is needed.

## 3. The heavy's held charge (Game Design 57abfec9)

B still down at 32 ticks keeps charging: full at 44, by itself at 70, armoured; at full it launches. The beat's `windup` is the whole hold, as for Y's. The tier's pieces draw their tell in the chamber alone (`tell_at` 0.5, held in plain sight), so a hold longer than 28 ticks needs something to build: a `hold` row on the `super` style (`from` 28, `to` 70, `squash` 0.5, `lean_back` 0.12): from tick 28 of the wind-up the body sinks toward the squash pose and leans back a little more every tick up to 70, whatever the key set's own squash, and it is gone as the blow lands. No light on the body (the flash is VFX's, a thin one on the hand); the hands stay as the chamber draws them. Checked on the real solve for all 16 pieces on 62 ticks: nothing above 80 before the last 6 ticks, every contact solved, loaded to 0.6 or more (`_test_windups`). The charged medium is not in this chain.

## 4. How to see them

`art/animation/review/cues-c2/`: `launcher`, `gave_ground`, `reach` and `dodge`, each a sheet and a loop of both fighters (the cue sent at tick 10; the stagger lasts 40 ticks, a miss 20). The scene is `flurry_study.tscn` with `window.__only = "cue_launcher"` (or `cue_gave_ground`, `cue_reach`, `cue_dodge`).

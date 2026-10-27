# Ground locomotion (Animation, 2026-10-23)

Owner: Animation. Window 2 of Orb's push. Parked as `docs/animation/pending/ground-locomotion.patch` (render side; a new data file `data/anim/ground_motion.json`, whose schema `anim.ground_motion/1` Tools writes, granted on Orb's word). Apply after `flight-locomotion.patch`.

## What was there

On the ground a free fighter stood in his stance pose and slid: walking, running and backing up all drew the same guard, with the feet where they were, until the speed laid him out in the flight pose (from about 700 units a second). A take-off and a voluntary landing drew nothing: only a launched body had ground events.

## What the player sees

A free fighter on the ground, not busy, moves on a gait and meets the ground:

| Moment | What the body does |
| :--- | :--- |
| **Walk and run** | a cycle driven by the distance he covers, one every 64 units, at 6.5 a second at the most (so it follows his speed and his direction, and runs the other way when he backs up; the hip bob is twice the rate, under what the twos solve can show): the thighs swing in turn (0.12 rad at a walk's 130 units a second to 0.46 at a run's 520), the swing leg's knee lifts (0.4 to 1.0), the hips bob twice a cycle (0.5 to 1.7 units), the shoulders turn against the pelvis, and the torso leans forward a little with the speed. It fades out from 520 to 900 where the laid-out flight pose takes over |
| **Take-off** | rising from the ground at over 150 units a second kicks him off for 12 ticks: the legs trail behind, the spine stretches, the hips lift |
| **Landing** | arriving at over 140 units a second absorbs: the hips sink 2.4 to 6.2 units by how fast he arrived (what the knees can take with the feet on the ground), the knees flex, he settles over 18 ticks |
| **Surface** | the landing and the run read what is under him (`WorldContact.surfaceAt`: soil, rock, paving, sand, rubble, water; and World's gen 2 look classes through `WorldContact.lookAt` once it exists, mapped by the file's `look`): **sand** sinks 25% deeper, lasts 20% longer and slides the drawn body on 8 units in the way he was going; **rock** and **paving** are crisp and shallow (0.85 and 0.8 of the sink); **rubble** stumbles (one knee catches and flexes more than the other, the hips hitch) and lifts the knees 35% higher; **water** wades (the knees lift 70% higher) and the landing sinks 50% deeper and takes 50% longer |
| **Personality** | the Protagonist's gait is long, loose and bouncy (cadence 1.0, full amplitude and bob); the Anti-hero's is short, quick and low (cadence 1.15, 0.88 of the amplitude, 0.7 of the bob) |

It stands aside (and eases away over 8 ticks) while the fighter is in an exchange, a lock, a rush, a hold, a press-ack, a recoil or a launch. Under reduced motion the gait, the bob and the sink are 0.5. Every ramp is 6 ticks or more (the snappy profile solves on twos). Nothing is written to the sim.

## Files

`render/anim/anim_fighter.gd` (`_ground_layer` after the flight layer; `_ground_surface`), `render/anim/anim_data.gd` and `render_anim.gd` (the loader, `RenderAnim.ground_loco`, `--no-ground-loco`), `data/anim/ground_motion.json` (new key set), `tools/anim_check.gd` (`_test_ground_motion`), `tools/flurry_study.gd` (scenarios `gr_course`, `gr_sand`, `gr_rubble`, `gr_water`; `window.__nogl = 1` is the before).

## Tests and gates

`_test_ground_motion`, both fighters: the walk swings the foot 3 units or more and the run 8 or more against the plain run, the run bobs the hips 0.5 or more, there is no gait standing still or after the stop, the head moves 3 units a tick at most against the plain run; a hop on each of soil, rock, sand, rubble and water kicks off (the foot trails 1.5 units or more) and lands (the hips sink 2 or more); water sinks deeper than rock; a lock switches it all off. Measured: a walk swings the foot 8.6 units and a run 18.8 (the Anti-hero 7.7 and 17.1), the landing sinks the hips 6.1 (rock) to 10.8 (water). Gates on a scratch export of main with the lunge crouch and the flight locomotion: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## The schema request (Tools)

`data/anim/ground_motion.json`, schema `anim.ground_motion/1`, closed except `_` keys, all required: `enter_ticks` (integer 6 to 30); `gait`: `min_speed`, `full_speed`, `run_speed`, `max_speed` (numbers 0 to 3000, ascending), `stride` (10 to 300), `thigh`, `knee`, `bob`, `twist` (each an array of two numbers 0 to 3), `lean_deg` (0 to 15); `takeoff`: `min_vy` (0 to 2000), `ticks` (integer 6 to 40), `kick`, `stretch` (0 to 1), `lift` (0 to 10); `land`: `min_vy`, `ref_vy` (above 0), `ticks` (integer 6 to 60), `sink` and `flex` (arrays of two numbers 0 to 20 and 0 to 2), `knee` (0 to 3); `surfaces`: exactly `soil`, `paving`, `rock`, `sand`, `rubble`, `water`, each `{sink, ticks, slide, stumble, lift, amp}` (numbers 0 to 20); `look`: a gen 2 look class (ice, snow, frost, mud, turf, litter, ash, crust, shingle) to a `surfaces` key; `fighters`: a roster id (`^[A-Z][A-Z0-9_]*$`) to `{cadence, amp, bob}` (numbers 0 to 3). Cross-reference: every `look` value is a `surfaces` key.

## Not here

The tumble and the air recovery (window 4), hair, coat and tail follow-through (window 5), a per-fighter idle on the ground beyond what `personality.json` already does for each stance and shape (the idle already breathes, sways and bounces by stance and shape; what was missing was movement, which is this window).

## Independent review, 2026-10-23

An independent read-only reviewer found, and these patches now fix: the locomotion and ground layers advanced their state on frames with no sim time passing (a 144 Hz view solves several times a tick); the sand slide was added after the root offset was read, so it never drew; the dash coil, take-off and landing envelopes had ramps under 6 ticks inside a longer window; the gait cycle could alias on the twos solve; the landing's sink was more than the knees could take, so the feet went into the ground. Also fixed in the air recovery (the busy test lacked the exchange, the beam charge and the grip; its speed decayed per frame) and the follow-through (a striking forearm keeps its contact target; a part at its bound stops there). Left as they are, on purpose: the hit-reaction variants' 0.05 s attack (a blow always solves every tick, not on twos), and the flight bank and flare stacking on the older flight pose's own bank (they partly cancel).

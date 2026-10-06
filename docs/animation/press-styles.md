# Press styles: how the body moves for tech, speed and heavy blows (2026-10-04)

Owner: Animation. Source: Orb's approved melee-feel prototype (`docs/ep/prototypes/melee-trade-v2.html`, Orb's words in `docs/ep/vision.md`, last two sections). Status: a plan and a first build behind a flag, `RenderAnim.press_styles`, **OFF by default** (`--press-styles` turns it on). Render only: it moves no sim state, no contact tick and no hash.

Orb: timing lands clean, instant-looking blows with an after-image. Mashing fires attacks, impact on the trigger, fast and a fluid blur. Holding is the most fluid-looking and carries the power hits. Warping or smear effects show the speed and the power.

## 1. What the three styles do to the body

All times are 60 Hz ticks, relative to the blow's contact tick `tc` (the sim fixes it; nothing here moves it). The numbers are in `data/anim/press_styles.json`; the prototype's own numbers are the starting point (tech 30-tick blow with a 6-tick tell, 10-tick hold and 8-tick return; speed 8-tick jab; heavy 26 to 46-tick wind-up, 8-tick lunge, hold to +18).

| | Tech (timed) | Speed (mashed) | Heavy (held) |
| :--- | :--- | :--- | :--- |
| Wind-up (load) | a 6-tick tell: the load key eased in hard at the end (ease 3), then **held** | **2 ticks** (ease 1.4; the ruling of 2026-10-04: press-to-blow wins, a speed blow from idle lands within 2 ticks of the press) | 24 ticks (22 for a light heavy), eased (1.6), scaled by the blow's weight |
| Snap into contact | **0 ticks**: the contact key lands on `tc` with nothing in between | **0 ticks**: the contact key lands on `tc` (the trigger frame) | 1 tick, and the **smear frame** is the tick before `tc` |
| Contact pose | the contact key, held **10 ticks** (the held beat); the fist keeps the point it landed on | the contact key on the trigger frame, overshoot 0.22 | the contact key, held **10 ticks**, then an 8-tick follow-through |
| Return | 6 ticks, quick | 7 ticks, **blended**: the next blow starts from where this one is, not from the guard | 14 ticks, eased |
| Limbs | the key set's own side | **alternate** blow to blow | the key set's own side |
| Body | stiff (lag 0.1) | **loose** (lag 0.9, spine yaw 0.16 rad toward the striking side, 7 ticks) | squash on the way in, stretch on the way out |
| After-images asked of VFX | 3 | 2 (a fluid blur) | 3 |

**Squash (heavy wind-up).** Legs, pelvis and the lower spine blend toward a crouch pose (weight up to 1, scaled by the blow's weight), with a 0.16 rad lean back and the body drawn 2.4 units back. The release takes it away over the last 3 ticks, so it is gone on the contact tick.

**Stretch and smear (heavy release).** From 2 ticks before the smear frame to 4 ticks after contact the spine extends 0.14 rad, the hips rise 1.4 units and the body is drawn 3 units ahead (the lunge), settling after contact. The smear frame (one tick, `press.smear`) is the peak of it, the frame VFX draws the smear wedge on. The bones are never scaled (the rig has no bone scaling): squash and stretch are pose-level, as the rig allows.

## 2. Mapping onto what exists (no new poses)

- Every blow still plays its **own key set** (`pr.*`, `ph.*`, `w1.*`, `rb.*`): its three keys are the load pose (`pc`), the contact pose (`pk`) and the follow pose (`pf`). The three styles are three timings over the same three keys. The pieces the director names (`args.piece`, `strike.jab`, `strike.haymaker`) pick the key set exactly as today, for all three styles.
- Tech: `pc` held, `pk` on `tc` with no in-between, `pk` held, then a quick `pf` and return. Speed: short `pc`, `pk` on `tc`, a loose `pf`, blended into the next blow's `pc`. Heavy: long `pc` plus the squash, `pk` plus the stretch, a held `pk`, `pf`, return.
- **No new poses are needed.** The squash borrows legs, pelvis and spine from existing poses: `pn.hold.brace_load` (the protagonist), `pe.plant_coil.arrive` (the rival), `brace` for anyone else. If Orb wants a deeper or more characterful wind-up, a dedicated `*.squash` pose per fighter is the one new pose I would add (two poses, no new waves).
- New data: `data/anim/press_styles.json` (schema `anim.pressstyles/1`; **a Tools schema is needed**, see NEEDS FROM EP). New profile field `hold_ticks`, read only for styled blows.

## 3. Can the style be read today? Yes, with two limits

The sim already carries what is needed. `args.piece` is stamped on every beat by `DirRecipe.dress`; the press log is `DirAlchemy.read(S, f)` (Controls' `SimPressRead.classify`: style `rhythm`, `mash`, `taps`, `hold`; timing `perfect`, `good`, `none`). The build chooses a blow's style in this order (decided once, the first time the blow is seen):

1. the beat's own `args.style` (`tech`, `speed`, `heavy`), when the director stamps one (nothing does yet);
2. a heavy blow (`ex.kind` heavy, `o.big`, damage 40 or more) is `heavy`;
3. the striker's press log now: `rhythm` is `tech`; `mash`, `taps` and no read are `speed` (VFX reads it the same way, so picture and body agree); a `hold` read on a light blow plays as today.

The two limits: the log is read **at first sight of the blow, not at the press** (a long string can change style under it), and a `hold` is not readable after the button is released, so heavy comes from the blow's weight, not the hold. Both are why the beat should carry the style (section 4). In a 1500-tick AI-vs-AI match (seed 7) the log read gave 9 speed, 4 heavy, 1 tech and 4 light blows thrown during a hold (played as today): the AI mashes, a person who times the blows is what brings tech.

## 4. What the beat must tell me (fields on `strike` and `chainStrike`)

On every `strike` and `chainStrike` beat, set when the director plans the string (the same moment `piece` is stamped):

| Field | Values | Used for |
| :--- | :--- | :--- |
| `style` | `"tech"`, `"speed"`, `"heavy"` | the whole choice above, without guessing from the log |
| `grade` | `"perfect"`, `"good"`, `"none"` | tech only: a perfect blow gets the full hold and 3 after-images, a good one 2 and a shorter hold; a missed beat lapses to `speed` (stamp `speed` on the following blows) |
| `k`, `n` | the blow's place in the string and its length | speed's alternation (today it counts the attacker's blows itself) and which blow is the closer |
| `closing` | bool | the string's last blow: the only one that sends the defender back, so it takes the heavy hold even in a speed string |
| `charge` | 0 to 1, the share of the hold | heavy only: how deep the squash goes and how long the wind-up (today the blow's damage stands in) |

`chainStrike` beats have **no `args` today** (the renderer invents `{"o": {"big": true}}`): please give them the same dictionary as a `strike` (`a`, `dmg`, `piece`, plus the fields above). The beat must also be announced early enough for the wind-up: tech wants 6 ticks before contact, speed 3, heavy 24 (shorter, the wind-up is cut to what there is, as today). **Ruling (EP, 2026-10-04):** speed takes only 2 ticks of notice from idle, inside a running flurry the next blow is known a tap gap ahead; the build's speed load is 2 ticks and `anim_check` asserts it.

### What is read from the beat (Encounter's slice B0, committed 4bc5ff1)

The beat's fields are read in place of the press log; the log is now only the fallback for a beat that names no `style` (a lab, an old tool, an exchange the planner did not dress). Numbers are in `data/anim/press_styles.json` under `beat` (a schema line is `docs/animation/handoff/press-styles-beat-schema.patch`).

| Field | What the body does with it |
| :--- | :--- |
| `style` (speed, tech, heavy) | the blow's style outright |
| `grade` (perfect, good, off, none) | tech only: a `perfect` press holds its contact beat 10 ticks and asks VFX for 3 after-images, `good` 6 and 2, `off` 4 and 1, `none` 6 and 2 |
| `hand` (`r` or `l`) | the striking side outright, over the alternation by `k` (B0's `hand` alternates by `k` as a stand-in; when Combat's cells name the side it comes from the piece and the body follows). A broken-arm override still wins |
| `closing`, `ender` | the closing blow of a string, and a heavy that ends it, hold their follow-through at least 6 ticks whatever their style, so the blow that ends it lands and stays |
| `charge` (0 to 1) | heavy: a held (1) heavy winds up for its whole time and squashes to the full depth; a tapped (0) one for 0.6 of it and a squash at the weight 0.25 (about two thirds of the depth) |
| `k`, `n` | carried on `press` for VFX (`ordinal` is the blow's place in the body's own list); the alternation uses `hand` |
| `chainStrike` args | a chainStrike now carries `a`, `d` and the beat fields like a strike, and its own `style` and `hand` are played; before, the render invented `{"o": {"big": true}}` |

**Tech means the same thing everywhere** (the EP's rule, questionnaire 18): the strike pose lands on the contact tick with no in-between, is held, and returns the same way, from idle, in a string and at the end of a zip's dash; the dash itself gets no snap. `anim_check` now compares the same perfect tech cross three ways (idle, after a speed jab in a string, at the end of a tech zip) pose by pose on the contact tick and the twelve after it: the worst difference is 0.08 rad (the contact solve and the zip's own settle), limit 0.15.

## 5. Squash, stretch and smear inside the joint limits

- The squash is a blend of two valid poses on the leg, pelvis and lower spine bones (the limb bones by swing and twist), so it cannot leave the range both poses are in.
- The stretch and the twist are a few hundredths of a radian on the spine and the neck, which have no limit of their own; the head counter-rotates so the eyes stay on the target.
- The return of a styled blow goes by `AnimPose.mix` (swing and twist) instead of a plain slerp, which folded the arm's own twist after a long follow-through.
- A styled blow's contact point is **latched** at the contact tick and held through the hold. Without that the arm chased the recoiling defender for ten ticks and went past the shoulder's twist range (9 violations; with the latch, none).
- The final limb pass (`limit_limbs`) still runs after everything.
- `RenderAnim.joint_audit` result (lab, hand-fed beats, violations summed over the audit stages): styled is never worse than plain in any of the eight lab scenes; tech and heavy have none at any stage, speed keeps the few the plain blow has (the arm's twist while two arms swap, `upper_arm` 47 to 72 degrees, before the limb pass).
- The contact tick still plays the contact key: the style layer leaves 0.0 to 0.08 rad on the spine (the speed twist), checked at under 0.2 rad. The plain blow stays under 0.02, which is the existing check and stays on with the flag off.

## 6. Hand-off to VFX: what I expose

After a solve, on `RenderAnim.fighter(S, f)` (an `AnimFighter`):

- `press` (a Dictionary, empty when no styled blow is playing): `style`, `phase` (`load`, `release`, `smear`, `contact`, `hold`, `follow`, `return`), `blow` (an id), `ordinal`, `ticks_to_contact`, `limb` and `bone` (the striking limb and its tip bone), `side`, `smear` (true on the smear frame), `ghosts` (how many after-images the style asks for), `weight`, `squash`, `stretch`, `twist` (0 to 1 each) and `dx` (how far the body is drawn from its anchor along its facing, model units).
- `press_pose(k)`: the pose `k` solves ago (0 is the newest), `{T, q, hips, root_off}`: the **previous pose** for the after-images. Pose the same `AnimBody` with it (`apply(q, hips, curl, root_off)`, the curl of the live pose is fine). Up to 12 solves, 0.4 s, kept for a moment after the blow ends.
- `press_path`: the striking limb's tip over the same solves, `{T, tip}` (model space, `root_off` included, flip x by `vface` for the world), the **limb path** for the smear wedge and the speed blur.

VFX's `press.gd` estimates the old pose and the limb path today; these replace both estimates. Smears drawn as shapes, after-images and contact marks stay VFX's. I draw nothing but the lab's yellow path dots.

## 7. The rival's glasses (Art's approved turnaround)

Choice: **`att_head_brow` with an offset**, no new socket. Art's callout puts the origin at the nose bridge: 1.0 down and 0.5 forward of the brow socket, a child of the head bone, so the glasses follow the head with no new rig point (a 15th socket would change the 14-socket contract and the retarget names for one fighter's accessory). The offset lives in the glasses part's own data (Rendering owns the part): `{"socket": "att_head_brow", "offset": [0.5, -1.0, 0.0]}` in head-local units (x forward, y up). The lens centre (4.2, 10.0 head-local) and the temple hinge (1.2, 9.9) then follow from the part's geometry; Rendering should check that the bridge lands at head-local (7.0, 10.2) on the rival's build profile, the one number I cannot verify from here. A nudge gesture can target the temple hinge as an extra offset from the same socket. If that check fails by more than a unit, the fallback is the new `att_glasses` socket with the origin at the bridge, and the glasses part needs no other change.

## 8. The lab and the review GIFs

`render/anim/tools/press_lab.gd` plays a string of hand-fed beats (each carrying `style`) through the real solver against a dummy defender: scenes `tech` (three timed blows), `speed` (five mashed blows 8 ticks apart), `heavy` (one held blow), `combo` (three mashed and a heavy closer), on either launch fighter, `--off` for the same beats without the styles, `--path` to draw the limb path, `--measure` for a headless line of numbers. `render/anim/tools/rgb_sheet.mjs` tiles frames into a PNG.

```
godot --no-window --path . -s res://render/anim/tools/press_lab.gd -- --scene=heavy --fighter=antihero --out=a.rgb --path
godot --headless  --path . -s res://render/anim/tools/press_lab.gd -- --scene=speed --fighter=protagonist --measure
```

The review GIFs are `art/animation/review/press-styles/<scene>-<fighter>.gif`, eight of them, each **off on the left, on on the right**, 60 frames a second at half speed. The yellow dots are `press_path` (the hand-off in use).

## 9. Check results (a fresh HEAD export plus my files, headless)

`anim_check` passed (5328 checks, including the new press styles test: both fighters, three styles, the hand-off, the joint comparison, the held fist within 1.5 units, no hash change with the flag on); `joint_scan --strict` exit 0 (675 poses, 0 past a limit; the sequences and the live frames 0); `lead_scan --strict --max=40` exit 0; `coverage_live --strict` exit 0; `render/tools/determinism.gd` passed. The pair's bake is unchanged (about 285 ms native, 486 poses): the styles bake nothing.

## 10. Status and risks

- Built behind the flag, off by default, the eight GIFs, the lab, an `anim_check` test (`_test_press_styles`) and the five gates (below).
- It reads as the prototype in the lab. It has not been seen in a live match with a human on the keys; the AI's press log, not a person's, drives the read today.
- Tech's "no in-between" is an instant jump on the contact tick (flagged as a blow snap so the inertialiser leaves it alone). At 60 Hz that is one frame; VFX's after-image has to carry the feeling of the blow, which is what the prototype does too.
- The squash borrows another pose's legs, so a fighter whose borrowed pose has an odd stance reads odd: the rival's `pe.plant_coil.arrive` is deep; Orb's eye decides.
- `chainStrike` args and the beat fields in section 4 are sim work (Combat or Encounter); until then the style comes from the log and the weight.
- The first-sight read can disagree with VFX's read one tick later; stamping `style` on the beat removes that.

## 11. Two additions (2026-10-06)

- **`push`, a fourth style** (the defensive stance's push): a beat's `style: "push"` plays a blow with no impact snap: a 10-tick wind-up, the contact reached over 5 ticks, a 10-tick follow-through, no overshoot. Tech, speed and heavy are unchanged.
- **The guard layer** (`guard` in `press_styles.json`): a strike beat with `check: true` (a check thrown over the guard) keeps the arm that is not striking in the defensive guard pose (weight 0.9), and a foot, knee or head blow guards both arms. Details and the checks are in `docs/animation/zip.md` section 8.

## 12. The brawl's riposte and its 20-tick stagger (plan, 2026-10-07; docs only)

Encounter's next brawl slice resolves a perfect block and a reversal inside the brawl. The cues and fields as announced: a cue **`riposte`** (actor the blocker, target the rival, `text` `light` or `heavy`, `n` its contact tick); the **stagger cue** gains two texts, `perfect_block` and `reversal` (`n` the ticks, `target` the fighter who earned it); a brawl's strike beats may carry `riposte`, `reversal` and `sure` (a sure blow cannot be blocked or dodged); `brawl_end` no longer says `perfect_block` or `reversal`. Nothing new needs posing: both reuse the step 3 poses.

**The blocker's riposte.** The perfect block already plays `s3.perfect_block` (30 ticks, with the `~b` variant for the other build): the parry and a loaded ready pose. The riposte is that ready pose released: the blow is an ordinary `strike` beat from the brawl, with `riposte: true`, and the body treats the block pose as its wind-up, exactly as a zip's strike treats the tell (section 4 of zip.md: `zip: true`): the strike block cuts its own wind-up to **2 ticks (3 for a heavy)**, drops its squash, and the block pose fades out over those ticks, so the blow leaves from the block and lands on the contact tick `n`. The look is the beat's: a perfect timing, so by default `style: tech`, `grade: perfect` (the contact held 10 ticks, 3 after-images) for a light and `heavy` for a heavy, unless the beat says otherwise; **`sure`** changes nothing in the body (a sure blow is the sim's rule) and is exposed on the `press` dict (`press.sure`) so VFX can mark it. A **reversal** (`reversal: true`) is the same with `s3.reversal` (8 ticks, the sidestep) as the load: the wind-up cut applies from it, and the blow after it is a riposte of that kind. If the contact tick comes sooner than the cut wind-up allows (under 2 ticks after the cue), the blow starts from the block pose as it stands and arrives on `n` with a shorter snap: the cue's tick is not moved.

**The 20-tick stagger in place.** The rival who is blocked or reversed stands in place and reels: `s3.stagger_blocked` (24 ticks; `~b` variant) for `perfect_block` and `s3.stagger_countered` (16 ticks) for `reversal`, **fitted to `n` ticks** (the entry layer's `fit`: every phase squeezed or stretched together; at 20 that is 0.83 of the first and 1.25 of the second, inside what the zip's entries already do), the last pose held if `n` is longer. No pose moves his position: the stagger poses are body poses and the sim holds him. The stagger cue plays them directly with `target` and `n`, so **the old watch** (`other_if_stunned`: the body waits three ticks for `stunTicks` to turn up) **is dropped for the brawl** and stays only for exchanges that do not send the new cue; if both arrive in the same few ticks the cue wins and the watch is cleared, so the stagger never plays twice. The ragdoll adds its own give (a head and shoulder sway) from the hit events as it does for any blow; reduced motion shortens nothing here (the stagger is gameplay time, the sim's 20 ticks).

**Checks.** `anim_check`: a staged riposte plays its blow on tick `n` within 0.02 rad of the contact key with the wind-up cut, the block pose is gone by contact, `sure` shows on `press`; a staged `perfect_block` and `reversal` stagger plays 20 ticks fitted with no joint past a limit and no root translation; the cue and the old watch together play one stagger; one tick a frame against two the same.

**Rows and schema.** No new pose, so nothing for `held_scan` (the `s3.` family is rest) or `joint_scan` (the all-poses pass covers them). One data row at build time: a `riposte` block in `press_styles.json` (the wind-up cut 2 and 3, the fade 4 ticks, the default style and grade): **a new schema key**, which goes to the EP as a one-liner for Tools before it is written.

### 12b. Built (2026-10-07), against hand-staged cues

Built as planned, with four precisions. **Where:** `anim_fighter.gd` (`_rip_args`, `_rip_fade`, `on_stagger`, `on_riposte`, the `riposte` dict, `press.sure` and `press.riposte`), `render_anim.gd` (the cue routing: `stagger` with text `perfect_block` or `reversal` goes to the cue's **actor**, who is the staggered fighter, as Encounter's brawl-b1 table has it; `riposte` goes to the blocker), `data/anim/press_styles.json` (`riposte`), `press_lab.gd` (scenes `riposte`, `riposte_heavy`, `reversal`, `riposte_long`), `anim_check` (`_test_riposte`).

- **The data row** is exactly `"riposte": {"windup": {"light": 2, "heavy": 3}, "fade": 4, "style": {"light": "tech", "heavy": "heavy"}, "grade": "perfect"}`; schema delta `docs/animation/handoff/riposte-schema.patch` (applies on the working tree's `anim-press-styles.schema.json`; `validate.js` passes with it and fails without it, which is the gate working).
- **`fade` is the ticks before the contact tick** over which the block pose fades out (so it ends on contact), not ticks of the wind-up as I first wrote: it is then independent of how long the strike block's own wind-up is. The fade reads the riposte from the exchange's beats, so **the riposte beat must be in `S.dirS.ex` while the block pose plays**; if the beat is not there yet the block pose simply plays out its 30 ticks.
- **The stagger is fitted to `n` at any `n`** (20 plays a 24-tick sequence at 0.83 and a 16-tick one at 1.25; 40 plays them at 1.67 and 2.5), not held at the last pose. The sim's `n` is the time; a stretched reel is slow but never frozen. Reduced motion does not shorten it. The cue wins over the old `stunTicks` watch in either order of the two cues.
- **The riposte cue's `n`** is read as a tick number when it is later than the cue's own tick and as the ticks ahead when it is smaller. It only feeds `riposte` (for VFX) until the blow's beat takes over; the posing is the beat's. Encounter: say which it is and I make it one reading.
- **What VFX gets:** `AnimFighter.riposte` (`kind` light or heavy, `reversal`, `sure`, `ticks_to_contact`; from the beat, or from the cue alone with `cue: true` before the beat exists) and `press.sure` and `press.riposte` on a styled blow.

**Checks (a fresh HEAD export plus my files, headless):** `anim_check` passes (6268 checks): both riposte kinds (light and heavy) for the perfect block and the reversal on both fighters, the wind-up cut to the data's 2 ticks (a light) and 3 (a heavy) and a negative control (windup 8 fails), the block's fade 1 to 0 and never rising, the blow within 0.2 rad of its contact key, no NaN or joint past a limit, `press.sure` and `press.riposte` set, the stagger fitted at n 20 and 40 with the old watch cleared, reduced motion not shortening it, the flag off (the blow plays plain, the stagger and the exposure still work), and one tick a frame against two equal within the ragdoll test's 1e-7. `joint_scan --strict` and `held_scan --strict` exit 0 (no new pose); render determinism plain and `--intro` pass. GIFs (off on the left, on on the right) in `art/animation/review/press-styles/`: `riposte-`, `riposte_heavy-`, `reversal-` and `riposte_long-` for `protagonist` and `antihero` (eight).

## 13. On by default (2026-10-08)

**The change:** `RenderAnim.press_styles` defaults to `true` (render_anim.gd, one line); `--no-press-styles` is the before and Shift+F7 still flips it. `main.gd` line 127 needs no edit: `host.vfx.press_enabled = RenderAnim.press_styles` reads the flag, so VFX's press looks follow it. `anim_check` now expects the default ON, restores the flag to the run's default after each test that changes it, and gives the seeded-match contact check a limit of 0.1 rad while the styles are on (see below).

**What a real match does with it on** (a fresh HEAD export, six seeds of brawl B1, 32,400 ticks, AI against AI, headless; the same six seeds with it off for the comparison):

| | off | on |
| :--- | ---: | ---: |
| NaN rotations | 0 | 0 |
| joint violations before the final limb pass (A to D stages, all frames) | 12,153 | 10,533 |
| solve cost a fighter-frame | 453 us | 467 us (+3%) |
| `main.frame` a frame (the whole view update, four seeds, mean / p95) | 2.05 / 3.15 ms | 2.12 / 3.33 ms (anim and VFX looks both on) |
| contact frames | 5,026 | 5,026 (every blow still lands on its tick) |
| worst contact error (pose against the contact key at the contact tick) | 0.003 rad | 0.080 rad, always `spine_1` and `spine_2` |

- **The 0.08 is the style, not a fault:** it is the cap of the mashed blow's spine twist in `press_styles.json`; the hand still reaches the contact point by the contact solve. The seeded-match gate in `anim_check` is therefore 0.1 with the styles on and 0.02 with them off.
- **Wrong hands:** 226 contact ticks compared the beat's `hand` with the side the body used: 0 mismatches (a broken limb overrides the side by design, and none occurred).
- **Poses against the ragdoll:** 0 frames of a styled blow while the fighter was launched, down or dropped. 14,334 of the 18,942 styled-blow frames overlap a hit reaction on the same fighter (the brawl's trades): the reaction and the style stack on the spine and the final limb pass keeps both inside the joints (no violation reaches the screen: `joint_scan --strict` exits 0).
- **Styles chosen from the real beats:** speed 1,481 blows, heavy 321, **tech 15**. The tech look is rarely produced by two AIs (they mash); it is tested in the lab and in `anim_check`, and a person pressing in rhythm is the first real run it gets.
- **Cost at 30 frames a second:** the CPU side is about 0.07 ms a frame (the solve is once a frame whatever the ticks a frame; the rest is the per-tick style state and VFX's looks), 0.2% of a 33 ms frame. Not measured: VFX's draw cost (the looks add sprites; the web bench would show it) and a real old laptop.

**Checks run with it on** (fresh HEAD export plus my two files): `anim_check` passes (6,268 checks), `coverage_live --strict`, `lead_scan --strict --max=40` (11 feet-first frames, the same as with it off), `joint_scan --strict`, `held_scan --strict`, render determinism plain and `--intro`, VFX's `effects_check` and `hash_check` all pass. Review GIF of a real brawl from the web build in headless Chrome (a scratch export with the flip, a screencast at about 5 frames a second, so the motion is sampled, not smooth): `art/animation/review/press-styles/real-brawl-web.gif`.

**What I could not see:** the screencast rate (software GL in headless Chrome) is too low to judge the timing of a single blow, only that no pose breaks, no limb flips and the two fighters stay in contact; Orb watching a match live with Shift+F7 as the A/B is the real check. **What I would watch first:** the tech look under a real player, and the brawl's trade frames (a styled blow while a reaction plays) at full frame rate.

## 14. B2's skill strike: the tech pose and the limb's set at the beat (2026-10-08; plan, docs only)

Encounter's next brawl slice asks for the tech pose on the contact tick in a brawl (the strike beat carries `style: tech`, `grade` perfect or good, and a new field `beat`: the ticks from its contact to the player's beat point) and for the limb's set at the beat point from a new cue `beat` (actor, `n` the beat point's S.tick), sent as a light or skill strike lands. The skill strike: contact 6 ticks after the press, a reel of 8 on the rival, a hit-stop of 4.

**What I have.** The tech style does what is asked: the strike pose lands on the contact tick with no in-between, is held (`grade` sets the hold: perfect 10 ticks and 3 after-images, good 6 and 2), and returns quickly; B0's beat fields (`style`, `grade`, `k`, `n`, `closing`, `charge`, `hand`, `ender`) are read in place of the press log. The tech wind-up is 6 ticks (`load_ticks`), which is exactly the skill strike's press-to-contact of 6: the wind-up starts on the press. The rival's reel of 8 is the existing `stunTicks` stagger (`s3.stagger_short`, fitted to 8 to 30 ticks, so 8 plays as 8) and the hit reaction on the damage event; the hit-stop freezes `S.T`, and my holds run on `S.T`, so they are live ticks, as the brawl's own holds are.

**The limb's set at the beat, in my terms.** I read it as the end of the contact hold: the limb is pinned at the contact pose (the fist within 1.5 units of the contact point, tested) until the beat point, and **sets there**, which is where the return begins. So the beat point is the hold's length, and what is new is that the hold is no longer the grade's fixed number but the beat's:
1. **`beat` on the strike beat:** the hold is `beat` live ticks (clamped 2 to 30) instead of the grade's table; the grade then only picks the after-images. A tech blow with no `beat` keeps today's table, so nothing changes for a blow that does not carry it.
2. **The `beat` cue:** an edge: on the tick `n` the limb is set (the return starts), and `press.set` is true for that tick for VFX and audio (a new key on the hand-off). The beat field drives the pose; the cue is the sim's own word for the moment and wins if the two disagree (the return then starts on the cue's tick).
3. **Nothing new for the contact tick, the reel or the hit-stop:** they are the tech style, the stagger path and `S.T`.

**Two questions for Encounter.** Is `beat` counted in S.ticks or in live ticks? The brawl's clocks run on `S.tick` through a hit-stop and its holds on live ticks; with a hit-stop of 4 at the contact, a beat counted in S.ticks would be 4 shorter in my time. I take it as live ticks unless told otherwise. And is the beat point the end of the hold (the set, then the return), as I read it, or a moment inside it?

**Build size:** a few lines in `_press_prof` (read `beat`), the cue routing (three lines in `render_anim.gd`), `press.set`, a test (a staged tech blow with `beat` 8 and 14, the hold the beat's length, the cue tick sets, no `beat` keeps the table) and a lab scene. One data change: none (the `beat` block already has the grade table; a `beat` field on a beat is the sim's). Not started.

### 14b. Encounter's answers (2026-10-08): the beat is a tick, and the open point planned both ways

**Settled by Encounter, and it changes the build.** The beat field `beat` is in **S.ticks** from the contact, and the cue `beat` carries `n` as an **absolute S.tick**. So the body **keys on that tick and does not count live ticks from the contact**: the blow's own hit-stop (inside the 24) and every freeze the rival's blows add before the beat point are unknown at the contact, and a live count would drift from the tick Controls grades on. (My first plan of section 14, "the hold is `beat` live ticks", is withdrawn.)

**How a pose follows a tick when `S.T` stops in a hit-stop.** My animation clock is `S.T`, which stands still through a hit-stop while `S.tick` keeps counting. The set must land on the beat's S.tick whatever froze before it, so for the ticks around the beat the pose is driven by the **S.tick countdown** (`left = n - S.tick`), not by `S.T`:
- the beat's tick `n` is the cue's, or, from the field alone, the contact's S.tick plus `beat`; the contact's S.tick is latched in `on_tick` (once a tick, so a frame of two ticks gives the same latch: no per-frame term, the rule of the ragdoll test) on the first tick with `S.T` at the contact time;
- until the return begins the limb is **pinned** at the contact pose (a pin does not move, so a freeze in it is invisible); the return runs for a fixed `R` ticks (the tech style's own return, 6) as a function of `left`, so the set lands on `n` exactly; a freeze inside the return would advance it a tick through the freeze, which is the smallest cost of keeping the grade's tick true.

**His line is free from the contact on, so an early press must cut it.** It does, with what exists: the new blow's window starts at its own wind-up and the strike block takes the **latest start** as the blow (`best`), so a flurry blow thrown at once replaces the pinned one on the tick its window opens, and the pinned limb comes back by the carry blend (5 ticks, `_press_carry`); nothing about the pin survives into the new blow. A test: a tech blow with `beat` 24 and a second press 9 ticks after the contact: the first limb is released by the new blow's wind-up and the new blow lands on its tick.

**The look is ruled (Game Design, `docs/design/melee-press-feel.md` section 4: the prototype's order), so `end` is the build and the two-way switch is dropped.** From the contact the limb is **pinned** at the contact pose with its wire echoes (VFX's) until **10 ticks before the beat point** (14 ticks for a beat at 24; 10 to 18 by the piece: the pin is `beat - 10` ticks), then the **return** runs over the last 10 ticks, **speeding up into the end**, and the limb is **set at the beat point** (the glint and the sound at `n`); **after the window the limb stays set** (the return's pose, the guard, until the next blow or the stance). The return always starts 10 ticks before the beat and always takes 10, whatever the piece: it is the cue. It applies to a light and a skill strike alike; **a flurry blow has no hold and no beat** (it carries no `beat`, so it plays as it does today).
- **In my terms:** the pose is a function of `left = n - S.tick`: pinned while `left > 10`; the return `u = 1 - left / 10` over `left` 10 to 0, eased so it accelerates (`u` to the power `return_ease`, 2.0: slow off the contact pose, fastest into the set); the set pose from `left <= 0` on. The contact pose, the hold's fist within 1.5 units of the contact point and the tech style's exact contact tick are unchanged.
- **Data, in my file's spelling** (snake_case, as `hold_ticks`, `load_ticks`): two keys in the `beat` block of `press_styles.json`: **`return_ticks`** (10; Game Design's `beat.returnTicks`) and **`return_ease`** (2.0). The `set` switch of the first plan is not needed and is not added. **Schema one-liner for Tools:** `properties.beat.properties.return_ticks` an integer from 1 to 30, `return_ease` a number from 1 to 4.
- **What the body exposes** for VFX's echoes, ring and glint: `press.phase` is `hold` while pinned, `return` over the last 10 ticks, `set` from the beat point; `press.beat_left` (`n - S.tick`, so the optional ring can close on the same tick) and `press.set` true on the tick `n`.
- **The cuts, from what exists:** an early press (a flurry blow thrown at once) replaces the pinned or returning limb on the tick its window opens (latest start wins; the carry blend, 5 ticks, brings the limb back from wherever it is); **a press in the last 4 ticks of the return throws the skill strike out of the return** the same way: its wind-up starts from the half-returned pose (the carry blend), and the skill strike's contact 6 ticks later is on its own tick. After the window nothing cuts it: the limb stays set.
- **Tests when built:** a tech blow with `beat` 24: pinned to `left` 10 (the fist within 1.5 units), the return over exactly the last 10 ticks and monotone toward the set, the set on tick `n` with a hit-stop of 4 at the contact and a freeze before the beat; the same for a skill strike (contact 6 ticks after the press, reel 8); an early press at 9 ticks after the contact cuts the pin; a press 3 ticks before `n` throws a blow out of the return; no `beat` (a flurry blow) plays as today; one tick a frame against two within the ragdoll test's tolerance. Not started: the build waits for Encounter's B2.

**The after-images follow the sim's grade** (Controls: perfect within 2 ticks of the beat, good at 3 to 4): `grade` on the beat picks 3 or 2 after-images as now; the body does no grading of its own.

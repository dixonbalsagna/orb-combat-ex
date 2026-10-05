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

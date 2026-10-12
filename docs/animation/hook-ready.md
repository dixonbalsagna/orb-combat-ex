# Ready for the recipes window: what Animation's tree does, and how it was proved

Owner: Animation. Date: 2026-10-12. For the EP, Combat (`docs/combat/pending/nine-cells.md` section 6), Encounter (the hook in `brawl.gd`) and Tools (the schema). Render only; the gameplay hash is untouched. Headless only. Every number is a first value.

## 1. The ids (item 1, ruled and sent)

| Piece | Fighter | Combat id | Place |
| :--- | :--- | :--- | :--- |
| `pk.bolt_flick` | Protagonist | `strike.bolt_flick` (unchanged) | chest |
| `pk.bolt_sweep` | Protagonist | `strike.bolt_sweep` (unchanged) | gut |
| `rk.bolt_flick` | rival | **`strike.bolt_flick_gut`** | gut |
| `rk.bolt_sweep` | rival | **`strike.bolt_sweep_chest`** | chest |

Set ids (`pk.*`, `rk.*`), `reach.json` and every reference by set are untouched. Only the manifests' and key sets' `combat` field changed, and `AnimData.resolve_strike` answers to the new ids and, still, to the old (`strike.bolt_flick` finds the rival's `rk.bolt_flick`). Checked: of 89 strike ids over every wave manifest these two were the only ones shared with a different place, limb, weight or range. `blast_chest` and `blast_gut` are shared with the same place but a different striking surface (palm and fist), which the pieces table does not carry.

## 2. Rows 09 and 10 of the tier (item 2a)

Four provisional key sets, built from Combat's names in `three-strengths.md` and `c2t-content.md` section 1. Their ids are the ones Combat took: **a word to the EP before any of them changes again.**

| Row | Fighter | Id | What | Drive | Place | Sends |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 09 | rival | `su_edge_legs` | a stepping low kick with the edge of the foot | step_through | the legs | across |
| 10 | rival | `su_plate_arm` | a falling forearm plate | fall | the arm | down |
| 09 | Protagonist | `su_knee_legs` | a turning knee, low, hands up for balance | turn | the legs | turned |
| 10 | Protagonist | `su_elbow_jaw` | a turning elbow, one turn | turn | the jaw | turned |

All four are in waves `rival7` and `protag10` (prefixes `ru`, `pu`), judged by the tier's own checks with no change to them: the drive rules, 28-tick and 62-tick wind-ups (nothing above 80 early, loaded to 0.6 or more), the 14-tick launcher window (`su_elbow_jaw` only: it launches; the other three are the wrench's and never do), Legal's follow-through rule, the held lint and the joint scan. Poses: 12 new (chamber, contact, follow each). Since Combat took them the contact numbers of `su_elbow_jaw` moved (the hips 4 at the blow and 30 after it, the hand 20 forward: the first draw overshot the target by 10 units and pulled the thigh); id, limb, tip, path, drive, place and sends are unchanged. Their covers in `reach.json` (units of slack past the striking distance): `su_edge_legs` 64, `su_plate_arm` 65, `su_knee_legs` 41, `su_elbow_jaw` 37.

## 3. The free arm (item 2b)

The arm comes from the run's order (`hand` on the beat), and the renderer mirrors the key set for the left hand. What was missing was proof that every piece plays whole on the other arm: `anim_check` `_test_free_arm` throws every bolt and blast of both fighters and 12 tier pieces each left-handed through the real solve: one contact reached, error under 0.25, nothing on screen, no NaN, and each bolt's left hand at the chest or the gut (38 to 62 high, below the collar). **26 pieces left-handed, all clean** (anim_check, 1 contact each, error under 0.25, bolts at the chest or the gut).

## 4. The charged medium (item 2c)

Built and viewed already (nine-cells.md section 3): the `medium` style's `hold` row (10 to 28 ticks) and its two hold poses (`ch.y_p`, `ch.y_r`, wave `charge1`): forward and patient, one shoulder wound back, the weight coming onto the front foot. At full (`charge_full`, the cue the sim already sends for the heavy; Encounter's pass 2 sends it for Y) the body trembles for the rest of the hold, a third of a unit and no more. **The flash itself is VFX's.** Nothing here needs the sim: the held layer reads `DirBrawl.winding` as it does for the heavy.

## 5. The strength map, and today's picture (item 2d)

- A beat that carries a `strength` and names **no style row** now gets its strength's row whether or not it is a flurry (light `speed`, medium `medium`, heavy `super`, bolt `speed`, blast `medium`; a beat with a burst number `burst`). Before: only when the beat said `flurry`.
- A beat that names a style row keeps it. Every brawl beat does today (`brawl.gd` 351, 504, 801), so **nothing on screen changes until Encounter drops the explicit style.**
- When the hook lands there is no switch: the first brawl beat with a strength and no style row sets `RenderAnim.hook_seen`, and the nine cells' other looks come in with it (the wind-ups drawn whole, the held charge, the armour read, the held X's set). `RenderAnim.strength_styles` (default false) forces the map over an explicit `speed` or `heavy`: how the cells are seen before the hook.
- **Proof that the default picture is unchanged:** a pose hash of both fighters' whole solved body (every bone, the pelvis and the fingers) on every tick, HEAD's `render/anim` against this tree's, default switches: two seeded AI matches of 900 ticks and six scripted-pad cells (held X, mashed X, mashed Y, held Y, held B, mashed B, 274 to 354 ticks each): **all eight hashes identical.** `anim_check` `_test_strength_map` and `_test_cells` keep the precedence and the default.

## 6. What the solve corrects by more than 30 degrees (Combat's finding)

Combat's three, measured on the real solve at the striking distance and at the slack the closing rule may leave (`_test_fix30`; joint scan output frames are 0 of 896 poses and no frame on screen past a limit, so these were the last pass's corrections, not what shows):

| Piece | What it was | Cause | Done |
| :--- | :--- | :--- | :--- |
| `ru.su_knee` (row 03, posed) | 18 frames at the striking distance, the thigh pulled back by up to 106 degrees (twist and swing) for the whole hold | Its striking distance (28, copied from the driving knee) is nearer than a *stepping* knee can fold to: the knee target sits inside the thigh's reach and the hip has to twist | **Its distance is 40** (manifest `offset`; band left `close`), the contact pose leans back a little and carries the hips less (hips 14, foot 32). Now 22 degrees at most, 0 frames over 30 at 0 to 20 units of slack; `reach.json` cover 69 to 38 |
| `pk.bolt_flat` | 2 frames (32, 66 degrees) at 5 to 10 units of slack | The upper arm's twist on the return, as the contact solve lets go with the arm nearly straight: one frame the last pass takes back | Not changed. Clean at 0 and from 20 up; its cover is 21. **Encounter's closing rule can avoid it by keeping a bolt's slack under 2 or over 15**, or I can ease the return (a 3-tick longer let-go): say which |
| `pk.bolt_thrust` | 1 to 2 frames (42, 66) at 2 to 10 | The same | The same |

The library has these: `pr.jab` pulls one frame by 47 degrees at any slack, `ru.su_heel` 105 at the striking distance, `ru.su_hammer` 74. They pass the joint scan (0 on screen) and nobody had looked; I did not move their covers. A one-frame arm-twist pop is under what the eye reads at 60 a second; the sustained one (the knee's 18 frames) was the real finding.

## 7. The plain light's hold for the perfect follow-up (Game Design section 16)

"Its hit holds its pose for 6 ticks, and the window is as it lets go." A frozen body for 6 ticks reads as a freeze (a hit-stop already freezes 2). So only the **hand** is held: the contact solve keeps the striking limb set on him, riding his reaction, for 6 ticks while the rest of the body goes on with the follow-through, and lets go over the next 3. The tick the hand starts to come off is the tick the window opens.

| | The Protagonist's lights (palm, blade hand, the edge of the foot; compact) | The rival's lights (fist, plate, a line; a show of it) |
| :--- | :--- | :--- |
| What the 6 ticks show | The palm *set* on the chest or the blade on the jaw, riding him back a hand's width; the free hand stays in guard | The fist stays on the knuckles, riding the reaction; the chin lifts a few degrees and the free hand opens: a flourish, a show of it (proposed) |
| What moves | The speed row's own 4-tick follow-through: hips settle, shoulders turn on | The same, the head turning with it |
| The let go | The hand leaves over 3 ticks, straight back to guard | The hand leaves over 3 ticks and the fist drops to guard |

**Built:** the pin (the hand set on him, riding his reaction, for 6 ticks, then off over 3) and nothing else. **Proposed, not built:** the rival's chin and open-hand flourish (a 4-degree head lift and a finger-curl change in the pinned ticks: two data fields on the `plain_light` row, no new pose).

Built, off: data `beat.plain_light.pin_ticks` (6), read by the solve for a beat that says `plain: true` (Encounter's field for "a light that is no flurry's or chain's") or, with `RenderAnim.plain_pin` on, for any brawl light that is the first of its string with no burst and no flurry. The follow-through is the speed row's own (4 ticks) and the recovery its own (7). Needs from others: the beat's `plain` field (a one-line addition at the same three places as the style), and VFX's: nothing.

## 8. The tree, for commit

Mine (everything under my paths; `tools/flash/*` in the same status is not):

- `render/anim/`: `anim_body.gd`, `anim_data.gd`, `anim_fighter.gd`, `render_anim.gd`; `tools/anim_check.gd`, `tools/wave_gen.mjs`; `tools/waves/` `charge1.mjs`, `depth1.mjs` (new), `protag10.mjs`, `rival7.mjs`, `rival8.mjs`, `tip_path.mjs`.
- `data/anim/`: `pair_live.json`, `press_styles.json`, `reach.json`; `waves/` `charge1.*` and `depth1.*` (new: poses, sequences), `protag10.*`, `rival7.*`, `rival8.*` (keysets, manifest, poses).
- `docs/animation/`: `nine-cells.md`, `fighters-in-depth.md`, `hook-ready.md` (new).
- `art/animation/review/nine-cells/` (two stills: the held Y and the held B; this PC only).

Gates on a clean export of HEAD plus these files: `anim_check` passed (seed 4, 2400 ticks, press styles on, mix, snappy and fluid); `joint_scan --strict` 0 of 896 poses, 0 on screen; `held_scan --strict`, `lead_scan --strict` and `coverage_live --strict` clean; `determinism` and `determinism -- --intro --seeds=2 --ticks=900` passed. Default picture: the pose-hash comparison of section 5.

## 9. For Tools and Encounter

- **New keys for the schemas:** `press_styles.json`: `styles.<style>.hold.pose` (a map of fighter to a pose id, added on `medium` and `super`), `beat.plain_light` with `pin_ticks`. `strength` map and `styles.burst.set` were already committed.
- **New waves:** `charge1` (prefix `ch`), `depth1` (prefix `dp`), `pair_live.json` shared now names both. `wave_gen.mjs` takes a `combat` override per strike spec.
- **Encounter:** drop `style` at `brawl.gd` 351, 504 and 801 and keep `strength` and `burst`; add `plain: true` to a plain light; send `charge_full` for the charged medium; a public `DirBrawl.heldX` in place of my two private slots.

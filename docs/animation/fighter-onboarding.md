# Bringing a fighter into the animation: what he is in my data, the steps, the costs

Owner: Animation. Date: 2026-10-12. Brief (the EP, Orb's question): a workflow so four fighters can be playable soon, each with his own flavour over a large common pool. **Every time below is an estimate** (marked ~, in days of Animation's own working time; Legal's screens, Combat's recipes, Art's model and the EP's gates run beside it and are not counted unless named). Render only: nothing here touches the sim's hash.

## 1. What a fighter is in my data, and what he gets for free

| Piece | Where | What it does |
| :--- | :--- | :--- |
| **Shape language** | `shapes.json` (key P, A, E, C), `ragdoll_motion.json` (`fighters`, `shapes`), `joints.json` (`shapes`) | His idle (sway, bounce, heel, breath, a head servo), the size of his flinch by body part, his tuck, brace, skid and crumple when thrown, and a per-joint range scale (swing, twist, hinge: all 1.0 now, there for a machine's wrists). **Four languages exist already**: P circles, A crouched wedge and blades, E wedges and sweeps, C squares and steps. |
| **Pose profile** | `fighters.json` `pose_profile` | Six numbers that turn the common strikes into his own at build time: `hand_states` (his hands are never claws), `rise`, `stance` (front foot's plant), `twist` (rounder or flatter arcs), `guard_raise`, `head_pitch`. Read by `wave_gen.mjs`, never at runtime: the poses it writes are plain poses. |
| **Packs (waves)** | `fighters.json` `waves` (`strikes`, `entries`, `energy`, `more`), `pair_live.json` | The key sets that are his alone (prefix per fighter: `pr`, `rb`, `ph`, `pu`, `pk`, ...) beside the shared ones. A fighter's first body bakes his waves. |
| **Holds, reactions, press styles** | `agency.json`, `ragdoll.json`, `press_styles.json` | A knockback's drift hold, a charge's lean, the flurry looks (`speed`, `medium`, `super`, `burst`, `tech`), each with `pose` maps **by fighter** for the burst's set, the charges' holds and the squash. The rows' timings are global. |
| **Transformations** | `forms.json` | Gather, break and settle per version, on placeholder poses until a fighter has form art. |

**For free on the rig R1** (one skeleton, 22 body bones and 5 for cloth): about 40 common strikes (`w1.*`: hands, elbows, knees, kicks, headbutt, shoulder), the mechanisms of the super-heavy tier and the energy pieces (the held charge, the closing rule's reach, the wind-ups drawn whole), every reaction, fall, flight, ground contact and ragdoll, entries and taunts as sequences, the contact solve that puts any limb on any region of any body, the flight lead, the clinch's strikes, mirroring for the free arm, the cloth springs.

**What makes it read as HIS without a key set** (the order I would spend time in):
1. **Stance and guard** (`stance.*`, `personality.json`): where the weight is, the hands' height and the chin. The biggest read at the smallest cost: it is on screen for most of a match.
2. **Idle** (shape row): sway, bounce and breath; a servo glance for a machine; slow and wide for a heavy.
3. **Spine and shoulder habits** (pose profile `twist`, `head_pitch`, `guard_raise`, the clavicle hunch): round arcs against straight lines.
4. **Timing inside a strike's fixed length**: the in-between profiles (`profiles.json`: snappy, fluid) and the press style's overshoot, lag and follow-through; the contact tick does not move.
5. **Follow-through and return** (a strike's `follow`, `hold_t`, `ci_end`).
6. **How he takes a hit**: flinch gains by part, tuck and crumple targets, how far a stagger bows him.
7. **Hands and tips**: fists on heavies, blades on lights, or never a fist (`tips.json`, `hand_states`).

## 2. The steps and the time

**Step 0: the ten-second study (~0.5 day; before anything else is built).** A stub `fighters.json` entry (shape key, a first pose profile), his stance, three common strikes through his profile (a light, a medium, a heavy) and a light and a heavy hit taken, as one clip. Orb looks at that and says yes, change, or no. Nothing below starts before it. Made through Tools' launcher only (`node tools/machine/capture.mjs frames --session animation`), uncommitted, never public.

**Tier 1: his look in motion on today's systems (~4 to 6 days, then ~1 day for Orb's changes).**
| Step | Content | ~Days |
| :--- | :--- | ---: |
| 1 | Shape row (idle, hit), ragdoll targets, joint scales; the profile tuned against the clip | 1 |
| 2 | Stance and guard poses for the four stances; the idle and the turn | 1 |
| 3 | His reactions: flinch, stagger, knockdown, get-up, the charge and knockback holds | 1 |
| 4 | A handful of pieces only he has: 6 to 8 key sets (three poses each, both arms by mirroring), through Legal's screen | 2 to 3 |
| 5 | Gates (`anim_check`, the four scans `--strict`, determinism) and the pair tests against each other fighter | 0.5 |

**Tier 2 adds** (~8 to 12 days): his own tier of heavies (8 to 10 key sets at the tier's rules, the longest part: Legal screens each), the signature's poses and its contextual variants (with VFX and Combat), the energy pieces (6 to 8), transformations (forms.json poses per version; the mesh per form is Art's), and a per-fighter set of entries and taunts. A form that is only a profile and a few pieces (the Tyrant's quick revisions) is ~1 day; a form with its own body is Art's days first.

**What Orb looks at, and when:** step 0's clip; a second clip after step 2 (stance, idle, a turn, a hit); the tier-1 build in the playable when step 5 passes; tier 2 piece by piece as each lands. Never a still of work in progress outside this PC.

## 3. What the common pool lacks for these four

| Need | What exists | What it costs |
| :--- | :--- | :--- |
| **A tail (the Tyrant)** | The cloth springs: a chain of secondary bones driven by his velocity and acceleration, one step per sim tick, deterministic, five today (`x_pack`, `x_sash_*`) | **A passive tail is not rig work in the pose sense**: bones appended to the skeleton (the list in `anim_rig.gd`; every pose carries identity for them), the spring array generalised from 5 to the chain's length, a mesh part: **~3 days**, no new pose. **A tail that strikes** (Combat has `tail_whip`, `tail_jab`, `tail_spike`, `tail_sweep` waiting) is a limb kind: a chain solve for the contact (a FABRIK pass beside the 2-bone one), sockets, a joint-limit class, and poses authored with the `fk` overrides: **~6 to 8 days**. |
| **A non-human build** | One skeleton, humanoid, a single procedural mannequin mesh per palette | A different body (four arms, digitigrade legs, a big torso) is a new rig (R2) and mesh: **Art's and mine, weeks**. A big or bulky humanoid is mesh and scale on R1: no rig work. |
| **Kicks** | About 14 foot strikes and the whole tier's feet, knees, elbows, a headbutt | Nothing missing. |
| **Grabs and throws** | The clinch's strikes (the sim's locked state), the zip's tackle, lift and throw (`zp.*`) | The grab poses are authored between two R1 bodies. Any size works through the contact solve (a hand goes to a region of any body) but a throw's carry assumes R1's proportions: **~3 days** to make the set size-aware, before a big Tyrant meets a small Protagonist. |
| **Speed poses (the Cyborg's last form)** | `move.dash`, the zip's entries, the flight lead, the ghosts (at most 2 of a limb, Legal f01) | A set of ~8 poses (run lean, brake, slide, a turn at speed): **~2 days**; the smears are VFX's. His speed itself is the sim's. |

**What the rig and the solves assume about proportions.** R1 has one set of rest lengths for everyone (the pelvis at 36 units, upper arm 16, forearm 15, thigh 17, shin 17; one body height, 75 units, `bh`). A fighter differs by mesh, scale and shape row, not by bone lengths, so today nothing is per-fighter. If a fighter's visible arms or legs differ by **under about 10 percent** from R1's, nothing changes: the contact solve's step (14 to 22 units) and the strikes' slack absorb it, and `reach.json` moves by a few units: re-measure it with his packs (~20 minutes). **Between 10 and 15 percent** the authored key poses (absolute units, e.g. a hand at 54 in front) stop landing on the same targets: the scan and the closing rule need his own cover numbers, and his packs are derived with a `scale` the pose profile does not have yet (~1 day to add: wave_gen would scale the units of the derived poses). **Beyond that** he needs his own key sets and his own sockets. The joint limits (`joints.json`) are human; the `shapes` rows scale them per fighter, enough for a machine's range; extra limbs or a tail are classed "no limit" today and need their own class (included in the tail's estimate above).

## 4. What must stay equal across fighters, and what may differ

**Equal, so the brawl's tuning carries:**
- A strike's **length and contact tick by strength**: light 2 or 4 ticks to contact, medium 12, heavy 28 (14 for the launcher), a bolt 2 and a blast 12; the follow and the return by the press style's row. The sim's cues carry these; I draw them whole.
- **Reach bands by piece class** (close, mid, long) and a piece's place, limb, weight and drive: they are Combat's table, and the director's closing rule and the no-two-to-the-gut rule read them. A fighter's piece fills a band; it does not make a new one.
- The **order of what is readable**: a wind-up in plain sight for the whole of a medium or a heavy (Legal's h05 and the held lint), the armour read, the stagger.
- The joint limits' output frames: 0 past a limit on screen, for every fighter.

**May differ:** the silhouette of every pose; the tell's shape; the stance, guard, idle and turn; the ease curves inside a strike's fixed length (snappy against fluid), overshoot, lean and squash by his own press-style `pose` maps; the hands and tips; follow-through and what the free hand does; how far he flinches and how he falls; entries, taunts and transformation poses. **Speed and handling** (move speed, dash, how fast he recovers) are Game Design's and the sim's, and I only show them.

## 5. The cheapest and the most work

| | Tier 1 | Why |
| :--- | :--- | :--- |
| **Protagonist, Anti-hero** | done (and a provisional tier 2: 10 heavies each, 6 energy pieces) | Their shape rows, profiles and packs are in. |
| **Demon Cyborg: cheapest** | **~4 days** | A humanoid biped on R1; his shape C already exists everywhere (idle servo, flinch, ragdoll targets, joint scale hook), and the machine reads as stiff, square and steps: it is mostly his stance, a few signature pieces and speed poses. Mechanical suits the pose pipeline's strengths. His forms (consumption) are scale and palette on one body. |
| **Galactic Tyrant: the most work** | **~8 to 12 days for a first form**; the chain of forms on top | A tail (3 to 8 days), a build that is probably not the Protagonist's, size-aware throws, and "ten or more forms, each with a subtly different moveset": the forms are cheap as profile rows (~1 day each) but the movesets and the meshes are many. The human Tyrant during the goon phase is R1 and cheap. |

**Order I would take them in:** the Cyborg first (the fastest to a second playable pair of looks and the best test of the workflow), the Tyrant's first revision as a plain humanoid with a passive tail next, the tail as a limb and the chain of forms after, with Orb's clip gating each.

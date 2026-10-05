# Animation's side of the moveset generator (2026-10-05)

Owner: Animation. For Combat's generator (`docs/combat/moveset-generator.md` sections 1, 5.1 and 6) and Orb's answers of questionnaire 17 (`docs/ep/vision.md`). What is built, what the data says, and what is left.

## 1. Tip and path on every strike row

Every row of the four strike manifests (`data/anim/waves/{wave1,protag1,protag6,rival2}.manifest.json`, 80 rows) and every posed key set now carries `tip` and `path`:

- **tip**: hand: `fist`, `blade` (the open hand edge-on), `palm`, `heel` (the back or the bottom of the fist), `plate` (the forearm leads); foot: `ball`, `heel`, `instep`, `edge`, `sole`; elbow `point`; knee `cap`; shoulder `plate`; head `brow`.
- **path**: `line`, `arc_in` (toward the centre line, the hook), `arc_out` (away from it, the backfist, the crescent), `rise`, `drop`, `spin`.

They are the **posed** ones, read off each contact key and its look. The source is one table, `render/anim/tools/waves/tip_path.mjs`; `wave_gen.mjs` writes both onto the manifest row and the key set and stops on a strike with no entry, so no row can be left without. The Protagonist's rows use the same table with three overrides. Read them from the manifests (the key sets carry them too, so a runtime reads the posed tip from `AnimData.keysets[id].tip`).

A schema line for them is in `docs/animation/handoff/moveset-parts-schemas.patch` (the manifest and keysets schemas are closed; the patch also adds the schema for `tips.json` and its `map.json` line; with it applied `node tools/validate.js` reports 0 errors, 147 files).

## 2. The hand-state swap (confirmed)

**It works on the rival's posed heavies.** `data/anim/tips.json` holds the finger curl of each hand tip and a per-fighter rule, `swap`: for the rival a heavy blow whose key set is posed with a `blade` shows a `fist` (Orb: fists on heavies, blade hands on lights). The render does it in `AnimFighter._hand_tip`: the striking hand closes over the wind-up and opens over the return; nothing else changes, so the contact pose, the reach, the contact solve and the timing are the key set's own. Checked on the rival's overhand, haymaker, body hook and rib shot (blade posed, now fists); the uppercut and hammer were fists already; his lights stay blades; the Protagonist has no rule, so his heavies are unchanged. On by default (`--no-hand-tips` for the before); `anim_check` has the test.

**A beat can ask for any hand tip.** A beat's own `tip` (`fist`, `blade`, `palm`, `heel`) wins over the rule, for either fighter and any hand strike, light or heavy: that is the generator's hand-state swap, no new field in Animation's data. For a two-hand blow both hands take it.

**What it cannot do, honestly:** the rig has one finger curl a hand, so `blade` and `palm` are the same open hand on screen (and `fist` and `heel` the same closed one); only the wrist could tell a palm from a blade, and it is not turned. The generator may keep both as moves (the grammar, the identity weights and the stick's lean care about the difference) but the sheet cannot show it. If Orb wants the difference seen, the one thing to add is a wrist roll per tip (an extra twist on `hand_r` of about 70 degrees for a blade against a palm, a pose-level change), about a day and an eye on the joint limits. Not built.

## 3. How far a re-aim goes (replaces the guessed neighbour table)

`strike_lab.gd --reaim` plays every posed strike (80) at its own contact distance with each of the seven targets (head, jaw, chest, gut, legs, shins, arm) forced on it, through the real contact solve, and writes the result into `data/anim/tips.json` under `reaim`, one row a key set: `own` (the target it is posed for), `ok` (lands within 1 unit of the surface, no joint past its limit, no limb into the defender beyond 6 units, and the arm or leg not bent more than 1.2 radians away from the authored one's change at its own target), `edge` (lands, but strains one of those), and everything else does not land. **Read the rows, not the summary below.**

How far it goes, by limb and the target the strike is posed for (strikes that land ok, land at the edge, do not land; the counts are over the strikes of that kind):

| Limb, posed at | Re-aims that land ok or at the edge | Does not land |
| :--- | :--- | :--- |
| hand, head (16 strikes) | jaw 11 ok, chest 10, arm 10, gut 8 (the rest edge); legs 6 ok, 5 edge | shins (all 16); legs for 5 |
| hand, chest (10) | jaw 8, arm 9, head 7, gut 7; legs 2 ok, 2 edge | shins (all 10); legs for 6 |
| hand, gut (4), jaw (3), arm (1) | mostly edge: the posed height was low or high already | shins, and legs for most |
| elbow, jaw (6) | arm 5, chest 2 ok and 4 edge, gut, head 2 | legs and shins (all); head for 4 |
| elbow, chest (4) | gut 4, arm 3 | head, legs, shins |
| foot, chest (14) | gut 8 ok and 6 edge, legs 6 ok and 8 edge, arm 6 and 8, shins 5 ok and 7 edge | head (all), jaw (13) |
| foot, gut (5), legs (2), shins (2) | the neighbours below the head; chest, gut, legs, shins and arm | head, jaw |
| knee, gut (6) | legs 5 ok | everything above the gut, shins; arm 4 |
| shoulder, chest (5) | gut 5 edge, arm 2 ok, legs 4 edge | head, jaw, shins |
| head, jaw (2) | chest 2, gut 2, arm 2 | head, legs (edge only), shins (edge) |

In words: **a hand re-aims freely between head, jaw, chest, gut and arm** (about two thirds ok, a third at the edge); it reaches the legs for some and **never the shins**. **A foot never goes above the chest** (the leg cannot reach, the silhouette would be a different kick) and re-aims between chest, gut, legs and shins, a third of them at the edge. A knee only goes from the gut to the legs; an elbow between jaw, chest and arm; a shoulder or a head blow barely moves. The silhouette breaks first at the **edge**: the elbow near its limit or the spine pulled off the key pose. The sheet should list `edge` re-aims with a look, and `ok` ones need none.

The one-line rule for the generator: a re-aim is allowed when the key set's `reaim` row lists the target (ok free, edge with a look). The table in `docs/combat/moveset-generator.md` section 5.1 that was a guess can be replaced by reading the file.

## 4. The beat on the body (what I expose, what is VFX's)

A glint on the striking limb is VFX's (`press.gd`); the body gives it everything it needs, from the press hand-off (`docs/animation/press-styles.md` section 6), already live: `AnimFighter.press` (the blow's `style`, `phase`, `ticks_to_contact`, the striking `limb` and its tip `bone`, `smear`, `side`), `press_path` (the tip's position over the last 12 solves) and `press_pose(k)`. For the beat itself, the sim's beat tick (`args.beat` on the beat, Encounter's B0 field list) tells **when**; the body says **where**: the striking limb's tip, `press_path`'s newest point, for a blow that is playing, or the **next** blow's limb (its `ks.limb` with its side) for one that is coming, which I will add to `press` as `next_bone` once the beat carries the next piece. The optional beat ring in settings is a UI and VFX drawing at the fighter's feet or hands; nothing is needed from Animation for it.

## 5. The first slice's new key sets: 23 and 4, as four parked waves (matched to Combat's sheet on 2026-10-05)

Combat's review sheet (`docs/combat/pending/movegen/review-sheet.md`, regenerated after Legal's screen) lists **8 new key sets for the Protagonist and 15 for the rival** (13 lights and 2 heavies). The waves now realise exactly those, shape for shape (limb, tip, path, target, weight), one key set each, so the generator's "waiting" moves find their keys. **One wave a fighter, parked like every wave** (baked only with `--waves`, never in the fighters' `waves.more`, so no pick list draws them until Legal's go on the poses): `rival4` (prefix `rm`) and `protag7` (prefix `pm`); the signature sketches are `rival5` (`rs`) and `protag8` (`ps`), sequence waves like the existing hold waves. The bake cost when they go live is 71 poses, about 27 ms native.

| Move (sheet id) | Key set | Shape: limb, tip, path, target (weight) | Legal |
| :--- | :--- | :--- | :--- |
| rival x05 | `rm.elbow_drop` | elbow point, drop, chest (light) | none |
| rival x16 | `rm.forearm_drop` | hand plate, drop, arm | L3 |
| rival x17 | `rm.fist_drop` | hand fist, drop, head | L3 |
| rival x18 | `rm.short_uppercut` | hand fist, rise, jaw | L1 |
| rival x21 | `rm.knee_lift` | knee cap, rise, gut | none |
| rival x22 | `rm.arm_chop` | hand blade, drop, arm | L3 |
| rival x24 | `rm.lift_kick` | foot ball, rise, gut | none |
| rival x25 | `rm.fist_sweep` | hand fist, arc out, arm | none |
| rival x26 | `rm.plate_drop` | hand plate, drop, chest | L3 |
| rival x27 | `rm.low_thrust` | foot sole, line, legs | none |
| rival x28 | `rm.gut_rise` | hand fist, rise, gut | L1 |
| rival x29 | `rm.plate_hammer` | hand plate, drop, head | L3 |
| rival x30 | `rm.knee_hook` | knee cap, arc in, legs | none |
| rival y03 | `rm.fist_rise` | hand fist, rise, chest (heavy) | L1, L6 |
| rival y15 | `rm.heel_backhand` | hand heel, arc out, arm (heavy) | L6 |
| protagonist x05 | `pm.knee_hook` | knee cap, arc in, legs | none |
| protagonist x15 | `pm.back_chop` | hand blade, arc out, arm | none |
| protagonist x18 | `pm.palm_rise` | hand palm, rise, gut | L1, L2 |
| protagonist x19 | `pm.palm_lift` | hand palm, rise, jaw | L1, L2, L8 |
| protagonist x24 | `pm.lift_kick` | foot ball, rise, gut | none |
| protagonist x27 | `pm.edge_crescent` | foot edge, arc out, gut | none |
| protagonist x28 | `pm.fist_chop` | hand fist, drop, arm | L3 |
| protagonist x29 | `pm.palm_heave` | hand palm, rise, chest | L1, L2 |

What changed from the first pass (which Combat's list had not yet reached me): the rival lost eight shapes that are not on the sheet (the collar chop, elbow thrust, plate rise, plate sweep, heel stamp, rib scythe, spear rise and a hook knee to the gut) and gained the arm chop, knee lift, lift kick, fist sweep, plate drop and hammer, low thrust, short uppercut and heel backhand; the Protagonist lost the elbow drop, palm slap, palm drop and elbow back and gained the lift kick, the palm lift and heave, the fist chop and and his back chop now lands on the arm. The rival has no palm anywhere (his row). **Legal's conditions are kept in the poses, not only tagged:** a rising blow keeps the feet down, no turn, the arm lowering at once (the follow comes down to 70 or lower), and its hand is chambered **low and forward, never at a hip** (x 18 or more, nothing in the hip zone); a dropping blow is one arm; the palms are open hands, never clawed; `pose_lint` runs each Legal tag on the poses (`not_at_hip`, `no_leap`, `no_held_raise`, `hands_open_or_claw`, `no_clasp`) and passes.

**Checked:** `wave_gen`, `pose_lint` (0 errors on all four waves), the strike lab's reach sweep and the contact sheets (`art/animation/review/rival4`, `protag7`), `validate.js`, and `joint_scan --strict --waves` (the new poses included, none past a limit). **Not yet:** Legal's eye on the poses themselves (the sheet screened the shapes), Combat's own ranges (the rows borrow the nearest posed strike's range and ticks, flagged `_estimate`), Orb's eye on the looks.

**The four signature sketches** are the tell (30 ticks or more, held) and the held end of each fighter's martial arts signature: the rival's, a sunk stance with the lead blade hand out at eye height measuring the distance and the head low, and after the launcher his striking arm lowered and open, the head turned up after the rival; the Protagonist's, the open hands low and wide with the palms down in a coiled circling step, and after the launcher the feet settled, the hands loose and in front of the hips, and a slight bow. They are held poses, so Legal screens them by eye every time (no hand at the hip, no crossed arms, no arm held raised); each carries `not_at_hip` and `hands_open_or_claw`, and `pose_lint` passes them.

## 5a. The pose flags on a manifest row

Every manifest row now has a `flags` list: the flags among the twelve Combat's generator reads (`leap`, `spin`, `multi_turn`, `travelling`, `clasped`, `wrists_together`, `two_hand_chamber`, `cupped_at_hip`, `drawn_to_hip_then_thrust`, `hip_chamber`, `held_raise_overhead`, `passes_through`) that the key set's three key poses **show**. `wave_gen` reads them off the poses (`render/anim/tools/waves/flags.mjs`) with the numbers `pose_lint`'s Legal rules use, and the schema line is `docs/animation/handoff/manifest-flags-schema.patch`. They are factual and conservative, because the generator **refuses** a move whose key set lists one:

| Flag | Present when | Today |
| :--- | :--- | :--- |
| `leap` | both feet off the floor in a key pose (or the airborne family) | the drop kick (both fighters) and the body ram |
| `spin` | a blow that is not a spin turns 100 degrees or more at contact | the body ram (158 degrees) |
| `multi_turn` | hip and spine twist over 140 degrees in any key pose | the body ram |
| `clasped` | both hands fists within 6 units | none |
| `wrists_together` | both wrists within 7 units at contact | none (the two-hand blows keep a hand apart) |
| `two_hand_chamber` | both hands within 10 units in the wind-up | none |
| `cupped_at_hip`, `hip_chamber`, `drawn_to_hip_then_thrust` | the striking hand in the hip zone in the wind-up (Legal's width, RL-076: **x 8 or less for a closed fist in a transient wind-up, x 14 or less for an open hand, a palm or any held pose**; height 24 to 44); open or clawed for `cupped`; thrust 36 or more ahead for `drawn_to_hip_then_thrust` | none. The closed-fist zone is the narrower one on purpose: the shipping uppercut dips its fist low and in front of the hip (x 12) before it rises, and Legal cleared it; an open hand in the same place is the cupped hand Legal rules out (and `pose_lint`'s `not_at_hip` already checks x within 14) |
| `held_raise_overhead` | a hand above 80 in the follow-through | none |
| `travelling` | **never from the poses:** a spin that travels is a motion, not a pose; no strike key set carries one | none |
| `passes_through` | **never from the poses:** it is the contact solve's: it puts the tip on the defender's surface (minus the fist), so a reach past it is not possible, and `strike_lab` finds every strike landing within 1 unit of the surface | none; a lint on the solve can be added if Legal wants it checked rather than argued |

## 6. What I did not plan, as asked

- **LT plus a face button, the mid-range lunge** (the zip in, the strike and the zip out in a stylistic blur): nothing planned until the EP's prototype is shown to Orb. What exists to build on: the press styles' smear and after-image hand-off, the rush and entry poses, and the contact solve's step-in.
- **A juggle of up to 5 skill strikes, a fully held lone heavy that may launch:** nothing needed from Animation; the contact solve already reaches a defender in the air (the gated drop kick and sweep prove it), and the press styles already treat a held blow as the heavy.

## 8. Legal's figures on the held poses (RL-076, 2026-10-05)

Shoulder width on the rig is 20 units (the upper arms' joints, measured on the baked poses). Hands apart is the 3D distance between the two hand bones; the hip zone is x 14 or less and height 24 to 44 in a pose's own coordinates, so a hand is outside it by height or by reach.

| Held pose | Hands apart | In shoulder widths | Hands (spec x, height) | Outside the hip zone | Hand state |
| :--- | ---: | ---: | :--- | :--- | :--- |
| `rs.hold.sig_tell` (the rival's tell) | 30.0 | 1.5 | lead (29, 64), rear (12, 54) | yes: 64 and 54 are above 44 | both flat open hands; the lead one is a flat open blade at eye height: the open state has no curl, so no point, no two fingers, no beckon |
| `rs.hold.sig_end` (the rival's held end) | 23.2 | 1.16 | (16, 44), (10, 54) | the low hand is at 44, the edge of the zone, with x 16 (the zone is x 14 or less), the other at 54 | open |
| `ps.hold.sig_tell` (the Protagonist's tell) | 42.2 | 2.11 | (26, 46), (22, 46) | yes: x 22 or more | open palms down |
| `ps.hold.sig_end` | 26.0 | 1.30 | (18, 42), (18, 42) | yes: x 18 | open |
| `zp.hold.tackle` | 24.0 | 1.20 | (40, 52) twice | yes | open |
| `zp.hold.lift` | 24.0 | 1.26 | (25, 65) twice | yes | open, shoulder height |
| `zp.hold.throw` | 24.4 | 1.22 | (42, 50), (40, 46) | yes | open |
| `zp.hold.carried` and `lifted` | 30.0 | 1.55 | (14, 47) and (14, 48) | yes: 47 and 48 | open, limp |

The two tells keep both hands apart by at least 1.5 shoulder widths (the rival's, widened from 1.32 in this round) and 2.1 (the Protagonist's) and outside the hip zone for the whole hold; neither pose has an arm above 80. The held poses (`rs`, `ps`, `zp`) carry `not_at_hip` and `hands_open_or_claw`, and `pose_lint` passes all of them.

**The three poses Legal asked to see full size** are in `art/animation/review/legal-rl076-fullsize.png` (chamber, contact and follow of `rm.fist_drop`, `rm.plate_hammer` and `pm.palm_heave`). The raised arm lowers at once on all three: the wind-up's high hand (84, 83 and 24 high) is transient, the contact is at 68, 74 and 62, and the follow is at 63, 71 and 60, at or below the contact, and the strike block's recover phase eases it back to the guard (10 ticks for a light blow). Nothing is held: no follow is above 80 and no hold pose has an arm raised. `rm.plate_hammer`'s contact was lowered from 82 to 74 and leaned further forward for this review, so it no longer reads as a raised arm.

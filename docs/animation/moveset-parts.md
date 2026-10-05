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

## 5. The first slice's new key sets: 21 and 4, as four parked waves

**It fits, as one wave a fighter** (the wave names are `^(wave|protag|rival)[0-9]+$`, so the rival's is `rival4` and the Protagonist's `protag7`; the signature sketches are `rival5` and `protag8`, sequence waves like the existing hold waves), **built in this release, parked like every wave** (baked only with `--waves`, never in the fighters' `waves.more` until Legal's go, so no pick list draws them live):

| Wave | Holds | Poses |
| :--- | :--- | ---: |
| `rival4` (prefix `rm`) | 12 lights and 1 heavy | 39 |
| `protag7` (prefix `pm`) | 8 lights | 24 |
| `rival5` (`rs`) | the signature's tell and held end (two sketches, also as two sequences) | 2 + 2 |
| `protag8` (`ps`) | the same for the Protagonist | 2 + 2 |

The bake cost when they go live is 63 poses, about 25 ms native, a tenth of what the pair bakes now.

**The shapes** (limb, tip, path, target; each is a key set with the generator's `strike.<name>` as its Combat id, so a beat's `piece` finds it once the wave is in the pick lists):

| The rival (`rm.`) | Shape |
| :--- | :--- |
| elbow_drop | elbow point, drop, chest (a short light version of the dropping elbow; Combat's named "new" shape) |
| forearm_drop | hand plate, drop, arm (the signature's opening piece) |
| fist_drop | hand fist, drop, head (the signature's piece against a guard) |
| gut_rise | hand fist, rise, gut |
| collar_chop | hand blade, drop, chest |
| elbow_thrust | elbow point, line, chest |
| hook_knee | knee cap, arc in, gut |
| plate_rise | hand plate, rise, jaw |
| plate_sweep | hand plate, arc in, chest |
| heel_stamp | foot heel, drop, shins |
| rib_scythe | hand blade, arc in, gut |
| spear_rise | hand blade, rise, jaw |
| fist_rise (heavy) | hand fist, rise, chest |

| The Protagonist (`pm.`) | Shape |
| :--- | :--- |
| knee_hook | knee cap, arc in, legs (Combat's named "new" shape) |
| elbow_drop | elbow point, drop, chest (Combat's named) |
| palm_slap | hand palm, arc in, head |
| palm_drop | hand palm, drop, arm |
| blade_back | hand blade, arc out, chest |
| palm_rise | hand palm, rise, gut |
| edge_crescent | foot edge, arc out, gut |
| elbow_back | elbow point, arc out, jaw |

**Combat's own list of the 21 lives in its scratch, not in the tree.** I built the ones its document names (the elbow drop on both, the knee hook, the plate and the fist dropped for the signature, the heavy fist rise) and filled the rest from the grammar's gaps in each fighter's identity weights (fists, plates, blades, drops and rises for the rival; palms, blades, arcs and the foot's edge for the Protagonist), 12 + 1 and 8 as sized. If Combat's generator asks for other shapes the swap is cheap (each is three poses over a base), so **please send me the sheet's list of the 21 by limb, tip, path and target** and I will rename or replace the ones that differ.

**Checked:** `wave_gen`, `pose_lint` (0 errors on all four; the notes are small reach clamps and elbow folds the limb pass trims), the strike lab's reach sweep (every strike lands at its Combat-row contact distance on the hips alone, in the borrowed ranges), the contact sheets (`art/animation/review/rival4`, `protag7`), and `validate.js` (with the schema patch). **Not yet:** Legal's screen of the shapes (the eye screen: every new shape is new), Combat's own ranges (the rows borrow the nearest posed strike's range and ticks, flagged `_estimate`; the reach tables in the review folders are what to correct them with), Orb's eye on the looks, and a hand-state or re-aim row for each (they come from `tips.json` as for the posed ones, after the next `--reaim` run).

**The four signature sketches** are the tell (30 ticks or more, held) and the held end of each fighter's martial arts signature (`docs/combat/moveset-generator.md` section 3.2, martial B): the rival's, a sunk stance with the lead blade hand out at eye height measuring the distance and the head low; after the launcher his striking arm lowered and open, the head turned up after the rival; the Protagonist's, the open hands low and wide with the palms down in a coiled circling step, and after the launcher the feet settled, the hands loose at his sides and a slight bow. They are held poses, so Legal screens them by eye every time (no hand at the hip, no crossed arms, no arm held raised); I wrote each with `not_at_hip` and `hands_open_or_claw` marks.

## 6. What I did not plan, as asked

- **LT plus a face button, the mid-range lunge** (the zip in, the strike and the zip out in a stylistic blur): nothing planned until the EP's prototype is shown to Orb. What exists to build on: the press styles' smear and after-image hand-off, the rush and entry poses, and the contact solve's step-in.
- **A juggle of up to 5 skill strikes, a fully held lone heavy that may launch:** nothing needed from Animation; the contact solve already reaches a defender in the air (the gated drop kick and sweep prove it), and the press styles already treat a held blow as the heavy.

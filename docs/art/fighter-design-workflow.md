# Fighter design workflow: from Orb's one-page brief to a fighter on rig R1

Owner: Art Director. 2026-10-12. For the EP and Game Design (`docs/design/fighter-pipeline.md`). Orb's ask (2026-10-12): "Ideally each character should have their own 'flavor' of attack animations and movesets, with a large common pool of attacks to pull from. Can we establish a workflow for the characters so I can get at least four into the playable build soon?" This file is the art half. Working labels, **pending Legal review**. In-progress character art stays on this PC and in working files; none of it goes on a public page or in the public repo (Orb, 2026-10-06; fighters as they appeared in past builds are fine). Everything is original: archetypes, not anyone's characters.

Names: the vision's "Galactic Tyrant" became **the Empress** (she/her) on 2026-09-29 (Orb); her tail became the bladed mantle. "The Anti-hero" is the neutral id `antihero` in `data/anim/fighters.json` and the stand-in `RIVAL`.

---

## Part 1. Where the four stand today

| | Protagonist | Anti-hero (the rival) | Empress | Demon Cyborg |
|---|---|---|---|---|
| **Shape key** (`data/anim/shapes.json`) | P: circles, open, forward | A: crouched wedge and blades | E: wedges and sweeps | C: squares and steps |
| **Look status** | **Approved by Orb, 2026-10-04** (broad body, about 20% broader than before; dark plated fists; short swept tuft; unmasked) | **Approved by Orb, 2026-10-04** (slim, about 8% slimmer; long tail and three flat coat plates; the bare wedge head; glasses frame C) | **Not approved.** Turnaround exists (masked, 2026-09-29); the refine sheet gives two silhouette options (a wide mantle; a crown and train). Orb has not picked | **Not approved.** Turnaround exists (masked, 2026-09-29); the refine sheet gives six directions. Orb called him "the least compelling of the launch fighters" (2026-10-01); no pick recorded |
| **Sheets** | `art/concepts/refine/approved-protagonist-turnaround.svg`, `approved-protagonist-faces.svg` (8 expressions), `launch-pair-protagonist.svg`; older `art/concepts/turnaround/protagonist-turnaround.svg` | `approved-rival-turnaround.svg` (with the glasses' attachment points), `approved-rival-faces.svg`, `rival-glare-c.svg`, `launch-pair-rival.svg`; forms: `art/concepts/forms/anti-hero-forms.svg` | `art/concepts/turnaround/empress-turnaround.svg`, `art/concepts/refine/empress-refine.svg` | `art/concepts/turnaround/cyborg-turnaround.svg`, `art/concepts/refine/cyborg-directions.svg` (Stepper, Stack, Furnace, Frame, Prosthetic, Sprinter) |
| **Silhouette** | Done and read-apart tested against the rival (100, 50, 25 px, flat black, overlaid) | Done, same test | Two options, flat-black at 120 and 40 px; no read-apart test against the others yet | Six options, flat-black at 120 and 40 px; no read-apart test yet |
| **Palette and lane** | Aura `#8fd6ff`; colour-blind triple done (`data/art/colour-vision.json`: protan `#30a6a6`, deutan `#35b6ab`, tritan `#9c90d5`) | Aura `#9a80d8`; triple done (`#6b0bcb`, `#5b0bcb`, `#6b0bcb`); aura colour per form in `data/art/auras.json` (Regalia, Sovereign, Apex; Orb's preference between three sets still open) | Proposal only: olive with a moss accent `#b8c96a` (`style-guide.md` 3.3); **no aura colour, no colour-blind triple** | Proposal only: dark red body, coral accent `#d8705f`; **no aura colour, no triple** |
| **Face** | Approved, eight expressions | Approved, eight expressions; glare frame C, eyes fully hidden (a question is open: always on, or only the taunt and the seal break) | Refined unmasked face (neutral, hurt, cold smile); not approved | Faces in the six directions only; the older close-up round (display cluster) was CONDITIONAL and predates the "no masks" call |
| **Parts off bones** | Tuft (2 spring bones), two sashes (R1 has `x_sash_a1/a2`, `x_sash_b1/b2`) | **Tail of hair, 4 + 3 bones, and a body tail: R1 has none** (`docs/animation/launch-pair-coverage.md`: four tail strikes blocked on the bones) | Topknot (2), mantle (two chains of 3), nine rigid hem blades, a diadem, the guard of honour (a separate retinue figure, one shared model): none built | Back unit (1), cables (two chains of 2 to 3): none built |
| **Forms and tiers** | No form sheet. Legal: no hair-colour ladder; show tiers by aura shape, markings, eyes and posture (RL-028) | Forms sheet on the older Coil body (Regalia, Sovereign, Apex; spine plates F1 to F6); not redrawn on the approved look | None. Orb likes the numbered "revision" joke; each revision is one or two data values and one tell, never the franchise's shapes | None. Molts; the hidden weapons appear only in the final form |
| **Legal** | RL-036 GO; launch pair RL-063 to RL-065. Conditions: fists solid, dark, plated, never light balls; tuft swept, never a curl; heat seams never red or gold | RL-066 and RL-068 (the glasses: asymmetric tapered lenses, violet frame, one pale-violet glare, 0.4 s at most; no readout on a lens; no beard); regalia break: no gold, no red glow | RL-036 GO with the front-view ring and crescent checks; RL-028 CONDITIONAL (final-form looks). Rule: no pale-and-purple, no horns, low collar flare only (revision 9 to 12 rule) | RL-045 CONDITIONAL (remove scan bars and pips; paler peach) and the screen's "avoid a horn-and-antenna silhouette", "not black-and-red". Food, consuming and the companion are mechanics: `docs/legal/fighter-concepts-review.md` section 4 |
| **In the build today** | Yes, on R1, as the stand-in `PROTAGONIST`; waves protag1 to 11 | Yes, on R1, as the stand-in `RIVAL`; wave1 is his own | No | No |
| **Missing before Animation and Rendering can put him in** | Nothing for tier 1. For tiers 2 to 4: a form strip (aura shape, markings, eyes, posture at 86 and 46 px) | Tail and second strand bones in the rig; the forms redrawn on the approved body | Orb's pick; unmasked turnaround; palette and aura with the colour-blind triple (see the flags below); mantle and topknot chains; the guard figure; a revision strip | Orb's pick of a direction; a new unmasked turnaround; palette and aura with the triple (flags below); back unit and cables; the companion's look |

### Flags found while checking the four against the colour rules (measured today)

- **Empress accent `#b8c96a` is too close to the wound marks**: against bruised `#f2e6a0` it measures 11.9 (default), 9.1 protan, 9.5 deutan; against battered `#ffb454` 3.2 protan, 5.3 deutan; against UI's fresh `#dfe6f0` 12.1 tritan. The rule is 20 default and 14 simulated. A yellow-green is the wrong lane colour; the search should pick a clearer green or a different family (step 3 below).
- **Cyborg accent `#d8705f` collides with the wound marks and "blood owns red"**: against broken `#ff5c8a` 16.2 default and 4.8 tritan; against battered `#ffb454` 15.2 tritan. Keep the dark red as a body value and give the aura a different colour family, or keep red off the aura and keyline entirely.
- **The two proposed lanes against each other**: `#b8c96a` against `#d8705f` is 13.0 under deutan vision (below the 20 for two fighters that can meet). Both lanes change in step 3, so this resolves itself if the search runs with all four in the room.
- The two fighters in the build have none of these problems (the presets were revised on 2026-10-07 against UI's actual marks).

---

## Part 2. The workflow

One rule across every step: **Orb's eye comes early and cheap (three flat silhouettes, not a finished sheet); Legal's eye comes before drawing (the brief) and before anything is built (the design).** A fighter that fails a gate goes back one step, never forward.

### Step 0. Orb's one-page brief (Orb, with Narrative and Game Design)
One page: the archetype and his role (`docs/design/roster-twelve.md` axes), a sentence on the shape language (P, A, E or C, or a new one), what he is to the world, hue family wishes, and one sentence on what he must never look like. Art needs from it: **build** (heavy, medium or light; tall or short), **silhouette hook** (one asymmetric feature that reads at 46 px: a tail, a mantle, a back unit), **forms** (how many, and what each changes), **appendages**.

### Step 1. Legal pre-screen of the brief (Legal)
The strip test on the one page, before a line is drawn: remove the labels and colours and describe the design in one sentence. Output: a list of conditions (like the four above). Cost: a short note. It prevents drawing a design that must be redrawn.

### Step 2. Three silhouettes (Art; **Orb picks one**)
Three flat-black silhouettes at fight size, **86 px** (a close brawl) and **46 px** (the old far framing), each in the lineup of all existing fighters and overlaid on each nearest neighbour. Differences must come from mass and from one hook, never from detail (the three-colour test and the silhouette test in `style-guide.md` 3.1). **Gate:** each option must be at least as far from every existing fighter as the launch pair are from each other at 46 px (Art measures the pair first and states the number on the sheet), and no horn-and-antenna read at 12 px. Output: one sheet, three options, a recommendation and a line on cost for each (does it need a new bone chain?). Orb may mix two.

### Step 3. Palette, lane and the colour-blind triple (Art; checked by tool)
R1's body is **seven palette slots**: body, legs, arms, skin, gear, accent, hair (`render/anim/anim_rig.gd`). Pick them from the chosen silhouette, then:
1. **Lane colour and aura** in an agreed hue family, never orange, yellow or gold (fire owns them), never mid blue (water), never red as a mass or an aura (blood owns it), and **never a colour the crowd or the HUD already uses** (the civilians' colours; UI's stance and wound colours, `ui/data/colour_vision.json`). Art checks the list against `ui/core/ui_look.gd` and Rendering's civilian colours each time.
2. **The colour-blind triple** (protan, deutan, tritan) from `art/concepts/colour-vision/search.mjs`, checked with `check.mjs`: 25 or more from every other fighter by default and 20 or more under each simulation; 20 or more (default) and 14 or more (simulated) from the wound marks, the guard `#5aaaff` and the sky near the fighters. Run with **all** fighters in the room, so two new lanes are not found separately.
3. **A non-colour mark** from a different glyph family to every existing one (a ring, a slash, then for example a chevron, a bar, a cross of dots), used on the body, the aura, the HUD chip and the strip marker (`art/concepts/colour-vision/marks.mjs`).
4. **The world-light check**: the body against the tinted ground at every key and mood is 15 or more, the aura 20 or more (`art/concepts/sky/world.mjs checks()`).
Output: swatches, the triple, the numbers, the data rows for `data/art/colour-vision.json` and `data/art/auras.json`. (UI's `lanes` must match: Tools' cross-check fails otherwise.) Orb sees the swatches in the lineup only if two real options remain.

### Step 4. Face and head (Art; Orb approves)
Eight expressions at cut-in size (neutral, hurt, laugh or sneer, rage, triumph, taunt and two of his own), unmasked (masks are parked for one future fighter), and the head's silhouette signature. Any head gimmick (the rival's glasses) is drawn to Legal's conditions from the start. **Gate:** reads at 24 px in flat black; the face is distinct from the other fighters' at 24 px.

### Step 5. Parts that hang off bones (Art specifies, Animation builds the bones)
Every non-body part is one of two kinds:
- **Rigid on one bone**: a plate, a collar flare, a diadem, a hem blade, a back unit, a pack. Costs a mesh part and a palette slot; no bone.
- **A chain** (hair, topknot, cloth, a tail, cables, a mantle): an `x_` bone chain of 2 to 7 bones driven by the spring solver, written on the sheet as: chain name, bone count, parent bone, stiffness class (stiff, medium, soft), and what it must do at 46 px (stream, bob, whip, billow).
R1 today has 22 core bones plus the pack and four sash bones; a chain of any other kind is new bones and the spring solver's chain mode (`docs/animation/hair-and-tail.md`: "R2", 46 bones for all four, cap 32 bones per fighter; not built). Triangle budget: near 2,500 a fighter; Art's turnaround part lists run 1,600 (Protagonist), 1,840 (Empress), 1,980 (Cyborg). Output: the part list with triangles and bones, and the sockets (strike points, hit regions, emitters, attachment points for cosmetics, `docs/animation/pose-pipeline.md` 2.2).

### Step 6. Forms per power tier (Art; Orb picks the idea, not the sheet)
Tiers 1 to 4 (data: the ladder in `data/fighters/<ID>/ladder.json`; transformations are cinematic and uninterruptible, Orb 2026-09-29). Each tier changes **at most four things**, in this order of cost: (1) **palette** (free: a swap of the seven slots), (2) **aura** (data in `data/art/auras.json`: shape, hue, intensity), (3) **a part set** (rigid parts shown or hidden, new meshes but no bones), (4) **a chain or a build change** (new bones or a different build profile). A form never changes the silhouette except at the break frame (`data/anim/forms.json`: gather, break, settle); the wear stays (damage is a property of the body, not the form). Never a hair-colour ladder (Legal). Output: a four-up strip at 86 and 46 px per fighter, the tell for each tier in one line, and every aura colour through the colour-blind check. Tier 1 is done first; later tiers are separate briefs so a fighter ships at tier 1 while the ladder is drawn.

### Step 7. Turnaround, build profile and the hand-off (Art; Animation and Rendering take it)
Front, three-quarter right (left is its mirror), back, the pose in play, read at 80, 40, 24 and 12 px, wear (fresh, bruised, battered, broken), and the part list from step 5. Plus the data: **build profile** (segment ratios, widths, mass class, joint-limit scale, socket offsets, `pose-pipeline.md` 2.4), the **shape key** entry in `data/anim/shapes.json` (idle and hit multipliers), the fighter's entry in `data/anim/fighters.json` (shape, waves, `pose_profile`) and the lane data of step 3. Animation runs the joint-limit lint (`data/anim/joints.json`; `--strict` after any pose change) on his poses.

### Step 8. Seen in the engine, in motion (Rendering stills, Art judges; **Orb looks once, in motion**)
One still set from the build (`node tools/machine/capture.mjs still --session art ...`, one at a time) at 86 and 46 px against the other fighters, at the five sky keys, under the three simulated visions and through the wound stages. **Orb looks at it in motion, not as stills**: he has said he cannot judge the aura and the blades from screenshots alone and wants to see them in motion (2026-09-29). Gate: nothing from steps 2 to 4 gets worse on the real body.

### Step 9. Legal's final screen and records (Legal; Art files them)
The checklist in `docs/legal/originality-rules.md` (the silhouette and three-colour test, no franchise, no name), `docs/art/ai-prompt-policy.md` prompt record, `docs/legal/asset-origins.md` row, and the disclosure line. A design is not GO until Legal says so and a human author is named (`ai-prompt-policy.md`).

**Where Orb's eye comes in:** step 0 (the brief), step 2 (pick one of three silhouettes), step 6 (the idea of each tier), step 8 (one pass in motion). **Where Legal's does:** step 1 (the brief), step 5 (any new mechanic part), step 9 (the final).

---

## Part 3. What a re-skin of the stand-in gives for free, and what needs new parts

**Free (data only, no code, no new bones):**
- Any palette in the seven slots; one mesh is built per palette and cached.
- The idle and flinch personality, by shape key (`data/anim/shapes.json`: `sway`, `hz`, `bounce`, `heel`, `breath`, `sweep`, `servo`; and the hit multipliers).
- His strikes without their own silhouette, by `pose_profile` in `data/anim/fighters.json` (rise, stance, twist, guard raise, head pitch, hand-state substitutions), derived from the rival's wave 1 by `render/anim/tools/wave_gen.mjs`. This is the "large common pool" with a personal flavour on top.
- Aura, flash colours, wear and wounds (`data/art/`), the colour-blind triple, the lane marks.
- A build proportion change inside the one skeleton (per the build-profile spec, if Animation has it built: ask).

**Needs new parts:**
- Any non-body shape that moves on its own: a tail, a mantle, cables, a long strand. New `x_` bones and the chain solver (not built; R1 has only the pack and four sashes).
- A new silhouette part with no bone (a back unit, collar flares, a crown): mesh parts only, but a new part table in `anim_rig.gd` (Rendering).
- A form that changes the body's mesh (more than a palette and an aura).
- A move whose silhouette is unlike every pool pose (the Cyborg's consume, the Empress's surveyor line): new poses in the fighter's own wave (about 50 own poses, about 30 deltas a fighter, `pose-pipeline.md` section 1).
- A unique mechanic's look (the companion backup drive, the Empress's guard of honour, the Anti-hero's pride crash): new meshes, flashes and VFX.

---

## Part 4. Which is cheapest, and which needs rig work

**Tier 1 is "his look on today's systems, no unique mechanic".**
- **Already at tier 1:** the Protagonist and the Anti-hero (approved looks on R1, as the stand-ins). The Anti-hero's only gap is the tail, which is rig work (R1 has no tail bones; Combat's four tail strikes are blocked on it). His tier 1 ships without the tail strikes or with the hair mass static.
- **Of the two not in the build, the Cyborg is the cheapest to tier 1.** His shape (C: squares and steps, a heavy, blocky body, a box head) is rigid parts on the R1 core; the back unit rides `spine_2` like today's `x_pack`; the cables can ship as a rigid, static mesh at tier 1 and gain two chains of 2 or 3 later. No skeleton change. His cost is Orb's pick among the six directions, not rig work.
- **The Empress needs the rig work.** The mantle is the largest part of her silhouette (two chains of 3 with nine rigid hem blades), her topknot is a chain, and the guard of honour is a separate retinue figure on a shared model. As a rigid panel on `spine_2` the mantle reads as a board, so her tier 1 wants the chain solver from day one.
- **A tail (the Anti-hero's) and a mantle (the Empress's) are the two chain jobs; "a non-human build" needs none of the four.** All four are humanoid on the one skeleton. The Cyborg is the heaviest build and needs a build profile (mass class heavy, wider shoulders and a box head), not a new skeleton. A quadruped, a serpent or a swarm (future fighters) would need a second skeleton, which the one-topology rule (`pose-pipeline.md` 2.2) does not allow without the EP.

### Estimates (marked as estimates; Art counts rounds, one round = one brief and one report)

| Fighter | Art rounds to tier 1 | Orb decisions | Legal | Other directors | Tiers 2 to 4 (Art) |
|---|---|---|---|---|---|
| Protagonist | 0 (done) | 0 | 0 | 0 | 2 rounds (a form strip, aura per tier through the colour check) |
| Anti-hero | 0 (done) | 0 for tier 1; the aura set and the glasses question are open | 0 | Animation: tail chain, 4 + 3 bones (about 1 unit) | 2 rounds (the forms sheet redrawn on the approved body) |
| Cyborg | 3 to 4: three silhouettes from the chosen direction, palette and triple, unmasked face set, turnaround | 3 (pick a direction; the silhouette; one look in motion) | 2 (brief, final); the food and consume mechanics are a separate screen | Rendering: part table (back unit, cables); Animation: cable chains later (about 1 unit) | 3 rounds (molts, the final form that brings the hidden weapons online) |
| Empress | 4 to 5: the pick between the two options (or three new), palette and triple, unmasked face set, turnaround, the guard figure | 3 | 2; the revision ladder is a separate screen | Animation: mantle and topknot chains (about 1 to 2 units) and a cost check for cloth; Rendering: part table; the guard figure on a shared model | 3 rounds (the revision strip: one or two values and one tell each) |

These are estimates of rounds, not of days: the cost that varies is **Orb's pick and Legal's screen**, which gate every fighter and sit in series. Running Cyborg and Empress step 2 in parallel makes the picks come in one sitting.

**Order I recommend:** one brief to Art now for the Cyborg's and the Empress's three silhouettes each (step 2), with the colour search run for all four lanes in the same brief (step 3's flags above), so Orb makes both picks together; Animation's chain solver in parallel, so the tail and the mantle are not waiting when the picks arrive.

---

## Part 5. The city list (when the fighters are moving)

From `docs/rendering/lanes-look.md` ("For Art: stand-ins"), parked behind the fighters:
1. **Seven shapes drawn with stand-ins, never seen**: `terrace`, `sawtooth`, `thatch`, `quay`, `crane`, `mast` and a plain `crown` (built, checked for size only; not in today's data). Art draws each in the district's look when a district names it.
2. **The octagonal shapes are four-sided** (`chimney`, `lighthouse`, the Gatebell's spire); the belfry is a dark band rather than open arches; the lighthouse has one band where the brief has two. Art decides whether each is worth the parts.
3. **A data file for the district palettes** (today in `render/core/shapes.gd`): `data/art/districts.json`, Art-owned, with the eight palettes and window patterns per look; Tools adds the schema.
4. **The two new landmarks' looks**, the ledger hall and the crown tower, which Rendering has drawn from the data (`lanes-look.md` Landmarks). Art reviews them against the district brief and Legal's landmark clearance (RL-040); Art owns a brief only if the EP wants them redrawn.

None of this is started. It waits for the EP's word.

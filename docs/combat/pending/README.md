# Combat's parked data

**Start here (2026-10-30): `audit-2026-10-30.md`.** What is ready to land and in what order, what has landed and can go, what tools still read, and what waits on Orb or on a build. The next landing's parts are in `split/README.md`.

`nine-cells.md` (2026-10-12) is the paper for `recipes.brawl.json`, now live: a pool for every cell of the brawl, the heavy tier and the energy pieces in them, how it was measured, and the lists for Tools and Animation. The change that reads it is `../brawl-hook.md`, for Encounter.

`grapple/` (2026-10-16) holds `hybrid.json`: the grapple on A as Orb picked it (the catch and the clinch, the clinch first), its paired phases as data with Game Design's numbers (`docs/design/grapple.md`), each fighter's throws by send and vicious blows, and Legal's asks on each phase. The note is `../grapple-hybrid.md`.

`launch/` holds the launch enders as the file Encounter's launch anywhere reads (`data/combat/enders.json`): `enders.json` on the live recipes, to land now, and `enders.next.json` on the split, to land with it; and a draft schema for Tools, `combat-enders.schema.json` (the note is `../launch-enders.md`). `throwables/` (2026-10-18) holds `throwables.json`: the pick-up and throw by size and by fighter, on Game Design's ruling (`../throwable-cars.md`).

`rally/` (2026-10-25) holds each fighter's own rally links and his sell in the daze, on Game Design's 23d frame (`rally.<fighter>.json`, `combat.rally/1`, a one-pager each), and with the draft schema. The choreographer's variety scoring is live as `data/director/rally.json`. The overview is `rally/README.md`.

`energy/` (2026-10-23) holds the four fighters' energy kits on Game Design's frame (`docs/design/energy-overhaul.md`): a one-pager and a `combat.energy/1` data file each (`protagonist`, `rival`, `empress`, `cyborg`), the frame by cell and each fighter's templates (`README.md`), and the draft schema `combat-energy.schema.json`. The overview and the director's choreography are `../energy-movesets.md`.

`biomes/` (2026-10-23) holds the biome layer of `../biomes.md` (with a scene per biome for Orb in `../biomes-sampler.md`). **Landed:** `sigvariants.json` with its schema (`data/combat/sigvariants.json`, e1521ef5, read by Encounter's W1 and W2; the park copy deleted 2026-10-28) and `launch.biome.json` (moved to `data/combat/launch_biome.json` by W3, d0d91c29). Still parked: `ground_atoms.json` (skid-stops, landings, approaches and crater shapes by look class), its draft schema `combat-ground-atoms.schema.json`, and `cases.biomes.json` (nine fixture cases for Tools).

`choreo/` (2026-10-19) holds `feel.json`: recoil exits, ricochets, clash meets and turns, each with its three beats for Camera and what Encounter, Animation and World need (`../choreography-feel.md`).

`roster/` holds sketches for fighters who are not in the build: identity rows for the Demon Cyborg (three options) and the Empress, their generated movesets, and the builder that makes them (`../roster-rows.md`). Their cards are in `cards/` beside the first two. None of it is part of the recipes window.

`split/` holds the next recipes file, `recipes.split.json` (2026-10-16): the split by path, the held X's leans and the new posed pieces, built on the live file with the training dummy's pools in. It lands with Animation's fourth patch, Encounter's mash key and Tools' two schema keys. The note is `../split-and-pieces.md`. `roster/` also holds the guards' kit, generated (`moveset.guard.json`).

## The biome layer (`biomes/`): apply plan

Keyed by World's fine biome names (`data/biomes/climate.json` `fine`, 1460d351). City and village key by settlement. **Order: Tools, then World, then Encounter, then Animation and VFX.** Every step sits behind the park's switches, so each can land alone.

1. **Tools** (on Orb's word)
   - The schemas `combat-sigvariants.schema.json` and `combat-ground-atoms.schema.json` go into `tools/schemas/`.
   - Map rows for `data/combat/sigvariants.json` and `data/combat/ground_atoms.json`.
   - The nine cases in `cases.biomes.json` go into `tools/fixtures/cases.json`, with the two files copied into the virtual tree.
   - The xref rules are in each schema's description, including two new ones: every variants key is a fine name or a settlement, and each `fineId` matches `climate.json`.
2. **World**
   - **A fine-name lookup for the director.**
     - On a gen 2 planet it returns the column's fine name; on gen 1 it returns the alias.
     - Settlements override, as `city` and `village`.
     - Keep the settlement codes apart from the fine ids: in `BIOME_NAME`, 7 and 8 are town and city ground, while in `climate.json` they are jungle and savanna.
   - **The join with window 2** (`docs/world/scratch-build/gen2-w2/`, parked; accepted by the EP 2026-10-23).
     - World's per-biome profiles (`data/biomes/ground.json`) are the source of grip, absorb, rough and furrow. This park's `ground_atoms.json` carries only the choreography looks, by look class; its brakes and biome map are dropped.
     - **World adds `look` to each profile** (window 3 or 4), naming one of the nine new classes or the five built ones. `biomes.md` §4.1 lists the proposed look for each biome.
     - Until then, a biome reads its profile's surface, and only the built looks show.
     - Window 2's `rough` tumbles more bodies in jungle, mountains and volcanic, and a tumble holds control. That is Game Design's to rule, as shingle's tumble was.
   - **Aftermaths:** the ten kinds (`part` with its run-up), `surfaceAt` with their strips, fire's hazard wear and breakable floes.
   - **Props:** window 2 lays trees. Still needed: lone trees, outcrops, boulders, bergs and vents as props the planner can find.
   - **Physics:** ice's control point at rock's stop, the embed threshold scaled by depth, and the crater shapes.
   - **The hash:** the sim numbers in `ground_atoms.json` (crater factors, refill, the embed factor, the mud wait, the landing slide, the root trip, the ice control point) go into World's hashed data, or `replay.gd` hashes the file.
3. **Encounter** (and Simulation for the hash)
   - **Step 1, bit-identical:**
     - read `sigvariants.json` in place of `templates.json` `beam.variants`, `crater.gd` `SCORCH_VARIANT` and `beam.gd`'s branches, with `aftermathOn` and `byPersonality.enabled` off;
     - delete `beam.gd`'s unused `VARIANT`;
     - Simulation adds the file to `DirData.dataHash`.
   - **Step 2:**
     - `planBeam` picks by World's fine name;
     - `aftermathOn` and the personality term go on (LANE SWEEP's own widths, if adopted);
     - the five twists and the ocean's HIT, with the water rule.
   - **Launch:** the `biome` block in `launch.json`, already in its hash:
     - the eight candidates, `surfaceLand`, `downBonus` (forest's hard-coded +8 moves into it) and `distMul`;
     - the stick and freshness rules;
     - MARSH SWALLOW's sure embed and ICE SKID's control point.
   - **The ground atoms:** the skid-stop, landing and approach by look class, and three events: `skid_stop`, `ground_land` and `crater_shape`.
4. **Animation**
   - Eleven shared stop poses, each with the fighter's flavour: heel dig, plough, sink slide, spin-out, deep plough, skitter, sink drag, heel peel, root catch, pebble slip, skim sink.
   - The ice landing slide.
   - Bounce multipliers for the new look classes.
   - Read the three events.
5. **VFX** (with Rendering for the decals)
   - The trails, bursts and ejecta by look class, and the crack decals.
   - The variants' looks (steam, shards, plates, powder, spray, embers, ash) and debris looks for the ten new names (`debris.gd` reads names).
   - The parted sea with its wave and run-up, the fire line and the ember strip.
   - **The look gate (ADR 0010)** applies to each: a side-by-side, and nothing fades or dissolves. The sea's walls fall, a fire burns out to char, and an ember strip cools to dark crust.

**Waiting on Orb:** LANE SWEEP (`adoptProposed`) and TIDE CLEAVE (a rename of the ocean row).

## The launch pair's own strike and entry rows

`strikes.launchpair.json`: Combat's rows for the Protagonist's eight own strikes and two entries, and for the Anti-hero's body hook and rib shot (range, ticks, classes, tags), replacing the rows Animation borrowed from wave 1 slots. Lunge and clear are left for Animation's strike_lab.

## Generated movesets

`movegen/`: the moveset generator's inputs (`parts.json`, `identity.json`, `cells.json`, `lock.json`), its reference script, the generated movesets for both fighters over all five stances (128 rows each; the martial arts stance on three strengths, `three-strengths.md`; the launcher and energy in reach for the slice C2t, with a plan for vicious, `c2t-content.md`; the heavy tier and the energy pieces as Animation posed them, `nine-cells.md`) and the review sheet. Its README has the counts and the keys for Tools. Parked; design in `../moveset-generator.md`.

## The launch pair: readiness and apply order

`apply-order.md`: the five files below checked against HEAD `a56187a` on 2026-10-03, what had drifted, the order they move into `data/combat/` (with Simulation's split and Encounter's slices 10 and 11), what each step does to the goldens and the frozen parity copy (never refreshed), and every new key for Tools. Fighter ids in the five files are `protagonist` and `rival`.

## The launch pair (parked; Game Design sets the scope)

`launch-pair.json`, with `../launch-pair-movesets.md`: what the Anti-hero and the Protagonist ship with in the next update (23 sketches for him, 37 for the Protagonist), each fighter's energy kinds, On the Chin's beats, and one finisher each as a row in the live finishers' form (they pass Tools' validator on a scratch copy), with the rival's glasses note.

## Start here: `waves-index.md`

One page for Orb: what each of the six waves adds in plain words, its new-pose count, what it needs before it can play, and the order they could go live in.

## Brawls without a launch, and trade beats (parked; waits for Game Design's recipe table)

`brawl-endings-and-trades.md` and `templates.brawl.json`: the knock-back launch vector, eight endings that are not a launch (3 level, 4 knock-back, 1 double slide), six trade beats and the lights-against-a-heavy pair, as beat lists in the live tick form. The `ends` and `sends` tags they rely on are on every strike and throw in `moveset.antihero.m0.json`. Which one plays when is left to Game Design, after Orb's questionnaire 14.

## The alchemist's recipes, the traded-blows set piece and the charges (parked; the rules are Game Design's)

`brawl-prep.md`, `recipes.brawl.json` and `channel.rival.json`: Combat's data for Encounter's brawl (`docs/director/brawl-plan.md`). The next version of the live recipes (a path on every piece, the beat point by path, and for three strengths a `brawl` block that maps each press of X, Y and B to a pool, the mediums, the `burst` block and a stated `fallback`: `movegen/three-strengths.md` section 9; since 2026-10-12 the heavy tier on B with the stand-ins as its fallback, the launcher by send and energy in reach: `nine-cells.md`) and On the Chin's beats with the `chin_plant` cue. Slice B1 runs on the live file unchanged. Not moved.

## Go-live step 1 (for Animation to apply after Orb's review of the wave 1 pack)

`golive-step1.md` and `golive-step1.picks.json`: the render-only change that lets wave 1's 23 long and mid-range strikes play in today's game. Two new pick lists for `data/anim/keysets.json` (11 light, 10 heavy), 2 gated strikes, the 7 that need a small step in at today's 58 u, which templates use which list, and three optional render-side rules. No sim file, no combat data and no data hash change.

## Wave 1: the Anti-hero's strike specs (for Animation; not for applying)

`wave1-strikes.md` and `strikes.antihero.wave1.json` are the 38 key strikes as specs to pose from: base family, limb and target socket, weight, reach and the strike's own contact distance, timing, limb tags and one line on the look. Animation has posed the 34 that do not need the tail (23 authored contact sketches, 11 derived; `art/animation/review/wave1/`), and the sheet carries its measured reaches; the 4 tail strikes are held until Orb rules on the tail. Section 6 of the sheet notes what a per-strike contact distance changes in the live contact data at M0. Legal screened wave 1: GO, with its conditions now in the rows (`docs/legal/rule-of-cool-screen.md`).

## Wave 2: the Anti-hero's entry specs (for Animation; not for applying)

`wave2-entries.md` and `entries.antihero.wave2.json` are the 15 entries (rush 6, stand 5, retreat 4) as specs to pose from: path, when it is offered, timing, where it plays, the new poses and what they derive from, the strikes it favours and one line on the look. 12 new poses. Eleven entries work on today's sim; the arc dive, the skid and the spiral need a path on the `rush` op, and the lane step needs fight lanes. Legal screened wave 2: GO, with its conditions in the rows.

## Wave 3: the ping-pong rally and the flight paths (not for applying)

`wave3-pingpong.md` and `pingpong.antihero.wave3.json`: the rally's beats in ticks, the `return` strike class, the 7 return blows and 16 enders as they play in a rally, three knock patterns, the defender's answers, and one new pose (the intercept turn). Section 2 is the one definition of the three flight paths (spiral, arc, ground) and the `path` event, for Encounter, Camera and VFX.

## Wave 4: the grab and throw family (for Animation; not for applying)

`wave4-grabs.md` and `grabs.antihero.wave4.json`: 16 pieces (2 grabs, the hold, 7 throws, the tackle, the dive grab, the reversal) with grip, ticks, limb tags, where each throw sends the rival and one line on the look; the turning throw as Game Design ruled it; the `held` state the sim must carry for the pinned ragdoll. 22 new poses, and 2 for the tail throw, which is held until Orb rules on the tail. Legal screened waves 3 and 4: GO, with its conditions in the rows.

## Wave 5: the pulse clashes and the beam answers (for Animation; not for applying)

`wave5-clashes.md` and `clashes.antihero.wave5.json`: the fist clash, the blur exchange and the grapple lock on Game Design's pulse (ticks, what is composed from the strike and grab pools, the strain poses), and the three looks of a perfect block against a signature (swat, split, walk through). 9 new poses for the clashes and 9 for the answers. Legal screened waves 5 and 6: GO, with its conditions in the rows; Game Design ruled their open numbers (`moveset-rules.md` section 11(h) to (j)).

## Wave 6: the energy family (for Animation and VFX; not for applying)

`wave6-energy.md` and `energy.antihero.wave6.json`: 7 emission shapes with range and travel, 6 hands, the 13 strikes that also emit, 5 energy poses, and all 31 energy strikes as emitter and shape. 7 new body poses. Every range band keeps at least 8 lights and 4 heavies, with a broken limb too.

## Wave 7: the first kit (for Animation; not for applying)

`wave7-first-kit.md` and `kit.antihero.wave7.json`: 3 specials (barrage volley, cutting step, grip and drag), 2 place signatures (the sweeping line, the ground shatter) and 6 showcases, each with its phases in ticks, variants by range, place and form, what it builds on from waves 1 to 6, and its sketches. 24 authored sketches, and 2 for the tail whip showcase, which is held. Legal screened it: GO, with the barrage volley's gather changed; Game Design ruled its numbers (`moveset-rules.md` section 11(k)).

## The Anti-hero's rich M0 piece list (not for applying)

`moveset.antihero.m0.json` is the piece list behind `../m0-rich.md`: 38 key strikes with limb tags, the energy shapes and emitters, 15 entries, 6 feints, the 16-piece grab family, 4 taunts, the set pieces' ticks, 3 finisher shapes, and the lists of 8 specials, 8 signatures and 16 showcases. It has no schema and no loader. It becomes `data/fighters/<id>/moveset.json` at M0, when Tools writes the `combat-moveset` schema and Encounter's composer reads it. The counts in `../m0-rich.md` section 2 are computed from it.

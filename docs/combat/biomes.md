# Biomes that change the fight: signatures, launches and the ground

Owner: Combat and Choreography. Date: 2026-10-23. Paper and three parked data files (`pending/biomes/`); nothing is built. **Ruled by Game Design the same day** (`docs/design/rulings-2026-10-23b.md`), and folded in: section 1b lists what each ruling changed.

**Orb** (2026-10-23): "pour resources into improving our planet generation, biomes, fighter animations". **The goal here:** the new biomes change how a fight plays out, not only how it looks. This covers pillar 7 (signatures adapt) and choreography that reads the ground.

## 0. What exists today

- **The signature.** One beam for everyone. Its variant is picked once, when the signature is planned, from the biome under the defender, and holds for the whole path. There are seven rows (`data/combat/templates.json` `beam.variants`; `sim/director/beam.gd` keeps an unused copy). In play, the rows differ only in:
  - the groove's depth and width (`sim/world/crater.gd` `SCORCH_VARIANT`);
  - three looks in `beam.gd` (desert dust and sparks, forest fire);
  - the debris looks in `render/vfx/debris.gd`, which reads the variant's name (glass flecks, spray puffs, larger embers).
- **The ice biomes are aliased.** On a planet arena, `WorldPlanetWorld.BIOME_NAME` reads the ice sheet as `mountains` and sea ice as `plains`, because the director's tables know only seven names. So a polar fight fires RIDGE BORE or FIELD SCAR. Every new biome would be aliased the same way until the tables know it.
- **The launch planner** (`sim/director/launch.gd`) has one biome number, DRIVE DOWN's +8 over forest. It finds MOUNTAINSIDE by biome name, and takes 45 off a predicted landing in the sea (MOUNTAINSIDE, which names its own landing, is exempt).
- **The ground.** World has five surface classes with a brake each (`data/biomes/contact.json`: paving, rock, soil, sand, rubble). Animation's bounce reads them (`data/anim/ground.json`). The recoil exits and ricochets are built (`data/anim/recoil.json`).

## 1. The rules over all of it

1. **The ground changes distances, looks and the world, never when a press the brawl would take is taken.** That is Orb's press feel (the shifted pillar 2).
   - **Two things the ground decides already hold control today:**
     - a carried body's journey (a launch or a long skid): control returns when it ends, so a lower brake returns it later;
     - an embed: World's 60-tick down state when a slam digs 1.75 bh deep.
   - **Game Design ruled both so they keep to the rule (section 1b):**
     - on ice, control comes back where the same send would have stopped on rock, and the rest of the slide is a skate;
     - an embed keeps today's rate on every surface, with MARSH SWALLOW the one deliberate embed;
     - mud's 6-tick wait on movement is accepted.
   - **A recoil exit's landing slide comes after control has returned:** momentum he can act out of. Nothing here makes a new tumble.
2. **Nothing is offered where its feature is missing, and everything is behind switches.**
   - Both new blocks have `enabled`.
   - Both have `touchBuilt`, which gates their rows for today's five classes: the sand and rubble landing terms, the built classes' crater shapes and sand's sink.
   - With `touchBuilt` off, a world without the new biomes plays exactly as today even with the blocks on.
3. **Today's rows are carried exactly.** The seven built variants keep their groove numbers and looks. With `aftermathOn` and the personality term off, moving to the new table is bit-identical. Game Design ruled both on, so the table lands in two steps: first both off, then on.
4. **Keys.**
   - **Biomes are keyed by World's fine biome names** (`data/biomes/climate.json` `fine`, 1460d351: 0 ocean, 1 plains, 2 forest, 3 desert, 4 mountains, 5 ice_sheet, 6 sea_ice, 7 jungle, 8 savanna, 9 tundra, 10 taiga, 11 wetland, 12 beach, 13 highland, 14 volcanic). Each fine row carries its `fineId`, and the cross-check holds every one to `climate.json`.
   - **City and village key by settlement.** They are the settlement grounds the director already names (`WorldPlanetWorld.BIOME_NAME` 8 and 7), each row carrying its kind (`city`, `town`). A settlement's ground overrides the fine biome under it, so a beach town fires the village's row.
   - **Until the director reads the fine name,** a gen 2 planet shows it each fine biome's alias: jungle and taiga play forest's row, savanna, tundra and wetland plains', beach desert's, and highland and volcanic mountains'.
   - Surfaces are keyed by World's classes. Each new class says what it reads as until World builds it.

## 1b. Game Design's rulings, folded in

| # | Game Design ruled (2026-10-23b) | What changed in the park |
| :--- | :--- | :--- |
| 1 | The candidates' values accepted as a set. The stick still wins, freshness goes by kind, and QA's bands are as proposed | `launch.biome.json` gains `rules` (stick wins, freshness by kind, personality) and `qa`. The cross-check proves the largest total the biome terms can add (44) stays below `stickWins` (200) |
| 2 | On ice, control returns where the same send would have stopped on rock (brake 0.8); the rest is a skate | `ground_atoms.json`: the ice skid-stop carries `controlAtBrake` 0.8, and its skid-stop gains `skate`. ICE SKID's text says so |
| 3 | Embeds keep today's rate on every surface: the threshold scales with the depth factor. MARSH SWALLOW always embeds. QA's row is 0.2 to 1 embeds a minute | `ground_atoms.json` gains `embedThresholdScales` and `qa`; the embed factor is how deep he sits, not how often. MARSH SWALLOW gains `alwaysEmbeds` |
| 4 | Mud's 6-tick wait accepted, only at the end of a skid in mud | The mud stop's note says so |
| 5 | A fire line and a glowing ember strip hurt lightly, by fire's hazard rules, within the 15% hazard cap. Flying over costs nothing; cooled crust is plain ground | The savanna and volcanic aftermaths gain `hazard`, and the table's text says so |
| 6 | The care term decides; the per-candidate bonuses are accepted as flavour. The signature's personality term goes on, inside every collateral budget | `byPersonality.enabled` is on |
| 7 | All five twists stand. Water rule: a fighter in water surfaces set within 30 ticks, with no down state beyond, landed once he surfaces. The ice sheet's push-back is distance only | `sigvariants.json` gains `waterRule`; the water twists cite it; the ice sheet's GUARD line says he guards throughout |
| 8 | Ocean against plains: HORIZON CLEAVE keeps its name and gains its own aftermath. The sea parts (for 1.5 s, row 10), then a wave pushes anything at the surface 2 bh along the beam's line. A HIT over the sea drives him under. TIDE CLEAVE as its name: Legal's to confirm, no objection | The ocean row carries it (section 2b), with my surge kept as the wave's run-up on the shore. TIDE CLEAVE is cleared by Legal (RL-175) and waits on Orb |
| 9 | LANE SWEEP costs the hero by the standing rules, with no special case: kills go on the firer's account, the tier's budget caps them and a row over budget evacuates. Near occupied houses the carer narrows to 0.6 and the villain widens to 1.3 | The village row gains `collateral` and its own `personality` (0.6 and 1.3 near occupied houses) |
| 10 | The parted sea lasts 1.5 s (90 ticks), Combat's, not 3 s | The ocean's `part`: `openTicks` 90 |

## 2. Signature variants by biome

The full rows, with every outcome's line, are in `pending/biomes/sigvariants.json`. The ten new rows:

| Biome | Variant | The groove (depth × width) | Trees | What it leaves for the rest of the fight |
| :--- | :--- | :--- | :--- | :--- |
| **Ice sheet** (today read as mountains) | **ICEFIELD THAW** | 0.9 × 1.0 | none | **Glaze:** the meltwater refreezes, and the groove reads as ice for the match. A slick strip |
| **Sea ice** (today read as plains) | **FLOE SPLIT** | 0.6 × 1.0 | none | **Split:** each floe on the path breaks in two, 1 bh apart. A lead of open water, a real gap |
| **Jungle** | **VINE SHEAR** | 1.0 × 0.9 | felled inward across the cut | **Clearing:** the strip loses its canopy cover, and the trunks lie across it (props a ricochet can plant on) |
| **Savanna** | **GRASSLAND BLAZE** | 0.8 × 1.2 | burned | **Fire line:** the grass burns outward, 1 column every 15 ticks for 4 s, up to 12 columns each side. It burns props, and a fighter standing or sliding in it takes fire's light hazard wear |
| **Tundra** | **FROST HEAVE** | 0.9 × 1.0 | none | **Heave:** the rim is thrown up as frozen plates twice the usual berm. A slide stops against them and a ricochet plants on them |
| **Taiga** | **PINE BREAK** | 1.0 × 1.0 | snapped, crowns drop | **Snow dump:** snow off the trees refills 40% of the groove within 2 s. A shallower scar |
| **Wetland** | **MIRE BOIL** | 1.1 × 0.9 | area | **Flood:** the groove fills to the water table at once. A water trench under the ocean rules |
| **Beach** | **SHORE SCOUR** | 1.0 × 1.1 | area | **Flood from the sea:** where the floor is below sea level within 30 columns of open water |
| **Highland** | **SCREE RUN** | 1.2 × 0.9 | area | **Scree:** on a slope steeper than 0.25, rubble runs downhill up to 10 columns. A strip that tumbles a slide |
| **Volcanic** | **CRUST SEAR** | 1.3 × 0.8 | burned | **Ember:** the groove glows for 10 s, then reads as crust. It lights props and grass, and a fighter on it while it glows takes fire's light hazard wear |

**Where the leavings go.** An aftermath is laid only on the groove's columns in the variant's own biome. Where the beam carves on into the next biome, the groove there is plain.

**The seven built rows keep their grooves and looks:** HORIZON CLEAVE, BOULEVARD RAZE (city and village), FIELD SCAR, FIRESTORM, GLASS TRENCH and RIDGE BORE.
- HORIZON CLEAVE also gains the ocean's own aftermath (section 2b).
- TIDE CLEAVE, cleared by Legal (RL-175), waits on Orb's pick. FURROW SCAR and CANOPY BURN stay unadopted notes.
- LANE SWEEP, the village's own row, is in `proposed` (section 2b).

**Outcome flavour.** Every row has a line for each outcome: CLASH, GUARD, DODGE, HIT and ESCAPE.
- **Most lines are presentation,** and they come mostly for free from the ground atoms (section 4):
  - a guard's push-back is the surface's skid-stop;
  - a hit's landing digs the surface's crater;
  - a dodge throws up a screen of the material;
  - a clash marks the ground below the meeting point.
- **Five lines are rules** (marked `rule:` in the data):
  - **Ice sheet, GUARD:** the push-back on the glaze slides 2.5 times as far.
  - **Sea ice, HIT:** when the lead opens under him, he drops into the water and climbs out.
  - **Tundra, GUARD:** the push-back stops against the heaved plates.
  - **Wetland, HIT:** he lands in the flooded trench.
  - **Beach, HIT:** the sea floods the cut behind him, and he lands in it where the floor is below sea level.
  - **Ocean, HIT** (section 2b): he is driven under.
- **The water rule** covers every twist that puts him in water: he surfaces set within 30 ticks, with no down state beyond that, and counts as landed once he surfaces.

**Against pillar 7.** The table has 17 rows.
- All ten new rows differ from each other and from the built ones in what they carve, what they do to trees and what they leave.
- **Ocean and plains** are settled by the ocean's ruled aftermath (section 2b).
- **City and village** still play alike until Orb adopts LANE SWEEP (Legal has cleared it).
- **The personality term** of `signature-variants.md` §5.1 is on, as ruled: near people the carer narrows the bite and the villain widens it, inside every collateral budget.

## 2b. The two pairs that played alike

| Biome | Built | Now | What sets it apart |
| :--- | :--- | :--- | :--- |
| **Ocean** | HORIZON CLEAVE, carving as plains does | **HORIZON CLEAVE with the ocean's own aftermath** (ruled, in `variants`) | **The sea parts:** for 1.5 s the groove is an open trench walled by water. Then the sea rushes back as a wave that pushes anything at the surface (fighters and props) 2 bh along the beam's line. A HIT drives him under, and he surfaces set within 30 ticks. Where the wave meets land within 40 columns it runs up the shore (wet ground, props knocked over); it moves no fighter beyond the 2 bh push and puts no one in water. The groove and looks stay today's |
| **Village** | BOULEVARD RAZE, the city's row exactly | **LANE SWEEP** (proposed, read only with `adoptProposed` on) | A low, wide graze along the lane (0.7 × 1.3), with a structure radius 1.4 times as wide at a bite of 0.7. A row of low houses is each partly flattened, not one gutted: the scar runs along the ground, where the city's runs up through towers. Collateral by the standing rules (row 9): near occupied houses the Protagonist's graze narrows to 0.6 of its width, sparing more of the row, and the villain's widens to 1.3 |

- **The surge and the wave don't conflict.** My surge is the same wave reaching land, so it stays as the wave's run-up on the shore. Row 8's 2 bh push is the only thing it does to a fighter. On the shore it wets the ground and knocks props over, and it puts no one in water.
- **My TIDE CLEAVE's deeper, narrower groove stays withdrawn:** the ruled row keeps today's groove, and only its 1.5 s parting came back (row 10).
- **TIDE CLEAVE as the ocean's name:** Legal cleared it (RL-175), and Game Design has no objection. It waits on Orb.
- **LANE SWEEP:** Legal cleared it (RL-175), and Game Design ruled its collateral (row 9). It waits only on Orb (`lane-sweep-for-orb.md`).
  - Every death is on the firer's account, and the hero's own cost him (his cost meter, and Witness).
  - The tier's budget caps the deaths, and a row over budget is evacuated instead.
- **Proven by the cross-check:** with LANE SWEEP adopted, all 17 rows carve differently (groove, structure radius and bite, trees and aftermath) and all 17 names end on different words.

## 3. The launch planner by biome

A block for `data/director/launch.json` (`pending/biomes/launch.biome.json`).
- **The shared terms apply to every new candidate** as they do to SMASH ACROSS: noise, care at the landing, distance, new biome, water, the repeat penalties and launch anywhere's freshness.
- **Each new candidate joins `SENDS`,** so the stick's aim and the launch enders reach it.
- **The block rides `launch.json`,** which the replay's data hash already covers.
- **Ruled (section 1b):** the stick still wins (the biome terms never outweigh `stickWins`, and a held stick's kind is never changed), and freshness goes by each candidate's kind.

| Candidate | Offered when | Send | Score (first values) | What happens |
| :--- | :--- | :--- | :--- | :--- |
| **CLIFFSIDE** | A rise ahead steeper than 1.2 over at least 2 bh, out to 166 bh, found from the heights and not from a biome name | across | 18, +1 a bh of rise (cap 8); villain +2 | MOUNTAINSIDE for any biome: highland crags, volcanic cones, sea cliffs. He hits the face: the slide's wall stop, or an embed |
| **ICE SKID** | Ice within 1 bh of him | across, low and flat, force 0.8 | 14; +6 when it ends in open water, +8 against a berg; hero +2 | **Ice to skid on:** a long slide for little force. Its length is World's ice brake. Ending in a lead puts him in the water. **Ruled:** he has control again where the same send would have stopped on rock, and the rest is a skate he can act out of |
| **MARSH SWALLOW** | Mud under him, at most 12 bh up | down | 16; hero +6, villain −2 | **The marsh swallows the slam:** it always embeds (the one deliberate embed, as ruled), he sits 1.8 times as deep, the crater closes again and little is destroyed, so the carer likes it |
| **TREE LINE** | 2 to 6 trunks on the line within 60 bh | across, low | 10, +2 a trunk; hero +2 | **Trees to smash through:** each trunk snaps and slows him by 12%, the way BUILDING SMASH chains buildings |
| **SKIM ASHORE** | He is over water, and the path skims 6 times or fewer and lands on dry ground within 160 bh | across, low | 14, and the water penalty is waived | Fights over the sea come back to land. That answers the old ocean-heavy launch mix |
| **DOWNHILL** | The ground falls 4 bh or more within 40 bh ahead, on rubble, turf, snow, ash or shingle | across | 8, +0.8 a bh of drop (cap 12) | He tumbles down the slope |
| **VENT LIFT** | A vent within 2 bh (World's prop) | up | 12; villain +2 | The vent's blast adds a quarter to the launch's lift: the landscape answers back |
| **PROP SMASH** | A lone tree, an outcrop, a boulder or a berg on the line within 40 bh | across | 10; hero +2, villain +2 | A building smash with no people and no chain. The prop breaks and he stops at it |

**Terms on the landing's surface,** added by the kind of send:
- **Snow:** +6 down and +2 across, and the impact hurts 0.85 as much. A drift is soft.
- **Mud:** +8 down and −4 across (a marsh catches a skid). The impact hurts 0.85 as much.
- **Ice:** +6 across.
- **Ash:** +4 down, with a soft landing.
- **Sand:** +2 down, with a soft landing.
- **Crust:** +4 down.
- **Shingle:** +2 across.
- **Rubble:** +2 across and +2 down.

The sand and rubble rows are today's classes, so they apply only with `touchBuilt` on.

**Two tables replace hard-coded numbers:**
- **`downBonus`:** forest keeps today's +8. Jungle and taiga add 8, wetland 6, tundra 4.
- **`distMul`:** open country rewards the long haul, closed country shortens it. Savanna 1.25, tundra 1.2, sea ice 1.2, ice sheet 1.15, wetland 0.8, jungle 0.7.

**What to measure** (QA's bands, as ruled; in the block's `qa`):
- each new candidate is taken in 5 to 30% of the launches where it is offered;
- no candidate takes more than 40% of launches inside its biome;
- the share of launches landing in the sea falls when SKIM ASHORE is on.

## 4. Choreography that reads the ground

`pending/biomes/ground_atoms.json`, keyed by look class.
- **World's ground profiles** (`data/biomes/ground.json`, window 2) are the source of grip, bounce absorption, roughness and furrow.
- **Each profile names its biome's look class** (`look`, World's window 3 or 4; accepted by the EP).
- **Until a profile names one,** a biome reads its profile's surface, so only the built looks show.
- **This file carries no brakes or biome map of its own.**

### 4.1 Surfaces

| Look class | Biomes (proposed for World's `look`) | Reads as until built |
| :--- | :--- | :--- |
| **ice** | sea ice; the glaze | rock |
| **snow** | taiga, ice sheet | sand |
| **frost** | tundra | rock |
| **mud** | wetland | sand |
| **turf** | savanna, highland | soil |
| **litter** | jungle | soil |
| **ash** | volcanic, where World lays it | sand |
| **crust** | volcanic; the ember strip after it glows | rock |
| **shingle** | beach | sand |

The aftermath strips override the biome's look (`stripLooks`): glaze reads ice, ember reads crust, scree reads rubble, and a flood reads water.

### 4.2 Skid-stops by surface

How a body carried along the ground comes to rest. That covers a short knock-back's upright slide, a long one's skid (World's slide on the feet) and a guard's push-back.

| Surface | The stop (Animation's pose) | The trail (VFX) | Left at rest |
| :--- | :--- | :--- | :--- |
| paving, rock, crust | heels dig in, a hand down | scrape and sparks; grind and chips; glowing cracks | crouch |
| soil, ash | both feet plough | a furrow and its berm; an ash plume | crouch |
| sand | the feet sink and slide | a spray and a trough | low crouch |
| rubble | a roll | debris | on a knee |
| **ice** | **a spin-out:** he turns through the slide and a hand brakes him, ending square to the one who sent him. Control is back where rock would have stopped him; the rest is a skate | a polished streak | crouch |
| **snow** | a deep plough, a powder bow-wave | a channel | shin-deep |
| frost | skittering steps, the crust cracking | a crack line | crouch |
| **mud** | the feet sink and are dragged | a mud wave | **sunk:** movement waits 6 ticks while he pulls free, only at the end of a skid in mud; presses are taken as ever (accepted) |
| turf | the heels peel a strip of turf that flips up | a peeled strip | crouch |
| **litter** | above 1,100 speed a root catches a foot: a stumble into a roll, a look inside the stop's own distance and time | leaves scattered | on a knee above that speed, else crouch |
| shingle | the pebbles roll under him, a slip and a catch | a pebble spray | crouch |
| water | a skim, then he sinks | a wake | waist-deep (World's water rules decide) |

**The recoil exits' landings** (skip, handspring, tuck, backflip):
- on ice the exit lands into a 1 bh slide;
- on snow the feet sink 0.25 bh, and on mud 0.3 bh;
- each new surface has its own touch-down puff (frost spray, powder, mud splash, ember flick and so on);
- the five built classes land as today unless `touchBuilt` is on (sand's 0.1 bh sink and puff are such a row).

**The approach.** A dash or zip from the ground starts with the surface's look: a slide-in on ice, a powder kick on snow, splashing steps in mud, a spray kick on sand and ash, a wake burst on water. It is a look, not a speed.

### 4.3 A slam's crater by material

Each factor multiplies today's bowl. These are proposals for World's crater (`crater.gd` `dig`, `contact.json` `embed`).
- The rows for paving, rock, soil, sand and rubble apply only with `touchBuilt` on.
- **Embeds keep today's rate on every surface,** as ruled: the embed threshold scales with the surface's depth factor. The embed factor is how deep he sits, not how often. QA's row is 0.2 to 1 embeds a minute.

| Surface | Radius × depth | Rim, wall | Refills | Body embeds | Cracks and ejecta | Extra |
| :--- | :--- | :--- | :--- | ---: | :--- | :--- |
| paving | 1.0 × 1.0 | 1.0, 1.0 | | | tilted slabs | |
| rock | 0.9 × 0.8 | 0.6, steep 1.4 | | | a star; blocks | |
| soil | 1.0 × 1.0 | 1.0, 1.0 | | | clods | |
| sand | 1.3 × 0.7 | 0.8, slack 0.6 | 30% in 3 s | ×1.2 | a fan of sand | |
| rubble | 1.0 × 1.0 | 1.2, 0.9 | | | debris | |
| **ice** | 1.0 × 0.6 | 0.4, steep 1.5 | | | radial rings; shards | **On sea ice, a bowl deeper than the floe breaks it and opens water under him** |
| **snow** | 0.9 × 1.4 | 0.5, 1.3 | 20% in 20 s (drift) | ×1.5 | a powder ring | |
| frost | 1.0 × 0.8 | **plates 1.6**, 1.2 | | | polygons; frozen clods | |
| **mud** | 0.8 × 1.2 | 0.2, 0.8 | **60% in 4 s: the marsh closes** | **×1.8** | a mud splash | Water stands in it |
| turf | 1.0 × 1.0 | peeled turf 1.1 | | | turf flaps | |
| litter | 1.0 × 1.0 | 1.0, 1.0 | | | roots; leaves and clods | Trees within 1.5 radii lean outward |
| ash | 1.2 × 0.8 | 0.7, 0.7 | 20% in 3 s | ×1.2 | an ash plume | |
| crust | 0.9 × 0.9 | 0.8, 1.3 | | | a glowing star; crust plates | Glows for 8 s |
| shingle | 1.1 × 0.8 | 0.9, 0.7 | 30% in 2 s | | a pebble spray | Fills with water within 30 columns of the sea |

**Events,** for Animation, VFX, Camera and Audio. Each rides an event that exists today where one does:
- `skid_stop`: who, surface, from, to, speed, end, spin;
- `ground_land`: the recoil cue's touch-down, with surface, slideBh and sinkBh;
- `crater_shape`: World's crater event, with the surface and the shape it dug.

## 5. The data and its schemas

| File (parked in `pending/biomes/`) | Target | Schema |
| :--- | :--- | :--- |
| `sigvariants.json` | `data/combat/sigvariants.json` | **`combat.sigvariants/1`**, draft `combat-sigvariants.schema.json` |
| `launch.biome.json` | a `biome` block in `data/director/launch.json` | **`director.launch/1`** gains `biome` (the schema is closed), draft `director-launch-biome.fragment.json` |
| `ground_atoms.json` | `data/combat/ground_atoms.json` | **`combat.ground_atoms/1`**, draft `combat-ground-atoms.schema.json` |

**Proven with Tools' own validator** in a scratch root, with the drafts and map rows added:
- all three files read 0 errors and 0 warnings (the ground atoms schema carries both switches, `embedThresholdScales`, `qa`, `stripLooks`, `controlAtBrake` and `skate`; the variants schema carries `aftermathOn`, `waterRule`, `proposed`, `adoptProposed`, `areaMul`, the `part` aftermath and `hazard`; the launch fragment carries `rules` and `qa`);
- nine refusals, three for each schema, each fail at their pointer, or at its parent for the aftermath's either-null-or-object rule. They are written in the shape of `tools/fixtures/cases.json` as `cases.biomes.json`.

**Cross-checks:**
- every biome has a variant and a surface;
- every surface has a skid-stop and a crater;
- each surface's `exists` flag matches `contact.json`;
- every candidate is in exactly the sends list of its own send;
- the largest total the biome terms can add stays below `stickWins`;
- the built rows match `crater.gd`.

Each schema's description lists the cross-references proposed for Tools' xref.

## 6. What each consumer needs

- **World:**
  - its final biome ids;
  - a biome name for each new biome, ending `BIOME_NAME`'s aliasing of ice;
  - a `look` on each ground profile (window 3 or 4), naming one of this park's look classes;
  - `surfaceAt(x)`, including the aftermath strips;
  - the nine aftermath kinds, and the ocean's `part` (an open trench for 1.5 s, then the wave's 2 bh push and its run-up within 40 columns of the shore);
  - fire's hazard wear on a burning fire line and a glowing ember strip;
  - ice's control point at rock's stop, and the embed threshold scaled by depth;
  - the crater shapes;
  - breakable floes;
  - props: trees on a path, lone trees, outcrops, boulders, bergs and vents.
- **Encounter:**
  - read `sigvariants.json` in place of the three tables, and delete `beam.gd`'s unused `VARIANT` copy;
  - the five rule twists and the ocean's HIT, with the water rule (surfaces set within 30 ticks);
  - MARSH SWALLOW's sure embed;
  - the eight candidates and the surface terms in `chooseLaunch`;
  - pick the ground atoms and send the three events.
- **Simulation:** two things for the replay's hash:
  - fold `sigvariants.json` into `DirData.dataHash`, as `enders.json` already is;
  - cover `ground_atoms.json`'s numbers that change the sim (crater factors, refill, the embed factor, `sunkMoveTicks`, `slideBh`, `tripAbove`, `controlAtBrake`): hash the file in `replay.gd`, or World moves them into its own hashed data.
- **Animation:**
  - the stop poses (shared, with each fighter's flavour): heel dig, plough, sink slide, spin-out, deep plough, skitter, sink drag, heel peel, root catch, pebble slip, skim sink;
  - the ice landing slide;
  - the bounce multipliers for the new classes.
- **VFX and Rendering:** the trails, bursts, ejecta, crack decals and the variants' new looks (steam, shards, plates, powder, spray, embers, ash). `debris.gd` keeps reading the variant's name; the ten new names need their own debris looks.
- **Tools:**
  - the two schemas, the `biome` fragment, the map rows and the nine fixture cases;
  - its grant is on Orb's word.
- **Legal:** LANE SWEEP and TIDE CLEAVE are cleared for adoption (RL-175). Ten new names to screen: ICEFIELD THAW, FLOE SPLIT, VINE SHEAR, GRASSLAND BLAZE, FROST HEAVE, PINE BREAK, MIRE BOIL, SHORE SCOUR, SCREE RUN, CRUST SEAR. An originality judge (a subagent) found no borrowing, and before this I changed five of my first names:
  - TINDER LINE, because "Tinder" is an app's trademark;
  - CINDER VEIN, which echoes a published game's title;
  - SURF SPLIT, which repeats a word and is a common move name in another franchise;
  - GRASSFIRE RUN, which repeats a word;
  - THAW LINE, which broke the naming pattern.

  All 17 rows now end on different words.
- **Game Design:** everything here is ruled (section 1b, rows 1 to 10). Nothing is open.
- **Orb:** two names to pick: LANE SWEEP (three plain lines in `lane-sweep-for-orb.md`) and TIDE CLEAVE for the ocean.

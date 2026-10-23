# Biomes that change the fight: signatures, launches and the ground

Owner: Combat and Choreography. Date: 2026-10-23. Paper and three parked data files (`pending/biomes/`); nothing is built.

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
   - **Every proposal that moves either is marked and routed to Game Design (section 6):**
     - ice's brake makes journeys longer;
     - MARSH SWALLOW and the snow and mud craters make embeds more frequent;
     - the ice, sand and rock craters make them less frequent;
     - mud makes movement wait 6 ticks.
   - **A recoil exit's landing slide comes after control has returned:** momentum he can act out of. Nothing here makes a new tumble.
2. **Nothing is offered where its feature is missing, and everything is behind switches.**
   - Both new blocks have `enabled`.
   - Both have `touchBuilt`, which gates their rows for today's five classes: the sand and rubble landing terms, the built classes' crater shapes and sand's sink.
   - With `touchBuilt` off, a world without the new biomes plays exactly as today even with the blocks on.
3. **Today's rows are carried exactly.** The seven built variants keep their numbers, so moving to the new table is bit-identical.
4. **Keys.**
   - Biomes are keyed by the names `WorldBiomes.biomeAt` returns. The eight new ones (jungle, savanna, tundra, taiga, wetland, coast, highland, volcanic) are provisional until World names its ids. A rename is a key change.
   - Surfaces are keyed by World's classes. Each new class says what it reads as until World builds it.

## 2. Signature variants by biome

The full rows, with every outcome's line, are in `pending/biomes/sigvariants.json`. The ten new rows:

| Biome | Variant | The groove (depth × width) | Trees | What it leaves for the rest of the fight |
| :--- | :--- | :--- | :--- | :--- |
| **Ice sheet** (today read as mountains) | **ICEFIELD THAW** | 0.9 × 1.0 | none | **Glaze:** the meltwater refreezes, and the groove reads as ice for the match. A slick strip |
| **Sea ice** (today read as plains) | **FLOE SPLIT** | 0.6 × 1.0 | none | **Split:** each floe on the path breaks in two, 1 bh apart. A lead of open water, a real gap |
| **Jungle** | **VINE SHEAR** | 1.0 × 0.9 | felled inward across the cut | **Clearing:** the strip loses its canopy cover, and the trunks lie across it (props a ricochet can plant on) |
| **Savanna** | **GRASSLAND BLAZE** | 0.8 × 1.2 | burned | **Fire line:** the grass burns outward, 1 column every 15 ticks for 4 s, up to 12 columns each side. It burns props |
| **Tundra** | **FROST HEAVE** | 0.9 × 1.0 | none | **Heave:** the rim is thrown up as frozen plates twice the usual berm. A slide stops against them and a ricochet plants on them |
| **Taiga** | **PINE BREAK** | 1.0 × 1.0 | snapped, crowns drop | **Snow dump:** snow off the trees refills 40% of the groove within 2 s. A shallower scar |
| **Wetland** | **MIRE BOIL** | 1.1 × 0.9 | area | **Flood:** the groove fills to the water table at once. A water trench under the ocean rules |
| **Coast** | **SHORE SCOUR** | 1.0 × 1.1 | area | **Flood from the sea:** where the floor is below sea level within 30 columns of open water |
| **Highland** | **SCREE RUN** | 1.2 × 0.9 | area | **Scree:** on a slope steeper than 0.25, rubble runs downhill up to 10 columns. A strip that tumbles a slide |
| **Volcanic** | **CRUST SEAR** | 1.3 × 0.8 | burned | **Ember:** the groove glows for 10 s, then reads as crust. It lights props and grass |

**Where the leavings go.** An aftermath is laid only on the groove's columns in the variant's own biome. Where the beam carves on into the next biome, the groove there is plain.

**The seven built rows stay as they are:** HORIZON CLEAVE, BOULEVARD RAZE (city and village), FIELD SCAR, FIRESTORM, GLASS TRENCH and RIDGE BORE.
- The renames proposed earlier are carried as notes and stay unadopted: TIDE CLEAVE, LANE SWEEP, FURROW SCAR and CANOPY BURN.
- LANE SWEEP's low graze along the lane (0.7 × 1.3) is the one that would make the village play differently from the city.

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
  - **Coast, HIT:** the sea floods the cut behind him, and he lands in it where the floor is below sea level.

**Against pillar 7.** The table has 17 rows.
- All ten new rows differ from each other and from the built ones in what they carve, what they do to trees and what they leave.
- **Two pairs still play alike as built:**
  - city and village, until LANE SWEEP is adopted;
  - ocean and plains: both carve 1.0 × 1.0, and only the sea's own splash and seabed set the ocean apart.

  LANE SWEEP settles the first, once Legal and Orb adopt it. Nothing proposed so far settles the second: TIDE CLEAVE and FURROW SCAR change only names. Ocean needs a carve or an aftermath of its own, which is open and not proposed here.
- **The personality term** of `signature-variants.md` §5.1 is in the file, switched off, for Game Design: near people the carer narrows the bite and the villain widens it.

## 3. The launch planner by biome

A block for `data/director/launch.json` (`pending/biomes/launch.biome.json`).
- **The shared terms apply to every new candidate** as they do to SMASH ACROSS: noise, care at the landing, distance, new biome, water, the repeat penalties and launch anywhere's freshness.
- **Each new candidate joins `SENDS`,** so the stick's aim and the launch enders reach it.
- **The block rides `launch.json`,** which the replay's data hash already covers.

| Candidate | Offered when | Send | Score (first values) | What happens |
| :--- | :--- | :--- | :--- | :--- |
| **CLIFFSIDE** | A rise ahead steeper than 1.2 over at least 2 bh, out to 166 bh, found from the heights and not from a biome name | across | 18, +1 a bh of rise (cap 8); villain +2 | MOUNTAINSIDE for any biome: highland crags, volcanic cones, coast cliffs. He hits the face: the slide's wall stop, or an embed |
| **ICE SKID** | Ice within 1 bh of him | across, low and flat, force 0.8 | 14; +6 when it ends in open water, +8 against a berg; hero +2 | **Ice to skid on:** a long slide for little force. Its length is World's ice brake. Ending in a lead puts him in the water. A skid is a journey, so a brake of 0.3 against soil's 1.3 returns control several times later: Game Design's |
| **MARSH SWALLOW** | Mud under him, at most 12 bh up | down | 16; hero +6, villain −2 | **The marsh swallows the slam:** he embeds 1.8 times as deep, the crater closes again and little is destroyed, so the carer likes it. A deeper bowl embeds more often, and an embed is World's 60-tick down state: Game Design's |
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

**What to measure** (QA's bands to set):
- each new candidate is taken in 5 to 30% of the launches where it is offered;
- no candidate takes more than 40% of launches inside its biome;
- the share of launches landing in the sea falls when SKIM ASHORE is on.

## 4. Choreography that reads the ground

`pending/biomes/ground.json`, keyed by surface class.

### 4.1 Surfaces

| Class | Biomes | Brake (proposed for World; today paving and rock 0.8, soil and sand 1.3) | Reads as until built |
| :--- | :--- | ---: | :--- |
| **ice** | sea ice; the glaze | 0.3 | rock |
| **snow** | taiga, ice sheet | 1.6 | sand |
| **frost** | tundra | 0.9 | rock |
| **mud** | wetland | 2.0 | sand |
| **turf** | savanna, highland | 1.0 | soil |
| **litter** | jungle | 1.2 | soil |
| **ash** | volcanic, where World lays it | 1.5 | sand |
| **crust** | volcanic; the ember strip after it glows | 0.9 | rock |
| **shingle** | coast | 1.1 | sand |

The aftermath strips override the biome's class: glaze reads ice, ember reads crust, scree reads rubble, and a flood reads water.

### 4.2 Skid-stops by surface

How a body carried along the ground comes to rest. That covers a short knock-back's upright slide, a long one's skid (World's slide on the feet) and a guard's push-back.

| Surface | The stop (Animation's pose) | The trail (VFX) | Left at rest |
| :--- | :--- | :--- | :--- |
| paving, rock, crust | heels dig in, a hand down | scrape and sparks; grind and chips; glowing cracks | crouch |
| soil, ash | both feet plough | a furrow and its berm; an ash plume | crouch |
| sand | the feet sink and slide | a spray and a trough | low crouch |
| rubble | a roll | debris | on a knee |
| **ice** | **a spin-out:** he turns through the slide and a hand brakes him, ending square to the one who sent him | a polished streak | crouch |
| **snow** | a deep plough, a powder bow-wave | a channel | shin-deep |
| frost | skittering steps, the crust cracking | a crack line | crouch |
| **mud** | the feet sink and are dragged | a mud wave | **sunk:** movement waits 6 ticks while he pulls free; presses are taken as ever |
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
- Depth and the embed factor change how often a slam reaches the embed threshold: more often in snow and mud, less in ice, sand and rock. That shift is Game Design's to rule.

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
| `ground.json` | `data/combat/ground.json` | **`combat.ground/1`**, draft `combat-ground.schema.json` |

**Proven with Tools' own validator** in a scratch root, with the drafts and map rows added:
- all three files read 0 errors and 0 warnings (the ground schema carries both switches);
- nine refusals, three for each schema, each fail at their pointer, or at its parent for the aftermath's either-null-or-object rule. They are written in the shape of `tools/fixtures/cases.json` as `cases.biomes.json`.

**Cross-checks:**
- every biome has a variant and a surface;
- every surface has a skid-stop and a crater;
- each surface's `exists` flag matches `contact.json`;
- every candidate is in exactly the sends list of its own send;
- the built rows match `crater.gd`.

Each schema's description lists the cross-references proposed for Tools' xref.

## 6. What each consumer needs

- **World:**
  - its final biome ids;
  - a biome name for each new biome, ending `BIOME_NAME`'s aliasing of ice;
  - the surface classes and their brakes;
  - `surfaceAt(x)`, including the aftermath strips;
  - the nine aftermath kinds;
  - the crater shapes;
  - breakable floes;
  - props: trees on a path, lone trees, outcrops, boulders, bergs and vents.
- **Encounter:**
  - read `sigvariants.json` in place of the three tables, and delete `beam.gd`'s unused `VARIANT` copy;
  - the five rule twists;
  - the eight candidates and the surface terms in `chooseLaunch`;
  - pick the ground atoms and send the three events.
- **Simulation:** two things for the replay's hash:
  - fold `sigvariants.json` into `DirData.dataHash`, as `enders.json` already is;
  - cover `ground.json`'s numbers that change the sim (crater factors, refill, the embed factor, `sunkMoveTicks`, `slideBh`, `tripAbove`): hash the file in `replay.gd`, or World moves them into `contact.json`, which `WorldContact.dataHash` already covers.
- **Animation:**
  - the stop poses (shared, with each fighter's flavour): heel dig, plough, sink slide, spin-out, deep plough, skitter, sink drag, heel peel, root catch, pebble slip, skim sink;
  - the ice landing slide;
  - the bounce multipliers for the new classes.
- **VFX and Rendering:** the trails, bursts, ejecta, crack decals and the variants' new looks (steam, shards, plates, powder, spray, embers, ash). `debris.gd` keeps reading the variant's name; the ten new names need their own debris looks.
- **Tools:**
  - the two schemas, the `biome` fragment, the map rows and the nine fixture cases;
  - its grant is on Orb's word.
- **Legal:** ten new names to screen: ICEFIELD THAW, FLOE SPLIT, VINE SHEAR, GRASSLAND BLAZE, FROST HEAVE, PINE BREAK, MIRE BOIL, SHORE SCOUR, SCREE RUN, CRUST SEAR. An originality judge (a subagent) found no borrowing, and before this I changed five of my first names:
  - TINDER LINE, because "Tinder" is an app's trademark;
  - CINDER VEIN, which echoes a published game's title;
  - SURF SPLIT, which repeats a word and is a common move name in another franchise;
  - GRASSFIRE RUN, which repeats a word;
  - THAW LINE, which broke the naming pattern.

  All 17 rows now end on different words.
- **Game Design:**
  - every score and factor;
  - whether a fire line or an ember strip ever hurts a fighter (here they don't);
  - whether mud's 6-tick wait on movement is within the press-feel rule;
  - the journey on ice (a brake of 0.3 returns control several times later than soil): stand, cap, or raise the brake;
  - the embed shift from the crater depths and MARSH SWALLOW;
  - the personality term.

# Proposals: generated movesets for two fighters who are not in the build

Owner: Combat and Choreography. Date: 2026-10-28. Status: **templates for Orb, proposals only.** Nothing here is in `data/`, loaded or hashed, and nothing changes what plays. Orb writes the universe: the names are Narrative's placeholders, the niches are Game Design's templates, and a row becomes a fighter only when Orb and Game Design say so.

| File | What |
| :--- | :--- |
| `identity.proposals.json` | the two identity rows (`combat.identity.proposals/1`): weights by limb, path, tip and entry, never rows, the burst's close, energy hands, and the manner in words |
| `moveset.prodigy.json`, `moveset.colossus.json` | **generated** (`combat.moveset/1`): every cell of the five stances, 135 and 136 rows |
| `lock.proposals.json` | **generated:** their strike ids and shapes, so an id never changes shape |
| `review-sheet.md` | **generated:** every move of the two beside the Protagonist's and the rival's, for Legal, Animation and Orb |

To generate again: `node tools/movegen/movegen.mjs --propose`. To check: add `--check`.

## How they are made

Each row is laid over the rival's row of the build and generated beside the two built fighters, as the roster sketches are (`../roster-rows.md`). The share rule keeps each proposal's own pieces his and leaves the built fighters theirs: the Protagonist's and the rival's moves come out unchanged (the generator stops if they move). Nothing is drawn for either proposal. What is posed is borrowed from the common pieces (the lights and mediums both built fighters have posed), and what must be his alone comes out as **waiting**: new key sets Animation would draw if Orb takes the row.

| | The Prodigy | The Colossus |
| :--- | :--- | :--- |
| **Template** | Game Design T2, the speedster ("Skirmisher, the quick study"); Narrative's Prodigy, the newcomer | Game Design T4, the heavy ("Bulwark"); Narrative's Colossus, the armoured guardian |
| **Why these two** | First in Game Design's build order on a zero budget: "an identity block and numbers" | Second in that order: armour is data, the scale one number on the shared rig |
| **His look in the grammar** | Hands and feet first; lines, outward arcs and rises; the back of the fist, the ball and instep of the foot. Never a spin, a headbutt, a forearm plate or both arms at once | The shoulder, the plate and the hammer fist; drops and lines. Never a cut (no blade hand), a turning kick, a kick above the gut, or a spin |
| **Rows** (posed, derived, waiting) | 135: 71, 38, 26 | 136: 68, 41, 27 |
| **His own pieces, all waiting for key sets** | 10 | 11 |
| **Game Design's gate on blows** (his own, with his own drawn) | 26%: a quarter | 29%: a quarter |
| **Heavies** (martial B) | falling heel to the gut; stepping and heaving ball of the foot to the gut; heaving and turning elbow to the jaw; stepping fist to the chest; turning fist to the jaw; falling hammer fist to the arm; stepping edge of the foot to the legs; heaving palm to the chest | falling sole to the gut; stepping shoulder to the chest; heaving elbow to the jaw; turning forearm plate to the head; stepping edge of the foot to the legs; turning fist to the jaw; heaving palm to the chest; falling hammer fist to the arm; stepping knee to the gut; turning knee to the legs |
| **Zips and steps** (manoeuvre X) | in on a dash, a spiral, a lane step or an arc dive, landing the backfist or a snap of the ball of the foot | in on a dash, a pivot, an arc dive, a coil spring or a rise, landing the shoulder, the plate, an elbow or a knee |
| **Energy** | a blade hand flicked or thrust; a bolt from the open palm | the open palm, thrust or dropped |
| **The push** (defensive Y) | the palm, the ball and sole of the foot, and once the shoulder | the shoulder, the palm, both forearms, and the ball and sole of the foot |
| **Specials** (charging) | placeholders, the Protagonist's three | placeholders, the Protagonist's three |

The manner rows in `identity.proposals.json` say in words how each throws, for Animation and Legal: the Prodigy throws on the move, his weight landing with the blow and already leaving; the Colossus throws slow and plain, the longest tell on the roster, his feet staying where they were.

## What the generator cannot give them

- **His mechanic.** Acceleration and learning (the Prodigy), armour, weight and the ground answering (the Colossus) are Simulation's and Game Design's: rules on zips, reel, knock-back and lift. The moveset only shows what each throws.
- **His specials and signatures.** The charging row holds the Protagonist's placeholders; the B frames are generic until the kinds are final.
- **The Colossus's size.** One scale on the shared rig changes his reach; his poses are the common pieces until Animation draws him.

## Before either goes further

- **Orb:** whether either template is wanted, and the universe it belongs to.
- **Legal:** the person screen of every new shape (the waiting strike rows: 11 for the Prodigy and 12 for the Colossus, one push each included; the sheet lists them), and the titles, which are Narrative's placeholders and have had no name screen.
- **Game Design:** the numbers of each mechanic; whether the gate's quarter is enough for a tier 1 fighter.
- **Animation:** the new key sets, if a row is taken.

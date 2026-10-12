# Bringing a fighter into Combat's data

Owner: Combat and Choreography. Date: 2026-10-12. For Game Design's `docs/design/fighter-pipeline.md`, on Orb's question of the same day (`docs/ep/vision.md`, last section). Counts are from the tree today. Sizes of work are estimates and are marked.

**The short answer to Orb.**
- **The two stand-ins are two of the four.** `protagonist` is the Protagonist and `rival` is the Anti-hero under a neutral id (`launch-pair-movesets.md`). Nothing built on them is thrown away.
- **A moveset does not move the balance today.** Which piece a blow plays changes its look and nothing else. Measured: the same four seeded matches gave the same 7,298 blows and the same match lengths on the old pools and on the new ones (`pending/nine-cells.md` section 3). Balance moves with stats and mechanics, which are Game Design's.
- **The moveset generator is already a common pool with identity as data.** A new fighter is one row of weights and bans over the same parts. He has a generated, checked moveset in an hour or two (estimate). What takes time is Animation posing what is his alone.

## 1. What a fighter is in the data today

| Where | What he has | Shared with everyone |
| :--- | :--- | :--- |
| `identity.json`, his block | His packs (`waves`, `tierWaves`, `energyWaves`, `entryWaves`); `weights` by limb, path, tip and entry; `weightsBy` strength; `never` rows; `pinned` shapes; his energy hands and releases; his burst's close; `manner` in words; his specials | The keys and their meaning |
| `parts.json` | Nothing | The grammar: limbs, tips, paths, places, wind-up rules, the heavy tier's drives, Legal's rows |
| `cells.json` | Nothing | Every count and quota: 30 lights, 16 mediums, 10 heavies, 4 bolts, 2 blasts, 128 rows over five stances |
| `lock.json`, `moveset.<key>.json`, the review sheet | His generated rows; an id never changes shape | The format |
| Recipes | His 22 pools, which cover the fifteen cells of the brawl and their fallbacks; his launchers by send; his burst's close and samples; his bolts, blasts and two mashed runs | The `pieces` table, one row an id; the `brawl` map; the rules |
| Not Combat's | His folder in `data/fighters`, the recipes key in `data/director/alchemy.json`, his finisher row | |

**What he inherits for free.** Every strike in a pack his `waves` list names is posed for him at once. Today 135 strike key sets are posed, 95 different strikes. 39 of them are posed for both fighters.

**What makes it his.** In order of how much it shows:
1. **A set only he has.** Today 28 strikes each: his ten heavies, his energy pieces in reach, and about twelve lights and mediums.
2. **His bans.** The Anti-hero never throws a palm. The Protagonist has no forearm plate, throws no straight fist as a light, and never brings his weight down on a head.
3. **His weights.** They decide which of the legal candidates fill a cell: the Anti-hero's lines and drops with fists and plates, the Protagonist's arcs and spins with open hands and the edge of the foot.
4. **His hands and places.** The energy hand, where a heavy goes, how his burst closes.

The result today: the two share 24 of their 44 and 47 martial shapes, and 39 of the 71 and 67 pieces in their pools.

## 2. From a one-page identity to a moveset

| Step | Who | Time (estimate) |
| :--- | :--- | :--- |
| 1. One page: how he throws, what he favours, what he never does, his hands, anything his body has that others lack | Game Design, with Orb | |
| 2. The identity row from that page | Combat | An hour |
| 3. Generate and check. The check refuses Legal's rows, a button that runs dry after any two blows, a light that cannot open a burst, a tier with no heavy to an arm or to the legs | Combat | Minutes |
| 4. **Orb's yes or no, on a one-page card** | Orb | Ten minutes |
| 5. Legal's screen of the sheet | Legal | |
| 6. Poses for what is waiting and for what must be his alone | Animation | The long step: see section 3 |
| 7. Regenerate on Animation's ids, build his pools, measure in scratch (pieces picked, joints strict) | Combat | Half a session a fighter |
| 8. The window: recipes, his roster entry, the key in `alchemy.json`, one regeneration of the goldens | The EP's | |

- **The review sheet is not a ten-minute read.** It is 805 lines for two fighters: every row, with Legal's conditions. It is for Legal and Animation.
- **A card for Orb is a new output, not built** (half a session, estimate). One page a fighter, generated from the same data: what he throws most, what he never does, the dozen pieces only he has by plain name, his launchers by direction, his burst's close, his energy hands, and how much is posed, borrowed or waiting.
- **Once, before the third fighter** (a session, estimate): the generator already loops over every fighter in `identity.json`, but my pool builder and scratch probe name the two. They have to take any number.

## 3. How large the common pool is, and where it is thin

| Family | Different strikes posed | For both | The rival only | The Protagonist only |
| :--- | ---: | ---: | ---: | ---: |
| Hand | 35 | 14 | 11 | 10 |
| Foot | 16 | 11 | 1 | 4 |
| Elbow | 6 | 5 | 1 | 0 |
| Knee | 5 | 4 | 1 | 0 |
| Shoulder | 2 | 2 | 0 | 0 |
| Head | 1 | 1 | 0 | 0 |
| The heavy tier | 20 | 0 | 10 | 10 |
| Energy in reach | 10 | 2 | 4 | 4 |
| **All** | **95** | **39** | **28** | **28** |

**The grammar is not the limit; poses are.** A fighter's 30 lights are chosen from 77 legal candidates, his 16 mediums from 78 to 99, his 10 heavies from 69 to 89.

**For four** (estimate): at today's rate each new fighter needs about 28 strikes of his own, so about 55 more than exist. A fighter who shares heavies needs fewer.
**For twelve** (estimate): that rate gives about 375 strikes, which is too many to pose. The share that is his alone has to fall to about 15 (his heavies and energy pieces), and the common lights and mediums have to roughly double, from 65 to about 120, so that weights and bans alone can separate fighters.

**Thin today.**
- **Elbows, knees, shoulders, the head:** 14 strikes in all, nearly all shared. A fighter built on them has nothing to choose from. This is the Cyborg's ground.
- **Kicks:** 16, of which 11 are shared. Enough for two fighters, thin for one who mostly kicks.
- **Heavies:** none is shared. Four fighters at ten each is 40.
- **A tail or a mantle:** not in the grammar and not posed. Four tail strikes are named for the Anti-hero and wait on Orb's ruling. The Empress's bladed mantle is the same kind of limb. It needs a limb with its own tips and paths, Legal's screen and Animation's rig.
- **Grabs and throws:** two kinds are named (a tackle, a clinch) and none is generated. They are context actions today.
- **Specials:** the charging stance is 14 rows a fighter, all waiting, for both.
- **Another body** (no legs, four arms): the grammar and Legal's rows assume two arms and two legs. The vision's body variety is 2 of 5, small departures such as a tail or size, so I have planned for nothing further.

## 4. The four as identity rows, tier 1

Flavour on today's systems, with no mechanic of their own. The last column is an estimate.

| | The Protagonist | The Anti-hero | The Empress (the Galactic Tyrant) | The Demon Cyborg |
| :--- | :--- | :--- | :--- | :--- |
| Base row | `protagonist`, as it is | `rival`, as it is: yes, RIVAL is his base | New | New |
| In a line | A huge hand-to-hand repertoire: pointed, not cruel | Brutal and showy: he lets the rival see it coming | Precise and dominant: she barely moves, and each blow is one clean line | The fastest: short, exact, machine-like |
| Limbs he or she favours | Hand and foot equally | Hand, then foot and elbow | One hand, then the heel | Elbow and knee, then the hand |
| Paths | Arcs, spins, rises | Lines and drops | Lines and drops; no spin, no leap | Lines and short rises; no wide arc |
| Hands and tips | Palm, blade hand, edge of the foot | Fist and plate on mediums and heavies, blade hand on lights | Blade hand and the heel of the foot | Fist, forearm plate, elbow point, knee |
| Never | A plate; a straight fist as a light; his weight down on a head | A palm; a blade hand on a medium or heavy | A headbutt, a shoulder, a two-arm blow, a spin | A spin, a kick above the chest |
| Energy hands (all exist today) | Palm thrust, ring hand, flat palm | Blade hand, the lit fist, pinch; his shots split | Pinch and blade hand, thrust or flick: a cut, not a burst | Clawed palm and open palm, thrust |
| Burst closes on | An arc | A straight | A drop | A straight |
| His own to pose | The widest spread: a few more lights and mediums than the others | His barrages are energy pieces; his finish by hand is his finisher row | Ten heavies, six energy pieces, about ten lights and mediums; the mantle later | Ten heavies, six energy pieces, and most of his lights: the pool has few elbows and knees |

- **The Protagonist's "huge repertoire"** shows best as more rows than anyone else, say 36 lights where others have 30. That makes a cell's count differ by fighter, which is Game Design's call (section 5).
- **The Empress's precise beam** must be a pinch or a blade hand. Legal's rows refuse a pointed finger or two fingers.
- **The Cyborg's speed** is a look at tier 1: short compact blows, more of his lights fitting the burst's fast gaps, no flourish. The frame data stays everyone's.
- **The mantle and a tail** are tier 2: a new limb.

## 5. What must stay equal, and what may differ

**Equal, so the tuning carries to every fighter.**
- **Frame data by strength:** a light's gap and the flurry's, a medium's 12-tick wind-up, a heavy's 28 and the launcher's 14, the blast's 12, the burst's slots and curve, and each strength's worth. Animation fits a key set to its cell's ticks, never the reverse.
- **Counts and floors:** the cells' counts and quotas; at least three pieces a button after any two blows; two launchers a send where the tier allows; a heavy to an arm and one to the legs; four bolts and two blasts.
- **The rules of a run:** Legal's string rules, never one of his last two pieces, the fallback's three steps.
- **Reach by class.** If the sim reads a key set's reach or offset, it has to be set by the cell and not by the piece. I don't know that it does. It is a question for Encounter.

**May differ.**
- Which pieces he has, their limbs, tips, paths and places; his weights and bans; his hands; his burst's close; his manner; his energy hands; his specials, signature and finisher.

**Where a look can leak into balance later.**
- **Places.** Today the sim doesn't read where a piece lands. When blows name their region (the wrench, the clinch), a fighter who goes to the legs more will break legs more. The spread of places by fighter then needs a floor and a ceiling.
- **Sends.** A fighter with more launchers that send down slams more, and the ground and the buildings answer for it.
- **A cell's count.** More pieces means more variety and nothing else, as long as the floors hold.

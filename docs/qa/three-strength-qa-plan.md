# QA plan: the three-strength brawl and the walk-out (paper only, 2026-10-06)

QA & Balance. This is a plan and nothing is built: no harness change is made until the slice that carries a row exists (C1 for §A and §C, C2a for §B, C2b for the holds). Sources: `docs/design/brawl-second-pass.md` §1, §2, §3, §7 and §11; `docs/director/brawl-plan.md` (walk-out, 4.3x). The mirror, momentum and first-slot rows that §11 retires are listed in §D. No retune is proposed here: every band below is Game Design's.

How to read a row: **Band** is the pass range. **Kind** is hard test (exact, any failure is a FAIL), point (a rate against a band, 95% interval shown), or reported (INFO, no band). **Needs** is what the harness needs from the build, and **Script** the player that produces the evidence. Rate rows follow the standing rule: PENDING below the sample size named.

## A. The three buttons

| # | Row | Band | Kind | Needs | Script |
| :-- | :--- | :--- | :--- | :--- | :--- |
| A1 | Press to contact, X | 2 ticks, 95% inside 4 | point | cue `blow` carries the press tick (`press_ack` tick against the blow's contact tick); a tapped X in each exchange | tapper X, medium AI |
| A2 | Press to contact, Y | 12 ticks, never past 16 | hard | same, a Y tap | tapper Y |
| A3 | Press to contact, B | 28 ticks, never past 32 | hard | same, a B tap | tapper B |
| A4 | Every press starts its move within 10 ticks | 100% | hard | the existing Encounter measure (press to first move), now per button | all three |
| A5 | A tap read as a hold, by device | under 2% on pad and keyboard; under 5% on touch | point, one row per device | a device tag on the scripted press (`dev=pad|key|touch`): a tap's real length drawn from Controls' ranges (pad 3 to 6 ticks, keyboard 4 to 8, touch 5 to 12) with a seeded draw; the sim cue or intent that says "this press became a charge" (`charge_start` on a button that was released inside the 4-tick grace is the failure) | `tapper` gets `tap=` (its release length) and `dev=` |
| A6 | Unintended charge (EP's row) | reported with the sample, then banded when Game Design names the band: the share of a masher's presses (Y and B mashers, the two-finger masher, the alternator) that open a charge | reported, then point | the same `charge_start` cue | Y, B, alternator and the two-finger masher, 100 matches each |
| A7 | Presses of a scripted two-finger masher that read as a pair | under 5% | point | a pair press cue or intent reading (X+Y or Y+B pressed within a window); the script presses two buttons on alternate ticks | `tapper` kind `twofinger` |
| A8 | A press on a cell with no move gives `press_ack` empty | every one, never silent | hard | cue `press_ack` text `empty` | a script that presses RT with X, Y and A, and the martial arts A |

## B. The flurries, the burst and the masher rows

| # | Row | Band | Kind | Needs | Script |
| :-- | :--- | :--- | :--- | :--- | :--- |
| B1 | X flurry against Y flurry | X wins 55 to 75% | point, 200 matches | none beyond the three mashers | `masher kind=X` against `masher kind=Y`, both `clock=tick`, on the seeded start offset the mirror uses (`off=7` on one side) |
| B2 | Y flurry against B flurry | Y wins 55 to 75% | point, 200 | same | Y against B |
| B3 | B flurry against X flurry | B wins 55 to 75% | point, 200 | same | B against X |
| B4 | Each flurry's own pace | X one blow every 6 ticks, Y 12, B 28, at its fastest | hard | blow cues by button | each masher alone against a guard-only dummy |
| B5 | Damage a second is level within a button, rising between buttons | within 10% inside X, Y, B; X below Y below B | point | damage events by button | the three mashers against the medium AI |
| B6 | The burst against a mash over the same time | 70 to 80% of the mash's damage, never over | point (never over is a hard test) | `burst` blow cues (kind or a flag on `blow`) | `holder kind=X` (hold X) against a never-defending dummy, and the 8-tick X masher over the same 55 ticks |
| B7 | A held X finishes eight blows with the gaps 4, 4, 5, 6, 8, 11, 15 | exact | hard | `burst` blow ticks | the holder |
| B8 | A full charged heavy thrown into an X flurry lands | at least 80% while the flurrier keeps flurrying | point | `charge_land` and the blow's end cue | `holder kind=B` against an X masher; arrives with C2b |
| B9 | A shove ends a heavy that is winding or charging | at least 90% of the tries in reach | point | `shove` cue and the heavy's `lost` end | `tapper` A against the heavy winder; C2b |
| B10 | The masher against the medium AI | X masher 35 to 50% (kept); Y masher, B masher, the alternator and the X holder reported | point, then reported | masher `kind=` Y, B and a new `alt` (X, Y, B in turn) and `hold` kinds | `masher` extended with `btn=X|Y|B` and `alt=XYB` |
| B11 | The mix-up: any order across X, Y and B | reported: wins against the medium AI, brawl length and share | reported | none | `mix` kind with `mix=XYB` |
| B12 | The brawl's median length | 3 to 8 s as a first band (Game Design re-reads after C2b) | point | none | the AI against itself, and the pressing script |
| B13 | A failed option leaves him open | at most 20 ticks, and no added damage of its own | hard | `open` state ticks (cue or state read) after a whiffed heavy, a dodged tackle, a failed clinch | scripts that whiff on purpose: a heavy thrown out of reach |
| B14 | Ki spent a minute, by what it bought | reported: mediums, heavies, charges, power attacks, zips, signatures | reported | the per-tick ki drop sum I already read, split by the cue that preceded it | the AI, and the zipper |

Notes. B1 to B3 are the three-way rock, paper, scissors: if any of them reads under 55 or over 75 the cause is nearly always the tie (identical start ticks), so each is read with the seeded start offset and with the exact tie as a reported number, as I do for the lights mirror. The presses are counted on S.tick so a hit freeze does not slow a script (clock=tick is the default for these).

## C. The centre, the double hit and the walk-out

| # | Row | Band | Kind | Needs | Script |
| :-- | :--- | :--- | :--- | :--- | :--- |
| C1 | The centre moves within 2 ticks of a stick, in every state where the stick works | exact | hard | the brawl's centre in a state read (`inBrawl` plus a `centre` field, or the two fighters' positions); per fighter state: striking, charging, reeling from a light, guarding | a script that holds a stick from a seeded tick in each state |
| C2 | The stick does nothing in knock-back, launch, lift, hold, buried, set piece, and a stagger | exact | hard | same | same, in each state |
| C3 | The centre moves at most 0.3 bh in one tick | exact | hard | same | any brawl, scan every tick |
| C4 | How far a held stick moves a brawl against a rival who holds none | reported, in bh a second; 0.4 and 0.8 of free-flight speed are the design values | reported | same | two scripts, one holding a direction |
| C5 | The brawl never passes through a building face, and a drifting brawl never damages a building | none | hard | the centre against `WorldStructures.blockedAt`; building damage events during a brawl with no throw, tackle, launch or blast | the nudging script flown at a building |
| C6 | Double hits a match | 0.5 to 2 in AI matches; at least one in 40 to 70% of matches; never more than 4 in a match | point, 400 matches | `brawl_end` text `double` | the AI against itself |
| C7 | Every trade still level at 240 ticks ends in a double hit | all | hard | the trade's tick count (`trade_break` or a `trade_level` cue) against the `double` end | the lights mirror |
| C8 | The double hit's worth and aftermath | 4 brawl lights to each, thrown back 6 bh, brawl ends, nobody won a decisive exchange | hard | damage events at the double tick and the positions 40 ticks later | the lights mirror |
| C9 | Walk-out, the two-stick rule: both sticks away within 45 degrees for 12 ticks running end the brawl `walk` | exact (12 ticks, free, no wait after it) | hard | `brawl_end` text `walk` and its tick; the sticks' scripted ticks | `walker` script: both fighters hold away from a seeded tick |
| C10 | A blow thrown by either in those 12 ticks starts the count again | exact | hard | same | the walker, with one blow thrown at tick 6 |
| C11 | The 12 ticks count while either guards; they do not count while either has a blow on its way or an attack button held, or is reeling or staggered | exact | hard | same | the walker, with a guard held; with a held X; and a stagger |
| C12 | One fighter's stick alone never ends a brawl | no `walk` end in the one-sided case | hard | same | the walker with one stick only, 24 and 60 ticks |
| C13 | A boost held with the stick away is the escape, not the walk | the escape's price is paid, the end text is `escape` and not `walk` | hard | `brawl_end` text | the walker with one boost |

Notes on the walk-out. The EP's ruling (2026-10-06): only the one-sided walk-out is retired (a fighter let go after 24 ticks of holding away with nothing landing on him; withdrawn in `brawl-second-pass.md` §1). The mutual walk-out stays, so C9 to C13 are all live: both hold away within 45 degrees for 12 ticks, free; the count runs while either guards, and does not run while either has a blow on its way or an attack button held, or is reeling or staggered. C12 is the hard test that the one-sided rule does not come back.

## D. Rows retired or re-read by §11

| Row | What happens |
| :--- | :--- |
| The even lights-only mirror finishes (95%) | Retired. It is a stalemate by rule; reported, with how it ends (double hits to the KO, or the cap) |
| An uneven mirror, 8 ticks against 10 | New: finishes at least 95%, the faster tapper wins at least 80%. Brink to KO 25 to 50 s read here. My `fast-slow` pair (6 against 12) is the nearest and gets re-pointed |
| Level trades that change who has the momentum; wins from the first slot | Retired with the draw. The first-slot read stays as a reported number on the tickoff mirror, since a slot effect would still be a bug |
| Knock-backs 60 to 75% and launches 25 to 40% of separating endings | Re-read after C2b with double hits as a third kind |
| Per-exchange rows already re-based | Unchanged |

## E. Harness work, in the order it is needed

1. **Before C1:** none beyond the baseline on 53d13b55. (The walker and the centre rows need the centre's state to be readable first. I ask Encounter for the field name, not the other way round.)
2. **With C1:** the walker script, C1 to C13, the `double` end, a `masher` stage for the double-hit rate, and the retirement of the momentum and finish rows in `masher.js` and `bands.js`.
3. **With C2a:** `masher` gets a button (`btn=`), the alternator (`alt=`), the holder kinds and the burst script; rows A1 to A8 and B1 to B7, B10, B11. `tapper` gets `tap=` and `dev=`.
4. **With C2b:** B8, B9, B13 and the unintended-charge row A6.
5. Each step lands with a synthetic self-test first, as the zip rows did.

## F. What I need from the build, collected

- `blow` and `press_ack` cues with the press tick, the button and the contact tick (A1 to A3).
- A cue or state for "this press became a charge" (A5, A6) and for a pair press (A7).
- `brawl_end` texts `walk`, `double`, `escape` and the tick counts for each (C6 to C13).
- The brawl's centre position, or the two fighters' positions each tick (readable already) plus the state they are in (C1 to C5).
- An `open` tick count after a whiff (B13).

## G. Harness state, 2026-10-06 (built in `qa/`, no Godot batch run; scripts smoke-tested on a scratch export at 2 matches, every row PENDING on a build with no C1)

Built against the cues and reads that `docs/director/brawl-plan.md` §9.2 promises, so the names are the plan's and must be confirmed when C1 lands:

| Plan row | In the harness | Reads |
| :--- | :--- | :--- |
| C1, C3, C4 | `c1.centre.latency` (hard, at most 2 ticks), `c1.centre.step.one` and `.both` (hard, 0.3 bh), `c1.drift.one` and `.both` (reported bh a second) | `DirBrawl.centre(S, ex)` returning `x`, `y`, `vx`, `vy` (the plan's keys); pairs `c1-drift-one` and `c1-drift-both`: lights mashers, one or both holding east from 24 ticks into a brawl for 60 ticks (`drift=east`) |
| C6 to C8 | `double.perMatch` (0.5 to 2), `double.matchesWith` (40 to 70%, at least 100 matches), `double.max` (at most 4, hard), `double.cue` (a double_hit cue for every double end, hard), `double.both` (both fighters take damage on the landing tick, hard), `double.after` (damage and separation 30 ticks later, reported) | the `double_hit` cue (`n` the landing tick) and `brawl_end` text `double`; the AI's default arm |
| C9 to C13 | `c1.walk.both`, `.jab`, `.guard` (hard: never under 12 ticks after the later stick or the jab press; the walk must happen), `.held` and `.one` (hard: no walk end at all) | `brawl_end` text `walk`; pairs `c1-walk-*`: both players hold away from 24 ticks into a brawl and stop pressing (`walk=1`), with `jab=6`, `wguard=1`, `wheld=1` as variants; the 12-tick floor is measured from the later stick or the jab's press tick, a lower bound that a blow cue could not give |
| C7 (every trade level at 240 ticks ends in a double) | **PENDING, not built**: it needs the trade's tick count on a cue (`trade_break` carries `amount` and `n` today; the double path has no equivalent) | ask Encounter for the level trade's tick on `double_hit` |
| C2 (the stick does nothing in a knock-back, launch, lift, hold, buried, a set piece, a stagger) and C5 (building faces) | not built: they need a script that holds a stick in each state | with C2a or after |
| the drop | `zip.drop` (hard; the hooked shot) and `zip.drop.bolt` (a real bolt; a coverage gap is PENDING, never a pass) | `drop_start`, `drop_land`, `drop_end` are **event types of their own** (`sim/core/fx.gd`), not cues, which the zip rows had read as cues until this batch: the earlier "0, 0, 0" in the baseline was that, and not only the missing coverage |

The drop row, what was found. A real bolt cannot reach a zipper on his way out in practice: the way out is 3 to 10 ticks, a bolt needs 6 to leave, and the zip's reach is itself a brawl, in which an energy press is a link and not a bolt. So the hard row (`zip.drop`) reports a shot of power 1 to `DirZip.shot` on a tick of the way out (`turret:...:hook=1`), the way Encounter's own check does; a second pair (`zip-turret`) fires real bolts with chance 25% a tick whenever no exchange runs, and reports how often one lands on the way out. On the build at 53d13b55, the hooked shot gives `zip_end down`, one `drop_start`, one `drop_end` and the state `dropped` in between. **`drop_land` did not fire in 3 of 3 drops** (the zipper was on the ground at the time, I suppose), so the row asks for one start and one end for each down, and reports the lands; Encounter to say whether a drop that begins on the ground should land.


## H. Orb's four playtest questions, as rows (2026-10-06; from `brawl-second-pass.md` §11 and §13)

Orb will play C1, C2a and C2t. The four questions are his acceptance test; the rows below are the checks that say a build is ready for him. **Built** means the harness has it and a self-test, with PENDING until the build has the field. **Paper** means the row is defined and the harness waits for a cue or a script that the build does not have yet.

### H1. "Can I move my character around during active combat?" (C1; the stagger's half is C2t)

| Row | Band | Kind | State | How |
| :--- | :--- | :--- | :--- | :--- |
| `c1.dead`: no live brawl tick with a dead stick, outside a knock-back and its kind | none | hard | **Built** | pair `c1-hold-one`: a lights masher holds a stick on every live tick of a brawl against a rival with no stick; after the ramp (14 ticks) a tick on which he does not move along it, in a state that is not launched, down, dropped, buried, held, thrown, lifted or carried, is dead; counted by state. **On 53d13b55 a 2-match smoke gives 12,369 dead of 15,323 held ticks, all in the state `locked`: this is the lock Orb felt, and the row's "before".** States reached today: striking, mashing, staggered, reeling. Wind-up, charge and guard come with C2a and C2b |
| `c1.aistick`: a held stick against the medium AI moves the brawl at least 0.7 as far as against no stick | at least 0.7 | point | **Built** | pairs `c1-drift-ai` (the stick against `ai:level=medium`) over `c1-drift-one` (the same script against a rival with no stick), as bh a second after the ramp |
| the AI holds against a player's stick on under 25% of the ticks he holds it | under 25% | point | **Paper** | needs the AI's own stick read on a tick (a `nudge` field on the AI's intent, or a cue) |
| the drift itself, and the latency of 2 ticks | | | built in §G | |

### H2. "Can I move my character when the opponent is charging up an attack?" (C2t, against wind-ups)

| Row | Band | Kind | State | How |
| :--- | :--- | :--- | :--- | :--- |
| a fighter with his hands down moves within 2 ticks of his stick while the rival winds up or charges | 2 ticks | hard | **Paper** | a `giver` script (hands down, stick away from the rival from a seeded tick) against a rival who taps Y or B. Needs the wind-up's start and end on a cue (`windup_start` with actor, strength and the tick it will land; the end as `blow` or `windup_lost`) and the fighter's own step (readable) |
| out of a tapped heavy that is not followed, started by tick 16: out every time | 100% | hard | **Paper** | the giver starts at a seeded tick 0 to 16 into the 28-tick wind-up; the rival script does not follow; the blow must miss (no damage to him, the rival open 20 ticks). Needs the tapped B (C2a) |
| the same, followed from the heavy's first tick: it lands | never out | hard | **Paper** | the rival holds toward him from the first tick (script `follow=1`); the blow must land |
| a medium: out only if he starts in its first 6 ticks | reported | reported | **Paper** | a seeded start tick sweep 0 to 11 |
| the medium AI winds up or charges a medium or a heavy, a minute of brawl | 4 to 10 | point | **Built** | `10.windup.perMin` counts `windup_start` cues over minutes of brawl; PENDING until the cue exists |
| a player's heavies miss the medium AI by its giving ground | 10 to 25% | point | **Paper** | needs the AI's giving-ground flag on the miss (a cue `gave_ground` or a `whiff` text) |
| the AI follows a player who gives ground | shares 0.3, 0.6, 0.9 by level | reported | **Paper** | same cue |

### H3. "Can I reliably launch my opponent?" (C2t)

| Row | Band | Kind | State | How |
| :--- | :--- | :--- | :--- | :--- |
| from a stagger of 12 ticks or more, a tapped B lands and launches | every time | hard | **Paper** | a `launcher` script: mash X until a `stagger` cue on the rival, then a B tap on the next tick. Needs the tapped B in the intent (Controls to say which field) and a launch event tied to the B |
| the route (X every 8 ticks, B on the stagger) launches in 50 to 75% of the brawls it is tried in against medium, 70 to 90% easy, 30 to 55% hard | by level | point, 100 brawls | **Paper** | the same script against each AI level; brawls tried = brawls with a stagger |
| a first launch inside 30 s of the first brawl, in at least 80% of matches at medium | at least 80% | point | **Paper** | from `brawl_start` and `launch` ticks |
| launches a match by the route's player at medium, and on him | 4 to 10; 4 to 8 | point | **Paper** | the launch events by victim; collateral (civilians and structures lost) is reported beside it |

### H4. "Do energy attacks look cool as part of close-range combos?" (C2t, §5b)

| Row | Band | Kind | State | How |
| :--- | :--- | :--- | :--- | :--- |
| a point-blank bolt lands 2 ticks after its press | exact | hard | **Paper** | a script that holds RB and presses X in reach (`stanceMask` bit 2); the press tick (`press_ack`) and the damage tick |
| a clean blast knocks back 4 bh | 4 bh | hard | **Paper** | RB + Y; the separation 30 ticks after the blast against the one before, along the stick's lean |
| no more than three full flashes in any second | at most 3 | hard | **Paper** | a mashed RB + X for 10 s; needs a `flash` cue with a full or spark text (the harness already reads `rec.cueText['flash:<text>']`) |
| energy blows are 5 to 15% of the medium AI's brawl blows | 5 to 15% | point | **Built** | `10.energy.share` reads brawl blow texts that name energy, a bolt or a blast; PENDING until one exists |
| a blocked point-blank bolt reaches the core once the arms are at their cap | reported | hard when built | **Paper** | needs the wear by region on the guard event |
| the bolt-only and mixed blaster rows | read again | | existing | the pairs `bolt-medium` and `blast-medium` stand; their bands are Game Design's to re-read after C2t |

### H5. The other rows from §11

- **Perfect blocks.** Banded by the minute at all three levels (1 to 4 medium, 0.5 to 2 easy, 2 to 5.5 hard): already in the baseline and unchanged. **Per 100 blows by strength is reported** (`7.pb.byStrength`, built): lights, mediums, heavies, read from `perfect_block` cues carrying the strength as their text and from the brawl's blow texts; bands (lights 0.5 to 1.5, mediums 2 to 6, heavies 6 to 15 at medium) are held after the first three-strength baseline. The total per 100 blows stays INFO. The harness needs the cue to carry the strength (`perfect_block` text) and the blow texts to name the strength (`light`, `medium`, `heavy`); the names are in `STRENGTH` in `bands.js`.
- **The zip drop.** A hard test by injection with no band: `zip.drop` (built) stays; `zip.drop.bolt` is reported only and now expected to stay PENDING.
- **`care`.** Protagonist 0.8 and rival −0.5, when Simulation applies it. It gets its own baseline: a **before** (the arms on the sha before the change) and an **after** (the same on the sha after), over the standing eight arms at 400, or the four core arms at 400 to save time, with the rows named in advance: the Protagonist's win rate over both slots (45 to 55), civilians lost at the KO (12 to 30%) and its split by fighter, structures lost, the brawl share, the brunts and flights rows, and the fight's biome shares (which way the AI nudges a brawl). A paired comparison by seed tells the change from the noise. The two runs cost about 2 hours each for eight arms on three jobs, or an hour each for four. It cannot be read until C1 gives the AI a nudge: before C1, `care` moves nothing.

### H6. What the harness needs, in one list (for Encounter and Controls, through the EP)

1. `windup_start` (actor, strength, the tick the blow lands) and its end (`blow` or `windup_lost`), for the giving-ground rows and the AI's wind-up rate.
2. A way to press B as a tap and as a hold in a scripted intent (which field), and the RB + X and RB + Y cells in reach.
3. The AI's own stick on a tick (or a share of ticks), for "the AI holds against a player's stick".
4. A `gave_ground` flag (or a `whiff` text that says why) on a blow that missed.
5. A `flash` cue with a full or spark text, and `perfect_block` with the strength as its text.
6. The strength on `blow` texts: light, medium, heavy, and bolt or blast for energy.


## I. After C1 as built, and the scripts for C2a and C2t (2026-10-06; Encounter's names from `docs/director/brawl-c1.md` and `brawl-plan.md` §10.3)

Built in `qa/`, no batch run; every script smoke-tested at one match on a scratch export of 53d13b55 (no crash; every new row PENDING there, since the build has none of the cues). Self-test 20 of 20.

### I1. The C1 rows, fixed to the build

| Row | Change |
| :--- | :--- |
| `c1.centre.step.*` (hard) | Reads the centre's **speed** (`vx`, `vy`, units a second over 60 and 75, in bh a tick), at most 0.3; the pair's middle moving over 0.3 bh because a strike placed its attacker is reported beside it (count and largest) |
| `c1.centre.latency` (hard) | Reads "moves at all within 2 live ticks" (the velocity's sign), not "at speed": the build answers on the tick after the stick is first read, small at first |
| `c1.walk.*` | The floor stays 12 ticks after the later stick is first read (or the jab's press), never sooner. Two AIs never walk out by rule, and an AI weighs a walk-out once (`walkOut` 0.1 to 0.3), so the pairs are two scripts |
| `double.trade240` (hard, new) | Every `double_hit` cue's `dur` (the trade's length) is 240 to 244, read from the records and from the pairs; C7 is built this way |
| `double.perMatch`, `double.matchesWith` | The AI against itself is **reported**. The band (0.5 to 2 a match, at least one in 35 to 65% of matches) is on the pairs `double-lights` (a lights-only presser, stick toward) and `double-mix` (L L H, stick toward) against the medium AI, as `double.presser.*`; Game Design measured 0.3 and 0.2 on C1, so they read FAIL until C2a's `digIn` |
| the lights mirror | The even mirror finishes (at least 95%) and its first slot (40 to 60%, at 200 matches) stay banded. **The momentum rows are retired** (the draw is gone). **The trade's two old hard rows are re-based to reported:** a break has no bound but the double hit; a close follows 85 to 95% of breaks (reported). A new **uneven mirror** (8 ticks against 10): finishes at least 95%, the faster tapper wins at least 80%, brink to KO 25 to 50 s |
| the zip drop | `drop_land` fires only when he was above the ground and reaches it in his 24 ticks (he falls about 1.07 bh); a drop that starts on the ground, or more than about 1 bh up, never fires it. My 3 hooked drops had none: the zipper was on the ground. The row asks for one start and one end for each down, and reports the lands; no seeds go to Encounter |

**A bug caught before it ran.** The first stick-hold script used the option name `hold=`, which the holder player already uses for the ticks of its hold (`hold=16`). A baseline run with it would have turned every holder script (T7 and the others) into a stick holder. It is `sthold=` now, and nothing was run between.

### I2. The harness stage and `--jobs`

The masher stage now builds one list of Godot jobs and runs it at most `--jobs` at a time (`pool` in `masher.js`, `jobs` from `run-godot.js`). Before, it started waves of three and seven jobs whatever `--jobs` said. The stage is 57 jobs long now (about 25 more than before), so it runs longer on `--jobs=3`: most pairs are 60 to 100 matches; the walk and drift pairs are capped at 150 sim seconds a match.

### I3. The C2a and C2t scripts (players.gd)

| Script | Spec | What it is |
| :--- | :--- | :--- |
| the Y masher, the B masher, the X masher | `masher:btn=Y:gap=12:tap=4`, `btn=B:gap=30:tap=4`, `btn=X:gap=6` | A press every gap ticks on one button (Y is the heavy edge, B a `sig` edge with no stance, X the light). `tap=N` holds the button's level for N ticks, a pad tap, so the wind-up reads a tap and not an edge with no level |
| the alternator | `mix:mix=XYB:gap=12:tap=4` | X, Y, B in turn |
| the X holder | `holder:kind=L:hold=60:rest=8` | holds X for 60 ticks, lets go 8: the burst |
| the 10-tick tapper with B | `mix:mix=XXB:gap=10:tap=4` | X X B |
| each flurry against the one it beats | pairs `fl-xy`, `fl-yb`, `fl-bx` | X every 6 against Y every 12, Y against B every 30, B against X, the second on a seeded offset of 0 to 7 ticks; rows `flurry.xy`, `.yb`, `.bx` at 55 to 75% |
| the launcher's route | `route` | mashes X every 8 ticks and presses one B on the tick a `launcher_open` names him (until `n`, the end of the stagger); pairs `route-easy`, `-medium`, `-hard`; rows `route.*` (50 to 75% medium, 70 to 90 easy, 30 to 55 hard), `route.every.*` (hard: none lapsed, a launch for each used), `route.first30` (at least 80% at medium), `route.perMatch` (4 to 10 by him, 4 to 8 on him) |
| a fighter who gives ground | `giver` (and `follow=1` on the rival) | presses nothing; from a seeded 0 to 22 ticks after a rival's `windup` start his stick goes away until the landing tick plus 10; his first step is timed. Rows: `give.lat.*` (hard, at most 2 ticks), `give.out.b` (hard: out of a tapped heavy every time when he starts by tick 16, the `miss` text `gave_ground`), `give.followed.b` (hard: never when followed), `give.medium.*` (reported) |
| an energy presser | `energy=1:btn=X` and `btn=Y` | RB held with X (bolts) and Y (blasts), the stick toward; rows `energy.bolt` (hard: the announced contact is 2 ticks after the press), `energy.flash` (hard: at most 3 full flashes in 60 ticks, 20 ticks apart), `energy.blast` (hard: the knock-back is 4 bh, within 0.25) |
| the burst against a mash | pairs `burst-dummy`, `mash-dummy` | damage a second of a held X against an X mash on a rival who never moves; `burst.share` 70 to 80%, never over |

Reads added: `windup` (start, end with `k`), `miss` (`gave_ground`, `reach`, `dodge`), `launcher_open` and `launcher_close`, `burst`, `energy_reach` and `energy_land`, the `launch` event by actor and target, the `knockback` event after a blast, and the perfect block's strength from the `stagger` cue's `source` (`pbstrength:` keys; `7.pb.byStrength`, reported). The AI's wind-ups a minute of brawl (`10.windup.perMin`, 4 to 10) and the energy share of its brawl blows (`10.energy.share`, 5 to 15%) read the same cues in the arms.

### I4. Not done, and why

- The AI's own stick on a tick (`DirBrawl.stick(ex, f)` exists): "the AI holds against a player's stick on under 25% of the ticks" needs a script that reads it every tick; it is one more counter in `drift=` and I have not built it. Say if it should go in.
- A blow's wound region and strength on the damage event (Simulation's): not needed by these rows.
- The mood and the `care` before-and-after: unchanged from section H5.


## J. The heavy's hold, the leash, the signature tell and the closing rule (2026-10-06; `brawl-second-pass.md` at 57abfec9, and the EP's answers)

**Built now:**
- `c1.aihold` (point, under 25%): the medium AI holds its own stick against a player's held stick on under 25% of the ticks he holds it. It reads `DirBrawl.stick(ex, f)` for the AI (its nudge, kept out of its intent) on every tick of the `c1-drift-ai` window and counts those whose x opposes the player's stick.
- `closing.d` (hard from C2t, PENDING before): a blow lands d ticks later than its own time, d from 0 to 4. The `windup` start cue gives the wind-up (`dur`) and the landing tick (`n`); the harness logs `[dur, n minus the press tick, the gap in bh]` for up to 400 presses (the alternator `str-alt` presses every strength from every gap). The exact formula (d the smaller of 4 and twice the gap in bh rounded up, a light at 2 + d, a medium 12 + d, a heavy 28 + d, the launcher 14 + d) is checked once Encounter confirms which gap it means; the samples are in the row's note for that.
- `closing.step` (hard: no blow moves its attacker more than 0.6 bh in a tick): counted on every `blow` cue as the attacker's step on that tick. On 53d13b55, with no closing rule, a 1-match smoke saw 1 of 70 blows move its attacker 1.07 bh, so the row is INFO (reported) until a build has the wind-up cue, and a hard test from C2t on.

**On paper (the heavy's hold; Encounter's cue names `charge_full` and `charge_release`, no scripts yet):**

| Row | Band | Kind | How |
| :--- | :--- | :--- | :--- |
| B still down at 32 keeps charging; full at 44 live ticks after the press (`charge_full`) | 44 | hard | a `charger` script: `masher:btn=B:gap=90:tap=60` holds B for 60 ticks; the `charge_full` live tick less the wind-up start |
| the blow goes 4 ticks after release; by itself at 70 | 4; at most 70 | hard | hold 50 (release) and hold 80 (auto) pairs; the `windup` end `k` 1 tick against `charge_release` |
| armoured while he winds or charges: a light never ends it and does half; a medium ends it only in its first 20 ticks | exact | hard | a rival who mashes X, then Y, into a charging B: the `windup` end `k` (2 stopped by a blow) by the rival's strength and the tick |
| a clean hit knocks back; at a full charge it launches, every time, aimed by the stick | every time | hard | a charger against a rival who never moves; a `launch` event for each full release with `ux` of the stick's sign; the knock-back otherwise |
| a miss leaves him open 20 ticks | at most 20 | hard (it is the failed-option row) | the `miss` cue's `n` after a charge released out of reach |
| the AI charges 0.15, 0.3 and 0.45 of its heavies (easy, medium, hard) and lets go within 8 ticks of the flash | shares | point, reported | `windup` start counts by `dur`, and the release tick less the `charge_full` tick for the AI |
| a fighter who gives ground against a charge | out of a full charge | hard | the `giver` against the charger: he is out if he starts in time; the gap passes its reach about 45 ticks after he starts to back off when followed (reported) |

**On paper (giving ground):**
- **The leash is 2.4 bh past striking distance, so a light always reaches a fighter who only gave ground** (hard): the `giver` pairs log the largest gap, in bh, over the give window; the row needs the build's leash number and the striking distance (both data keys under `brawl.give`, not there yet), and the light's reach test: after the window, a light pressed by the rival lands (no `miss` cue on it).
- **He may give ground during a signature's tell in reach** (movement only; it does not change the beam's outcome): a `giver` against a rival holding RT + B (a `sig` edge with `stanceMask` 4): his first step within 2 ticks (hard); the beam's outcome (`clash`, `guard`, `dodge`, `hit`) is read as before and is reported by whether he gave ground.

**Contact rows** (press to contact by button) now read the closing rule: X at 2 + d, Y at 12 + d, B at 28 + d, the launcher at 14 + d, d from 0 to 4; the old "never past 16, 32" bounds are the same thing at d at most 4.

# The split by path, the tenth round's pieces, the guards, and the two apart

Owner: Combat and Choreography. Date: 2026-10-15. The EP's brief of 2026-10-15 (Orb: "the depth and breadth of animations and mechanics continually refined and enhanced"). Everything is parked. Nothing in `data/` is changed. Measured in a scratch copy of main (f3e1a713).

## 1. The split by path, built and measured

**What is built.**
- **The pool builder** has `--split` (Combat's scratch, `make_pools_n.py` and `split_block.py`). Each style of Y and B draws on its own pieces, by the piece's path. Each fighter's charged heavy, as Game Design names it, stays in his held B whatever its path. The held X's floor draws on the burst's mid class.
- **The generator** (`pending/movegen/`) carries the split as quotas: each group keeps 5. A fighter's row may add places to a cell (`adds`). One pick now meets as many short quotas as it can, in strike cells only. Self-test passes; the two in the build read 37% and 35% as before.

**The pools.** Counts are Anti-hero / Protagonist; figures in brackets wait on Animation's poses.

| Style | Pool | Pieces |
| :--- | :--- | :--- |
| Y tapped, the stop | A quick medium on a line or a rise | 5 / 4 (+1) |
| Y mashed, the grind | A quick medium that drops or arcs | 5 / 6 |
| Y held, the patient close | A medium with a long wind-up | 4 / 4 |
| B tapped, the hammer | Every heavy | 10 / 10 |
| B mashed, the advance | A heavy on a line or a drop | 6 / 4 (+1) |
| B held, the big read | A heavy that arcs, rises or spins, plus his charged heavy | 5 (+1) / 6 |
| X held, the floor | The burst's mid class | 13 / 12 |

**The three pieces,** added by the quotas:
1. **The Protagonist's stop: a rising palm to the gut.** It's a re-aim of his rising palm, so it needs no new key set.
2. **The Protagonist's advance: a stepping palm to the arm.** A new key set.
3. **The Anti-hero's big read: an unwinding fist to the jaw.** A new key set; it is also a launcher that turns him.

All three are his own and pass Legal's rows.

**What the AI throws, before and after.** Ten seeded matches against the medium AI, 300 s each. The held Y and held B rows were read with Encounter's parked charged medium in.

| Cell | Blows in 10 matches (A / P) | Before | After |
| :--- | ---: | :--- | :--- |
| Y tapped | 76 / 74 | 10 pieces; rises 41/35%, drops 29/26%, arcs 18/32%, lines 12/7% | 5 / 4 pieces; rises 67/70%, lines 33/30% |
| Y mashed | 2 / 6 | Every blow is a tapped piece | None is |
| Y held | 0 / 0 | The medium AI never charges a medium | |
| B mashed | 1 / 1 | | Lines or drops only |
| B held | 6 / 4 | Drops, lines and arcs | Arcs, rises and spins |
| X held, the floor | 47 / 20 | 23 / 16 pieces; drops 17/10% | 13 / 12 pieces; no drop, no kick |
| Every other cell | | Unchanged | Unchanged |

- **The matches played out the same, blow for blow:** 18,498 blows before and after, and 16,872 with the charged medium. A piece is the picture, not the fight. So QA's re-read of the mashed rows should find the bands where they are.
- **The AI uses the split little.** It taps Y and B. It almost never mashes them, and never holds Y. The split shows on QA's masher and holder scripts and in a player's hands.
- **The B held row** was read before each fighter's charged heavy was pinned into his pool, which adds the Anti-hero's ram.

**Two ways to land it** (`pending/split/`):

| File | What changes | Who else |
| :--- | :--- | :--- |
| `recipes.held-only.json` | The held B, the held Y and the held X's floor. The held Y shows once the charged medium is built | Nobody. **Tools' schema passes as it is** |
| `recipes.split.json` | All of it | **Encounter:** a mashed medium or heavy asks for `mediumMash` or `heavyMash`, else the tap's cell. It's a few lines; my stand-in is `_mashCell` in scratch. **Tools:** the two keys in `combat-recipes.schema.json`, under `brawl` and in `fallback.lower`'s names. The validator otherwise reads 4 errors |

- **Landing the tap's split without the mash key would lose the grind.** Every mashed Y would then throw the stop, and the drops and arcs would never be thrown. The full split wants the hook and the schema in the same commit.
- **One sketch moved.** The Hopper's stepping palm to the arm was the same blow as the Protagonist's new heavy. The fighters in the build come first, so his became a stepping blade hand to the arm. The other three sketches, their gate shares and the two in the build are unchanged.

## 2. Pieces for Game Design's tenth round

Counts are Anti-hero / Protagonist. "Exists" means a posed piece in the live pools.

| Mechanic | What serves | What is new |
| :--- | :--- | :--- |
| **The cash-in** (RT+B in a perfect window, an instant heavy) | **The launcher's pieces by send**, when the launcher is ready (2 each way / 2 up, 1 down, 2 across, 2 turned); the ender's otherwise. The rises and lines read with no wind-up: the heaves, the ram, the knee / the palm heave, the ball-of-foot heave, the edge kick, the blade to the jaw | **A cash-in row for Animation:** from the follow-up's held pose, no load, a long hold, the hit's flash. Whether a falling or turning heavy reads with no wind-up is Animation's call. If not, one short downward heavy each |
| **The duel of perfects: the riposte in kind** | **Y:** the reversal pool, lines and rises out of the guard (5 / 4). **B:** the ender, below | **X:** today a riposte light draws on every light, kicks and drops included. A riposte pool of the lights on a line or a rise that come out of the guard (9 / 8, all posed) is a data line, with a key for Encounter |
| **The duel: the amplified send** | The follow-up's own piece. The flight, and the double hit's staged picture at level 8, exist | No strike piece. The levels are VFX's, the camera's and Audio's. Animation: the contact's hold growing by level |
| **The chase's mid-air beatdown** (up to six blows) | **The held X's burst strings,** generated by the stick's lean (5 a fighter). Each blow sends along the lean, and the strings are already built by lean. The arrival blow is a zip strike's piece | No strike piece. Animation: the travel between blows, drawn every tick inside Legal's travel floor |
| **The director's ender: building** | The launcher's across-sends into it (2 / 2), and the wall slam | None |
| **The ender: spike** | The launcher's down-sends: falling heel and hammer fist / **the falling palm alone** | **A second falling heavy for the Protagonist.** With one, a second spike in a row falls back to a medium. Generated under his identity; never the Anti-hero's falling heel |
| **The ender: uppercut** | The launcher's up-sends (2 / 2) | None |
| **The ender: knock-back** | Any heavy of the tier, and the hammer's push | None |

## 3. One versus many

**Does an interjection from the ring need pieces of its own? No new key sets.** It needs three things:
- **A piece on the beat.** Today the ring beat carries none, so the renderer plays the strength's default (Encounter's `_schedule`). A recipes key `interject`, read the way the cells are, is Encounter's.
- **A pool of the guard's lights on a line or an arc in,** for a blow from the side of the pair: jab, cross, spear hand, palm heel, hook, short elbow, shoulder, short knee and knee hook (9). From the air above, when Encounter turns on `kinds: ["medium"]`, his mediums that drop: dropping elbow, overhand, stomp. Kicks stay out of the interjection: they're for his own brawl as a partner.
- **A tell he can see for 10 ticks on a light** (Animation). The speed row loads in 2. The medium row's shape at 10 ticks, carried by the closing step, is the nearest.

**The guards' kit, generated** (`pending/roster/moveset.guard.json`, from a kit row in `identity.candidates.json`):

| Cell | What it holds |
| :--- | :--- |
| Lights | 16, all common and posed: four straight hands, a hook and a backfist; two elbows, two knees and a shoulder; five low or plain kicks |
| Burst | 5 strings built from those lights |
| Mediums | 10, all common and posed: rises (uppercut, rising knee), drops (dropping elbow, overhand, stomp), lines (body ram, driving knee, double palm) and arcs (haymaker, roundhouse) |
| Heavy | 1, new: **a falling sole to the chest.** No heavy of the tier is common, since each fighter's ten are his own |
| Bolt | 1, new: **the measured bolt, from an open palm,** thrust and planted |

- **How a kit row works.** It has only the cells its kit names, draws only on posed common pieces, has no share rule, is outside the gate as the dummy is, and is never counted when the common pieces are found. No spin and no headbutt: the guards are a screen, not brawlers.
- **The two new pieces are key sets on the mannequin.**
- **Each common piece names one of the two fighters' key sets.** Whether the mannequin can play them, and on which body, is Animation's to say: the reference fighter has no animation data yet. Simulation's dummy script lists "his moveset" as Combat's and Encounter's: this row is it, once it is a pool in the recipes.

## 4. The two apart: Game Design's §8, against the data

Read from the measure above (what the AI throws, every cell but energy, zips and the double hit), the pools and the packs.

| Game Design's line | True in the data today | Missing |
| :--- | :--- | :--- |
| **Fluid arcs; snappy lines** | **His heavies arc** (43%, and spins 10%); the Anti-hero's drop and go straight (30% and 23%). **The lights don't differ:** his paths are rises 35%, lines 33%, arcs 30%; the Anti-hero's lines 37%, rises 29%, arcs 30% | **The motion isn't per fighter.** The press-style rows are the same for both (only the set and squash poses differ). Animation: a per-fighter modifier, a longer follow-through and overshoot for him, none and a held stop for the Anti-hero |
| **What he throws most** | **His open hands, true:** palm 34%, blade 11%. The edge of his foot and his spins are almost never thrown (2% and 0%) | **The Anti-hero's most thrown hand is a blade hand (22%), not a fist (17%).** His jab, cross and spear hand are drawn open in the first pack, which is the Protagonist's ground. Fist versions would be a hand-state swap on the same key sets (Animation, small) |
| **Held X: circling palms; piston jabs** | **His burst is palms in 44% of blows,** rising or straight, with arcs in 30%. **The Anti-hero's is straight in 32%,** but with a blade hand | A lean in the burst toward each look (identity weights for the strings: mine, in the generator), and the fists above |
| **The charged heavy: a coiled palm; a ram behind the plate** | **Not today:** a held B throws any of the ten. **In the split** both are in the held pool (the palm heave; the ram, pinned) | At full charge, his named heavy rather than any of the pool: a rule in the hook (Encounter). Animation's load poses for both exist |
| **The perfect follow-up: a palm that turns; a fist behind the plate** | The follow-up isn't built (§16). **The pool it would draw on holds no palm for him** (kicks, chops, a backfist, a hammer fist). For the Anti-hero, plates on drops (plate drop, plate hammer, forearm drop) | **A turning palm light for the Protagonist** (new). **A straight light behind the plate for the Anti-hero** (new, or the cross as a fist) |
| **The director's sends: up and away, turning; down and back, into buildings** | **The launch planner's personality is in:** the hero's care for people, and the collateral-feeder's pull to tall buildings. The stick picks the send | **No preference between up, down and turned by fighter** when the director shapes an ender (Encounter's data). The Protagonist's second falling heavy (section 2) |

## 5. Pieces, in one list

| Who | Piece | Source | State |
| :--- | :--- | :--- | :--- |
| The Protagonist | A rising palm to the gut (re-aim) | The split | Generated |
| The Protagonist | A stepping palm to the arm | The split | Generated, waiting |
| The Anti-hero | An unwinding fist to the jaw | The split | Generated, waiting |
| The Protagonist | A second falling heavy | The spike ender | Not yet generated |
| The guards | A falling sole to the chest; the measured bolt from an open palm | On the mannequin | Generated, waiting |
| The Protagonist | A turning palm light | His perfect follow-up | Not yet generated |
| The Anti-hero | A straight light behind the plate | His perfect follow-up | Not yet generated |
| The Anti-hero | Fist versions of the jab, the cross and the spear hand | Hand-state swaps | Not yet generated |

## 6. To run it

```
python -B docs/combat/pending/movegen/gen_moveset.py --check
python -B docs/combat/pending/roster/build_roster.py --check
```

The first passes. The second exits 1 on the Empress's gate line alone, as before.

The pool builder, the probe and the setup are in Combat's scratch, and so is the measure's log:
- `make_pools_n.py`, `split_block.py`, then `pools_n.py --split --out FILE`.
- `split_setup.py --recipes FILE [--pass2]`, then `split_probe.gd`.

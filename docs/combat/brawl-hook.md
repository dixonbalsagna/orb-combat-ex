# The brawl asks for a piece by its cell: the hook, for Encounter

Owner: Combat and Choreography. Date: 2026-10-12. For Encounter to apply in its own files; the EP routes it.
Written against `sim/director/brawl.gd` and `sim/director/recipe.gd` at `d6aee3c3` (neither has changed since `68c1bbbb`), and Combat's parked recipes (`docs/combat/pending/recipes.brawl.json`, which becomes `data/combat/recipes.json` in the same window).

**Why.** Today `_piece` picks the pool by strength alone: `power.last` for B, `combo.accent` for Y, `blur.base` or `blur.toward` for X. So B plays the old heavies, a medium plays an accent piece, a bolt is an ordinary light and a blast an old heavy. The recipes now name a pool for every cell. The hook is to ask for the cell and read the pool's name from the file.

A stand-in for part 1 ran in Combat's scratch copy of HEAD (four AI matches, 7,298 brawl blows). Every heavy and launcher came from the tier, every bolt and blast from the energy pools, and no blow was left without a piece. The same seeds on today's pools gave the same blows and the same match lengths: the pick changes the look and nothing else. The counts are in `pending/nine-cells.md`. Parts 2, 4 and 6 have not been run.

## 1. `_piece` takes the cell (brawl.gd:907)

```diff
-static func _piece(S: SimState, f, st: int, toward: bool) -> String:
+static func _piece(S: SimState, f, st: int, toward: bool, cell: String = "") -> String:
 	if not DirRecipe.on():
 		return ""
 	var pool: String = "power.last" if st == 2 else ("combo.accent" if st == 1 else ("blur.toward" if toward else "blur.base"))
+	var named = DirRecipe.rec().get("brawl", {})   # Combat's recipes: the pool each cell draws on
+	if cell != "" and named is Dictionary and named.has(cell):
+		pool = String(named[cell])
```

Today's four pools stay as the fallback, so a recipes file with no `brawl` block plays as it does now.

**The three callers.**

| Where | Today | The cell to pass |
| :--- | :--- | :--- |
| brawl.gd:823, every press | `_piece(S, f, st, toward)` | `launcher` when `lau`; else `blast` or `bolt` when `energy` (`st` 1 or 0); else `heavy`, `medium`; for a light, `lightToward` with the stick toward, `flurry` when `inFl`, else `light` |
| brawl.gd:355, `blowAt` | `_piece(S, f, <by the blow's kind>, false)` | a burst's blow by the class of the gap before it: `burstFast`, `burstMid` or `burstSlow`, from `burst.slots[n - 1]` for blow `n`; `burstFloor` for the pace it settles to. The double hit keeps today's pool: it has no cell |
| brawl.gd:506, the reversal | `_piece(S, f, 1, false)` | `reversal` |

As run in scratch, at 823:

```gdscript
var cell: String = "launcher" if lau else (("blast" if st == 1 else "bolt") if energy else ("heavy" if st == 2 else ("medium" if st == 1 else ("lightToward" if ((pp >> 2) & 3) == 2 else ("flurry" if inFl else "light")))))
var piece: String = _piece(S, f, st, ((pp >> 2) & 3) == 2, cell)
```

**A charge picks again.** A wound blow's piece is chosen at the press, before anyone knows whether the button is still down at the wind-up's end. When it becomes a charge (the `windup` cue's `charge`, brawl.gd:2102, and the charged medium of pass 2), take a new piece from `heavyHeld` or `mediumHeld` and put it on the beat. `mediumHeld` is the only place the mediums that need a long wind-up are thrown.

## 2. The launcher's pick, by where it sends

The launcher's pool is `brawl.launcher`. Each piece's row has `sends` (`up`, `down`, `across`, `turned`). The recipes' `launcher.aim` maps the stick's quarter to the send wanted: up to `up`, down to `down`, toward to `across`, away to `turned`. With no stick the launch planner's pick decides the send (`launcher.noStick`).

In `_piece`, when the cell is `launcher`, keep the first pick whose row has that send, in the same loop that turns away a second blow to the gut:

```diff
 	for salt in range(6):
 		...
 		id = DirRecipe.pick(S, f, pool, _g(f, BLOWS) * 8 + salt)
 		var pc = pieces.get(id) if pieces is Dictionary else null
 		var gut: bool = pc is Dictionary and String(pc.get("target", "")) == "gut"
-		if not (gut and _g(f, GUT) == 1):
+		var sends: bool = want == "" or (pc is Dictionary and (pc.get("sends", []) as Array).has(want))
+		if sends and not (gut and _g(f, GUT) == 1):
```

`want` is the send for his quarter (`_quarter(f, o)`, which the beat already carries as `aim`). When six tries find none, the step lower applies (part 6): `launcher.bySendLower` lists his posed mediums by send. The Protagonist has one piece of the tier that sends down, so this path is used.

**The wrench** (C2b) is found the same way and has no pool: a held B on a battered limb takes a heavy of `brawl.heavy` whose row's `target` is that limb (`arm_r` or `legs`). When he has none, it takes his nearest heavy, as Game Design ruled. Each fighter has one for an arm and one for the legs: the rival's `strike.su_plate_arm` and `strike.su_edge_legs`, the Protagonist's `strike.su_hammer_arm` and `strike.su_knee_legs`. A tapped B may throw them too: the blow lands on the limb, and it is not a wrench.

## 3. No explicit style (brawl.gd:351, 504, 801)

```diff
-		"style": "heavy" if wound else "speed", "grade": "none", "k": k, "n": k, "closing": _closes(S, ex, f),
+		"grade": "none", "k": k, "n": k, "closing": _closes(S, ex, f),
```

The same at 351 (`blowAt`) and 504 (the reversal). Keep `strength`, `flurry`, `energy`, `burst`, `launcher` and `wind`: they say what the blow is. Animation's renderer takes an explicit style before anything else (`render/anim/anim_fighter.gd:2163`), so its strength-to-style map (`data/anim/press_styles.json` `strength`: medium, super, and the bolt and blast rows) is never reached while the beat names one. Today a medium and a heavy both say `heavy`.

For Animation, with this: the map is read only when the beat also says `flurry` (anim_fighter.gd:2167). A tapped medium or heavy would fall through to the old branches once the style goes, so that branch has to take any brawl blow that carries a strength.

## 4. The hand, for mashed bolts (brawl.gd:801, 351)

`"hand": "r" if (k % 2) == 1 else "l"` is right, left, right, left. For a mash of point-blank bolts that is the pump Legal's e09 bans.

The recipes give the order ready-made: `reach.runs[fighter]` holds two runs of twenty bolts, each with the arm that throws it (`lead` or `free`). Each run is a loop: played round and round it still keeps every rule. So for a bolt that follows a bolt in the same string, take the next piece and arm from his run (pick one of the two by a keyed draw when the mash starts) and never from the pool. A single bolt between punches takes the pool and the hand it has today.

`lead` and `free` are which arm, not which side: Animation mirrors a bolt for the free arm.

## 5. Rules that are not at run time yet

`DirRecipe.pick` keeps "never one of his last two pieces", and `_piece` keeps "no two blows running to the gut". Legal's other string rules are in the data and not in the pick. Counted in the same four matches, on the pieces table, over 7,298 blows:

| Rule | Legal's row | What the data gives | Broken with the hook | On today's pools |
| :--- | :--- | :--- | ---: | ---: |
| Never one of his last two pieces | (the director's own) | | 0 | 0 |
| No two running to the gut | s02 | `pieces[id].target` | 2 | 0 |
| No more than two running to one place | s02 | `pieces[id].target`, and his last two places | 106 | 238 |
| A rise is never followed by a rise while he is airborne | s05 | `pieces[id].path` | at most 52 | 0 |
| A spin is never followed by a spin or a head kick | s04 | `pieces[id].path`, `limb`, `target` | 0 | 0 |
| No more than three running of one limb, tip and path | s01 | `limb` and `path` (a row has no tip: judged on the two, it is stricter) | not counted | |
| The burst's own four | f05 | `burst.rules` | not counted | |
| Never the same energy hand and release twice running | e06 | `reach.rule`, `reach.pieces` | kept among bolts: each is its own pair, and no piece follows itself. A blast after a bolt is not a repeat (Legal, `321c046d`), so the pick does nothing for it | |
| A mashed run of bolts reads as varied | e09 | `reach.run`, `reach.runs` | part 4 | |

- **The two gut blows are one give-up.** After six tries that all draw the gut, `_piece` takes the last one and clears the flag (brawl.gd:924), so the blow after it may go to the gut as well. It happened once, on the rival's bolts: two of his four go to the gut. Asking the pool for a piece that is not to the gut, in place of six blind tries, closes it; so does the step `repeat` or `lower` of part 6.
- **The rises:** the probe did not read whether he was airborne, so 52 is a ceiling. The new pools hold more rising blows than the old ones.
- The rules count the whole string, whatever button threw each blow (Legal's f02). `PIECE_1` and `PIECE_2` already do, since they are one pair a fighter.
- Two more small ints a fighter (his last two places) and one for his last path cover s02, s04 and s05.

## 6. The fallback: no press is silent

`fallback.steps`, tried in order when a cell's pool has nothing it may throw:

1. `pool`: a piece of the cell's pool, not one of his last two, inside Legal's rules.
2. `repeat`: one of his last two again, the older first, when Legal's rules allow it.
3. `lower`: a piece of `fallback.lower[cell]`, thrown on this cell's wind-up and at its worth. For `heavy` and `heavyHeld` that is `brawl.heavy.lower`, the old stand-ins; for `launcher`, `brawl.launcher.lower`.

Legal's rules are never dropped. On the tier's ten a fighter, a tapped or mashed B never leaves step 1 (counted over every two blows of his pools). The launcher leaves it only when the stick asks for a send the tier has one piece for, or none it may throw.

## 7. What moves

- `data/combat/recipes.json` is in the data hash, and the picks change, so the goldens are regenerated once, in the window.
- The frozen parity copy (`sim/director/test/combat-parity/`) holds templates and finishers only. It is not touched.
- `pieces` stays one row an id for both fighters.

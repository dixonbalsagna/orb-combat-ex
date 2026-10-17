# What the run asks of the collateral and the buildings: World's side (paper, 2026-10-16)

Owner: World and Environment. **Paper only: nothing in `sim/` or `data/` changed by this note.** It answers Simulation's `docs/architecture/run-core.md` (section 5's ledger, section 6's tier tables, section 7's planet ceiling and its World row) and Game Design's `docs/design/run-mode.md`. The five asks, read from the code on main (e6fa72ff and after):

| # | Ask | Where it lands | Hash / golden in a versus match | Size |
| :--- | :--- | :--- | :--- | :--- |
| 1 | A building's place id and plan index | `Building.place`, `Building.plan` (`state.gd`), set in `terrain.gd` and later by window 3 | Not in the per-tick hash. A versus match is unchanged. The tick-0 `world` hash (Simulation's) covers them | S |
| 2 | The owner on every damage path | Audited below: every call site already passes one; three gaps to close for the new sources | None | S (code and one lint) |
| 3 | Budgets and ceilings as shares of `stage.present` | `S.world.present` in `collateral.gd` (5 sites), `structures.gd` (2), and two others that are not mine | None in versus: present equals `pop0` | S |
| 4 | `ceilingLeft` taking `peopleLeft` | One line in `WorldCollateral.ceilingLeft`, plus `S.world.peopleLeft` | None in versus (no limit) | S |
| 5 | The three collateral tables in data, with the catastrophe kind | `data/biomes/collateral.json` (new, with a schema); `collateral.gd` reads it | None if the file holds today's numbers (a check proves it) | M |

Also, from the EP: **no minions for the Cyborg** (Orb, homework 19). No world document assumes them: a search of `docs/world/` finds none. The only mention of the Cyborg there is his collateral-fed meters (Hunger per civilian, the molt thresholds: `collateral-caps.md` section on `norm`), which stay as they are. The one-versus-many guards (`empress-guards.md`) are a different fighter's, and World's N-body patch (`scratch-build/n-bodies/`) is by slot, not by fighter.

## 1. A building's place id and plan index

- **Fields:** `Building.place: int = -1` (the place's id: its index in the planet's places list, window 1's `WorldPlanet`; for today's Bellgate setup, the settlement's index 0 to 3 in `settlements.json`) and `Building.plan: int = -1` (its index in that place's plan: today, its position in `WorldSettle.generate`'s building list for the settlement; the list is seeded and sorted by x and row, so the same building has the same index every time).
- **Where set:** `terrain.gd` where each plan entry becomes a `Building` (the `for e in g.buildings` loop, which already knows `si`, the settlement index, and the entry's position). So **Bellgate gets real values now** (the four settlements), and a ledger can be tested on today's world before the planet is read. Window 3 sets them from a city's plan.
- **Not hashed per tick:** `idx` is already set at generation and "not hashed"; these two are the same kind of field (set once, never change). They go in Simulation's tick-0 `world` hash (the buildings as placed), a new hash with no existing golden.
- **Use:** `WorldCollateral.kill` gets the place by `S.buildings[bi].place` (no signature change: `kill` already takes the building index); the wear list's building records are `[plan, stage]` per place (`WorldPlanet.wearBuilding`).
- **Size:** two ints a building, about 120 buildings. One test: every building has `place >= 0` and the `(place, plan)` pair is unique.

## 2. The owner on every damage path

Every path that can bring a building down or kill a civilian, read from the call sites:

| Path | Owner it passes | Can it be none? |
| :--- | :--- | :--- |
| Ground pound, power-up crater (`fighter.gd:22`, `:58`) | the fighter `f` or `by` | No |
| Melee strikes, launches (`melee.gd:237`; `contact.gd:715`, `:824`; `slide.gd:151`) | the attacker `A` / `by` | No |
| A launched body's brunt, chain, lodge, splash (`brunt.gd`: `by` throughout) | `by` = the flight's launcher: `f.launchBy`, else `SimRoster.opp` (World's patch: `WorldCollateral.launcherOf`, nearest foe) | No with two bodies; with more, `launchBy` must be set (the director sets it) |
| Blasts and shots (`blast.gd:98`, `:135`, `:171`, `:178`, `:187`) | the shot's owner `f` | No |
| Beams (`beam.gd:245`, `:247`, `:280`) | the beam's fighter `A` | No |
| Collapse, rubble (`structures.gd:494` `collapse`) | the cause of the blow that finished it | No |
| The failing stack (stage C, parked) | `failBy`: the slot of the fighter who brought it down; **-1 when none did** (a spent tower with no cause) | **Yes: the one existing gap** |

Three gaps to close, all in what the run adds:

1. **A failing stack's `failBy`** may be -1. In the run's boss fight, the cause is always a fighter (the crack comes from a power send, a beam or an ability), so `startFail` must be given the cracker; a probe asserts that no stack starts with -1 in a match with a `stage`.
2. **Hazards** (Research's magma, the exosphere bombardment's craters, a falling stack's dust): each must carry the owner of what made it. **Magma** keeps the slot of the fighter whose beam bored the shaft, in its state (`S.cata`/the magma state, Simulation's and Research's), and a collapse its heat causes passes that owner; **a bombardment shot** has the shooter. "No owner" is then a real case only for a death with no fighter behind it at all, and the ledger counts it as `other` (Simulation's cause column).
3. **A lint** (in `parity.gd`'s existing family: "`kill` is the only place a civilian dies"): no call site of `damageBuilding`, `damageArea`, `explode` or `collapse` passes a literal `null`. Today none does; the lint keeps it so.

## 3. Budgets and ceilings as shares of `stage.present`

- **The state:** `S.world.present: float` (the people present at the stage's start). `init` sets it to `pop0`; a setup with a `stage` block sets it to `stage.present` (the host computes it: `WorldPlanet.slicePeople` summed over the slice's places with the run's wear, so a slice through ruins has fewer). In versus the two are the same number, so nothing moves.
- **The five sites in `collateral.gd`** read `present` where they read `pop0`: `budget` (line 108), `ceilingLeft` (119), `beginEvent`'s allowance (134), and the two normalisations (`kill`'s `norm`, line 225, and the evacuee menace, line 210).
- **The two that are mine in `structures.gd`** (17 and 21: the near and building share references, `pop_refs` times `pop0`) take `present` as well (Game Design ruled that "population references scale with the people").
- **The two that are not mine:** `mood.gd:403` (the mood's casualty impulse, `casualties / pop0`) and `launch.gd:254` (the chain's allowance for the director's planning, `EVENT_ALLOW * pop0`). The first is Simulation's, the second Encounter's: both must read `present` or the chain plans against a budget the world no longer gives. Listed here so they are not forgotten.
- **A question for Game Design (meters):** the per-casualty gains (menace, the villain's power, anguish) are `x 425 / pop0`, "so the meters read the share of the population lost". With `present` below `pop0`, dividing by `pop0` makes a casualty in a half-ruined slice worth half as much; dividing by `present` makes it worth the same share of what is there. Their `run-mode.md` says "the meters read what is really there: a villain can't feed in ruins", which reads as **`present`**; the paper keeps `pop0` for the meter normalisation until they say, as one constant.
- **Hash:** `present` joins `S.world`'s hashed list only when it differs from `pop0`, a conditional append as World's N-body patch did for `evtMore`: a versus hash is unchanged byte for byte.

## 4. `ceilingLeft` taking `peopleLeft`

- `S.world.peopleLeft: float`, set from `stage.peopleLeft` (the whole people the run may still lose: the planet's ceiling of 40% before the boss and 70% by the end, minus what has died), or a large number when there is no `stage` (versus: no limit).
- `ceilingLeft` becomes `minf(maxf(0, CEILING[maxTier-1] * present - casualties), peopleLeft - casualties)`: the lower of the tier's own ceiling and what the run may still lose. Past it, people shelter, as they do at today's ceiling (nothing else changes: `isOver` reads `ceilingLeft`).
- One line plus the state; hashed conditionally with `present`. A check: a match with `peopleLeft` set to 100 never loses more than 100.

## 5. The three tables in data, with the catastrophe kind

- **File:** `data/biomes/collateral.json` (schema `biomes-collateral.schema.json`, and Tools' two lines: the map rule and four invalid cases, as `planet.json` needed):

```
{ "schema": "biomes.collateral/1",
  "budget":  [0.02, 0.04, 0.08, 0.15],        # per rolling 60 s, by tier 1 to 4, shares of present
  "ceiling": [0.10, 0.30, 0.60, 0.90],        # cumulative, by tier
  "eventAllow": { "slide":     [0.0, 0.0, 0.05, 0.10],
                  "chain":     [0.0, 0.0, 0.12, 0.20],
                  "landslide": [0.0, 0.0, 0.05, 0.10],
                  "quake":     [0.0, 0.0, 0.0,  0.10],
                  "catastrophe": [0.0, 0.0, 0.0, 0.0] } }
```

- **The catastrophe kind** is a fifth set-piece kind beside the four (Research's mass-collapse set piece, `79a0941e`): its allowance at tiers 1 to 4 is zero (a catastrophe is a tier-5 event), and its **fifth entry lives in `data/fight/tier5.json`** with the other tables' fifth entries (run-core.md section 6), so a versus replay's data hash does not change. `beginEvent("catastrophe", cause)` works like any kind; the numbers are Game Design's.
- **The tables read by index `tier - 1`, and `tier()` clamps to 4 today.** A stage's ceiling comes from the setup (`stage.ceiling`, 5 for the boss): the tier functions clamp to the setup's ceiling instead of 4, and the fifth entry is read only when the setup's ceiling is 5. The check run-core.md names (every inventoried table has its fifth entry) covers these three.
- **The kind names become the file's keys,** so `EVENT_KINDS` in World's parked N-body patch (the list that keeps the extra set pieces in a fixed order) reads the file's key order instead of a constant; that patch needs a small re-cut when this lands (they touch the same file).
- **A check that proves the move changes nothing:** the loader's tables equal today's constants for tiers 1 to 4 (a test holds the old constants as the expected values for one release), and the 1v1 golden is byte-identical.

## 6. Order and what each needs

1. **Now, no code from me:** this paper, to Simulation (their ledger's cause and place columns), Game Design (the meter question, the catastrophe numbers) and Encounter (`launch.gd:254`).
2. **A World window ("collateral for the run"), on the EP's go,** in scratch on HEAD and parked: the five items in the order 5, 3, 4, 1, 2 (the data move first, because it is the one with a proof of "nothing changed"; then `present` and `peopleLeft`; then the fields and the lint). One scratch test each, the 1v1 golden byte-identical, and the parity lint clean. Lines in files that are not World's: `state.gd` (`World.present`, `World.peopleLeft`, `Building.place`, `Building.plan`), `hash.gd` (the conditional appends), `mood.gd:403` and `launch.gd:254` (one token each), `tools/schemas/map.json` and `tools/fixtures/cases.json` (Tools': the schema's rule and cases), `data/fight/tier5.json` (Simulation's file).
3. **After the N-body patch or before it:** both edit `collateral.gd`. The N-body patch is parked and applies on main today; this window would be cut on it or it on this: the EP orders them.

## 7. For Legal (c08, c09)

Nothing here scores or rewards a death: the ledger's tallies (Simulation's) and the wear list's people lost are state, and the owner on every path exists so that a death is attributed, not so that it is rewarded. The planet's ceiling (at most 40% of the people dead before the boss) is a limit on the number the world will allow, not a target.

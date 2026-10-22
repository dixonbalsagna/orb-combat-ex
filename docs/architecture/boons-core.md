# The run's rare boons in the core

Owner: Simulation and Engine. 2026-10-18. The core's build of Game Design's three rare boons (`docs/design/rulings-2026-10-18b.md` section 4, a draft for Orb to react to in play): a base form that is a transformation. **Applied in 83405d99 (2026-10-23), with Tools' schema.** Run-only: a match's setup names them, and no versus match does, so with none named every match, replay and checkpoint is the same to the bit.

## 1. What it is

- **The setup names them:** `"boons": {slot: id}`, for example `{"0": "born_ready"}`. The run's host builds it from the run state (`run-core.md` section 3), the way it builds `stage`.
- **The numbers:** `data/fight/boons.json`. It joins a replay's data hash only for a setup that names a boon.
- **The module:** `sim/core/boons.gd` (`SimBoons`). It reads its file itself, outside `FighterData`, so the roster's hash stays as it is.
- **Offering them is the run's.** When a boon is offered (from fight 3, one in three offers; Second skin only after Born ready; the borrowed form as the temptation between fights 2 and 3) is the run's draw from its seed, not the match's.

## 2. The rules as built

| Boon (working names) | As built |
| :--- | :--- |
| **Born ready** (`born_ready`, `steps` 1) | Every fight starts one form above base: step I for a fighter with steps of his own (forms on), the tier-2 form for anyone else. Power starts at that form's floor. He is never in base, so that step is never coiled |
| **Second skin** (`second_skin`, `steps` 2) | Two forms above base: II (tier 2) with forms on, tier 3 for anyone else. An opponent with a Trial fill takes `opponentForm` at once, since he starts below |
| **The borrowed form** (`borrowed`, `firstBreakSooner` 0.25) | Every fight starts at his highest form (V, tier 4, with forms on; tier 4 for anyone else today). His wear comes 1 / (1 - 0.25) as fast until his first region breaks (stage 3), so it breaks a quarter sooner. After the first break his wear is as anyone's |
| **Every boon** | The world's top tier (`S.world.maxTier`) is the boon's from the first second, so collateral's budget is the higher tier's |

**My readings, for Game Design to confirm:**
- **"A quarter sooner"** is read as the first break coming at three quarters of the damage, so his wear runs × 4/3 until then. It is one factor on `SimWounds.addWear`, read only for a fighter with a boon.
- **"The Protagonist's step I or II"** is read with forms on. With forms off he has the shared ladder like anyone, so he starts at tier 2 or tier 3.
- **A form passed at the start picks a branch** the way a release does, with both fills empty, so Second skin starts him on the first tie's branch (Trial today).
- **The ceiling** (`run-mode.md` section 1.1) is the run's and does not exist yet. Until it does, the ladder's top caps a boon: the borrowed form gives tier 4. When the ceiling arrives, the boon's form is the lower of the two.
- **The opponent's Trial fill** gets `opponentForm` (15), the fill for an opponent's form taken while his tier is no higher. He did not hold a form, so it is not `opponentFormHeld`.

## 3. In the core

| Where | What |
| :--- | :--- |
| `boons.gd` (new) | `SimBoons`: the file, `apply` at a new match, `wearMul` for the borrowed form's price |
| `state.gd` | `Fighter.boon` (the id, `""` for none) |
| `sim.gd` | `newMatch` applies the setup's boons after the forms' setup |
| `hash.gd` | The boon, only when it is not `""` |
| `replay.gd` | `boons.json` joins the data hash only for a setup with `boons` |
| `wounds.gd` | `addWear` multiplies by `wearMul` only for a fighter with a boon |
| `tools/parity.gd` | One check (section 4) |

## 4. The proof

**The check, "the run's rare boons":**
- A match that names none has none, and a replay that names one carries the boons' data.
- Without forms, each boon starts its fighter at tier 2, 3 and 4 at power 35, 65 and 100, with the world's top tier raised and the other fighter at tier 1.
- With forms, at step I, II and V, at tiers 1, 2 and 4, at power 20, 35 and 100, with the first tie's branch past II.
- Second skin on the rival fills the Protagonist's Trial at once.
- The borrowed form's wear is the ordinary wear × 4/3 (the rival's is ordinary), and is ordinary again once a region breaks.
- A boon match of 1,200 ticks carries the boons' data and plays back.

**Results:** every check passed on the applied commit (83405d99).

## 5. Not in this window

| What | Whose |
| :--- | :--- |
| Offering them (the run's draw, rarity shown, never rolled) and the run's ceiling | The run's window (Simulation, with Encounter) |
| Their names and their lines | Narrative |
| The boon's card and the borrowed form's warning | UI |
| The schema for `data/fight/boons.json` | Tools (on main since 83405d99) |
| The AI with a boon (whether it plays a started form differently) | Encounter |

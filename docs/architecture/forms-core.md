# Forms in the core: the Protagonist's five steps and the slingshot

Owner: Simulation and Engine. 2026-10-17 (the coil re-ruled the same day, edd7dcd8). The core's build of Game Design's `docs/design/hero-forms.md` sections 4 and 4b, with the hold and release signals Narrative asked for (`docs/narrative/waiting-game-lines.md`). **Applied in 8f157894 (2026-10-17), and the branches (section 7) in 421134e0.** Behind one data switch that is off: with it off, every match, replay and checkpoint is the same to the bit.

**The working rule of 2026-10-18 (section 8) was applied in c09c3bef (2026-10-20).** It replaces the banking release and the release's extras in section 2: one step a transformation, and the coil makes that one form stronger.

## 1. What it is

- **One switch:** `data/fight/forms.json` `enabled` (false). `SimCore.newMatch` copies it into `S.formsOn`, unless the match's setup has its own `"forms"` (probes and tests).
- **A fighter's own steps:** `data/fighters/<id>/forms.json`. Only the Protagonist has one. With forms on, a fighter without a file plays the shared ladder exactly as today, and only his hold and release are told.
- **The module:** `sim/core/forms.gd` (`SimForms`). It reads both files itself, outside `FighterData`, so the roster's hash and every fighter's hash stay as they are.

## 2. The rules as built (Game Design's numbers, all in the Protagonist's file)

| Rule | As built |
| :--- | :--- |
| **Five steps** at power 20, 35, 50, 65 and 100 | `steps`: each has its power, its tier for the world (1, 2, 2, 3, 4), its kind (live at I and III, pausing at II, IV and V) and an id. His tier for the world steps at 35, 65 and 100, as everyone's does, and reads everywhere the tier is read today (collateral, structure reach, the building ladder, the acts) |
| **A step is never forced** | Each step makes him ready (`formReady`, the `transform_ready` event as today), and he takes it by the transform, through the director's path as today |
| **Banking** | Every step his power reaches while he waits is banked (`form.ready`). The release takes them all at once: from base to III, or to the top, in one go. The tier for the world rises once to the last step's, with one power-up (`tier_up`) |
| **Each step's gains**, modest and all-round | In place of the shared ladder's gains a tier: speed and damage +5%, launch force +8%, ki regen +5%, a guarded hit's damage −5%, a launch's recovery 5% sooner, each per step taken |
| **The coil** (re-ruled by Game Design, 2026-10-17) | **Starts at the first break in the fight after a step came ready**: the first moment it could have been taken and wasn't (`SimForms.canTake`, the director's own rule for taking a transform: between exchanges, before a KO, with no approach running, free or charging). A step that comes ready mid-brawl coils nothing until then. It fills at 0.5 a second of fight time and 0.005 a point of damage traded (dealt or taken, after patience), both twice as fast while the opponent's tier is above his. At most 100, it never decays, and the release spends it |
| **Patience** | While he holds banked steps and the opponent's tier is above his, he takes 4% less damage a tier between them, at most 12% |
| **The release's extras**, at a coil of c, by c / 100 | A burst like a ground power-up (its damage and its crater's energy, near the ground) and a push that reaches and pushes up to twice as far; for 10 s (600 ticks), speed and damage +15%; armour on his next 3 blows (rounded); and for the rest of the match his step gains × (1 + c / 200), at most × 1.5 |
| **A live step** never pauses | A release of live steps only (I alone, or III alone) is the pause's live version; any pausing step in it lets the pause choose, as today |
| **The top** | No step past the last; a banked step is never lost |

**My readings, confirmed by Game Design (edd7dcd8):**
- **A step taken at once** carries a sliver of coil (a tick's worth). The extras start at a coil of 1 (`release.minCoil`), so an ordinary step adds no burst.
- **Several releases:** the lasting gain keeps the largest so far. It does not stack.
- **The armour scales** with the coil (3 blows at a full coil, rounded).
- **"Chip through a guard −5%"** is read as his own guard: 5% less of a guarded hit reaches him.
- **"Damage traded"** is every damage that reaches him, and every damage he deals, after patience.
- **The release's burst** is a ground power-up's at c / 100 of its strength, on top of the power-up any tier rise brings.

## 3. The signals (the waiting game)

| Event | Fields | When |
| :--- | :--- | :--- |
| `form_hold` | actor, n, dur, amount | A ready form held `hold.signalTicks` (60) live ticks; again for each step banked since. `n` steps ready, `dur` seconds held, `amount` the coil |
| `form_release` | actor, n, amount, dur, k, tier | At the take: `n` steps, the coil spent, the seconds held, the step reached (0 for a fighter without steps) and the tier for the world it brings |
| `form_step` | actor, k, kind, tier, amount | At the break: the step he now stands at, its kind (the marks at I and III have no `tier_up`), the tier, the coil spent |

- They are sent only while forms are on, for every fighter. Narrative's ten-second hold is the presentation's clock on `form_hold`.
- **With forms off,** a hold is already visible: it runs from `transform_ready` to `transform`, both events of today.

## 4. In the core

| Where | What |
| :--- | :--- |
| `state.gd` | `S.formsOn`; `FormState` (the step, the banked count, the coil, the hold's ticks, the release in flight, the surge, the armour, the lasting gain); `Fighter.form` and `Fighter.fd` |
| `sim.gd` | `newMatch` sets the switch and each fighter's form state |
| `hash.gd` | `FormState` is hashed only while forms are on. The three events' `FX_FIELDS` |
| `fighter.gd` | Readiness from his steps in place of the thresholds; the hold's tick; the transform and the break through `SimForms.take` and `rise`; flight speed, ki regen and the recovery in water read his gains |
| `damage.gd` | The hit's damage factor reads his gains; `hurt` applies patience and his guard's gain, and counts the coil |
| `pause.gd` | A release of live steps is the live version |
| `replay.gd` | The two files join a replay's data hash only for a match with forms on |
| `fx.gd`, `view/fx.gd` | The three events; the reference consumer passes them |
| `tools/parity.gd` | One check (section 5) |

**Every gain returns today's expression** for a fighter without steps, in the same order of operations, so with forms off no number moves by a bit.

## 5. The proof

**The check, "forms: five steps and the slingshot".**
- Off: a match has no form state, and a replay carries no forms data. With them on, the forms data joins the replay's data hash.
- The five steps come ready at 20, 35, 50, 65 and 100 and stand at tiers 1, 1, 2, 2, 3 and 4. Five steps send 3 `tier_up`, 5 `form_step` and 5 `form_release`.
- The gains at five steps; and today's gains for a fighter without steps.
- Four steps banked at 65 and a fifth at 100. The coil, exactly as its rule adds it: a second at a time, twice two tiers behind, and from 20 damage traded. A step that comes ready inside an exchange coils nothing, and its coil starts at the break. Patience at 8% two tiers behind. The hold told at 4 and 5.
- One release takes all five steps: tier 1 to 4 with one `tier_up`. The surge, the armour and the lasting gain by the coil's share. The surge ends after 600 ticks. Armour is spent. The coil stops at its max.
- A release of step I alone is live, and one with II in it is not.
- The rival's hold and one-step take are told.
- A forms match of 3,000 ticks replays, and carries the forms data.

**Results:** every check passed on the applied commit (8f157894).

## 6. Not in this window

| What | Whose |
| :--- | :--- |
| Witness and Trial (section 7) | Applied in 421134e0, with World's two lines |
| The director's four lines: the transform event's tier, the speed estimate and the launch planner's two tier factors | Encounter granted them, applied with 8f157894 |
| The AI's holds (up to 10 s at medium while its rival is above it; up to 30 s at hard while its coil is under 60) | Encounter |
| Spending the armour on a blow that lands (`SimForms.armoured`, `useArmour`) | Encounter |
| A launch's recovery: the core's water path reads his gain. The ground-contact journey's and the planner's prediction (`predictFlight` reads no fighter) do not | World, Encounter |
| The schemas for the two files | Tools |
| The HUD's fills and the form names; the looks; the release's showpiece | UI, Narrative, Art, Animation, VFX |

## 7. The branches: Witness and Trial (applied in 421134e0)

The second window: Game Design's section 3 and section 4's pick. Behind the same switch, so with forms off nothing moves.

| Rule (Game Design's) | As built |
| :--- | :--- |
| **Witness fills** by each person his opponent kills within 3,000 units of him, shortest arc: +1 times 425 / pop0. A guard's kills are his principal's. Each person he kills takes 2 off it | `SimForms.casualty`, from World's `WorldCollateral.kill` (one line: where they died, and who caused it). Never below 0 |
| **His anguish** takes only his own kills; the opponent's go to Witness | `SimForms.anguishOther` in World's `_feed` (one token): 0 for a fighter with branches, today's number for anyone else |
| **Trial fills** when the opponent takes a form while his tier is no higher (+15; +25 if his own form was ready and he held it); +1 a second of fight time while the opponent's tier is above his; +2 for each blow of a medium or more he lands while it is; +5 each time the opponent commits fully; every coil point | `SimForms.events` reads the tick's events after the mood: `tier_up`, `damage` (landed, medium or heavy), `finisher_start`, `beam_outcome` CLASH, `brink_enter`. The deficit seconds and the coil are counted in `readyTick` and `traded` |
| **Neither decays.** Taking a form empties its branch's fill; the other keeps its own | As ruled |
| **The pick** at II and IV: the higher fill; a tie to the branch he is on; the first tie to Trial | `_pick` at the break, for a release that passes a branch step |
| **A Witness form:** damage +4%, launch force +8%, care +0.5 | On the gains (`damageMul`, `launchMul`); his `care` (which the director's launch planner reads) |
| **A Trial form:** speed +4%; the perfect-block window 1 tick wider at II and 2 at IV; perfect follow-ups worth 1 more | Speed on `speedMul`. The window and the follow-up are the director's: `SimForms.blockWiden` and `followBonus` return them, and Encounter reads them |
| **A cross** at IV is a story | `form_step` carries the branch (`text`) and `source` cross |

**My readings, confirmed by Game Design (fda9b426).** Under the working rule (section 8) a release is one step, so the first is moot:
- **A release picks once.** It is one transformation, so a slingshot from base to IV takes one branch for both II and IV, and empties one fill.
- **The extras belong to the form he is in, and don't stack** between II and IV: a Witness form gives +4% damage at II, at III and at IV. The block window is the one that grows: 1 tick at II's level, 2 at IV's.
- **V picks nothing and empties nothing.** It wears the branch he came by, and keeps that branch's extras.
- **"Commits fully"** is read as three events: the opponent's finisher, a beam clash he is in, and the opponent entering the brink. "A clash at full ki" is read as any beam clash.
- **"His tier is no higher"** compares his tier with the opponent's before the opponent's rise.
- **The fills have no cap.**

**In play** (a scratch probe, 12 AI matches of 14,400 ticks, the Protagonist against the rival, at `perPerson` 1):
- **Trial is taken in all 12. Witness is taken in none, and nothing crosses.**
- When the picks came, Witness's fill was 0 to 6, and Trial's 4 to 16.
- Each person the rival kills near the hero is worth 0.24 at an arena of 1,800 people, and the hero's AI leads the fight away from people. Trial meanwhile takes 5 for every commitment and 15 or 25 for every form the rival takes.
- **Game Design's row** (each branch taken in at least 25% of matches) **fails by its numbers, not by the build.** It needs Witness's `perPerson` about four times higher, or Trial's `commit` and `opponentForm` lower: theirs to rule. Each match played the same twice.
- **Game Design ruled `perPerson` 4** (fda9b426). It is in the working rule's park (section 8).

## 8. The working rule: the next single form is stronger (applied in c09c3bef)

Game Design's rulings of 2026-10-18 (`rulings-2026-10-18b.md` item 2), the working rule until Narrative's lore paper. Behind the same switch, so with forms off nothing moves.

| Rule (Game Design's) | As built |
| :--- | :--- |
| **One step a transformation:** a release takes only the next step, and the steps still ready stay ready | `SimForms.take` takes one step (`form_release` has `n` 1), and `form.ready` keeps the rest. He stays `formReady` while any is ready. A release is live when the next step is live |
| **The coil makes that one form stronger:** its step gains × (1 + c/100), at most × 2, for as long as he is in it | `FormState.formMul`, set at the break from the coil spent: 1 + c × `perPoint` (0.01), at most `maxMul` (2), from a coil of `minCoil` (1) up; 1 below it. Every step gain reads it (speed, damage, launch force, ki regen, the guarded hit, the recovery). His next step sets it again, from that step's coil |
| **The coil, patience and Trial's road stay as ruled** | Unchanged |
| **Withdrawn:** the jump of several steps, the burst, the 10 s surge and its armour, the lasting gain | Removed from the module, the state and the data. `FormState` loses `surgeT`, `surgeMul`, `armour` and `lasting`. `SimForms.armoured` and `useArmour` are gone; no director code called them |
| **Witness `perPerson` 4** | In the Protagonist's file |

**My readings, for Game Design to confirm:**
- **"For as long as he is in it"** ends at his next step, which sets its own factor from its own coil. A step taken at once carries a sliver of coil (under `minCoil`), so it is plain.
- **The factor multiplies the step gains** (`gain × steps × formMul`), as the lasting gain did. It does not touch a branch's extras.
- **A release spends the whole coil,** even with more steps ready behind it. Those steps start a new coil at the next break, as any ready step does.

**In the core:** `forms.gd`, `state.gd`, the Protagonist's `forms.json`, the two forms checks in `tools/parity.gd`, and `form_release`'s row in `fx-events.md`. Tools' schema for the release block, the self-test's fixture hero and its release cases came in the same commit. Three comments in `damage.gd` and `fighter.gd` that named the surge are corrected.

**The checks:** the release takes step I alone with four still ready, sends a `form_release` of 1 with the coil and no `tier_up`, and sets the form's factor from the coil; the next step taken at once is plain; a full coil's form is × 2 and no more. With I and II ready the release is live (I alone), and after it II is not. The branches' picks happen one step at a time: a release from base at 65 takes I and picks nothing, and the next, at II, picks.

**Results:** every check passed on the applied commit (c09c3bef).

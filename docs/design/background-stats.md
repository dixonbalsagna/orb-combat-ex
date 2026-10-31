# Background stats: anguish and menace as more than meters to fill

Owner: Game Design. 2026-10-31. **A proposal for Orb, paper only. Nothing is built or measured.** Orb: "maybe the stats like "anguish" and "menace" should just track as background stats that the fighters use to determine their voice lines, instead of meters for a fighter to fill. maybe each fighter has a different mechanic tied to each of the background stats". Legal's limits are RL-217 (`docs/legal/review-log.md`).

**My recommendation: yes.** Hide anguish and menace. Casualties feed anguish only, as voice and a cost to the hero. Move menace's inputs off casualties, onto structures, wear and fighter states. Give each fighter a distinct mechanic on a stat that isn't fed by deaths. It's a better fit for pillar 5, a simpler screen, and it ends the places the game still pays a fighter for civilian deaths.

## 1. What they do today

They exist in the code only on the two built fighters. The roster's own meters (Respect, Pride, Wrath, Hunger) are mostly design so far.

| | Anguish (Grist, the hero) | Menace (Loupe, the rival, for now) |
| :--- | :--- | :--- |
| **Filled by** | Casualties: +0.9 his own, +0.5 anyone else's | Casualties he caused, +0.9; people his blows forced to flee, +0.45 |
| **Drains** | 0.6 a second | 0.4 a second after 4 s unfed |
| **Power** | Ki regen down, at most 1 a second: a cost | **Ki regen up, at most 1 a second; damage up, at most +5%; beam struggle power up, at most +8.** Legal: "a mechanical benefit from the toll", grandfathered and flagged, not a take-down trigger |
| **HUD** | A bar on the plate | A bar on the plate |
| **AI** | Nothing reads its value. Having the meter marks him the hero | The same, as the villain |
| **Voice** | **Nothing reads it today** | **Nothing reads it today** |
| **Pillar 5** | "The hero is pressured by collateral damage (anguish)" | "The villain feeds on it (menace)" |

Grist's comeback (up to +50% damage near the brink) reads his wounds, not his anguish, so it's fine as it stands.

**Three more readers of the toll that I found in the code, for Legal and the EP. They aren't in RL-217's list, and the QA test below will catch them:**

| Where | What it does | Why it matters |
| :--- | :--- | :--- |
| `sim/world/collateral.gd` `_feed` | **A casualty also raises the cause's `power`** (`cause.power += n × 0.09 × norm`), if he has menace | Power leads to tiers, so deaths bring a villain's transformation closer. It's the largest of these |
| `sim/core/forms.gd` `casualty` | **`h.form.witness`:** deaths near a fighter, caused by his rival, fill his Witness; his own lower it | When Witness leads, his next form takes the "witness" branch, with extra damage and launch power (`forms.gd`). RL-217 says no power and no transformation from civilian deaths. `data/fight/forms.json` is off today, so it's a problem to fix before forms go on |
| `sim/core/mood.gd` (`casGiven`) | Casualties raise `S.mood`, which sets `S.mood.aggression`, the director's scale | So the toll changes how hard the AI fights, for both fighters |

RL-214 also left the old people terms in `chooseLaunch`, `bruntScore` and `DirLocation`.

## 2. What moving them means

**Hidden, with nothing to fill.** No bar, no number and no player goal. **What stops working:**

| Goes | Consequence |
| :--- | :--- |
| The two HUD bars | `minimal-hud.md` gets simpler, and `hud-spec.md` loses a row. `economy.md` §4's "every ego meter is visible" no longer covers these two |
| Menace's regen, damage and struggle power, and `power` from casualties | **The balance moves.** QA has to re-read both win rates and the match-length rows first. Menace changing has swung them hard before (`balance-targets.md`) |
| Being the label for hero and villain | `location.gd` and the UI bridge read a role from the roster's data instead. A small change |

**What's lost.** A visible, felt pressure. Pillar 5 would rest on voice, posture and the fighter's own mechanic, and none of those is built. **The voice lines Orb describes are new work** for Narrative.

**Legal's limits on voice (RL-217 A).** A toll-fed stat may drive voice if it's hidden, and one-way: nothing a line selects feeds back into the sim. Lines treat harm as a fact or a cost, and never celebrate, relish or count it. Villain lines are about his character and quote no count. So my earlier flag on menace choosing lines mostly goes away once menace isn't toll-fed.

## 3. The stats, and what each reads

**Names for the lint.** "Built" means it's in the code today. The people-terms lint (`crowd`, `popAlive`, `popNear`, `popHist`, `pop_mult`, the toll) applies to every stat that drives a mechanic. The only exception is the hero's cost. Field names for stats not yet built are proposals for the owner to confirm.

| Stat | Inputs, by name | Toll-fed? | What it may do |
| :--- | :--- | :--- | :--- |
| **Anguish** | Built: `n` and `cause` in `WorldCollateral._feed`; `f.md.anguishCasSelf`; `SimForms.anguishOther`; `f.md.anguishDecay` | **Yes** | **Voice, and a cost or restraint on the hero only. Never power** |
| **Menace, as proposed** | Structures downed by his blows, by mass: `b.w`, `b.h`, `b.d`, `b.floors` from `building_fall`, the same occupied or not. Wear he's dealt: `SimWounds.addWear`. Fighter states: `f.tier`, `f.power`. **Comes out:** `collateral.gd` lines 252 and 270 | No | A mechanic is allowed. Legal's log also lists evacuees as a non-lethal input, but they're counted from people, so I leave them out |
| **Mood** | Built: `SimFx` events through `SimMood`, plus `S.world.casualties` through `casGiven` | **Partly** | Voice, until the casualty line leaves whatever drives a mechanic |
| **Respect** | Events: `tier_up`, `finisher_start`, `beam_outcome` CLASH, `brink_enter` (`forms.gd` `events`) | No | Grist's form track |
| **Pride** | Wins: `parry`, stage breaks, region stages; `building_fall` by mass; taunts (`combat_barks.json`) | No | Loupe's forms and crash |
| **Wrath** | Her own wear (`SimWounds`), her court falling, taunts | No | Orza's revision chain |
| **Hunger** | Components by mass, from a ruin or a lab (§14 of `docs/world/ring-any-angle/game-design.md`); taunts | No, by RL-216 | Bolus's meter: **the one still filled on purpose,** because gathering is his play |

**Every fighter tracks all of them,** and each cares about them differently, which is Orb's "a different mechanic tied to each". Respect, Pride, Wrath and Hunger drive forms, so they stay real, and I'd show them on the body as forms do, with only what a player must plan around at the edge.

## 4. Fighter against stat: examples, as options

First ideas for Orb, under RL-217. "Voice" means it changes only what he says and how he carries himself.

| | Anguish (cost only) | Menace (not toll-fed) | Respect | Pride | Wrath | Hunger |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Grist** | **A shakier guard or a refused finisher at high anguish,** or a lean toward emptier ground. Choose one: today's small ki cost is the mildest | Voice: he won't be this | **His form track, as designed** | Voice | **Comeback near the brink,** from his wounds, as today | Voice |
| **Loupe** | Voice: he doesn't care, and it shows | **A small edge from what he's torn down,** by mass, in place of today's menace | **A rival who commits earns a clean duel:** he drops his barrage and closes by hand | **His forms and the crash, as designed** | Voice | Voice |
| **Empress Orza** | Voice: she's filing it | **The sky dims as it rises:** a look only | Voice: she doesn't give it | Voice | **Her revision chain, as designed** | Voice |
| **Bolus** | Voice: comic, and he misreads it | Voice, with no line about people | Voice | Voice | Option: a thrown scrap heap when he's been denied a gather | **His meter, and every step of his growth** |

**The rule behind the table (c08, as sharpened by RL-217): no mechanical benefit to any fighter from the toll or civilian harm. A cost or voice is allowed.** Asymmetry is fine: a hero who pays for harm, and a villain who doesn't gain from it.

## 5. The swing score and pillar 5

**The swing score: RL-215's terms stay, and they get easier.** Timing may read `f.anguish`, `f.menace` and `S.mood`, never raising the total, and direction may read `f.anguish` only. **RL-217 says a toll-fed stat is voice only, except the hero's cost,** so read together, these two need one line from Legal. **My ruling until then: the terms stay behind their switch.** Once menace is re-fed, it isn't toll-fed at all, and timing can read it freely. Anguish leaning a swing toward emptier ground is a restraint RL-217 names. Mood waits until its casualty line is out. **Hidden means hidden from the player, not from the debug feed,** which still prints them.

**Pillar 5 needs new words, and that's Orb's call.** "Feeds on it" would no longer be true. A proposal:

> **5. Characters are personalities.** Each fighter relates to the world in their own way, and it shows in what they say, how they carry themselves and how they fight. The hero pays for what the fight costs. The villains don't care, or enjoy the ruin.

## 6. If Orb says yes

1. **Legal:** the three extra readers in §1, and the line between RL-215 and RL-217.
2. **QA's test (RL-217):** with civilians removed, no fighter's mechanical output changes beyond the hero's cost. **It will fail until menace, `power`, Witness, mood's aggression and RL-214's old terms have all changed,** so it's the gate for this work rather than a first read. An arm with menace's power off comes first, for the balance.
3. **Simulation and World:** menace's new inputs and the role in the roster's data, behind a switch, with the golden holding when it's off. **It changes fights, so it goes through the usual gates.** The demo stays as it is (Legal: not a take-down trigger).
4. **UI:** the bars off.
5. **Narrative:** lines reading the stats, under RL-217 A.
6. **Combat and Game Design:** the mechanics Orb picks from §4.

**For Orb, one question:** hide anguish and menace, with deaths only ever costing the hero and never strengthening anyone, and each fighter's own mechanic on stats that aren't fed by deaths? Or would you rather keep a visible pressure on the hero? (Legal allows a visible menace bar once it isn't toll-fed, if you'd want one.)

# Co-op brawler mode, part 2: can the director carry a multi-fighter fight?

Research & Prototyping, 2026-10-11. This follows `co-op-brawler.md` and Orb's eight answers (docs/ep/vision.md, last section). It is a written study only: nothing was built or measured, and no code or data was changed. The code was read at HEAD 9e1ee6cf, while Encounter's C2 chain was landing. Everything marked *(estimate)* is a judgement from reading.

## Answer in short

**Yes, the director can integrate a second attacker without a break, and the cheapest sound way is "pair and satellite".**

- The brawl stays a pair with a centre, exactly as built.
- A player who attacks an opponent who is already engaged becomes a *satellite*. He is never locked. He keeps his own strike line, and every press in reach is a real blow woven into the same beat schedule.
- The pair re-forms around him at natural seams, or when the opponent turns on him with a visible tell.

A true three-body brawl is a redesign of 2,658 lines that are still being tuned. A fast baton by itself breaks strings, and so the feel.

**Free roam can be staged on one rule: one full choreographed fight at a time, plus any number of lighter scuffles with henchmen.** Two full fights at once need a deeper change, because hit-stop and cinematic pauses freeze the whole sim today.

## A. Joining an engaged fight without a break

What the code does today (`sim/director/brawl.gd`):
- **State.** Each fighter carries about 86 integer slots of brawl state (his strike line, taps, wind-up, run, the AI's memory). The pair's shared state sits in the attacker's slots "for both": the trade, the double hit, the centre's velocity and carry, the walk-out count.
- **Blows.** Every blow is a `strike` beat tagged with role "A" or "D". `contact()` resolves the attacker and the defender from that tag.
- **The tick.** `tick()` loops over the two members and ends the brawl if either is not `locked`. Both members are locked: the director moves the pair, not their own flight.
- **The run.** A fighter's run is one number "against the rival".
- **A precedent.** A zip's way in already runs next to the exchange "with no exchange", while the rival stays free. A body acting beside an exchange is not new.

| | (i) True three-body brawl | (ii) Pair and satellite | (iii) Fast baton alone |
| :--- | :--- | :--- | :--- |
| Centre and sticks | Three sticks move one centre; they will often disagree | The pair's two sticks move the centre as today; the satellite's stick moves only him | As today; the outsider flies free |
| Flurries | Two flurries land on one body at once: his reel and the run rules need a rule for three | Both players flurry at full timing. The satellite's blows add **half-steps to the pair partner's run** (a shared stagger gauge), and only the pair partner's blow can be the close | Each pass ends one brawl and begins another, so strings, runs and tap gaps reset. Two players cancel each other's flurries |
| Wind-ups and charges | Whose wind-up does the opponent answer, and against whom does he give ground? | Satellite may wind a medium or a heavy. The opponent's armour applies as built. A satellite's heavy adds pressure but cannot stagger by itself | A pass cancels the waiting player's wind-up, or forces a pass to wait for it |
| The launcher's opening | Needs an owner rule | **The opening belongs to the team**: one sets up the stagger, either may press B and launch. The best co-op beat, for one small change | Lost at every pass unless carried over |
| Giving ground | Undefined with two attackers on two sides | Pair only, unchanged. The satellite is free and steps back on his own stick | Pair only |
| Double hits, trades | Three pairings of each | Pair only, unchanged | Impossible across a pass |
| Perfect blocks, ripostes | The opponent's guard needs a facing | Pair only. Against a satellite his held guard takes the blow by the blocked rule; no perfect block, no riposte | Pair only |
| Zips | Unclear | A satellite's zip: the way in as today, one satellite blow, the way out | As today |
| One press is one attack | Yes | Yes, for both | **No** for the outsider, unless every press is a pass |
| In control except in knock-backs | The third body is locked to a centre he only part-steers | Yes: the satellite is never locked. The opponent's burst can knock him back | Yes |
| Cost *(estimate)* | Redesign: every pairwise rule gains "which rival"; 8 to 12 slices and a full re-tune | **4 to 6 slices**: a new module beside the brawl, three hooks into it | 2 to 3 slices |
| Risk to versus | High: the same code paths change | Low: with no teammate the module never runs | Low |

**How the opponent stays dangerous in (ii) without being stun-locked:**
- **Armour as built.** During his heavy, a light does half and changes nothing. Satellite blows follow the same table.
- **The close stays a pair event,** and the existing guard against being closed on again (`closeGuardTicks`) still applies. Two players reach a close sooner, but not twice as often.
- **The burst** (a held X) hits everything in reach, the satellite included. That is the satellite's one loss of control, and it is a knock-back, so the control rule holds.
- **The turn.** With a visible tell, the opponent makes the satellite his new pair partner. The old partner becomes the satellite. This is the baton of (iii), used only at the opponent's choice or at a natural seam: the pair partner is launched, knocked back, walks out, or goes idle.
- **Boss-grade numbers:** more health, and more blows needed for a close.

This matches Orb's sentence directly. If player 2 is engaged and player 1 starts attacking the same opponent, player 1 is a satellite from his first press. Nothing ends, nothing restarts, and the pair re-forms later without a cut.

**Recommended: (ii), with (iii)'s re-forming as its seam rule.**

**The smallest scratch experiment** (one slice *(estimate)*, in a scratch copy, never in the shared tree): a third fighter whose presses are a script (lights at flurry gaps, then a heavy) acts as a satellite on the AI opponent, who is in a brawl with fighter 1. Run QA's scripts over 100 matches and read:
1. the opponent's share of time staggered, against the two-fighter baseline;
2. time to the first close and to the KO, against the baseline;
3. the share of the satellite's presses in reach that became a blow (it must be all of them);
4. whether the pair partner's strings were ever dropped by a satellite blow (never);
5. the two-fighter goldens, with the module present (bit-identical).

Then one session for Orb with two pads. **It is killed if** the opponent spends more time staggered than a band Game Design sets beforehand, or if the goldens move.

## B. Free roam with many enemies

- **How many engagements.** A full engagement is one exchange: an opponent, his pair partner and any satellites. Today there is exactly one (`S.dirS.ex`, read in 91 places across 21 files in the sim, renderer, HUD and audio).
- **Why two at once is deep.** Hit-stop (`S.dirS.stop`) and the pausing set pieces (`S.pause`) freeze the *whole* sim, and no input is consumed while they run. With two fights a planet apart, player 1's heavy would freeze player 2's hands. Two full engagements therefore need freezes that are local to an engagement, as well as an exchange per engagement. That is the largest structural cost in the mode *(estimate: 4 to 6 slices)*. Versus 2v2 needs the same work.
- **The staged rule.** One full engagement at a time, plus scuffles.
  - A *scuffle* is a fight with lower-grade henchmen under a lighter rule (section C). It uses no exchange and no sim-wide freeze, so any number can run beside the full fight.
  - Fighter-grade enemies take turns: one commits, the others stand off. Orb's own concept for one boss opens this way.
  - The one case this excludes is both players each in a separate full brawl at the same moment.
- **Target choice and lock-on.** Decided at the press:
  1. the opponent of the player's current engagement, if he has one;
  2. otherwise the enemy nearest his aim;
  3. otherwise the nearest enemy.

  Aiming the stick at another enemy while pressing switches target. "Never out of range" holds as today: the press becomes a lunge, a zip or a shot at the target.
- **What unengaged enemies do.** They hold attack turns: at most one or two may attack a player at once. The rest circle at a stand-off distance. Marksmen fire at a low rate. Some go for a settlement, which gives two players a real choice: gang up, or split to protect.
- **Camera.**
  - *Apart:* a pane per player, as the split works today. Each pane should frame its player *and his target*, which is the reference pair shot at pane size (new, medium).
  - *On the same enemy:* one merged shot of the pair. The satellite is within reach by definition, so he is in frame.
  - A chip at the pane's edge points to the partner.
  - Until freezes are local, a finisher's pause would stop both panes. It must either be allowed to (simple) or be shortened in co-op (a question for Orb).

## C. Henchmen in grades from procedural parts

What exists to build on:
- **The body.** Animation's rig R1 is 27 bones with a *faceted, rigid-skinned body built from a palette* (`render/anim/anim_rig.gd`). Parts already hang off single bones, which is what a part grammar needs.
- **Shapes and poses.** Each roster fighter has a shape language (`data/anim/shapes.json`) and a pose profile that turns another fighter's strikes into his own (`data/anim/fighters.json`).
- **Movesets.** Combat's moveset generator already assembles moves from parts, offline, with a seed and a review sheet (`docs/combat/moveset-generator.md`).

What a part-built henchman needs:
- **A part grammar.** Regions (head, torso, pelvis, upper and lower arm, hand, upper and lower leg, foot), part sets per faction, a palette, and a seed.
- **Constraints.** Bone lengths stay inside bands, so the shared poses, the reach table and the contact solve still land. The joint limits apply (`joints.json`). The existing silhouette lint and Legal's screen rule run on generated bodies, on a review sheet.
- **One shared rig (R1).** Every existing pose and key set then works, and a henchman's moves are drawn from pieces that are already posed. No new poses for henchmen.
- **Sim blindness.** The sim reads only a grade and a size class, never the parts. The body seed is cosmetic, so variety costs no determinism.

| Grade | Sim body | Rule in a fight | Moves | Wounds |
| :--- | :--- | :--- | :--- | :--- |
| 0 Fodder | A light body: position, health, a few timers | Scuffle only: one or two blows drop it | One attack | None |
| 1 Grunt (bruiser, marksman, speedster) | Light body with a type | Scuffle: guards or dodges by type, staggers, is launched | Two or three, by type | None; visible part damage only |
| 2 Elite | The full fighter | **Full brawl**, as pair partner or target of a satellite | Generated: one stance, lights and a medium | On, reduced |
| 3 Lieutenant | The full fighter | Full brawl, set pieces | Generated: one or two stances, three buttons | On |
| 4 Boss | A roster fighter, hand-made | Everything | Authored | On |

- **The scuffle rule** (grades 0 and 1):
  - A press targets the nearest henchman in reach.
  - The blow uses the fighter's own strike timing and piece.
  - The henchman's reaction is canned by grade: flinch, stagger, knock-back or launch.
  - No exchange, and no sim-wide hit-stop.
- **Keeping "power has weight".** A launched henchman is a real body. He flies by the launch planner, ploughs into buildings by the brunt rules and craters the ground. A heavy through a line of grunts is collateral. Henchmen are fuel for the game's existing weight, not targets that pop.
- **Render cost: not measured.** Fodder need a cheaper path (fewer bones or instancing, no outline pass, a simple ragdoll). Animation's `solve_bench` and the A0 spike project can give the number. That should be the first measurement of stage 2.

## D. A CPU partner for solo play

Today's AI plays one opponent against `opp()`: 388 lines in `ai.gd`, plus the brawl's own `aiInput`. A partner needs, beyond that:
- **Target coordination.** Assist on the player's opponent as a satellite by default. Take a second enemy only when one threatens the player or a settlement.
- **Deference.** It never takes the team's launcher opening or the closing blow unless the player has left it unused for a set time. It must not win the fight for the player.
- **A leash.** It stays within a distance of the player unless guarding something.
- **Saves.** It breaks a grab or a finisher on the player, and revives him.
- **Its fighter's nature.** A hero partner lures fights away from civilians (the AI already has that rule). A villain partner would not.
- **Determinism.** It writes intents inside the sim, as the opponent AI does, with keyed draws.

Size: about 2 slices *(estimate)*, after the satellite exists.

## E. Planet runs, bosses, and destruction

- **Structure.**
  - A campaign is a sequence of planets, each a procedural seed.
  - A planet is one free-roam map: henchmen by district, lieutenants who take turns, and the boss.
  - The boss fight is the full choreographed duel, with the partner joining as a satellite.
- **State that must persist.**
  - *Between encounters on a planet:* the world block. That is terrain deformation, craters, scorch, cracks, water, rubble, every building's stage and floors, trees and living civilians. All of it is already in `SimState`.
  - *Per player:* wounds (by `modes.md`'s survival rule: broken regions stay, battered heals to bruised), energy, forms.
  - *Per run:* planets cleared, casualties, and a run seed from which each encounter's seed is a keyed draw.
- **A gap.** There is no state snapshot today: a replay re-runs from the seed and the inputs. A world-block save and load is new work. Rollback (for online versus, which Orb puts first) needs full snapshots too, so the two should be designed together.
- **Where destruction's rules live today:**
  - `sim/world/crater.gd`: the deformation floor, and a crater-radius cap with an "uncapped" switch;
  - `sim/world/collateral.gd`, `structures.gd` and `data/biomes/stages.json`: building stages, and the rule that one blast cannot level a standing building;
  - `docs/design/balance-targets.md`, "Collateral": the per-tier budgets (2% and 4% of civilians a minute at tiers 1 and 2).

  **There is no "planet destroyed" ending in the sim.** It is a line in the vision, pinned for exploration.
- **What Orb's answer needs.**
  - A *planet integrity* measure, built from deformation, structures lost and the top-tier events.
  - An ending when it runs out.
  - A **destruction profile chosen by the match setup**, as data:
    - versus: the ceiling is reachable at top tiers in a full-length match;
    - story: the ceiling is locked unless the encounter unlocks it (a boss's last stand, a failed defence).
  - One rule set and two profiles, with no code fork.
  - Owners: World and Game Design, with QA's bands.

## F. Friendly fire off, with a hook for an exception

Damage reaches a fighter through few doors:
- `SimDamage.hit` (a blow in an exchange);
- `SimDamage.hurt` (everything else; it already takes "by whom");
- `SimShots.hitFighter` and the shot explosion's loop over fighters;
- beam impacts, blasts and the burst.

The check is one question, **"is A hostile to B right now?"**, asked at those doors and at target choice. It should read a fighter's *current side*, not his birth team:
- Mind control changes his side for a time.
- An illusion makes him treat a partner as hostile.

Both are ordinary sim state, in the hash, with keyed draws. Collateral stays shared. A launched partner's body still collides; it just does no damage to a friend.

## G. Revised plan

| Stage | What | Owners | Size *(estimate)* | Waits for |
| :--- | :--- | :--- | :--- | :--- |
| 0 | The rules on paper (pressure, the team launcher, the turn, the bands), then the scratch experiment of section A | Game Design, Encounter, QA | 2 slices | The three-strength brawl's open bands (C2's section 9: the masher rows, double hits, match length) |
| 1 | **Join:** teams and `target` in place of `opp()`, the hostile check, the satellite module and its hooks, the third plate, pane rules for three, two pads on one team. Co-op against one boss | Simulation, Encounter, Combat, Animation, Camera, UI, Controls, Audio, QA | 10 to 12 slices | Stage 0's verdict; the brawl settled |
| 2 | **Henchmen and free roam:** the light body and the scuffle rule, attack turns, target choice, the part grammar and generated bodies, generated movesets by grade, the pair shot per pane | Simulation, Encounter, Art, Animation, Combat, Rendering, Camera, Tools | 10 to 14 slices | A render-cost measurement first |
| 3 | **CPU partner** | Encounter | 2 slices | Stage 1 |
| 4 | **Planet runs:** world-block save and load, run state, a boss per planet, planet integrity and the two destruction profiles | Simulation, World, Game Design, UI, QA | 6 to 8 slices | The snapshot design shared with rollback |
| 5 | **Two full engagements at once:** an exchange per engagement and local freezes. This is also 2v2 versus | Simulation, Encounter, Camera | 4 to 6 slices | Stages 1 and 2 proven |
| Later | Online co-op, after online versus. Input-delay lockstep is enough against AI | Netcode | | Online versus |

Two gates apply to every stage, as in part 1: co-op code is dormant in a two-fighter match (same ticks, same hash), and every new random draw is keyed.

**The phone.** That question stays with Controls. Co-op adds only one thing to it: a way to switch target on the Simple layout.

## New questions for Orb

1. **Equals or pair and satellite?** When both players are on one opponent, is it acceptable that only the player he is facing can trade, close and be riposted, while the other's blows add pressure and either may take the launcher? Or must both be full equals in one brawl (the redesign)?
2. **One full fight at a time, at first?** Until stage 5, both players could not each be in a separate full brawl with a fighter-grade enemy at the same moment. One would be scuffling with henchmen or joining the other's fight. Is that acceptable for the first playable?
3. **Freezes.** When one player's fight freezes for a heavy hit or a finisher, may the other player's game freeze too (simple), or must it keep running (stage 5's cost, earlier)?
4. **Henchmen and the planet's ledger.** Do henchmen count toward anything (menace, anguish, a score), or are they only bodies with weight?
5. **A destroyed planet in a run:** does it end the run, or change it (the pinned idea of a fight continuing in space)?
6. **The CPU partner:** fully its own mind, or can the player give it one order (focus or hold back)?
7. **Whose trick is mind control?** An enemy's (it turns your partner on you), a player fighter's (it turns henchmen), or both?

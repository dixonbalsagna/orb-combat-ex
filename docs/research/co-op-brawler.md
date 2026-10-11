# Co-op brawler mode: a research study

Research & Prototyping, 2026-10-11, for Orb's brief of the same day. This is a written study only: nothing was built, and no code or data was changed. It was read against HEAD 02cff62d. Every size and cost marked *(estimate)* is a judgement from reading the code and docs, not a measurement.

**Orb's question.** How could today's versus systems carry two players fighting together against AI opponents, as part of a bigger game?

## Recommendation in short

**Build "lead and wing" first: two players against one boss-grade AI opponent, with exactly one engaged pair at a time.**

- The player in the exchange (the lead) plays today's versus game unchanged.
- The second player (the wing) is a free fighter. Every press is still one real attack: a blast from range, a cut-in blow in reach, or the blow that takes the engagement over.
- The engagement passes between the two players like a baton. It never leaves one player watching.

This shape keeps the three things the game is built on: the single exchange, the brawl as a pair with a centre, and the two-pane camera. Linked pairs (2v2), grunts and a run of encounters come after it, in that order.

## 1. Where "exactly two fighters, one pair" is assumed

The sim is about 20,800 lines of GDScript. The visible part of the assumption is small: `SimRoster.opp()` has 37 call sites in 17 files, and `fighters[0]` or `fighters[1]` appears 28 times in the sim. The larger part is state shaped like a pair. The "lead and wing" column is the recommended first slice; the last column is what linked pairs or grunts would need.

| System | What assumes two | Lead and wing | Linked pairs, grunts |
| :--- | :--- | :--- | :--- |
| Sim state (`state.gd`, `sim.gd`) | `fighters` is already an array, but `newMatch` fills slots p1 and p2, sets facing for two, and reads `ai: {p1, p2}` | Small: a team id and a third slot | Small |
| The other fighter (`opp()`) | "The fighter who is not me": the defender, the AI's target, facing, credit for damage | Small but wide: a `target` per fighter at every call site | Same |
| The exchange (`S.dirS.ex`, `Exchange.A` and `.D`) | One exchange for the whole match, one attacker and one defender, one cooldown | **No change**: still one exchange | Large: one exchange per pair, each with its own cooldown |
| The brawl (`brawl.gd`, 2,658 lines) | One pair with a centre that both sticks move; two strike lines | **No change** to the pair; small: a cut-in beat joins it | Redesign only if three bodies share one brawl (not recommended) |
| Lock-on and "never out of range" | Attacks close on `opp()` | Small: close on the target | Small, plus a rule for choosing a target |
| Wrap maths (`SimWrap`) | Nothing: `sdx(a, b)` is between any two points | No change | No change |
| Zips (`zip.gd`) | Goes in on the rival and out round him (7 `opp()` uses) | Small | Small |
| Beams and clashes | A beam aims at `opp()`; `S.game.clash` is one clash | Small: clashes only inside the engaged pair; the wing fires shots | Large: a clash per pair, and beams that cross a third body |
| Launch planner (`launch.gd`) | Scores one victim; the variety history is global | No change | Small: a history per pair |
| Wounds | Per fighter. The exchange packs wound flags as "slot × 4 + region" bits | No change (the bit fields have room) | No change |
| KO and match end (`S.game.ko`) | One KO ends the match | Small: a team is out when all its fighters are | Small |
| Anguish, menace, collateral | Collateral is world state. Anguish goes to the first hero in the list (a known bug, sim/README) | Small: fix that bug, credit by team | Small |
| The AI (`ai.gd`) | Plays against `opp()` | Medium: choose a target, react to a cut-in. A new AI if a solo player gets an AI partner | Large: grunt behaviours, attack turns |
| Input (`hub.gd`, replay) | Two human slots; a replay records two input streams | Small: a third slot; both humans on one team | Small |
| HUD (`ui_hud.gd`, lanes, `ui_split`) | Two plates, two lane colours, one edge pointer | Medium: a third plate and team colours | Large on a phone: four plates do not fit |
| Camera (`split_rig.gd`, 17 two-fighter uses) | The merged shot frames the pair; a pane frames one fighter; the trigger is the pair's size on screen | Medium: pane A frames the engaged pair, pane B the wing (a pane is already a one-fighter shot) | Large: a pane per pair, four bodies in one shot |
| Audio cues (`audio_brawl.gd`, `audio_voices.gd`) | Voices and brawl cues by slot 0 and 1 | Small | Medium: a voice budget |
| Flash register | The cap is global (3 grants in any 60 ticks, 1 in reduced), so the rule holds for any number of bodies | No change to the rule; small: who is refused first | Same, but refusals rise (section 4) |
| Goldens and determinism | Every golden is a two-fighter match | Medium: two-fighter goldens must stay bit-identical (the gate); new co-op goldens | Same |
| JS parity oracle | Frozen at the prototype's behaviour (ADR 0006) | **No change** | No change |

Two rules follow from this table:
- **Any new random draw must be a keyed draw** (`SimRng.keyed` exists). A new draw on the shared stream would change every versus golden.
- **The co-op code must be dormant in a two-fighter match:** same ticks, same hash. That is the proof versus was not disturbed.

## 2. Encounter shapes compared

Two of the project's control rules have to hold for both players in every shape:
- "One press is one attack."
- "The player always feels in control except in knock-backs."

| Shape | How the director choreographs it | Camera | Cost *(estimate)* |
| :--- | :--- | :--- | :--- |
| **A. Two against one boss, pincer** | Both players are in the brawl with the boss at its centre, one on each side. The boss has one strike line and must turn to face a player, with a visible tell. | One shot of three bodies most of the time | Large: the brawl becomes a three-body system |
| **B. Two against two, linked pairs** | Two ordinary pairs, each today's game. A third body that attacks an engaged fighter is a cut-in (`docs/design/modes.md` already defines it). Players can swap opponents, and tandem signatures are possible. | A pane per pair; one shot only when all four are close | Large: an exchange per pair, four full fighters, two AIs |
| **C. Two against a wave of grunts** | Grunts are not fighters. They have no exchange: a press auto-targets the nearest grunt in reach, and a blow staggers, launches or drops it. The director hands out attack turns so only one or two grunts attack a player at a time. | A pane per player, merged when they are close | Medium to large, but self-contained: a new, lighter body class beside the director |
| **D. One pair plus a partner in support** | The lead and the opponent are today's pair. The partner is free: cover fire, cut-in blows, saves (breaking a grab or a finisher), collateral duty, a tandem signature. | Pane A is the pair's shot, pane B the partner's | **Small to medium**: the single exchange and the pair stay |
| **E. Lieutenants, then the boss** | Shape D or B against two or three lesser opponents who take turns (one fighter concept in vision.md opens this way), then the boss. | As D | D plus an "it is your turn" rule for the AI side |

What each shape does to the control rules and the pillars:

- **A (pincer).**
  - Both players press freely, and the boss is stun-locked unless he gets armour and wide sweeps. That is a new opponent design, not a number change.
  - The brawl's centre can no longer follow two sticks that disagree.
  - Pillars hold. "Power has weight" is at risk if the boss becomes a punching bag.
- **B (linked pairs).**
  - Each player has a full duel, so control is as good as today.
  - But the two players mostly fight *next to* each other. The co-op verbs (cut-in, swap, tandem, revive) are the only shared moments.
  - On a wrapped planet the two duels drift apart, which is the hardest camera case.
  - Four fighters double collateral, and anguish and menace need team rules.
- **C (grunts).**
  - Control is easy to keep, but this is a different genre. Mature blows on throwaway bodies thin out "power has weight" and the wound system.
  - It serves "collateral" well if grunts threaten civilians.
  - Orb's three goon types (bruiser, marksman, speedster) fit here as *spice inside another shape*, not as the whole mode.
- **D (support).**
  - The lead's control is exactly today's.
  - The partner is always free, so always in control. Each of his presses is a real attack. "Never out of range" holds through blasts.
  - The risk is that the partner feels second-class. The fix is the baton (section 6).

**Recommended: D with the baton** ("lead and wing"), against one boss-grade opponent first. E is the natural second step, B the third. A and C are not recommended as starting points.

## 3. What "part of a bigger game" could mean (structure only)

The versus match stays the unit. A bigger game is a sequence of matches that remember things. `docs/design/modes.md` already sets survival rules that fit: the planet's damage carries over, broken regions stay, battered wear heals to bruised.

- **A ladder (smallest).** Four to six encounters on one persistent planet, mixing duels, duo-against-boss and lieutenant openers, with rivals and bosses drawn from the roster of twelve. This is arcade mode with a second player.
- **A planet run.** A map of encounter nodes across the biomes, with a choice of route. The planet's damage and the civilians lost persist. The run can end the way a match can: the planet is destroyed.
- **Encounter types** the systems can already suggest:
  - a duel (today's versus, solo or with a wing);
  - a boss;
  - a gauntlet (lieutenants, then the boss);
  - a defence (keep a settlement's losses under a limit: collateral as the objective);
  - a pursuit across biomes ("the planet is the arena");
  - a sparring interlude between the two players (versus itself, inside the run).
- **What carries between fights:** planet damage, wounds, anguish and menace, and energy.
- **What does not:** a KO. A fallen partner returns next fight, or mid-fight through the revive beat Orb has already approved for 2v2.

## 4. Input and platform

- **Two pads on one PC: small.** `SimHub` already assigns devices to two human slots, and the shared keyboard halves exist. Co-op needs both humans on one team, with the opponent in a third, AI slot.
- **One phone.**
  - Two touch players on one phone is not realistic: the Simple layout already uses both thumbs and the whole screen.
  - Realistic: one touch player plus one Bluetooth pad; two pads with the phone as the screen; or two phones online (after launch).
  - A large tablet with two Simple layouts at opposite ends is possible in principle, but untested.
- **Online co-op.**
  - Against AI, input-delay lockstep is enough to start: the sim is deterministic, and only inputs travel. It needs no re-simulation, so it avoids rollback's cost.
  - Rollback multiplies the tick cost by the frames it re-simulates, and more bodies make each tick dearer.
- **Sim cost** *(estimate)*.
  - Measured today: 0.175 ms a tick on the desktop with two fighters (`docs/rendering/README.md`).
  - Projected to an old laptop's browser, using the engine spike's factors (CPU 2.6 to 3.9 times slower; wasm about 1.85 times): about 0.85 to 1.25 ms a tick.
  - Lead and wing adds a free fighter, not a second exchange: about 1.3 times. Linked pairs: about 2 times.
  - With a 7-tick rollback, linked pairs would cost about 13 to 20 ms a frame there, which is over budget. Lockstep stays under 3 ms.
- **Frame cost.**
  - A third fighter's render cost is **not measured**. Animation's spike project (`render/anim/spike/`) is built to measure it, and should be run before a commitment.
  - A split fills the screen twice whatever the body count. Three bodies need no third pane.
  - Grunts need a cheaper body (shared rig, instancing, no wound marks) and their own budget.
  - A real phone's speed and memory are still unmeasured (`docs/perf/phone-web-fullscreen.md`).
- **Flash safety.**
  - The register's cap is global, so the granted count stays legal with more bodies.
  - But more bodies ask more often, so more hits lose their flash. Today, with two fighters, 20 to 30 body flashes a match are already refused.
  - The pixel check already fails five of sixteen two-fighter clips, on beams, explosions and camera cut-ins. Those sources grow with the body count.
  - Co-op needs a priority rule (a human's own hits first), and its own clips through the pixel check.

## 5. How co-op works elsewhere (by mechanism)

- **Attack turns.** In side-scrolling brawlers and crowd-action games, many enemies surround a player but only one or two may attack at once. The rest circle and feint. This keeps a mob readable and fair.
- **Threat.** In boss fights built for parties, the boss attacks whoever has drawn the most attention. Players pass that attention deliberately, so one recovers while the other holds.
- **A shared stagger gauge.** In character-action and hunting games, every player's hits fill one gauge on the boss. Filling it opens a window for everyone, which makes two players' damage add up without stun-locking.
- **Assists and tags.** In team fighting games, an off-screen partner is called in for one strike on a cooldown, or swapped in. A swap is safest during the active fighter's attack and riskiest when called raw.
- **Saves.** In tag-team wrestling games, the partner may break a hold or a pin within a short window, then must leave. It is the clearest "my partner saved me" beat in any genre.
- **Synchronised finishers.** Both players confirm within a window for a combined super. Missing it costs only the bonus.
- **Revives.** A downed partner can be raised by standing next to them, which exposes the reviver. Some games share one pool of defeats for the team instead.
- **Scaling.** Bosses gain health or stagger resistance with player count, rather than new moves.
- **Shared screens.** A soft leash keeps players within one frame, edge markers point to whoever is off-screen, and some games split the screen dynamically when players part, as this game's camera already does.
- **Flight-arena raids.** In free-flight arena fighters with raid modes, several players fight one giant opponent with phases. Lock-on switching and target markers carry most of the readability.

Three of these map straight onto the recommended shape: threat, the save, and the shared stagger gauge (the brawl's run and stagger rules are close to one already).

## 6. Recommendation: the smallest playable slice

**"Lead and wing": versus-AI with a third fighter.** Two humans on one team against one AI opponent with boss-grade numbers (more health and stagger resistance, no new moves).

- **The baton.** One engaged pair exists at a time.
  - The wing's blow on an opponent who is free starts the next exchange with the wing as lead.
  - The wing's blow on an engaged opponent is a cut-in: one strike, no chain.
  - When the lead is knocked back or launched (the one time a player is out of control), the baton is open: the wing's next attack takes it. A knock-back becomes the hand-over, not dead time.
- **The opponent's attention** follows a simple threat rule: the engaged player, unless the wing has just cut in twice.
- **Camera.** Pane A is the engaged pair, framed as today. Pane B is the wing, shown when far. It merges when the wing is near.

| Piece | Owner | Size *(estimate)* |
| :--- | :--- | :--- |
| Teams, a third slot, `target` in place of `opp()`, team KO; dormant in two-fighter matches | Simulation | 2 slices |
| The baton, the cut-in beat's rules, threat, the AI's target choice | Encounter | 2 slices |
| Cut-in and save beats as data | Combat | 1 slice |
| Pane rules for three bodies | Camera | 1 to 2 slices |
| Third plate, team colours, pointers | UI | 1 slice |
| Third input slot, both humans on one team | Controls | under 1 slice |
| Third fighter view, voices and cues by slot | Rendering, Audio | 1 slice together |
| Co-op goldens, the "versus unchanged" gate, a first balance band | QA | 1 slice |
| Flash priority, and co-op clips through the pixel check | Tools | under 1 slice |
| Rules: friendly fire, threat, boss numbers, what a save is | Game Design | 1 slice, first |

That totals about 10 to 12 slices *(estimate)*.

**Defer:** linked pairs (2v2), grunts, the revive beat, tandem signatures, an AI partner for solo players, the run structure, online co-op, and any phone co-op.

**The three biggest risks:**
1. **The wing is not fun, or the boss is.** Two players can smother one AI, or the wing can feel like a helper. Only play settles this. A paper rule set and a small scratch test should come before any slice is built.
2. **Versus regresses.** The pair assumption runs through 20,800 lines that Encounter is still changing. The "dormant in a two-fighter match" gate and keyed draws are the protection, and they cost time on every slice.
3. **Readability and flashes.** A third body adds flash requests, voices and HUD to a screen that already fails the pixel flash check in five clips. Co-op could make the photosensitivity gate harder to pass.

## Questions only Orb can answer

1. Is co-op for two humans only, or must a solo player get an AI partner?
2. Is "lead and wing" with the baton acceptable as the first shape, or must both players always be in the same exchange?
3. Do you want crowds of grunts at all, or only fighter-grade opponents (with the three goon types as spice)?
4. Which bigger game: a ladder (arcade with a second player), a planet run with a map, or endless survival?
5. Can the pair lose by collateral (the planet destroyed, a settlement lost), and is anguish shared by the team?
6. Is friendly fire off between partners, as `modes.md` says for 2v2?
7. After launch, which comes first: online versus or online co-op?
8. Is co-op on a single phone a requirement, or is "a phone plus a pad" enough?

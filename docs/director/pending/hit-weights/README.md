# The director's hits name their weight (parked, 2026-10-22)

Owner: Encounter Systems Director. Encounter's part of Simulation's hit-stop by weight (`docs/architecture/feel-core.md` §2 and §5; Game Design's `rulings-2026-10-19b.md` 4a).
- **Every line sits behind Simulation's `S.hitstopOn`** (`data/fight/hitstop.json`, off). A hit's options are often a beat's, and beats are hashed, so with it off nothing is written: play and the golden don't move.
- **Built and read in scratch. Not applied.**

## To build it

`node hw.cjs <root>` from this folder, on main with Simulation's hit-stop by weight. `--check` reads every anchor and writes nothing. It composes with the 4c/4d, wall-kick, balance, camera-intent v3 and calm-turn parks.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/melee.gd` | Encounter | `weigh` (names a hit's weight while it is on); `holdSend`: the send holds a launch's stop (14), a full launch's (16, launch anywhere's full power) or a set piece's decisive one, through `SimHitstop.hold` |
| `sim/director/brawl.gd` | Encounter | `weightOf` and the blow's name at its contact; the point-blank bolt (light) and blast (medium) |
| `sim/director/exchange.gd` | Encounter | A planned strike (heavy or ender: heavy, else light); a chain link (light); **the finisher's last blow: decisive** |
| `sim/director/grapple.gd` | Encounter | A throw: heavy |
| `data/director/interrupts.json`, `tools/schemas/director-interrupts.schema.json` (**Tools'**) | Encounter | `anywhere.fresh.airSense` removed: Simulation's `brake.json` holds the one |

**The names** (Simulation's table): a brawl blow by its kind. A mashed, flurry or held-pace light is `light_mash`, a tapped light `light`, the close `launch` (the table's "a launch or a close"), a medium `medium`, a heavy `heavy`, the double hit `heavy`. The duel of perfects isn't built, so it names nothing yet.

## What it read (main 30fcaf28 with Simulation's shared park, in scratch; 10 AI matches)

| | Hit-stop by weight off | On, with the names |
| :--- | ---: | ---: |
| Frozen share of all ticks | 22% | **30%** |
| A brawl blow's stop, as held | 2 ticks (9,579 blows); 7 (90, the heavies' 6) | 2 (4,433 mashed lights); 5 (2,935 tapped lights' 4); 8 (190 mediums' 7); 11 (97 heavies' 10); 15 (116 closes' and launches' 14) |

- **Most stops hold one tick over their ticks** (4 holds 5, 7 holds 8, 10 holds 11, 14 holds 15), as today's heavy's 6 holds 7 and its light's 2 holds 2. A stop of n ticks in seconds, counted down by `DT` a tick, can leave a hair over 0. That's the step's count, Simulation's; worth a look with the table.
- **The frozen share is 30% against Game Design's budget of 12%.** The budget's one lever, mashed lights to 2, can't bite. The AI's strings are tapped lights at 4, and they are most of a brawl. That's for Game Design and Simulation.
- **Off** (30fcaf28, with camera-intent v3): the golden is main's, byte for byte, and the full gate list is 34 of 35. Its one red is main's own anim_check.

# The AI's perfect block against a charge: a guess, never a reaction (parked, 2026-10-16)

Owner: Encounter Systems Director. Game Design's eleventh round (`docs/design/brawl-second-pass.md`), item 3, after Orb's playtest: "the CPU opponent was able to easily perfect block every charged attack I used." **Built and read in scratch on main 0ee9cb6b. Not applied.**

## Why the AI knew

On main the AI weighs its perfect block against a heavy when the heavy's wind-up ends, and marks the blow. **That mark stayed on the blow however long the player then held the charge.** So the block was decided before the player let go, and his release timing changed nothing. Every perfect block of a charged heavy the probe saw on main came from a press before the release, at every level.

## To build it

`node pg.cjs <root>` from this folder, then regenerate the golden. `--check` reads every anchor and writes nothing; any other option is refused. It works on main, or on main with the return fix: its two slots go at `END`, whatever `END` is.

| File | Change |
| :--- | :--- |
| `sim/director/brawl.gd` | Two slots, `GUESS_AT` and `GUESS_P`. `_guessCharge`: as a heavy's charge starts, the AI it is aimed at decides once whether to try, and picks a tick across the charge (keyed draws, so the sim's stream is untouched). `_guessTick`: it presses on that tick if he still holds the charge. `_guessed`, read at the release: the mark is judged afresh |
| `sim/director/interrupt.gd` | The AI's guard press never marks a charge that has been released |
| `data/director/ai.json` | `brawl.chargeGuess` by level: 0.1, 0.3, 0.5 (Game Design's tries) |
| `data/director/interrupts.json` | `brawl.heavy.charge.guessTicks` [33, 70]: the span of the AI's pick, in the charge's own ticks from its wind-up (the charge runs from 32 to 70; it is not keyed to the flash at 44) |
| `tools/schemas/director-ai.schema.json`, `director-interrupts.schema.json` (Tools') | The two keys |

## As built

- **The AI never reacts to a release.**
  - It tries a level's share of the charges it sees.
  - It picks its tick when the charge starts, and presses only while he still holds it. A release before the tick drops the guess.
  - It never presses after a release.
- **At the release, the blow's mark is judged again.**
  - A press counts only if it came before the release and falls inside the perfect window when the blow lands: 14 ticks, the heavy's window with its early tolerance.
  - For the AI, only its guess counts; its stance's other presses never perfect-block a charge.
  - **For a player, his last fresh guard press counts, free of the lockout. So a player may guess too.** Before, nobody could perfect-block a charge with a press before the release.
- **What isn't covered:** a signature's hold, the held X's set and a tackle's coil, which Game Design also named. The AI's beam answer goes through its own path (`DirBeamPlay`), not this one.

## What it read

`probes/pg1.gd`: 20 matches against each level, seeds 1 to 20. A scripted player taps X every 8 ticks and, every 150 ticks, holds B for 36 to 72 ticks, so most of his Bs are charges let go at a spread of moments. Counted per charged heavy he let go.

| | Easy | Medium | Hard |
| :--- | ---: | ---: | ---: |
| Main: perfect-blocked | 35 of 590 (5.9%) | 47 of 758 (6.2%) | 31 of 608 (5.1%) |
| ... of those, decided before the release | all | all | all |
| **With the guess: perfect-blocked** | **15 of 578 (2.6%)** | **19 of 702 (2.7%)** | **9 of 602 (1.5%)** |
| The AI's guard presses on or after a release, before it lands (the hard test: none) | 0 | 0 | 0 |
| Game Design's estimate | about 3% | about 10% (the band: 5 to 15%) | about 20% |

`probes/pgd.gd` (10 matches) shows where the guesses go.

| | Easy | Medium | Hard |
| :--- | ---: | ---: | ---: |
| Charges | 297 | 352 | 315 |
| The AI tried | 33 | 84 | 139 |
| It pressed (the release hadn't come yet) | 21 | 36 | 50 |
| Its press fell inside the window | 12 | 18 | 19 |

- **The mechanism works, and the shares come out under Game Design's estimate.**
- **More than half the picks come after the release and are dropped.** The span is the whole charge, as the ruling asks (not keyed to the flash), and this script lets go early in it.
- **About half the blows marked in the window never become a perfect block at medium, and three in four at hard.** The blow is lost before it lands: a miss, a trade, or the AI's own blow first. At hard the AI stops more charges outright and loses more marks, which is why hard reads lowest. That's worth a look on its own.

## Open, for Game Design

- **The shares.** At these tries the AI perfect-blocks about 3% of charged heavies at every level: under the 5 to 15% band at medium, and with no rise by level. Three levers:
  - **The tries.** They scale about linearly, so medium at about 0.55 reads near 5%.
  - **The span.** A narrower one puts more picks before the release, but leans the picks toward where players let go.
  - **Picks after the release.** A pick made at the charge's start could still press up to the landing (about 40% more inside the window). It isn't a reaction, but by the letter it is a press within reaction time of a release.
- **A player can now perfect-block a charge by guessing.** That follows from the ruling's "as a player has to", but it is new.

## Gates

The full gate list, 35 of 35, on main 0ee9cb6b with the park applied. Play changes in 3 of the 9 golden matches (their light digests), where the AI meets a charge. Every checkpoint moves, since two slots grow the hashed brawl state. Wounds, rally, cripple, mood, keyed, `rosterHash` and `fightHash` are unchanged.

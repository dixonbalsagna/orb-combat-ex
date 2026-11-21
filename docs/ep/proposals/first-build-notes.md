# Your first build made from the main game: what is new, and what to try

A draft by Orb's stand-in, 2026-11-20, for the EP to move to homework when the build exists. The part for Orb comes first. The last section is for the EP only and should be cut before Orb sees the page.

---

## In one line

This is the game you played on 9 November, made straight from the team's main copy with no special link, and it now opens on a real start menu.

## What you will notice

| What | What you see | What you press |
| :--- | :--- | :--- |
| **A list of modes** | The game opens on "Choose a mode". Two can be played: "Against the computer" and "Two players, one PC". The other six (two against two, Horde, Practice, Custom planet, Play over a network, Campaign) say "Coming" | Up and down on the d-pad or stick, A to choose. A on a "Coming" mode does nothing; its card says the mode is not in the game yet |
| **A fighter pick** | After you choose a mode you get "Set up the match": your fighter, the computer's level or Player 2, and their fighter | Left and right on a row to change it, then the start row at the bottom |
| **Two of the same fighter is not allowed yet** | If you step onto the other player's fighter, the two swap. The screen says why: the two could not be told apart yet | |
| **Quit** | A "Quit" row on the mode list, on the pause menu and on the match-over screen. It asks "Close the game?" with "Stay" lit first, so one stray press never closes the game | A on Quit, then choose |
| **Pause opens its menu** | On 9 November the pause menu could stay off the screen. It now slides in from the left every time | Start (the Menu button) during a match |
| **The d-pad moves evenly** | On the start menu, up from the top row goes to the bottom row and down from the bottom goes to the top. Left and right only change the row you are on | |
| **A version line** | Small grey text at the foot of the menus, for example "Version 0.1.7". The match-over screen adds the build and its date | |
| **No special link** | The things your 9 November copy switched on through its link are now simply how the game is: the energy model, the dash from any range, the slip past a rival, the kick, the round ground with the new crater look, the meteor trail, your camera, your pad layout, the sound sets and the menu with the panel down the left | |
| **A saved match** | At the end of a match the game can save the match as a file, so the team can replay exactly what happened | |

## What should feel exactly the same

Everything in the fight itself: every blow, dash, launch, beam and crater should behave as it did on 9 November. The team checked this by replaying recorded matches and comparing them number for number. If a fight feels different, that is a finding, and it is worth telling the EP.

## Two differences you may feel, both known

| What | On 9 November | In this build | When it goes back |
| :--- | :--- | :--- | :--- |
| **How far a launched fighter flies** | Your link set it to 1.5 | 2.0, so a launched fighter travels about a third farther | 1.5 comes in the next batch |
| **Top flying speed** | Your longer match used 3,500, the speed you chose | 5,000, the old starting value | 3,500 comes in the next batch |

This build has no link, so it cannot carry those two values the way your 9 November copy did. They become the game's own values in the next batch.

One more thing: match files you saved on 9 November will not play in this build. It tells you so in plain words instead of failing halfway.

## What to try (about ten minutes)

1. **Start a match against the computer.** Choose the mode, pick the other fighter from the one you usually play, start. Does the start menu read clearly? Is anything on it confusing?
2. **Pause in the middle of a fight** with Start. The menu should slide in. Go down to Quit, press A, and check that "Stay" is lit first. Press B to go back to the fight.
3. **Hold up on the d-pad on the mode list** and watch it wrap round from top to bottom.
4. **Go to Horde and press A.** Nothing should start, and its card should say the mode is not in the game yet.
5. **Play one full match** and say whether anything in the fight is different from 9 November, apart from the two differences above.
6. **At the end of the match, save it,** and check the game tells you a file was saved.
7. **Start "Two players, one PC"** if someone is with you, and check each of you can pick a different fighter.

## One question for you

**Are the words in the new menus right?** They are working words nobody has shown you yet: "Choose a mode", the eight mode names, "Coming", "Set up the match", "Quit", "Close the game?", "Stay". The EP has a short page with all of them. Changing a word is quick, so say what reads wrong.

## What is not in this build yet

These are built or being built and come in the landings after this one:
- flying speed 3,500 and launch distance 1.5 as the game's own values;
- the old hero and villain meters no longer changing the fight;
- a stick beam you let go of no longer firing later on its own;
- the round planet as the world every match starts on by default, with lakes drawn properly;
- buildings that remember being hit;
- planets in more than one size: small, medium and big come first.

---

## For the EP only (cut this section before the page goes to Orb)

Facts this draft rests on, and what to confirm when the build exists:

| Claim in the draft | Where it comes from | Confirm before sending |
| :--- | :--- | :--- |
| The mode list, setup, Quit, the d-pad and the words | `docs/ui/pending/a1-start-flow/README.md` ("What it does", "Words for Orb to see before use"); `a1-rail-default` flips `menu_modes` on; your ruling on S-03 keeps it on | That the built game's packed `ui/data/features.json` has `menu_modes` true |
| Pause slides in | `docs/ui/pending/a1-pause-clock/README.md` | A real pause in the built game, with Reduce motion off |
| Start pauses | Read from `ui/hud/ui_hud.gd` (`JOY_BUTTON_START`); not tried | Try it on a pad |
| The version line and its example | `docs/ui/pending/a1-menu-fixes/README.md` section 2 | The real version number in the build |
| Launch distance 2.0 against Orb's 1.5; top speed 5,000 against 3,500 | `docs/ep/reviews/GW1a-standin.md` S-01 and your ruling to keep 2.0 in GW1a; `data/fight/power.json:108` (`flatOut` 5000) and `:110`; `docs/architecture/pending/gw1b-energy/README.md:8-10`. Orb's two 9 November plays used flat-out 5,000 and 3,500 (`docs/qa/runs/6a30b4c9/README.md:3`) | Settled by the EP on 2026-11-20: the table stays, because the desktop build has no link words. If the first build Orb gets turns out to be after GW1b, delete it and move the first two lines of "not in this build yet" up into "What you will notice" |
| Old play files are refused in plain words | `docs/ep/reviews/GW1a-standin.md` S-08; `docs/ui/pending/a1-replay-words/README.md` | That the refusal shows on screen and not only in a log; S-08 was open on 2026-11-20 |
| "The game can save the match as a file" | `docs/tools/pending/code-03/README.md` (the report hook) | Which button or row saves, and that the folder it names is right (S-04 was open: desktop builds named the wrong folder). I left the button out because I could not confirm it |
| The tundra colours | Your commit 59ca7a47 puts Art's 9 November colours into GW1a, so nothing to tell Orb | |
| "Lakes drawn properly", "buildings that remember", "five sizes" in the later list | `docs/ep/reviews/GW1b-review.md`, `memory-under-model-review.md`, `GW1c-readiness.md` | Drop any line whose landing has slipped out of A1. The sizes line already reads "small, medium and big come first", per your ruling |

The question for Orb is the one already waiting in homework ("Decide - words in the new menus"). It is asked once here, with no recommendation, because the words are Orb's taste.

Not in the draft on purpose: anything about flashing or safety settings, any team nickname, and any mark drawn on or over a fighter.

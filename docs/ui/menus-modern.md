# Modern menus: a design pass (UI & UX, 2026-11-08; Orb's overnight order: "enhance the menus and make them more modern")

**Status: design only.** No menu code changes until Orb picks a direction. Pictures are in `docs/ui/runs/397a7adf/menus/` (today's four screens from the web build, three mockup directions, side-by-sides). The mockup pages are in `docs/ui/mockups/menus-modern/` (`a-rail.html`, `b-tiles.html`, `c-strip.html`, `?s=start|pause|options|over`). They are drawn over the demo's grey-box backdrop, in the system font; the game's own font and art stay as they are.

## 1. Today, and what is wrong with it

| Screen | What you see | The problem |
| :--- | :--- | :--- |
| **Start** | One card: four lines of Legal's notice, then radios and five boxes in two columns, one wide button, a small Not now | The notice is a wall above everything; the form has no hierarchy (is "Reduce flashing" as important as "Players"?); the focus ring is the only guide; nothing says what the choices add up to |
| **Pause** | A narrow centred list of seven buttons with keyboard letters (P, F1, N) | The letters are for a keyboard only (a pad player sees keys they do not have); the facts and the "player two" line crowd the card; Resume is not clearly the first thing |
| **Options** | A long list in a card, chevron buttons, one help paragraph at the foot | Dense; ten rows visible of a hundred; the help is far from the row it explains; no categories to jump between |
| **Match over** | A small card: result, two counts, three buttons | Plain, and nothing for what Orb's testers now need (save the match, report a problem) |

All four are the same card with different contents. That is consistent, but it reads as a form, not as a game.

## 2. The direction in one paragraph

**One frame for every screen, built for a pad first**: a dark rail down the left edge with the screen's name, big type and one clearly lit row (a solid bar with a gold notch, so focus is shape as well as colour); the detail for that row on the right, in words that say what it does; the buttons for the player's own device along the bottom edge. The world stays visible and unchanged behind it. Nothing fades, wipes or blurs (ADR 0010, Orb 2026-10-18): the lit bar moves between rows with a short ease, panels slide in from the edge they belong to, and everything else cuts. With Reduce motion on, all of it cuts.

## 3. Three directions (see the stills)

**A. The rail (recommended).** The frame above, on all four screens. Start becomes a short rail (Players, Player 1, Computer, then the comfort switches), a detail side with Legal's notice in its own labelled panel and a summary of the match, and one gold button. Options becomes tabs across the top (LB and RB jump between Controls, Display, Sound, Accessibility, Camera) over a list with the row's explanation beside it. Pause and match over are the rail alone with one small card.
- Best at: scanning, reading what a setting does before changing it, a pad.
- Cost: the most new drawing code (one new layout plan, the tab bar, the detail card) and the most hud_check geometry to extend.

**B. The tiles.** Big tiles to pick from (1 player, 2 players, Comfort on the start screen; Play again, Save this match on match over), small pills for the second-level choices.
- Best at: the first screen. It feels like a modern console front end and takes the fewest presses to start.
- Cost: it does not scale to Options (a hundred rows) or Pause; it would be a start and match-over style only, beside A or C.

**C. The bottom strip.** A command bar along the bottom edge for Pause and Match over; the fight stays almost fully visible.
- Best at: a pause in a LAN match, where the match is not stopped and nothing should hide the fighters; also the lightest build.
- Cost: seven entries do not fit in one row on a narrow screen without scrolling; it does not suit Options or Start.

**What I would build:** A for all four screens, with C's strip as the pause layout while a LAN match keeps running (one setting in the plan, not another design). B's tiles are the better first screen if Orb prefers them; A and B share the same data.

## 4. What each screen must say (the words are plain and ours; Legal's stay exactly as written)

- **Start.** Title "Start a match". Rows: Players, Player 1, Computer, Intros, Captions, Move guide, Screen shake, Reduce flashing. A "Read this first" panel with Legal's notice **word for word** (the text is unchanged, only where it sits), above the buttons; the button stays "I understand, start" and "Not now" stays. A "This match" panel says in a sentence what the choices make ("You, keyboard, player 1. Against the computer, Medium"). Reduce flashing's one-line state stays under it.
- **Pause.** "Paused". Resume first and lit. Entries: Resume, How to play, Settings, Send feedback (its panel gains SAVE REPORT on a LAN build), About, Main menu, New match (still asks first). On a LAN build a line says where saved reports go. A small card: the match time, buildings lost, craters (no counts of people: RL-257). The "Player two: press any button to join" line becomes a chip.
- **Options.** Category tabs; a row is a name and its control; the right panel names the row, says what it does in the words it has now (Narrative's words, unchanged), the current value and the default; "Reset this page" on Y.
- **Match over.** The headline is the result ("Grist wins", or "No contest: nobody played"). Entries: Play again (first, lit), Save this match, Send feedback, Main menu. The two counts stay in a small card. "Save this match" says in its card what it saves and where it stays (docs/ui/lan-report.md); after it is pressed the card says what happened.

## 5. Pad first: how you move

| Input | Does |
| :--- | :--- |
| D-pad or left stick up and down | Move the lit row (one step a push; the stick must come back to rest) |
| Left and right | Change the lit row's value; on a row with no value, jump to the next group |
| A (keyboard: Enter) | Choose |
| B (keyboard: Esc) | Back one level; on Pause it resumes, on Start it is Not now |
| LB and RB (keyboard: Q and E) | Options: previous and next tab |
| Y | The row's details, or Reset this page |
| Start | Pause: resume |

The hints along the bottom edge are drawn from the glyph set of the device the player last used (a pad shows A and B; a keyboard shows Enter and Esc; never both), the way the legend is. The mouse works as it does now, with hover moving the lit row. Touch is parked (ADR 0011): nothing here is phone work, but hud_check's phone sizes stay in the gate for every plan I change.

## 6. Motion (eased, never faded, never wiped)

| What | How | Reduce motion |
| :--- | :--- | :--- |
| The lit bar moving between rows | Slides to the new row in 140 ms, ease-out | Cuts |
| The rail and the detail card arriving | Slide in from the left and right edges in 180 ms, ease-out, the world already in place | Cut |
| A value changing | The new value replaces the old at once; the small arrows give one 80 ms press mark | Cut |
| The status line (a saved file, a marked moment) | Appears at once and goes at once after its time | Same |
| Anything fading, wiping, blurring or flashing | Never | Never |

The lit bar is steady (no pulse); its gold notch and its fill are shapes, so focus does not depend on colour (the colour-vision rule). Nothing animates more than twice in a second in any one place (the flash rule), and a held direction repeats at 6 steps a second, not faster.

## 7. What it costs to build (for Orb's pick)

- **A:** a menu frame widget (`UiMenuFrame`: plan, hit, draw, like the cards today), then Pause, Match over, Start and Options moved onto it one at a time, each behind its own flag in features.json so main never loses a working screen. Estimate: four short sessions of mine, each with hud_check at every size and a side-by-side. The flash check and the look gate apply to each.
- **B or C alone:** one session each, but they leave Options and one of Pause or Start as they are today.
- **Not changed by any of them:** the words (they move into the new frame as they are), the data files, the sim, the input layer (Controls owns the pad's meanings; this uses the buttons the menus already read).

## 8. For Orb

1. Which direction: A (the rail), A with B's tiles for the first screen, or C for the pause only?
2. Legal's notice stays word for word; it sits in its own panel and the "I understand, start" button stays. Is that the right place for it, or should it be the first thing on a screen of its own?
3. Should the comfort switches (Intros, Captions, Move guide, Screen shake, Reduce flashing) stay on the Start screen, or move to Options with a one-line summary on Start?

# What the stance layout needs from UI: costs and data (a note, nothing built)

Owner: UI & UX. Date: 2026-10-05. Answers the EP's brief after Orb's stance layout (`docs/ep/vision.md` 2026-10-04 and 10-05; `docs/design/melee-press-feel.md` section 10; `docs/ep/stance-answers-2026-10-04.md`; the move generator's shape in `docs/combat/pending/movegen/`). **No code, no data files, no edits outside this note.** Sizes are working sessions of this director's own: **S** under half a day, **M** a day or so, **L** two or three. Every number is a guess to be corrected when the data lands.

## The layout in one line

Five stances by what is held (nothing = martial arts, LB defensive, RB energy, RT charging, LT manoeuvre), and four face buttons that read by stance: X quick, Y strong, A context, B signature. Hybrids (LT+RB, LB+RB, LT+LB) are reserved. The held-stance actions already exist in the data as `guard`, `mode` (now "Energy"), `power` and `dodge`, so the glyphs for the stance buttons are the layouts' own bindings with no new action; what is new is that the face buttons mean something different in each stance.

## What stays, what goes

- **The old four stance chips** (PRESS, GUARD, DODGE, ESCAPE on the plate and in the prompt row) are the retired model. They become the five stances, or go (see 2).
- **Brawler** is retired (answer 28, migrating a saved choice to Arena): its legend scheme, its settings choice and its transform wording go with it; Controls does the migration.
- **Remap** needs nothing new: the actions it lists are the same buttons.

## 1. The key help for five stances by four face buttons

**What it is.** A live legend and a matrix. The legend (the control hints in a player's column) shows the four stance buttons once (hold LB, RB, RT or LT, each with its word) and **the four face buttons as they read in the stance being held right now**: nothing held, "X light strikes, Y heavy strikes, A grab, B signature"; holding LB, "X check, Y push, A reversal, B counter", and so on. It is the same rows as today, so it costs no more column height (about 11 rows). How to play's controls page gets the full 5 by 4 matrix as a table (five columns; at a narrow size one stance at a time with tabs). Remap, the settings and the touch Full buttons keep their words.

**Cost.** M. Touches: the legend (`UiHints`: rows become stance-aware, one more input: the held stance), How to play (a matrix page and its fit at the 15 sizes), the words as data (`ui/data/stances.json`, mine, new), tests at the sizes, docs. Runtime: none to speak of; the legend redraws when the held stance changes (a few times a second at most). Simple and touch Simple show their one-line version (the choreographer picks); touch Full labels its stance buttons.

**Data I need.**
- **From Controls:** the final names of the stance actions and the held-stance mask (4 bits: LB 1, RB 2, RT 4, LT 8) in the fighter state the bridge reads, per fighter and for the AI too; which layouts have which stance buttons (Arena, the keyboards, touch Full; Simple has none); the Brawler migration done.
- **From Game Design:** the stance matrix as data, not only as the table in section 10: per stance and per button, an id, a short name and a ki cost (zip strike 15, zip heavy 25, zip tackle 20, step strike 5, and so on), so the legend and the move list never drift from the rules. I will read it from a file; where it lives is Game Design's call (`data/combat/stances.json` would do).
- **From Narrative:** the words, in the player's voice (the player is the fighter): five stance names and about 20 two-or-three-word cell names. I will draft them from section 10 so Narrative edits instead of starting from blank.

## 2. The stance badge

**What it is, and the decision it needs.** Two different things were asked, and the answers disagree about the first:
1. **The fighter's own held stance, as a small chip on his plate** (martial arts, defensive, energy, charging, manoeuvre; the newer button while a hybrid is held). It replaces today's stance chip. I recommend it for the player's own fighter.
2. **The rival's stance on the HUD.** Answer 7 says no HUD glyph for it unless a setting turns it on (the pose and one aura cue read it). Today's plate always shows the rival's stance chip, and the stance change pulses it, because the rival's stance is a read. **Orb or the EP decides:** keep it always (a read, as now), off by default with a setting (answer 7), or only for the player's own fighter. I will build whichever; my recommendation is **own fighter always, rival's off by default behind a setting "Show the rival's stance"**, which matches answer 7 and Orb's "easier to spot when used against you" (that is the pose's job).
3. **The choreographer's badge** (answer 22): a small badge showing the stance the choreographer has chosen for a player who has handed stance choices to it; off in Manual. A variant of the same chip with a different frame (shape, not colour), shown only when assisted.

**Cost.** S to M. Touches: the plate's stance chip and its flash; five stance icons and colours in `UiIcons`/`UiLook` (new art: a fist-in-guard shape for martial arts, the shield, the blast mark, the rising caret, the double chevron; plain shapes, inside Legal's stacking rule); the words (`stance.*`); the settings row and its test; the prompt row's old four chips go (the row keeps the weight mark and the form chip). Runtime: the same as the chip now.

**Data I need.** The held-stance mask per fighter (above); for the badge, the assist settings per slot (which stances the choreographer owns and the one it picked now), from Controls and Encounter; the five tells' wording only if a glyph is wanted, which answer 7 says no.

## 3. The beat ring (an option, off by default)

**What it is.** Orb: the beat is shown on the body, plus an optional ring in settings. The ring sits on the rival and closes on the beat point of the blow the player is timing. At the beat the striking limb sets with a glint (Animation's, not mine) and the ring finishes. Off by default; the option row is `beat_ring` in Accessibility or Controls. Reduced motion and colour-blind safe by shape: under reduced motion the ring does not shrink; it is a still ring that fills or lights at the beat instead of closing, and it is a ring and a notch, never colour alone.

**Cost.** S to M. A widget like the crown's parry and chain windows (`UiCrown`): a cached layer redrawn while a window is up (the ring's progress quantised to twentieths, so about 20 redraws a second only during a window), the option row and its test, docs. It reuses the anchor of the rival.

**Data I need (events or state, from Encounter and Combat):** for each blow of a string that the player can time, a window `{actor, target, start tick, beat tick, length}` and, on the press, a grade (early, on the beat, late) so the ring can show it landed. It is the same fact the sim already needs for "on-beat presses give skill strikes", so I need it exposed, not computed. The beat point sits inside 20 to 28 ticks (section 4), so the ring is short-lived.

## 4. The per-fighter move list

**What it is.** A screen opened from the pause menu ("Moves") that lists what the fighter can do, generated from his moveset data, so it can never be out of date (answer 30: it ships first, with the practice mode later). Stance tabs (five), then the four face buttons as columns or rows, then the moves of that cell: a name, the weight (light, heavy), which forms it can be (flurry, skill), what it costs in ki where it costs, and the stick lean that picks it ("lean away: the elbow, lean up: the rising palm" from the `quotas` toward, away, none, down, up). A move that is not playable yet (`status` waiting, a key set not yet posed) is left out; a move the fighter cannot do with a broken leg is greyed. Two players: each opens their own fighter's list. It is a list to read, not a trainer.

**Cost.** M to L, the biggest of the four. Touches: a new screen (the same pattern as Settings and Remap: a cached card, rows, scroll, pad and keyboard and touch input, 15 sizes), a loader for the moveset files (`UiMoveData`: reads `data/combat/movesets/<fighter>.json` and the parts vocabulary), a pause menu entry, tests at the sizes and with both fighters, docs. The list is virtualised (only the visible rows draw), so runtime is nothing at rest. About 250 moves a fighter across the five stances, so the screen needs the stance tabs and a scroll, not one long list.

**Data I need, and the gap that matters most.**
- **Names.** `moveset.<fighter>.json` has ids (`mv.protagonist.martial.x.01`) and attributes (`limb`, `tip`, `path`, `target`, `weight`, `forms`, `step`, `sends`, `links`, `beat`, `status`, `ground`), and **no name**. Either Combat gives each move a player-facing `name` (generated: "Short elbow to the jaw", from the vocabulary), or Narrative gives the **vocabulary** (a word or phrase for each limb, tip, path and target) and I compose it. I recommend the vocabulary: it scales to 250 moves and keeps one voice. Without either I can only show ids, which is not shippable.
- **Cells for the other four stances.** Only `martial.x`, `martial.y`, `martial.a` and `martial.b` exist; the rest need the same shape (`defensive.*`, `energy.*`, `charging.*`, `manoeuvre.*`), with the signature cells carrying a name and a tier (the B frame is generic today).
- **A cost field** per move or cell where there is one (ki), and a `lean` tag per move (the five leans are quotas now, not a tag on each move).
- **A schema** from Tools for `combat.moveset/1` so the loader can trust the shape, and a statement of which `status` values are shown.
- **The playable flag** at runtime for a leg-broken fighter (Combat's `ground` field says which moves work on the ground); that is the sim's state, passed by the bridge.

## Order, and what is cheap

| Step | What | Size | Waits for |
| :--- | :--- | :--- | :--- |
| 1 | `ui/data/stances.json` and the words, drafted from section 10 | S | Narrative's pass; Game Design's matrix file if they want it as data |
| 2 | The five-stance badge (own fighter) and the key help (legend and How to play) | M | the stance mask in the bridge (Controls) |
| 3 | The beat ring option | S to M | the beat window events (Encounter, Combat) |
| 4 | The move list screen | M to L | names or vocabulary; the other four stances' cells; Tools' schema |
| 5 | The rival's stance and choreographer badge settings | S | Orb or the EP's call on the rival's chip; Controls' assist settings |

The key help and the badge can start as soon as the stance mask exists, because they read the layouts' own bindings. The move list is the one that waits on others, and it is also the one that makes the generated movesets visible to players, so the vocabulary is the thing to ask for first. Everything above reads state and never writes it, so determinism is untouched, and every piece follows the HUD's rules: cached layers redrawn on a signature change, reduced motion and colour-blind safe by shape, 15 sizes checked in `hud_check`, headless only.

## Questions for Orb or the EP

1. The rival's stance on the HUD: always (a read, as now), off with a setting (answer 7), or the player's own only? (Recommendation: own always, rival's off by default.)
2. Does the move list ship as a pause-menu screen only, or also as a legend toggle in a fight?
3. Is the beat ring for the player's own blows only (recommended), or also the rival's, to read his blows?

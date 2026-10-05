# The key help for five stances: a plan (nothing built)

Owner: UI & UX. Date: 2026-10-05. The queue item after the badge (`stance-ui-needs.md` step 2): make the prompt row, the legend, How to play, Remap and the touch buttons say what the stance layout says, so the old four stance chips (PRESS, GUARD, DODGE, ESCAPE) stop disagreeing with the five-stance badge on the plate. **Plan only; no code or data touched except this file.** Sizes: S under half a day, M about a day, L two or three.

## 1. What disagrees today, and where the old model lives

The sim's legacy `f.stance` (0 press, 1 guard, 2 dodge, 3 escape) is still patched into `UiFighterModel.stance`. The badge reads the new mask (`stance_kind`). The old model is read in:

| Where | What it shows | Replace with |
| :--- | :--- | :--- |
| Prompt row (`UiPrompts`) | four chips, the current one filled; GUARD and DODGE carry their glyph | **five chips** (below, piece A) |
| Legend (`UiHints`, `hints.json`) | one row per action: Light, Heavy, Signature, Guard (hold), Dodge, Power (hold), Energy (hold), Context, Specials, Escape | **stance-aware rows** (piece B) |
| How to play | the idea page's "What you are doing" list of four stances (icons `stance_0` to `stance_3`); the controls page's per-action rows | a **stances page** with the 5 by 4 matrix, and rewritten rows (piece C) |
| Remap and Settings words | Guard, Dodge, Power, Energy, Light, Heavy, Context, Signature | stance names for the four stance buttons (piece D) |
| The crown (`UiCrown`) | a stance icon above the head | the five-stance icon (piece E) |
| The finisher telegraph (`UiReads`, `reads.json` `finisher_counter`) | the stance that answers each finisher: GUARD a launch, DODGE a melee, PRESS a beam | the stance that answers it **in the new model: a question for Game Design** (section 6) |
| Touch (`UiTouchControls`) | the guard button carries the shield icon; Full's words GUARD, MODE, DODGE, POWER | stance words (piece D) |
| The hub (`stance_set` event, `_set_stance`) | feeds `m.stance` | stays until the sim retires `f.stance`; the badge never reads it |

## 2. Piece A: the prompt row becomes the five-stance row (M)

**What it is.** The row under the cards keeps its job (shown for 3 s at the start and for 3 s after every stance change, always with Show prompts on, and never for an AI) and keeps the weight mark and the form chip. Its four stance chips become **five**: martial arts, defensive, energy, charging, manoeuvre. Each chip carries the stance's icon (`UiIcons.stance5`) and, except martial arts (nothing held), the glyph of the button that holds it in the player's own layout: defensive = the layout's `guard` binding (LB on Arena, Shift on the solo keyboard), energy = `mode` (RB, Q), charging = `power` (RT, E), manoeuvre = `dodge` (LT, Space). The held stance's chip is filled and edged in its colour, as now. Both players see their own layout's glyphs (the shared keyboard's differ: player one's energy is E and charging Q, player two's O and Slash).

**Room.** Five chips are wider than four. Arena (pad glyphs are narrow) fits at every desktop size; the solo keyboard (Shift, Space) fits at 1080p and needs three tiers below it: **full** (icon and glyph on every chip), then **glyphs on the held and the chips next to it only**, then **icons only** (the held chip also shows its glyph). The weight mark and the form chip keep their present rule (they drop out when the row is full). Touch has no row (`prompts[i].size.y` is 0 there), so nothing changes.

**Data.** None new: the held mask is in the model (`stance_kind`), the glyphs are the layouts' bindings (`UiGlyphs` already resolves `guard`, `mode`, `power`, `dodge`), the names are `stances.json`.

## 3. Piece B: the legend becomes live and stance-aware (M)

**What it is.** The legend (a player's column, first 12 s of a match, always with prompts on or `control_hints` "always") keeps the same rows in the same height (about eleven, no more than today's twelve) and reads them by stance:
- **Fly** (unchanged).
- **The four face buttons as they read in the stance held now:** the layout's Light, Heavy, Context and Signature glyphs with the held stance's four cell names from `stances.json` ("Light strikes, Heavy strikes, Grab and throw, Signature" in martial arts; "Check, Push, Reversal, Counter" holding the guard button; "Zip strike, Zip heavy, Zip tackle, Terrain art" holding dodge; and so on). A stance change redraws the four (a few times a second at most).
- **The four stance buttons, once:** the hold glyph and the stance name ("Defensive (hold)", "Energy (hold)" or "Energy (toggle)" by the player's setting, "Charging (hold)", "Manoeuvre (hold)").
- **Escape**, and **Transform** only while a form is ready, as now.
- The **Specials** row goes: its three specials are the charging stance's X, Y and A, which the face rows show while RT is held.
- **A stance change shows the legend for 3 s** even after its 12 s have faded, so the first time a player holds a stance button the answer to "what do these do now" is on the screen.

Simple, Simple touch and the layouts that have no stance buttons keep their present scheme (`simple-pad` stays as is: the choreographer picks the stance).

**Data.** The stance matrix as data: today `stances.json` carries the four names per stance. Game Design may later move costs and exact names into `data/combat`; the legend reads one file and does not care which.

## 4. Piece C: How to play (M)

- **A new Stances page** between Controls and Reading the fight (the card goes from three pages to four). A table: the five stances across (name, icon, the glyph that holds it in the player's layout), the four face buttons down (the player's own glyphs for X, Y, A and B, from the layout), each cell the stance's name for it from `stances.json`. At a narrow size (a phone, the 360 by 640 window) it shows **one stance at a time with the stance tabs** along the top.
- **The idea page:** its four-stance list ("Pushing the attack, hold guard, tap dodge, hold dodge and move away") is replaced by the five: "Nothing held: your martial arts. Hold a shoulder button to change stance: guard, energy, power or dodge." The copy keeps treating the player as the fighter. The 360 by 640 page has to keep fitting (it failed once when a row was added), so the replacement is the same length.
- **The controls page** rows are renamed to the stance names and the Specials row goes, with a line pointing at the new page.
- The touch list says which Full buttons are stance buttons (with Controls' answer, see 5).

## 5. Pieces D and E: words, the crown and touch (S each)

- **D, Remap and Settings words:** Guard becomes "Defensive stance (hold)", Power "Charging stance (hold)", Dodge "Dodge and manoeuvre", Energy stays; helps rewritten (for example "Hold for the defensive stance: guard, and the face buttons check, push, reverse and counter."). Full touch's button words follow Controls' final stance buttons (the EP's answer 8 said Full arms two stance buttons; I need which two and their labels).
- **E, the crown's stance icon** reads `stance_kind` (the five icons) instead of the legacy stance. The legacy `m.stance` stays in the model for the telegraph until the sim retires it.

## 6. What I need from others

| From | What |
| :--- | :--- |
| Game Design | **What answers each finisher kind in the five-stance model.** Today: GUARD a launch, DODGE a melee, PRESS a beam (with 40 Charge). Proposed mapping, to confirm or change: a launch is answered by the defensive stance, a melee by manoeuvre, a beam by energy (or by martial arts' B)? The telegraph chip and the reads data (`finisher_counter`) change with the answer |
| Controls | Full touch's stance buttons and their labels; whether the stance holds on touch are hold or latch (their answer 29: a one-shot latch) so the touch legend can say it |
| Narrative | the stance names and the four face cells in `stances.json` (my first draft), and the hold words ("Defensive (hold)") |
| Tools | nothing new (the stances schema is in) |
| Encounter | when the AI's stance mask is real (its badge reads martial arts until then) |

## 7. Tests (hud_check, headless)

- **A:** the five chips' highlight is `stance_kind`; their glyphs per layout (Arena LB RB RT LT, solo keyboard Shift Q E Space, shared keyboards' own); the three fit tiers at the 15 sizes with no overlap and the row inside its column; the 3 s show on a change; two players each see their own row; touch has none.
- **B:** the four face rows' labels per held stance and per layout; the stance rows' words and the (toggle) word; Specials gone; the row count within 12 at the 15 sizes; the legend shows for 3 s after a change; Simple's scheme unchanged.
- **C:** four pages and each page fits at the 15 sizes including 360 by 640; the stances page's table and its tabbed form; the idea page copy contains none of the old four stance names; no player-facing copy says "strategist", "director" or "intent" (the existing lint).
- **D and E:** the Remap labels; the crown icon per stance.
- All of it as the HUD's other checks: cached layers redrawn on a signature change, reduced motion and colour blind safe by shape and word, headless, a still from the web build.

## 8. Order and cost

| Step | What | Size | Waits for |
| :--- | :--- | :--- | :--- |
| 1 | A, the five-stance prompt row, with D's Remap words | M | nothing |
| 2 | B, the live legend | M | nothing (Narrative's edits to `stances.json` are data) |
| 3 | C, How to play | M | step 2 for the words; Game Design's answer for the telegraph copy |
| 4 | E, the crown icon; the telegraph chip | S | Game Design's answer on finisher counters |
| 5 | Touch Full's labels | S | Controls |

Steps 1 and 2 remove the disagreement the EP asked about and wait on no one; I would build them first and together, since the legend and the row read the same words. About three working sessions in all. Runtime cost is nil (cached layers, redrawn when the held stance changes).

## 9. Questions for Orb or the EP

1. **The face cells on screen during a fight.** The plan puts them in the legend (live, shown for 3 s after a stance change). The alternative is a strip of four chips (X, Y, A, B with the cell names) in the prompt row. The legend is cheaper and already exists; the strip is more visible but crowds the row. Recommendation: the legend.
2. **The Specials row** goes because the charging stance's cells replace it. Confirm the power layer is the same thing as the charging stance (RT held, then a face button).
3. Game Design's ruling on the finisher counters (section 6).

## Built (2026-10-05)

Steps 1 and 2 (the five-chip prompt row and the live legend; a stance's names show only where `stances.json` `_live` is true, which on HEAD is the energy stance alone, and the Specials row stays until the charging stance is live), with the finisher telegraph's answers moved to the five-stance wording (`stances.json` `_counters`). See `hud-spec.md` section 37. Not built: How to play's stances page, the Remap and Settings words, the crown icon, and Full touch's labels and armed-stance display (Controls' `docs/controls/stance-key-help.md`).

## Built (2026-10-06, the last pieces)

The crown's mark, Full touch's stance labels and the armed-stance display (section 39 of the spec). The armed state needs Controls to expose it (see the spec); the HUD shows it when the touch state and the model carry it.

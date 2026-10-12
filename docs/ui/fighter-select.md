# A fighter select: what exists, what the smallest one needs, and its size (UI & UX, 2026-10-12)

Owner: UI & UX. **Paper only; nothing here is built.** Answers Game Design's question in `docs/design/fighter-pipeline.md`.

## 1. What there is today: no select

- **There is no screen for choosing a fighter or a slot.** The match starts when the page loads, as the roster's first two ids in order (`FighterData.order().slice(0, 2)`: PROTAGONIST, RIVAL), the player on slot 0 against the computer. `hud-spec.md` lists the menu flow and the character select as "not built".
- **What exists that a select would use:**
  - **The pair is already a match input:** `SimHost.new_match(seed, ai, setup)` takes `setup["slots"] = [id_a, id_b]` (roster ids, in order), and `ai = {"p1": bool, "p2": bool}`; the host files its intro memory by the pair. Nothing in the UI sets `slots` yet, so a select is one signal away: `fighters_chosen(slots, ai)` into `main.start_match`.
  - **The roster is data** (`data/fighters/roster.json`, `FighterData.order()`); the HUD names fighters from `ui/data/fighter_names.json` and reads a readout profile per id (`readout_profiles.json`).
  - **Slot and device:** player two joins by pressing any button (the join prompt, "P2: press any button to join") and can be handed back to the computer from the pause menu; the legend, prompts and Remap are per slot and per device.
  - **The pause menu** has New match (the same pair, a new seed), How to play, Settings and Send feedback; the gate and the first-run How to play card come first on a fresh page.

## 2. What a select needs at its smallest

One card, two rows, nothing else:

| | |
| :-- | :-- |
| **Rows** | **P1** and **P2 or CPU** (a toggle on the second row: a human joins by any button, as today). Each row picks a fighter from the roster. |
| **Tile** (per fighter) | Name and title (`fighter_names.json`), the fighter's face portrait (Art's `faces`), **the lane colour as the tile's edge and its non-colour mark beside the name** (below), and one line of how he plays (new data, Narrative's to write and Orb's to mark). No numbers. |
| **Marks** | The first two keep the ring and the slash. **The third and fourth carry a chevron and a bar beside them** (Art: no four lane colours clear the rule under protan and deutan). The same marks go on the plate, the YOU marker and the edge arrow, so a tile teaches what the fight will show. |
| **Keyboard** | Left and Right choose, Tab swaps rows, Enter confirms, Esc goes back (to the gate's Settings or the pause menu). |
| **Pad** | D-pad or stick, A confirms, B goes back, X toggles the second row between a human and the computer. |
| **Touch** | A tap on a tile selects it; a second tap on the same tile, or the **Fight** button (48 dp), confirms. Tiles are 48 dp or more; on a phone in landscape four tiles fit in one row at the smallest size UI supports. No portrait layout: phones are landscape only (the turn card). |
| **Rules** | The flashing gate is always first. A mirror match (the same fighter twice) needs a second lane colour from Art, so it is off until Art has one. The hidden reference fighter (the dummy) is not a tile: a Settings row, **Show the training fighter**, adds it (so a public build shows none). |
| **Output** | `fighters_chosen(slots, ai)`; Rendering's `main.start_match(seed, ai, {"slots": slots})` does the rest. Nothing in the sim changes, and the determinism gates are unaffected (the select is before the match). |

**With two fighters** the select is only side choice and human or computer; it earns its place with the third. So the widget is a row of N tiles from the start (N is the roster), and at two it is a short card.

## 3. Size

| Piece | Whose | About |
| :-- | :-- | :-- |
| `UiSelect` (plan, draw, input for keys, pad and touch), the HUD's entry and exit, a pause-menu entry (Choose fighters), data (`fighter_names.json` gains a title, a one-line style and a mark id), tests in `hud_check` (geometry at the 16 sizes, every input, the marks, the output), a doc section and stills | UI | **about two days** |
| Hold the match until a pair is chosen (start deferred past the gate and the select), call `start_match` with `slots` | Rendering (`main.gd`) | **half a day** |
| The marks' art (chevron and bar next to the ring and slash) and the tile portraits' crop | Art | what they have already, plus the marks |
| The one-line styles | Narrative, then Orb | ten lines |

**Needs:** Art's mark set as data (ids and shapes), Narrative's lines, and Orb's ruling on whether the select shows once per session or at every New match.

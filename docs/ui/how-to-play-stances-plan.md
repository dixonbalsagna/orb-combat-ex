# How to play's stances page, and the Remap and Settings words: a plan (nothing built)

Owner: UI & UX. Date: 2026-10-05. Steps C and D of `docs/ui/key-help-plan.md`, behind the same `_live` flags in `ui/data/stances.json`, so nothing unbuilt is taught as present. **Plan only. It needs about a dozen new player-facing words (section 4), so it waits for your go on the words, as asked.** Size: M for the page, S for the words.

## 1. The page

How to play goes from three pages to four: **the idea, the controls, the stances, reading the fight.** The stances page is the five stances across and the four face buttons down, the player's own glyphs on both axes:
- **Header, per stance:** its icon (`UiIcons.stance5`), its name (`stances.json` `name`), and the glyph that holds it in the player's layout (the same bindings the prompt row uses: LB RB RT LT on Arena; Shift Q E Space on the solo keyboard; the shared halves' own). Martial arts has no glyph: "nothing held".
- **Rows:** X, Y, A, B as the layout's own Light, Heavy, Context and Signature glyphs, in that order.
- **Cells:** a **live** stance shows its four names from `stances.json`. A **not-live** stance shows what the four buttons really do today (the legend's old words: Light, Heavy, Context, Signature), dimmed, under a header tag "New moves soon". It teaches nothing that is not in the game, and when Encounter's slice flips `_live` the column fills in with no code change. (The alternative, collapsing a not-live column to a header, hides that martial arts' X, Y and B are real today. I recommend the dimmed old words.)
- **A line under the table:** "Hold a shoulder button to change stance. Let go and you are back in martial arts." On Full touch one more: "Tap a stance button to use it for your next blow, or hold it to stay in the stance" (Controls' arming rule, `docs/controls/stance-key-help.md`). On Simple and Simple touch the page says the game picks your stance for you (their choreographer) and shows no table.
- **Narrow screens (the 360 by 640 window, a phone):** one stance at a time, with the five stance icons as tabs along the top (left and right or a tap changes the tab), the held stance first. Wide screens show the whole table. Each page has to keep fitting at the 15 sizes, as How to play already does (it failed once when a row was added, so the page is built to the same height budget as the tallest existing page).

**The idea page's old four-stance list** ("Pushing the attack, hold guard, tap dodge, hold dodge and move away") goes, replaced by two lines of the same length: "Nothing held: your martial arts. Hold a shoulder button to change stance." and "Each stance changes what your four buttons do: see Stances." **The controls page** renames its stance rows by the same live rule (below) and says "Dodge (tap)" again, which the legend lost.

## 2. The Remap and Settings words

The Remap screen's action rows for the four stance buttons read by the stance's live flag, from `stances.json` (`_remap` per stance, so Orb edits data):
- **Not live (HEAD):** the old words, unchanged: Guard, Energy, Power, Dodge; the helps unchanged.
- **Live:** "Defensive stance (hold)", "Energy stance (hold)", "Charging stance (hold)", "Dodge (tap), manoeuvre stance (hold)", each with a help that says what the stance does (section 4).
- Settings: the option "Energy: hold or toggle" already says energy; nothing else in Settings names a stance.

## 3. What it costs and reads

- New: `UiHowto` gains the stances page (a table renderer with the narrow tabbed form), `howto.json` a page entry, `stances.json` the page words and `_remap` words, tests at the 15 sizes with both layouts' glyphs, docs. No runtime cost (a cached card, drawn when open).
- Reads only: the layouts' bindings (`UiGlyphs`), the held stance for the tab order, the `_live` flags.
- Tests: four pages and each page fits at the 15 sizes including 360 by 640; the table at wide sizes and the tabs at narrow; live and not-live columns; the glyphs per layout for both axes; flipping a stance live changes the column from data only; the idea page has none of the four old stance names; no player-facing word says "strategist", "director" or "intent"; the Remap labels by live flag.

## 4. The words I need Narrative to look at (my drafts, all in data)

| Where | Draft |
| :--- | :--- |
| Page title | Stances |
| Under the table | Hold a shoulder button to change stance. Let go and you are back in martial arts. |
| Full touch line | Tap a stance button to use it for your next blow, or hold it to stay in the stance. |
| Simple line | The game picks your stance for you. |
| Not-live header tag | New moves soon |
| One-liners (the page's tab captions and the Remap helps) | **Martial arts:** Your own style: strikes, throws and your signature. **Defensive:** Guard, answer his blows and push him back. **Energy arts:** Blasts instead of blows: bolts, charged shots, mines and your beam. **Charging:** Gather power for your specials and your ultimate. **Manoeuvre:** Dodge, boost and zip in and out. |
| Idea page | Nothing held: your martial arts. Hold a shoulder button to change stance. / Each stance changes what your four buttons do: see Stances. |
| Remap rows (when live) | Defensive stance (hold) / Energy stance (hold) / Charging stance (hold) / Dodge (tap), manoeuvre stance (hold) |

The stance names themselves and the cells are already in `stances.json` (Orb edits them in the voice lab). The one-liners say what a stance does in moves that exist only when its flag is live, so each one-liner is shown only for a live stance (a not-live stance shows its tag instead).

## 5. Questions

1. Not-live columns: the dimmed old words under the tag "New moves soon" (my recommendation), or collapsed to the header?
2. Words: build on my drafts now (Narrative edits the data later, as with the stance names), or wait for Narrative's?

## Built (2026-10-05)

Built on the EP's rulings: a not-live column shows what the four buttons really do today, at normal weight and with no "New moves soon" tag (the page promises nothing), and the words are my drafts in data. See `hud-spec.md` section 38. The "New moves soon" tag in sections 1 and 4 above was dropped; the page's lines are `howto.json` icon-row items.

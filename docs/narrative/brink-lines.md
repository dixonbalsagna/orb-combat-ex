# Brink lines: a short bark that repeats while a fighter stays nearly beaten

Owner: Narrative and Fighter Identity. Version 1, 2026-11-01. **Paper only; twelve drafts for Orb to mark.** Nothing is in `data/` or the game. The EP's brief: a short repeating bark for the brink, about every 20 seconds while a fighter stays on it, said by the fighter or by the one who has him there; UI's call-out ("NEARLY BEATEN", `ui/data/terms.json`) and the faint ring stand, and the lines do not repeat their words.

## 1. What the line does

The ring and the call-out tell the player **that** he is nearly beaten. The bark tells them **how it feels in the fight**, in two voices:

- **From the fighter on the brink (`self`):** he is hurt and will not say so. Grist grins and keeps swinging; Loupe denies it in clipped, cold sentences. Neither gives a speech (Legal: no final speech) and neither asks for mercy.
- **From his opponent (`other`):** Grist wants his rival at full strength and urges him back up; Loupe grades the wobble and counts it down.

Both sides are always said **to the opponent**, in a 1v1. No line mentions people, a crowd, a toll or a reward, and none repeats a call-out word.

## 2. How it would fire (for Game Design and the EP to rule)

- **The clock:** the first bark comes 20 seconds after `brink_enter`, not at it (the last stand's own line, if any, is already playing then), and then every 20 seconds while the brink lasts. `brink_exit` stops it. A fight of two minutes gets a few, not a drumbeat.
- **Who speaks:** the emitter's hash picks the fighter on the brink or his opponent each time, with the pool for that side. Over a long brink they alternate on average, so a line is not said by one voice only.
- **Silence first:** the existing limits still hold (8 seconds a fighter, 4 a minute, 3 seconds between any two, 180 seconds for the same line). With 3 lines a side, a long brink repeats a line only after the others are used; a few more per side would help if the brink usually lasts over a minute.
- **Held off** during a finisher, a last stand window and a set-piece pause, so the bark never talks over a bigger moment.
- **Data and code:** one new beat, `brink_hold`, whose lines carry `about: self | other`; the emitter tracks `brink_enter` and `brink_exit` from events (as it tracks the core stage) and offers the beat when the 20 seconds pass. That needs a small presentation-side read in `ui/core/narrative_barks.gd` (the EP's grant), a schema line for `about` (Tools) and nothing in the sim.

## 3. Drafts to mark

Mark **x** to keep, **alt** to ask for another, or type your own. Four to eight words each, short on purpose: on the brink the voices thin out (`dialogue-director.md`, act 4). Lint: 12 lines, 0 failing, no repeat of any approved line.

| id | Speaker | Situation | Line | Mark |
|---|---|---|---|---|
| BR-01 | Grist | He is nearly beaten | Still on my feet! Come on, keep swinging! | |
| BR-02 | Grist | He is nearly beaten | I'm not finished! You'll have to hit harder! | |
| BR-03 | Grist | He is nearly beaten | Legs are shaky, but my fists still work. Try me! | |
| BR-04 | Grist | His rival is nearly beaten | Hang in there! I want your best swing! | |
| BR-05 | Grist | His rival is nearly beaten | Don't quit on me now! One more round! | |
| BR-06 | Grist | His rival is nearly beaten | You've got more in you, I know it! Show me! | |
| BR-07 | Loupe | He is nearly beaten | You still haven't put me down. | |
| BR-08 | Loupe | He is nearly beaten | A few cracks. You'll need far more than that. | |
| BR-09 | Loupe | He is nearly beaten | I'm still standing. That's your problem now. | |
| BR-10 | Loupe | His rival is nearly beaten | You're barely upright. One more should do it. | |
| BR-11 | Loupe | His rival is nearly beaten | Swaying already. This is nearly over, amateur. | |
| BR-12 | Loupe | His rival is nearly beaten | Your footwork's gone. Stand still and take it. | |

**Trusted most:** BR-04 (Grist urging him back up is the point of him) and BR-09. **Weakest:** BR-03 (long for a brink line) and BR-07 (only 6 words and flat). Loupe's lines keep the voice bible: no "Pathetic", no respect shown, "amateur" as the insult; Grist never apologises and never insults.

**Questions for Orb:** (1) Should the opponent speak at all, or only the one who is nearly beaten? (2) Every 20 seconds, or less often?

# The beam answer alert (UI & UX, 2026-11-01, second version)

Orb: "engineer some way to non-intrusively alert the player on the receiving end that there is a window to fire back their own beam attack or dodge, this UI / UX element should have granular display options available to the player." Game Design has ruled the window (`docs/design/rule-of-cool-map.md` section 5, rows 40 and 41). This page is the player-facing part. The clickable mock is `docs/ui/mockups/beam-answer-alert.html` (open it in a browser; every settings row changes the scene as you press it). **The UI half is built, behind a switch that is off** (section 5).

## 1. What Game Design ruled, in plain words
- **A beam travels.** It leaves the hand and takes a tenth of a second to a full second to arrive, longer at range, longer for a bigger beam.
- **The chance to answer opens when the beam leaves the hand and closes when it arrives.** The gathering before that is only a warning.
- **Fire back** any time in the chance (answering late means the beams meet closer to you). **Dodge** only works in the last 14 ticks before arrival (a dodge made too early gets followed). A fresh guard press just before arrival is a perfect block.
- **All the alerts are view only.** They change nothing in the fight and each player sets their own.

## 2. What tells the player (seven things, each the player's to set)
| Family | What it is | Who builds it | Default |
| :-- | :-- | :-- | :-- |
| Shooter's glint | A bright spark at his hand as the beam is gathered, in his own colour | VFX | on, normal |
| The beam | It travels | the game | always, not a setting |
| Air and light | Air ripples ahead of the beam, its colour sweeps the ground, dust lifts | VFX | on, subtle |
| Sound | A low rising note that climbs to arrival, from the shooter's side | Audio | on |
| Rumble | A buzz on the controller that grows to arrival (a new kind, `incoming_beam`) | Controls | on |
| **Screen edge line** | A thin steady line in the shooter's colour at the screen's edge on his side, with a small arrow pointing in; for the target only | **UI (built)** | on, only when the shooter is off screen |
| **Caption** | BEAM INCOMING, then the answers as the player's own buttons (FIRE BACK, DODGE), and a bar that runs down to arrival with a notch where the dodge opens | **UI (built)** | off; for players who cannot hear |

Plus **Early warning** (UI, off): the same caption reading BEAM CHARGING while the rival gathers, turning into the answers when the beam leaves. It shows only what a lit hand already shows.

## 3. Rules it keeps
- **Nothing over the fighters.** The line is at the screen's edge; the caption sits just inside it. A mark that would meet a fighter's body is not drawn (it is held back, not moved or faded).
- **No fades, no flash, no pulse.** A mark is drawn or it is not. The caption, the notch and the dodge word are cuts; the bar shortens (in quarters under Reduced motion); the dodge word goes from dim to plain when its moment comes (a steady change). **One exception, Legal's:** the edge line comes in and goes out over 6 ticks (a tenth of a second) and never blinks (RL-227 term 5). That is a flash-safety onset, not a dissolve, but it is the one place a mark is not a pure cut, so Orb should know (question 4).
- **Never colour alone.** The line has a place (the edge) and an arrow, the caption has words and the player's own button marks, the bar has a notch. The line's colour is the shooter's, which the colour-blind setting already adjusts, and **never white, gold or red** (a shooter in one of those gets a blue-violet line; RL-227 terms 5 and 7).
- **Air and light stay local (RL-227 terms 1 to 4, VFX's):** they never dim or tint the sky or any part of the frame, are never a screen-wide wash, the ripple is a thin local band at the front and never over a fighter, the ground sweep is thin, the shooter's lane colour and no brighter than the beam, and dust is a light drift, not a rubble ring. The edge line has a thickness cap (Game Design names it; Thick is 10 pixels at 720p, Reduce flashing limits it to Medium).
- **Reduce flashing limits the strong settings:** Strong air comes down to Subtle, Bright glint to Normal, a Thick line to Medium. The host reads the limited values.
- **Plain words:** BEAM INCOMING, BEAM CHARGING, FIRE BACK, DODGE. No numbers, no chance of success.
- **A solid backing plate** under the caption, so it reads on any sky; its words follow Text size. **Large is clearly larger** (about 1.9 times Small); the words never go under the text floor. **Live glyphs:** FIRE BACK shows the player's own energy button (and the strike stick when the right-hand attacks are on), DODGE the player's own dodge button, from the layout they are playing (a swap, a remap, a keyboard).
- **The dodge is shown as available only inside its moment** (the last 14 ticks): before it, the word is dim; the bar carries a notch where it opens (Accessibility's finding: an early dodge gets followed, so the alert must not teach it).

## 4. The settings (a "Beam alerts" section, per player)
- **Alert set:** Calm, Standard (default), Full, Custom. Choosing a set writes the rows below for that player; changing a row turns it into Custom.
  - Calm (Accessibility's): no edge line, one caption at the fixed bottom-centre place, early warning on, glint normal, air off, sound and rumble low.
  - Standard: edge line off-screen only, no caption, all beams, glint normal, air subtle, sound and rumble normal.
  - Full: edge line always and thick, caption on, early warning on, all beams, glint bright, air strong, sound loud, rumble high.
- **Rows:** Screen edge line (off, off screen only, always), Edge line thickness, Caption (on, off), Caption size (small, medium, large), Caption place (shooter's side, bottom centre), Early warning, Which beams warn (all, charged, signature only), Glint (off, normal, bright), Air and light (off, subtle, strong), Incoming beam sound (on, off) and volume, Incoming beam rumble (on, off) and strength.
- **A row never does nothing:** the glint and air rows are listed only once VFX has them (flag `alert_vfx`), the sound rows once Audio has the note (`alert_audio`), the rumble rows once Controls has the kind (`alert_rumble`); the rumble rows are hidden for a keyboard. The whole section is hidden until `answer_alert` is on.
- **Per player:** every row has a player-two copy when two people play. **Per pad** (each controller remembering its own) is not built; it needs the host to name the device and a saved file keyed by it.
- **Strength is split, as Accessibility asked:** the visual rows (edge thickness, glint, air), the sound volume and the rumble strength are separate, so a louder sound never means a brighter flash. A "beside my own plate" place is not built (it would share a column with the legend); the bottom-centre place is the fixed one.
- **Colour presets:** the game's own Colour-blind mode; the mock previews three views.
- **More time to answer (a longer window)** is not a display setting, so it is not in this section: it changes outcomes. It can be set in solo, co-op and training; in versus only when the match setup allows it, and then it is shown to both players in the setup. Accessibility recommends a short hatched tail on the bar marked "Assist" and a line in the replay header; Game Design and Orb decide the rest.

## 5. What is built, and what each owner still owes
**Built (UI, in the tree, off):** the cue reader (`beam_charge`, `beam_window`), the edge line, the caption with the bar and the dodge notch, the sets, Reduce flashing's limit, the Settings section and its rows, per-player copies, `UiHud.alert_for(slot)` for the host. A demo: `--alert=window|charge --alertn=TICKS --alertset=minimal|standard|full`. **Switch:** the feature `answer_alert` (features.json, off).
**The cue (Encounter):** `beam_charge` `text` start or end: `actor` the shooter, `target` the receiver. `beam_window` `text` start or end: `actor`, `target`, `n` the ticks from the hand to arrival, `k` the beam's level (0 the snap, 1 to 3 the levels, 4 the signature), `amount` the ticks before arrival the dodge opens (14 when it is 0 or missing; an event has no `dodge_from` field). The end cue closes the alert at once. UI reads the cues; nothing is written to the sim.
**VFX:** the glint and the air and light, passing `alert_for(slot)` (brightness, strength). **Audio:** the note, with the volume. **Controls:** the `incoming_beam` rumble kind and the strength. **Camera:** nothing.
**Accessibility** has reviewed the first draft (`docs/accessibility/beam-alert-review.md`): this version takes its sets, the dodge notch, the early warning, a solid backing plate and the words-after-glyphs order; its split of strength into separate rows is the rows above; its hatched "Assist" tail waits on the longer-window ruling.

## 6. Questions for Orb (plain)
1. Which set should a new player start on: Standard (only an edge line when the rival is off screen) or Full?
2. Should the caption (words and the countdown bar) be on for everyone at first, then switch off once they know the game?
3. Should "More time to answer" exist for versus matches at all, or only in solo, co-op and training?
4. Legal wants the edge line to come in and go out over a tenth of a second, so it is not a hard cut. Is that fine with your no-fades rule, since everything else on this page is a cut?

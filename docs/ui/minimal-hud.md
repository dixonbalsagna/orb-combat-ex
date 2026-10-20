# The minimal HUD: nothing on, over or between the fighters (UI, 2026-10-18)

Owner: UI & UX. Against Orb's rule (ADR 0010, `docs/ep/taste.md`), Game Design's `docs/design/minimal-hud.md` and Research's `docs/research/readable-speed.md` rows 11 and 12. **Built in scratch and parked behind `features.json` `minimal_hud` (off):** `docs/ui/pending/minimal-hud/minimal-hud.patch`, which applies on main after the grey-circles park. With the switch off, nothing changes. Pictures for Orb are in `homework/mocks/ui/minimal-hud/` (private).

## 1. The audit: every element that can draw near or over a fighter in play

| Element | Where it drew | With `minimal_hud` on |
| :--- | :--- | :--- |
| **The beam struggle's tug:** track, diamond, hand rings, beat bar (and the grey rings cut earlier) | between the two fighters | **Gone.** The beams' meeting point is the gauge (VFX); the pulse is sound and rumble. The caption option below can name it at the edge |
| **The crown:** damage arcs, the brink ring, the parry and chain window rings | round each body | **Gone** |
| **The stance marker chip** over the head (the crown's) | over each head | **Gone** |
| **The beat ring** (an option, off by default) | on the defender | **Gone**, even with the option on |
| **The finisher's beat rings** (UiStruggle) | round the fighter on the brink | **Gone** (the audio tick carries it) |
| **The YOU label over the head** | over the fighter | **Gone.** The arrow at the screen's edge when the fighter is off screen stays. The rim light in his colour is Rendering's |
| **The chain banner** (CHAIN x3) and the plate's chain chip | top centre; the plate | **Gone** (a counter) |
| **The split screen's distance chips** | level with the fighters, beside the divider | **Moved to the bottom edge** of the pane, above the strip's place |
| **The incoming chip** (RUSH, CLOSING, OFF SCREEN) | at the edge of the fighters' space | **Stays at the edge, in its small form** (the arrow and the countdown, no words) |
| **The rival pointer chip** (arrow, distance, his marker) | at the left or right edge, level with the fighter; it also showed while he stood beside him (the anchor's visible flag reads false in one view; it showed in d3f1ca0e too) | **Only while he is off the screen**, judged from his position, not the flag |
| The planet ring map | bottom centre | Gone (the grey-circles park) |

Everything else already sits in the layout's columns at the screen's edges (plates, wound cards, silhouettes, the prompt rows, the legend, the bark lanes and face cut-ins, the touch controls) and in the banner slot between the plates (the hint, the telegraph chip, the sim's banners). The split divider is Camera's.

## 2. What the edge HUD keeps, and what goes

**Keeps, at the edges:**
- **The two plates, trimmed** (top corners): the name, the CPU or player tag, the brink mark, the power pips with SIGNATURE (the ready step), and ki (the CHARGE bar, moved up into the row the ego meter had). The plate's scrim shrinks to fit, so no empty band is left.
- **The wounds' readout:** the silhouette panels and the wound cards in their columns, untouched.
- **The button legend**, with B lit LAUNCH while a launch is open. The hint line, once. The rival pointer chip and the off-screen YOU arrow. The many-body markers (inactive).

**Goes from the play screen:**
- The share-lost bar: **it is on the pause screen** now, as the counts (people lost of the total, buildings, craters), never as a score and never celebrated (Legal c08). The results screen already says it.
- The planet strip. The stance chip, the ego meter (ANGUISH or MENACE) and every state chip on the plates (the weight chip, LAUNCH or RESTING, OPEN, the run's pips, HIT or GUARD, charging, hidden, trail lost, chain).

**New, optional, off by default (accessibility): Cue captions.** One short line at the bottom edge, centred, names a cue while it lasts: "Beam struggle: press on the beat" for a struggle, "He is open: press B" for an open launch for a human. Static text, no motion. Settings, Accessibility.

## 3. What I did not touch, and questions

1. **The legend is in the side columns, not at the bottom edge.** Game Design's page says the bottom edge; moving it is a layout change. The side columns are edges too.
2. **The hint** is in the banner slot between the plates (the top), not the bottom edge.
3. **Barks, face cut-ins and wound cards** sit in the edge columns and carry the voice and the wounds; the spec does not list them under "nothing else", so I left them. Say if they go.
4. **The form-ready chip** under each plate (a ready form) stays; the spec says the aura and the power bar carry it. Say if it goes.
5. **The sim's banners** ("BEAM CLASH", "PERFECT BLOCK", "REVERSAL") are words in the banner slot at the top centre. They are not on the fighters, but they are large. Narrative and Game Design own whether they stay.
6. **The launch-anywhere park's pips and rose** (not yet applied): `docs/design/launch-anywhere.md` section 9 says the lit B only. A follow-up one-liner removes the pips and the rose from the lit B when that park is on main; I will cut it then.
7. **Training's edge readout:** training has no screen yet.
8. **The greybox's help paragraphs** ("Computer vs computer demo...", the key list, "Head flashes") over the bottom are Rendering's (render/core/main.gd): they are the other half of the cluttered look.

## 4. Gates

On a fresh copy of main with the patch (switch off as shipped): `hud_check` **4,754 checks, 0 failed** (4,738 before, plus 16); `determinism` plain and `--intro --seeds=2 --ticks=900`, `hud_words_check` and `pane_check` passed. `_minimal_hud_rules` turns the switch on and checks: the crown, beat ring, tug, finisher rings and YOU label draw nothing; the toll chip, strip and ring map are not in play; the plate keeps the name and ki and drops the stance chip, ego meter and state chips; the pause screen carries the toll (and not with the switch off); the CHAIN banner is cut; the split chips ride the bottom edge; the rival pointer shows only while he is off the screen; the incoming chip is the small one; the captions are off by default, name a struggle and an open launch, and end with them; Settings lists Cue captions.

## 5. The pictures, for Orb (`homework/mocks/ui/minimal-hud/`, private)

From web exports of main (before: the demo as it stands with the grey circles cut) and of main with this patch and the switch on (after), live AI matches, Reduce flashing locked on. They are different matches, chosen for the same moment. `1-struggle-before-after.png`: the tug bar Orb circled, then the beams alone with the plates trimmed (the BEAM CLASH words at the top are the sim's banner). `2-brawl-before-after.png`: the brawl with the crown arcs, badges, plate chips and toll chip, then without. `3-full-screen-split-before-after.png`: the live pin's split view (ring map, chips beside the divider, strip, toll chip), then the split with the chips on the bottom edge. The single frames are beside them (`*-before.png`, `*-after.png`).

**Still on screen after the patch, and not UI's:** the red or blue stance badge over each head (Rendering), the soft guard and aura shells (Rendering), the thin white ring at a beam's impact (VFX: no UI layer draws on the fighters with the switch on), and the greybox's help paragraphs at the bottom (Rendering).

## 6. Round two (2026-10-19): hud_check switch-aware, the flip, and the EP's list

`docs/ui/pending/minimal-hud-on/minimal-hud-on.patch` (applies on main with minimal-hud in): **`minimal_hud` is true as shipped**, and `hud_check` passes with it on (**4,769 checks, 0 failed**; the 42 that failed were the older rules asking for the elements the switch removes). Those rules now run with the switch off, set once after `_terms()` in `_run`; `_minimal_hud_rules`, `_minimal_teach_rules` and `_cut_rules` set it explicitly and read the shipped default once. Determinism plain and `--intro`, `hud_words_check` and `pane_check` pass.

With it on:
- **The beat ring** is not drawn (it was already behind the switch; the test checks it with the option on).
- **The rush and incoming chips** are the small chip (the arrow and the countdown, no CLOSING or RUSH words), and in a split they ride the bottom of the pane next to the divider, away from the fighters.
- **The controls legend is compact.** The whole list shows only at the start of the **first** match (12 s, from the moment a human takes a fighter), on pause, and with Control hints "always". Every other time it shows only the rows that matter now: the lit B, a charge running, the held stance, a press that did nothing, the medium that stops him. In a second match it does not start whole again.
- **"Press any key to play"** is the one-line hint while nobody is playing (both fighters are the computer), and goes the moment a human takes a fighter. Plain: the words alone, no warning icon and no tutorial dots (the hint pill used to draw the tutorial's row of beat dots under every hint; plain hints, this one included, skip it).
- **Orb's hint picks (homework 6):** "Full! Let go to knock him back." the first time a charge is held to the click, and "He's open. Hit the lit button." the first time the rival misses. Each once per profile, with Control hints on, plain. The miss line shows only where the three strengths light the button (it would not be true otherwise).
- **Performance:** with the switch on the HUD has no toll chip, strip, crown, tug, struggle or ring-map layers and a shorter plate, so it draws less. I cannot count draw calls headless: Performance's layer cut with `minimal_hud` on is the measurement, and the hud_cache park is the follow-up.

## 7. The full-charge hint only where it is true, and the captions against Research's rec 18 (2026-10-19)

`docs/ui/pending/minimal-hud-hints/minimal-hud-hints.patch` (apply after minimal-hud-on):
- **"Full! Let go to knock him back."** (Orb's exact words) shows only where letting go of a full charge knocks him back: **a heavy (B) held to the click while the launcher is resting** (`brawl-second-pass.md` section 15: the same B knocks him back for the 40 s after a launch, and launches when the launcher is ready). A charged medium (Y) does not knock back, and a ready launcher launches, so there it stays silent and is not marked as taught. With the launch-anywhere park there is no rest, so it never shows there; Game Design and Narrative's line for a heavy that launches at full goes in `prompt` as a sibling and is a one-line addition when it exists.
- **Rec 18 (Comfort, `docs/research/cinematic-storytelling.md`)** against the cue captions: the captions are static text with no motion, no fade, no flash, no zoom, nothing that shakes or depends on the shake slider, and they read the same under Reduced motion and Reduce flashing; they are off by default. The one thing the rec's "nothing that changes state more than about three times a second" catches is the open-launch caption, which a B relit at every landing could blink at up to 2.5 times a second; it now holds 0.8 s after the launch closes (a check), so it cannot. The beam-struggle caption lasts the whole struggle.

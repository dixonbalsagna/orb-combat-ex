# The swing and motion sensitivity (Accessibility, 2026-10-31)

For the EP, to meet Legal's RL-213 condition 7: "Accessibility reviews it for motion sensitivity (a setting that turns the swing to a cut or a still) before it ships". Paper only. Read: `docs/world/ring-any-angle/game-design.md` §9 to §13, `camera.md` §5, `docs/camera/swing-view.md`, UI's uncommitted right-hand settings words in `ui/data/` and Controls' `docs/controls/right-hand-attacks.md`.

**What this rests on, and what it does not.** Everything below is reasoning from the numbers in those pages. Nobody has tested a swing with a motion-sensitive player. The only play evidence is Orb's, on bars and boxes with no fighters, and Orb is not the audience this review is for. The swing test in `homework/Files/swing-test` is a web export (`index.pck`, `index.wasm`), so I could not read it and I reviewed the text only. Treat every ruling as a first value to re-check with a sensitive tester before the swing leaves the demo.

## What makes a swing a motion risk

- It turns the whole ground at once, up to 60°/s on a launch (a full circle in 6 s), with ceilings of 98 and 65°/s and, once the flash reading allows, small swings at up to 240°/s. A large field turning around a fixed point is the main trigger for motion discomfort; it is the same kind of motion as turning a first-person view.
- The meteor shot zooms the whole picture about 20 times in roughly 3 s (2,700 to 53,000 wide at up to 3 e-folds a second). Zoom is a second whole-field trigger.
- The rest is small by comparison: the nudge (3°/s, 6° at most per place), the horizon turn, and the camera roll, which is not built (`CAMERA_ROLL_ON` off).
- A cut is a different risk: a sudden full-picture change, which belongs to the flash register, not the comfort one.

## Rulings

### 1. A view-side cut or still as the first answer: **yes**
- **Why.** It never touches the sim, so online play, rollback and the other player are unaffected, and a sensitive player gets relief without anyone's match changing. Camera's per-shot table (`camera.md` §5, "Legal's RL-213") is the right shape.
- **A separate setting from Reduce flashing.** Reduce flashing is about luminance; this is about turning. Someone may need one and not the other.
- **Conditions.**
  1. It is a **plain cut**, never a dissolve or fade. Today's `CUT_DISSOLVE_S` under Reduce flashing must not be used (Orb, 2026-10-18; Camera already says so).
  2. A cut counts in the flash register. A lone cut is not a flash by count; the risk is a cut stacked with the blow's flash, the whip and the explosion inside one second. The analyser reads each shot with the setting on, in **both** flash modes, at 16:9 and 4:3. If a stack fails, the cut moves off the blow, or that swing is not taken (rule 2).
  3. **Cuts are rationed.** First value, mine: view-side cuts no closer than 4 s apart outside a launch's own cut and its whip, and small swings (under 15°) are never cut but folded into the next cut. QA counts cuts a match and reports the shortest gap.
  4. The held-heading limit is **Rendering's and Simulation's** to state. I accept Camera's foot limit (`r × 0.5 × angle > 10` units) as the bound for this review, and I require that a catch-up cut falls on a hit-stop or another cut on action, never on its own.
  5. **No roll, bank or tilt under this setting, ever,** even if clip 7 passes for the default. Roll is the worst case for sensitive players.

### 2. `swingReduced` at 30°/s as the backstop: **acceptable as an internal backstop, not as a promise to the player**
- 30°/s is still a swing (a half turn in 3 s). It is a reasonable limit for the case where a shown heading cannot be held, and it is wrong to describe it in any text as "reduced" or "safe".
- **Needed for a second case Camera did not list:** a swing whose cut fails the analyser (rule 1.2). The view cannot dissolve it and cannot hold it, so the only remaining answer is to take no swing, or a slower one, in that match. **I recommend the sim flag become three-valued in data (full, slow, off) even if the first build ships only full and slow.** *Off* is the clean answer for a sensitive player: no turning, no parting of shown and sim ground, and the fight plays as it did before the swing (QA's existing baseline). Game Design and Orb decide whether *off* is offered.
- **Online.** Each player's setting crosses in the lobby and the strongest wins (on if either has it on). That is right here: the sensitive player's need outranks the other's preference. It goes in the match header with the other flags. I recommend it is allowed in ranked and online play, since it gives no advantage: Orb decides.
- **Player-facing.** The view-side setting is the row. The sim flag is set by it (reduced motion on, or the lobby), not by a second row, so players meet one idea.

### 3. The meteor shot's zoom under motion settings: **Camera's cut, held, cut back is right; the default zoom needs its own read**
- Under the setting: a cut to the widest at the release, held still, a cut back at the impact, as written. The trail carries the read, so VFX's trail must not flicker (a burning trail is a flash source) and is read with the clip.
- **The two cuts are 6 s apart, so they do not count against each other,** but each is read stacked with the launch's blow and the landing's blast (rule 1.2).
- **The default zoom is the open one.** Doubling the scale every 0.23 s is a strong expansion for anyone, and the meteor is rare (about one match in two or three). I do not rule a slower rate without a tester. I ask for it to be a data number, separate from the setting, so a read can lower it.
- If a sensitive player finds the cut jarring, the next step is a capped width (the lower tier's) held still, not a slower zoom.

### 4. Spectators and replays: **the view-side setting is the answer, and a few rules close the gaps**
- A spectator or replay viewer plays the recorded sim rate. The sim flag cannot reach them; the view-side cut can, because the shown heading is the viewer's own value. The setting is the **viewer's**, never the recorded players'.
- **Playback at faster than 1× scales the turn rate with it** (2× is 120°/s, above the 98°/s ceiling). Rule: above 1×, every swing is shown as a cut regardless of the setting. Below 1× is fine.
- **Seek, scrub and join mid-match snap the heading** (a cut). Never animate a catch-up through a swing the viewer skipped.
- **A rollback correction** over 5° in a tick is already kept out of the picture (Camera, ≤60°/s); under the setting it is a cut or a hold instead.
- Exported or shared clips bake in the player's setting at capture. Out of scope here; Tools should know.
- Owner and timing as Game Design set them: Rendering and Camera, due before a replay viewer or spectator mode ships.

### 5. The nudge's rate at half speed: **none, as written; scales with speed if ever extended; shown for everyone**
- Keep "the nudge only runs flat out, so half speed gets none". A continuous slow drift in the view is the case most like turning without having asked to; keeping it to one speed also keeps it inside the one run Orb made.
- If it is ever extended below flat out, the rate scales with speed (3°/s × speed ÷ flat out, so 1.5°/s at half) and **never rises above 3°/s.** I would add a floor of no nudge below a third of flat out, because the drift would then be a larger share of the ground's motion than anything tested.
- Under the motion setting the nudge is **shown as is.** It is 5% of a launch's rate and under 0.05 of the width a second, and it runs only in free flight. **If a sensitive tester finds it noticeable, the setting holds its shown heading for it:** that is safe, because nobody is standing during flat-out flight (the rival is out of reach), which is the condition Camera's table needs for any held heading.
- One run, at top speed, on bars, is thin evidence. It needs a second tester who is sensitive.

## UI's right-hand settings words and `right-hand-controls.md`, against what is parked

**Built (checked in `ui/data/options.json`, `data/input/layouts.json`, `sim/input/hub.gd`, `sim/input/remap.gd`):** `hand_layout`, `dpad_mirror`, `strike_style`, `brace_style`, `pad_right_stick`, each with `_p2`; swapped presets for every pad and the solo keyboard (`SimSwap`: sticks, shoulders, L3 and R3, face buttons with the D-pad); the brace button; a bindable Escape; the claw gate run on the swapped pad. That closes my rows 1, 3, 4, 6, 7 (brace and vanish) and 8. The roles are named by role (flies and defends, strikes), not by left and right, as rule 1 asked.

**Still open, in order of harm:**
1. **A setting can strand a player.** `brace_style` = "Button only" removes the flick brace, but on a pad `brace_key` is an optional Remap row, unbound by default (`remap.gd` `OPTIONAL`; `arena` has no `brace_key`). A pad player who picks it has no brace until they find the Remap screen. Same for `strike_key` and the pad Escape. **Owner Controls and UI:** ship a default control for the pad brace, or make the row open the bind prompt on selection, or dim the choice until a control is bound.
2. **Words that do not match the build.** The `hand_layout` help says the "face buttons trade sides"; the swap moves the four face-button actions to the **D-pad** and the D-pad's to the face buttons. **UI:** say that. Add to `dpad_mirror` that while the thumb is on the D-pad it is off the movement stick. Add to `brace_style` "Button only needs a brace button; set it in Remap". All three are one-line edits.
3. **"Swing" now means two things.** `reduced_motion`'s help says the split screen swaps "with a quick fade instead of a swing", and the world swing arrives with the same word. Player-facing text needs one word each (glossary rule 3, one word one meaning). I suggest "turn" for the world and leaving the split as it is. The "quick fade" also sits badly with Orb's no-fades rule. **Narrative and UI.**
4. **A row for this review.** `world_turning` with choices auto (follows Reduced motion), full, cut; help: "When the fight turns to face somewhere new, the world can swing round behind the fighters. Cut jumps to the new view on the blow instead." **UI, Camera.** The sim flag stays internal.
5. **Defaults.** Seed `reduced_motion` from the platform's own preference where one exists (the web build can read it). Ask Legal whether a motion line and its own two buttons may sit beside the flash notice on first run. **Tools, UI, Legal through the EP.**
6. **Not built yet, correctly:** the wider chord and slip windows (my row 7, first half). They change outcomes, so they stay behind a Game Design ruling and a header record. Rows 2 (the swapped thumb's capture, QA), 9 and 11 (UI's legend, how-to-play and string tables) and 12 (the checklist, mine) are as Controls reports.
7. **Localization.** UI's new words are in the tree, uncommitted. The pseudo-locale is stale for them. I refresh it on a clean export once they land, on the EP's word.

## Questions

- **Orb, with Game Design:** is *off* (no swings in the match) offered to sensitive players? I recommend yes. Allowed in ranked and online? I recommend yes.
- **Legal:** may a motion line sit beside the flash notice on first run?
- **Rendering and Simulation:** the number for how far shown and sim ground may part under a standing fighter.
- **QA:** cuts a match under the setting and the shortest gap; the cut stacked with a blow, both flash modes, 16:9 and 4:3.
- **Everyone:** one tester who is sensitive to motion, before the swing leaves the demo.

## Next

When the first swing build exists, I audit it with the setting on and off against rules 1 to 5 and add them to the P5 checklist. Idle until then.

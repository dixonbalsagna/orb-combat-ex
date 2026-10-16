# Teaching the launch: how the HUD and the first-run hint would show Game Design's ruling (UI, 2026-10-16)

Owner: UI & UX. **Paper only; nothing here is built.** Against Game Design's eleventh round (`docs/design/brawl-second-pass.md` section 14, "Finding the launch", 332557c0) and Orb's first playtest ("I couldn't quite figure out how to launch my opponent"). Marks that already exist are in `docs/ui/brawl-teaching.md` (sections 1, 2, 7) and `docs/ui/hud-spec.md` (sections 52, 58). Words follow `docs/narrative/writing-quality.md` section 0.

## 0. The finding that matters first

**Orb played a build with none of these marks on.** The run pips, the lit B, the plate's LAUNCH or RESTING chip, the legend's "launcher ready" note and the How to play line about the launcher are all behind `three_strengths` (`features.json`, off). The flag also turns the three buttons into Light, Medium and Heavy, which is a bigger change than teaching a launch needs. So Orb saw a brawl with no gauge, no lit button and nothing that says B now. The ruling's "hidden more than rare" is true twice over: the opening is short, and the marks that would show it were switched off.

**Proposal:** a second flag, `launch_marks` in `features.json`, that turns on only what the ruling needs and leaves the buttons' names alone (the marks below, the lit B, the chip, the hint). `three_strengths` keeps its own job. One new flag, off until Encounter's cues arrive (section 4), then on.

## 1. What the player sees, step by step (Game Design's five points, as HUD)

| Ruling | The HUD's part | Built? |
| :-- | :-- | :-- |
| **1. A gauge on the rival: four pips, one per point of the run; it empties as he answers** | The run on the target's plate (`docs/ui/brawl-teaching.md` section 2): four pips then a caret; each unanswered blow fills one; it clears 2.5 s after the last blow, or at once when he answers. Moved from "under the plate name" to **under the rival's plate, at the same width as the plate's bars**, 4 pips at 22 px each so it reads at fight size (it is about 2,000 px, under any threshold). | Built, needs the `blow` cue's `run` and `run_to` (Encounter) and the flag |
| **2. At four the gauge flashes and the B lights with the word "launch"** | **Full is a steady state, not a flash:** the four pips fill solid and gain a ring, and the player's B (legend row, Full touch button, Simple's Attack ring) lights with the word LAUNCH. It stays until the run breaks or the opening closes. See section 3 for why it must not blink. | Lit B and word built behind the flag; the full state is new (small) |
| **3. He lands one more blow, then presses B, or presses B as the gauge fills** (the early press is kept) | Nothing extra: the lit B is the prompt. The press is kept by the sim (Encounter). | n/a |
| **4. The opening is unmistakable** (head snaps back, arms fly open, a ring on his chest, a ping, a pad pulse) | The ring, the pose and the ping are VFX's, Animation's and Audio's. **HUD's part:** the plate's OPEN brackets on the rival for the stagger (built, `miss`/`stagger`), and a signal `haptic_requested("launch_open")` for the pad, which the host plays (Controls). | OPEN built; the signal is new (one line) |
| **5. The camera follows the launch** | Camera's. The HUD's part is the rival pointer (section 6 of this file, hud-spec section 60): while he is off the screen it points at him, and warns when he comes back. | Built this round |
| **The launcher's readiness beside the B: lit = ready; dim with a ring filling = the rest** | Section 52's steady mark (filled triangle or hollow) beside the heavy row, the plate chip and Full touch's button. **One change to ask for:** the earlier ruling is "nothing counts down in a fight", and a ring that fills is a countdown in shape. I would draw it as a **slow ring with no number**, one step a second (so under any rate), 30 s round; Game Design to confirm that this is what the ruling means. | Mark built; the ring is new |

## 2. The first-run hint

Once per profile (`UiPrefs taught`), only with Control hints on, at the first time the gauge fills for a human. Game Design's line: "Gauge full: hit, then B to launch." Narrative's rules want four to twelve words, plain, no team nouns ("gauge" is ours; the player sees four pips). Options for Orb:

| | The hint |
| :-- | :-- |
| **A** | Keep hitting, then press B to launch him. |
| **B** | Four hits in a row! Now B launches him. |
| **C** | He's open soon. Hit, then B. |

My pick is **A**: it is the action, in order. "B" is the button's name on the pad; on the keyboard and on touch the line names the button the legend shows (the word is built from the device's glyph, the way the legend's rows are), so the player looks at the lit one.

**If Orb wants a second teaching beat** (Game Design leaves the training dummy to Fighter Pipeline), the same slot can show once more at the first time a B lands as a hammer during the rest: "Resting. B only hits for now." (a hint about the launcher's rest, so the player does not read it as broken).

## 3. Why the "flash" is a steady state

The ruling says the gauge "flashes" at four. Two reasons not to make it a repeated flash:
- **Legal's rule (k06):** nothing flickers above 3 Hz, and a gauge that fills and empties in a fast brawl can refill every second or so. A *state* (solid, ringed, lit B) changes at most as often as the run does and never blinks.
- **The register:** a brightening that is a flash goes through the shared flash register, which refuses it under Reduce flashing. A steady state is not refused, so the teaching works for everyone.
If Game Design wants one bright beat at the moment of filling, it is one step up in brightness for 0.2 s through the register (not a blink), once per fill, and the steady state follows it.

## 4. What I need

- **Encounter (through the EP):** `run` and `run_to` on the `blow` cue (the target's run, 0 to 4; the brawl's run is already in the sim); `launcher_ready` / the rest's length in the bridge (built for the ready state; the ring needs the rest's total, 30 s, from data); the early B kept (their part).
- **Controls or the host:** play `haptic_requested("launch_open")`.
- **Game Design:** the ring in the rest (section 1 last row), and which of the hint options.
- **EP:** the `launch_marks` flag (section 0), and whether the marks go on with the next recorded build.

## 5. Build order and gates when the cues arrive

1. `launch_marks` flag, and the run pips, the full state, the lit B and the word, behind it (`hud_check` cases: nothing with the flag off or before the cues; the pips fill and empty; the full state is steady, with no redraw at rest; the lit B shows from the full state until the opening closes; every size).
2. The launcher's rest ring and the hint (`hud_words_check`; the hint shown once, on the first full for a human, never for the AI; fits the hint line at the small sizes).
3. The `haptic_requested` signal.
Gates: `hud_check` including `_block_toggle_rules` and `_sim_untouched_rules`, `hud_words_check`, `determinism` plain and `--intro`. All marks are under 5,000 px and none changes state twice in a second as a block.

## 6. The rival pointer (built this round; the HUD's part of ruling 5)

Orb: "I felt like I had no idea what they were doing until they rushed back at me at full speed." The pointer and the warning are in `docs/ui/hud-spec.md` section 60.

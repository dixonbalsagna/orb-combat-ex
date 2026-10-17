# The launch marks with no RECHARGING state (UI, paper, 2026-10-17)

Owner: UI & UX. **Paper only; the tree is not changed.** For Orb's note (`docs/ep/vision.md`): "I'm not a fan of 'cooldowns' and 'recharging' except in limited circumstances ... avoid strict caps", and Game Design's redesign in progress: the launcher can start and aim from any point in a string, with no hard rest. What is built is in `docs/ui/launch-teaching.md` and `docs/ui/hud-spec.md` sections 62 and 63. This page says what each mark becomes, so the change is small when Game Design rules.

## 1. The finding that makes this cheap

**Everything that talks about a rest hangs on one fact: the director sends `launcher_ready` and `launcher_rest_left`** (the model's `launcher_known`). The plate's LAUNCH / RECHARGING chip, the ring that fills round the hollow mark, the legend's "launch ready / launch recharging" note and Full touch's mark are all drawn only while `launcher_known` is true. **If the director stops sending those two keys, those four marks disappear on their own with no code change.** What is left to change is words and one rule.

## 2. Mark by mark

| Mark | Today | With no hard rest | Change |
| :--- | :--- | :--- | :--- |
| **Plate chip** (LAUNCH / RECHARGING) | Shown while the director sends the launcher's state | Gone: there is no state to show | None (it goes with the keys). The words `launcher_rest` and the two legend notes become unused data: delete them in the same commit |
| **The ring round the hollow mark** | Fills over the rest's length (`launcher_rest_total`) | Gone | None. `launcher_rest_total` and `UiFighterModel.launcher_rest_left` become unused; remove them |
| **Legend note** ("launch ready / recharging" on the B row) | While the state is known | Gone | None |
| **Full touch's mark** | A filled or hollow triangle by the heavy button | Gone | None |
| **The lit B** (from `launcher_open`) | Lit while an opening exists, and at a full gauge while the launcher is ready | **Stays, and becomes the one launch mark:** B is lit and its row says LAUNCH whenever a launch can start, which is now any hit in a string | The "ready" half of the rule drops (`gauge_full` no longer asks `launcher_ready`: it already skips it when `launcher_known` is false). What lights B is the director's `launcher_open`, sent for every moment a launch is allowed |
| **The gauge** (the run's four pips on the rival) | The build-up to the opening, full at four | **Stays as feedback, not as a gate:** a launch can start before four, so the pips say how far the string has run. Full (the steady state) can read "as strong as it gets" if Game Design makes a longer string launch harder | Words only. See question 2 |
| **OPEN** (the rival's brackets after a miss) | As built | As built | None |
| **The hint** | Once, at the first full gauge: Orb's pick C, "He's open! Press B and send him flying!" | Same text, same place. It no longer waits for a full gauge if a launch can start at any hit: show it at the first time B lights for a human | One condition: the trigger becomes the first lit B for a human, not the first full gauge (a one-line change in `_update_launch`) |
| **How to play's line** | "Get an opening, then press launch. It recharges; until then it only hits hard." | The second sentence goes: "Hit him, then press launch when B lights. You can launch from any hit." (Narrative words it) | Data: one line in `howto.json` |
| **The pad's pulse** (`haptic_requested("launch_open")`) | On the rising edge of `launcher_open` for a human | Same: it now fires at every lit B, so it may fire several times a string; Controls should rate-limit it (once a second at most) | Controls' one rule |
| **The press that does nothing** (the refused mark) | A B pressed in the rest shows as a hammer | B always launches when lit, so a B pressed unlit is the ordinary heavy: nothing to refuse | None |

## 3. What a launch from any point and an aim add

- **An aim mark** (optional, and the one genuinely new piece): while B is held or the launch is winding up, a short arrow from the rival shows the stick's direction, the way the launch will go. A shape in the player's ring colour on a dark keyline, steady, drawn only for a human and only during the wind-up, 0.3 s at most. It teaches that the stick aims, which Orb's playtest never discovered. Needs the director to send the aim as a cue field (`launch_aim`: `x`, `y`, the lean the stick holds) on the wind-up. It is a few lines in `UiHints` and one test, and I would build it once the cue exists.
- **A launch's weight, if it varies.** Orb dislikes hard caps, so if Game Design lets a launch's force fall with how recently the last one landed (a soft cost), **do not draw a bar or a countdown** (that is the cooldown again). Draw it as the lit B's ring: a thick ring for a full-strength launch, a thinner one for a weaker, in three steady steps, no word. The player learns "B is stronger now" the way they learn a charge. Needs a field on `launcher_open` (`strength`, 1 to 3).
- **What I would not show:** a count of launches, a "launches left", any timer of any kind.

## 4. Words that go and words that come

Goes: RECHARGING, "launch recharging", "launch ready", "launcher", "recharges". Stays: LAUNCH (on the lit B), OPEN, the hint's "He's open! Press B and send him flying!".

## 5. Questions for Game Design (through the EP)

1. Does the director still send `launcher_ready` and `launcher_rest_left` in any form (a soft limit)? If not, nothing in the HUD needs a switch.
2. Is a launch from early in a string weaker, shorter or the same? If it varies, I draw the ring's thickness (section 3); if it is the same, the gauge is only feedback.
3. Is the stick's aim sent as data on the wind-up (for the aim mark)?
4. Is B lit at every hit of a string, or only at the moments the director names? (It changes how often the pad pulses and how much the lit B competes with the hint.)

## 6. How small the change is when ruled

Delete the unused words and data (`launcher_rest`, the two legend notes, `launcher_rest_total`, `launcher_rest_left`, `REST_TOTAL`'s remains), change one How to play line and the hint's trigger, update the tests that assert RECHARGING, and optionally add the aim mark and the strength ring. About two files of data, three of code and the tests. Nothing in the sim is touched.

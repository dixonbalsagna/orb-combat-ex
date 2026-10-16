# Haptics: the pulse for a launch opening, and what the host does

Controls, 2026-10-16, for `docs/design/brawl-second-pass.md` section 14 (the twelfth round: the launch marks are on) and UI's `haptic_requested(slot, kind)` signal (`ui/hud/ui_hud.gd`). Rumble is output: it never touches the sim, the intent, the replay or the hash, and it is never the only cue (UI's lit B and its chip say the same).

## What was built

- **`sim/input/haptics.gd` (`SimHaptics`), pure.** `plan(kind, target, enabled, last_ms, now_ms)` turns UI's request into what to play, or `{}`:
  - a pad: `{via: "pad", id, weak, strong, seconds}` for `Input.start_joy_vibration(id, weak, strong, seconds)`, on the pad's own joypad id (`hub.rumble_target(slot)["id"]`);
  - a phone: `{via: "handheld", ms}` for `Input.vibrate_handheld(ms)`;
  - nothing on a keyboard, an empty slot, an unknown kind, the player's `haptics` option off, a pulse of no length or strength, or a second pulse for the same slot inside `minGapMs` (80).
  `numbers(kind)`, `kinds()`, `allow(last, now)` and `min_gap_ms()` are the parts. No clock, no state, no RNG: the host owns the millisecond clock.
- **The numbers are data** (`haptics` in `data/input/timing.json`), for UI's two kinds:
  - **`launch_open`: a sharp tick.** The high-frequency motor at 0.7, the low motor off, 25 ms on a pad and 25 ms on a phone. Sharp and short so it reads as "now", and different from the form prompt's soft thump.
  - **`form_prompt`: the host's old soft thump, unchanged** (0.3 and 0.3, 15 ms), moved into data and not yet read from it (the existing `_on_form_prompt` keeps its numbers; it can switch to `SimHaptics.plan` whenever Rendering likes).
  - **`minGapMs` 80:** a launch that opens twice in a breath, or a launch and a form prompt together, is one pulse and not a buzz.
- **The host's one connect** is `docs/controls/haptics-host.patch` (render/core/main.gd, Rendering's file, so a patch and not an edit): `ui_hud.haptic_requested.connect(_on_haptic)` beside `form_prompt_shown`, and a 14-line `_on_haptic` that asks `SimHaptics.plan` and plays the result. It reads the HUD's `haptics` option (the same one the form prompt reads) and host time only.

## Device rules

- **A pad:** its own motors, on the device id the hub gave that slot, so in two-player play only the player whose launch opened feels it.
- **A phone:** `Input.vibrate_handheld` where the browser or the OS has it; **iOS Safari has no vibration API**, so a Safari phone gets no pulse and relies on the lit B. That is why it is never the only cue.
- **A keyboard** gets nothing. **A slot nobody holds** (an AI fighter) gets nothing.
- **The web build:** the browser's gamepad vibration is patchy; the host treats "cannot rumble" as off and never errors.

## Proof

`haptics_test.gd` (23 checks): the data and its clamping, every device, the gap (79 ms dropped, 80 plays, a restarted clock plays), the option, a pad pulse on its own id with a second player on a keyboard, and that asking changes no intent. Gated on a clean export of HEAD with the patches: all 14 input tests, `npm test --prefix sim` (5 of 5), `tools/validate.js` (0 errors) and its self-test (7494 of 7494), render determinism plain (seeds 12345 and 4, 5400 ticks, all four runs same as the sim alone) and `-- --intro --seeds=2 --ticks=900` (15 checkpoints, same as the sim alone).

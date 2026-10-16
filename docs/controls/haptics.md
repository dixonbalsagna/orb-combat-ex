# Haptics: the pulses, one set of numbers, and what the host does

Controls, 2026-10-16 (revised the same day after Audio's numbers, `docs/audio/launch-and-tug.md` sections 1.3 and 2.4), for `docs/design/brawl-second-pass.md` section 14 (the launch marks) and `docs/design/rule-of-cool.md` section 2 (the beam struggle). Rumble is output: it never touches the sim, the intent, the replay or the hash, and it is never the only cue (UI's lit B and chip, Audio's ping and tug say the same).

## One set, and who chose what

**Audio's ear for the feel, Controls' numbers for the hardware.** The shape of each pulse is Audio's. The hardware limits are mine: a pad motor needs about 20 to 40 ms to spin up, so a pulse shorter than that is barely felt; Godot reads a duration of 0 as "for as long as it can"; two calls in a row replace each other; a phone's Vibration API has one duration per call and none at all on iOS Safari. So the data holds **steps** (a pulse and when it starts), with a floor under every length.

| Kind (who asks) | Pad: Audio's number | Pad: in `timing.json` | Phone | Why it changed |
| :--- | :--- | :--- | :--- | :--- |
| `launch_open` (UI, the launcher only) | thump (0.3 weak, 0.7 strong, 80 ms), then (0.2, 0, 60 ms) 90 ms later | **the same two steps** | 25 ms, a 60 ms gap, 10 ms (steps at 0 and 85) | nothing: it is Audio's, and replaces my first sharp tick (0.7, 0, 25 ms) |
| `struggle_pulse` (the beat, both players, 3 a second) | 8 ms | **20 ms**, strong 0.4, weak 0: a low thud | 10 ms | 8 ms is under what a motor can start; raised to the floor, kept low so it reads as the "tok-thud" |
| `struggle_surge` (a player's own surge) | 15 ms | **30 ms**, weak 0.5, strong 0.3 | 15 ms | the same floor reason, and it must be clearly stronger than the beat so a player feels their own press land |
| `struggle_lose` (the loser, once, at the end) | 40 ms | **60 ms**, weak 0.4, strong 0.8 | 40 ms | a heavy end; 40 ms at full is barely a bump on an ERM motor |
| `form_prompt` (the form is ready) | not Audio's | 0.3, 0.3, **20 ms** (was 15) | 15 ms | the floor; the host's existing `_on_form_prompt` still plays its own 15 ms until it is switched to `SimHaptics` |

**What is not mine to judge:** how these feel. The floors are from how the hardware behaves, not a measurement on Orb's pad; I have no pad here. The numbers are data (one block in `timing.json`), so Audio and Orb can change them on a real pad without code. A first test is: play `launch_open` and the three struggle kinds in turn on the pad Orb uses; if the beat is too soft raise `strong`, not the length.

## What was built

- **`sim/input/haptics.gd` (`SimHaptics`), pure.**
  - `steps(kind, device)`: the cleaned steps for `"pad"` or `"handheld"`: each `at` 0 to 1000 ms, motors clamped to 0 to 1, each length raised to `padMinMs` (20) or `handheldMinMs` (10), a step with no length (or, on a pad, no strength) left out, sorted by time, at most four.
  - `plan(kind, target, enabled, last_ms, now_ms)`: what to play, or `{}`:
    - a pad: `{via: "pad", id, steps: [{at, weak, strong, seconds}]}` for `Input.start_joy_vibration(id, weak, strong, seconds)` on the pad's own joypad id (`hub.rumble_target(slot)["id"]`);
    - a phone: `{via: "handheld", steps: [{at, ms}]}` for `Input.vibrate_handheld(ms)`;
    - nothing on a keyboard, an empty slot, an unknown kind, the player's `haptics` option off, or a second request for the same slot inside `minGapMs` (80).
  - No clock, no state, no RNG: the host owns the millisecond clock and the timers.
- **The numbers are data:** `haptics` in `data/input/timing.json` (`minGapMs`, `padMinMs`, `handheldMinMs`, and for each of the five kinds a `pad` list and a `handheld` list of steps). The schema is `docs/controls/haptics-schema.patch` (a closed block: the five kinds, at most four steps, motors 0 to 1, lengths 0 to 500 ms).
- **The host's one connect** is `docs/controls/haptics-host.patch` (render/core/main.gd, Rendering's file, so a patch): `ui_hud.haptic_requested.connect(_on_haptic)` beside `form_prompt_shown`, a handler that asks `SimHaptics.plan` and plays the first step now and the rest on `get_tree().create_timer`, and a four-line `_play_haptic_step`. Host time only; the timers touch nothing in the sim. UI raises only `launch_open` today; the three struggle kinds are in the data for UI to raise (from the cues `beam_pulse`, `beam_surge` and `beam_end`) with no further change here.

## Device rules

- **A pad:** its own motors, on the device id the hub gave that slot, so in two-player play only the player whose event it is feels it. **Only the fighter who may launch feels `launch_open`** (UI raises it for him alone).
- **A phone:** `Input.vibrate_handheld` where the browser or the OS has it; **iOS Safari has no vibration API**, so a Safari phone gets nothing and relies on the lit B and the chip.
- **A keyboard** gets nothing. **A slot nobody holds** (an AI fighter) gets nothing.
- **The web build:** the browser's gamepad vibration is patchy (Chromium has it); the host treats "cannot rumble" as off and never errors.

## Proof

`haptics_test.gd` (34 checks): the five kinds, Audio's launch shape step for step, the struggle's three and the floor (8 ms raised to 20, 4 ms to 10), the floors as data, a step of no length or strength left out and never passed as 0, ordering and the four-step cap and clamping, a malformed list falling back, every kind on both devices, the gap, the option, a pad on its own id with a second player on a keyboard, and that asking changes no intent. On a clean export of HEAD with both patches: all 14 input tests, `npm test --prefix sim` (5 of 5), `tools/validate.js` (0 errors) and its self-test (7415 of 7415), and render determinism plain and `-- --intro --seeds=2 --ticks=900` (each same as the sim alone). The schema was also checked to reject a motor over 1, an unknown key and a fifth step.

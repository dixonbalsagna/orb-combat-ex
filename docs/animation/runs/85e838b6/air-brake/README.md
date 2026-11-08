# Air-brake looks: the real side-by-side (Animation, 2026-11-07, run on main 85e838b6)

A is main (85e838b6). B is main plus `docs/animation/pending/air-brake-looks.patch` (with `exit_ticks` 5) and its schema patch. Both builds are scratch web exports with `data/fight/brake.json` switched on, as the stack does for Orb's build (main has it off). The picture is the real renderer, the real sim and the real pad path.

## What was filmed

A real launch (`DirLaunch.doLaunch`, plan SMASH ACROSS, force 2,200, the second fighter sending the first, 250 units up), with LT held through the pad path from tick 2: the sim's own air brake starts at tick 16, ends by speed at tick 31 (control back at about 430 u/s, 900 units up). 20 frames a second, played at half speed in the GIFs, the real left pane cropped round the fighter. Both fighters (the Protagonist, then the Anti-hero knocked back).

| File | What |
| :--- | :--- |
| `brake-protagonist-seg0-AB.gif`, `brake-anti-hero-seg0-AB.gif` | A beside B, LT lit while held |
| `sheet-*-high-send-A-over-B.png` | the same as contact sheets, A over B at ticks 19, 28, 34, 40, 46, 58, 76, 100 |
| `legal/air-brake-hand-stills.png` and `legal/ax.*.png` | `ax.plant_p.hold`, `ax.plant_r.hold`, `ax.regain_p.open`, `ax.regain_r.open` drawn as authored by the real renderer, the figures scaled 3x, hands visible (RL-255 (6)) |

## What the pictures show

- **A**: the knocked-back fighter flies laid out head first, the brake changes little of the silhouette, and after control returns he hangs upright and stiff.
- **B**: the first brake tick drops him upright into the plant (a leg thrown out ahead, one arm pressed out ahead, the other back), he stays braced as the speed falls, then comes up out of the lean over about 10 ticks, tucks, and sweeps into the guard, facing the foe throughout.
- The hand stills show the Protagonist's hands open (blades) and the Anti-hero's closed, on all four poses. Neither fighter carries anything; the plant's rear hand is at height 27.7 (below the shoulder), the lead hand at 65.3.

## Not proven here

- **The skid landing.** A second staged send (low, fast, 4,500) was filmed too, but the fighter crosses the camera in the first ticks and ends the brake in the air, so it is not a clean A/B and is not shipped. A real landing out of the brake needs a staging where the brake is held until he meets the ground; the solve strips (`art/animation/review/air-brake/skid-landing-*-AB.png`, stick figures) are what shows the landing so far. Owed.
- **Flash gate.** Nothing in the patch adds light; the analyser was not run on these clips.
- **Fight camera.** The clips are the split-screen view the capture build gives with the fighters apart; the fight camera's own framing of a knockback is Camera's.

## Longest brake

36 ticks with ki, 72 with none (`sim/core/brake.gd`); set against RL-218's 68 in `docs/animation/creative-rulebook.md` as a rulebook call.

# Parked: the KO shot and a finished fight's winner in a 2v2 (cross-ko)

Camera, 2026-11-07, for the EP's two 2v2 items:
- **The KO shot.** A first KO no longer ends a 2v2, so its shot shouldn't treat it as the match over.
- **The focus ease.** A winner's focus moves across to the other fight once his own is finished, eased over about 12 ticks (Game Design), and he may rush most of the way round the planet.

Both are one park, because the second starts where the first ends.

**Apply on main** (cut on 7e74b8e9; `git apply --check --cached` passes on 85884449): `git -c core.autocrlf=false apply cross-ko.patch` (sha1 0a9fb8be).
- **The two-fighter ratchet goes down by 2** (main 367 to 365; split_rig 43 to 41). The KO shot's four "which slot is the KO'd body" lines, main's two and the park's new ones, take it from the list (`_ko_slot`, `S.fighters.find`), with the same answer.
- Files: `render/camera/split_rig.gd`, `render/camera/camera_params.gd` and a new `render/camera/tests/cross_ko_check.gd`, all mine.
- **Behind the cross switch** (`S.stage.cross`): in a 1v1, or in a two-fight match without cross, nothing changes.

## What it does

| When | What you see |
| :--- | :--- |
| **A first KO in the fight on screen** (his team still stands) | The loser's close-up, as today, once. It doesn't go on to the wreck: that shot is the match's end. At `WRECK_AT` it hands back. The close-up holds the screen two ticks more while the new layout settles behind it, the winner's pane opens already on him at his own size, and the split eases back |
| **Then** | The winner's pane takes the screen, eased (the solo `across`). The KO'd body is out of the match and isn't framed, so no half of the screen is spent on him until the rejoin. The winner's anchor starts where he is in his pane and eases to the solo's rest, as a launch's does |
| **His focus across** (`DirOutside.focusAcross`) | His framing leads toward it by `ACROSS_LEAD` (0.12 of the width). The lead eases at one whole lead every `FOCUS_EASE` (0.2 s, Game Design's 12 ticks), so a turn round goes through the middle. It falls away as he closes on the target (none within `ACROSS_NEAR`, 150 units; all of it from 1,500), so a target passing him doesn't flip the frame |
| **He flies across** (a computer winner at once; a player's press) | His pane follows the rush, at the chase's limits. **While he flies faster than `ACROSS_WIDE_SPEED` (10,000 units a second), the scroll governor may take him as wide as `ACROSS_WIDE_R` (0.02 of the height, 14 px at 720p)**, and his pane opens at that size if he's already flying at the hand back. A rush moves a body with no velocity, so the pane's speed is seeded from the rush. It's wide while he's really flying, as a flat send's, and readable again within a second of his stopping (the readable rule) |
| **The rejoin** (Simulation clears the fight's KO) | The solo ends and the layout eases back to the new pair |
| **The match ends in the other fight** | The final shot, the wreck, round the fight on screen's winner |
| **A KO in the other fight only** | No shot here |
| **The peak shot** | Gives way only to a KO that ends the match (`_ko_ends`). A finished fight's winner can still be sent flying from outside |

No cut and no fade anywhere in it. The only cut seen in the runs is the rig's own `side_swap`, made while one pane has the whole screen, so the divider it flips isn't drawn.

## Proof

| Run | Result |
| :--- | :--- |
| `cross_ko_check` (new), with the park | 21 of 21 |
| `cross_ko_check` on main's rig (negative control) | 6 fail: main plays the wreck on a first KO, cuts once (`solo_cut_in`), and never gives the winner the screen |
| `clip_digest`, a 1v1, main against the park | byte-identical |
| `split_sweep`, with the park | passes |
| **Flash register**, the staged 2v2 KO, every tick 2 to 480 (the KO, the close-up, the hand back, the winner's takeover), both modes | **PASS 0.5 / 0.5.** Main reads 2 / 2. The first cut read 3 to 4 (FAIL): the winner's pane opened at fight size on a body rushing through a city at 20,000 units a second, with towers streaming across it. The wide flight above is the fix |

**The check's cases:**
- A first KO, then the match's end in the other fight.
- A KO in the other fight only.
- The rejoin.
- The switch off.
- A computer winner flying across with blows from outside on.

It reads:
- the picture's jolt of a pane shown on both ticks, outside a cut (0.06), and 0.30 within 10 ticks of a rush's start or stop, as a launch's release in `launch_shots_check`;
- 0.10 through a rush, as `chase_rush_check`;
- the winner out of his own picture from the hand back: at most 15 ticks;
- the lead's ramp: about 12 ticks.

**Readings:**

| Case | Jolt | Out of picture | Lead ramp | Cuts |
| :--- | ---: | ---: | ---: | :--- |
| First KO (a player winner, standing) | 0.015 | | | none |
| The rejoin | 0.015 | | | none |
| The flight (78,000 units) | 0.026; 0.015 round the rush's start and stop; 0.046 through it | 1 tick | 11 ticks | `side_swap` 1 (hidden) |

## Look gate

`docs/camera/img/cross-ko/` holds the side-by-side of a staged 2v2 KO on the web build. **Main is on the left (blue bar), the park on the right (orange).** Seed 12345, planet 7, tiles; slot 2 falls to slot 1 at tick 40, and slot 1 is a computer winner who flies across.

The files:
- `cross-ko.gif`: ticks 30 to 756, every 6th, 10 fps.
- Stills `t00330.jpg`, `t00370.jpg`, `t00420.jpg`, `t00560.jpg`.

What they show:
- **Both builds show the loser's close-up** (tick 330).
- **Main** then plays the wreck, the match-over shot, on the winner, though the match goes on.
- **The park** eases from the close-up through the split (370: the winner's pane opening at the left, already on him) to the winner alone (420), and follows him out over the sea (560).
- No cut, no fade, nothing over the fighters.

How the clips were made:
- Captured through `tools/machine/capture.mjs`, one at a time, HUD off (`nohud`).
- **A scratch scene only** (`ko2v2` in the hook: two fights, cross on, outside forced on, the KO staged; never a park).
- It holds `host.paused` off, because UI's match-over card opens at the first KO and pauses the game. See RISKS below.

Flash: both modes run on the register, above.

## RISKS

- **UI's `cross_end` feature is off in `ui/data/features.json`.** With it off, a first 2v2 KO is read as the match's end, and the match-over menu opens and pauses the game. Two fixes:
  - UI's switch on with cross; or
  - the host asking `SimCore.ended(S)`, as cross-end's README asks.

  UI's call.

## Found, not changed (not mine, or main's in a 1v1 too)

- **The KO close-up's own start can whip** when the KO blow launches the loser: a 0.157 jolt on its first tick in the flight case. It's main's code, the same in a 1v1. The brief keeps a 1v1 unchanged, so it's measured and left.
- **A computer winner leaves during the KO's moment** (Encounter's `DirOutside.aiRescue` presses on the KO's tick). So he's 6,000 units off when the close-up hands back, and his pane opens on him there. Game Design's ruling for a player winner is "once the finisher has played out and he's had his moment standing in the wreckage". If that's meant for the computer too, it's Encounter's change.
- **The other fight isn't drawn** (RL-249: drawing the partner's fight is for later). His lead points at a target that isn't on the screen until the bodies meet.

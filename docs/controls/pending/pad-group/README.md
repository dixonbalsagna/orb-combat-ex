# pad-group (park, on HEAD 51b840f5): A-CONTROLS-02, the pad as Orb plays it, made main's data

Controls, 2026-11-14, sprint A1 wave 2. First of GW1a's switch groups. **No new input behaviour:** eleven input switches that main ships off and the 9 November build played on become `true` in `data/input/timing.json`, and the tests that were written against the old defaults pin them with their reason. Records: `docs/controls/runs/51b840f5/` (CD-22).

## Apply

`git -c core.autocrlf=false -c core.eol=lf apply docs/controls/pending/pad-group/pad-group.patch` (four files, all Controls' paths):
- `data/input/timing.json`: `bNoBeam`, `bNoBeamKeepRt`, `chargeLostCue`, `chordPick`, `dashHandover`, `dodgeHeld`, `driverOnRb`, `flickKept`, `flightStrikeB`, `hapticStages`, `inertKnock` false to true. 11 lines, no shape change, no schema change.
- `sim/input/input_data.gd`: `pin_switches_off()` gains `hapticStages` (it was the one input switch the pin list never needed while the data kept it off).
- `sim/input/test/push_stick_test.gd`, `refusal_cue_test.gd`: pin `hapticStages`, `flickKept` and `chargeLostCue` for the checks that are of the older path, each with its reason in a comment.

The grant for `data/input/timing.json` is the EP's, by the brief. No other file.

## What it proves (all saved under `runs/51b840f5/`)

- **timing.json is the kept build's, byte for byte** (sha256 `59841511...`). The eleven keys above were the only keys that differed (`pad-group-data-compare.txt`). **`sim/input` at HEAD is byte-identical to the kept build's**, every file.
- **All 45 input tests pass** on the new defaults, with no test left pinned without a reason (`pad-group-input-suite.txt`). Control: with only timing.json flipped, 4 of 45 fail (`...-control-no-pins.txt`), which is why the patch carries the pins.
- **Golden (a), the pad group alone:** `golden.gd` on HEAD + this patch is **byte-identical to main's own golden**. So these eleven switches do not move the golden's nine matches or two replays (measured; I did not trace why, the likely reason being that the golden's recordings bypass the layout and never press the inputs the switches change) (`pad-group-golden.txt`).
- **Golden (b), the composition:** HEAD + this patch + the kept build's whole `data/` + the two energy words (GW1a's recipe) is **byte-identical to Simulation's target** (`a2b9ed1c...`, 184,833 ticks). So the pad group's data is complete and right, and `sim/input`'s code does not move the record.
- **The same actions:** a scripted pad through the real hub (`audit_probe.gd`, 136 cells: movement, the left hand, every face button by every layer, the right stick's flicks and holds by layer) gives the **same output on the composed tree as on the kept build: 0 of 136 differ**. Control: with main's old timing.json, **54 of 136 differ** (`pad-group-audit-same-actions.txt`).
- Lint (`lint-determinism`) and the validator pass on the patched tree (321 files, 0 errors). The patch applies on a clean `git archive` of HEAD and reproduces the tested tree byte for byte.

## Not done, and why

- **The side-by-side (ADR 0010) is not run by me:** no browser of my own, and captures go through Tools' launcher. Nothing is meant to look different and the proof above is stronger than a still: the pad's code and data are the kept build's, byte for byte. If the EP wants the stills, Tools runs `tools/flash/side-by-side.mjs` on the composed tree.
- **Not run:** `parity.gd`, the director checks and `hud_check` (the EP's gate runs them). `ui/tools/hud_check.gd` lines 37 and 38 pin `driverOnRb` and `dodgeHeld` false with the comment "Controls leaves this one off in the shipped data": the pins still work, the comment will read stale (UI's file).

## Rows to take out of the page's table once this lands (Tools' `tools/preview/switches.mjs`; I name them)

Rows whose only key is in `data/input/timing.json`, which main then carries: `bNoBeam`, `bNoBeamKeepRt`, `chargeLostCue`, `chordPick`, `dashHandover`, `dodgeHeld`, `driverOnRb`, `hapticStages`, `inertKnock`, and `stallKeep` and `hapticImpact` (main already had them on). Rows whose other keys stay (the row stays, my `more` key becomes a no-op): `flightStrikes` (`flightStrikeB`, `dodgeHeld` in its `more`) and `flickKeep` (`flickKept` in its `more`).

## The rest of the pad is not mine: rows for other owners (GW1a's other groups)

- **Encounter, `data/director/`:** `driver`, `beamMove`, `beamMoveAi`, `strikeStages`, `lightStops` (true to false), `flickKeep` (with `pendFollow`), `flickRun`, `fullSend`, `stickLungeLight`, `flightStrikes`, `stances`, `refusedCue`, `pushMode`, `arrive`, `carryRound`, `sideFromBlowOnly` (`launch.json`), `paceMatch` (`ai.json`, the computer opponent's group).
- **Simulation, `data/fight/` (no owner line in my brief):** `slip` (`power.json`, with `power.json` `enabled` and `dash.enabled`, the page's two energy words), `airBrake` (`brake.json`), `hitstopAny` (`hitstop.json`).
- **UI:** `pushUi`, `pushUi2` (`ui/data/options.json`), `fullSend`'s `slam_hint` feature, `menusRail` (`ui/data/features.json`).

## A pad that is not a safe place to stop

Three of the eleven pair with a row in another group. **Until those land, a build from main is not the game Orb played:**
- `dashHandover` needs `arrive` and `slip`: handover alone makes close taps and 6 to 11 tick presses fly past the rival (`docs/controls/dash-handover.md`).
- `flickKept` needs `flickKeep` (Encounter): alone the hub waits 120 ticks before it says "no answer" while the director keeps nothing.
- `hapticStages` needs `beamMove` (Encounter): alone the hub's own ladder pulses step aside for cues that are never sent, so a long charge pulses nothing.

So the pad group should land in the same window as Encounter's director rows and Simulation's three, which is GW1a's own order; it is not a point to build or play from.

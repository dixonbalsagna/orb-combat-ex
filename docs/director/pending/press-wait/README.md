# Parked: a press waits for the blow in hand, and a hold builds while it waits

Encounter, 2026-11-02, on Game Design's `docs/design/press-decides.md` sections 3 and 5, from Orb's second play: "hard to charge up an attack when every hit seems to interrupt". Read: `../../second-play-read.md` section 3. **Behind its own switch, off:** `data/director/interrupts.json` `brawl.pressWait.enabled`. Sections 3 and 5 share it, as Game Design ruled.

**Apply second, after `../charge-close/`:** `git -c core.autocrlf=false -c core.eol=lf apply press-wait.diff`. It doesn't apply alone.

**This replaces the earlier press-wait,** which kept a press through a stun. Game Design ruled a stun clears it.

## What it does

| | Off (today) | On |
| :--- | :--- | :--- |
| A press made while his own blow is going | Waits 10 ticks, then is thrown away | **Waits for that blow.** One slot, the newest wins. `maxTicks` 600 is only a backstop |
| A B held from during his own blow | The press lapses, and **the hold comes to nothing** | **The press goes when he's free, and the hold has built since the press** |
| A stun | | **Clears the waiting press,** with the cue `press_ack stunned` |
| A press made in a stun | Gone, with nothing said | Still gone, **but told:** `press_ack stunned` |
| The brawl ends | | The slot is cleared |

**In Orb's second match:**
- 161 of about 670 presses lapsed, all of them during his own blow or its recovery.
- Of his 10 holds of 32 ticks or more, **all 4 that began during his own blow came to nothing.**
- 144 presses were made in a stun.

## A press made in a stun: told, not kept

Game Design rules it's cleared. I agree, with the cue: a blow that fires after a stun the player has forgotten reads as the game pressing for them, and `press_ack stunned` tells them why nothing happened. UI and Audio need the cue to be seen or heard.

## Read

`press_decides_check`, on an idle dummy:

| | Off | On |
| :--- | :--- | :--- |
| B held from during Y's wind-up | Lapsed; no charge | **Didn't lapse; the full flash 44 ticks after the B** |
| A stun while a press waits | | Cleared and told; no blow thrown |
| A press in a stun | | Told |

## The masher (taken on the earlier variant, which kept a press through a stun)

QA's masher against the medium AI, 30 matches an arm: X every 8 ticks won 8 of 30 off and 11 of 30 on, inside the noise; **Y every 8 ticks won 30 of 30 both ways,** which is QA's and Game Design's finding with or without this. QA should read its 100-match row on this variant.

## Proof

All six parks gated together: with every switch of mine off, Orb's second match reproduces all 40 checkpoints and its final hash c130250f9f984886. Golden byte-identical, validate (302 files), self-test 9,977. With every switch on: determinism on the field, rollback, `two_states`, and `press_decides_check`, `beam_front_check`, `stick_check` and `chase_tap_check` at 0 failed.

## Grants, given

| Whose | What |
| :--- | :--- |
| Controls' | `sim/input/control.gd`, 2 lines: a stun's press reaches the director before the stun clears it, so it can be told |
| Simulation's | `sim/core/dir.gd`, the forward `pressInStun` |
| Tools' | the switch: `{ id: 'pressWait', file: 'data/director/interrupts.json', path: ['brawl', 'pressWait', 'enabled'], from: false, to: true, needs: [], optional: true }` |

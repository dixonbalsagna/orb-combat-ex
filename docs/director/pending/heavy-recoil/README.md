# A clean tapped heavy recoils him (parked, 2026-10-23)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 1a and `rulings-2026-10-23.md` §1, with the sim's own pi in the director (the EP, after `SimMathx.PI` landed in 74ee6b04).

The recoil sits behind `recoilFlip.enabled` (false on main) and its `heavy.enabled`. Off, the heavy staggers in place as today, the AI's flip shares aren't read, and the golden doesn't move.

## To build it

On main (74ee6b04 or later: the recoil flips, `SimMathx.PI`): `node hr.cjs <root>` from this folder. `--check` reads every anchor and writes nothing. It composes with the calm turn's 7b, the wall kick, the chase and balance-19 in that order. Its new slot `RC_BSL` makes `RC_N` 9, and every slot block after the recoil flips' follows by its base.

| File | Change |
| :--- | :--- |
| `sim/director/recoil.gd` | `RC_BSL` (the slide's live ticks left). `heavyRecoil`: a clean tapped heavy in a brawl recoils him `heavy.bh` (1.5) body heights as a slide of `heavy.ticks` (8), in place of the stagger. A wall behind him shortens it. It opens the flip's window: kind 4, the flip allowed while locked in the brawl. With no flip he reels `heavy.reelTicks` (6) at its end. The recoil cue says `exit` (a backflip fitted to the slide) |
| `sim/director/brawl.gd` | `_bigLanded` calls `heavyRecoil` before the stagger. In `_throw`, the counter-rush out of a flip closes the gap at once |
| `data/director/interrupts.json` (`recoilFlip.heavy`), its schema (**Tools'**) | `heavy` {`enabled` true, `bh` 1.5, `ticks` 8, `reelTicks` 6} |
| `data/director/ai.json` | GD 2026-10-23 §1: the AI's flip shares 30, 60 and 85% (were 20, 45 and 70) |
| `sim/director/beamplay.gd` (3), `launch.gd`, `zip.gd`, `calm.gd` | `SimMathx.PI` in place of the engine's `PI` (and calm.gd's own copy): the same double, so nothing moves |

## What it read (main 555dd367 plus 1a, in scratch; 10 AI v AI matches, 23.5 minutes, recoilFlip on in memory)

| | Heavy recoils | Flips (after a heavy's recoil) | Flips a minute | Counter-rushes |
| :--- | :--- | :--- | :--- | :--- |
| Before 1a (2026-10-22's recoil-flip read) | none | | about 0.3 | |
| **1a** | 58 | 20 (15) | **0.85** | 6 |
| **1a with the shares at 30, 60 and 85%** | 61 | 32 (25) | **1.37** | 11 |
| recoilFlip off | none | none | 0 | 0 |

**GD's AI-play band (1.5 to 6 a minute) isn't reached, even with the share rise:** 1.37. A flip comes from a knock-back, and the AI lands few clean heavies. The next lever is Game Design's: more knock-backs, or higher shares again.

- **Animation:** the exit cue's backflip runs over the 8-tick slide; Animation's recoil flips are re-cut for an 8-tick backflip (cca8e6dd).
- **Gate list** (switches off, 1a without the share rise and the pi swap): **35 of 35 at 0**; the golden is main's, byte for byte. The share rise is data the AI reads only with recoilFlip on, and the pi swap is the same double, so both are behaviour-identical. On 74ee6b04 the whole script applies and validates (245 files, 0 errors).

## Probe (`probes/rcp.gd`, from a copy's root)

`rcp.gd -- <matches> <seed0> [--ticks=10800] [--off] [--flipUp]`. It reads:
- knock-backs by kind, heavy recoils, flips by kind and fighter;
- the ticks from a knock-back to its flip;
- counter-rushes, flips a minute, and a sample.

`--flipUp` sets the shares in memory.

# Parked: a stick throw that fired no beam doesn't aim the next one (the third stray beam; GW1b rider)

Encounter, 2026-11-14, sprint A1. The stand-in read it from code in the beam-in-space trial design (`beam_aim.gd:79-80`, `stick.gd:799-808`), and a probe confirmed it. **Off on main's data (the stick's aim, `beamPlays.front.aim`, is off), so the golden doesn't move.** It acts once the 9 November rows are main's (GW1a), like the other stray-beam fixes.

## What happened

- At every stick release `DirBeamAim.thrown` keeps the stick's direction (`B_THROW`). Only a beam's fire uses it, through `DirBeamAim.wide`.
- A release that fires no beam never clears it: refused for ki, refused late, or dropped by stray-beams' `dropOnPress`. So the next beam to fire reads the stale aim, and if it's more than the assist off the line to the rival, it fires wide.
- The next beam can be a signature from RT + B, which is always aimed at him.

**Confirmed by `aim_throw_check`:** a stick hold aimed straight up, let go without the energy for a stage (refused, `ki`), then RT + B. With the throw read as before, **the signature fires wide, straight up.**

## The fix

The throw belongs to the beam its release starts.
- **Binding:** when that release starts its beam's exchange (`DirBeamMove.tryFire`, and `DirBeamPlay.fromStick` on the older path), the throw is bound to it. The exchange's index goes into the throw slot's spare bits, so there's no new slot and no other module's slots move.
- **Using:** `wide()` uses only a throw bound to the exchange firing now. Any other throw is dropped, and the beam is a shot at him, as a signature always is.
- **Off:** with the aim off nothing is written (`bind` returns at once), as before.

## Apply

On main b0e20f9a (GW1a), after `../stray-beams/` in the GW1b order: `git -c core.autocrlf=false -c core.eol=lf apply beam-aim-throw.diff`.

**Re-cut for B-17 (2026-11-21):** `aim_throw_check` presses RT on the tick it fires the signature with RT held, as stray-beams' four checks now do. With GW1a's data and stray-beams' RT window, its B was otherwise the heavy and three of its rows failed.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `beam-aim-throw.diff` (re-cut for B-17; the first cut was 43a450db): `sim/director/beam_aim.gd`, `beam_move.gd`, `beamplay.gd`; the new check `aim_throw_check.gd` | Encounter | 624485ae0a42632fce4b3fe9da22039b02667716 |

## The check

`aim_throw_check.gd`, 4 checks, with the beam's own move and the stick's aim on:

| Row | Result |
| :--- | :--- |
| **Negative control** (the throw read as before): a refused release aimed up, then RT + B | the signature fires wide (Orb's kind of stray beam) |
| Fixed: the same | the signature fires at him |
| No refused release first | the signature fires at him |
| A stick beam aimed up that does fire | still goes up, wide: the throw is its own |

## Proof

The gates ran on main def3445a plus this park. Records are in `docs/director/runs/def3445a/beam-aim-throw/`, and every output went through `tools/gate.mjs` with no SCRIPT ERROR.
- On main def3445a the golden didn't move. **On the GW1a data no gameplay row moves** (every match's and replay's gameplay digest is the same), but one full-state checkpoint each in matches 0 and 7 differs (checkpoints 117 and 61). The re-record in GW1b takes it with the others (`docs/director/runs/b0e20f9a/b17-lane/`).
- Validate 0 errors; self-test 10,093 of 10,093; ratchet 365.
- **All 43 director checks pass** (all but `loader_check`), `aim_throw_check` with them. So do the beam move's, beam front's, beam AI's, struggle's and strike stages' checks.
- The core checks `two_states` and `load_split` pass.
- **Render:** 15 of 15.

## NEEDS FROM EP

- **QA:** fold it into acceptance 3's count (beams that fire where the player didn't aim). It's the same family as tick 5220.
- **Tools:** add `aim_throw_check` to CI with the rest (7 s).

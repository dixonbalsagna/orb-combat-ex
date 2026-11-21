# Parked: the two stray beams from Orb's 9 November play (GW1b riders)

Encounter, 2026-11-13, sprint A1 wave 1 (A-COMBAT-05, A-COMBAT-11). QA's replay of `orb-first-play-20261109-1646.json` (`docs/qa/runs/6a30b4c9/README.md`) found both. **On the GW1a data (main since b0e20f9a) its switches are on, and it moves the golden: both human-input replays, from their second checkpoint (no match row)** (the GW1b review's B-17; the lane is in `docs/director/runs/b0e20f9a/b17-lane/`). They act once the 9 November rows are main's (GW1a), and land in GW1b.

## 1. Tick 5220: a stick beam let go and refused never fires later into something else (A-COMBAT-05)

**What happened.** Orb held RB and the stick, let go at 5185, and the release was refused for the moment ("the lit hand holds": the target hadn't been free 0.3 s). Orb pressed Y and X at 5211, which began a brawl. At 5219 the waiting beam fired and ended the brawl Orb had just started. `DirBeamMove.tryFire` fires a waiting release whenever it can, for up to `maxWaitTicks` 90, whatever the player has started since.

**The fix: `ownMove.dropOnPress` (true).** A player's waiting release is dropped once he presses for anything else after letting go: a face button, a guard, a dodge, RT, a new stick strike, the context, the transform or Escape. The cue is `stick_refused` `beam` `replaced`. UI shows a word only if it adds `prompt.refuse_replaced`; otherwise it's silent and counted, by UI's own rule.
- With nothing pressed, the waiting beam still fires once the target is free, as before.
- A press on the release's own tick is part of the release.
- The computer's waiting release isn't dropped: its beam pacing is its own.
- False puts back the old wait.
- I chose this over capping `maxWaitTicks` near the refusal window: a cap would still fire into a press made inside it.

## 2. Tick 6617: RT + B is the signature only just after RT (A-COMBAT-11)

**What happened.** Orb pressed RT at 6591, and B at 6617 (26 ticks later, RT still held, locked in a brawl) started a signature. The keep-RT clause of `DirBrawl.isB` read `f.state != "charging"`: a fighter locked in a brawl is never charging, so RT held + B stayed the signature for as long as he wasn't channelling, not for the 12 ticks the comment says.

**The fix.** RT + B is the signature only within `tapHold.holdStart` (12) live ticks of RT's press, and never once RT's hold is the channel.
- **State:** one slot after DirBands' slip hold on `f.act.dirI`. It holds the live ticks left of RT's window, written at the end of each live update (`DirBrawl.noteRt`), and only for a player with Controls' `bNoBeam` and `bNoBeamKeepRt` both on.
- **Same tick:** a B on RT's own tick reads the press itself, so the pad's RT + B chord is still the signature.
- **Live ticks:** a hit-stop doesn't eat the window.
- **Where `isB` lives:** in my `sim/director/brawl.gd`. It reads Controls' two switches in `data/input/timing.json`, and nothing of Controls' changes.

## 3. The dash probe reads flight's default (Game Design, `docs/design/flight-3500.md`)

`sim/director/tools/dash_probe.gd` set `flatOut` 5,000 by hand. It now reads the data's default (`power.json` `flight.flatOut`, which becomes 3,500 in GW1b, Orb's decision 5). It prints the value the match used, and `--flat=` still tries another. It's a tool only, so nothing in the sim changes.

## Apply

On main b0e20f9a (GW1a), after `../launch-cone/` in the GW1b order: `git -c core.autocrlf=false -c core.eol=lf apply stray-beams.diff grant-tools-schema.patch dash-probe.diff`.

**Re-cut for B-17 (2026-11-21):**
- `interrupts.json`'s context line now reads `"enabled": true`, since GW1a turned the beam's own move on. The plain apply failed at line 294.
- Four checks now press RT on the tick they fire the signature with RT held: `beam_front_check`, `morning_fixes_check`, `outside_check`, `push_mode_check`. With GW1a's `bNoBeam` and `bNoBeamKeepRt` on, RT + B is the signature only inside RT's window after its press, and a real pad's RT is pressed on its first tick. Without the press, their B was the heavy and their beam rows failed (21, 3, 2 and 1 rows on the stack).

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `stray-beams.diff` (re-cut for B-17; the first cut was ff15d3e2): `sim/director/beam_move.gd`, `brawl.gd`, `exchange.gd`, `data/director/interrupts.json` `ownMove.dropOnPress`, the new check `stray_beam_check.gd`, and the RT press in `beam_front_check`, `morning_fixes_check`, `outside_check`, `push_mode_check` | Encounter | 2c748f23d44af5cdd26bf00896ecabb3aed05459 |
| `grant-tools-schema.patch` (`tools/schemas/director-interrupts.schema.json`: `ownMove.dropOnPress`, optional) | Tools (schema grant) | 952f78d01ed97a54477d0aa54ebc2875010ca1ca |
| `dash-probe.diff` (`sim/director/tools/dash_probe.gd`: flight's data default) | Encounter | 8f9b58791c13357a8d40a98d31ff9185cc3b658f |

## The check

`stray_beam_check.gd`, 11 checks. The beam's own move is on, as Orb's build plays it. A stage 1 hold is let go while the target is stunned, so it waits.

| Row | Result |
| :--- | :--- |
| On: Y pressed 8 ticks after the release | dropped (`replaced`), no beam in the next 100 ticks |
| On: a guard press instead | dropped, no beam |
| On: nothing pressed | it still fires once the target is free (+56 ticks) |
| On: Y on the release's own tick | part of the release: it still waits |
| On, at close range (Orb's case): a Y that begins a brawl after the release | dropped, and the brawl stands |
| **Negative control, off:** the guard press | the beam fires anyway (+56) |
| **Negative control, off:** the brawl's Y | the beam fires 58 ticks later and **ends the brawl**: Orb's 5220 |
| RT + B with B 0, 12, 13 and 26 live ticks after RT | the signature, the signature, the heavy, the heavy |
| **Negative control:** the window unread (the old rule) at 26 | still the signature: Orb's 6617 |
| The switches off | nothing written for RT |

## Proof

The gates ran on main def3445a plus `stray-beams.diff` and the schema grant. Records are in `docs/director/runs/def3445a/stray-beams/`, and every output went through `tools/gate.mjs` with no SCRIPT ERROR.
- On main def3445a, where the switches were off, the golden didn't move. **On the GW1a data it does:** both human-input replays, from their second checkpoint. The B-17 lane has every director check passing on the full GW1b stack.
- Validate 0 errors; self-test 10,093 of 10,093; ratchet 365.
- **All 43 director checks pass** (every one but `loader_check`), `stray_beam_check` with them. So do the beam move's, the beam AI's, the struggle's, the strike stages', the stick's, the flight strikes' and the morning fixes' checks, which all run with the beam's own move forced on.
- The core checks `two_states` and `load_split` pass.
- **Controls' tests:** `b_no_beam_test` 103 of 103, `b_no_beam_layouts_test` 4 of 4 (RT + B on the pad is still the signature; the only beams from B have RT in the chord), `layout_test` 131 of 131.
- **Render:** 15 of 15.
- `dash-probe.diff` is a tool. Its readings are in the report.

## NEEDS FROM EP

- **QA:** acceptance 3 asks for QA's count before and after: how often a waiting stick beam fires after a new press began something, and the count of refusals beside it, on Orb's saved files and the scripted set. `dropOnPress` true against false on one tree gives both. Dropping may read as more refusals.
- **UI:** `stick_refused` `beam` `replaced` is silent unless UI adds `prompt.refuse_replaced`. UI decides whether a dropped beam gets a word. I'd suggest none: he moved on.
- **Controls:** nothing to change. For their records: `isB` now reads RT's press age, not the fighter's state.
- **Tools:** the schema grant (optional key).

## Grants

`grant-tools-schema.patch`: `tools/schemas/director-interrupts.schema.json` (Tools').

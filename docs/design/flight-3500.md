# Flight at 3,500: every number keyed to absolute speed

Owner: Game Design. 2026-11-13, sprint A1 row A-CONTROLS-04, on Orb's decision 5: "flight 3500 as the default in every mode, with the slider dropped." Orb on 9 November: "tuning flight speed down to 3500 felt a lot more manageable than the default."

**What lands:**
- 3,500 a second is base flat-out flight in `data/fight/power.json`, in every mode.
- The private page's slider goes.
- A LAN match plays the same speed on both PCs, with nothing typed.

It lands in **GW1b**, after main reproduces the 9 November golden record, together with Simulation switching the energy model on in data (A-ENERGY-04).

## The list

| Number | Where | Keyed to flight? | At 3,500 |
| :--- | :--- | :--- | :--- |
| **Flat-out flight, base** | `power.json` `flight.flatOut` (`:108`) | It *is* the number | **5,000 → 3,500.** At maximum it's 3,500 × 2.305 = 8,068 (was 11,525). `growth` stays 2.305 |
| The setup range | `power.json` `flight.min` / `max` (3,500 / 7,000) | A setup's override is held to it | **Unchanged.** 3,500 becomes the default and the bottom. Tests may still set up to 7,000 |
| **The dash's close-time targets** | `power.json` `dash.closeSec` (`:113`), QA's targets from my ruling (c) | Yes: written for 5,000 | **Moves:** from 1,000 units **0.45 s** (was 0.4), from 3,000 **1.0 s** (was 0.8), from 6,000 **1.9 s** (was 1.4). At maximum, from 6,000, **0.9 s** (was 0.75). By the same model: first tick 1,000, full by tick 12, the 1.5 bh ease |
| The slip's brake | `power.json` `dash.slip.speed` 1,125 | No: a slip's own speed | Unchanged |
| The glow and burning trail on a launched body | `power.json` `burn` (4,500 / 6,000) | No: it reads the launch speed, which comes from energy | Unchanged |
| VFX's trail on a moving fighter | `data/vfx/meteor.json` `burn_from` 3,500 | Yes: it reads the body's speed | **Unchanged, and it matches.** At base, flat out is now exactly `burn_from`, so base flight never burns. That's what the 9 November build showed at 3,500. Transformed flight still burns (8,068 is well inside the ramp to 10,000). No grant needed |
| How fast a sent body moves on screen | `power.json` `launchTravel` 2.0 | Related: `power-scale.md` says a sent body never outruns a flat-out flyer of his level | **Read from Orb's 9 November match first.** At 2.0, a base send moves 4,000 on screen against a flyer's 3,500. The chase rush (30,000) still catches it, so nothing breaks. **The default becomes whatever `travel` Orb's match file recorded** (the 8 November play ran at 1.5). The travel slider goes with the flight slider |
| The gravity well's snap | `gravity-well-reading.md` | Yes: "flat out for his level" | It follows the number: 3,500 at base |
| Beam fronts (option A, if built) | `beam-physics.md` | No: their own speeds (8,000 to 18,000) | Unchanged. QA's escape bands read them against 3,500 flight |
| Flight strikes, the chase rush, the lunge | `interrupts.json`, `zip.gd` | No: travel floors and their own speeds | Unchanged |
| **Simulation's range check** | `sim/core/tools/power_check.gd:97-104` | It tests a setup of 3,500 and the clamp at 7,000 | Simulation updates any row that expects the default 5,000 |
| **Encounter's dash probe** | `sim/director/tools/dash_probe.gd:28` sets 5,000 by hand | Yes | It reads the data's default instead of a typed number |
| **The page's sliders** | `tools/preview/blackbox.mjs:461-478` (flight, and travel) | They set the number | **Both go.** A setting in the game's own options can come later, as a real setting |
| **LAN** | `net/lan.gd:30` sends no flight speed | It relies on the data | **Nothing to add:** both PCs read 3,500 from the same build's data. Netcode confirms the setup sets no `flatOut` |

## The look gate

**Nothing is meant to look different:** the 9 November build already flew at 3,500. Rendering and VFX run the side-by-side (`node tools/flash/side-by-side.mjs`) on the trail and the dash at 3,500 against the 9 November build, before the EP commits (ADR 0010).

## Proof

- `power_check` passes (Simulation).
- The first desktop build's packed `power.json` reads `flatOut` 3,500.
- A LAN match's replay on both PCs shows the same speed.

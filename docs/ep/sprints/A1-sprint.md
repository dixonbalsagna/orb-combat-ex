# Sprint A1: main is the game Orb plays (EP-run)

Started by the EP on Orb's word, 2026-11-13 23:30 PST: "I want you to take care of the plan and starting the sprint." Orb accepted every recommendation in the path's decisions table (vision.md, 2026-11-13 night) and added one thing: "I do want the planet, terrain, destruction, clipping all worked on heading towards the A1. Five different planet sizes should be achieved along with this."

The source of truth is `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md`, section A1, and each director's brief in `05-directives/A1/<slug>.md`, **read to its end**: the "Amendments after the adversarial review" section overrides the text above it.

## Budget and stop line

- **Up to about 40% of this week** (Orb accepted the recommendation). The week reset Fri 13 Nov 19:00 PST. The audit used about 26 points, so A1 runs until the all-models meter reads about 66%, then pauses for Orb.
- A1 is about 55M tokens over 2 to 4 weeks (the path), plus the added planet scope below (about 12M, the EP's estimate).
- **Fable:** the stand-in runs on Fable High. A Fable reset is Orb's to press, when the Fable meter is near full while the all-models meter still has room and Fable work is queued. See the plan at the end.
- **Stop line:** A1 closes when its exit criteria pass (path, A1 "Exit criteria"). Orb plays the A1 build before A2 starts landing.

## The fixed order (from the path, with the amendments)

1. **Day one:**
   - the outside-tester safety chain is briefed first: Tools' measuring-chain repair (A-LEGAL-08), then Camera, Rendering and VFX's readings (A-LEGAL-01, A-CAMERA-02) and Legal (A-LEGAL-03);
   - the spikes start on scratch copies.
2. **A-PROCESS-03 (EP):** the working tree (14,805 paths) is committed or deliberately ignored, one owner's group at a time, screened before each push.
3. **A-CODE-03 (Tools):** the code that lives only as patches in the build tool moves onto main: the planet entry, the report and replay hook (A-UI-02), and the energy model's switch (A-ENERGY-04).
4. **A-NET-05 (Simulation):** the build id in a replay, landed before the golden window.
5. **GW1a:**
   - the golden record is made first on the kept 9 November build's own data, as the target;
   - the switch groups land as main's data one owner at a time, in this order: pad, computer opponent, match-ending rules, round planet, camera, look, sound sets, left-panel menus. Each comes with its own gate run and side-by-side;
   - A-CODE-01 closes when main reproduces the target record bit for bit.
6. **GW1b:** the riders, straight after: the meters set to zero, the stray-beam fixes, flight 3500 and the rest of the path's list.
7. **The first desktop build** (A-TOOLS-01): Windows, then Linux, compared by stills on the same replay.
8. **Beside it all, on scratch copies:**
   - the mode list, fighter pick, quit row and mode smoke suite;
   - the measuring tools;
   - spikes S1 to S5;
   - the planet scope below.

**Nothing lands on main except through the EP's gate.** Directors park, the EP gates and lands in batches, and every visible change carries its side-by-side against the 9 November build (ADR 0010; decision 4).

## The added scope: planet, terrain, destruction, clipping, five sizes (Orb, 2026-11-13)

Built as parks beside GW1. They land **after GW1a is proven**, as their own windows, because they change the hash.

- **Five planet sizes (World, with Simulation and Performance):**
  - five selectable sizes, from World's six in `docs/world/planet-overhaul.md` (tiny to colossal), with World proposing which five;
  - each generates, plays and holds the shipped quality on Orb's PC;
  - the frame cost of each is read in a quiet window.
  - Ties to decision 2 (a random planet per quick match, plus a fixed one) and to A4's dials.
- **Terrain (World, with Camera):**
  - terrain step 2 (globe-step2), re-cut so Camera's chase_rush_check passes;
  - then the path's terrain rows.
- **Destruction (World, with VFX):** craters and trenches drawn where you stand (decision 3), and buildings breaking at every tier without the "ping pong" rebound Orb saw.
- **Clipping (Rendering, with Animation):** fighters' feet meet the drawn ground (Orb: "the terrain doesn't quite match up with the character's hitboxes"), plus no fighter sinking into a crater or a building.
- The terrain-mesh and tessellation overhaul stays after Alpha (decision 3).

## Waves (one PC)

- **Wave 1, from tonight:**
  - Tools, Simulation, UI, Encounter, World and Rendering build in scratch copies;
  - Game Design, Production Ops and Legal write papers;
  - the stand-in designs and reviews (below);
  - the EP does the working tree.
- **Wave 2, from Saturday:**
  - Camera and VFX (the flash readings, captures one at a time);
  - Controls, Audio, Combat (S4), QA (first readings), Performance (the desktop build's frame and load readings, in quiet windows only) and Netcode.

**Machine rules this sprint:**
- at most 2 Godot processes per director in wave 1, 3 in wave 2;
- long runs (over 10 minutes) one at a time per director, at below-normal priority;
- headless only;
- Chrome only through Tools' launcher, one capture at a time;
- stop only your own PIDs;
- no frame-rate or loading reading while the machine is busy, since such a reading is void.

## Decisions status (path table)

- **Answered by Orb:**
  - 1, 7, 8 (Discord "SOON"), 9, 10, 13, 18;
  - 15 (the full table at Beta: "keep iterating");
  - 16 (horde first size three);
  - 2 to 6, 11 and 14 (all recommended, 2026-11-13 night);
  - 19 is a direction ("keep improving performance on all levels"): X-23 and X-24 stay working targets;
  - 12: no standing yes. Workshop it, "player agency must be respected", and ask after spike S2's clip.
- **Still open, asked when their milestone needs them:**
  - 16's other parts (couch line-up, computer partner, dials) and 17, before A4;
  - 20 to 22, before A5;
  - 23, at A6.
- The marks drawn on fighters (Orb's answer 12): placeholders for diegetic auras and glows where a mechanic needs showing (A-RENDER-13 re-scoped, behind the look gate).

## Orb's stand-in on Fable: specialist work

The stand-in becomes the team's **design and review specialist** for A1 (Orb, 2026-11-13: "assign valuable specialist tasks to my stand-in ... Ensure optimal use of the Fable capabilities"). It writes design pages and review reports, and never edits code, runs Godot or touches git. Multi-agent runs are allowed for these jobs (Orb's word).

1. **Spike designs, ahead of the builders:**
   - S2, the gravity well: size, zones and the snap, with pseudocode and the toy, plus the close-fight question for Orb built around player agency;
   - S1, beam option A: travel, aim, escape, and what the struggle becomes.
2. **The planet design:** the five sizes, and terrain, destruction and clipping as one technical design: what each size costs, the order of the work, and the risks.
3. **The landing reviewer:** before each batch the EP gates, an independent adversarial review of the parks (determinism, hash discipline, taste rules, Orb's rules). It reports to the EP, and only verified findings count.

## The Fable reset plan

Orb has two Fable-only resets, valid to 8 March 2027. Unused, they're lost.
- **Reset 1, during A1:** when the Fable meter reaches about 90% while the all-models meter is under about 60% and stand-in work is queued. Expected this week or next. Orb presses it, and the EP says when.
- **Reset 2, during A3:** the fight's new rules (beam, signatures, stamina, the gravity well) are the heaviest design and review work on the path. Expected December or January. If A3 slips past mid-February, use it in whatever week the Fable meter fills first, before 8 March.

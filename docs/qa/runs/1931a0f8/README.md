# Beams in Orb's play of build 1931a0f8 (seed 11970847): what fired them and what hit (QA, 2026-11-08)

Source: `orb-first-play-20261108-1714.json` (Downloads; saved 2026-11-08 17:14 local), Grist (player, slot 0) against Loupe (easy AI, slot 1), planet 7, 13,382 ticks, no AI toggles in the file's `toggles` list (slot 0 was a human throughout). Replayed headless on the build's own tree (`homework/Files/builds/orb-first-play-1931a0f8-7a5a2d2c/tree`, copied to scratch) with `qa/godot/beam_trace.gd` (new) and `qa/godot/trace_replay.gd` (now prints the stance and right-stick layer masks). The replay agrees with what the page recorded: its own launch marks fall on every beam hit tick below (8187, 11370, 11672, 11991, 12352, 12540, 12738). Outputs, saved: `beam-trace-orb-play-20261108-1714.txt` (every beam event with both fighters' places and slot 0's intent), `slot0-trace-excerpts.txt` (slot 0's input around the beams discussed). The file's `checkpoints` list is empty, so the replay is checked by its marks, not by `blackbox-verify`. Times are tick / 60.

## 1. "Firing beams without intending to": two beams started by B, not by RB + the right stick

Slot 0 started four beams. Two came from RB + the right stick (the hold began with RB down, stance mask 2: held from 5484 and released at 5562, stage 2, fired wide; held from 12621 and released at 12673, stage 3, hit Loupe at 12738). **Two came from the B button:**

| Tick (time) | What slot 0 pressed | What the sim did |
| ---: | :--- | :--- |
| 3326 (0:55) | B alone, left stick walking left; no RB, no right stick, no trigger (stance mask 0) | `press_ack: queued`, `beam_charge: start`, beam fired at 3373 (`beam_fire`), outcome DODGE at 3417 |
| 8096 (2:15) | B with the dodge/sprint held (stance mask 8) | the same: charge at 8096, fired at 8143, outcome HIT at 8187 (Loupe launched) |

So in this build a B press with no layer held, or with the dodge held, throws the signature beam. That is the behaviour `layout.gd` line 987 leaves open: `signatureRtOnly` only turns B into a heavy when another stance button is already held (mask not 0) or energy mode is on, and `input_data.gd`'s note reads "B alone stays the big blow". Orb's rule of 2026-11-01 is that beams come only from the right stick (`memory: orb-beams-right-stick-only`; the page said RT + B was coming out). Of the 283 signature edges (B presses, counted by tick) in the match only these two started a beam of slot 0's (I did not classify what the other edges did), which is why it would feel like a random event: it needs the signature ready, 45 ki and a free fighter. Orb's 1:17 note falls 22 s after the first of them and about 4 s after a run of six B edges (ticks 4401 to 4406, state locked, no beam); in the 4,400 to 4,620 stretch no beam of slot 0's was started, and Loupe fired one wide at 4438 (`beam_wide`), so the note may describe that one. I cannot tell which beam Orb meant from the note.

## 2. "Opponent fired a beam at me, way under me": Loupe's beams hit from 2,400 to 6,500 units away, up to 2,850 units off in height

All Loupe's beams that landed on slot 0:

| Fire tick (time) | Hit tick | Range at the hit | Slot 0 against Loupe in height | Slot 0 doing |
| ---: | ---: | ---: | :--- | :--- |
| 11332 (3:09) | 11370 | 58 (point blank) | 34 above | in the fight |
| 11614 (3:13) | 11672 | 2,409 | 1,110 above | sprint held (mask 8), flying up |
| 11929 (3:19) | 11991 | **6,568** | **2,850 above** (y 3,853 against 1,003) | sprint held, flying up |
| 12290 (3:25) | 12352 | 3,796 | 569 below | nothing held |
| 12479 (3:28) | 12540 | 3,062 | 300 below | RB + right stick held (mask 2) |

Orb's two notes (3:17 and 3:22) sit right after the 11672 and 11991 hits. In both, slot 0 was climbing away at a sprint and was hit anyway, launched from 2,300 and 3,850 units up, with the shooter 2,400 and 6,600 units off and far below. **By design:** `beamplay.gd` header: a signature not answered "reaches the defender travelTicks later, at any distance", and `frontTicks` caps the flight "so it always arrives (pillar 3)". Fire to hit took 58 to 62 ticks (about 1 s) whether the range was 58 or 6,568. A sprint is not an answer (the dodge counts as a tap 18 ticks before arrival to 2 after; `beamPlays.front.dodgeBefore/After`). Whether the player's pane showed the shooter or the beam's approach at 6,500 units is a Camera and UI question this replay cannot answer; the beam trace shows the geometry only.

## 3. Open, with owners (for the EP to route)

| Item | Owner |
| :--- | :--- |
| B alone, and B with the dodge held, still throw the signature beam in 1931a0f8: confirm the next build removes it (Orb 2026-11-01) and that `signatureRtOnly` strips B at mask 0 as well | Controls, Game Design |
| Orb: "a big overhaul to the beam physics": the beam's long-range always-arrives rule, height and the view of an incoming beam from far off | Game Design (design), Encounter (`beamplay.gd`), Camera (framing) |
| QA can measure what an overhaul changes: range and height of every beam fired in AI-v-AI and with a scripted human, share fired beyond one screen, share answered | QA, when briefed |
| Orb's 1:17 note: which beam it meant is not in the file; ask Orb | EP |

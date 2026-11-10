# Orb's two plays of the afternoon build 6a30b4c9: the beam without the right stick (QA, 2026-11-09)

Orb attached `orb-first-play-20261109-1625.json` (2,040 ticks, seed 8487607, flat-out 5000) and `orb-first-play-20261109-1646.json` (19,388 ticks, seed 14617899, flat-out 3500, match over), both against the easy computer, with notes on the ground, a row of humps, a pause with no menu and the start menu. Orb's words to the EP: "I tested the signature with RT and B and that fired a beam as described in the readme, but I hit some combination of face buttons and fired a beam" without touching the right stick.

Method: replayed both files headless on **the build's own tree** (`homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree`, copied to scratch; one job at a time, below normal) with `qa/godot/beam_trace.gd` (now also prints the queue and the last 24 ticks of slot 0's buttons at each of its beam starts), `trace_replay.gd` and a small `probe_queue.gd` (new). No toggles in either file (slot 0 human throughout). Both switches `bNoBeam` and `bNoBeamKeepRt` are on in this build's data, `holdStart` is 12. The files carry no checkpoints; the replays are checked only by running clean. Saved outputs: `beam-trace-orb-1646.txt`, `beam-trace-orb-1625.txt`, `slot0-trace-excerpts.txt`.

## 1625: no beam at all

Slot 0 started no beam in the 2,040 ticks, and neither did the computer.

## 1646: slot 0 started 8 beams; seven came from RB + the right stick or RT + B, and one came late

| Tick | Slot 0's buttons just before | What it was |
| ---: | :--- | :--- |
| 4146, 4423, 8112, 12120, 16625, 18516 | RB and the right stick held, then the stick let go (RB let go a few ticks earlier in 4423, 12120, 16625) | the intended beam, fired on the release |
| 6617 | RT held (since tick 6591), B pressed at 6617 | RT + B: a signature (see below) |
| **5220** | **a Y press at 5211 (a brawl began), nothing else; 33 ticks earlier a right-stick hold with RB (5169 to 5186)** | **a stick beam that waited and fired late** |

**Tick 5220 is the beam Orb felt as "face buttons, no right stick".** At 5169 Orb held RB and pushed the stick toward the foe, reached stage 1 at 5181, let go at 5185 to 5186. The release was refused for the moment (`stick_refused: beam`: the target had not been free for 0.3 s, so "the lit hand holds"). Orb then pressed Y and X at 5211, which began a brawl. At 5219 the held-back beam fired (`brawl_end: beam`, `beam_stage 1`, `beam_charge: start` at 5220), ending the brawl Orb had just started, with no stick or RB down. The rule is in `beam_move.gd` (`tryFire`): a waiting release fires "when it can", up to `maxWaitTicks` **90 ticks** (1.5 s), whatever the player is doing by then (`data/director/interrupts.json`, line 296). So a stick beam can come out up to 1.5 s after the stick was let go, in the middle of the next thing the player does with their face buttons.

## 6617: RT + B past the interim window is still a beam

RT went down at 6591 (`powerPress`); B at 6597 (6 ticks after, inside the 12-tick window) was refused (`press_ack: refused`); B again at **6617, 26 ticks after RT**, with RT still held and the fighter locked in a brawl, started a signature exchange (`sig:signature`) at once, with the queue empty. The interim rule (`brawl.gd` `isB`, the `bNoBeamKeepRt` clause) lets RT + B stay a signature when `stanceMask & 4` and **`f.state != "charging"`**; it does not count ticks since RT's press, it reads the fighter's state. A fighter locked in a brawl is never "charging", so in practice RT held + B is a beam for as long as he is not channelling power, not only in the first 12 ticks (the comment says 12, the code says "not charging"). Orb read this one as intended ("fired a beam as described in the readme"); the readme says RT + B.

## The EP's three suspects

- **(a) the interim `bNoBeamKeepRt`:** confirmed for tick 6617 (above): RT + B past 12 ticks still beams while the fighter is locked. It is not what happened at 5220, where RT was not down.
- **(b) a stale queued signature (the 3326 kind):** **not at 5220.** The queue was empty at each of slot 0's beam starts, and nothing was queued from before. The stale thing here is the beam move's own waiting release (`M_PEND`), not the attack queue.
- **(c) today's batch (dashHandover, slip, the hitstop budget):** nothing in the 1646 beam starts points at them; I did not isolate their switches.

## What Orb's other items hold for QA

- **Ground clipping with the character models, a row of three humps in the crater, "game is paused, no menu", the start menu's d-pad (up and down inconsistent, left and right moving the option underneath):** none of this is readable from the sim; each needs a still or the page. Rendering and World (ground, humps: Orb says leftovers of the earlier wave, craters not waves), UI (the pause and the start menu). I measured nothing for them.
- Orb's answers on the file (flat-out 3500 felt more manageable, knock-backs bounce back "like a ping pong ball", wants to chain hits on a flying foe) are in the file's `answers` for Game Design and Combat.

## For Controls and Encounter (the EP routes)

1. **Tick 5220:** a released stick beam that cannot start yet should not fire 33 ticks later into a brawl the player has begun; options are to drop it when a new press begins an exchange, or to cap the wait (90 ticks now) at about the refusal window. The cue `stick_refused: beam` ("the lit hand holds") is the only word the player gets.
2. **Tick 6617:** `isB`'s keep-RT clause reads `f.state != "charging"`; if the intent is "B within 12 ticks of RT's press", it needs the ticks (or the layout's `powerPress` age), not the state.
3. QA offers a count across AI-v-AI and the scripted human of how often a pending stick beam fires after a new face press began an exchange (a one-line cue read), if wanted.

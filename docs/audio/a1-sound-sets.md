# A-AUDIO-01: the sound sets Orb's build turned on are on in main's data (Audio and Music, 2026-11-14)

Sprint A1, wave 2. Brief: `docs/ep/alpha/audit-2026-11-13/05-directives/A1/audio-music.md`. **Parked, not landed.** Run records: `docs/audio/runs/51b840f5/`.

## 1. What changed (my files)

- `audio/data/tug_cues.json`, `moment_cues.json`, `carry_cues.json`: `"enabled": false` becomes `true`, and each note now says "ON since A-AUDIO-01". **Nothing else in the three files changed.** `git diff 6a30b4c9 -- audio/data` (the commit Orb's 9 November build was made from) is exactly these three flips and three notes, nothing in the sound values: `docs/audio/runs/51b840f5/audio-data-vs-6a30b4c9.diff`. The played build's packed files hold the same three values (`docs/tools/runs/6a30b4c9/pck-verify.txt` lines 93 to 95: soundTug, soundMoments, soundCarry ON).
- Three audio checks were pinned to the old defaults and are updated, with the reason in each line:
  - `tug_check.gd`, `moments_check.gd`, `carry_check.gd`: "the switch is off in the data" became "the switch is ON in the data (Orb's build had it on)", and the off path is still tested by setting the switch off in memory. `tug_check`'s line "an update finds both voices" failed with all three sets on. Traced (EP's order): the check jumps the beam's point from 0.5 to 0.9 in one tick and counted every cue the pool took; the carry set's "point nears a fighter" cracks (thresholds 0.6, 0.8, 0.9) added two one-shot `tug.crack` cues, which are cues, not voices that moved. Both drone updates played. The fix counts only update cues (`if c.update and v.play(...)`), and the check now runs with all three sets as shipped, nothing masked. In real matches (12 AI matches, kept build's data) a point never moved more than 0.3 in a tick, and two near-cracks in one tick happened 5 times (a slightly thicker crack, by design).
- New `audio/tools/drop_probe.gd` (a model of the voice pool; see docs/audio/drops.md) and `audio/tools/sets_check.gd`: reads the data as shipped (no switch is turned on), plays seeded matches, and checks that the sim's events for a beam, a knock-out, a launch, a struggle and a transformation each become cues with bank sounds at in-range levels.
- Nothing in `sim/`, no state hash, no schema (no shape changed), no picture.

## 2. The two sets that stay off (written line each, criterion 2)

- **World (biome beds and ground surfaces, `world_cues.json`): stays off for Alpha.** It was off in Orb's build and no switch ever turned it on, so nobody has judged it; its 19-clip listening set (`audio/preview/biomes`) is unheard; and it adds boot warm-up work. Proposal for later: after Orb's ten-minute listening pass (A-AUDIO-03), with those clips to listen to first.
- **Co-op and controller sounds (`coop_cues.json`): stays off for Alpha.** Off in Orb's build. Its main beat, the brink's call, comes out only with the 2v2 director on, which Alpha builds do not have on by default, and its four clips (`docs/audio/img/coop/`) have not been judged by Orb. (The stray's knock in a clash is not behind it: it is in `tug_cues.json`, so it is live with the struggle set.) Proposal for later, with the clips, when 2v2 is on.

## 3. Gate run on main's new defaults (scratch export of HEAD 51b840f5 plus these files; one Godot process at a time, below normal priority)

All pass (`docs/audio/runs/51b840f5/`): `tug_check` (after the update; its first run on the old assertions failed, kept in `summary.txt`), `moments_check`, `carry_check`, `coop_check`, `brawl_check`, `tone_check`, `status_check`, `web_policy_check`, `beat_check`, `babble_check`, `world_check`, `warm_check`, `host_check`, the new `sets_check`.

## 4. Listening note (criterion 4): what I can and cannot say

Nobody listened: this is a cue record, not an ear. A replay played with main's data makes the same cues as on the 9 November build, because the audio data is the same (section 1) and the audio code has not changed since that commit (`git diff 6a30b4c9 -- audio/` has no code in it). What each of the five has, on seeded AI matches with the sets as shipped:

| Moment | On the kept build's own sim data (8 matches, up to 7,200 ticks, the page's power and dash words) | On main's sim data (4 matches) |
| :--- | :--- | :--- |
| A beam charging and firing | 46 events, 69 cues | 1 event, 2 cues |
| A launch | 27 events, 27 cues | 10 events, 10 cues |
| A beam struggle | 6 starts, 172 cues (the bed, pulses, surges, strays, lock, end) | none (the struggle is off in main's sim data until A-CODE-01 lands) |
| A transformation | 6 events, 6 cues (the ready sting, the coil) | none (the energy model is off in main's sim data) |
| A knock-out | none in 16 AI matches (the sim's KO comes from the wounds, and these matches end on time); its cue is proven on a staged event in `moments_check` ("a KO: a heavy hit at about half speed and a crater under it") | the same |

So on main's data today a player gets the launch and a beam but **no struggle and no transformation sounds, because the sim never makes those events there**, not because audio is off. They return when A-CODE-01's switch groups land. A short clip for Orb's ear of the played build and of main on the same replay needs a replay file and a browser capture (Tools' launcher); I have not made one.

## 5. For Tools and the EP

- **Switch rows to remove from `tools/preview/switches.mjs`** (lines 236 to 244, once this lands): `soundTug`, `soundMoments`, `soundCarry`. Their `from: false` no longer matches main's data, so left in place the build tool would try to flip a value that is already true. `soundCarry` needs `soundTug` and `soundTug` needs `struggle`; with the rows gone, the struggle row stays and the sound sets are simply on.
- **The audio scripts among the 82 unreviewed** (`docs/tools/check-scripts.md`), my answer:
  - **Run in CI:** `babble_check`, `beat_check`, `brawl_check`, `carry_check`, `coop_check`, `moments_check`, `status_check`, `tone_check`, `tug_check`, `web_policy_check`, `warm_check`, `sets_check` (new): headless, seeded, 1 to 20 seconds each, no timing rows. `world_check` too (91 s on a loaded PC).
  - **Gate only (as is):** `host_check` (58 s, prints hashes for comparison between trees).
  - **Not run in CI, with the reason:** `warm_async_check`: its slice-timing rows (the longest run between two yields) fail on a loaded machine even on plain HEAD, and a CI runner is one; its correctness rows (bit-identical clips) are covered by `warm_check`.
  - Also in `audio/tools/` but not `*check.gd`: `pad_start_check.mjs` and `web_voices_check.mjs` need a real browser through Tools' launcher: not CI, by hand.

## 6. Risks

- Turning the three sets on moves the boot warm-up: the struggle's drones are rendered at warm-up when the set is on (`audio_bank.gd`). This is what Orb's build did, so it is no worse than what Orb played; `warm_check` passes.
- The struggle and carry sets read events that main's sim data does not yet make (section 4).
- Not heard, as before.

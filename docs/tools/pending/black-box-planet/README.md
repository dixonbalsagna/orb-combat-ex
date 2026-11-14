# The black box playback starts a match on a planet the page has not loaded (Tools, parked 2026-11-14)

**What was wrong.** The page's black-box playback (`tools/preview/blackbox.mjs`, `_bb_pb_step`) starts a recorded match with `SimCore.newMatch(S, seed, ai, setup)`. The game's host sets `SimPlanetLoad.strict`, and with it `newMatch` **refuses** a setup whose planet is not loaded yet: it touches nothing, counts a refusal, and the page goes on playing the match it already had (a default two-body match). A saved match that names no planet (the S2 files) is not refused, so it replayed exactly. A saved match that names a planet (`"planet": 7, "planetGen": 3`: Encounter's Horde files) is refused, so the page played a two-body match instead of the recorded one and the clip kit said `THE REPLAY DIFFERS from tick 60`.

**What it looked like.** Read from inside the page with scratch probes (not in this park): right after `newMatch`, `n=2 hordeOn=false` with the setup naming `"horde": true`. With the fix: `n=5 hordeOn=true`, the five bodies at the same x and y as a headless `SimReplay.play` at tick 60, and 14 of 14 checkpoints equal over the first 8,526 ticks (the full `horde-clip-1.json`).

**The fix** (`black-box-planet.patch`, sha1 `5223b2c6f9bf16d951ea1e2a6ba3829b9546d02f`, applies to HEAD, three lines of `HOST_FUNCS`): the playback turns `SimPlanetLoad.strict` off around its own `newMatch` and puts it back. A planet that is not made yet is then made cold (a pause at the start of a playback, which has no loading screen), as `SimReplay.play` makes it.

**Proof.** The Horde trial build with this fix and nothing else: `tools/clips/make.mjs --from-match horde-clip-1.json` reads "the replay is the match that was played (14 checkpoints equal)". Without it, on the same tree: "THE REPLAY DIFFERS from tick 60". The patch is only in the scratch copy of the tools so far; it has not been through `preview-selftest` or `stack-selftest` (they build with a stand-in for Godot and do not play a match), so run both when it lands.

**Not proven, and what to check.**
- A playback of a match that names a planet *and* is made from the page's own `?planet=7&go=1` start already worked, because that page had loaded the planet; this fix changes nothing for it, but I did not re-run one.
- I also tried two other changes in the same function (sizing the playback's input array from `SimStage.slotCount` after the new match is made, as `replay.gd` does, and leaving an unmentioned body's AI flag as `newMatch` set it). They are not in this park: with only the three lines above the Horde match replays exactly, so I did not find them necessary. If a 2v2 saved match is ever played back in the page and differs, look there first.
- It touches `BB_FINGERPRINT`'s input (`HOST_FUNCS`), so every cached page build is rebuilt once after it lands.

**Owner.** Tools (`tools/preview/blackbox.mjs`). Lands any time; no data, no schema, no other director.

# Where Orb's 29% of dropped cues came from (Audio and Music, 2026-11-14)

The EP's question: Orb's 12:29 play file (all three sound sets on) shows 656 of 2,226 cues dropped, 638 by the voice pool (`played 1505 dropped 638`). Are important sounds losing their slot to minor ones?

## Answer

**No, not in play with the sound running. The drops were the silent first three minutes.**

`audio/tools/drop_probe.gd` models `AudioVoices.play`'s decision (the same distance rule, `_take`'s group, class cap, free voice and weakest-voice rule, 16 voices, a one-shot busy for its length over its pitch, a looped voice until its group stops) and runs seeded AI matches on the kept build's own sim data (6 matches, 720 s, the three sets on as shipped). Nothing is played. Records: `docs/audio/runs/51b840f5/drop_probe-*.txt`.

| Run | Asked | Dropped for distance | Dropped for no slot | Share |
| :--- | ---: | ---: | ---: | ---: |
| Sound running all the time | 5,142 | 46 | **0** | 0.9% |
| Sound held back for the first 60 s of each match | 5,142 | 46 | **1,530** | **30.6%** |
| The same, with the fix below (cues held, not taken) | 2,364 taken (2,778 held) | 46 | 0 | 1.9% |

- **With the sound running, nothing loses a slot** (the pool never fills; no class cap fired). The 46 distance drops are cues 2,600 units or more from the camera: 15 rush whooshes, 13 light impacts, a few craters, guards, perfect blocks and cries. Far events, as designed.
- **The 30.6% matches Orb's 29%.** In Orb's play both browser audio contexts were suspended for 178 s (docs/audio/pad-start.md). While the page player's context is not running, a cue falls to a Godot player on the engine's frozen context. That player stays "playing" and never ends, so 16 frozen voices fill the pool; every later cue drops unless it outranks the weakest frozen one. The dropped sounds in that run: light hits (impact.light and its lite variant, 1,008), guards (275), whooshes (63), medium hits (46), wind-ups (30). Heavy hits, the beam, launches, the struggle and voices stay (priority 60 and up outrank the frozen light hits). Nothing a player could hear was lost, because nothing could be heard then.
- **A burst at the first press.** When the context wakes, the 16 frozen voices finish at once: an old pile of hits at the first key press. Not measured by ear.
- The page's "dropped" count also includes `false` returns that are not drops (an update for a bed that ended, a stop for nothing playing: 47 cues in the file have no sound), so its 656 is a little higher than the pool's own 638.

## The fix (a separate park, not on main)

`docs/audio/pending/held-when-blocked/` (README and a patch that applies to HEAD): while the page player is installed and its context is not running, every new cue is held (counted as `held`, in the status line, not as a drop) instead of starting a Godot player on a frozen context. Updates and stops are untouched. The pool stays free and nothing bursts at the first press. The pad-start fix (76cc199c) makes the blocked phase shorter for pad players; this makes what is left harmless.

## Risks

- A model, not a recording: AI matches, not Orb's play, and it assumes a Godot player on a suspended web context stays "playing". The 30.6% against Orb's 29% supports it; Orb's next play file (the status line's `dropped` and the new `held`) would settle it.
- A looped bed (the struggle's) started while blocked is held too, so it is silent until the next struggle starts after the sound wakes.

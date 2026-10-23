# Cuts and eases: when the camera may move instantly

Research & Prototyping, 2026-10-23, for Orb's request: "the camera looks like it snaps too fast, all dynamic camera movement should be smooth, no instant movement unless well justified by real cinematography theory". It is for Camera's audit of every instant change.

Conventions:
- "CS n" cites the source list in `cinematic-storytelling.md`; new sources are numbered at the end.
- Frames are 60 fps ticks.
- Numbers marked *(est.)* are ours.
- No fades or dissolves anywhere (`docs/ep/taste.md`).

## 1. The rule of thumb: ease, cut or whip

| The change | Do | Never |
| :--- | :--- | :--- |
| **Small:** within one shot size, same space (a reframe, push, lead room, zoom with separation) | **Ease** | Snap: a small instant change is a jump cut [CS 36], the "snaps too fast" look |
| **Large, and the space between does not matter** (a new phase, place or set piece) | **Cut**, for a reason in section 2 | Slide there fast |
| **Large, and the space between matters** (riding a launched body, swinging to where a charge came from) | **Crisp whip:** short (about 8 to 15 frames), a hard ease at both ends, background streaks, no blur, in the direction of the motion | Whip with no motion to motivate it |

The middle is forbidden: a long fast slide, which is neither a cut nor a crisp whip. A crisp pan judders worst between about 0.36 widths a second and whip speed (CS 63, converted to 60 fps). A crisp whip stays short and eases hard at both ends, so it spends little time in that band. The background streaks carry the speed, not blur, because Orb's taste rejects blur.

A "snap" is any of three things:
- a small instant change;
- a long fast slide;
- a move with no ease at its start or end.

## 2. When a hard cut is justified

**The five reasons:**
1. **Cut on action.** Cut in the first frames of a motion onset (a strike, dash, launch or beam ignition). The motion carries on across the cut at the same speed and direction and carries the eye with it. Viewers miss about a third of such cuts [CS 6, 2].
2. **Match cut.** Join two moments by matching shape or pose, such as the struck pose to the crater it makes. Rare: it reads as a statement [4].
3. **Scene, time or space change.** A new phase or place: the exosphere, the planet's far side, into or out of an authored set piece. Also a jump a move would only smear, such as a blitz.
4. **Reveal.** Cut to what a look, charge or incoming attack points at, on the side it faces, or to the damage after an arrival.
5. **Shock beat (smash cut).** A jolt by contrast: a decisive blow, a transformation's release, quiet into chaos [3]. The rarest; spend it on story weight.

**The conditions** [CS 1, 5, 34, 61]. Every cut must also meet all of these:
- The change is big: at least one shot size (about 1.5 times the scale, *est.*). Anything smaller eases.
- It falls at an onset or in a pause, with a sound. Never mid-move, never during a pass, and never mirroring the pair.
- The subject lands where the eye already is.
- Nothing the player must read falls in the 0.5 to 0.8 s after the cut, while gaze re-finds the subject.
- The reason is written beside the cut, in the code and in `docs/camera/director.md` (Orb, 2026-10-22).

"The framing target jumped" is not a reason. A lag catch-up or a side swap gets a damped catch-up or a whip [CS 40].

## 3. Ease durations at 60 fps

- **Film.** Operators ease every start and stop; a fluid head exists to prevent jerky ones [8].
- **Engines.** One engine's default blend is a 2 s ease in and out, and a cut is a zero-length blend set up for specific camera pairs [1].
- **These values** are starting points to tune on side-by-sides.

| Move | Shape | At 60 fps | Basis |
| :--- | :--- | :--- | :--- |
| **Follow** (pan, tilt) | Critically damped spring, exact exponential form | Half-life 6 to 15 frames *(est.)* | CS 42 |
| **Vertical follow** | Lazier; ignores jump and launch arcs; re-centres on landing | 1.5 to 2 times the horizontal half-life *(est.)* | CS 40 |
| **Reframe** | Ease in and out; position and zoom on one curve | 18 to 36 frames *(est.)* | CS 40, 41 |
| **Slow push** (power-up, menace) | Ease in and out | 60 to 180 frames *(est.)* | Slow pushes run several seconds [5] |
| **Impact push** | In with a fast start and soft landing; hold for the hit-stop; ease back | In 5 to 10 frames, back 15 to 25 | Snap zooms run 2 to 4 frames at 24 fps [5, weak]; "a hard accent bounces back" [CS 32] |
| **Crisp whip** | Hard ease at both ends; background streaks; no blur | About 8 to 15 frames in all *(est.)*, with as few as possible in the judder band | Editors' whips run about 10 to 15 frames at 24 to 30 fps [6, weak]; judder band CS 63 |
| **Background pan** | Constant speed, eased ends | Under about 0.36 widths/s, or whip speed with streaks | CS 63 |
| **Dutch roll** (mood) | Slow ease in and out; level again on resolution | 30 to 90 frames, at most 5 to 8 degrees *(est.)* | CS 31 |
| **Return** after a set piece | Ease in and out, or a cut on action if the angle differs a lot | 18 to 30 frames *(est.)* | |

**Comfort:**
- Never roll with the action. A rolling chase camera is a common nausea trigger, and a horizon turning behind a still subject loses the player's orientation [7, anecdotal].
- No sustained oscillation at about 0.1 to 0.5 Hz; sickness peaks at 0.2 to 0.4 Hz [CS 69].
- Shake and automatic moves can be turned down [CS 55].

## 4. Launches, supers and impacts in fighting and action games

- **Impacts.**
  - The sim freezes both bodies for 6 to 15 frames by weight, capped at 20 to 30. The struck body shakes along the ground or air axis, decaying [CS 68].
  - Punch-ins are gated, firing only on specific strong hits or a predicted match-ending blow. They are suppressed when they would hide the field [CS 46].
  - Shake is a decaying trauma value through smooth noise, never a per-frame jump [CS 43].
- **Launches.**
  - Side-scrolling cameras track the group, ignore the vertical arc, re-centre on landing, and predict from the planned path [CS 40].
  - The anime tradition matches the camera to the flying body's speed, so the body hangs while the world streams past [CS 28].
  - The snap belongs to the body, not the camera [CS 71].
- **Supers.**
  - A super flash freezes the game and buffers both players' inputs [CS 45].
  - The cinematic plays after a confirming hit, cutting into an authored scene and back out (reason 3). Its cameras hide position cheats [CS 47].
  - One major action game never cuts at all [CS 56].

## 5. For Camera's audit

- **Classify every instant change** as an ease, a cut or a whip. A cut stays only with a section 2 reason that meets the conditions.
- **The blow push** (`docs/camera/feel.md`) rises over 3 frames, faster than a film snap zoom. Try 6 to 8 frames with a soft landing; its 0.25 s return already fits.
- **Measure per clip:**
  - the instant changes by reason (`clip_digest.gd`'s cut flag records the line that set it);
  - the camera's jerk peaks at the start and end of each move.

## Sources

The new sources were read through search results on 2026-10-23.

1. Unity, Cinemachine manual, "Blending between cameras". https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineBlending.html
2. "Cutting on action", Wikipedia. https://en.wikipedia.org/wiki/Cutting_on_action
3. MasterClass, "How to use a smash cut". https://www.masterclass.com/articles/how-to-use-a-smash-cut-transition-when-editing-a-film
4. Adobe, "Match cut". https://www.adobe.com/in/creativecloud/video/discover/match-cut.html
5. Morphic glossary, "Snap zoom" (weak: an AI-written glossary). https://morphic.com/ai-glossary/snap-zoom
6. Editors' whip-pan tutorials (weak): Creative Cow, https://creativecow.net/?p=2451776; TutVid, https://tutvid.com/?p=7869
7. ModDB developer blog, "To roll or not to roll the camera" (anecdotal). https://www.moddb.com/news/to-roll-or-not-to-roll-the-camera
8. How To Film School, "Fluid head". https://howtofilmschool.com/dictionary/fluid-head/

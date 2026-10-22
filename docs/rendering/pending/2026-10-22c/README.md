# Parked: the camera roll, motivated and rare (Rendering, 2026-10-22)

This replaces the first 22c, which let the story start the roll on its own. It follows the EP's option (b):
- the sim's climax event decides when;
- with Encounter's feed on, the live story decides how much and which way;
- only the top climaxes roll, at least 8 s apart.

**Base:** HEAD c6980e25 **plus Camera's story slots** (`docs/camera/pending/story-slots.patch`: split_rig's `story_a` and `story_d`). The roll reads those slots while the feed is on, so they must land first. Every check below ran on copies of the commit, never on the tree.

**Apply order** (each from the project root, with `git -c core.autocrlf=false apply`):
1. Camera's `docs/camera/pending/story-slots.patch`.
2. This park: `docs/rendering/pending/2026-10-22c/batch.diff`.

Then delete this folder.

## What it changes

- **When:** a finisher's start or a KO (`RenderLook.ROLL_EVENTS`, weight 1), or a decisive exchange won by a beam clash (0.5), a guard break or a launch (0.25) (`ROLL_DECISIVE`).
  - A plain knock-back, a heavy clash, a beam won, an interrupt, a shot and a barrage do not roll.
  - A roll starts at least `ROLL_GAP_S` (8 s of match time) after the last one; a finisher's start and a KO roll whatever the gap.
- **How much and which way:**
  - With the feed on and a story held in Camera's split rig: the story's weight (1 or 2: 0.25, 3: 0.5, 4: 0.75, 5 or a finisher: 1), never under the event's own, leaning toward `story_d`'s side of `story_a`.
  - Otherwise the event's own weight, leaning toward the loser's side of the winner.
- **Off by default**, as before (`RenderLook.CAMERA_ROLL_ON` false). With the roll off nothing on screen changes, so no side-by-side was made; the roll's own stills are in `camera-roll.md`.

| File | Change |
| :--- | :--- |
| `render/core/camera_roll.gd` | the top-climax list, the gap, the story's weight and direction (`consume(S, events, rig)`, `_story_live`, `_roll_to`) |
| `render/core/look.gd` | `ROLL_EVENTS`, `ROLL_DECISIVE`, `ROLL_GAP_S` |
| `render/core/main.gd` | passes `split_rig` to the roll while the split view is attached |
| `docs/rendering/camera-roll.md`, `docs/rendering/README.md` | what rolls, and what the probe measured |

## Checked

- **Gates:** gates9 (17 checks) and cue_check pass on the slots plus this, with 0 script errors. The outline and cull checks need a window, so they were not run.
- **Three two-minute matches (seeds 1 to 3, roll on), feed on and feed off alike:**
  - 8 rolls on the 10 listed climaxes (2 fell in the gap);
  - 0 rolls without a climax;
  - 4.2% of match time rolled, against 33.8% for the event list on main and 29.4% for the first 22c.
- **Seed 1 played to its KO:** 4.9% of match time rolled. The finisher and the KO, 4 s apart, both rolled 8 degrees. The details are in `camera-roll.md`.

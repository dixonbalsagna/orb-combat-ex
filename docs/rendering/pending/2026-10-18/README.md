# Parked: the stance badge, steady and out of saturated red (Rendering, 2026-10-18)

**Base:** HEAD fda9b426. The diff applies on that commit alone and after the 2026-10-17b park (`../2026-10-17b/`); both were checked on copies of the commit, never on the tree.

**Apply** from the project root, after 2026-10-17b if that goes first:

```
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-18/batch.diff
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-18/batch.diff
```

Then delete this folder.

## What it changes

The stance badge above each fighter (`render/core/fighter_view.gd`) is not the cause of the ring of five's red flash, which was the Anti-hero's clothing (`RenderLook.CAPE`). But it is a saturated red to the frame analyser and it spun, so the EP asked for it to be one or the other no longer.
- **Out of saturated red.** The aggressive colour goes from #ff5a4a to #ff8066. The analyser counts a saturated red at R/(R+G+B) 0.8 or more, on stored or linear values. #ff5a4a is 0.85 on linear values; #ff8066 is 0.74 (0.53 stored). The badge's flat shading only scales its colour, so the share holds in light and shade. The other three stances' colours were never near it (0.05 to 0.27).
- **Steady.** The badge no longer turns (it spun at 2 rad/s). It stands at a fixed turn of 0.6 rad, so two of its four faces show with different shading and it still reads as a solid.

| File | Change |
| :--- | :--- |
| `render/core/look.gd` | `STANCE_COL[0]` #ff8066, its comment; `BADGE_TURN` (new) |
| `render/core/fighter_view.gd` | the badge's turn is `BADGE_TURN` |
| `docs/rendering/README.md` | the fighters' paragraph |

The legacy HUD (`render/core/hud.gd`, `--legacy-hud`) takes the same colour from `STANCE_COL`.

**For UI (not in this park):** UI's own stance colours (`ui/core/ui_look.gd`) put the aggressive stance at #ff6a5a, which is 0.80 on linear values: at the analyser's line. UI's plate pulses its stance chip on a change.

## Checked

`gates9` (17 checks) and `cue_check` on a scratch copy of HEAD with the diff, and Tools' ring clips (ring of three and ring of five, both modes) against HEAD's. The results are in the report that goes with this park.

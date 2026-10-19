# Parked: nothing of Rendering's on, over or between the fighters (2026-10-19)

**Base:** HEAD c984129c. The diff was checked on a copy of that commit, never on the tree.

**Apply** from the project root:

```
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-19/batch.diff
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-19/batch.diff
```

Then delete this folder.

## What it changes (Orb's minimal rule, `docs/ep/taste.md`)

- **The stance badge** over each head is off: `RenderLook.STANCE_BADGE_ON` false. The stance still shows in the lean and on UI's plate.
- **The guard arc** (the translucent crescent in the lane colour in front of a guarding fighter) is off, and its perfect-block flash with it: `RenderLook.GUARD_ARC_ON` false. A held guard shows in Animation's guard pose. The flash register's bookkeeping is unchanged.
- **The greybox key help** is shown only with `--keyhelp`, or `?keyhelp=1` on a page: the demo's prompt ("Computer vs computer demo. Press any key..."), the system and debug keys, the head flashes' keys, and the seed and tick line. F3's performance readout still shows on its own.

Each constant brings its piece back.

| File | Change |
| :--- | :--- |
| `render/core/look.gd` | `STANCE_BADGE_ON`, `GUARD_ARC_ON` (new, false) |
| `render/core/fighter_view.gd` | the badge and the arc follow them |
| `render/core/hud.gd` | `key_help`: the prompt, key help and seed line only with it |
| `render/core/main.gd` | `--keyhelp`; `keyhelp` among the URL arguments a public page may set |
| `docs/rendering/README.md` | the guard arc's section, and the rule's entry |

**Before and after:** `docs/rendering/img/minimal-before-after.png` (uncommitted). Seed 4 at tick 1120, the demo's prompt shown as a visitor sees it.

**Not Rendering's, still around the bodies in that still:**
- the teal and violet bubbles are VFX's standing aura (`render/vfx/aura.gd`, shown while a fighter charges or attacks);
- the wide faint ring closing on the fighter about to be hit matches UI's beat ring (`ui/widgets/ui_beat_ring.gd`).

## Checked

`gates9` (17 checks) and `cue_check` pass on a scratch copy of c984129c with the diff, with 0 script errors.

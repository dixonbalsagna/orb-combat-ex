# GW1b landing, C-1 finish and C-2: records (Camera, 2026-11-22)

## (1) Full split_sweep, below-normal priority

| Tree | Result |
| :--- | :--- |
| the 55-line stack (s426) + gw1b-split-sweep, gw1b-camera-checks, gw1b-handover-ease, gw1b-landing-c1 | split sweep passed |
| main b04de5d5 + the rig changes (wide hold at the drawn floor, handover ease, `_drawn_off`) | split sweep passed |

## (2) C-2: side-by-side, both flash modes, through Tools' run-pixels (one capture at a time, none starved or void)

Builds: **ref** = d3f1ca0e (docs/ep/taste.md; `--legacy-hook`); **before** = the 55-line stack without Camera's GW1b rig changes; **after** = with them. Default look = reduced.

| Clip | Build | normal: primary / area-15% / 2 s memory | reduced: primary / area-15% / 2 s memory |
| :--- | :--- | :--- | :--- |
| ai 3, 1200 ticks | ref | 0 / 0.5 / 0 | 0 / 0.5 / 0 |
| | before | 1 / 1.5 / 1.5 | 2 / 2 / 1.5 |
| | after | 1 / 1.5 / 1.5 | 2 / 2 / 1.5 |
| ai 38, 300 ticks | ref | 0.5 / 1 / 0 | 0.5 / 1 / 0 |
| | before | 1 / 2 / 0.5 | 1 / 2 / 0.5 |
| | after | 1 / 2 / 0.5 | 1 / **1** / 0.5 |
| ai 1, 600 ticks | before | 2 / 2 / 1.5 | 2 / 2 / 1.5 |
| | after | 2 / 2 / **1** | 2 / 2 / **1** |

All PASS, 0 general red, 0 dips. No reading is worse after; two are lower (ai 38 reduced area, ai 1 memory both modes). The reference's lower readings are the old build's scene (the arena demo), not the camera: GW1b's planet, HUD and data are in both before and after.

Seed 3 doesn't exercise the changes (before and after differ only in foreground ground, at most 7.7% of pixels per frame). Clip digests on the stack picked seeds that do: ai 38 differs at ticks 62–115 (up to 63% of pixels), ai 1 at ticks 89–186 (up to 72%), the same in both modes. In both, before shows the panes with the fighters off the drawn screen (only the off-screen pointers); after, the split opens at its eased rate and each pane holds its fighter.

## Pictures (uncommitted: docs/camera/img/default-view-stack/gw1b-landing/, ignored)

change-default, change-normal, vs-reference-default, vs-reference-normal (seed 3); ai38-change-default/normal; ai1-change-default/normal; ai38-vs-reference-default/normal. Each has a GIF and stills (left: before or ref; right: after).

**Best two for Orb:** `ai38-change-default-t00087.png` and `ai1-change-default-t00107.png`.

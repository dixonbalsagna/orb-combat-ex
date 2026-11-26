# Parked: the pump, split before zooming out (a2-pump)

Camera, 2026-11-26. This fixes Orb's "zoom jumps" (A2 issue c) and helps "splits or joins abruptly". The EP's go covers parts 1 and 2 as one park.

**Apply on the landing order:** main, then `../reset-frame/`, `../gw1c-door-holds/`, `../cd04/` (at 0.045). Then `git -c core.autocrlf=false apply a2-pump.patch` (sha1 f319fd15, 65 lines). Two files, mine: `render/camera/split_rig.gd`, `camera_params.gd`. Records: `docs/camera/runs/54474b97/a2-pump/` (the hunt is in `docs/camera/runs/54474b97/zoom-hunt/`).

## What was wrong

As a pair flew apart, the shared view zoomed out at the transition's comfort cap, 4% a tick. Then the split opened, and both panes zoomed back in at the same cap.
- Seed 3 at 79 s: the view went from 0.96 to 0.32, three times wider, in 0.45 s, then from 0.32 back to 0.70 in 0.4 s.
- The hunt counted 22 pumps in three long AI matches (about 8.5 minutes), 15 of them a zoom-out of 1.5 times or more.

## The change

| What | Where |
| :--- | :--- |
| **1. Split on the coming separation.** A pair flying apart faster than `SPLIT_LOOK_RATE` (1,500 units a second) is judged on the size it will have `SPLIT_LOOKAHEAD` (0.35 s) on. Below the split line, the split waits the ordinary dwell only, without the wide hold. This mirrors the join's lookahead, which is already on. Switch: `split_lookahead`, on. | `_update_trigger` |
| **2. The shared view zooms out at the ordinary rate** (1.2 e-folds a second) outside a transition. It always had the transition's 2.4. The scroll governor's zoom-out for speed keeps the faster rate, and so does the peak launch's own framing. A fighter who leaves the frame opens the split, as before. Switch: `merged_out_ordinary`, on. | the shared camera's filter |

Neither rule acts in a match's first 3 s (`SPLIT_LOOK_FROM`). The default opening's framing is Orb's own question (split_sweep's `OPENING_PLANET_CEIL`, due 28 Nov), and without this gate rule 2 split the opening's first dash.

## Proof

- **The pump counter** (seeds 3, 10 and 17 to the KO, the rig as shipped, Reduce flashing on):
  - pumps: 22 → **13**;
  - zoom-outs of 1.5 times or more: 15 → **6** (two of the six are in the opening, which is left alone);
  - capped zoom ticks: 865 → 778.
- **Gates:** every camera check passes, as does split_sweep (at standard, later and sooner) and own_pane at later and sooner. The pane, seam and determinism gates pass. The golden is unchanged (989878d6d335).
- **Two reds were found and fixed on the way:**
  - peak_shot: the catch's zoom read 3.65 e-folds a second against 3.45. The peak launch is now left out of rule 2.
  - split_sweep's default opening split. Both rules now wait out the first 3 s.
- **Readings** (medium, worst of 4, base against this park; the EP only; `readings.txt`):
  - collapse: reduced 1 / 2 / 1.5, normal 1 / 1 / 1, the same;
  - rushcity: reduced 4 / 4 / 3.5, normal 3.5 / 3.5 / 3, the same worst readings (one 1024x768 reading moves 3.5 to 4, one 960x540 reading moves 3 to 2.5).
  - These were taken with cd04 at 0.03, before the EP's 0.045, on base and park alike.

## The look (`docs/camera/img/default-view-stack/a2-pump/`, ignored: fighters)

- `rushcity-reduced-base-vs-pump`: stills at 330, 600, 620, 730, 1250, 1350 and 1450, plus a GIF from 300 to 1500.
  - At 1350 the base's shared view has zoomed so far out that both fighters are specks and the human is only an edge pointer. With the park the screen has split, and each fighter is at fight size in their own half.
- `ai10-base-vs-pump`: seed 10's first 20 s. The same picture: the fix acts on 2 frames in this stretch.
- Every move eases. There is no cut, fade, dissolve or blur.

## Risks

- **More splits per fight.** The wide "flying around the world" beat is shorter. The later setting is the way to keep it longer, and Orb judges it in play.
- The four remaining big pumps are a pair turning from one view straight into a split. That is the next lever, if Orb still feels them.

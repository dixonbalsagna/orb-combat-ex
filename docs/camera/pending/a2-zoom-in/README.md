# Parked: the panes' zoom-in eases after a split or a slam's join (a2-zoom-in)

Camera, 2026-11-26. The second part of Orb's "zoom jumps" (A2 issue c), on the EP's go. **Camera's recommendation: hold it.** It is parked so the evidence stays, but its readings are slightly worse and its look gain is small (below).

**Apply after `../a2-pump/`:** `git -c core.autocrlf=false apply a2-zoom-in.patch` (sha1 2c4b89cb, 46 lines). One file, mine: `render/camera/split_rig.gd`. Records: `docs/camera/runs/54474b97/a2-pump/`.

## The change

- **A pane zooming in while the split opens or closes** takes the ordinary comfort rate (1.2 e-folds a second), not the transition's 2.4. This applies to both its filter and its drawn zoom. It does not apply to the slam's door or the shots.
- **The shared view zooming in outside a transition** takes the ordinary rate too: just after a slam's join, or a pair that comes together. The peak launch is left out.
- Switch: `zoom_in_ordinary`, on.

## Proof

- **The pump counter**, against a2-pump:
  - pumps: 13 → 12;
  - zoom-outs of 1.5 times or more: 6 → 5;
  - capped zoom ticks: 778 → **584**. The zoom-ins at the cap are mostly gone.
- **Gates:** every camera check passes, as does split_sweep (at standard, later and sooner), own_pane, pane, seam and determinism. The golden is unchanged.
- **Readings** (medium, worst of 4, against a2-pump; the EP only):

| Clip | a2-pump | + a2-zoom-in |
| :--- | :--- | :--- |
| collapse, reduced | 1 / 2 / 1.5 | **2** / 2 / 1.5 |
| collapse, normal | 1 / 1 / 1 | 1 / 1 / 1 |
| rushcity, reduced | 4 / 4 / 3.5 | 3.5 / 4 / **4** |
| rushcity, normal | 3.5 / 3.5 / 3 | 3.5 / **4** / 3 |

- **The look:** `rushcity-reduced-pump-vs-zoomin` and `ai10-pump-vs-zoomin` in `docs/camera/img/default-view-stack/a2-pump/` (ignored: fighters). The picture is a little wider for a moment as the panes come in, and otherwise the same.

## Why hold

- The worse readings are half a flash in the default look (collapse reduced 1 → 2, rushcity's 2 s memory 3.5 → 4).
- The gain is fewer capped zoom ticks, which Orb may not feel once a2-pump has removed the big zoom-outs.
- Orb's play on a2-pump decides whether the zoom-ins still read as jumps. If they do, this park is the lever, with a fresh reading.

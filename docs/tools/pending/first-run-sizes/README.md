# Park: the one-click first run plays small and big (Tools, 2026-11-26)

`first-run-sizes.patch`: `tools/first-run/sizes.json`, `first-run.mjs`, `first-run-selftest.mjs`. Applies on main with or without World's `unhide-small-big.diff`.

A size is chosen as a player does it, with the setup's "Planet size" row (a locked build takes no argument for it): four Down, Left (small) or Right (big), four Up, then Start. The script reads from the program's own data whether the size is offered, and says "Not run" otherwise (also without a window, where the keys are not pressed and a run would be medium).

    tools\first-run\FIRST-RUN.cmd --size small,medium,big

(A plain double-click still runs the default, medium, only.)

**Checked:** self-test 29 both without and with the flip. Headlessly, on a tree with the flip, the keys played small (2,560 columns), big (9,600) and medium (4,800), and each run still paused and closed. **Not proven:** in a real window; the row order is assumed to stay as it is (a new setup row before "Planet size" would need one more Down, and the headless probe is not part of the self-test).

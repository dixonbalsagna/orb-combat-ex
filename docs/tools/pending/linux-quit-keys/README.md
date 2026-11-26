# Park: the Linux first run fails when the keys do not close the game (Tools, 2026-11-25; EP's ruling)

`linux-quit-keys.patch`. In `tools/first-run/linux-numbers.mjs` the `quit-keys` row now fails the run if the pause, Quit and "Close the game" keys do not close the program. The window manager's close stays as the fallback and its row says whether that worked. One self-test row; `docs/tools/first-run.md` rewritten on why earlier runs did not close.

Run: first-run self-test 28; workflow check. Not re-dispatched with this change: run 45777933506 closed by the keys, so it would pass.

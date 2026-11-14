# B1 re-check: the six findings after the re-cut (2026-11-14)

An independent re-check of the B1 batch against the stand-in's review (`B1-replay-build.md`). It was run by an Opus reviewer for the EP, because the stand-in was paused for the Fable reset. It was read-only.

The batch is replay-build 73b9862a, grant-netcode-build 3cd1b355, lan-stamp 5d7f7be0 and lan-hash 29146f1a, plus Tools' piece in e7f1448a and the report hook ebe79b6a (which lands with A-CODE-03).

**Verdict:** five findings are fixed and one is partly fixed. Nothing blocks the landing.

| # | Verdict | Evidence |
| :--- | :--- | :--- |
| 1. LAN clip and verifier refuse new LAN saves | Fixed | lan-stamp writes the page's own id into the kit's stamp. Netcode's run (docs/net/runs/00925b89/b1-stack/kit-and-verify.txt) shows both saves verify on `tree/` and on the page tree. |
| 2. The report hook's saves are refused by their own build | Fixed | report-hook.patch calls `SimReplay.header` when present. The recorder, `NetDesync.replayOf` and the black box all use it. |
| 3. A page build of an older commit stops compiling | Fixed | `blackbox.mjs` `hasHeader(tree)` gates the new host lines. preview.mjs and stack-preview.mjs pass it through. |
| 4. A stray stamp in the shared folder breaks parity | Fixed | Parity names the stamp and says how to clear it. The golden never plays a replay. |
| 5. The README's claim about ids is wrong | Fixed | Leftover: the self-test row label at `stack-selftest.mjs:272`. |
| 6. Smaller points | Partly | Fixed: `refusal` on the page, `--home` on the verifier, parity's one-call stamp. Open: the four readers of `build_info.json` still follow different rules. Only the file-level display can differ now, because every replay-level writer goes through `header()`. |

**The other questions:**
- **Unstamped dev trees and CI:** no build field is written and the header keys are unchanged.
- **The sim:** no state is added and nothing reads the clock in `sim/`.
- **Own saves:** no path makes a stamped build refuse its own saves.
- **lan-hash thread safety:** sound as written. The worker hashes the checkpoint's own copy-on-write copy. `save()` and the desync report wait for running jobs. A copy goes back to the pool only after its job ends.

## New defects (follow-ups, not blockers)

1. **Low to medium, Netcode:** lan_kit copies the source tree's `sim/` read-only, which includes the `sim/core/tools/blackbox_verify.gd` that the verifier writes. If someone ran a verify on the kept tree first, every later verify on the LAN folder's `tree/` fails with EPERM. The fix is to leave that file out of the copy.
2. **Low, Tools:** `lan-clip.mjs` always passes the save's own build as `home`, so a LAN clip never applies the build check.
3. **Minor, test only, Netcode:** lan-stamp's `_stampRows` holds the stamp around whole matches, the same pattern finding 6 fixed in parity.
4. **Minor, Netcode:** `lan.gd` `commit8` shortens a `--build` name that contains a dash to its first piece.

## Not verified

- The page's black box running in a browser.
- A hash job outliving its session when the game quits without calling `close()`.
- The read-only `.godot` copy in the kit's `tree/` beyond one run.

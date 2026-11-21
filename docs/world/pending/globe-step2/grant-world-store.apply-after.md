# Apply-after note for Simulation's `grant-world-store.patch` (`WorldStore.swapBlocks`), World, 2026-11-21

The grant (`docs/architecture/pending/intro-store/grant-world-store.patch`, sha1 f12828ac) is right for GW1b on main's `store.gd`: it folds each record at its kind's length (`LEN` 12, 11, 9, 11), which is what `_push` folds there, and main's records carry no index.

**After `globe-step2.diff` lands (GW1c) it is wrong twice**, and `swap-blocks-gw1c.diff` (this folder) corrects it:

1. `_push` then folds **all STRIDE (16) numbers** of a record (`_fold(h0, full)`, the slots padded to their defaults), so the swap's LEN-based refold gives a hash that pushing the blocks in the swapped order does not give: watching and skipping the intro would again start different matches.
2. Records carry `O_SUP` (slot 15), the **index** of the record they supersede. A swap that moves records without moving the indices leaves every superseded pointer on the wrong record (the check row sees `{4: 5, 5: 4, ...}` for `{4: 3, 5: 2, ...}`).

**Order:** `grant-world-store.patch` (GW1b), then `globe-step2.diff` (applies after the grant: checked), then `swap-blocks-gw1c.diff` (strict after both, and after `globe-check-pin.diff`). `swap-blocks-gw1c.diff` also removes the grant's now-unused `LEN` constant and adds `globe_check`'s `_swap` rows: a swap keeps every superseded index on the record it named; the store and its hash are exactly what pushing the blocks in the other order makes; a control (an index left unmoved) names another record so the row can fail. With the grant as it is on the globe-step2 tree both rows fail (`runs/planet-stack-recut/swap-blocks-gw1c.txt`).

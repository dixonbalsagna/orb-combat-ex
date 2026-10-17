# Parked: the calm crater fades, and the audio bank warms in headless (Rendering, 2026-10-17)

**Base:** HEAD ac4334ce, which has the 2026-10-17 batch (66405ec5). The diff was checked on a copy of that commit, never on the tree.

**Apply** from the project root:

```
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-17b/batch.diff
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-17b/batch.diff
```

`core.autocrlf=false` keeps the files LF; with it every file comes out byte for byte as gated. Then delete this folder.

## The pieces and their files

| Piece | Files |
| :--- | :--- |
| **The calm crater fades** (the EP's go, 2026-10-17; reduced mode only) | `render/shaders/ground.gdshaderinc` (`crater_new`: under `calm_ease` the colours fade in over the whole crater at once), `render/core/look.gd` (`CRATER_CALM_S` 1.5 to 3.0, its comment), `docs/rendering/flash-sources.md` (new section "The calm crater fades"), `docs/rendering/README.md` |
| **The audio bank warms in headless too** (Audio's ask, through the EP) | `render/core/main.gd` (the headless guard on `bank.warm()` removed), `docs/rendering/README.md` |

## Checked

- On a scratch copy of HEAD with the diff applied: `flash_reg_check`, `ground_check`, `open_check`, `after_check`, `hud_words_check`, `determinism` and `cue_check` pass, with no script or shader errors.
- The fade's readings come from a scratch switch with the same code on 0654a2e2 (table in `flash-sources.md`). ai-43 reduced, ticks 2700 to 3030, went from 2.5 / 3.5 / 2.5 (fail) to 2 / 2.5 / 2 (pass); the blastdummy pairings stay at 3 / 3 / 3.

## Still to run (after Orb's break)

- The EP's condition for this park: Tools' clips in both modes on HEAD and on HEAD with the park. These are the record's ai-43 and both blastdummy pairings, and collapse, mashcity, signaturecity and rushcity. Normal mode should read as main does, since the fade is reduced mode only.
- The rest of the gate set (`gates9`: 17 checks), for the headless warm in every tool.

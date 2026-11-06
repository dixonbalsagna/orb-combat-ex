# The words-only child of the pin, and the four readings (Legal RL-209)

Tools, 2026-10-30. What keeps the demo up while flash work is paused (Orb, 2026-10-30: flash work stays paused, the child of the pin is the plan, no signature fix on main).

## Why a child

Main's signature clip reads, REDUCED at 16:9, 3.5 / 3.5 / 3 (960x540, full size), worse than the live pin 257a766c's 3 / 3 / 3, and Legal's RL-209 (b) does not let the pin move to it. The live pin's in-game words are the old ones (RL-192, RL-193), and the excuse for them ends on 2026-11-08. The least change that satisfies both is the pin's own code plus only the cleared words: **the child**. It inherits the pin's grandfathering (RL-195, RL-202; RL-200 ends) to 2026-11-15 only if the signature and collapse clips, both modes, both sizes, read no worse and look the same.

## What the child is

`tools/pin-child.json` lists 17 strings in 4 files (`ui/data/terms.json`: the notice, the two card bodies and the lock line; `settings.json`: the help of "Flashing effects notice"; `options.json`: "Color-blind mode" and three helps; `howto.json`: eight licence words). Each entry names a string in the pin's file and the same string, as the cleared words, in main's `b7a2cd86`. A feature, a new key or a moved item in main is not a word and is never copied (the diff of `ui/data` between the pin and main also holds toggle styles, text size and volume, which are not in the child).

```
node tools/pin-child.mjs --check                 the 17 strings, and a proof that nothing else in ui/data differs from the pin
node tools/pin-child.mjs --commit-id             the child commit's id, computed in a throwaway object directory (the repo is not written)
node tools/pin-child.mjs --patch <file>          a patch against the pin
node tools/pin-child.mjs --tree <dir> --recipe   the changed files written to <dir>, and the git plumbing that makes the commit for real
```

The text of each file is edited, not re-serialised (the old string as JSON must occur once; it becomes the new one), then the child's parsed JSON is compared with the pin's parsed JSON with only the listed strings changed. The author, committer, dates and message are fixed in the config, so **the commit id is known before the commit exists** (`302d0be9...` today; the self-test and a scratch clone both reproduce it): the pin move can name it, and the EP's recipe makes that same commit without touching the work tree, the index or any branch. The commit needs a branch (the site pin names its id and CI's export reads it with `git archive`).

`node tools/pin-child-selftest.mjs` (16 checks) covers the replacements, the proof, the ambiguity refusals, the patch (it applies to the pin) and the id (same twice, same as the recipe's commit, no object written).

## The proof that the child is the pin

Legal's condition is that the signature and collapse clips, both modes, both sizes, are byte-identical or within noise to the pin's by the frame comparison, then the nightly on the child. The words are in menus and cards the clips never show, so the frames should be the pin's. `tools/flash/compare-frames.mjs` compares the child's frames with the pin's at every tick; the noise bound is the pin against itself (collapse is not byte-reproducible even build against itself: `render/shaders/crowd.gdshader` reads the engine's clock, see load-and-captures.md).

## The four readings (tools)

`tools/flash/readings.mjs`: a clip is captured at 960x540 (the primary) and at 1024x768, and each capture is read at full size and at the analyser's default scale for its width (2 for both: a box average down to 640 or under). **The worst of the four counts**, number by number, for the gate and for the interim's 3.5 trigger. `run-pixels.mjs` does it by default (`--sizes 960x540,1024x768` to choose); its `summary.json` rows keep `result` in the analyser's own shape (so the nightly, the release pass and the signature gate read them as before) with the worst numbers, and add `readings` (each of the four) and `worst` (which one). The second size's folder is `<id>@1024x768`. A clip costs twice the capture time (about 25 minutes, so a 16-clip nightly about 6 hours: pass `--sizes 960x540` to halve it where Legal's rule allows).

`tools/flash/signature-gate.mjs --record-child <child summary> --pin-summary <pin summary> --commit <child> --of <pin>` records the child as grandfathered when **no reading** (each of the four, each of primary, red, area-15% and the two-second memory, of the signature and collapse clips, both modes) is worse than the pin's, and re-points the RL-202 engine-flip entry at the child. It refuses, writing nothing, when one is worse or missing.

## State at the pause (2026-10-30, evening) and what resumes

Done, in scratch and in the parks:
- The child's data strings (`pin-child.json`, 17 strings in 4 files), its commit id (`302d0be9...`, reproduced by the recipe in a scratch clone), its Web export (scratch, custom template, lock and hook as the nightly's measurement export).
- The four readings of the pin and of main, reduced and normal, signature, collapse and (reduced) clash. The pin's worst of four (primary / area-15% / memory): signature reduced 3 / 3 / 3, normal 2.5 / 2.5 / 3; collapse reduced 2.5 / 2.5 / 2.5, normal 3.5 / 3.5 / 2; clash reduced 2 / 2 / 2. Main's: signature reduced 3.5 / 3.5 / 3 (blocked), normal 3.5 / 4.5 / 3.5; collapse reduced 2.5 / 3 / 2, normal 3.5 / 3.5 / 2.
- The nightly on the pin (custom template, 16 clips at 1024x768 full-size, none over 3.5; exit 3 is the signature clip's grandfathered 3 / 3 / 3), and the reduced seeds re-read at 960x540 full-size: 1049 3.5 / 4.5 / 3.5, 1050 3.5 / 3.5 / 3.5, 1051 1.5 / 2.5 / 1.5, 1053 1.5 / 2.5 / 2, 1054 2.5 / 2.5 / 2.5. RL-212's tripwires (primary over 3.5, area-15% over 4.5) have not tripped; 1049 and 1050 are at the line.

Not done (resumes at start-up, in this order): ai-1055-reduced at 960x540 (its capture was stopped by the pause); the second capture of ai-1049-reduced at 960x540 with its frames kept, and what is on screen at ticks 853 to 880 (the headless register shows no flash ask between 780 and 892, so the seven changes are not register flashes; the owner is Rendering or VFX once the frames are seen); main's clash (reduced, then both normals) and the pin's clash-normal; the child's proof run (`run-pixels` with both sizes on the child's export, frames kept, then `compare-frames` against the pin's kept frames at both sizes, noise from the pin against itself) and `signature-gate --record-child`; the nightly on the child; the load experiment's window re-capture and starved capture; the route check's first real run; the pin-move commit's files (site.json, signature-gate record, excuse and grandfather files).

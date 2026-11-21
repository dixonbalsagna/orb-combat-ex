# release-pass-redo (park, Tools, 2026-11-21; the EP's word)

`release-pass-redo.patch` (sha1 21f861e785d49e5bc167800b72817cb3b9c81d3b, one file, `git apply --check` passes on d168a518): a `toRedo` note in `tools/flash/release-pass.json`, for whoever records the next full pass.

- mashdummy (4 clips): its staging now taps the heavy three times (d168a518); the headless register recount passes, but no pixel capture or reading of the three-heavy clip exists.
- signaturedummy (4 clips, found while writing the note): its scenario is 3,600 ticks now, and a pixel clip is as long as its scenario, so each of its clips takes twice as long to capture and read.

The record is already superseded and holds for no commit, so nothing about `--verify` changes: `release-pass.mjs` ignores the new key (self-test 113 checks pass with it in place, on a scratch copy).

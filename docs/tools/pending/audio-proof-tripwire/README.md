# Park: the --audio-proof safeguard in the route scan (Tools, 2026-11-25; EP's yes)

`audio-proof-tripwire.patch`, cut on HEAD 735505c6. `git apply docs/tools/pending/audio-proof-tripwire/audio-proof-tripwire.patch`.

`desktop-package.mjs routes` now fails unless, whenever any packed script reads `--audio-proof`:
- the branch is the first thing `render/core/boot_entry.gd`'s `_ready()` does, adds only the proof node and returns;
- no other script reads the argument, and the entry reads it once;
- `audio/audio_proof.gd` loads nothing under `res://render/`.

Every desktop build runs `routes`, and CI runs the packaging self-test against the tree. Self-test 170 (was 165); the scan passes on a locked copy of HEAD.

**It reads text only:** a branch rewritten in another form fails (look and update the pattern); a proof that reached the picture by some route other than a `res://render/` path would not be seen.

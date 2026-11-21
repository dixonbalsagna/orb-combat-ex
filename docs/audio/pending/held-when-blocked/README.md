# Park: hold cues while the browser holds the sound back (Audio and Music, 2026-11-14)

Why: docs/audio/drops.md. While the page player's context is not running, one-shot cues fell to Godot players on the engine's frozen context, which stay "playing", fill the 16-voice pool (30.6% dropped in the model, 29% in Orb's play file) and burst when the context wakes.

What: `held-when-blocked.patch` (`git apply --check` clean against HEAD 51b840f5), three files, all Audio's:
- `audio/audio_web.gd`: `AudioWeb.blocked()` = the player is installed and its context is not running.
- `audio/audio_voices.gd`: `held` counter; `play()` returns false and counts `held` for a non-update cue while `web.blocked()`; the web part of the status line ends with ` | held N`.
- `audio/tools/web_policy_check.gd`: the old line ("the Godot player takes it while the page's context is not running") is replaced by "the cue is held, nothing is queued, no Godot player starts, it is counted as held and not dropped", plus "a held cue is not a drop".

Proof (scratch export of HEAD plus the A1 files): `web_policy_check` passes (record: runs/51b840f5/web_policy_check-with-held-patch.txt), `status_check` and `tug_check` pass. The model: `drop_probe.gd --suspend=60 --hold` gives 0 no-slot drops against 1,530 without it (runs/51b840f5/drop_probe-*.txt). Real browser: `web_voices_check.mjs` is not affected (it tests the page player alone) and was not rerun.

Not done: it changes what a build does before the first key, so Orb should hear a pad-only start once (the sound arrives with the first key or click, and nothing plays in a pile). Frozen on the three files until the EP says; this park is in the tree only as the patch.

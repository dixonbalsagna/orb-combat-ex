# A1 sound sets (A-AUDIO-01), cut for GW1a

Audio's sound-set group, which lived only as working-tree edits, cut into one patch by the EP so it can stack in GW1a. The design is in `docs/audio/a1-sound-sets.md`.

- `sound-sets.patch` (sha1 starts ca74d3d82eaf):
  - `audio/data/{tug,moment,carry}_cues.json`;
  - `audio/tools/{tug,moments,carry}_check.gd`;
  - the new `audio/tools/sets_check.gd` and `drop_probe.gd`.
- It lands in GW1a with Tools' CI step for `sets_check` (`docs/tools/pending/ci-later/` §1).
- Audio only: no sim state, no hash change.

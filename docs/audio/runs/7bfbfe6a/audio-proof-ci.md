# Audio proof on the exported programs, `7bfbfe6a` (A-AUDIO-04, criterion 3)

Desktop builds run 45767037480 (workflow_dispatch), **success**. Full record (Tools'): `docs/tools/runs/7bfbfe6a/desktop-run-45767037480.md`.
The figures below are as the EP reported them from the run; Linux and Windows gave identical numbers.

| Row | Result |
| :--- | :--- |
| Limiter | a -18 dB tone out at -13.0, a +7 dB tone at -1.0, shape kept |
| The 8 cues | all ok at their expected lengths, peaks -14.6 to -4.6 dB |
| Nine loud sounds at once | held at -1.0 dB, nothing clipped |
| Wind loop | -29.7 dB |
| Nothing asked for | silence |

**Limit:** the engine's dummy audio driver. This proves the program, its data and its mixer, **not** that any machine's speakers play it.

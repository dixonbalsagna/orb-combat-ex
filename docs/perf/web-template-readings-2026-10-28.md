# The custom web engine's four readings, on the live pin (2026-10-28)

Owner: Performance and Platform, for the EP and Tools. Brief: the EP, 2026-10-28 (the readings `"template": "custom"` needs, `docs/tools/site-template.md`). Template: release `web-template-4.7.2-lazy-1`, zip SHA-512 starting `f0b7b0805ef3d63e` (fetched with `node tools/site-template.mjs --download`, size and both hashes verified). Commit: the **live pin 257a766c** (the one `tools/site.json` serves and `check` compares against), not the next one.

## Result in one line

All four readings are taken on the custom export and recorded in a parked copy of `tools/web-template.json`. **`--check` with custom in a scratch site.json fails on one line only: the signature clip, reduced, reads 3 / 3 / 3, over the RL-195 limit of 2.5 / 3 / 2. The standard template reads the very same numbers on this commit, and its frames are byte-identical: the pin itself is over that limit** (the grandfathered record in `tools/flash/signature-gate.json` says the same: reduced 3 / 3 / 3). That is a ruling for Legal and the EP, not a reading to adjust. Parked at `docs/perf/pending/web-template-readings/`.

## Method

- Two scratch exports of 257a766c from `exportPinned` (the nightly's own: Reduce flashing locked on, capture hook on), identical but for the template: the custom zip, and the standard template. Each 26 s. The custom `index.wasm` is 38,450,604 bytes (the pinned `godot.wasm` size), the standard 39,514,754. `tools/site.json` was not touched (a scratch script passes `template` to `exportPinned`).
- Signature and collapse, both modes, 1500 ticks, seed 12345, through `tools/flash/run-pixels.mjs` (Tools' launcher, below-normal, 25% core cap, 2 jobs, one run at a time, frames kept): once on the custom export, once on the standard, once more on the standard (the noise capture). Every run started after the quiet check. The verdicts count frames, not time, so load does not move them.
- Nightly: `tools/flash/nightly-seeds.mjs --pin 257a766c…` on the custom export, 8 new seeds (1040 to 1047) in both modes plus the signature clip, scratch history file (the repo's `nightly-seeds.json` is untouched), limit 3.5 (the owner-approved interim, from `site-interim-owner.json`).
- Frames: `tools/flash/compare-frames.mjs`, standard against custom, per clip, with the second standard capture as the noise capture.

## The readings (primary / area-15% / two-second memory)

| Clip, pin 257a766c | Standard | Custom |
|---|---|---|
| signature, normal | 2.5 / 2.5 / 3 | 2.5 / 2.5 / 3 |
| signature, **reduced** | 3 / 3 / 3 | **3 / 3 / 3** (limit 2.5 / 3 / 2: over on primary and two-second memory) |
| collapse, normal | 2 / 3.5 / 1 | 2 / 3.5 / 1 |
| collapse, reduced | 2 / 2.5 / 2 | 2 / 2.5 / 2 |
| nightly (8 seeds x 2 modes) | | 16 of 16 read, none missing, none over 3.5; largest 3.5 (`ai-1047-reduced`) |
| signature in the nightly | | normal 2.5 / 2.5 / 3, reduced 3 / 3 / 3 (the same) |

The standard readings of the signature clip equal Tools' recorded ones for this pin (`signature-gate.json`, `docs/tools/signature-bisect-2026-10-27.md`). The nightly's 3.5 is the content, not the engine: seed 1047 re-run on both templates reads 3.5 / 3.5 / 3.5 reduced and 2.5 / 3.5 / 2.5 normal on each, and the frames are the same (3,596 of 3,600 identical in each mode, 4 within the floor, 0 beyond). Earlier nightlies on this pin also peaked at 3.5 (2026-10-19, 2026-10-22; 3 on 2026-10-23).

## Frame comparison, standard against custom (RL-199 item 1)

| Clip | Frames | Identical | Within noise | Beyond noise | Worst frame / bound (% of pixels) |
|---|---|---|---|---|---|
| signature, normal | 1500 | 1500 | 0 | 0 | 0.000 / 0.100 |
| signature, reduced | 1500 | 1499 | 1 | 0 | 0.000 / 0.100 |
| collapse, normal | 1500 | 208 | 1292 | 0 | 0.112 / 0.113 |
| collapse, reduced | 1500 | 195 | 1305 | 0 | 0.112 / 0.157 |
| **Total** | **6000** | **3402** | **2598** | **0** | |

No frame is beyond noise, so the full set is not required by the check (`measured.full` stays null). Two things to know: the collapse clip is not byte-reproducible even standard against standard (the noise capture's worst frame is 0.091% and 0.126% of pixels), and the custom's worst collapse-normal frame, 0.1124%, sits just under that clip's bound, 0.1132%. The bound is the check's own rule (1.25 x the noise capture); read it as "the same as the standard build's own jitter", not as margin. The extra seed-1047 pair adds 7,200 frames, none beyond the floor. Mash was byte-identical in all 600 frames in the earlier template study (`web-template-2026-10-28.md`).

## `--check`, in a scratch site.json with `"template": "custom"`

```
site template check FAILED: measured.signature.reduced reads worse than 2.5 / 3 / 2 (Legal RL-195 condition (a)): the pin cannot move to it
```

That is the only line: parity, collapse, nightly and frames all pass with the readings above. Re-run it with `node tools/site-template.mjs --check --config docs/perf/pending/web-template-readings/scratch-site.json --record docs/perf/pending/web-template-readings/web-template.json` (the scratch site.json is the real one with `"template": "custom"`).

## What this does and does not say

- **The engine changes nothing the flash gate reads**: 13,200 frames, standard against custom, with zero beyond noise, and every reading identical, on this pin. The signature clip's reduced reading is a property of the pin's content, present on the standard template today.
- **The check is stricter than the pin it guards.** RL-195's limit is written for a pin move (a new commit must read no worse than 2.5 / 3 / 2 reduced); `check-site-interim.mjs` lets the standing pin through as grandfathered. `site-template.mjs` applies the limit to the custom record with no such allowance, so the flip is refused for a reading the live site already has. Options for the EP and Legal: a ruling that for a template flip on a grandfathered pin the condition is "no worse than the standard build of the same commit" (Tools would add that case to `recordProblems`), or waiting for the renewal's new pin to pass the limit and taking the custom readings on it.
- **If the readings are meant for the next pin**, they do not carry over: each reading carries the zip's SHA-512 and a commit, and `nightly` and `frames` must equal the pin. The renewal moves the pin, so these four have to be re-taken on it (about 2 hours of captures: the exports 1 minute, the 12 clips 36 minutes, the nightly about 2 hours, the frame comparison 10 minutes). The recipe is at the end of this note.

## Not covered

Radeon and other browsers (Chrome only); the full required set (not required: no frame beyond noise); a release or a Reduce-flashing toggle restore (RL-199 item 3: still needs the full set on the custom build, a standing rule); the `web-parity.yml` job on the custom template.

## Files and recipe

`docs/perf/pending/web-template-readings/`: `web-template.json` (the full record, readings filled), `web-template.patch` (against HEAD's `tools/web-template.json`, applies cleanly), `scratch-site.json`. Raw runs in my scratch folder (`r/`: `clips-cus`, `clips-std`, `clips-noise`, `cmp-*.json`, `nc/`, `ns/`, `s1047-*`, `nightly.log`). Recipe: a scratch script calls `exportPinned(pin, out/web, { tree, godot, lock: true, hook: true, template: <zip or null> })` from `tools/site-pin.mjs`; `run-pixels.mjs --clip signature-normal,signature-reduced,collapse-normal,collapse-reduced --keep` on each export; `compare-frames.mjs --standard --custom --noise --json` per clip; `nightly-seeds.mjs --pin <sha> --work <dir whose <sha7>/web is the custom export> --history <scratch copy>`; the record's counts are the sums of the four comparisons.

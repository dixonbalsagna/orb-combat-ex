# The custom web template (lazy shader specialization), standard against custom (2026-10-28)

Owner: Performance and Platform, for the EP and Tools. Brief: `docs/tools/cloud-reports/2026-10-28-web-template.md`, NEEDS item 2. The template is Tools' GitHub Actions run 40624057612 (the lazy-specialization patch, no trims), `web_nothreads_release.zip`, 9,861,157 bytes, SHA-512 starting `f0b7b0805ef3d63e` (matches the file beside it). The wasm in it is 38,450,604 bytes against the standard template's 39,514,754.

## Method

Two scratch web exports of main **9631fc75**, identical but for the template: `make-audit-sites.mjs --rev 9631fc75 --only plain,bp3,pblay`, the second with the new `--template <zip>` option (it writes `custom_template/release` into the scratch copy's `export_presets.cfg` only; the repo's preset is untouched). `plain` is the commit as it is, `bp3` has boot marks, `pblay` is the coast scene. RTX 5070 Ti, Chrome 156 through Tools' launcher (below-normal priority, one browser at a time). Every timed run passed the quiet check first (`audit/quiet.cjs`) and the frame-bench load rule; runs are alternated standard, custom. The sim parity run and the picture captures do not depend on timing and ran under whatever load there was.

## Results

| Check | Standard template | Custom template |
|---|---|---|
| **Sim parity** (`web_parity`, 51 keys against `golden.json`) | not run (CI's `web-parity.yml` passes it) | **all 51 keys match**; the one DIFF line is the engine label, see below |
| **Link wait**, x1 (`linktime.mjs`, 2 runs) | 156 programs, 15.2 and 14.7 s waited in all, 17 and 16 programs over 200 ms | **43 programs, 4.47 and 4.45 s**, 5 over 200 ms |
| Link wait, CPU x4 | 156 programs, 15.7 s | 43 programs, 4.46 s |
| **Boot done** (page clock, `freeze-probe` marks), x1 (2 runs each) | 27.7 and 26.4 s | **15.1 and 14.0 s** |
| Boot done, CPU x4 | 43.6 s | 33.0 s |
| Long tasks, sum, x1 / x4 | 26.0, 26.1 s / 73.3 s | 14.1, 14.6 s / 72.4 s |
| Stalls over 250 ms in the 45 s probe, x1 | 23, 23 | 11, 11 |
| Longest main-thread block, x1 / x4 | 4.72, 4.37 s / 14.9 s | 3.15, 3.21 s / 14.6 s |
| Frame bench, coast scene, x1, p50 / p95 / p99 (2 runs) | 7.5 / 15.6 / 33.3 and 7.4 / 14.6 / 32.6 ms | 7.6 / 16.4 / 33.9 and 8.0 / 17.0 / 34.8 ms |
| Frame bench, x1, slowest frame | 534 and 504 ms | 278 and 278 ms |
| Frame bench, x4, p50 / p95 / p99 | 58.9 / 85.6 / 95.8 ms | 57.3 / 89.1 / 105.2 ms |
| Draw calls, view update, tick (all runs) | 238, 1.5 to 1.6 ms, 0.3 ms (x4: 10.9 ms, 2 ms) | 238, 1.6 to 1.7 ms, 0.3 ms (x4: 11.2 ms, 2 ms) |
| **Look**, mash scene, 600 ticks, seed 12345 | | **600 of 600 frames byte-identical** |
| Look, collapse scene, normal and reduced | | no difference beyond the scene's own noise, see below |

- **The default programs and their wait are gone.** 156 programs fall to 43 and the wait from about 15 s to 4.5 s, a saving of about 10.5 s, at x1 and x4 alike (it is a driver wait, not CPU-scaled). The remaining 5 programs over 200 ms are the ones the game draws (0.3 to 0.8 s each).
- **Boot is about 12 s shorter at x1 and 10.6 s shorter at x4** (27 to 14.5 s, 43.6 to 33.0 s). The x4 start block (the longest main-thread block, 14.9 against 14.6 s) does not move: only the shader wait does. The longest block at x1 falls from 4.4 to 4.7 s down to 3.2 s. These boot times are on 9631fc75, so they are longer than the 22.6 to 23.5 s measured on 3d276d57 (a few commits of new shaders and scripts since); compare standard with custom within this table only.
- **Steady frames are unchanged within the noise.** Medians match (7.4 to 7.5 against 7.6 to 8.0 ms); the custom p95 reads 0.8 and 2.4 ms higher, but its second run ran at 30 to 40% machine load against 17 to 19% (valid by the rule, not equal); at x4 the p95 is 3.5 ms higher and the p99 9 ms higher with the load 27 to 35% against 18 to 27%. One pair each; I would not call it a change, and the build difference (`lto=none` against the release's `lto=thin`) is the only suspect if a repeat shows it. The slowest frame, the scene's opening, halves (534 to 278 ms) because the first draws no longer wait on the defaults.
- **Sim parity.** `web_parity` on the custom template: 51 of 51 keys equal to the golden (a scratch copy of the tool that takes a template path, `tools/make-web-parity-template.cjs`). The tool still exits 1, on one line: `DIFF web godot against golden.json: "4.7.2-stable (custom_build)" vs "4.7.2-stable (official)"`. That is the engine label, not the sim. `web-parity.yml` would fail on a custom template until Simulation lets `custom_build` through (their tool, `sim/core/tools/web_parity.mjs`, and `golden.json`'s `godot` field).
- **Look.** Mash: byte-identical in all 600 frames. Collapse: not byte-reproducible even standard against standard (two captures of the standard build differ in 598 of 600 frames, by a few hundred pixels each), so I measured the pixel difference. Standard against standard: mean 0.043 of 255 at most, at most 0.078% of pixels differ by more than 30. Standard against custom, normal: 0.031, 0.075%. Reduced mode, standard against custom: 0.017, 0.070%. The custom build is inside the scene's own noise. Side-by-side stills (left standard, right custom; the corner labels `aa` and `bb` are the font's only letters, not hashes): `img/web-template-2026-10-28/collapse-t00150.png` and `collapse-t00450.png`. No dissolves, fades, blur or markers involved; the look gate has nothing to flag.

## Not covered

Radeon, x6, the phone-size freeze in a real phone, the Safari/Firefox engines (Chrome only), the site checks (`tools/check-site-offline.mjs`, the site job), the flash analyser's both-modes pixel run (only the mash and collapse clips above), the template with trims, `KHR_parallel_shader_compile`. Single or paired runs: where two exist they are shown.

## Files

`tools/make-audit-sites.mjs` (new `--template <zip>`), `tools/make-web-parity-template.cjs`, raw runs in my scratch folder (`w/wtrun/`), stills in `img/web-template-2026-10-28/`.

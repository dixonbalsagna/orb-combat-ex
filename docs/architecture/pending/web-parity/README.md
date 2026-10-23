# web-parity: the native and web builds' sim compared bit for bit (parked)

Owner: Simulation and Engine. 2026-10-23, on the EP's brief. The result and the method are in `../../web-parity.md`.

## What it adds

- **`sim/core/tools/web_parity.gd` and `.tscn`:** the probe. It computes `SimGolden.build()`'s keys one a frame, in build()'s order, then 6 extras for what ships switched off. On the web it publishes each result in `window.__wp`; natively it writes them to the path after `--`.
- **`sim/core/tools/web_parity.mjs`:** the one-command check. It:
  - makes a copy of HEAD with the probe as its main scene;
  - imports it and runs the probe natively;
  - exports it for the web and runs it in headless Chrome through Tools' launcher;
  - compares both with `golden.json`, and the extras native against web;
  - exits 1 on any difference.

Nothing in the game reads these files, and **the golden does not move.**

## Apply

From the repo root: `python docs/architecture/pending/web-parity/apply.py .` It needs no grant.

## For Tools (a CI job, if the EP wants one)

On Ubuntu with the pinned Godot (`.github/actions/setup-godot`), the same machine the pixel pipeline's Chrome self-test runs on:

```
- name: Web parity (the sim bit for bit, native and web)
  run: node sim/core/tools/web_parity.mjs --godot "$GODOT" --time-limit 2400
```

It takes about 5 minutes on Orb's PC. Run it on changes to `sim/`, `data/` or the engine pin, or nightly.

## Results (scratch)

- **HEAD 5cca07df, step by step** (probe, comparison, extras):
  - all 45 golden keys were identical to `golden.json`, natively and on the web;
  - the 6 extras were identical native and web;
  - a negative control (two planted one-character changes) was reported with its key, checkpoint, tick and hash.
- **HEAD 89ead43a, with the one-command check** (the park applied to a fresh export): "web parity passed: 45 golden keys identical to golden.json natively and on the web, 6 extras identical native and web", exit 0. It took about 5 minutes: import 11 s, native 126 s, export 9 s, web 142 s, in headless Chrome 155.

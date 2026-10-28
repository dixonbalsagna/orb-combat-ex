# web-parity-label: the engine's build label is not a difference (parked)

Owner: Simulation and Engine. 2026-10-28, on the EP's ask from Performance's run on the custom web template (the lazy-specialization patch). All 51 keys matched the golden, but `web_parity.mjs` exited 1. The web's engine string was "4.7.2-stable (custom_build)", and `golden.json` has "4.7.2-stable (official)". The page is `../../web-parity.md`.

## What it changes

One file, mine: `sim/core/tools/web_parity.mjs`.

- **The `godot` key is compared by its version only.** The version is the string before the build's label in brackets.
  - The same version under another label passes.
  - Any other version fails, as before. So does a missing string.
  - Every other key, checkpoint and extra is compared as before.
- **The labels are printed** on every run, as `[web-parity] engine: golden.json …, native …, web …`. When only the labels differ, the line adds "(the same version under another build label: not a difference)".
- **`--self-test`** runs the comparison on made-up results, with no Godot, no browser and no copy of the project. It has 12 checks:
  - the same label;
  - a custom build on the web;
  - a custom build on both;
  - another version on the web, natively, and on both;
  - no engine string;
  - a custom build with a key, a checkpoint, an extra or a stray key that differs (each still fails);
  - the printed labels.
- `.github/workflows/web-parity.yml` doesn't check the label (it only runs the tool), so it needs no change.

## Apply

On main (9d367592 or later, where `web_parity.mjs` is blob f897bcf7), from the repo root:

```
git -c core.autocrlf=false apply docs/architecture/pending/web-parity-label/web-parity-label.diff
node sim/core/tools/web_parity.mjs --self-test
```

The diff covers 1 file, sha1 7a77ae4109a1. Applied to HEAD's file, it gives the proven copy byte for byte.

## Results (node only, no Godot)

- **The self-test:** ok, 12 checks.
- **The old rule fails it:** with the `godot` key compared exactly, as on main, it fails 6 of 12 (every custom-build case).
- **A real run replayed** (scratch, through `compare`): the native and web results of the 2026-10-23 web-parity run, with the web's label rewritten to "(custom_build)".
  - Against the golden of that day (5cca07df or 89ead43a): 0 differences, 45 golden keys and 6 extras. The engine line shows the three labels.
  - Against today's golden: it still fails, on the 4 keys that have changed since.

## For others after it lands

- **Tools (optional):** the self-test is cheap enough for the main CI, as a step in `.github/workflows/ci.yml`:

  ```
  - name: Web parity's comparison (self-test)
    run: node sim/core/tools/web_parity.mjs --self-test
  ```

# Parked: the energy model on Orb's page, the travel slider (Tools' verification of Simulation's grant, G4)

Tools, 2026-11-07, for the EP's brief for Sunday's G4 (the page turns the energy model on by default, with a travel slider; the data stays off, so the golden does not move). The runs are in `docs/tools/runs/ba87218e/` (CD-22: `g4-*`).

## Apply (from the repository root, in this order)

```
git -c core.autocrlf=false apply docs/tools/pending/power-page/grant-tools-page.patch
git -c core.autocrlf=false apply docs/tools/pending/power-page/tools-power-page-extra.patch
```

| Patch | Files | sha1 |
| :--- | :--- | :--- |
| `grant-tools-page.patch`: Simulation's, **unchanged** | `tools/preview/switches.mjs`, `blackbox.mjs`, `preview-selftest.mjs`, `docs/tools/preview.md` | 64221d571039fbbc737dbb22b6cfd34c76071c29 |
| `tools-power-page-extra.patch`: Tools' | `tools/preview/blackbox.mjs` (one line), `tools/preview/power-page-check.mjs` (new), `docs/tools/preview.md` (a paragraph) | 5da350a685eaccef6e272aa23af903bc8b08e859 |

Simulation's travel grant (`docs/architecture/pending/power-travel/grant-tools-travel.patch`, sha1 89125318a7469a8a3f2473ab12048a3cbe65fdce) is reviewed here, not copied: **APPROVED** (`runs/ba87218e/g4-travel-grant-review.txt`): the data change alone fails validation ("unknown property travel"), with the grant validation is clean (299 files, 0 errors), and the page's `?travel=` feeds the same `"travel"` setup key and range (1.25 to 2.0). The schema makes `travel` required, so the data change, the grant and the page patch land together.

## What was checked (the brief's five items)

1. **Applies.** The grant applies to HEAD (ba87218e; and to the working tree, `git apply --check`), and the extra applies on top of it. The first message quoted the sha256's start (4a8999c2d65f); the file's sha1 is the one above.
2. **Self-tests, through the launcher:** `preview-selftest --require-browser` 151 checks ok in a patched copy of HEAD; the stack and pack-verify self-tests ok (`g4-selftests.txt`).
3. **The dry run, in a real built page** (`tools/preview/power-page-check.mjs`; `g4-power-page-check.txt`): no word and `?power=1`: black box setup `power true, travel 2, flatOut 5000`, two sliders on the page; `?power=0` and `?power=off`: `power false`, no `travel` or `flatOut` key, no slider; `?travel=1.5&flatout=6000`: the setup carries 1.5 and 6000; an out-of-range pair (`travel=9&flatout=100`) is ignored (2 and 5000); the sliders move `window.__travel` / `window.__flatout`, are remembered as `orb_travel` and `orb_flatout`, and the labels read "how far a launch carries x1.55" and "flat-out flight base speed 6200". The black box's own record of the setup is what is read.
4. **The pack verify** still reads the switch list: the dry-run build reads 73 keys out of its pack, 0 problems (`g4-build.txt`, `g4-pck-verify.txt`).
5. **Outputs** are under `docs/tools/runs/ba87218e/`.

## A defect found, and the one added line

The grant's README says `?flatout=N` starts the flat-out slider at N. On the web it never did: the page head set `window.__flatout` to the slider's own value (5000 or the remembered one) and the game takes that first, so the word never reached the setup (first run: `?flatout=6000` gave a setup flatOut of 5000). `tools-power-page-extra.patch` adds one line to the head so it reads `?flatout=N` (3,500 to 7,000) as it reads `?travel=`; an out-of-range word is ignored by the head, as travel's is. After it, the same check passes: `?flatout=6000` gives 6000.

## Not done / notes

- The travel key is read only by a tree that has Simulation's `power-travel` (`SimPower.setup`); on a tree without it the setup carries `"travel"` and the sim ignores it (the black box still records it).
- The check opens a browser per address (about 20 minutes for the six, below-normal, one at a time); it is a Sunday-build step, not a CI step.
- Camera's chase_rush already flaps with the model on (the EP routed it to Camera); it does not touch this park.
- After it lands: delete this folder and `docs/architecture/pending/power-page/`.

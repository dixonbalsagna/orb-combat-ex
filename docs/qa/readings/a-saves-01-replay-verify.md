# A-SAVES-01: a saved replay verifies to its last tick on its own build (QA, run 2026-11-14)

**What it measures.** That one of Orb's saved play files of the baseline build, replayed through the project's own replay path on that build's tree, reproduces its final hash.

**Tool.** `tools/preview/blackbox-verify.mjs` (Tools'). **Command:**

```
node tools/preview/blackbox-verify.mjs <orb-first-play-20261109-1646.json> --tree <copy of the 6a30b4c9 tree>
```

**Tree.** Build 6a30b4c9's tree (`homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree`), copied to scratch so the kept folder is untouched; no patch.

**Result.** `BLACKBOX OK ticks=19388 final=27cf5381b18eb2cd`. The file is a match played to its end (a KO), and its recorded final hash is reproduced to the last tick. The other file of that day (1625) is a cut-short play with no final hash and no checkpoints, so only a run to its last tick is possible for it. Record: `docs/qa/runs/6a30b4c9/blackbox-verify-1646.txt`.

**Not done.** The criterion also asks for the first real LAN save to be put through the report tool; no LAN save exists in the project's folders yet (the LAN build has no end-of-match save until Netcode's lan-stamp lands). It runs when the first one exists. A-NET-05 (the build id in a replay) lands before GW1; this reading is to be repeated after it.

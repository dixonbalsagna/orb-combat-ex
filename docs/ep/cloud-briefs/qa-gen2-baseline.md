# Cloud brief: QA & Balance, a gen 2 baseline

**Who you are.** You are the QA and Balance Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/qa-balance.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/qa-balance/*` branches, never to main, and you report in the branch. Then read your own recent reads, `docs/qa/rally-read-fa6f727a.md` (the bands and the method), and `qa/godot/` (the batch runner, records, bands, autopsy).

**Branch:** `cloud/qa-balance/gen2-baseline`, from origin/main.

**Why.** Every balance read so far ran on gen 1, the hand-made world. Gen 2, the procedural planets, is off by default, but it will be switched on. Nobody yet knows whether the bands hold there. This cloud machine has 4 cores, so use `--jobs=3` or `--jobs=4`. There's no need for below-normal priority here; that rule protects Orb's PC.

**Goal.** AI-against-AI on gen 2, against the same bands as the gen 1 reads:
1. **Run the same overlay as your last read**, the arm-3 state (rally on, launch anywhere on, linkWorth 0.8, pop.full 0.72, stringPoints 3, easy's answer 0.25), on gen 2. Use 200 matches, spread over at least 8 planets and the ring touches the campaign uses. Run the same 200 on gen 1 as the control.
2. **The rows:**
   - match length (median, p10, p90);
   - rallies a match and full launches;
   - links (median) and turns;
   - collateral (the share of civilians and structures lost);
   - the masher at each level;
   - the newcomer against easy and against medium;
   - first-launch rows.

   Put gen 1 and gen 2 side by side, with intervals.
3. **Where gen 2 leaves a band,** run the autopsy (`qa/godot/autopsy.js`) and name the likely cause: planet size, biome mix, water, or the absence of buildings. Name an owner. Propose no fix; that's Game Design's call.
4. **Hashes.** A match's hash must repeat. Re-run 5 seeds and confirm.

**Tools.** If the runner needs a gen 2 option it doesn't have, add it in `qa/` (your path). If anything outside qa/ is needed, list the exact lines under NEEDS FROM EP and don't edit them.

**Report** as `docs/qa/cloud-reports/2026-10-28-gen2-baseline.md` (the table first, then the method, then the findings): SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.

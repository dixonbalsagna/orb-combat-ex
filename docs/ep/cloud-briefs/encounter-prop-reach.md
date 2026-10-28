# Cloud brief: Encounter Systems, PROP SMASH reaches its prop, and the zip.price lead

**Who you are.** You are the Encounter Systems Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/encounter-systems.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/encounter-systems/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else install the pinned Linux build as cloud-workflow.md says. Then read:
- World's W6 report, `docs/world/cloud-reports/2026-10-28-biomes-w6.md`, NEEDS 1. W6 is on main as ede6490b, and `sim/world/tools/flighthooks_probe.gd` is in it;
- your W3 report;
- QA's `docs/qa/cloud-reports/2026-10-28-gen2-baseline.md`, the "Leads" paragraph.

**Branch:** `cloud/encounter-systems/prop-reach` from origin/main.

**Build:**
1. **PROP SMASH reaches its prop.** In World's probe, 3 of 10 PROP SMASH launches stopped short of the prop and 1 passed over a low boulder's top. The planner's `land` is the prop, but the force isn't set to reach it, and the line test reads his height at launch rather than in flight. Do one of these, and say which and why:
   - offer PROP SMASH only when the predicted flight reaches the prop below its top;
   - set its force the way BUILDING SMASH aims.

   The candidate's pick share must stay inside QA's band. Re-read it with `launchbiome_batch.gd --on`.
2. **The zip.price lead.** QA's gen 2 records show one zip priced off the table: seed 105, gen 2 planet 17, touch 2, a light paid 21.77. Re-run that match with the director line and find out whether it's a real price bug or a same-tick ki change. If it's real, fix it; if not, say so.

**Acceptance criteria:**
- the golden is byte-identical with `biome.enabled` off;
- determinism passes plain and with `--intro`, with the switch off and on;
- `flighthooks_probe`'s prop line reads every launch that reached the prop as stopping at it, with none short and none over;
- `launchbiome_probe`, `sigafter_probe`, all World checks and the standard gate set pass, each one's last line in the report.

**Report** as `docs/director/cloud-reports/2026-10-28-prop-reach.md` with these sections: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.

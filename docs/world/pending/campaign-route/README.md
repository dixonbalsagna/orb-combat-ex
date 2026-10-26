# Campaign first slice, step 1: World's route on the ring (parked; behind `campaign.enabled`, off)

World and Environment, 2026-10-25. `campaign-route.diff` (sha1 a6873039dc61, 10 files) is a git-apply diff. **Applies after `../wreck-toss/wreck-toss.diff`** (they share Tools' `map.json` and `cases.json`), on the EP's gate tree (main plus windows 9 to 12 and the host diff). Design, interface and the questions: `../../campaign-route.md`.

**Off by default** (`data/biomes/campaign.json` `enabled: false`): nothing in `WorldCampaign` runs, a setup's `wear` key is ignored, and the golden is unchanged. The one line in a path that runs when it is off is `WorldPlanetWorld.gen`'s `if setup.has("wear") and WorldCampaign.enabled()`.

- New: `sim/world/campaign.gd` (`WorldCampaign`: `column`, `beginColumn`, `side`, `wearOf`, `mergeWear`, `standingOf`, `damagedOf`, `applyWear`), `data/biomes/campaign.json`, `sim/world/tools/campaign_check.gd` (30 checks), `tools/schemas/biomes-campaign.schema.json` (Tools', granted), a map rule and three invalid cases.
- Edited (World's): `sim/world/epoch.gd` (`turned` takes the ring's own middle column as an optional last argument, default as before; `askCampaign` is the campaign's turn in a running sim: one candidate, none of the fight's caps, not counted in `n`; `choose` carries the flag), `sim/world/planet_world.gd` (the `wear` hook).
- No Simulation line, no hash line, no event.
- Proof: as in `../wreck-toss/README.md` (the same chain covers both): all 42 World checks, lint, validate and self-test, run-all 5 of 5 with the golden unchanged, the gen 2 soak, the render gates.

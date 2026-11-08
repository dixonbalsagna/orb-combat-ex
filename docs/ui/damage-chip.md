# The damage chip and the card's facts: no counter of people anywhere (UI & UX, 2026-11-07; Legal RL-257 and lint row c11; the EP's brief)

**The rule.** Orb's ruling of 2026-11-07 (no civilian deaths) retired every death, kill or people-lost counter a player or the public sees, and the words "civilians lost", "casualties", "toll", "kill count", "death count" and "body count". This page is what the HUD did about it. It replaces docs/ui/civilian-bar.md, which is kept as history.

**What went.**
- The chip's CIVILIANS LOST line and the thin bar for "the share of the city's people lost" (`UiCenter.civilian_share`, `bar_plan`, the bar's drawing) and the number beside it.
- The match-over card's and the pause screen's "Civilians lost: n of total" line (`prompt.over_civilians`), and the terms `toll.civilians` and the whole `toll` group's name.
- The hub's `civilians` and `pop0` counters. `UiSimBridge.patch` no longer reads `S.world.casualties` or `pop0` at all (the sim's own scalar is Game Design's, World's and Simulation's to remove: Legal RL-257 (2)); a `world` event that still carries `civilians` or `pop0` has them ignored.
- The word "toll" in code: `hub.toll` is `hub.damage`, `layout.toll` is `layout.damage_chip`, `toll_age`, `_l_toll`, `TOLL_*`, `set_toll` and `draw_toll` follow, and the demo flag `--toll` is `--damage=structures:craters`.
- The howto icon id `toll` is `damage`; the strings inventory's surface is "Banners and the damage chip".

**What stays.** The structures and craters the fight has done to the world: the chip is one steady line, "STRUCTURES LOST n    CRATERS n" (`prompt` words unchanged: `damage.structures`, `damage.craters`); the match-over card and the pause screen say "Buildings lost: n" and "Craters: n". Neither is a count of people: Legal RL-257 (4) lets World's own measure of spread stay. Under `minimal_hud` (shipped) the chip is not drawn in play and the two counts are on the pause screen and the card, as before.

**The flag.** `civilian_bar` is `damage_facts` in ui/data/features.json (on): the chip is steady (no dimming at rest, no brightening on a change) and the card has the counts; off, the chip dims and brightens as the old chip did and the card has no counts. The geometry of the chip's slot is unchanged, so the banner, the pause button and the read slot sit where they did.

**The schema (a grant).** `tools/schemas/ui-terms.schema.json` requires the terms group `toll`; it must say `damage` in the same commit (docs/ui/pending/damage-chip/schema-grant.patch).

**Tests (hud_check).** `_damage_facts_rules` (the chip's line and its steadiness, the people counters a feed still sends not kept, the card's two facts and their fit at nine sizes, the open card's words) and `_retired_words_rules` (every file in ui/data has none of the retired words, and the chip's line has none), each failing with a retired word put back (tried). The old four-digit fit test and the bridge, minimal-HUD and layout tests were moved to the new names.

**Not UI's, still open:** the sim's civilian-death scalar and every meter fed from it (Game Design, World, Simulation: Legal RL-257 (2)); the lint file movegen-banned.json's c11 (Legal). The old parks in docs/ui/pending/ (civilian-bar, minimal-hud and others) quote the retired words as history; they are record, not code, and can be deleted when the EP clears landed parks.

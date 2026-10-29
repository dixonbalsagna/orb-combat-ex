# Cloud briefs

> **Retired (Orb, 2026-10-28).** Cloud sessions are no longer used; starting them by hand cost Orb time. Every brief that had not run moved to its local director session on 2026-10-28 (Status column: "local"). A local director reads the brief as its own, works in the shared tree, parks and reports by message, and ignores the cloud-only parts (branches, pushes, the Godot install). The reports the cloud sessions wrote stay in each director's `cloud-reports/` folder.

Each file here is a self-contained brief for one fresh cloud session. Orb starts a cloud session on this repository (environment **Meridian**) with the one line:

> Read docs/ep/cloud-briefs/<file>.md and follow it.

| Wave | Brief | Director | Branch | Status |
| :--- | :--- | :--- | :--- | :--- |
| 1 | world-w4.md | World & Environment | cloud/world-environment/biomes-w4 | landed bb5cdb43 |
| 1 | netcode-rollback.md | Netcode & Online | cloud/netcode-online/rollback-core | landed 04478dc2 |
| 1 | tools-web-template.md | Tools & Pipeline | cloud/tools-pipeline/web-template | landed 2acfc4cd |
| 2 | encounter-w2.md | Encounter Systems | cloud/encounter-systems/biomes-w2 | landed (this commit) |
| 2 | qa-gen2-baseline.md | QA & Balance | cloud/qa-balance/gen2-baseline | landed 688f2514 |
| 2 | accessibility-foundation.md | Accessibility & Localization | cloud/accessibility-localization/foundation | routine (plan), 28 Oct; do not start by hand |
| 3 | simulation-snapshot-tick.md | Simulation & Engine | cloud/simulation-engine/snapshot-tick | routine (plan) |
| 3 | tools-ci-linux.md | Tools & Pipeline | cloud/tools-pipeline/ci-linux | routine (plan) |
| 3 | combat-moveset-generator.md | Combat & Choreography | cloud/combat-choreography/movegen | routine (plan) |

Wave 3 runs as routines, which bill the Max plan rather than the credit, so it can run while Orb is away.
| 4 | vfx-variant-debris.md | VFX | cloud/vfx/variant-debris | routine (plan) |
| 4 | netcode-desync-spectate.md | Netcode & Online | cloud/netcode-online/desync-spectate | routine (plan) |
| 4 | animation-pose-drain.md | Animation | cloud/animation/pose-drain | routine (plan) |
| 5 | world-w5-props.md | World & Environment | cloud/world-environment/biomes-w5 | landed 70c1ab3e |
| 5 | simulation-packed-structures.md | Simulation & Engine | cloud/simulation-engine/packed-structures | landed 5a2c58c2 |
| 5 | netcode-transport.md | Netcode & Online | cloud/netcode-online/transport | landed 2afeda13 |
| 5 | animation-pair-ready.md | Animation | cloud/animation/pair-ready | landed b7fd2250 |
| 5 | ui-settings-access.md | UI/UX | cloud/ui-ux/settings-access | landed 9979146a (foot re-cut locally) |
| 6 | encounter-w3.md | Encounter Systems | cloud/encounter-systems/biomes-w3 | landed d0d91c29 |
| 7 | world-w6-flight-hooks.md | World & Environment | cloud/world-environment/biomes-w6 | landed ede6490b |
| 7 | encounter-tick-skip.md | Encounter Systems | cloud/encounter-systems/tick-skip | landed fa078e1c |
| 7 | netcode-ai-depth.md | Netcode & Online | cloud/netcode-online/ai-depth | landed 8cddcd0f |
| 8 | world-w7-ring-buildings.md | World & Environment | cloud/world-environment/biomes-w7 | local, wave B sent 2026-10-29 |
| 9 | tools-desktop-builds.md | Tools & Pipeline | cloud/tools-pipeline/desktop-builds | landed e8a0ed75 |
| 9 | ui-difficulty-textsize.md | UI/UX | cloud/ui-ux/difficulty-textsize | landed b6df7059 |
| 9 | controls-hold-toggles.md | Controls & Game Feel | cloud/controls-feel/hold-toggles | landed 5d26c626 |
| 9 | narrative-live-barks.md | Narrative & Fighter Identity | cloud/narrative-identity/live-barks | landed e4be0c65 (switch off) |
| 9 | rendering-pane-sweep.md | Rendering & Technical Art | cloud/rendering-techart/pane-sweep | local, wave B sent 2026-10-29; look gate local |
| 9 | encounter-prop-reach.md | Encounter Systems | cloud/encounter-systems/prop-reach | landed f250cf02 |
| 10 | netcode-ai-takeover.md | Netcode & Online | cloud/netcode-online/ai-takeover | local, wave B sent 2026-10-29 |
| 10 | simulation-forwards-warmup.md | Simulation & Engine | cloud/simulation-engine/forwards-warmup | landed 39f6bc3f |
| 10 | rendering-broken-props.md | Rendering & Technical Art | cloud/rendering-techart/broken-props | local, after pane-sweep; look gate local |

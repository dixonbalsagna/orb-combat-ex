# impact-haptics: the five rumble picks that were missing (Controls, 2026-11-06; job 3 of the controller-vision brief, row 7)

Landed blows (felt by the attacker and by the one hit), closes, launches felt by the one launched, landings, and buildings breaking: Orb's 2026-10-05 picks. Full table and reasoning: `docs/controls/impact-haptics.md`.

## Files
`impact-haptics.patch`: `sim/input/haptics.gd` (+87: six kinds, `event_requests`), `input_data.gd` (`haptic_impact_on()`), `render/core/main.gd` (+2, the host's call: **a grant**, Rendering's file), `data/input/timing.json` (`switches.hapticImpact` false), `tools/schemas/input-timing.schema.json`, `sim/input/test/impact_haptics_test.gd` (58 checks) with its `.uid`, `haptics_test.gd` (twenty-two kinds).

Apply **after** `../landing/controls-landing.patch` and `../stall-keep/stall-keep.patch` (cut on that tree). `git apply docs/controls/pending/impact-haptics/impact-haptics.patch`. To turn it on: `"hapticImpact": true` in timing.json; `hapticIncomingBeam` (the beam warning, already built) is the other flip the brief asks for and goes in the switches-on set.

## Checked (landing + stall-keep tree, headless, below normal priority)
- impact_haptics_test 58 of 58: the mapping over fabricated events (heavy from slot 0 to 1 is `blow_land` for 0 and `hit_taken` for 1; light, medium, heavy climb; a guarded blow is dull; a hit by the world is felt by the one hit; beams, impacts and other kinds rumble nothing; slots 2 and 3 rumble nothing; the rush, launch, land and building_fall events), the shapes (low motor first, nothing bright, over inside 160 ms, own gap), `plan` plays a thud on a pad, and **two real AI matches' events through the same mapping** (counts in the doc), so a wrong field name would show.
- haptics_test 80 of 80 (the signature rules: distinct shapes, 160 ms, motor duty at most half, distinct phone patterns); all 31 input tests; `main.gd` parses (`--check-only`); lint and validate clean. No sim file changed: the golden is unaffected.
- **Not shown:** a building falling (none fell in the two matches), and a pad actually shaking: this is the mapping and the plan, as the earlier rumble rounds were.

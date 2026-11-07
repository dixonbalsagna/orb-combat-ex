# Seeing all four in a 2v2: the plan (Legal RL-249's drawn case)

Rendering, 2026-11-07, from the EP's brief on Orb's first 2v2 together: "never saw all four fighters on screen together even though we were within reasonable proximity". Orb wants to see the partner's fight when it's near. Everything below is behind switches that are off by default, as parks, and private to Orb until Legal's clips pass (RL-249).

## Why Orb saw two

- **The LAN kit never turned it on.** `orb-lan-a8bc66e2-c`'s launchers pass `--lan-2v2-together --tiles=1` and no `--others`, so neither PC drew the other fight.
- **On main, `--others` (`SimHost.draw_others`) already draws** the other fight's bodies and shadows when they're on a pane's screen, and its beams, calm and outside any flash register. Its sparks, dust and shots need VFX's local word too (`?otherfights=1`). Since this afternoon each hub gets its own fight's events on either PC (stage-feed, a8bc66e2).
- **The camera frames only your own pair,** so the other pair shows up only when it happens to be in frame.
- **The world is shared** (SimStage: the planet, its stored damage, the buildings and the water). The other fight's craters, collapses and scars are drawn in your view today, drawn case or not.

## Who does what

| Owner | Part | Legal's condition |
|---|---|---|
| **Rendering** | A: `--others` draws bodies and shadows only. The other fight's beams move behind the effects word, so `--others` alone draws none of its light. Its hub gets its events only while a pane draws that fight (within view distance), so nothing from round the planet runs or pops in mid-effect. B: once VFX's register exists, add an on-screen test (any pane) for it. Then the other fight's beams, and the light from changes it makes to the shared world (a crater's glow and colours, a collapse), ask the register and take the form it grants. | (2), (3), (4), (5) |
| **VFX** | One register per screen. It sums every light event drawn on any pane, from either fight and from the shared world, against the RL-249 limits, including one rise and one fall per 2 s for catastrophe-class events across both fights. When it's over, the other fight gives way (calm, thinner or later), never your own fight. The per-hub registers become feeders. Counting starts on the tick an effect comes on screen (Rendering's test). | (1) to (5) |
| **Camera** | When the other pair is within reach, ease the frame to hold all four. Your own pair stays first and readable. No cuts, no markers, Orb's smooth camera rule. It reads `SimHost.other_x`, `other_z` and `other_pose` (already on main). | (9) no marker |
| **UI** | The desktop switch for the other fight's effects: off by default, shown only in the private 2v2 LAN setup, with Reduce flashing locked on and the warning shown. `?otherfights=1` stays a local-page word. | (6) |
| **Netcode / Tools** | The private LAN kit's 2v2-together launchers pass `--others`, and the effects word only once the switch and register pass. Tools: the two-fights-drawn flash clips (both modes, day and night, the two worst cases) through the analyser and the guarded launcher. | (6), (7) |
| **QA** | The civilian band per fight and together, a place both fights reached counted once, reported as a trend. | (8) |
| **Art / Animation** | When the same fighter appears twice: A4's second palette (body colour only), with stills to Legal for an originality look. | (9) |
| **EP / Legal** | Whether the second person at Orb's LAN is covered (RL-249 (10); RL-253 covers Orb 2 for private builds). The new team moves are separate rows. | (10) |

## Order

1. **Rendering A** (now, small, 1v1 identical). With `--others` alone the four bodies show whenever they're on screen, with no other-fight light at all. It's the safest first look for Orb, once the EP says the kit can carry `--others`.
2. **Camera's framing** in parallel. Without it, "near" only shows by luck.
3. **VFX's register**, then **Rendering B** on its API, behind the effects switch.
4. **UI's switch and Netcode's launchers**, then **Tools' clips and QA's band**.
5. **Orb sees the drawn effects** in the side-by-side, privately (ADR 0010, RL-249 (6) and (7)). Nobody else sees them until the clips pass.

## What Rendering needs from VFX

A call per light event, per frame it's on screen: `ask(kind, own_fight: bool, catastrophe: bool, first_tick: bool) -> form` (full, calm, thin or later), on the same register that Rendering's own flashes already ask (`SimHost._ask_beams`, `_ask_hits`). Plus a way to count shared-world light (a new crater's glow, a collapse) whichever fight caused it. The exact shape is VFX's to choose. Rendering adapts its beams and the planet view to it.

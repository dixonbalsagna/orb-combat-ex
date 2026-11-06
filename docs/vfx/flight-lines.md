# Flight lines (VFX, 2026-11-01)

Orb: "each fighter's unique way of exploiting the in-universe energy source could account for flight lines when flying at max speed", and "The glow should be enough to look cool when the camera dynamically zooms". Game Design's rules are `docs/design/rule-of-cool-map.md` section 1; Legal's are RL-221 (colours) and RL-222 (the trail's head).

**A flight line is the meteor trail's ribbon (`docs/vfx/meteor-trail.md`), laid by a fighter who is flying near flat out, with a strength of its own.** One ribbon, so a fighter's beam, clash, burn and flight line stay one identity. It is view only: it reads the fighter and writes nothing of the sim, draws no random number, and a replay lays the same points.

**Off by default.** `VfxHub.flight_enabled` (`VfxLook.FLIGHT_DEFAULT` false). A local preview page turns it on with `?flight=1`, `=quiet` or `=loud` (the meteor trail's two sets: `loud` keeps a wide ribbon at full strength, `quiet` dims it by area); a public page's word is never read. With it off nothing runs and nothing draws, and the meteor trail's own rows are as they were.

## What it reads

| Reads | How | Value (data/vfx/meteor.json `flight`) |
|---|---|---|
| Strength | Its own term, **not** the meteor's `cool` product (which leaves a tier-4 flier at 0.15). Tier plus form steps; none at tier 1 or 2 (tier 2 keeps today's speed streak only) | Tier 3: 0.5. Tier 4: 0.8. Each form step adds 0.1, up to 1 |
| Speed | None under 80% of flat out, full at flat out. **Flat out is the sim's own:** `SimFighter.flightSpeed` for a held dash at the full traversal boost (10,320 u/s at tier 1, 13,416 at tier 4; the sea slows it), a pure read of the state. The boost is the sim's alone: it is full only 12,000 or more from the rival, so a melee dash never draws a line | `from_k` 0.8 (`flat_out` 6,100 in the data is only the fallback where there is no state to read) |
| The stick | Held steady: the stick at 0.6 or more for 0.3 s, then eased in. A launched body has no stick and follows the burn | `hold_min` 0.6, `hold_s` 0.3 (reads `heldMx`, `heldMy`) |
| The camera | A flight line is laid along the path the camera follows, so it is not a band sweeping the pane: the camera's speed dims it to 0.6 at most where the meteor's loud set dims to 0.1 | `pan_k` 0.6 |
| Altitude | Thick air, a short line; thin air, a long thin one. Above the air the pixel floors still hold, so it never disappears | Length x0.7 on the ground to x1.5 from 8,000 up; 80% as wide in thin air |
| Fighter | A data row, `fl_*` keys that apply only while the lines are on | below |

The ribbon is sampled finer within a few body heights of the fighter, so the head's width cap bends the outline smoothly and not as one kink at a knot.

It is drawn behind every fighter (the ribbon sits 12 units behind the fighter's plane) and never in front of one. It is the same ribbon the trail view draws, so it ends by tapering from the tail and cooling in colour: no pulse, no fade of the whole.

## The four rows

| Fighter | Built | Not built |
|---|---|---|
| **Grist** (Protagonist) | Wall front with the beam's boil rings travelling down it; widest (x1.15); **widens and lingers as it cools** (x1.3, then x0.9 smouldering); **a braid with each form step** (0.34, 0.67, 1: two strands crossing along the ribbon, hue and a little shape, at most half a hertz) | |
| **Loupe** (Anti-hero) | Lances and facets; a hard thin needle (x0.8); **drawn from knots five times as far apart, with a knot at every corner**, so it stays within a body height of his true path (the check measures 10 of 75 units on a quarter turn and a long arc, at 26 knots where Grist's takes 48); **narrows (x0.3), colder, lasts x1.3** | |
| **Empress Orza** | Wire front: a long taut arc, shedding nothing; **a thin gold rim line (`#c9a227`) on the body layer only**; draws tight as it cools (x0.55); **settles toward the straight line between its ends over 1.5 s once she has stopped** | Her smoothest turn is the same path as everyone's: the line follows where she flew, and her kit is parked |
| **Bolus** (Cyborg) | Sputter front: **gaps fixed to the path's arc length, never in time** (about two fifths of the line at the start, none at molt 4, because the noise threshold scales with the open share); **each molt closes them (1, 0.75, 0.5, 0.25) and thickens the line (x1.2, 1.3, 1.4, 1.5)**; a dull core and a hot slag-orange rim (`#fa9a2e`); sparks as soft flecks fixed to the path, longer along it than across | **Sparks thrown out of a corner** (the flecks sit in the ribbon; a thrown spark needs geometry the ribbon does not have). His Hunger steps are read as the form step, which is what `docs/design/economy.md` says triggers a molt |

## Colour rules (Legal RL-221, Art)

- Gold is the **Empress's ribbon rim only**. Her aura, ring and flash stay moss (`#b8c96a`, `#6d7d30`, with `#dfe8a8` only as a small hot point). A check holds that no other row has a gold rim and that no rim is white or red.
- No white: the core's lightness cap (L* 86) and the shader's `glow_cap` hold for the flight line as they do for the beams; nothing here lifts them.
- A trail streaming upward needs Legal's look against stacking mark 3 (the wake of a climb); the shape is what carries each fighter, so a colour change would not hurt it.

## Cost

One mesh a fighter, as the meteor trail. The shader gains two uniforms; per fragment the braid is two sines and two smoothsteps, the sparks one hash, the rim a few operations. **The lowest level drops the braid and the sparks first** (and keeps the shape). Arithmetic only; Performance benches it with the meteor trail.

## Checks (`effects_check`, `_flight_lines`, 22 checks)

Strength by tier and form step; the speed ramp and the altitude length; each row's composition, and that no `fl_` key leaks into a row with the lines off; the gold rule; the model (full strength at flat out with the stick held, none at half speed, at tier 2 or with the stick let go, half strength at tier 3); the length and width by altitude; knots against the true path round a corner and an arc; the Empress's settle; the switch (off by default, and on it lays the line without the burn); and the view (her rim and his slag rim reach the shader).

**Flash: not run.** The flash clips are paused for private work (Legal RL-226) and are required before anything public. The ribbon is steady: every travelling feature is at most 0.9 Hz and a line only brightens as the fighter reaches speed (eased over 0.3 s).

## Not built, and to decide

- **Ground contact** below about 600 units (a water V, dust, bending treetops) pairs with water's A1 (rule-of-cool-map section 5) and needs World and Rendering; the wake does not touch the ground yet.
- **Flat out is read from `SimFighter.flightSpeed`** (a static function Simulation owns; the view calls it as a read). If Simulation changes the formula, the line follows; if it moves the function, `VfxMeteor.flat_out_of` is the one place to change.
- **The speed streak and the line never show together** (Game Design's ruling): the tier-2 speed streak (`shots_view.gd`'s `_flight_streaks`, the thin world-anchored lines along a launched body's flight) stays at tier 2 and stops for a fighter whose line has taken over at tier 3 or more, while the lines are on. The launch and heavy streak of feature 11 (`speed.gd`) is a different thing and stays.

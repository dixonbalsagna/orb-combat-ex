# The city's cars: four silhouettes and a wreck (2026-10-18)

Owner: Art Director. For Orb's cars: scenery, and something a fighter can throw. City art, so it may be public; concept art, working labels, **pending Legal review**; Tools adds the schema. **Sheet:** `art/concepts/city/cars.svg`. **Data:** `data/art/vehicles.json`. Regenerate: `node art/concepts/city/cars.mjs`.

## The four
Side-on, facing right, faceted (prisms and chamfers, the wheels octagons), at the game's scale (a fighter is 75 units, about 1.75 m): the **sedan** 193 by 62 units (wheel radius 14), the **van** 223 by 86 (17), the **bus** 516 by 137 (22), the **bike** 90 by 56 (15). About 10 rigid parts a car (the bus 14, the bike 8), and about 120, 150, 260 and 90 triangles (estimates).

## Paints
Six, the walls of the city's tints (`city-facades.md`): low chroma, so a street of cars reads as part of the city and never as a fighter. The glass is the tint's dark glass; the lights are the city's one lit colour, small and steady, and go dark in the wreck. Nothing is orange or yellow (a taxi would be fire's colour), mid blue (the sea's) or a saturated red (blood's). The fighters' rings are 20 or more from every paint; the training dummy's pale lavender-grey ring is 13 to 23 from them (a light grey car is the nearest thing to it), so he is told apart by his keyline.

## The wreck
The same silhouette made lower and askew: the roof crushed by about a quarter, the body tilted 6 to 9 degrees about the front axle, one wheel off or sprung (the bike's front wheel off), the glass out and soot-dark, the lights dark, a soot band along the roof and the sill. No flame or smoke in the art (VFX's if wanted), and no people in or around a car. A thrown car that lands becomes the wreck.

## Thrown
Seen thrown a car tumbles as a flat box, so **the long side is the read**: at fight size (86 px a fighter) a sedan is 166 px long, a van 192, a bus 444, a bike 77; at 46 px, 89, 103, 237 and 41. Nothing sticks out further than a quarter of the length (the bike's handlebar is the most). Art's suggestions for Combat and Game Design, in `vehicles.json`, not rules: mass classes (bike 1, sedan 3, van 4, bus 8), the first power tier that can throw each (tier 1 the bike, 2 the sedan, 3 the van, 4 the bus), and the hit box the car's own size.

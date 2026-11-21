# Relief cap on tiny and small planets: Art's ruling (2026-11-20)

Asked by the EP for World's GW1c proposal (`docs/world/pending/relief-cap-gw1c/README.md`; review RC-02 in `docs/ep/reviews/relief-cap-and-lake-dig-review.md`). This is the ruling in Art's own docs.

## The cap

**0.3 of the radius on both tiny and small** (the share Game Design already chose for buildings). Keep the knee at 0.6, or raise it to 0.7.

Why: the smooth squeeze piles every cut peak up against the cap, so a tighter cap turns more mountain tops flat like tables. At 0.25, 7.2 percent of tiny sits on the squeeze; at 0.3, 4.4 percent. At 0.3 tiny's ridges stop at about 1,956 units (about 26 bh, a third of the planet's width) and small's at about 3,911. Medium and up stay as they are. Take the stills of both sizes before landing, and look for flat-topped mountains.

## The altitude lines (snow, pale rock, tree line, highland)

**The lines sit at one fixed share of the capped height on every size.** What the player sees is the capped ground, so the tallest mountain on every size must reach the same snow line, and the same fraction of any slope must be pale rock.

How to set it: take each line's height on medium, where nothing is capped, as a share of the tallest relief (6,739 units). On a capped size the line is that share of the size's capped maximum. In practice every altitude threshold is scaled by (cap in units) divided by 6,739 on tiny and small, and left as it is on medium and up.

## What not to do

World's first build reads biomes from the uncapped height. That keeps mountain and highland land where it was, but on ground the squeeze has flattened, so it shows mountain biome (rock, snow, strata) on near-flat hills, and the lines land at different shares of the cap on each size (about 0.67 on tiny and 0.63 on small). That is not what this ruling means: one share of the capped height, the same on every size. If the biome map must stay on the uncapped height for a different reason, the land type may stay, but the altitude lines (snow, pale rock, tree line) must still be placed by the capped height.

# Rally prototype tools

Research & Prototyping, 2026-10-25.

The prototype is `docs/ep/prototypes/rally-v1.html`. It builds Game Design's rulings 23d (`docs/design/rulings-2026-10-23d.md`): the daze, the sell, the rally of linked flight attacks, and the turn. It sits on these rules and numbers:

- fight-feel's launch flight, glances and counter-rush (`docs/design/fight-feel.md` sections 1 to 3 and 6);
- the brawl's blow numbers (`data/director/interrupts.json`, `brawl`).

Its clips are Orb's homework: `homework/combat-and-controls/SOON - rally (stun, sell, bounce)/`.

| File | What |
| :--- | :--- |
| `work/sim.js` | The sim, the director's stand-in, the camera and the drawing, with no DOM, between the "RALLY SIM" and "PAGE" markers |
| `work/page.html` | The page: clip buttons, keyboard and gamepad, the step list and sound. Its `/*SIM*/` slot takes `sim.js` |
| `build.mjs` | Writes the single-file prototype from the two |
| `gif.mjs` | Runs the sim in node with a scanline rasteriser, the bitmap font and a GIF encoder (copied from `research/right-stick-proto/gif.mjs`), then makes the clips, the stills and a sheet per clip. It merges its clip list into the homework README between markers, so it never replaces the README. `--check` prints each clip's feed, and `--frames` saves chosen ticks |

## About the sim

**The world.** A planet strip 7,200 px around that wraps, running through plains, a city of box buildings, a stone quay, the sea, a beach and a cliff.

**The brawl.** The blows, guard and stagger come from `data/director/interrupts.json`:

- **Light (X):** contact in 2 ticks.
- **Medium (Y):** a 12-tick wind-up.
- **Heavy (B):** a 28-tick wind-up. Held, it charges, and it is full at 44 ticks.
- **The launcher:** a 14-tick wind-up.

A landed blow frees the line at once (`recover` 0). A press made during a hit-stop waits for it to end.

**The daze (23d items 1 to 3).** It is earned: a fully charged heavy breaks a guard, or lands clean. It lasts 40 live ticks. Each of his presses takes 3 ticks off, one counted every 6. The burst (RT) breaks it after its first 12 ticks. He is wary for 2 s after a rally ends on him. A flurry's close only staggers.

**The sell (item 4).** In the daze, each landed medium or heavy:

- takes the launch's hit-stop (12);
- gets a camera push;
- gets a reaction a size larger.

**The send (item 5).** B at a dazed fighter is the sure launcher, with the decisive hit-stop (20). It opens the rally.

**The flight (fight-feel section 1).** The kick ramps over 5 ticks, holds the peak for 3, then glides down to 0.4 of the peak by tick 30. At the arrival:

- Glances happen under 40 degrees, above the line.
- The sea skips him at the same angle.
- At most two ricochets in a row.
- Anything steeper is a wall slam or a landing.

**The links (item 6).**

| Link | Input |
| :--- | :--- |
| The chase strike | LT with X or Y. The stick turns the send by up to 30 degrees |
| The overtake | The chase with the stick held back against his flight |
| The spike | B from above him. Hard ground glances him back up |
| The bank | A dodge tap as the chase meets, or passes within 1.5 bh of, a building's face. Free |
| The lob where he will land | RB with Y |

**The tech (item 8).** He gets 4 ticks for a fresh kind and 8 for the same kind as the last. A third of one kind is teched by itself.

**The turn (item 10).** A teched link gives him the counter-rush within 20 ticks. If it lands on the chaser in the air, it is a full send, and the rally is his.

**The camera.** It eases onto both fighters and fits their whole bodies below the HUD's strip. It zooms out faster than in, rides a flight closer, and never cuts.

**Simplified:**

- Flight distances are drawn at half the game's.
- There is no damage.
- The defender's wall kick, recoil flip and the meet rules are not modelled.
- The brake is a plain slowdown.

```
node research/rally-proto/build.mjs
node research/rally-proto/gif.mjs --check
node research/rally-proto/gif.mjs                       # the five clips into the homework folder (about 6 s)
node research/rally-proto/gif.mjs --frames D4 30,60,90 out.png
```

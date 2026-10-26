# The Demon Cyborg in a rally: appetite

Combat and Choreography, 2026-10-25. Game Design's frame is `rulings-2026-10-23d.md`. The data is `rally.cyborg.json`; the names are working labels. **Wreckage and metal only** (Legal ln04).

**Who he is in a rally.** He works the fight like a scrapyard. He hooks the body back when it tries to get away, bats it on with whatever wreck is nearest, and keeps it bouncing on his own slag.

## His links (each its own kind for item 8; the base link's price and tech)

**Crane Reel** (the grab in flight)
- **Input:** RB with A at the flying body.
- **Tell:** the hook swings once behind him on its cable.
- **What happens:** the crane hook latches round the body's arms or torso mid-flight, and the foe struggles on the line. His payoff, the throw, reels the body back toward him on the cable and turns it once, short and at body height, never overhead (RL-183), then flings it 6 bh along the stick: the flight reversed.
- **Price:** the grab's (10, or 14 held).
- **Legal:** one call-out (ln06), and no taunt over the reel.

**Wreck Toss** (a world link)
- **Input:** two presses, each one action (23d item 20): the pick-up (A), then the throw (Y) at the flying body. He must be free (not inside a zip), the body out of striking reach (a rally gives that), and the wreck within 2 bh, inside his tier's lift, empty, with nothing living near it.
- **Tell:** the lift: a forearm plate slid under the frame.
- **What happens:** he hurls the wreck at the flying body. It strikes and sends the body on along the throw's line, as a thrown object does, and the wreck bursts into scrap, which damages structures by the tier factor. The lift's tell takes its time while the body flies on, so the throw must arrive while the body is still in flight or within 20 ticks of its landing (23d item 11); otherwise the rally has already ended.
- **Price:** none. Throwables carry no ki and no cooldown.
- **Legal:** wrecks are always empty, and a wreck with anyone living near it is not a candidate (RL-183).
- **Legal RL-186:** the pick-up is refused with any civilian within 3 bh of the wreck, indoors or out, and the link is never chosen for a landing near people (the scoring's `exclusions`).
- **The lift by tier** (Game Design 2026-10-26 item 3): the heaviest wreck each tier lifts is **2, 6, 16 and 57** on World's wreck masses. What the hit does to a body stays the throwables' rule (damage by size). The burst's damage to structures is World's brunt ladder with the tier factor.
- **Checked against the throwables table** (tier 1 lifts mass 4, a van; tier 2 mass 8, a bus; tier 3 ships):
  - **The units differ.** The cars' masses are Art's classes (bike 1, sedan 3, van 4, bus 8). A wreck's mass is its graspable piece in cubic body heights (World's `wreck-toss.md`).
  - **Read as one scale, they fight at tiers 1 and 2:** a tier-1 fighter would lift a mass-4 van but not a mass-3 wreck.
  - **In heft they agree.** The cars' boxes come to 0.24, 2.04, 3.45 and 15.08 cubic bh (bike, sedan, van, bus). So a solid piece of 2 at tier 1 sits near a hollow van, 6 at tier 2 near a hollow bus, and 16 and 57 sit in the ship range.
  - **Recommended:** World names its field `wreckMass` (cubic bh), so nobody reads it as the car classes.
  - **Separately,** World's `props.json` gives each car a `throwTier` (bike 1, sedan 2, van 3, bus 4). That disagrees with the throwables ruling, under which tier 1 lifts the bike, the sedan and the van, and tier 2 the bus.

**Slag Catch** (a lob link)
- **Input:** RB with Y held to level 2, its landing led to where the body will come down.
- **Tell:** he hammers his chest plate and the grille steps brighter.
- **What happens:** the slag lands and rolls to the landing. The body comes down in it and the burst pops it 3 bh back up, so the rally goes on even on soft ground, where a spike would end it.
- **Price:** the level-2 lob's 12 ki.
- **Legal:** one flash event; the slag rolls and never seeks people.

## His sell, a size larger (item 4, as re-read: two sold mediums, then the send; lights aren't sold)
- **The first medium:** the sensor housing jerks aside and its lights stutter, under a 10% step and 2 Hz (fx09). Plates dent with a clang and spring back, and the seams hiss as the flesh beneath knits.
- **The second medium,** a step bigger: his head snaps back with sparks from the neck seams (one burst). He folds at the waist joint with the chest grille rattling and is driven a step back. He recovers with a whirr as the limiter resets, the flesh steaming and closing.
- **The send** (B, the heaviest blow of the sell, decisive hit-stop 20): launched in a shower of loose rivets and wire, limbs swinging on their joints.
- **Voice:** a mechanical grind and a growl. The hunger lines stay in his voice, never in a mouth (ln02).
- **Scale:** snap ×1.1, fold ×1.1, step 1.0 bh.

**Settled** (23d item 20): allowed, as a world link in two presses.

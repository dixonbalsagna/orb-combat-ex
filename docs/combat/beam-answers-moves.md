# Beam answers, as moves

Combat, 2026-11-01, for Game Design's `docs/design/beam-answers.md` and Orb's order in `docs/ep/vision.md`. **Paper only: nothing here has been run, drawn or played.** "Spectacular" is my judgment from the numbers and the kits. Worth and windows are Game Design's. Fighters: Grist is the Protagonist, Loupe the rival, then the Empress and the Cyborg.

## The verdicts

| Answer | Verdict | Why |
| :--- | :--- | :--- |
| Fire back | **Spectacular,** and built | Two fronts meet, and the struggle traits already differ by fighter |
| Dodge | **Good, but plain on its own** | The show is what the beam hits behind you |
| Powerful block | **Spectacular if the beam visibly parts** | Otherwise it's a guard with a sound |
| Swat | **The most spectacular, and the riskiest** | The picture is a bent beam, and the player chooses what it hits |
| Walk into it | **Best picture, wrong numbers** | Beams last 0.3 to 0.9 s. A slow wade can't arrive |
| Split | **Only reads on paper as its own move** | It's the block's picture with a harder press. Fold it in |
| Slip and close | **Good play, ordinary picture** | A dodge, then a lunge. It needs no new rule |
| Eat it | **Spectacular on one fighter** | The Cyborg. It's close to the drain we already refused |
| Blast the front | **Only reads on paper. Cut** | A small pop on a huge beam, and it shares fire-back's input |
| **New: raise the ground** | **Spectacular** | The planet answers, and it's different in every biome |
| **New: the hose** | **Spectacular** | Hook the rooted shooter's arm, and his beam goes wild |

**My first set:** fire back, dodge, the block, swat. Then the hose and raise the ground. Walk in for level 3 only, if it gets its time.

## Four things that decide all of them

1. **Beams are short.** 20, 36 and 54 ticks by level: 0.33, 0.6 and 0.9 s. Anything that happens *during* a beam has under a second, and a level 1 has a third of one. This is what breaks the walk, and it limits the hose.
2. **It's side-on, so a swat has few directions.** Left and right along the fight mean back up the beam or straight behind you. So a swat really has up, down, and over the shoulder. Depth might add more; `docs/world/ring-any-angle` would say.
3. **Almost all of these need one new picture: a beam that bends or parts at a body.** With it, the block, split, swat, walk and eat all read. Without it they all look like a guard. That's Rendering and VFX, and it's the one thing worth building first. The carve has to follow the bent path too (map row 31).
4. **What's behind you is the choice.** A dodge lets the beam through to the town. A block leaves a clean wedge behind you. A swat chooses where it goes. No new rule is needed for that, and no new term has to read people: the hero's existing anguish pays for what he let through. That's pillar 5 made into one quick decision.

**One ruling already exists:** `rule-of-cool.md` §2 gives a perfect block three looks by the left stick: away swats, neutral splits, toward walks through. It's one press on the left hand, so it fits the laws better than the packet's right-stick swat. **I'd keep that press and change one thing:** the player aims the swat, with the left stick, in place of "the game picks". Orb's "the stick puts him where you aimed" applies here too.

## The moves

The pieces are candidates by name from the recipes. **Grist and Loupe have them. The Empress and the Cyborg have no melee pools yet,** so everything they'd do with a body is new work, or the reference pool until then.

### Fire back
- **Bodies:** a snap from whatever he was doing into his release, with no charge pose, since level 1 fires at once. Today all four directions use `blast_chest` or `blast_gut`, so it looks the same for everyone until the casts differ.
- **By beam, all ruled:** Breakwater flattens like a palm on a door. Lance Sheaf tightens and presses. Hem Sweep wedges, and bows when losing. Furnace Vent sputters and surges.
- **Behind you:** a late answer meets near your hands, so your own ground gets scoured.

### Dodge
- **Bodies:** the existing dodge, off the line. In the air or to the depth side; a side-on sidestep along the line can't clear it.
- **By beam:**
  - **Breakwater,** ×1.2: the hardest to clear, so the dodge has to go up.
  - **Lance Sheaf:** he stands among the missed lances, smouldering in the ground. Cheap, and already ruled.
  - **Hem Sweep,** 38° a second: she can chase him with the sweep. The best contest of the four.
  - **Furnace Vent,** 26° a second: the slowest, so it's the easiest, and the shooter's open longest.
- **Behind you:** everything. The trench carries on past him.

### Powerful block
- **Bodies:** a fresh LB, both feet ploughing. He stops the front at his hands. Stay away from the crossed-arms pose and the other genre stances, and let Legal read it. Grist: flat palm. Loupe: the forearm plate. The Empress: the hem swept up. The Cyborg: shoulder in, grille shut.
- **By beam:**
  - **Breakwater:** a slab that piles up and fans out, the biggest.
  - **Lance Sheaf:** forks straight, already ruled.
  - **Hem Sweep:** barely parts. It's a wire on a blade, a small hot point, and it reads as precise.
  - **Furnace Vent:** splashes, and embers fall (render only).
- **Behind you: a clean unburnt wedge,** with scars either side. A hero in front of a town with the town untouched in his shadow is the best image in this list. It needs the carve to take a mask.

### Swat
- **Bodies, by aim:**
  - **Up:** Grist `palm_turn`, Loupe `heel_backhand`.
  - **Over the shoulder:** Grist `back_chop` or `turning_edge`, Loupe `swing_plate`.
  - **Down:** Grist `knife_chop`, Loupe `forearm_drop` or `arm_chop`.
- **By beam:**
  - **Breakwater:** a palm can't swat a wall. It should only take the middle, with the edges running past, or else it's level 1 only.
  - **Lance Sheaf:** the bundle scatters like dropped sticks, and they stand where they land. **The best fit, and the cheapest.**
  - **Hem Sweep:** flicked aside like a wire, and she can sweep it back. A good exchange.
  - **Furnace Vent:** a spray of slag instead of a line.
- **Behind you:** up is free, so it's the hero's choice. Down craters at his feet. Over the shoulder lands on whatever's there.
- **Legal first:** a player aiming a beam at a town needs reading. Keep `WorldSettle.noTarget` and "no term reads people", and it's the old ruling's "at buildings" that needs a fresh look.

### Walk into it
- **Bodies:** head down, leaning in, heavy steps, the guard shaking. It arrives with `shoulder_check` or a heavy: Grist `drive_palm`, Loupe `plate_ram`.
- **By beam:** Furnace Vent fits it best, stepping in its lulls. Breakwater is a door to shoulder through. Lance Sheaf breaks on the plate lance by lance. Hem Sweep makes it meaningless, since she just sweeps off him.
- **Behind you:** his shadow moves up the beam, and he leaves a furrow pointing at the shooter.
- **The problem:** 54 ticks at a walk is about a body height or two. The stand-off is 9 bh. Either it's a 3-step charge, which isn't a wade, or a beam being waded runs longer, which is new. **The old ruling skips the problem:** he arrives in front of the attacker. That's fine as a cut to the arrival, but it's not the picture Orb means.

### Split
Fold it into the block: a neutral block *is* the split. A second timed flick asks a lot in under a second for a picture that hardly differs. Two limits: Hem Sweep is the one beam that shouldn't visibly part, as "never thins" and "never parts" were ruled for its struggle, so Legal should re-read that. And "the town behind you pays" is backwards: the wedge protects it, and the two scars either side are what pay.

### Slip and close
A dodge, then a zip or lunge along the flank. It's the dodge's prize, and needs no rule of its own. **Hem Sweep and the sweep generally beat it,** which is the right tension. A hit on a rooted, side-on shooter is a good picture, but ordinary.

### Eat it
- **Bodies:** arms back, chest open, the beam ends at him, and he glows.
- **The Cyborg only:** the grille opens and the Furnace Vent's opposite happens. It suits him and no one else, and it's one of the roster's character moves.
- **Limits:** "a drain payoff" is on our refused list, and the Cyborg's siphon was dropped. The rival's On the Chin is already a body-takes-it stance. So it needs Legal and Game Design both.
- **Behind you:** untouched, like the block.

### Blast the front
Cut. RB + stick inside the window already fires back, so one input can't be both. And the picture's weak.

## My two new ideas

### Raise the ground
**Right stick down in the window, on or near the ground.** He drives a hand into the floor, and the ground heaves up as a wall in front of him. The beam bores through it, and the wall bursts. Level 1 stops there. Level 2 comes through late. Level 3 hardly slows, but you've bought time for a dodge.
- **Why it's good:** pillar 1, 4 and 7 in one press, and a beam answer that the landscape gives you. In the desert, a sheet of sand. On the sea, a wall of water and steam. In a street, the paving. In the air there's no floor, so it's simply a swat down.
- **Bodies:** Grist `plunge_blade`, Loupe `hammer_drop`. The Empress stamps her staves, and the Cyborg uses the crane hook to rip it up.
- **Behind you:** you've spent your own ground: a trench at your feet, and debris thrown both ways. Against that, what's behind you lives.
- **What it costs:** a raised strip in the heightfield, which the world may not do yet, and it's World's call. It can stay a look first: a burst of what's there and a shield of a set strength.
- **Avoid:** `fist_drop` and `plate_hammer`, Legal's pieces.

### The hose
**After a dodge, while he's still rooted: your kit's grab, RB + A.** It takes his firing arm, and for the rest of its length his beam goes where you drag it, at his own sweep rate. A face button fires no beam here, so it fits the law: it's still his beam.
- **Why it's good:** it turns the dodge's vague opening into a move only this game has, and it's a free-swinging line of destruction across the landscape. Each fighter's grab is already different, so four versions exist on paper.
  - **Grist's Harbour Net:** wide and slow, so it's the latest. The arm's hauled in, and he walks the shooter round.
  - **Loupe's Rank Ring:** snaps round the arm, and the beam jerks up straight.
  - **The Empress's Banner Snare:** staves stamp down, and the beam's dragged into the ground. The line of it digs.
  - **The Cyborg's Crane Hook:** the winch swings it like a hose, and the shooter's dragged too.
- **By beam:** Breakwater is the widest scythe. Hem Sweep cuts deepest and neatest. Lance Sheaf only makes lines. Furnace Vent sprays.
- **Limits:** the grab takes up to 30 ticks to arrive. So it's levels 2 and 3 only, and a level 2 is nearly over by the time it lands. Level 3 is the real one. Grabs bind arms and torso only, and the shooter must be free to cut the beam with LT, as he is now.
- **Behind you:** whatever you choose, and that's a real gamble for the hero. **Legal first,** the same way as the swat.

## What I'd ask of Game Design

- Whether the swat's aim is the player's.
- Whether a waded beam can run longer, or walking stays a cut to the arrival.
- Whether the first set should be fire back, dodge, block and swat, as I've put it.

**Not checked:** any of it in motion. The pieces are names from the recipes, and none has been posed against a beam.

# Energy movesets by fighter (parked)

Combat and Choreography, 2026-10-23. **Orb's brief:** "Energy attacks overhaul" in `docs/ep/vision.md`.

**Inputs.** Controls' constraints went to Game Design: X light, tap or hold to auto-fire; Y the medium lob; B the heavy, tap or charge, with release firing, Guard cancelling and mashing pulsing; A the grab; and a mine left by a blast thrown while guarding. **Names:** Narrative's provisional names (`docs/narrative/energy-names.md`) are the starting points, and better mechanics win.

**Owners of the rest.** Game Design is writing the frame (`docs/design/energy-overhaul.md`). Until it lands, this folder works to the provisional frame below and is adapted when the frame arrives. Nothing here is built.

## Files

| File | What it is |
| :--- | :--- |
| `README.md` | This page: Game Design's frame by cell, each fighter's templates, the shared data shape and the rules every fighter keeps |
| `protagonist.md`, `rival.md`, `empress.md`, `cyborg.md` | One page per fighter, step by step, for Research to prototype and for Orb to read |
| `energy.protagonist.json`, `energy.rival.json`, `energy.empress.json`, `energy.cyborg.json` | Each fighter's energy moveset as data (`combat.energy/1`) |
| `../../energy-movesets.md` | The overview: the four side by side, and how the director composes energy exchanges |

## 1. The frame is Game Design's (landed)

**`docs/design/energy-overhaul.md`, E1 to E117.** It replaces the provisional frame this page first carried, and it overrides any note above it.
- **The grammar is the same for every fighter** (E10): the buttons, gestures, ki, hit-stop and rules.
- **A fighter differs only in the cells Game Design leaves to Combat:**

| Cell | What is each fighter's own | Bands (E81 and the cell's rule) |
| :--- | :--- | :--- |
| **X, the bolt and the stream** (E20 to E26) | The bolt's shape, colour and spread | Speed within 20% of 60 a tick; damage within 15%; the stream's pace is the frame's |
| **Y, the lob** (E30 to E36) | Its shape, its arc and **its level-2 form** | Arc 36 ticks ± 6; level 1 at 28 ticks and level 2 at 48, each ± 10%; damage within 15% |
| **B tapped, the heavy blast** (E41) | Its look | The frame's numbers, damage within 15% |
| **B held, the beam** (E42 to E50, E90 to E97) | Its shape, width, sweep rate and end, and **its struggle trait** | Levels at 30, 54 and 84 ticks, each ± 10%; lengths and worth by E43; the struggle look changes how a surge and a buckle look, never the push (E96 as amended) |
| **A, the grab** (E60 to E69) | Its look (net, ring, lash, cage of bars, or its own), **one payoff** (yank, bind, slam or throw) and its held variant | Throw within 30 ticks; catch at most 40; the way out and the limits are the frame's |
| **LB + RB with B, the trap** (E75) | His own (templates: a line that fires his level-1 beam, a pillar from the ground, a field that drags down) | The frame's lay price, arming, flare, field limit |
| **LB + RB with A, the snare** | His grab laid as a trap, automatically | As the grab |
| **LB + RB with X and Y, the spark and blast mines** | Only their look | Everyone's |

- **The ki table is everyone's** (E100). Pulses are E50. Struggles are E90 to E97: a pulse on the beat counts double, and the losing beam bulges and quivers, never thins.
- **Hit-stop** is E102. **Collateral** is E113: near people the carer's beam narrows to 0.6 and his lob's burst to 0.7, and a villain's widen to 1.3. **Biomes** are E114 to E116.
- **Legal's rule for names** (E117): "blast cloud", never nuclear words.

## 2. Each fighter's templates, so the four stay distinct

| Fighter, identity | Side | Grab: look and payoff | Lob's level 2 | Beam: shape and struggle trait | Trap (B) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **The Protagonist,** control (cyan to azure, from the heel of the palm) | Hero; anguish | **A net** (wide and slow, a long catch), payoff **the yank** (into reach; the brawl starts with his blow). Held (E61): **charge**, a wider net and a longer catch | **Bounces:** it lands, hops once toward him and bursts again at half | Broad and driving, built on heat; **pushes as a wall** | **A pillar:** a solid slab of ground or lane-coloured stone a few bh tall, rising over several ticks (never a light beam, never around a body). It throws whoever trips it up and away, and so moves the fight off people. As the carer's, it holds while a person is in its burst (E79) |
| **The Rival (Anti-hero),** precision (violet to magenta; fists, plates, straight lines) | Villain; menace | **A ring** (a thin loop that flies facing forward at hand height and snaps shut round arms and torso; never a spinning disc or hoop, never above the head, never cuts), payoff **the bind** (held where he is; the Rival's next shot lands as on an open fighter). Held (E61): **aim**, the ring thrown ahead to lead him | **Splits into three** on landing, stepping toward him | A sheaf of thin **straight, parallel** lances, his barrage made one; in a struggle the sheaf presses straight and tightens, never rotating (Legal e11: no drill, spiral or helix) | **His own:** a pressure plate that, crossed, fires a fan of needles up from the ground: area denial |
| **The Empress,** dominion (ivory with a deep gold rim, Art's lane) | Villain; menace (assumed) | **A cage of bars:** four banner staves stamped into the ground round him, their banners wrapping his arms and torso. Payoff **the slam**: he is dragged down into the ground under him and lands kneeling. That is the slam's landing, never a held humiliation (Legal e12). Held (E61): **place**, the staves laid where the stick points, up to 6 bh, a snare she springs | **Clings:** the thrown crown tumbles on an arc (never spinning flat, never overhead), clings to the torso, back or arm (never the head, neck or face) and goes off 20 ticks later | Thin (×0.4), precise and the fastest sweep (38°/s, inside E81's 20% of the reference's 32), from the mantle's hem or her blade hand's edge, never a fingertip; her own look | **A line** across the air that fires her level-1 beam along itself when crossed |
| **The Demon Cyborg,** appetite: wreckage and metal only (molten slag oranges with scrap-metal grey, Art's lane) | Villain; hunger (menace) | **A lash:** a crane hook on a line. Payoff **the throw**: a swing that flings him 6 bh along the stick. Held (E61): **aim**, a long cast that leads his flight | **Rolls** along the ground as molten slag | Ragged and unstable, vented from his **chest furnace,** through a chest plate or grille with vents (never a maw, teeth, jaw, mouth, head or belly); his own trait | **A field** that drags a passing fighter down: **Scrap Pit,** clamps and plates around a pit that holds and drops; no chewing and no teeth (Narrative; Legal e14) |

- **The EP confirmed this map** over the starting points in Game Design's §14 (2026-10-23): four distinct looks and four distinct payoffs. Every kit differs from every other in at least four cells (grab, lob level 2, beam and trap), against §14's rule of three. The bands in §14 also hold: beam damage per level within 15% of the reference, beam length within 25%, and a trap's hit within 15% of a level-1 beam.
- **Colours are Art's lanes** (`data/art/energy-lanes.json`, eed730f1): each kit names its `lane` and reads core, main and edge per kind (bolt, lob, beam, grab, trap) from that file. Only `light.colour`, the lane's bolt main, is carried, and it is checked against the file.
- **Narrative's re-fitted names** (lob, beam, trap, grab):
  - the Protagonist: Pier Lob, Breakwater, Trip Pillar, Harbour Net;
  - the Rival: Stair Split, Lance Sheaf, Pressure Plate, Rank Ring;
  - the Empress: Crown Toss, Hem Sweep, Velvet Rope, Banner Snare;
  - the Cyborg: Slag Roll, Furnace Vent, Scrap Pit, Crane Hook.
- **Drain and confine became looks and payoffs inside the templates.** The ki table is everyone's, so no fighter takes another's ki. A siphon payoff may be proposed to Game Design as a future template.
- **The Cyborg's whole energy set runs on wreckage and metal, never on people** (Legal ln02, ln04).
- **The Empress's base form** trades the energy stance for her command stance (`docs/design/empress-guards.md`). She keeps one bolt and her beam, and her revisions add the rest.
- **The Cyborg's grammar stays whole in every form** (E10). His limiter shows in looks and sound until his final form, and any gating is an open question.

## 3. The data shape (`combat.energy/1`)

One file per fighter. Only what is the fighter's own, plus the frame's numbers where he sits inside a band. Keys starting with `_` are notes.

```json
{
  "schema": "combat.energy/1",
  "fighter": "PROTAGONIST",
  "side": "hero",
  "meter": "anguish",
  "frame": "docs/design/energy-overhaul.md (E1-E117)",
  "names": {"light": "...", "medium": "...", "heavy": "...", "grab": "...", "trap": "...", "beam": "..."},
  "light":  {"shape": "...", "colour": "#rrggbb", "spreadDeg": 6, "speedMul": 1.0, "dmgMul": 1.0, "look": "...", "atoms": ["..."]},
  "medium": {"shape": "...", "arcTicks": 36, "dmgMul": 1.0, "l1Ticks": 28, "l2Ticks": 48,
             "l2": {"template": "bounce|split|cling|roll", "...": 0}, "look": "...", "atoms": ["..."]},
  "heavy":  {"look": "...", "dmgMul": 1.0, "atoms": ["..."]},
  "beam":   {"shape": "...", "widthMul": 1.0, "sweepDegPerSec": 40, "end": "...", "levelTicks": [30, 54, 84],
             "trait": {"kind": "wall|sheaf|...", "pushMul": 1.0, "_note": "always 1.0: E96, looks only"}, "pulseLook": "...", "struggleLook": "...", "atoms": ["..."]},
  "grab":   {"look": "net|ring|lash|cage|own", "payoff": "yank|bind|slam|throw", "throwTicks": 30, "catchTicks": 40,
             "held": "...", "answers": ["..."], "reads": "...", "atoms": ["..."]},
  "trap":   {"template": "line|pillar|field|own", "what": "...", "numbers": {"...": 0}, "trigger": "...", "answer": "...", "look": "...", "atoms": ["..."]},
  "snare":  {"look": "..."},
  "mines":  {"spark": "...", "blast": "..."},
  "collateral": "...",
  "forms": "...",
  "atoms": {"en.protagonist.light.tap": {"windup": 0, "active": 4, "recover": 6, "tell": "...", "pose": "..."}},
  "legalAsks": ["..."],
  "openQuestions": ["..."]
}
```

## 4. Rules every fighter keeps

- **Original only.** No pose, gesture, shape, sound or name that echoes a well-known anime, manga or fighting-game move. Examples to stay clear of: the two-handed charge cupped at the hip, a pinpoint beam from a fingertip, a sphere gathered overhead from others, a thrown spinning cutting disc, a beam from two fingers at the brow. Legal screens after (`docs/legal/originality-rules.md`).
- **The press feel** (Orb, `melee-press-feel.md`). Each press is one action. The ground and the energy never hold a press the brawl would take.
  - A grab or trap that holds the foe gives him an answer, at most 45 ticks without one, and a visible tell first.
  - Nothing locks a player out of acting for more than Game Design's caps.
- **The look gate** (ADR 0010): no dissolves, fades, slow wipes, full-screen blur, or markers over the fighters. Energy appears and is spent physically: it fires, hits, bursts, burns out, cools.
- **Never out of range.** A seeking shot reaches at any distance. A trap or grab that needs range says how it closes the gap.
- **Hero and villain.**
  - The Protagonist's energy is pressured by collateral: it angles away from people and narrows near them, and every life it takes costs him (anguish).
  - The villains' energy feeds on it: they widen near people, and casualties and fleeing people feed menace.
  - Every collateral budget still caps the deaths.
- **Data, not code.** Every number is in the file. Determinism is untouched: seeded draws only, through the director.
- **Legal's conditions** (`docs/legal/energy-overhaul-screen.md`, e11 to e13 and fx08):
  - **Nothing in or above a hand:** no ball, sphere or orb in or above a hand; a charge is a brightness step at the hand or a thin ring, and a loaded hand is a steady light.
  - **Beams and hoops:** no flat spinning disc or hoop; no spiral, drill or helix beam (a twin beam's tints alternate along it, never around); no hand-frame, fingertip, finger-gun or two-finger beam; no fireball from cupped palms.
  - **Binds:** they take arms, torso or body, never throat, face or hair; the held fighter struggles or braces; no slow motion, zoom, taunt or finisher on a bound fighter.
  - **Mines:** they fizzle after 12 s and never move toward people. Arming is a soft single tick, never a repeating beep, and names prefer "Hanging" to "Hung" (Legal e15).
  - **Flash (fx08, fx09):** a stream has a steady muzzle light, not a flash per bolt; a barrage's 4th and 5th bursts in a second draw as smoke, dust and ember, or the bursts share one glow that never falls 10% between them; red lanes peak on a white-hot core; at most 3 counted bursts a second in a window, and a level-2 split counts as one; a pulse is a swell under a 10% luminance step; a line of mines flares staggered.
- **Each fighter's forms** may change the kit. Say how, briefly: the Empress's guards, the Cyborg's final form, the Protagonist's heat, the Rival's pride.

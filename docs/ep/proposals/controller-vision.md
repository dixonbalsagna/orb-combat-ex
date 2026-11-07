# The playable build: controller vision

From Orb's stand-in, 2026-11-06. It answers Orb's ask through the EP: "brief me on their vision for the playable build along with any improvements they can engineer." It builds on:
- the EP's brief (`docs/ep/standin-controller-brief.md`);
- Game Design's beam replay (`docs/design/beams-third-play.md`) and its pages on beam answers, right-hand attacks and buildings;
- the pad packet;
- Orb's words in `docs/ep/vision.md`.

**How it was checked.** Four read-only readers (about 0.9M tokens) checked every claim against the code and against the tree of the build Orb plays (`homework/Files/builds/orb-first-play-10d8b8cf-68ee07cc/tree`). A skeptic (about 0.3M) then found 13 problems in the first draft, and all are fixed here. Design only: nothing here is built.

## The idea in one line

**Your left hand flies and defends, your right hand hits, and the two meet in one family of flight strikes you choose.** Nothing locks you up unless you asked for it. Every press either happens or tells you why it didn't. And the city takes the fight instead of bouncing it back.

## 1. The pad

"Already on your page" means it's switched on in the build you play, even if main has it off.

| | Today, on your page | In the playable build | Why it feels better |
| :--- | :--- | :--- | :--- |
| **Left stick** | Move and fly | The same. Knocked back, **hold LT to brake in the air** (built, off). Later, **a small steer of where you land** | Fewer moments as a passenger |
| **LT** | Tap to dodge or slip; hold to sprint; with X or Y, four unrelated moves | Tap and hold unchanged. **LT + a face button, up close or at zip range, is a flight strike: the left stick picks the path** (section 2) | One grammar: the stick says where you go, the button says what you hit with |
| **LB** | Guard; a tap just before a hit is a perfect block | The same. When a beam is coming, LB is the powerful block, and held it's the catch | Defence stays on the left hand |
| **Right stick** | Flick to strike in four directions. Hold to charge, and the pad ticks at each level (already on) | The same, plus **2 to 6 charge stages by power**, a sound that rises with each stage, and a pose that grows. Let go to fire | You feel what you're about to throw |
| **RB + right stick** | A beam that went through the signature request and usually did nothing | **The beam is its own move.** Hold to charge in stages, let go to fire where the stick last pointed (that aim fix is already on), at any range. No 15-second wait, and up close it throws them back | It fires whenever you've got the energy, or tells you why not |
| **RT** | Hold to power up | Unchanged | |
| **RT + right stick** | Nothing | **Your signature:** hold and let go. It's always aimed at them. Loupe's is a volley, not a beam | Each fighter's big move on the stick, as you liked |
| **RT + B** | Your signature (a stopgap on your page) | **A faster version of B's big blow** for 15 energy, on a switch so you can try it (Game Design's pick; your call) | Frees the signature for the stick, per your rule |
| **X, Y, B** | Light, heavy, biggest; tap, mash or hold | The same nine ways to press | The brawl you approved |
| **A** | Grab near, taunt far | The same | |

**Rules kept:**
- Beams only from the right stick.
- No claw-grip gain: the right thumb is on the stick or a button, never both.
- Each press is a blow.
- A held stick wins.
- Every camera move eases.

## 2. Flight strikes: your three circle moves as one toolset

Today the zip, the step through, the hop over (LT + Y) and the dodge loop are four separate systems. Why LT + Y felt strange, from the code:
- It isn't a circle. It's a 0.4-second hop over the head, and you only choose over or under at the press.
- It fires on every LT + Y in reach.
- It always lands you on the far side, so the stick you were holding suddenly means the opposite.
- It drains your energy to zero instead of refusing.
- A medium blow can stop it partway.

**The grammar: hold LT, point the left stick, press a face button.** The direction is read at the press, relative to your opponent. It works from close range out to the zip's range, 12.5 body heights.

| Left stick | The path | Where you end up |
| :--- | :--- | :--- |
| **Nothing** | **The zip:** straight in, the blow, straight back | Where you started |
| **Toward them** | **The line:** through them, striking as you pass | Their other side. **The side switch is your choice** |
| **Up or down** | **The arc:** a real loop round them, over or under, striking from the top or bottom of the loop | Above, below or behind them |
| **Away** | **The parting shot:** the blow, then out further than you started | Out of the brawl, with a hit to show for it |

**The button picks the blow at the end:** X quick, Y heavy, B your biggest. That makes twelve moves that work the same for every fighter. Each fighter's style changes only how they look.

**How it fits LT's other jobs** (needs Game Design's ruling and Controls' claw check):
- **LT alone stays the slip or the dodge.** Today, up close, an LT tap with the left stick is a slip (your 2026-10-28 rule). With the stick away, it's the dodge-cancel that ends a brawl. Held while moving away, it's the Escape stance.
- **A face button within about 8 ticks of LT turns it into the flight strike.** The slip or dodge-cancel is taken back, with its energy and cooldown refunded. With no face press, LT does exactly what it does today.
- **Not read while you're knocked back,** where held LT is the air brake.
- **Not read when flying flat out from afar,** where LT + B is already the long strike and the spike off a trail.

**Chaining:** press the next flight strike as the last one ends and it follows with a short tell, a little weaker. You can keep going until your energy runs out (your 2026-10-05 pick), and the price rises each time. If you can't pay, the pad knocks and nothing starts. No more draining to zero.

**Counters stay:** a well-timed heavy or skill strike stops it (Orb, 2026-10-05). A stopped flight strike leaves you where you were and free, as the hop does today, never knocked down.

**"Control taken away":** when the computer dodges and loops round you, you only follow if you're still pushing toward it.

**Honest size:** the zip's machinery already ends anywhere on a circle, passes over or under, and keeps Legal's minimum travel time (RL-076). Missing pieces:
- A true loop path (core code: Simulation's grant).
- Reading the stick at the press.
- Letting the zip start up close.
- Chaining.
- The LT take-back.
- One dispatcher to replace four.

Plus a look per path from Animation, a streak from VFX, Camera framing both fighters, the look gate, and a clip of each move with the buttons drawn. **About 5 to 7 director sessions.**

## 3. Beams that do what you press

From Game Design's replay of your third play: your stick beam started 36 times, and none of your own beams left your hand.
- **Inside a brawl** it was silently refused, because it went through the signature's request.
- **Just outside a brawl** it turned into a heavy, which the computer dodged.
- **Far away,** the signature's 15-second wait refused it.

The computer's beam was its signature, which locked you while it charged.

**The fix, one rule for everyone:**
- **The beam is its own move:**
    - It costs its stage's price.
    - There's no signature wait.
    - It fires at any range, including point blank, where it throws them back the way they face.
- **Charging is protected from light blows from the first moment.** On your page that starts at 0.2 seconds. A medium in the first half second, a heavy, a grab or a beam still stops it.
- **Nobody is locked while someone charges.** You can hit the charger, guard, dodge or answer.
- **A beam can't fire until its target has been free for 0.3 seconds.**
- **The computer fires through the same move.**
- **Every release that can't fire says why,** with a knock on the pad and a word at the edge: "No energy", "Hit".
- **A held charge never fires by itself.** Today a held stick lets go on its own after about 1.1 seconds. A 6-stage charge needs up to 2 seconds, and a swat needs you to hold until the beam arrives.
- **The warning when a beam is coming at you** (built, off on your page) goes on: a rumble that tells you to answer.

**Answering a beam,** with your left hand defending and your right hand attacking:
- **Fire back:** RB + the right stick toward them. This already works, and it was the only beam that fired for you.
- **Dodge:** LT tap with the left stick.
- **Powerful block:** LB as it arrives.
- **Catch:** hold LB as it arrives. You're pushed back, carving a trench, or driven down with a crater under your feet if it comes from above.
- **Swat,** your idea: charge a right-stick strike and release it as the beam arrives. More stages swat a bigger beam, and mistiming it means you take the hit.
- **Walk into it:** Game Design has a full design and Legal has cleared it with limits. It's your call when you want it.

**Winning the clash, made obvious:**
- **The beat:** the meeting point already throbs on it. Add a sharp sound and a rumble on a good push, and a dull knock on a stray one.
- **Teaching:** the first three clashes of a match show the push at the edge of the screen.
- **Which button pushes** is the question at the end of this page.

## 4. Pressing the fight into the city

What you saw is the wall slam:
1. A tower holds the hit.
2. The whole fight freezes for half a second.
3. The fighter is thrown back at a quarter of his speed.
4. His depth snaps back to the fight's line in about a third of a second.

That's the ping-pong. Nothing turns the world after an impact today. The world swing can turn the city around the fight's line, but it can't move the fight onto the street behind a building. So this comes in two steps.

**Step one, in the playable build: mostly turning on and tuning what's built** (about 2 sessions):
- **Only he is held, and the fight goes on.** That's the existing "hold only the body" switch; today the whole fight freezes.
- **No more ping-pong.** He stays at the building's face for that hold instead of bouncing out (a new data value).
- **The world turns on impact.** This is new: the swing fires at the hit and eases the city round toward the street, so the camera angle changes. It has a written reason for the camera, and no cut.
- **A follow-through window:**
    - **B toward him follows the tower ladder** that's already ruled: at base power he goes into the tower and lodges, and from tier 2 he goes through one tower and into the next. A weak send through a tower stays "never".
    - **Y slams him again.** The building remembers (built, off), so repeated slams break it.
    - **LT + toward zips after him.**
- **His way out:** a perfect block, or the wall kick (built, off).
- **Your choice to make by playing:** Game Design built two versions of being stuck in a building. "Brief" is a short hold. "Pinned" is a longer hold where the attacker's shots can't miss. You're meant to play both and pick. Legal hasn't screened the pinned hold yet, so it goes to them first.

**More fights near buildings.** Today about 3 in 57 launches meet a building with swings on, against a target of 4 to 8 a match from a start in town. The levers are built and off: pushing the fight toward a building with the left stick, and fights visiting towns. They come on with this, **after QA reads the civilian band and match length.** Nothing about bystanders changes while Legal's RL-247 hold stands.

**Step two, later** (large): the fight's line runs down the street through the city, with buildings acting as real walls on a turned line. That needs new core work from Simulation, plus walls that hold when nothing is aimed at them. Without it, a fight pressed down a street would ghost through buildings.

## 5. Always in control, and every press answered

- **Four places still swallow a press with no sign:**
    - A face press that waits too long behind the stick.
    - A stick stun held back by the one-a-string rule.
    - The director's attack queue running out.
    - The perfect-block anti-mash lockout.

  Each gets a knock on the pad and, the first few times, a word at the edge.
- **Rumble.** Your page already rumbles on:
    - a launch, for the launcher only;
    - a full charge, each charge level and the release;
    - the clinch, the air brake and beam struggles;
    - refused stick presses and incoming stick strikes.

  **Missing from your 2026-10-05 picks:** landed blows, closes, landings, building breaks, and launches felt by the one launched.
- **No input lost in a stall.** When the page hitches, several game steps read one pad snapshot, so a quick flick can vanish. The fix keeps every button press and the stick's furthest point since the last step.
- **Hitches and crackle.** On main, the largest single cause of slow frames is bursts in the planet drawing (29 of 71); destruction isn't the main one any more. Rendering times and fixes those. The crackle is sound mixed on the page's main thread. The two quick fixes trade some delay or some effects for smoothness, so they need your ears.
- **A faster stick strike at range.** A flick up close lands in about 11 game steps. At range it asks for the heavy lunge and lands at about 25. Asking for the light lunge fixes it.

## 6. Improvements, ranked by fun and responsiveness

Costs are at about 1M tokens per director session, including the look gate's clips, QA batches and the EP's landing gates. Orb's week is about 110M.

| # | Improvement | What you'd feel | Owners | Rough cost |
| ---: | :--- | :--- | :--- | ---: |
| 1 | **Beams that do what you press** (section 3) | Your beam fires every time you've got the energy, or tells you why; nobody shoots you out of a lock; a rumble warns you one is coming | Encounter, UI, Controls | 4M |
| 2 | **Every press answered** (section 5) | You always know whether the game heard you | Encounter, UI, Audio, Controls | 2M |
| 3 | **Flight strikes** (section 2) | Your three circle moves as one toolset you choose and chain | Encounter, Simulation grant, Game Design, Controls, Animation, VFX, Camera, QA | 5M to 7M |
| 4 | **Hitches, crackle, and no input lost in a stall** | Smooth at the big moments, and no flick lost to a hitch | Rendering, Controls, Audio, Performance | 3M |
| 5 | **Clash made obvious, with a choice of how you push** (section 8) | You know how to win a beam struggle in the first second, with the input you prefer | UI, Audio, Controls, Encounter, Game Design | 2M |
| 6 | **Pressing into the city, step one** (section 4) | A wall slam turns the world and gives you a moment to follow through | World, Encounter, Camera, QA, Legal | 2M |
| 7 | **The rumble you picked, still missing** | Every hit, landing and building break felt in your hands | Controls, Audio | 1M |
| 8 | **Charge stages by power, and the swat** | You feel each stage build, hold as long as you like, and can time a release against a beam | Encounter, Controls, Audio, Animation, VFX | 2.5M |
| 9 | **Signature on RT + right stick, and RT + B as the power blow** | Your big move on the stick | Controls, Encounter | 1.5M |
| 10 | **Stick strike as fast at range as up close** | The flick feels instant from any distance | Encounter | 0.3M |
| 11 | **Air brake on (built), then steer your fall** | You get control back sooner after a knockback, and later nudge where you land | Encounter, Simulation grant, Controls | 0.3M, then 2M |
| 12 | **Housekeeping:** land on main what your page already has (Controls' and Encounter's switches) | Nothing new to you; main stops drifting from your page | EP, Controls, Encounter, QA | 2M |

**Total: about 27M to 29M tokens, roughly a quarter of a week.** Step two of the city (about 6M to 8M) and each fighter's own signature move come after.

## 7. The tools I want first

| # | Tool | Why | Rough cost |
| ---: | :--- | :--- | ---: |
| 1 | **Feel replays:** replay any of your saved matches with a candidate rule swapped in, and count beams fired, refusals, side swaps and time without control. It forks at each press of interest | Every change gets checked against your real hands first. Its base tools exist but aren't committed yet, so the EP commits them first | 2M |
| 2 | **A refusal ledger:** from a saved match, every press the game didn't honour, when and why | It turns "it felt like it ignored me" into a list we can fix | 0.5M |
| 3 | **A button strip in the clip kit,** and a clip recipe for each flight strike and beam answer | You judge each move in one sitting, seeing what was pressed | 0.5M |
| 4 | **Pad lab, small version:** a page with no fight that reads your thumb (dead zone, rise time, drift, aim spread, spring-back) and saves a profile | Stick thresholds from your thumb, not a guess. It also catches a phantom pad | 0.5M |
| 5 | **Scheme gauntlet:** scripted players play many matches against each computer level for each scheme | Proves a stick player isn't stuck losing before you feel it | 2M plus machine hours |
| 6 | **Record every pad's right stick** in the black box | A phantom pad can't hide your real stick again | 0.2M |

## 8. What pushes in a beam struggle: an option (Orb, 2026-11-06)

Orb's answer: "Put it in options, let players choose whether they want rhythm on right stick (easiest), rhythm on face buttons (hard), or another undecided mode potentially."

| Mode | What you press | Notes |
| :--- | :--- | :--- |
| **Right stick (easiest), the default** | Flick the right stick toward them on the beat, however you fired | Game Design re-rules its "in a struggle the stick does nothing" row and the walk-in's presses |
| **Face buttons (hard)** | X, Y or B on the beat, as today | A on the beat still lets go |
| **A third mode, undecided** | Stand-in's suggestion, for Orb to judge: **hold steady**. Hold the right stick toward them with no rhythm, and your push comes from your charge stages and energy. It's an accessibility mode in the spirit of Orb's "Simple controls: all of the spectacle, chosen for them" | Not built; Orb's call later |

The stand-in's calls on the details:
- **Every mode pushes equally hard.** The option changes only what you press, never how strong you are, so it stays fair in versus and over LAN.
- **The setting is per player,** and each pad keeps its own. The first three clashes of a match teach whichever mode that player has chosen.
- **Owners and cost:** UI adds the option and its words, Encounter reads the mode, and Controls checks the claw law for the stick mode. About 0.5M on top of item 5.

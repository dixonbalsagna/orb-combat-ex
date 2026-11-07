# Controller brief for Orb's stand-in (EP, 2026-11-06)

**Orb's ask (2026-11-06):** "in order to best create a controller scheme to maximize fun and responsiveness, write up a detailed, technically rich overview of the gameplay feedback you've collected with me... brief the stand-in with details that could prompt useful controller insights and lead us to smooth, enjoyable controller schemes." The stand-in's job includes engineering new features.

**What the stand-in returns:** a brief to Orb on its vision for the playable build, plus the improvements it can engineer. Orb's standing order is in the last section: token limits are lifted, and agent swarms are approved where they help.

Orb's own words are quoted from `docs/ep/vision.md`. Numbers come from replays of Orb's saved matches. Each replay was checked against the match's final hash, so the counts are what happened. Orb's play files are in `homework/Files/orb-first-play-*.json`. Read them only through the replay tools (`qa/godot/trace_replay.gd`, `qa/godot/ai_compare.gd`, `tools/preview/blackbox*.mjs`); don't copy Orb's raw samples into the repo.

---

## 1. Orb's hardware and setup

- **Pad:** an Xbox 360 controller (XInput, the browser's standard mapping, axes 2 and 3 for the right stick), on Windows, played in **Opera GX**. Its tab limiter can slow the page. Sound was silent in GX on the second play and worked on the third.
- **Builds:** each kept build is the page built from main plus Tools' stack: overlays, Controls' parks and page words. The playable is `homework/Files/builds/orb-first-play-10d8b8cf-68ee07cc` on port 8766.
- **Controls' parks are not on main.** `first-pad`, `quick-read`, `stick-feel` (responsive-2, first-press, signature-rt-only, web-rumble, haptic-switches), `beam-aim` and `stage-haptics` live only in `docs/controls/pending/` and the page stack. `data/input/timing.json` still has `switches.rightStick: false` on main. A scheme that ships means landing these.
- **A possible phantom pad.** `rawRightStick` reads the first pad that has a right stick. With a phantom pad listed first, it records the phantom and stays empty while the real pad is in use (Controls, 2026-11-06). `first-pad` (the first press of a never-used pad takes P1) answers it, but it isn't landed. Orb's first play had the P2-seat bug: slot 1 carried nearly all the input.
- **The new recorder** (`rawPad`, fcd2cf58) saves every pad's buttons as a bitmask on each change, both triggers, and the left stick. It reaches Orb in the next build.

## 2. Orb's rules for the pad (settled; don't relitigate)

From `docs/ep/vision.md` and the pad packet (`docs/controls/pad-packet.html`):

1. **Left stick moves and defends; right stick attacks** (2026-10-28). Slips and dodges are LT, LB or both, plus a flick of the left stick.
2. **Directional-charge strikes** go on the right stick: a flick is a quick stunning blow, and holding a direction charges a powerful one. The feel Orb named is the platform brawlers' smash attacks. In the repo say "directional-charge strikes" or "platform brawlers", never a franchise name. Orb picked **4a** on 2026-10-30, making stick strikes their own class outside light, medium and heavy.
3. **Beams are fired only with the right stick,** "with extremely few, if any, exceptions" (2026-11-01). No beam or beam answer goes on a face button. RT + B is out. Orb wants a brief window to dodge, block powerfully or fire back, plus walking into a beam, swatting it away, "and anything else cool".
4. **One consistent idea across the face buttons and the four shoulders,** with every reasonable shoulder combination pitched (2026-10-28).
5. **Zero claw-grip advantage.** The right thumb picks the stick or a button, never both at once. The lockout law is L = 6 ticks and R = 8 ticks (K1 to K3, `sim/input/strike_law.gd`).
6. **Each press is a blow** (the approved melee prototype, `docs/ep/prototypes/melee-trade-v2.html`, 2026-10-04):
   - Mashing gives faster flurries the quicker you tap.
   - A timing player lands flashy skill strikes that lapse into flurries on a missed beat.
   - The heavy is reliable against a heavy guard and sets up juggles.
   - The flurry belongs on every attack.
   - Holding charges a light or a heavy alike.
   - A fully charged Y punishes a flurrier who doesn't block.
7. **"Players should always feel like they are able to control their character, with few exceptions like during knockbacks"** (2026-10-05). When a rule trades control for spectacle, control wins. Each player can nudge the pair's centre during an exchange.
8. **Combos are generated the way procedural games generate worlds.** Don't alienate players who like set combos; appeal to platform-brawler fans and procedural fans alike (2026-10-30).
9. **Customisable controls and a left-handed swap** are assumed. Both are already built: `swap.gd`, hand layouts, Remap.
10. **Keyboard and gamepad are equal** (questionnaire 1). Mobile is parked (ADR 0011).
11. **Camera:** every camera move eases, and a hard cut needs a written reason (2026-10-22). No dissolves, fades, slow wipes, full-screen blur or markers over the fighters (2026-10-18).
12. **Hit weight:** Orb can't tell hit-stop variants apart, so never ask again. Game Design and Combat pick.

## 3. What Orb felt, play by play

### First play (2026-11-01)
- The P2-seat bug: Orb's input drove slot 1.
- Beam aim: on Orb's file, 92 of 103 beam throws read aim 0 at release. The release row read the stick after it had snapped back to centre. Controls' `beam-aim` park fixes this with a 4-degree trailing aim band and a throw that carries the mean of the last 3 rim ticks. Not landed.

### Second play (2026-11-01, `orb-first-play-20261101-2130.json`)
- **"Tight circle then attack" on a held LT: Orb loved it.**
- **Knockbacks feel arbitrary.** Orb wants control over combos.
- Beams and charging felt unclear.
- No sound in Opera GX.

### Third play (2026-11-06, `orb-first-play-20261106-1934.json`, 6.3 minutes against the easy AI)
Orb's words: "sometimes felt like control was taken away from my character, was forced into switching sides with opponent and then they fired a beam at me. I couldn't figure out how to fire a beam at close range but the opponent seemed to be able to pull off charging beams in melee range." First change: "Tighten beams up, make sure it's obvious what to press to win beam clashes, lets keep refining the right-stick mechanics, keep refining the combat." Sound: "during high speed impacts the frames stuttered and the audio sounded crackly."

Game Design's replay (`docs/design/beams-third-play.md`):
- **The stick beam went through the signature request.**
  - It was started 36 times, 18 of them up close. None of Orb's own beams fired; only 3 answers did.
  - Inside a brawl, releasing did nothing, and said nothing.
  - Just outside a brawl it became a heavy, which the AI dodged and countered.
  - Holds were broken by blows 10 times.
  - Far away, the signature's 15-second wait refused it 3 times, silently.
- **The AI's beam is its signature.** The brawl gives way to it and Orb is locked. 4 of its 6 charges came up close.
- **The forced side switch** was the AI's point-blank signature. It locked Orb, and its charge rise carried the shooter over at a 1-unit gap, 17 and 21 ticks into the charge. Separately, 16 of 31 side swaps were dodge exchanges carrying Orb round the foe.
- **Nothing shows how to win a clash.** You win by pressing X, Y or B on the beat, and nothing on screen says so.

Game Design's recommended changes (approved in principle; build pending):
- The stick beam becomes its own move: a stage price, no signature wait, any range, and the brawl gives way only at release. It's protected from light hits from its first tick, and the AI fires through the same move.
- Nobody is locked while someone charges.
- Every refused release says why.
- A beam can't fire until its target has been free for 0.3 seconds.
- A dodge exchange's follow happens only while the player is still pushing toward the foe.
- Clash prompts appear for the first three struggles, with a sound and rumble on a good press and a knock on a stray one.

**"Kept attacking after I let go"** (QA, `qa/godot/trace_replay.gd` and `ai_compare.gd`):
- The sim never attacked by itself: only 6 events came more than 20 ticks after every control was released, and none was sustained.
- At 3:11 to 3:18 the right stick was at rest, but the intent stream was not. The left stick swung between full left, down and right, and heavy, signature and dodge presses came every few ticks.
- No AI hand-off: `replay.toggles` is empty, and those intents agree with the sim AI's choices only 27% of the time.
- So it was device input: a noisy or phantom pad, or more pressing than Orb felt. `rawPad` will tell the next time.

**Stutter and crackle** (Performance, `docs/perf/impact-stutter.md`, in progress):
- The sim isn't the cause. 81 of the 94 slow frames had a sim tick under 4 ms natively; the worst tick in the match was 20.3 ms.
- The stalls are page-side, on destruction:
  - 162.6 ms at tick 773 (two launches, 24 building stages, 49 afterimages)
  - 104 to 125 ms with fire, scorch marks and building falls
- The web audio worklet skips an output block when a main-thread stall outlasts its roughly 93 ms buffer. That is the leading cause of the crackle.
- A stick scheme that feels responsive needs frames that keep pace at the moments of impact.

### Fourth play, with the circle on (2026-11-06, `orb-first-play-20261106-1956.json`, `?circle=1`)
- Of the three clips (circle-t14080, the dodge exchange that loops round the foe; step-strike-t5150, LT + X straight through along a line; zip-t13150, straight in, a blow, straight out), Orb said: **"all three of those should be refined, folded into the game, and be recognizable as part of a player's toolset."**
- LT + Y, the circle: **"worked very strange, but as a baseline I would really like to see those movements evolved, overhauled, expanded on. Keep refining controls."**
- **"The fighter that collided with a building bounced back into the plane we were fighting on like a ping pong ball. I was hoping I'd see the camera angle change and then be able to press the fight into the city."**

  This connects to Orb's turntable pick: the fight's bearing changes and the world swings round the fighters (2026-10-31, Research's E and E2, "closest to my vision"). A send into a building should open a new line of fight, not snap back to the old plane.

## 4. Measured responsiveness and known gaps

From `docs/controls/responsiveness.md`, the controls audit and QA's arms:

- **Latency:** a tap reaches a hit in 3 ticks. A stick strike takes 15 ticks: 3 to 4 to read the stick, plus the director's 12 wind-up ticks. Vanish waited 6 ticks. `quick-read` (settle 1, vanish on the second press, a pre-pose for the strike) is parked.
- **Stick-only play is weak.** The stick-only QA arm won 4 of 30 matches against easy and 0 of 30 against medium.
  - 1,162 of 1,417 refusals on stick-only were "late", even with the pending follow.
  - Flick runs at 1.5 and 2 came out identical, probably a rounding issue.
  - The masher at medium scored 52, over its band.
- **The clean band misses.** Game Design wants 10 to 25% clean hits from the stick; it gets 0 to 2% on the beat and 6% on the pad. Lights take 88% of stuns.
- **LB + flick:** its stun is eaten by the one-a-string and third-in-3-seconds rules, and 13 to 22% of presses leave no cue (untraced).
- **The audit** (`docs/controls/controls-audit.md`) found that brace, vanish, the RT specials, the Driver and the beam sweep had no answer in the sim. Game Design ruled (`docs/design/pad-first-press.md`): brace and specials off, L3 unbound, R3 cut.
- **Built but off:** `rightStick`, `quickRead`, `beamAim`, `hapticLadder`, the rumble kinds (`stick_refused`, `release_thump`). Four more rumble kinds wait for a go: landed blows, launches, landings, building breaks.

## 5. Questions worth engineering answers to

These are prompts, not rulings; pitch what you think plays best.

1. **The three circle moves as a toolset.** How do the dodge loop, the step-strike line and the zip become a family the player owns and recognises? Consider:
   - one input grammar: LT plus a direction plus a face button or stick, where the shape of the stick motion picks the path (arc, line, in and out)
   - chaining one into the next
   - which ones close distance, which ones switch sides on purpose, and which ones bait a beam

   Orb loved the loop, and the side switch that hurt was one Orb didn't choose. Owning the side switch could turn it from a punishment into a weapon.
2. **The right stick as an analogue instrument.** Use the flick's speed, the hold's depth and a rotation (a rim-to-rim pump, the stoke) as separate verbs, within the claw law. Measure what an Xbox 360 stick can actually tell apart on Orb's thumb; Controls has `orb_aim_probe.gd` and `stoke_probe.gd`.
3. **Charge feel.** Charge stages should be felt, not read: the rumble ladder (`stage-haptics`), the sound pitch rising, the fighter's pose. The release fires on letting go, toward the trailing aim (`beam-aim`). Up close, a released beam should still do something visible and fair.
4. **Beam clashes.** An answer the player reads in the first second: what to press, whether it worked, and a bulge-and-quiver look that shows who is winning (Orb, 2026-10-22). Orb also wants beam answers on the stick: dodge, a powerful block, firing back, walking in, swatting it away.
5. **Pressing the fight into the city.** A send into a building should change the camera's bearing and give the player a short window to follow through: drive the foe through, pin them, or chase into the streets. Today they bounce back into the old plane.
6. **Knockbacks under the player's influence.** Orb said "knockbacks feel arbitrary". The physics model (`docs/ep/proposals/physics-model.html`: heft, drive, Footing 0.75, Liftoff 2, Skybreak 52 dv per 100 hf) makes them predictable from the force. Directional influence on the left stick during a knockback, or a held direction picking the send, could put the player in charge of them. Physics building waits for Orb's go; designing the controls around it doesn't.
7. **Always in control.** Make sure no state locks a player for long without a readable reason: the signature lock, the AI's charge, dodge carries. Every refusal gets a short rumble and a cue (`stick_refused`).
8. **Input clarity tools.** Clips Orb judges draw the buttons and tap, mash or hold along the bottom. The clip kit (`node tools/clips/make.mjs`) and the F9 / View + RB marks make that cheap. A live input overlay on the page, or an in-game "what just happened" readout from the debug feed, might shorten every play-test loop.

## 6. Tools that could be built for this

Suggestions; the stand-in picks and pitches.

- **Pad lab page.** A small page with no fight: it shows each axis, the deadzone, the flick speed, the hold depth and the rotation in real time, and it saves a profile of Orb's thumb. That replaces guessed thresholds with Orb's own numbers.
- **Feel replays.** Replay any saved match with a candidate controller rule swapped in, and count what changes (beams fired, refusals, side swaps, clean hits). This builds on `trace_replay.gd`, `ai_compare.gd` and the deterministic sim.
- **A scheme bot gauntlet.** Script player arms (stick-only, masher, timing player, beam-first, circle-first) to play many seeded matches against each AI level for every scheme candidate. Report win rate, refusal rate, time with no control and moves used. QA's arms are the start.
- **A refusal ledger in the debug feed.** Every press the sim refused, with why and when, viewable after a match.
- **A clip recipe per move.** Every move in the toolset gets a recipe in `tools/clips/clips.json` with the button strip, so Orb can judge them all in one sitting.

## 7. Orb's standing order (2026-11-06)

Orb's words: "PURGE ALL FLOATING TOKEN-RELATED LIMITS. I AM ON THE ULTRA SUBSCRIPTION, UNLIMITED 5-HOUR SESSIONS, I WANT TO MAXIMIZE TOKEN USE EFFICIENTLY SO A QUALITY PRODUCT IS ACHIEVED, INSTRUCT AGENTIC SWARMS WHERE NECESSARY, SUGGEST PROJECT-SPECIFIC TOOLS THAT CAN BE BUILT TO ACHIEVE OUR GOALS."

- Workflows and agent swarms are approved where they improve quality.
- Machine discipline still applies: at most 6 Godot processes per session, headless only, long runs at below-normal priority, browser captures through Tools' launcher only, stop only your own processes.
- Holds that still stand:
  - Bystander work and the pillar 5 change wait on Orb's follow-up.
  - Physics building waits for Orb's instructions.
  - Don't talk to Orb about flashing.

## 8. What the stand-in sends back

To Orb, in plain words (button names, what you see and feel, no team nicknames):

1. Its vision for the playable build: the controller scheme as a short table of what each hand does, what changes from today, and why it will feel better.
2. The improvements it can engineer, ranked by how much fun and responsiveness each buys, each with a rough token cost.
3. Which tools it wants built first.
4. Any question only Orb can answer, one at a time.

Then the stand-in sends the EP the same plan. The EP routes the builds to directors, gates them, and lands them.

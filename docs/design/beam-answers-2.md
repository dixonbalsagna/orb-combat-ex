# Answering a beam, round two

Owner: Game Design. 2026-11-01, on your marks in `docs/ep/vision.md`. It replaces `beam-answers.md` wherever they differ. **Paper and a toy only. Nothing here has been in the game, and every number is a first value.**

**Try it:** open `docs/design/toys/beam-answers-toy.html` in a browser. It works with your pad or the keyboard. It's boxes on a line, for feeling the timing, not the look.

**In short.** Your charge idea is the answer, and it fixes more than the swat. **Holding the right stick builds stages, and letting go releases.** It's one gesture for everything: with RB it's a beam, with RT your signature, with nothing held it's a charged blow, and if a beam's arriving as you let go, it's a swat. I'm dropping my left-hand swat.

## The pad, now

| You do | What it is | The risk |
| :--- | :--- | :--- |
| **Hold right stick up, down or away, and let go as the beam hits** | **Swat,** where you aimed | Miss and you take all of it |
| **Hold right stick toward him, and let go as the beam hits** | **Knock it back,** bursting halfway. At your top stage, **punch up the beam** | Miss and you take all of it. The punch costs health even when it works |
| **RB + right stick** | **Fire back:** a flick at once, or hold for more stages | You can lose the struggle |
| **RT + right stick** | **Fire back with your signature** | The same, and 45 energy |
| **LT tap and a direction** | **Dodge** | Whatever's behind you takes it |
| **LB press as it hits** | **Block.** It parts around you | Low, and a miss is guard damage |
| **Keep LB down after that** | **Catch.** It drives you back | You pay energy while you hold it. Run out and it breaks you |
| **Hold LB and push toward him before it hits** | **Walk into it:** a fight on the beat | Lose and you're thrown |

## 1. Charge stages

**My pick: your numbers. A base fighter has 2 stages, and a maximum fighter has 6.**

| You are | Stages you can reach | A stage at full power is worth |
| :--- | ---: | :--- |
| Base, no power | **2** | Half, then all, of your energy |
| Base, 100% power | 3 | |
| Tier 2 | 3 | |
| Tier 3 | 5 | |
| Maximum, 100% | **6** | A sixth more each time |

**The clock is the same for everyone.** More stages means holding longer, so the big ones are a real commitment. **Controls measured your thumb:** your longest hold was 1.9 s, and 2.7 s, my first top, was out of your reach. So the top is 2 s, which you can get to, and it's still a real risk with a beam coming. Every right-stick hold uses this clock:

| Stage | Reached after | Beam's energy cost | Beam lasts | Beam's damage |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 0.2 s | 12 | 0.33 s | ×1 |
| 2 | 0.47 s | 20 | 0.6 s | ×1.6 |
| 3 | 0.77 s | 32 | 0.9 s | ×2.4 |
| 4 | 1.1 s | 38 | 1.1 s | ×2.8 |
| 5 | 1.5 s | 44 | 1.3 s | ×3.2 |
| 6 | 2.0 s | 50 | 1.5 s | ×3.6 |

- **How it fits the energy model (`power-scale.md`):** your last stage always spends all your energy, and each stage before it a fair share. So stage 2 of 6 at maximum (20) is still four times a base fighter's best (4.9). Power decides how much there is, and stages decide how much you've gathered.
- **Holding at the top:** you can stay there as long as you can pay, 4 energy a second. It never fires by itself. When you can't pay, it steps down a stage.
- **While holding:** you barely move, and light attacks can't stop you (already ruled). A heavy blow, a beam or a grab still can, and the pad gives a short knock so you know.
- **How you know your stage, with nothing over the fighters:** your hand and body glow step up in your own colour, a rumble pulse and a rising sound mark each stage, and the top stage has its own sound. The small left panel shows a row of pips only while you're holding.
- **Plain charged blows** gather stages too, but their damage and stun stop growing at stage 3. Past that the charge is only good for a swat or a punch.

**Why it should be fun:** it's a reason to power up that you feel in your thumb. Transforming means your beam can get bigger, and a beginner fights with a shorter, easier ladder.

## 2. The swat

**My pick: yours.** Hold the right stick with no shoulder, and let go in the last 0.2 s before the beam hits. **I withdraw my left-hand version.** I'd moved it there because a quick flick would have had to mean two things. A hold doesn't, so that problem's gone, and the risk you wanted is back.

- **The window, for now:** from 0.2 s before it hits to 2 ticks after, judged on the tick your thumb lifts. **It doesn't get narrower than that until it's measured.** Controls' drill should use a moving front, not a flash, since this is about judging an arrival. The toy now shows your own timing and spread, so you can try it. Set the window so about nine in ten good tries count.
- **Your aim:** up goes into the sky. Down hits the ground at your feet, and on the ground that's where **the ground answers** (a wall heaves up and the beam bursts on it). Away goes over your shoulder. **Toward him, below your top stage, knocks it back along its own line, and it bursts halfway.** At your top stage it's the punch. Most of your holds point straight at or away from him, so this one had to do something. The direction you held is the direction it goes, with no help toward a town.
- **You need enough charge.** Your charge's energy is measured against his beam's:

| Your energy against his | What happens |
| :--- | :--- |
| At least half | **A clean swat.** His beam ends, and he's stuck for 0.5 s |
| A quarter to a half | **Glancing.** It goes aside, you take 30% of it and you're knocked back |
| Under a quarter | You were never going to move that. **You take all of it** |

So at equal power you need about half your stages, which is 0.77 s at maximum. A base fighter can't swat a maximum signature at all, and that's what the model promises. **Start charging when his hand lights up:** the charge and flight give you 1.4 s, so you can reach stage 4.

- **Miss:** too early and it's a charged blow into the beam. Too late and you never let go. Either way, **you take all of it.**
- **His answer:** he can hold his own beam ready, so you don't know when it's coming. Nothing else. The mind game is the point.
- **The price:** just the charge's own, 3 to 8 energy by stage.

## 3. RT

**My pick: RT stays the charge. You still need one button that means "I'm powering up".** It matters more now, because power is what buys stages. So holding RT is how a base fighter becomes a 6-stage fighter. Standing there charging while the ground cracks is the genre's best moment, and I wouldn't give it up.

| | RT is | For | Against |
| :--- | :--- | :--- | :--- |
| **A, my pick** | **Hold to power up.** With a button or the stick, it spends power: specials, the signature, the power blow | One idea. You're wide open while you charge, which is a real decision | RT does two jobs |
| B | Power only rises from fighting. RT is an "overdrive": a burst that strengthens your next attacks | Faster fights, nobody stands around | Loses the powering-up moment |
| C | RT is a pure special button, and power-up moves to a click of the left stick | Clean | A click is awkward while steering, and you asked for powering up to matter |

**RT + B: the power blow, as before.** B's big charged blow reaches its flash in 0.4 s instead of 0.73 s, for 15 energy. It's "pay instead of wait", which is what RT means everywhere under A. **A real difference to feel for yourself,** so it's on a switch.

## 4. The signature on the stick

**My pick: Combat's idea. One press and four verbs: RT + right stick, 45 energy, one cooldown, and what the stick does during it is the fighter.** You'd know whose it is with your eyes shut. **Your stage count sets its size,** and it always spends your top stage. These are first ideas, with names for Narrative:

| Fighter | The verb | Your hands | What the stage count does |
| :--- | :--- | :--- | :--- |
| **Grist** | **Holds** | Hold at least 0.8 s, let go to fire, at him. **The direction you hold is where the hit puts him:** toward carries him off, up throws him skyward at the end, down drives him into the ground, away drops him at your feet for a follow-up | How much force: a short plain lance at base, a column to the horizon at the top |
| **Loupe** | **Flicks** | Hold RT, and each flick throws a volley as he walks forward. **The direction picks the volley.** Land most of them and he arrives with one heavy blow. If not, he's open | One volley a stage: two at base, six at the top |
| **Orza** | **Draws** | The line fires at him, then **the stick drags it across the world,** whole and straight, at her own speed | How long the sweep lasts |
| **Bolus** | **Stokes** | **Pump the stick** to open the slats, and let go at the top. Let it sit and it sputters back. On the last pump, toward is a column, and down comes up under him | How many slats |

- **Loupe's isn't a beam, so it can't start a struggle.** He fires back with RB + stick like anyone. It's your call whether that's fine for a signature, and answers work volley by volley. **It's the one to prove first:** it's the most character and the most control, and the shot kinds exist.
- **Limits:** Loupe's volleys have to pass Legal's limits on hands and the flash rule, and six in a row needs that most. Orza's line never bends. Bolus's pumping needs a thumb's read from Controls, and if it's hard on thumbs or the claw grip, it's a plain hold with a sputter you time. Nothing opens, and nothing eats.
- **Orza only has it from her ninth revision,** and against open sky a thin line needs something to cut.

## 5. Walking into a beam

**My pick: make it the beam struggle, with your body in place of a second beam.** That's the game's core shot, and it's already built, on the beat. I'd offered a slow walk with one choice for him, when to cut it. This is a contest for both of you.

- **Press:** hold LB and push toward him before the beam hits. Then **press X, Y or B on the pulse,** as in any struggle. There are no new rules to teach.
- **See:** you lean in with your guard shaking. Each surge is a step, the ground cracking under it. Each of his surges shoves you back, ploughing a furrow. The camera holds you both side-on. **The meeting point is you.**
- **Winning:** you walk 9 body heights in 9 pulses (3 s) if you both keep the beat and you're pushing harder. Your steps count double his surges, as you're starting at the far end, so if you both keep the beat, you arrive on the last pulse. **Reach him and you get a full send from point blank.**
- **Losing:** pushed back past where you started, **you take the beam and you're thrown.**
- **Cost:** guard damage on each pulse, so you can't do it forever. No energy, as in a struggle.
- **His way out:** cut the beam with LT at any time. He's free, you're close, and nobody gets the prize.
- **Which beams:** stage 3 or more and signatures. On a smaller beam, you just lean in, and it's over too soon to matter.
- **Competitively:** it's the only defensive answer that can send him. So it's a real alternative to firing back when you're out of energy, since it costs none.

## 6. The catch

**My pick: yes, and it's the block held on.** The same fresh LB press as the beam hits, and if you keep LB down, you catch it, on one plated forearm or shoulder.

| The beam comes | What happens to you | What it leaves |
| :--- | :--- | :--- |
| **From above** | **You're driven into the ground, still standing.** Feet planted, sinking | A crater under your feet: at maximum, up to 620 across each way and 136 deep |
| **Level, on the ground** | **You're pushed along, still standing.** | A trench under your feet, as long as you slide |
| **Level, in the air** | Pushed back through the air | Nothing, until you hit something. A building breaks around your back |
| **From a slant** | Both | A trench that ends in a bowl |

A quarter of his beam's energy goes into the ground. The harder his beam is than you, the faster you go: `slide = 300 × √(his energy ÷ yours)` a second, from about 150 to about 1,050.

- **The risk: you pay energy every moment you hold it.** 20 a second, rising with his beam against you, up to 60. **If you run out, it breaks you: you take the rest and you're thrown.** So a catch against a much bigger fighter is a real gamble.
- **The ways out**, any time you're holding:
  - **Hold to the end:** he's stuck for 0.5 s, and you're standing in your crater, looking at him. The picture's the reward.
  - **Flick the right stick:** throw it where you aim (a swat, with half his stuck time).
  - **RB + right stick:** fire into it from one hand, and a struggle starts at your hand.
  - **Let go of LB:** it parts around you. It's a block from then on.
- **Why it isn't always best:** you're being pushed toward whatever's behind you, and you're spending energy he's already spent.

**Legal now allows a catch for as long as the beam lasts, up to 3 s.** One arm, shoulder height or lower, no open palm. The sinking is the ground giving way, and never shown as injury.

## 7. Aiming

**My pick: where your thumb is, is where it goes.** You're already holding the stick to charge, so the stick is the aim.

- **While charging,** your arm follows the stick at once, 32 directions, with no delay. You see the aim on your own body and nothing else is drawn.
- **Near him, it locks on.** Within 22° of him the aim sticks to him and follows him as he moves, so a beginner just pushes toward him and it works. There's no such pull toward anything else, and never toward a town.
- **Letting go** reads where the stick was just before your thumb came off. Controls measured it on your own holds: today nearly every beam would fire right, whichever way you held, and their fix brings that to about 4° off. **On.** The aim also ignores about 4° of thumb wobble, so it's steady.
- **Once it's out,** push the stick again to sweep it, at your fighter's own speed. It's rooted fire, so you turn but don't move.
- **Things in the way:** a beam goes through a tower, as you say. The front slows by what it's cutting, the same for anything of that size.

**Straight down from opposite sides of the planet.** Firing into the ground just digs a hole: the beam ends in the ground, at its groove's depth, and you've wasted the energy. So there's no reason to do it. **But** if two human players fire straight down within 2 s of each other, from nearly opposite sides of the world, both get a special voice line and an achievement, once. Nothing else happens. The AI never does it. Narrative writes the line.

## 8. Loupe

**My pick: the moves are for everyone, and the attitude is his. His rule is: Loupe goes forward.** Everyone else flies, and he walks. Everyone else answers a beam, and he takes it personally.

- **Punch up the beam is for everyone,** because it's the swat's gesture aimed at him at your top stage. **Everyone:** top stage only, half the beam on the way, arriving with your charged blow. Grist arrives shoulder first, Bolus bulldozes in slower, and Orza thrusts along the line. **Loupe:** from stage 2, a quarter of the beam, and he lands fist first and full.
- **On the Chin stays his alone.** It's made of Pride, and standing there is who he is. Its poses need redrawing with closed fists, by Legal's ruling, before it can be used.
- **What makes him memorable, as looks with no change to balance:** his dodge reads as a step past you, his knock-backs land him upright and walking, his plates chip off with each volley and stay gone for the round, and his signature is always a walk. **He calls it:** he raises a fist and points his chin at you, and if that blow lands he gets the most Pride a blow can give. It can be hit. That one's for later.

**The other choice:** the punch for Loupe alone. It would be more memorable, but people will press that gesture anyway, and I'd rather it did something.

## UI's questions on stages (`docs/ui/charge-stages.md` section 6)

| Question | Answer |
| :--- | :--- |
| **1. Is a stage a time rung, or energy spent?** | **A time rung, and you pay on release.** You reach stages by holding, on the table above, and a beam's cost is taken when you let go. **The stage stops rising at what you can afford,** with one knock on the pad. So the ladder always tells the truth: stages you can't pay for look different from ones you haven't reached yet. Holding at the top pays 4 energy a second, and if that runs out, the stage steps down, and the ladder shows it |
| **2. Is the count from the tier alone, or also which charge?** | **From your level, tier and power together,** so base at 100% has 3. Take the count when the charge starts, and don't change it mid-hold. **It applies to the right-stick holds:** RB's beam, and the plain hold that's a charged blow, a swat or a punch. **Not the others:** B and Y keep their one flash, and the Driver its three levels, on the existing ring. A signature has no ladder: it always spends your top stage, and your stage count sets its size. **Powering up has no stages** (it's the power number), so no second name is needed |
| **3. Can a hit drop a stage?** | **No. A hit either does nothing to the charge or ends it,** so there's no dropping one at a time. A light doesn't touch it. A medium before 0.5 s, a heavy, a beam or a grab ends it, and your own guard or dodge press does too. All of it's lost, and that's the `lapsed` mark. The only step down is running out of energy (above). Stages are never skipped |
| **4. Is any stage but the top worth holding for?** | **No fixed sweet spot, so the notch goes on the last one.** Every stage is a fair trade of time for energy. For a swat, the stage you need depends on his beam, about half your stages at equal power, and players learn that by feel. I wouldn't draw it |

**UI's foe ladder on his plate is fine by me,** at the edge of the screen, since a charge you can't read can't be answered. It's more on screen than you've wanted so far, so it's on UI's off switch, and yours to judge. The fighter's own glow stays the main read.

## Controls' read on a real pad (`docs/controls/stoke-and-chin.md`)

| Question | Ruling |
| :--- | :--- |
| **Does letting go in a direction work?** | **Yes, with Controls' fix on.** Read as it is today, the direction is wrong in more than half of your holds, as the stick has already sprung back. Read from the last moments before your thumb lifts, it's about 2° off, and 2 of 43 land in the wrong quarter |
| **A hold near a diagonal** | **Within about 15° of a diagonal, it counts as toward or away,** as the fight is side-on and that's how you aim. **Your fighter's pose shows the answer it's about to give,** so you can correct it before you let go |
| **Up and down** | **Untested: you've hardly ever held them.** Controls' drill should have a front coming and a cue for each direction, 30 tries each. It's the same drill as the release window's, so one run answers both |
| **Bolus's pumping** | **Yes, with two conditions.** The input has to count reversals, so a claw grip can't slip a button press in mid-pump. And a plain hold with a timed sputter stays as the assist. It's still behind Loupe in the build order |
| **On the Chin's press** | **A fresh RT press in the answer window is the Chin, at once.** So Loupe can't start his signature in that window. **That costs him nothing:** his signature's volleys couldn't start a struggle anyway, and he fires back with RB + stick. Everyone else is unaffected. A press with RT already held does nothing new |

## The rest of your marks

| | Your mark | Ruling |
| :--- | :--- | :--- |
| **The ground answers** | Cool | Keep. It's the swat down, on the ground |
| **Cover your partner** | Cool | Keep. In 2v2, any answer works for this |
| **The hose** | Doubtful | **Shelved.** Not built, and no time spent on it unless you bring it back |
| **Knock their aim** | Maybe | **Later, on a switch.** Signature charges now have armour, so only a heavy blow can do it |

## Legal's limits (RL-238, `docs/legal/review-log.md`)

**None of it's a no.** It all stays open until it's built and through the look gate, the flash clips in both modes and the held-pose check.

| Move | The limits |
| :--- | :--- |
| **Walking into it** | One guard arm forward, a plated forearm or shoulder. Never an open palm, both hands or arms wide. The beam parts at the plate, with **no rim or ring of light.** A step can crack the ground under the foot, as a small local mark, with no rubble ring or wind around him. **The only light is the struggle's pulse. Nine pulses in 3 s is close to the flash limit,** so it's read on clips, and if a pulse flashes on each step, it's capped. No taunt, zoom or finisher on the loser |
| **The ground answering** | One wall and one burst, local, with one light event and no ring of rubble around him. Aim's the player's. The AI goes by terrain and standing buildings, and never reads people. Nothing's gained for what it hits |
| **Punch up the beam** | **One fist, shoulder or closed edge leads.** Never both hands or an open palm, and nothing above the shoulder until the last 6 ticks. Orza leads with her shoulder or one edge of her hand, never her mantle. Bolus leads with his shoulder, and nothing opens. The beam splits at the body, as a block does. No shouted line or named move. The cost to health stays |
| **The catch** | Up to the beam's length, at most 3 s. One arm, at or below the shoulder. **Never a crouch with clenched fists.** No scream, lightning, rising flame, hair change or flash with a name. The crater's a bowl that digs, with debris thrown along the beam's line, not a rising ring. One light event when it breaks |
| **Loupe's volleys** | **Straight narrow bolts only,** never a sphere, disc, column or spiral. From a closed fist, one hand at a time, **the hands alternating.** No ball in or above a hand. The loaded arm at shoulder height or lower, never both fists together, never a beckon. **No flash per bolt:** a steady glint at the hand. **At most three light events a second,** counting everything on screen, with clips of six in a row by day and by night |
| **He calls it** | One brief gesture at shoulder height, never a beckon. It gets its own look when drawn |
| **Straight down from opposite sides** | **Only a voice line and an achievement.** No planet-splitting picture, cutscene or text about ending the world. Its words celebrate no destruction and name no real place. It's earned by two humans coinciding, never by what the beams hit. Once only |
| **Any moving hold** | Moving doesn't reset the clock on a held pose. The check reads it tick by tick, and a hold that can't stay inside the rules for its length gets shortened |

**One thing this may cost:** the top stage at 2 s and Loupe's walk are both long holds in motion, so if the check shortens them, the ladder or the walk has to change. Six volleys with the flash limit may also need wider spacing.

## What it does to the struggle

Good news: **a risky swat helps.** My worry was that a safe swat would pull skilled players away from struggles, and a miss now costs everything. Walking is itself a struggle, so it counts toward the target of 30 to 60% of signature beams. The block is still free, and it's the one to watch.

## For the builders

| Who | What |
| :--- | :--- |
| **Encounter** | Stages in `data/director/stick.json`: count from level, the six-row ladder. Swat on the release, with the energy test. Walk on the struggle's pulses. Catch with its energy drain |
| **Controls** | The aim: the live arm, the lock-on, reading the stick before the thumb comes off. Claw gate rows for each answer |
| **Combat** | Each fighter's stick signature. The bodies for swat, walk, catch and punch |
| **World** | A crater and a trench made under a standing fighter's feet, as he moves |
| **Rendering and VFX** | The beam that bends or parts at a body comes first. Then the catch's front on a forearm |
| **UI** | The pips in the left panel while holding, and the hints |
| **Narrative** | The straight-down voice line and its achievement |
| **QA** | The stage reached, swat results by energy, walk wins, catch breaks and the struggle's share |
| **Legal** | RL-238 read this page: limits below. Still not asked: Grist's, Orza's and Bolus's stick verbs, the stage ladder, RT and the aim lock-on. **RL-231 and RL-232 still stand** |

## Your calls

1. **The stage ladder:** are 2 to 6 stages, up to 2 s, what you imagined?
2. **The swat:** does the toy feel like the risk you meant? It has the timing window as a number you can change.
3. **RT:** A, B or C, and the power blow.
4. **Each fighter's verb:** holds, flicks, draws, stokes. Which grab you, and is a Loupe signature that isn't a beam all right?
5. **The walk as a struggle:** is that "really cool", or did you picture something else?
6. **The punch:** for everyone, with Loupe the best, or Loupe alone?

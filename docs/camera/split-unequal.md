# Split screen at speed: 70/30 and other ideas, for Orb (Camera, 2026-11-01)

Orb, after the first play (`docs/ep/vision.md`): "the flight definitely feels overtuned, way too fast, and the split-screen taking up half of the screen real estate makes flying at super high speeds uncomfortable. lets workshop ideas to deal with this, I was thinking about something closer to a 70/30 split when your opponent is a CPU".

**This updates `split-vision.md`.** It's for you to mark. The 70/30 is built behind a switch, off, and nobody has played it. The pictures here are mock-ups cut from real frames.

## The short version

**My pick, in order:**
1. **Bring the flight speed down.** That's Game Design's and Simulation's, not the camera's, but nothing else does as much: half the speed is half the rush, in every layout.
2. **70/30 against a CPU,** as you suggested.
3. **More room ahead of you when you're flying fast,** so you see where you're going.
4. **A steadier horizon in fast flight.**

You can already try one comparison today: Settings, "Split screen against the computer", off. That's one camera on you, and a pointer and the map for your rival. **I'd want your hands on 50/50, 70/30 and off, one after the other, because this is about how it feels.**

## What 70/30 looks like

![Today's 50/50 beside a mock-up of 70/30](img/split-unequal/flying-today-and-mock.jpg)

*Left, a real frame today. Right, a mock-up: two real frames from different moments, cut along a new line. In the game your fighter stays in the middle of your own larger pane.*

| Question | My answer |
| :--- | :--- |
| **Who gets the 70%?** | You. Against a CPU, your pane is always the large one |
| **Which side?** | Wherever you are relative to your rival, as today: the panes face each other along the shortest way round. It can be either side of the screen |
| **The line** | Still angled toward the other fighter, as you asked for in 2026-09. It sits about 30% in from the CPU's side |
| **The distance chips** | They already sit either side of the line, so they move with it. The one in the CPU's pane has less room, and it fits in the mock-up's proportions. **UI should check this,** along with the top plate, which nearly fills a 30% pane's width |
| **The CPU's fighter** | Stays centred in the small pane, at the size it has now, so he's just as big in less picture around him |
| **As you close and merge** | The line slides out as the panes open and slides back as they close, with the same ease and no timer of its own. Nothing fades |
| **A slam or a launch shot** | They take the line over from wherever it is, as they do now |

![How the line moves as the panes open and close](img/split-unequal/how-it-eases.jpg)

*A drawing, not a frame: one picture, the line slides out, 70/30, slides back, one picture.*

## Two humans

**Stay even, 50/50, on one screen.** Each pane belongs to somebody, and neither of you should get less.

**On two PCs, each screen is its own,** so each player would get the 70% on their own screen. That's the same camera work as here. It's not built, because two PCs isn't built.

**A CPU fight with nobody playing,** such as the demo, stays even too.

## The numbers: what 70/30 does and doesn't fix

How many times a second the ground crosses your pane, flying flat at a pane's usual size (0.085), whatever the screen's width:

| Flying at | 50% pane today | 70% pane | 30% pane (the CPU's) |
| :--- | :--- | :--- | :--- |
| 5,000 units a second | 6.4 | 4.6 | 10.6 |
| 10,000 | 12.8 | 9.1 | 21.3 |
| 20,000 | 25.5 | 18.2 | 42.5 |

Worked out from the lens, not measured. **So 70/30 cuts the rush by about 30% in your pane, and half the speed cuts it by 50%.** And the CPU's small pane rushes faster, when he's the one flying. I think that's fine, since you're looking at your own, but you may not.

## Where 70/30 could look bad

- **The CPU's windups in a narrow pane.** A beam charging in there is smaller and has less room around it. The new warning that a beam is coming matters more.
- **A beam struggle.** The beams meet at the line, which is now off-centre, so one beam looks much longer. I'd go back to even during a struggle. That's a small change, not built yet. Your call.
- **The line changing sides.** When the two of you pass each other and the panes swap, the line has to cross 40% of the screen. I haven't tested that with 70/30.

## The other ideas

| Idea | What you'd see | Cost | My view |
| :--- | :--- | :--- | :--- |
| **A. More room ahead** | When flying fast you sit in the back third of your pane, not the middle, so what you're flying into is on screen sooner | Small. The pane already leads a little | **Yes.** It helps at any layout, and it's what makes speed readable rather than just fast |
| **B. A steadier horizon** | In fast flight the camera's height moves slowly and smoothly instead of following every rise, so the skyline doesn't bob | Small | **Yes,** after measuring how much it bobs today. I haven't |
| **C. Pull out as you speed up** | Your fighter gets smaller the faster you go, about 0.085 to 0.06 of the screen's height at top speed, and the rush falls by 30% | Small | **Not first.** It works, but you've already said fighters seem too small |
| **D. Less ground rush** | The ground's detail softens as it speeds past, the way building windows already do | Rendering's | **Worth asking,** especially for flying low. Your rule on blur and fades means it must stay crisp, so it's lower contrast and not a blur |
| **E. The CPU's pane shrinks further at speed** | 70/30 at rest, closer to 80/20 while you're flying flat out | Small, on top of 70/30 | **Try it only if 70/30 isn't enough** |
| **F. No second pane at speed** | One camera on you and a pointer to your rival while flying fast, split back when near | Small: the setting exists, it needs a speed rule | **Keep in reserve.** You lose sight of your rival's moves |

## Decided since (the EP, 2026-11-01)

- **A beam struggle goes back to even.** The line eases to the middle over 0.6 s, and back after. Built.
- **More room ahead:** built behind a switch, off. It leads the player's large pane only, up to 0.16 of the width from 6,000 units a second (0.08 today). The CPU's narrow pane has no room for it.
- **The horizon, measured** in 6 AI fights, fast flight only, from a sum on the sim's ground rather than from pictures: it moves about 130 pixels a second at 720p as a median, 420 at the 90th percentile. Over a flight it travels up to 400 pixels, but mostly one way, with about 0.7 reversals a second. So it's a climb or a dive more than a bob, and I'd **hold off** on steadying it until you've played the others.

**A known cost of 70/30.** In 3 real fights your fighter never left your pane. The CPU's fighter can leave his narrow pane for up to 50 ticks, about 0.8 s, when he's flying fast. The chip still points to him. I haven't found the whole cause of that.

## Marks wanted from Orb

1. **70/30 against a CPU:** does it feel better? Is 70 right, or more?
2. **More room ahead:** shall I build it next?

Your three marks in `split-vision.md` are still open too.

## For the team

- **Park:** `pending/swing/swing-share.patch`, after swing-rush-follow. `SplitRig.split_share` (0 is off, 0.7 is this) and `SplitView.set_split_share`, with `render/camera/tests/split_share_check.gd`. No line in `main.gd` yet, so Tools can give it a page word.
- **The check** stages a flight apart and back with the player in either slot and on either side. His pane is 0.71 of the middle row (the line's tilt), each fighter stays in his own pane on all 466 split ticks, the line's biggest step is 0.015 of the width a tick, and two humans stay even.
- **Not done:** no real frames (no captures in this window), no play, the side swap, and flash, per the backburner ruling.

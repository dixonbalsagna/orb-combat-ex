# Orb's page with a pad: what you press and what the pad does (Tools, 2026-11-01)

Built from the live map (`data/input/layouts.json`, the Arena pad) and `docs/controls/right-hand-attacks.md`. Not every number below has been played; the moves are named by what they do.

## From the double-click to a fight

1. Double-click `homework/1 Urgent/Open - playable.cmd`. A window shows the flashing warning; press a key.
2. The browser opens the page. A black screen says **Preparing the graphics**. It took about 45 seconds on the test PC (software drawing); on yours it should be shorter.
3. **Press any button on your pad once**, so the browser notices it.
4. A card shows the flashing warning and your choices. With this page, **Player 1 is already Controller and Intros are off.** Click **I understand, start** with the mouse (the pad can reach it too: D-pad Down eight times, then A).
5. The fight starts within about ten seconds. You are Grist, the left fighter; Loupe is the computer. There is no How to play card and no intro on this page.
6. **Start** on the pad pauses (Resume, How to play, Settings, Main menu, New match).

## The pad in the fight

| Control | What it does |
| :--- | :--- |
| Left stick | fly and move |
| **Right stick** | **strike**: flick it toward Loupe, up, down or away from him: a quick blow. Hold it out: the blow charges through three levels; let the stick go back to rest to throw it |
| **LT** (left trigger) | dodge on a tap; hold to sprint (flat out); tap it with a left-stick flick to slip |
| **LB** (left bumper) | guard; a tap just before a blow lands is a perfect block; LB with a left-stick flick is the brace |
| **LB + LT together** | the vanish (an upgraded dodge) |
| **RB** (right bumper), held | energy: **the right stick becomes a beam** (flick for a quick one, hold to charge, steer while it is out); the face buttons fire blasts |
| **RT** (right trigger), held | power: charge up; the right stick does nothing while it is held |
| **LT + RT** held half a second | transform |
| **X** (west) | light blow |
| **Y** (north) | heavy blow (hold it to charge) |
| **B** (east) | signature move (needs the ki bar, 45) |
| **A** (south) | context: a grab, or whatever the moment offers |
| **RT + X / Y / A** | the specials |
| **D-pad** | the same as the right stick, if you prefer it (a setting) |
| **Back** | show or hide the button hints |
| **Start** | pause |

The kick and the takeoff: **flat out** (hold LT with the stick over) leaves at 80% of top speed on the first tick, then top speed within a fraction of a second. A hard flip of the left stick at speed brakes, plants and kicks the other way. Try other values with the page's printed addresses.

## A first minute to try

1. Fly at Loupe with the left stick and **LT held**.
2. Flick the **right stick** at him: a quick strike. Do it again; hold it out and let go for a charged one.
3. Tap **X** and **Y** for light and heavy; **A** next to him for a grab.
4. Hold **RB** and flick the right stick for a beam. **B** is the signature once the bar is full.
5. When he swings, tap **LB** just before it lands (perfect block) or **LT** to dodge.

## Known rough edges (for you to judge, not to hide)

- **A fight can run on after the first fighter's health reaches 0** (it did in my test, for 2,600 ticks, with no KO card): the finisher decides it, and the computer did not land one. Game Design and Encounter are looking at it.
- **With buildings everywhere on**, the camera sometimes sits behind a huge wall (Camera and Rendering have it).
- **A beam clash has not been seen in any of my reels**, so the new clash look is unseen by me.

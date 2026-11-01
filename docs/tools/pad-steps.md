# Orb's page with a pad: what you press and what the pad does (Tools, 2026-11-01)

Built from the live map (`data/input/layouts.json`, the Arena pad) and `docs/controls/right-hand-attacks.md`, then checked by Controls against its audit of the pad in real fights (`docs/controls/controls-audit.md`) and Game Design's first-press ruling (`docs/design/pad-first-press.md`). **Only what answers in a fight is listed.** Nobody has played this page by hand yet; the moves are named by what they do.

## From the double-click to a fight

1. Double-click `homework/1 Urgent/Open - playable.cmd`. A window shows the flashing warning; press a key.
2. The browser opens the page. A black screen says **Preparing the graphics**. It took about 45 seconds on the test PC (software drawing); on yours it should be shorter.
3. **Press any button on your pad once**, so the browser notices it. If the pad isn't seen, press any button on it again. **If your browser is Opera GX, its limiter (GX Control) can slow a tab: turn it off for this.**
4. A card shows the flashing warning and your choices. With this page, **Player 1 is already Controller and Intros are off.** Click **I understand, start** with the mouse (the pad can reach it too: D-pad Down eight times, then A).
5. The fight starts within about ten seconds. You are Grist, the left fighter; Loupe is the computer. There is no How to play card and no intro on this page.
6. **Start** on the pad pauses (Resume, How to play, Settings, Main menu, New match).

## The pad in the fight

| Control | What it does |
| :--- | :--- |
| Left stick | fly and move |
| **Right stick** | **strike**: flick it toward Loupe, up, down or away from him: a quick blow that stuns. Hold it out: the blow charges through three levels (the pad ticks at each); let the stick go back to rest to throw it. **The direction matters on this page** (Combat's table, Encounter's rules; nobody has played it by hand yet): up floats him, down puts him on the floor (in the air it spikes him down), toward drives him back, away carries you past him to his back. A light that lands on a quick flick no longer ends it, so the direction shows |
| **LT** (left trigger) | dodge on a tap; tap it with the left stick pushed and you dodge that way; hold to sprint (flat out) |
| **LB** (left bumper) | guard (held, it roughly halves the damage you take); a tap just before a blow lands is a perfect block |
| **RB** (right bumper), held | energy: **the right stick fires energy**: flick for a quick blast, hold it out to charge and let go to fire the beam; X and Y fire shots and blasts; **RB + B is the Driver** (see below; if this page was built without it, RB + B is a blast like Y) |
| **RT** (right trigger), held | power: charge up; the right stick does nothing while it is held. **RT + B is the signature beam** (see B) |
| **X** (west) | light blow |
| **Y** (north) | heavy blow (hold it to charge) |
| **B** (east) | **on its own, your biggest blow** (a heavy hit; from range it lunges in first; very far away, past about 12 body heights, a tap is only a taunt). **The signature beam is RT + B only** (it costs 45 ki, so the bar must be at least that): about 150 damage. If both of you fire one at once they clash. B with LB, LT or RB held is not the signature: it is the heavy of that stance, like Y (so guarding or dodging and pressing B never fires a beam by accident) |
| **A** (south) | **close up, a grab** (a brawl starts with the catch as its first blow); **in a brawl, the catch**; **far away, a taunt**; and nothing, with a short empty-button buzz, when you cannot act or he is in the air or down. (The grapple is on in this page) |
| **D-pad** | nothing, unless you turn on the setting that makes it the right stick |
| **Back** | show or hide the button hints |
| **Start** | pause |

**The Driver (RB + B)**, if this page has it: hold RB and press B. A tap throws a straight heavy shot that knocks him back (10 ki). Hold B and it gathers through three levels, at about half a second, nine tenths of a second and 1.4 seconds (14, 18 and 24 ki): level 3 is a full send across the world and breaks a guard. Let go to fire. Holding level 3 drains 4 ki a second. A guard or a dodge press drops it for nothing; if you cannot pay, you get a refusal buzz. It never fires by itself, and only you have it (the computer does not).

The kick and the takeoff: **flat out** (hold LT with the stick over) leaves at 80% of top speed on the first tick, then top speed within a fraction of a second. A hard flip of the left stick at speed brakes, plants and kicks the other way. Try other values with the page's printed addresses.

## A first minute to try

1. Fly at Loupe: push the left stick toward him and **hold LT**. **The kick is on in this page** (its data switch is on, whatever words the address carries): from a standstill you leave at about 90% of top speed on the very first tick, which is the instant takeoff. Flip the left stick the other way at speed and he brakes, plants and kicks off the other way. To feel the difference, open the printed address with &kick=off beside it.
2. Flick the **right stick** at him: a quick strike. Do it again; hold it out and let go for a charged one.
3. Tap **X** and **Y** for light and heavy; **A** next to him for a grab.
4. Hold **RB** and flick the right stick for a blast; hold the stick out and let go for the beam. For the **signature beam**, hold **RT** and press **B** with the bar full (45 ki); B alone only throws the big blow. If Loupe fires his at the same moment, the two beams clash.
5. When he swings, tap **LB** just before it lands (perfect block) or **LT** to dodge.
6. **To try the meteor** (Encounter; a stand-in rule for trying the move, not the final rule): both fighters must be at tier 4, which the full-power shortcut gives you at once, so open **Open - full power** (the address ends in &peak=1). Then **fly next to Loupe, hold B until the flash, and let go.** The first big launch of the match is then the meteor: he goes up one long curve and comes down as it. (In this page the match's first one is always the meteor; without that rule it needs him stunned as it lands.)

## Known rough edges (for you to judge, not to hide)

- **A fight can run on after the first fighter's health reaches 0** (it did in my test, for 2,600 ticks, with no KO card): the finisher decides it, and the computer did not land one. Game Design and Encounter are looking at it.
- **Buildings and the camera:** in moving-player reels of 3,600 and 7,200 ticks neither fighter stood behind a building for even one second (the longest run was 10 ticks), and no single flat face filled more than 30% of a frame. The towns on the far hills may still look like they hang over the slope (Rendering has it).
- **The clash:** with both fighters firing RT + B, a clash lands (tick 248 in my reel), and a player who presses RT + B within about 0.3 s of the computer's beam leaving its hand gets one too; later than that it is a plain hit.

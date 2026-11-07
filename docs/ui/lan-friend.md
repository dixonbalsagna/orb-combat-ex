# What the screen shows for a LAN friend (UI & UX, paper, 2026-11-01)

Orb: versus on the globe, the structure tuned for co-op over a local network, and a split-screen vision (`docs/ep/vision.md`, last paragraphs). Camera's side is `docs/camera/two-v-two.md`: on each PC one rig frames a pair, **you and whoever you have focused**; a teammate is drawn in the world when they are in frame, and off frame **the edge HUD's distance chip** shows them; no pane or strip of their own; a partner's far meteor does not take your camera. This page is what UI adds on top, for two cases: a friend on the other side (1v1 over the network) and the 2v2 case with a partner and two rivals. Paper only; nothing is built. Camera's split vision is still being written; where it says something else, it wins.

## 1. The rules this keeps
- **Nothing on, over or between the fighters.** Everything below is at the screen's edge, on a plate, on the map, or in a line of words.
- **Each person's screen is their own.** It is view only, so two screens can differ with no cost to the match. Everything is drawn for the local player and their focus.
- **A shape for each person, never colour alone.** Four bodies need four marks. The first fighter keeps a circle and the second a diamond (as the planet map and the plates use today). A partner gets a square and the other rival a triangle. Each mark also carries the fighter's lane colour and name on the plate.
- **Plain words:** "Your friend", the fighter's name, "far away", "left the match". No ping numbers, no team words.

## 2. The friend on the other side (1v1)
| What | Where | How |
| :-- | :-- | :-- |
| The friend's fighter | In the world, at their real place | Camera frames you and them; nothing from UI |
| Their plate | The far top corner, as the computer's is today, with the tag **YOU** for the local player and **FRIEND** for them (today it says CPU); P1 and P2 are not used on a network |
| Off frame | The edge distance chip, as for the rival today | The pointer chip UI already draws (edge arrow, small), with the friend's mark and name |
| The map | The planet globe in the ring's slot (docs/ui/planet-map.md): your trail and both of you | One mark for each: you (circle), them (diamond), the one point when together |
| Trouble on the line | One line of words at the edge: "Waiting for your friend", then "Your friend left" | Only when Netcode says the line stalled or dropped; a pause, never a fade; the match is held, not lost |
| A rematch | The match-over card: Play again, which both must press | The card's first line says who is asked: "Waiting for your friend" after you press it |

## 3. The 2v2 case (a partner and two rivals)
| What | Where | How |
| :-- | :-- | :-- |
| The partner, in frame | In the world | Camera draws them as they are; no mark over them (the rule) |
| The partner, off frame | The edge distance chip, with the square mark and their name | The same chip as the rival's; the chip's colour is their lane colour; two chips at one edge stack by distance so they never overlap |
| The two rivals | The plate shows your **focus** rival: name, Charge, power, tag. The other rival is a **small second plate** under it, name and a short "nearly beaten" mark only | The D-pad's focus switch (Controls and Camera): the plate that is in focus has the bright edge; switching eases (Camera's 0.5 s blend), the plates swap their edges at once, no fade |
| Who focuses whom | One line, small, under the plate: "Focus: <name>". Changes when you switch | A cut of words, no animation |
| The map | The globe with four marks: you (circle), your focus (diamond), your partner (square), the other rival (triangle), and **your own trail only** (each player has their own record of the planet, as Orb asked) | The trail is yours; the others show as marks only |
| A partner's far meteor launch | One line at the edge, **not** a camera move: "<Name> is launched" with the direction mark, only in a calm moment; the sky trail and the landing shake are VFX's and Audio's | Camera's rule: your frame stays on your own fight |
| A beam fired at your partner | Nothing to you (the beam answer alert is for its own target only) | |
| The result | The card names the winning pair ("Grist and Loupe win") and has the same Play again | Both must press it, and the card says who is waited for |

## 4. The pad's part (no mouse, no dead end)
- **Menus.** The D-pad and now the left stick step the cards; Up from the top of the start menu reaches Start in one press; A accepts; B or Start goes back; the match-over card's Back goes to Play again (the second-match fixes of `hud-spec.md` section 76).
- **Starting a network match.** One new row pair on the start menu, only when two are not on this PC: **Play with a friend** (Host or Join). Host shows a short code and "Waiting for your friend"; Join lists the hosts the network has found, picked with the D-pad, and a typed code is the last resort (the pad's on-screen keys are not a good way to type, so discovery comes first: Netcode's). The same card is the way back after a drop.
- **During the match.** The focus switch is a D-pad press in a fight that has two rivals (Controls', ruled with Camera); in a 1v1 the D-pad does what it does today.

## 5. What each part needs, and who
| Piece | Whose | Size |
| :-- | :-- | :-- |
| Plates for a friend, the FRIEND tag, the second small plate, the focus line, the four marks on the chip and the globe | UI | about two days, with the checks (geometry at the supported sizes, no overlap of two chips, every mark by shape, the words fit at every Text size) |
| A pair view with a focus, and the events filtered to your pair | Camera, Simulation | theirs; UI reads the pair through the same anchors |
| Network states: connected, stalled, dropped, who has pressed Play again | Netcode, as events (`net_state`, `rematch_wait`) | small; UI draws words from them |
| Host and Join screens, discovery | Netcode with UI | UI draws the card; Netcode supplies the list |
| The map's four marks and each player's own trail | UI (the globe widget already takes a list of positions) | small, after the swing feed |

## 6. Open questions (for Orb, plain)
1. Should your partner always show as a small mark on the map, or only when they are off screen?
2. Should the second rival's small plate show at all, or only the one you are focused on?
3. When the friend leaves, should the match wait (and say so) or hand their fighter to the computer?

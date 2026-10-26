# The rally's camera (parked)

Camera, 2026-10-25. **The frame is Game Design's** rulings 23d (`docs/design/rulings-2026-10-23d.md`): a daze, the sell, a rally of links that bounce the body around the planet, and the turn. **Combat's kits** (`docs/combat/pending/rally/`) give each fighter's own links. Encounter is building the rally behind `rally.enabled`. This is the camera's part: built, parked, and inert until Encounter's cues come.

**Orb's rules that bind every move here:**
- Every camera move is eased. A cut needs a cinematography reason, written in director.md §11.
- Nothing is drawn over the fighters: no fades, dissolves, blur or markers (ADR 0010).

The patch, `director-18-rally-framing.patch`, applies after director-17 (on bf34d1d4 with the half-plane patch, 16 and 17). The numbers are its data: `CamParams.SELL_*` and `CamParams.RALLY_*`.

## 1. What the camera reads (Encounter's cues: please confirm or rename)

All four are `cue` events, Encounter's channel:

| Cue | Fields | When |
| :--- | :--- | :--- |
| `sell` | actor = the attacker, target = the dazed fighter, amount = 1 for a medium, 2 for a heavy | Each sold blow lands (23d item 4) |
| `rally_link` | actor = the attacker, target = the body, text = the link's base kind (`chase`, `overtake`, `spike`, `bank`, `energy`, `world`, `grab`), n = the link's index | Each link starts, including the opening send |
| `rally_turn` | actor = the new attacker, target = the new body | The counter-rush lands on the chaser in the air (item 10) |
| `rally_end` | actor, text = the reason | The rally ends (item 11). Optional: the camera also ends it 0.6 s after both are out of flight with no link |

Without the cues nothing changes. The camera digests of six scenes are byte-identical with the patch and without it.

## 2. The shots, beat by beat

| Beat | The camera | Why, and its limits |
| :--- | :--- | :--- |
| **The daze** | Nothing of its own. | It reads on the body (23d item 2), never with a marker. |
| **A sold blow** | The view pushes in 3.5% (a heavy 4.9%): up in 7 frames with a soft landing, held 0.4 s after each sold blow so the push stays in through two or three blows. Each blow adds a 12-frame eased punch of 1.2%. A blow landing while an earlier push lets go rises from where the push is, with no step. | Weight without slowing anything beyond the sim's hit-stop (Combat §3). Research's impact push: in over 5 to 10 frames, back over 15 to 25. Reduced motion: none. |
| **The send that opens the rally** | The launch shot follows the sent body, as any launch does (step 4). | |
| **Each link** | The launch shot **persists** from link to link: no layout decision at each landing, so a rally is one continuous shot. | It ends 0.6 s after both are out of flight with no link (the ruling's 20 ticks and a margin), or at `rally_end`. |
| **The chaser** | The shot takes in the chaser when both fit with each fighter at least 0.06 of the height (43 px at 720p): the pair within 0.3 of the width and 0.35 of the height, eased in between. A chaser further away leaves the body at his own size. | The chase, the overtake and the bank read as two bodies, not one. |
| **Overtake, spike** | The body's place on the screen moves on a critically damped spring (ω 8 a second, settled in about 0.6 s). An overtake's reversal swings the lead room to the new side, eased at both ends. A spike, falling faster than 2,500 u/s, sits higher (0.45 of the height), with the ground he is driven into below him. | The old anchor eased only exponentially, which starts at full speed. |
| **Bank, world link, energy** | The follow, the two-shot and the existing shots: a building smash or the stage dolly, the beam framing. | No new cut. |
| **A grab in flight** (the haul, the bind, the slam, the reel) | The shot's size is held from the grab to the next send. | Legal e12 and ln06: nothing said, slowed, zoomed or finished over a fighter held in the air. |
| **The turn** | The shot moves to the new body from what is on the screen: his place there and the zoom drawn. It then eases to its trailing frame. **No cut.** | They are together at the turn, since his counter-rush lands on the chaser, so nothing jumps. If a pane is still mid-takeover, his send starts its own launch shot as any send does. |
| **A meet** (both arrive together) | The existing clash and meet framing. | |

## 3. Proof (scratch tree: bf34d1d4's camera with the half-plane patch, 16, 17 and 18)

New split_sweep rows:
- `sell push`: three sold heavies 20 ticks apart. Peak x1.062; the push holds between blows, and only each blow's own punch eases off (0.013); back to x1.000; no cut.
- `rally follow` and `rally turn`: a body thrown at 5,000 u/s with the chaser 600 units behind, a 15-tick lie, then an overtake or the turn. Each is compared with the same flights with the rally framing off:

  | Row | Cuts (with / without) | Body off-screen ticks | Chaser off-screen ticks |
  | :--- | :--- | :--- | :--- |
  | follow | 3 / 3 | 34 / 48 | 15 / 28 |
  | turn | 1 / 4 | 57 / 65 | 15 / 28 |

  The shot holds over the lie, the turn moves it with no cut, and it ends after the rally. The cuts and off-screen ticks left are the row's one-tick throw from rest under the travel budget, which the sweep runs on and the game ships off.
- `rally grab holds the size`: the size target stays within 1% while the chaser closes on a held body.

Also run: the 18 headless render checks, determinism plain and --intro, and the digests (identical: the cues don't exist yet).

**No GIF yet:** there is no rally in the sim to capture. When Encounter's rally runs behind `rally.enabled`, the clips are a daze, the sell and a four-link rally with a turn (23d's prototype clip).

## 4. Asks

- **Encounter:** emit the four cues in §1, or tell Camera its names. Give `rally_link` the base kind in `text`, so grabs hold the size.
- **Animation:** the sell's larger reactions are yours. The camera's push is sized to sit under them, not to replace them.

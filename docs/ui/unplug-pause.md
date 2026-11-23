# The unplug pause (path-to-alpha job 14, decision 20, A-CONTROLS-03, X-07)

When the controller a person is playing on drops out in the middle of a match, the game pauses and says so. When a controller comes back, the match carries on.

## What the player sees

The pause card opens (the same card as P or a pad's Start) with one line on it:

| Who | The line |
| :--- | :--- |
| One person plays | Controller disconnected, reconnect to carry on |
| Two people, player 1's controller | Player 1's controller disconnected, reconnect to carry on |
| Two people, player 2's controller | Player 2's controller disconnected, reconnect to carry on |
| Both controllers | Both controllers disconnected, reconnect to carry on |
| The controller is back | Controller connected, press any button on it to carry on |

The words are in `ui/data/terms.json` (`prompt.pad_dropped`, `_p1`, `_p2`, `_both`, and `prompt.pad_back`). The line is the chip above the match facts on the Rail card, and the first foot line on the older card. It takes the place of the "press any button to join" line while it shows. Resume is lit, so a player whose controller is dead can press Enter or Esc on the keyboard and carry on. Nothing fades or dissolves in: the line is on the card from the first frame the card is, and is gone the frame the card closes.

## What brings the match back

- A controller plugged in (any controller; the host tells the HUD for each). With two drops on screen, the first plug-in takes one name off the line. When the last one is back the card STAYS UP and the line changes to "Controller connected, press any button on it to carry on". The match does not go on until the returning controller has pressed a button and holds a slot again, so nobody plays a moment against the computer.
- That first press goes to the input hub (the host forwards it, in `_pad_event`, because the card is open and the hub never hears a card's presses), which gives the controller its slot; then the card closes as a Resume. A press from a pad that already holds a slot is the card's, as for any pause.
- Resume by hand (Enter on Resume, Esc, P, a pad's Start) at any time, also while the card waits for the pad. The line goes with the card, so the next pause does not carry it. The pad then joins on its own next press, as it does today.
- A card the player had opened themselves, or one with Settings, a question or another panel on it, stays open when the controller returns, and its line goes. It does not wait for a press.

Where the controller goes back to: the input hub already hands player 2's slot to the computer, and player 1's to the keyboard, on a drop (`sim/input/hub.gd` `pad_disconnected`). On the pad's first press it takes a free slot again (`hub_test`). Paused, the host runs no tick, so two things the tick does are done by the host's pad handler at the moment: `host.take_players()` (the computer takes player 2's slot at the drop, the returning player joins at the press) and the hub's `set_humans` (who is human), because a slot the hub still thinks is human would be handed to the returning pad without a join being queued, and the next tick would free it again (found in the probe: player 2's pad pressed and was left as the computer). These are the same calls the pause menu's "Hand player two back" makes.

## What does not pause

- A controller nobody was playing on (a third pad, or one that never joined).
- The start menu, the flashing-effects warning, the loading screen, and a finished match.
- The greybox HUD (F2), which has its own plain pause.
- Online, replays and recordings: the pause is the host's `paused` flag, which stops the loop that feeds the sim and writes nothing to it. The HUD never touches the sim (`pad_dropped` sets HUD fields and emits `pause_menu_opened`, as P does). The LAN and the replay readers do not use the HUD.

## Hooks

- `UiHud.pad_dropped(slots: Array)`: the players (0 and 1) the dropped controller carried. The host calls it BEFORE the hub lets the slot go.
- `UiHud.pad_returned()`: a controller was plugged in.
- `UiHud.unplug_waiting()`: the card waits for the returning controller's first press. `UiHud.pad_claimed()`: that press was given to the hub; the card closes.
- `UiHud.unplug_notice()`: the line, or "".
- `render/core/main.gd` `_on_joy_connection` and `_pad_event` make the calls (Rendering's file: a grant patch).

## Checks

`ui/tools/hud_check.gd` `_unplug_rules`: one person; the same drop twice; the controller back and the wait for its press; going again before the press; Resume by hand (also while waiting); a card the player opened; an empty list; the match over; the start menu; two people (names, the slot handed to the computer, one of two back, both back); and the longest line's fit at five sizes, Rail on and off, with the join and save lines.

Pictures: the demo scene takes `--unplug` (the one person, the plain solo line; a bare flag), `--unplug=2 --p2` (player two) and `--unplug=both --p2`, and `--unplugback` with any of them for the line that waits for a press.

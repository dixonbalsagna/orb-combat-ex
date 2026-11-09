# Report this: one press saves a report in a LAN match, and "Save this match" (UI & UX, 2026-11-08; the EP's brief from Orb's overnight order: "ensure the next LAN play-test has all the tools necessary for reporting issues"; the shape agreed with Netcode through the EP)

**Status: built and parked** (docs/ui/pending/report-this/). The UI half is done and tested. The host's half is one hook (section 4), which Netcode's `host.lan.report` fills.

## 1. The problem it solves

In a LAN match nobody can stop to write a report: the other person keeps playing. So there is **one press that saves a report right now, with no menu and no pause**, and a fuller save (tags and a note) on the pause screen, where a pause already holds both PCs. The existing "Send feedback" panel (docs/ui/hud-spec.md section 20) is where the tags and the note are written.

## 2. The one press (during the fight)

| Input | Does |
| :--- | :--- |
| **F9** (keyboard) | Saves a report now |
| **View and RB together** (a pad) | The same. Either order; View alone or RB alone does nothing |

- It calls the host's hook with empty tags and an empty note: `lan_report_fn("", "")`, which is `host.lan.report("", "")`. The hook answers the file name it wrote (or nothing if it could not).
- **The confirmation is one short line at the edge**, in the legend's teaching row (the same row that carries "Hold for a beam" and the refusal words), for 3.5 s, never over a fighter, no fade: **"Report saved: saved/report-….json"**, or "Could not save the report" when the host answers nothing.
- **One a second.** A held chord or a second press inside a second does not save twice.
- **Never pauses and never writes the sim.** Not for a computer, not while a screen is open or a planet is loading, not with the switch off.
- **Who.** A pad's report belongs to the player that pad drives (`pad_slot_fn`); the keyboard's to the first person.
- **How a tester learns it.** The first two matches, six seconds in, the legend says "Press F9 to report a problem" (keyboard) or "Press View + RB to report a problem" (a pad). It does not repeat.
- **Without a LAN host** (the web page, a solo desktop build): the web page downloads the report file to the player's Downloads folder ("Report saved to your Downloads folder"); anything else says "This build can't save a report yet". It never says "saved" when nothing was.
- **Note on the chord:** RB is also a fighting button (the beam's hold, a flick), so pressing RB for the chord reaches the fight as RB does. The report is saved at the second press; the fight does not stop.
- **Switch:** `report_this` in ui/data/features.json (on).

## 3. Saving with tags and a note (the pause screen, where a pause holds both PCs)

- **The feedback panel gains SAVE REPORT** (on a LAN build only, when the host has set the hook; otherwise the panel is as it was). It calls `lan_report_fn(tags, note)`: the ticked tags as their ids joined by commas (`bug,confusing`; the tags are Bug, Felt unfair, Confusing, Loved it) and the note box's text. It then shows the panel's second state: "Report saved: <file>" and "Saved reports go in the 'saved' folder beside the game."
- **On a LAN build the panel does not offer SEND** (the public GitHub issue link): reports go to the private saved folder instead.
- **The pause screen says where saves go** (LAN build only): one line under the buttons, "Saved reports go in the 'saved' folder beside the game."
- **Save this match** is a new entry on the match-over card (Play again, Save this match, Main menu, Send feedback), switch `save_match` (on). On a LAN build it saves through the same hook (empty tags, the note from the panel if any); on the web page it downloads `orb-combat-match-<seed>.json`; with neither it says "This build can't save a match file yet". The card says what happened for eight seconds, in the same line as the pause screen's foot.

## 4. What the host sets (for Netcode, through the EP)

```gdscript
ui_hud.lan_report_fn = func(tags: String, note: String) -> String:
	return host.lan.report(tags, note)   # the file name written, "" on failure
```
One line where the HUD's other hooks are set (render/core/main.gd, a grant). With it unset every LAN-only piece is hidden or says it cannot, so the UI patch is safe to land first.

**The web page's record** (`UiHud.match_record()`, also what a host may call): `{schema "orb-combat-match-record/1", saved_at (unix s), build {commit, date}, seed, setup, match_time (s), over, winner, settings (one line), note}`. A LAN host writes its own record in `host.lan.report`; the UI never shapes it.

## 5. Tests

`_report_this_rules` in hud_check: F9 with no hook says it cannot; with a hook it saves with empty tags and note, says "Report saved: <file>", does not save twice inside a second, and says "Could not save the report" on an empty answer; View and RB together save, either alone does not; not for the computer, not with a screen open, not with the switch off; the first matches say how to report; the feedback panel has SAVE REPORT only with the hook, hands the host the ticked tag ids and the note, then shows where it saved, and BACK clears it; the pause screen says where saved reports go only on a LAN build; the match-over card lists Save this match and says what happened (the hook's file, or "can't"), and it goes after a few seconds; the LAN panel fits wherever today's does and its saved state, the pause card with its foot lines and the match-over card with four buttons and a status fit at nine sizes, touch off and on. Negative controls: with the key's branch and the save entry removed the checks fail (tried).

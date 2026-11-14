# Report this: one press saves a report in a LAN match, SAVE REPORT with tags and a note, where saves go, Save this match, and four more refusal words (parked, not committed)

`docs/ui/pending/report-this/report-this.patch` (sha1 95274122606f; 12 files). Cut on HEAD f24029fb and tested on it; applies clean. The accounts are **docs/ui/lan-report.md** (the shape agreed with Netcode through the EP) and **docs/ui/menus-modern.md** (the design pass, no code), both new files already in the working tree, so they are not in the patch.

**Apply:** from the repo root, `git -c core.autocrlf=false apply docs/ui/pending/report-this/report-this.patch`. It carries the regenerated strings.md (a large generated diff: new lines re-batch the surface) and the pseudo-locale terms.json (new lines only; `pseudo --check` current).

## What it does
1. **The one press** (F9, or View and RB together on a pad, switch `report_this`): calls `lan_report_fn("", "")` mid-fight, no pause, and says "Report saved: <file>" (or "Could not save the report") in the legend's teaching row at the edge for 3.5 s; one a second; never for a computer or with a screen open. The first two matches say how ("Press F9 to report a problem" / "Press View + RB to report a problem"). Without a host hook the web page downloads the file, anything else says "This build can't save a report yet".
2. **SAVE REPORT** in the feedback panel, on a LAN build only (hook set): calls `lan_report_fn(tags joined by commas, note)`, then the panel says "Report saved: <file>" and where reports go. On a LAN build the panel does not offer SEND (the public issue link).
3. **Where saves go:** the pause screen says "Saved reports go in the 'saved' folder beside the game." on a LAN build.
4. **Save this match** on the match-over card (switch `save_match`): the same hook on a LAN build, a download on the web page, else it says plainly it cannot. The card widens to fit a long file name (and the fit check now catches a line that would spill over the card's edge).
5. **Words for four more refusal reasons:** `charging` "Charging" (RT held, a right-stick push) and `warding` "Warding" (LB and RB held), from Controls' inert-knock park, joining the nine from before.

## The host's one line (coordinate through the EP; Netcode's `host.lan.report` does not exist yet, so there is no grant patch)
```gdscript
ui_hud.lan_report_fn = func(tags: String, note: String) -> String:
	return host.lan.report(tags, note)   # the file name written, "" on failure
```
Where the HUD's other hooks are set (render/core/main.gd). Unset, every LAN-only piece is hidden or says it cannot, so this patch is safe to land first.

## Gate
The full hud_check on HEAD plus this patch: **7783 checks, 0 failed** (log in `docs/ui/runs/f24029fb/`). New: `_report_this_rules` (9 checks) and the two words in `_refusal_reason_words_rules`. Negative controls (the words check with a word removed; the earlier marking design's removal) failed as they should. The older rules pin the two new switches off in `_live_on()`, as they do for the other features, because the first-matches line and the extra card entry would change what they look at.
- **One unexplained failure** appeared in one of four full runs on the way (the beam teach rule "a flick with RB says Hold for a beam the first three times"); it did not repeat in isolation, in order after my rule, or in the next two full runs (both 7783/0, the last on the exact patch files). I could not find a cause; treat as a possible flake of that rule and tell me if it shows in yours.
- Not run: the render gates (UI only; nothing is drawn over a fighter).

## Pictures (the web build of the demo through tools/machine/capture.mjs, 1280 by 720; `docs/ui/runs/397a7adf/report/`)
`report-f9` (the legend row after F9; the demo's own FEED chip sits over its left end, which the real game does not have), `panel-save` (SAVE REPORT beside COPY REPORT and CLOSE, no SEND), `panel-saved` (the second state), `pause-where` (the foot line), `over-saved` (the card after Save this match, wide enough for the file name), `over-nolan` (the card with no host). The design pass's stills are in `docs/ui/runs/397a7adf/menus/`.

## Not done
The menus are design only until Orb picks (docs/ui/menus-modern.md). A per-mark note list was dropped when the shape was agreed (one press, no marks). The B-and-the-signature words are listed in docs/ui/b-and-the-signature.md, not changed.

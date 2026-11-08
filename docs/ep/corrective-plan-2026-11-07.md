# Plan for the corrective directive of 2026-11-07

The EP's reply to `audit/2026-11-07/corrective-directive.md`: an owner and an order for each of the 27 CDs. As each CD closes, its commit id goes in the last column.

**Order:** wave 1 is the time-critical items, before 2026-11-15. Wave 2 comes before the next public pin. Wave 3 comes before any store or internet release. "Ongoing" items are process changes that start now.

| CD | Wave | Owner | First step | Orb decides? | Closed (commit) |
| :--- | :---: | :--- | :--- | :---: | :--- |
| 01 CI running again; a separate workflow-lint workflow; run check in the landing steps | 1 | Tools (EP adds the playbook step) | Quote the four step names, remove the duplicated steps, add the lint workflow, test it on a broken branch | No | |
| 02 Take-down with no game job; manual unpublish written down; a contact route | 1 | Tools; Legal for the contact wording | A manual-dispatch offline-notice workflow, plus the fallback steps in site-interim.md | No | |
| 03 The public test build decision goes back to Orb | 1 | EP puts it to Orb; Tools and Legal act on the answer | One question with one page of facts (`homework/1 Urgent/0 Decide - the public test build (2 min).md`). Until Orb answers: run the nightly on 257a766c, or take /play/ down by hand on Orb's word | **Yes** | Orb delegated to the EP (vision.md); /play/ down 38f4f5e6 + takedown run 42430593567; RL-161 row and nightly still owed |
| 04 Flash limiter against what players see (SCROLL_MAX_REDUCED, hard cuts ask the register) | 2 | Camera; Rendering and VFX for the register | Restore 0.03 or justify it with a saved reading; route the hard cuts through the register with a negative control | No | |
| 05 The villain feeding on civilian deaths | 2 | Game Design, World, Simulation, after Orb's ruling | Put the ruling to Orb (this also lifts the RL-247 hold for this one item); remove the casualty source and the 0.09 line; add a kill() check | **Yes** | |
| 06 A trademark search before any store page | 3 | Legal (counsel); Orb (spend) | Put the spend to Orb when a store page is planned; keep "(working title)" | **Yes** | |
| 07 Personal details in the public repo | 1 | EP asks Orb; Tools replaces the paths | Ask Orb; the disclosure README is already redacted (d552ac9e) | **Yes** | disclosure README redacted d552ac9e; Orb's answer owed |
| 08 Make the public text true (README, CLAUDE.md, /about/, the pin's notice) | 1 | Tools; Legal for wording; EP for CLAUDE.md | Fix README.md:7 and :9, the CLAUDE.md "open source" line and the /about/ engine line; ship the strings-only child or move the pin | No | |
| 09 Repair the flash measurement chain (wcag.js tie, signature-gate wording, scheduled nightly with an alarm, supersede d3f1ca0e, night-sky clip, outside-analyser calibration before store) | 2, with calibration in 3 | Tools; Accessibility | Sub-items one commit each; the self-test fails on the old tie code | No (Orb sets the take-down line only if not 3) | |
| 10 Harden the LAN link (delay cap, slot and input validation, a dropped-PC notice, the dropped seat handled); DTLS before internet | 2, DTLS in 3 | Netcode | Fold into the parked lan-n4 work with negative controls | No | |
| 11 Secret scanning, push protection, branch protection | 1 | EP, with Orb's approval of repo settings | Ask Orb; then enable and record | **Yes** | |
| 12 Desktop workflows can't publish an unlocked build | 2 | Tools; Performance & Platform | Fold linux-export into desktop-builds with the lock; set `shell: bash` on the tee'd steps | No | |
| 13 One store-readiness list with owners | 3 | Legal; Art, Audio, Performance & Platform | Rebuild pre-store-checklist.md with owners and status | Rating target: **Yes** | |
| 14 Accessibility (cue captions, Hit pause wired or removed, brace_key on pads, ship main's fixes with the next pin) | 2 | UI; Accessibility, Controls, Audio | hud_check covers cue captions; no option without a consumer | No | |
| 15 Pose and look rules move to a creative rulebook | 2 | Legal with Art and Animation | Re-tag the rows; change originality-rules.md:70 | No | |
| 16 Close the stale rows; commit RL-247 or remove citations to it; RL-248 to 255 back in the table | 2 | Legal; QA; Netcode | One pass with a commit or reason per row. RL-247 itself waits on Orb's bystander follow-up | RL-247: **Yes** | |
| 17 Correct the overstated records | 2 | Legal | One pass over the listed AC items | No | |
| 18 Take process and engineering items out of the safety records | 2 | Legal with each owner | Re-home each item with a horizon tag | No | |
| 19 Check what players get: a daily job on /play/'s pin, the interim end date and the nightly's age | 1 | Tools | A scheduled CI job reporting to the EP | No | |
| 20 Someone watches CI: the standup reads `gh run list` first | 1 | EP | Add the step to the standup skill and the playbook | No | |
| 21 Stop silent passes ("grandfathered", "report only", "CHECK" print as exceptions) | 2 | Tools | build-site.mjs and the clip kit | No | |
| 22 Keep evidence: gate results saved under docs/<area>/runs/<sha>/ | 1 | EP (playbook), every director (charters) | The next landing saves its run file | No | |
| 23 Horizon tag and closing step on safety records; re-check at each baseline | 2 | Legal; QA | Add both fields to the review log and known-bugs | No | |
| 24 Every delegated safety decision has a named owner and written conditions; "don't raise it with Orb" never covers a lapsed safeguard | 1 | EP | Add the rule to the playbook; the flash decision gets its owner through CD-03 | Through CD-03 | |
| 25 One machine-read list of Legal's clip conditions that blocks a pin | 2 | Tools; Legal | A list beside tools/flash/sources.json, and a self-test where a pin fails on an open condition | No | |
| 26 Retire prototype suites from the deploy gate; retire flash-pixels-dryrun; rename the CI flash job | 2 | Tools | Deploy no longer needs qa and sim | No | |
| 27 A public-repo content screen on every push | 1 | Tools | A CI step that fails on a planted profile path | No | |

**Questions for Orb, one at a time, in this order:** CD-03 (the public test build), CD-07 (personal details), CD-11 (repo settings), CD-05 (the villain's casualty feed), then CD-13's rating target and CD-06's spend when a store page is planned.

**Directors:** they're paused for quiet time. Wave 1 starts when Orb lifts the pause, or sooner on Orb's word for CD-01 and CD-02, given the 2026-11-15 date.

# 5. Rule origins

For each standing safety rule: whether it comes from an outside source, and which, or was written inside the team. This is from my reading; the records themselves are the authority.

| Rule | Origin | Where |
| :--- | :--- | :--- |
| Flash limits (3 flashes a second, general and red flash area) | Outside: WCAG 2.3.1, with ITU-R BT.1702 and Harding named | `docs/legal/photosensitivity-note.md`; `tools/flash/wcag.js` |
| The weighted register (2.5 of weight, 1 under Reduce flashing), catastrophe-class rise and fall, L* 86, "calm is no exemption" | Inside, by Legal, built on the WCAG basis | `docs/legal/review-log.md` (for example RL-226, RL-227, RL-246, RL-249) |
| Reduce flashing on by default on the public site; click-through; no autoplay | Inside (Legal's interim terms) | `tools/site-interim.json`; `tools/check-site-interim.mjs` |
| Age ratings | Outside: ESRB, PEGI, IARC are named | `docs/legal/guide-stomp-and-ratings.md` and several screens |
| Children's and personal data | Outside: COPPA and GDPR are named | `docs/legal/go-to-market.md` |
| AI disclosure | Outside: Steam's disclosure policy is named; inside: Orb's "disclose upfront" rule | `docs/legal/steam-readiness.md`; ADR 0007; EP notes `ai-disclosure-upfront.md` |
| Licences (MIT, CC BY) | Outside licence texts; the choice is inside, pending Orb | `docs/legal/licence-recommendation.md`; `docs/legal/drafts/` |
| Originality (no franchise names or designs) | Inside, by Orb | `CLAUDE.md`; `docs/legal/originality-rules.md` |
| Pose and hand rules (h02 arms out, h05 chamber, RL-218) | Inside, by Legal | `docs/legal/review-log.md` RL-218 |
| Look gate: no dissolves, fades, slow wipes, blur or markers over fighters; eased camera | Inside, by Orb | ADR 0010; `CLAUDE.md` |
| No WIP character art in public | Inside, by Orb | EP notes `no-wip-character-art-public.md` |
| Bystanders, and the villain never fed by civilian deaths | Inside, by Orb | `CLAUDE.md` pillar 5; RL-214 and others |
| RL-226: private builds on Orb's (and now Orb 2's) screen only | Inside, by Legal | RL-226, RL-253 |
| LAN terms (home /24, no tunnel, firewall rule removed, no recording) | Inside, by Legal | RL-230, RL-241, RL-249 |
| Machine discipline (Godot caps, below-normal long runs, own PIDs) | Inside, by Orb and the EP | `CLAUDE.md` |
| Determinism (seeded RNG, fixed step) | Inside, engineering | `CLAUDE.md`; ADR 0004 |

# Re-home index for the misfiled safety items (audit CD-18)

Legal, 2026-11-07. The audit found 68 items that are process, engineering or design rules and not Legal's, filed in safety records (21 process, 34 engineering, 13 design rules), plus 1 business item. Nothing in this index is a legal finding. Each row names the owner that should hold the item and the horizon it matters at (private, web or store, as the audit tagged it; unclear means nobody has said). Legal's own files keep only what protects players, Orb or the project at release. Rows in review-log.md that cited these items are tagged Moved (CD-15, CD-18). The owner column is a first guess from the source path; the EP routes it.

Source: audit/2026-11-07/false-alarms.md (MISFILED) and claims.md.

## Engineering and quality

| Item | What it is | First source | Owner | Horizon |
|---|---|---|---|---|
| AC-044 | GB-003: the split-screen camera jolts when a player is knocked away. | qa/known-bugs.md:173 | QA | web |
| AC-046 | Open asks: seed Reduced motion from the platform's preference, and ask Legal whether a motion line with its ow | docs/accessibility/swing-motion.md:61 | Accessibility | web |
| AC-056 | The snapshot copier compiles GDScript at run time, which is untested in exported builds, the web included. | docs/net/cloud-reports/2026-10-28-rollback-core.md:67 | Netcode | unclear |
| AC-058 | The handshake refuses a peer on another protocol version or match key, which includes the data hash and AI lev | docs/net/rollback.md:240 | Netcode | private |
| AC-059 | The desync digest 'is not a security hash', since 'a peer that lies can lie about anything': there is no trust | docs/net/rollback.md:127 | Netcode | unclear |
| AC-065 | On a desync each peer writes a JSON report (replay, snapshots, field walk) to disk. An online upload to a cras | docs/net/rollback.md:134 | Netcode | unclear |
| AC-174 | Civilian and hazard hard tests are pending: H1 (hazards never break a region), H2 (zero tier-1 hazard casualti | docs/qa/README.md:46 | QA | store |
| AC-214 | No machine is a target during development, and minimum specs are measured and set before launch. | docs/decisions/0013-no-laptop-target.md:8-10 | EP | store |
| AC-226 | A bug in the played LAN build: a pause's rollback left fight 0 in the state, so a paused PC showed the wrong f | docs/net/pending/lan-n4/README.md:1-3 | Netcode | private |
| AC-227 | Orb reported faults in the LAN and 2v2 tests: intermittent stutter, both screens following only the main PC's  | docs/ep/vision.md:1654 | EP | private |
| AC-229 | The legacy suite (node qa/run-all.js) gates determinism, the seam, and a 1,000-match soak with no NaN, no cras | qa/README.md:15 | QA | unclear |
| AC-230 | Cross-processor agreement gates the LAN plan: if the two PCs disagree, everything else waits. | docs/net/two-pc-check.md:74 | Netcode | private |
| AC-231 | Known LAN rough edges, with no drop policy for a vanished peer: one match only with no rematch, a lost link ju | docs/net/lan-v1.md:85 | Netcode | private |
| AC-232 | The Godot QA run exits non-zero only if the run broke (no Godot, NaN, a fighter outside the world) or a hard a | docs/qa/README.md:19 | QA | unclear |
| AC-233 | Cross-play is only as wide as the parity proof: macOS ARM, Linux ARM, Android and iOS are not proven bit-ident | docs/net/rollback.md:214 | Netcode | store |
| AC-234 | Mutable statics outside the snapshot (DirBrawl._fr*, DirExchange.planEntry and others) are unaudited and could | docs/net/cloud-reports/2026-10-28-ai-depth.md:78 | Netcode | private |
| AC-236 | The web build's first start takes 22 to 57 s on this PC and possibly 1.5 to 2.5 minutes on a low-end phone, an | docs/marketing/phone-freeze-words.md:20 | Marketing | web |
| AC-242 | The native link (ENet) is 'built and tested between two programs in CI', and enet_check runs only in CI, never | docs/net/two-v-two-lan.md:117 | Netcode | private |
| AC-243 | The GDScript goldens are checked by tools/parity.gd on every push (CI, Linux) and locally. | docs/decisions/0006-gdscript-source-of-truth.md:14 | EP | unclear |
| AC-249 | The webrtc-native GDExtension would be a new dependency and needs approval before native-to-browser cross-play | docs/net/rollback.md:257 | Netcode | store |
| AC-260 | Beam alert accessibility: marks sit on a solid plate with 4.5:1 text contrast, visual, sound and buzz strength | docs/accessibility/beam-alert-review.md:16-17 | Accessibility | unclear |
| AC-263 | Three controller layouts plus full keyboard and pad remapping for both players ship, every layout producing th | docs/accessibility/audit-2026-10-28.md:29-35 | Accessibility | web |
| AC-269 | Combat's CC-007 to CC-013 were never added to the register, and the register-agreement check is meant to fail  | qa/known-bugs.md:198-200 | QA | unclear |
| AC-280 | Prototype bug KB-001: a signature against an ESCAPE defender hits less as the attacker's tier rises (a sign er | qa/known-bugs.md:9 | QA | unclear |
| AC-281 | Prototype bug KB-002: the 1.35x damage against a charging defender never applies. | qa/known-bugs.md:10 | QA | unclear |
| AC-282 | Prototype bug KB-003: a parried exchange still gives the attacker a chain window, so 13% of counted chains are | qa/known-bugs.md:11 | QA | unclear |
| AC-283 | Prototype bug KB-004: every chain strike ignores the defender's stance, putting 76.5 HP a match through a guar | qa/known-bugs.md:12 | QA | unclear |
| AC-284 | Prototype bug KB-005: a dodged signature freezes the defender 300 units up for 0.87 s. | qa/known-bugs.md:13 | QA | unclear |
| AC-285 | Prototype bug KB-006: the rush flies through terrain (15% of rushes) and through standing buildings (6.7%). | qa/known-bugs.md:14 | QA | unclear |
| AC-286 | GB-002: the high-tier sky reaction read as a glowing patch, and the clouds shimmered as fighters moved. It was | qa/known-bugs.md:156-165 | QA | web |
| AC-290 | A setting may change only what is drawn, never what the sim computes, so players on different settings can sti | docs/decisions/0012-turntable-and-quality-range.md:10 | EP | unclear |
| AC-292 | GB-008: a launch or charge cleared a lock-broken fighter's flag without the found event or the 6 s guard. | qa/known-bugs.md:181-187 | QA | web |
| AC-293 | The harness refuses a win share for a scripted player that pressed fewer than 100 times a match (SCRIPT BLIND) | docs/qa/brawl-qa-plan.md:76 | QA | private |
| AC-294 | Six baselines printed launches 'by him' and 'on him' the wrong way round (the launch actor is the body sent),  | docs/qa/README.md:73-74 | QA | private |

## Team process and hygiene

| Item | What it is | First source | Owner | Horizon |
|---|---|---|---|---|
| AC-025 | The records conflict on a reduced-motion dissolve: the audit wants it kept as an opt-in exception and camera_p | docs/accessibility/audit-2026-10-28.md:92 | Accessibility | web |
| AC-051 | f01 echo ceiling: the earlier pass rested on VFX's false claim of at most two echoes alive at once. It was fix | docs/legal/review-log.md:128 | EP | web |
| AC-060 | Mods load under defined format, loading and validation rules. | DIRECTORS.md:683 | EP | store |
| AC-066 | Internet play needs outside services (STUN, plus a paid TURN relay, or a forwarded port), so a ruling is requi | docs/net/rollback.md:206 | Netcode | store |
| AC-154 | Low-risk fallback titles Skyburden, Splendid Wreckage, Sky Arsonists and Redline Sky (RL-016, RL-017, RL-022,  | docs/legal/review-log.md:38-39 | EP | store |
| AC-155 | Title candidates Glorious Ruin and Sunburners are Medium and CONDITIONAL (album or .com collisions, confusion  | docs/legal/review-log.md:40 | EP | store |
| AC-177 | The 2026-10-06 rule against showing or describing buildings falling (w01, w02, RL-124 guard words, RL-127/RL-1 | docs/legal/review-log.md:146 | EP | web |
| AC-235 | Before Orb's first play: the warning shows first, the match record saves even when a match is cut short, ten m | docs/ep/first-press-list.md:13 | EP | private |
| AC-253 | Accessibility options (remapping, timing assist, colour-blind palettes, shake and flash reduction, subtitles)  | DIRECTORS.md:602 | EP | store |
| AC-265 | Open Legal flags for the P0 gate: RL-001, RL-002, RL-012, RL-014, RL-016 to RL-025, RL-027 to RL-030, RL-035,  | docs/legal/review-log.md:270 | EP | unclear |
| AC-266 | Never put a prompt in front of Orb: sessions run in bypass mode and write commands that never trip the built-i | CLAUDE.md:19-23 | EP | private |
| AC-267 | Every risk has an owner and a mitigation, and the risk register is kept as a live document. | DIRECTORS.md:514 | EP | private |
| AC-268 | Only the EP changes git state (reviews, commits and pushes); directors edit only the paths they own, and every | docs/decisions/0002-directors-as-sessions.md:11-12 | EP | private |
| AC-270 | LAN version 1 is 'Ready, not started' and must not run until Orb says so, because the firewall step needs Orb' | docs/net/lan-v1.md:3 | Netcode | private |
| AC-271 | Netcode exceeded its CPU cap (about 4 CPU-hours against 3), including a run at normal priority as a fourth God | docs/net/cloud-reports/2026-10-28-ai-takeover.md:20 | Netcode | private |
| AC-272 | Old-PC test of the private build: same warning before play, Orb alone watches, home address only with a /24 fi | docs/legal/review-log.md:246 (HEAD) | EP | private |
| AC-274 | The EP escalates every Legal flag to Orb, one clear question at a time, and directors never message each other | CLAUDE.md:12 | EP | private |
| AC-275 | No phase closes until its exit criteria are met and QA, Production and Legal have signed off. | docs/ep/playbook.md:12 | EP | private |
| AC-276 | QA harness hard caps so a run cannot hang the machine: --capsec 900, --wall 300 s, --budget, and godot.js guar | docs/qa/brawl-qa-plan.md:67 | QA | private |
| AC-277 | Machine discipline: at most 6 Godot processes per session, never the same batch twice, stop only your own proc | CLAUDE.md:18 | EP | private |
| AC-278 | Token discipline under ADR 0005 (Pro plan, zero budget, workflows or ultracode only with Orb's per-task approv | docs/decisions/0005-lean-team-and-token-discipline.md:10 | EP | private |

## Design rules (pillar 5, tone, tuning)

| Item | What it is | First source | Owner | Horizon |
|---|---|---|---|---|
| AC-178 | The civilian band (12 to 30% of civilians lost at the KO, reported with the split by fighter) is re-based on p | docs/qa/three-strength-qa-plan.md:152 | QA | store |
| AC-185 | The landmark nudge reads structures only, the same for every fighter, and the player's input wins; the Cyborg' | docs/legal/review-log.md:238 (HEAD) | EP | store |
| AC-186 | Hero care-relief lever: the trigger counts sends only, relief scales the mark-down by one factor with a data f | docs/legal/review-log.md:241 (HEAD) | EP | store |
| AC-187 | Far-town people feed only the hero's anguish as a cost, with no counter shown and no menace, power, Witness or | docs/legal/review-log.md:250 (HEAD) | EP | store |
| AC-188 | Power scale: a block collapse reads no occupancy, shows no one dying and has no ceremony; its light is one cat | docs/legal/review-log.md:254 (HEAD) | EP | store |
| AC-189 | The struggle meeting crater makes a large fall part of most matches: QA reads the band at every tier with over | docs/legal/review-log.md:268 (HEAD) | EP | store |
| AC-191 | Wreck Toss counts every living civilian within 3 bh, indoors or out, and never aims a landing near people. | docs/legal/review-log.md:208 (HEAD) | EP | store |
| AC-193 | Cyborg ground claims and co-op beat lines read wear state, never casualty counts, with no people, no remains a | docs/legal/review-log.md:187 (HEAD) | EP | store |
| AC-197 | Places barred by c09 (school, hospital, place of worship) take no damage from any blast, fall or unaimed body  | docs/legal/review-log.md:264 (HEAD) | EP | store |
| AC-261 | Gameplay assists that change outcomes (late-answer grace, wider chord and slip windows, a single-button vanish | docs/accessibility/beam-alert-review.md:41-45 | Accessibility | unclear |
| AC-287 | GB-004 to GB-007, playtest observations: a ranged press locks both fighters (a design question), mountain tumb | qa/known-bugs.md:174-177 | QA | web |
| AC-288 | GB-009: a brink fighter could not be finished by bolts alone. The finish was fixed in df05b9f, but the blaster | qa/known-bugs.md:189-194 | QA | web |
| AC-289 | A drifting brawl must never pass through a building face or damage a building (hard row C5). | docs/qa/three-strength-qa-plan.md:49 | QA | unclear |

## Business

| Item | What it is | First source | Owner | Horizon |
|---|---|---|---|---|
| AC-219 | Legal's four guides for Orb (licence, selling, company or individual in <state>, the stomp and ratings) are ge | docs/legal/review-log.md:174 (HEAD) | EP | store |

Total rows: 69.

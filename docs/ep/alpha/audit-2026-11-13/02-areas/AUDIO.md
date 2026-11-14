# AUDIO: audio and music (Alpha audit, baseline 8901d351)

Read-only review, 2026-11-13. Game code at the baseline is the code of the last build Orb played, 6a30b4c9. **This area was reviewed at reduced depth:** mainly from the inventory slices (I-05, I-09) and the Audio pages, with the code opened only where a blocker or major might hide. No Godot run, no browser, nothing listened to.

## Summary

- **Works:** the sound pipeline is wired into the game (sim events become cues, every sound is synthesised by our own code, a voice pool plays them), volume and mono settings exist, the browser-build crackle fix is on main and in Orb's build with saved measurements, and Legal has a written ruling for the music tool.
- **Does not work:** on main, five of the sound sets are switched off, so a build made plainly from main has no beam, knock-out, launch, struggle or transformation sound; buildings, bystanders, the gravity well and the menus have no sound at all in any build; there is no music.
- **Biggest gap:** nothing in this area is proved by ear or on the Alpha's platforms. Every proof is a log or a browser recording; nobody has recorded listening to a Windows or Linux desktop build, and Orb's last word on sound (2026-11-09) is still a complaint.
- No blocker found. Three majors, all cheap to settle (S or M).

## Questions and answers

**Q1. What's placeholder, by sound group.**
No page marks any sound "placeholder" (grep of `docs/audio/direction.md`, `grunts.md`, `brawl-cues.md`, `audio/README.md`: no hit). In practice every sound is provisional: all are synthesised by code (`01-inventory/I-05-ui-audio-loc.md:28`), and Orb's standing word is "I really want to keep workshopping new and different sound effects" (`docs/ep/vision.md:1703`). By group:

| Group | State at the baseline | Evidence |
| --- | --- | --- |
| Hits, wind-ups, misses, the launcher ping, bolts and blasts, craters | Live on main. The hits were re-tuned lower after Orb's "tinny" note; that is Audio's claim from a tone check, not re-run here, and not confirmed by Orb's ear. Bolt and blast are named by Audio as still bright. | `audio/audio_cues.gd:85-94`, `audio/audio_brawl.gd:77-144`; `docs/ep/vision.md:1333-1334`; `docs/audio/first-play-sound.md:7-9` |
| Grunts (pain, effort) | Live, procedural, not words. | `docs/audio/first-play-sound.md:16` |
| Beam struggle, "moments" (beam charge and fire, knock-out, launch, parry, meteor landing), "carry" (perfect block, rush, transformation ready/hold/release, air brake) | Written, **off on main**, on in Orb's build by switch. The moments set re-uses existing sounds at other pitches, by its own note. | `audio/data/tug_cues.json:4`, `moment_cues.json:3-4`, `carry_cues.json:4`; `docs/tools/runs/6a30b4c9/pck-verify.txt:93-95` |
| World: one ambience per biome, ground surfaces, water | Written, off on main, and no switch turns it on in any build. | `audio/data/world_cues.json:3-4`; `tools/preview/switches.mjs:236-244` (three sound switches, none for world) |
| Co-op and controller sounds (the brink call, refusal knock) | Written, off, no switch. | `audio/data/coop_cues.json:3-4` |
| Fighter "babble" voice for captions | Written (444 lines), not reached by the game. | `01-inventory/inventory.md` check 4; `01-inventory/I-05-ui-audio-loc.md:30` |
| Buildings, bystanders, gravity well, menus | No sound exists. | see F-AUDIO-02 |
| Music | None. `audio/music/` holds a README, a notice, a template and an empty `incoming/`. | `01-inventory/I-05-ui-audio-loc.md:31`; `docs/legal/asset-origins.md:54` |

**Q2. Orb's crackle complaint, and "no sound until I paused the first time". Open or fixed?**
- *Crackle:* a fix for the browser build is on main and in Orb's build (commit d4748ec3, an ancestor of 6a30b4c9): short sounds are played by the browser itself so a slow frame cannot cut them. Audio's saved numbers show holes of 66.7 and 106.7 ms before and none after (`docs/audio/crackle.md:13-18`; data in `docs/audio/img/crackle/ab-*.json`). But the page says "Nobody has listened to it" (`docs/audio/crackle.md:3`), and Orb's answer on 2026-11-09, after the fix was in the build they played, is "the crackles sounded bad and I didn't like them" (`docs/ep/vision.md:1703`). Whether that sentence is about the old crackle or the fixed build is **not evidenced**. Status: **open until Orb listens.** Looping sounds still go through the engine's mixer and can still drop out at a stall (`docs/audio/crackle.md:58`). Whether any of this happens on a desktop build is not evidenced (see Q6).
- *No sound until paused:* cause found (a browser holds sound until a key, click or touch; the pad had been used for three minutes), `docs/audio/pad-start.md:3-11`. **Partly fixed:** the browser-side player now asks on a pad press (commit 76cc199c, in 6a30b4c9). Not done: the hook for the engine's own sound context is still a parked snippet (`git grep __audioShell -- tools` returns nothing; `docs/audio/pending/audio-resume/README.md:3`), the start-menu line that tells a pad-only player is parked (`docs/ui/pending/sound-line/README.md:3-9` (uncommitted)), and nothing reads `web_blocked()` (`audio/audio_voices.gd:281` is its only non-doc use). Whether a real pad press wakes sound in Orb's browser is **not evidenced** (`docs/audio/pad-start.md:26`). This is a browser rule; the Alpha's platforms are desktop builds, so it matters only for private browser looks.

**Q3. The baseline Alpha needs: which sounds must exist for a stranger.**
Reading X-13's list against what has a sound:

| Pillar moment (X-13) | Sound today |
| --- | --- |
| Blows, guard, miss, wind-up, charge | Yes, on main |
| Crater | Yes, on main (`audio/audio_cues.gd:92`) |
| Beam charged, fired, struggle | Only with the moments and struggle sets on (off on main) |
| Launch, meteor landing, knock-out | Only with the moments set on |
| Transformation | Only with the carry set on (`audio/audio_carry.gd:94-98`) |
| Signature | No cue of its own found; it would sound as a beam or blow. Not evidenced beyond that. |
| Building damaged or collapsing | **None** |
| Bystanders scattering | **None** |
| Gravity well's pull | **None** |
| Menus (move, confirm, back), match start, result | **None** found (no `ui/` code calls audio outside settings; the only `ui.` sound is the in-fight launcher ping) |
| Music or any bed under the fight | **None** (world ambience is parked; no music) |

Proposed baseline for Alpha: the three sets Orb already plays with become the default on main; a building-hit and collapse sound; a menu move/confirm/back set; one ambience or music bed so the fight is not dry. Bystanders and the gravity well are nice to have.

**Q4. Orb's "unified audio toolset": before or after Alpha.**
Orb: "Keep this in the queue so we can come back to this when the 3d globe arena is ironed out" (`docs/ep/vision.md:1704`). No plan page exists for it (search of `docs/` for "unified audio", "audio toolset", "audio workbench": only Orb's words, the audit's own pages, and a note in `docs/ep/proposals/alpha-feature-workshop.html:282` that an adaptive-music idea "fits the audio toolset you have queued"). **Placement: after Alpha**, as the first audio job of the polish period, with one small piece pulled forward: a listening page for Orb (see F-AUDIO-03). Reason: Orb's own condition (the globe settled) is not met, a new sound style is a feature and Alpha is followed by a feature freeze only for new features, not for finishing; and the gaps in Q3 can be closed with the existing synths.

**Q5. The Suno pipeline test; Legal's check of the tool's terms.**
- The pipeline is designed (`docs/audio/suno-direction.md:3`, `audio/music/README.md:3-12`) and has never run: `audio/music/incoming/` is empty apart from `.gdignore`, and the audio encoder install was twice not approved (`docs/ep/vision.md:628`, `:698`). It waits on Orb for a track and the install.
- Legal's ruling exists (`docs/legal/suno-music.md`, 2026-10-04): shipping is "Conditional" (paid plan, keep downloads untouched, a separate notice, never call it human-made; `:30`, `:44-47`), disclosure is required on Steam and advised on itch.io (`:36`). The notice file is in place (`audio/music/NOTICE.txt:1`); the About page's music sentence exists behind a flag that is off (`ui/data/features.json:8`), which is correct while no music ships.
- Weakness: Legal read summaries of the terms, not the terms ("Could not verify", `docs/legal/suno-music.md:15`), and the read is six weeks old. A re-read is owed before any track ships.

**Q6. Audio on Linux and the Deck.**
**Not evidenced.** Every audio proof found is for the browser build in Chrome (`docs/audio/crackle.md:57`, `docs/audio/pad-start.md:13-15`). `project.godot:12-14` has one audio setting and it is web-only. No CI job runs any audio check (`01-inventory/I-05-ui-audio-loc.md:9`). No page in `docs/audio/` mentions Linux, the Deck, or a desktop output device (grep, no relevant hit). The game's audio status line does report the mix rate, output latency and device (`audio/audio_voices.gd:258-263`), so one desktop run on each platform that saves that line would settle "does it start" (not "does it sound right"). The PERF area records the same hole for stalls on desktop (`02-areas/PERF.md:81`, F-PERF-13).

## Exit criteria

| Id | Status | Proof or gap | Measuring tool; exists? |
| --- | --- | --- | --- |
| X-13 | Not measurable today | The criterion is read from the match's event feed; no checklist probe was found (`git grep -il 'alpha.*checklist\|pillar_check\|alpha_match' -- qa tools sim`: nothing). Audio's part: of the eleven pillar moments, three have no sound in any build and four have one only with switches that are off on main (Q3). X-13 as written does not ask that a pillar be heard; that is a gap in the criterion (see "Gaps the questions missed"). | Alpha match checklist probe (QA, with Encounter): **does not exist**. Audio already has a headless cue log method (`docs/audio/first-play-sound.md:3`, a scratch script, not in the repo) and `audio/tools/cue_sweep.gd`; a "cue heard per pillar" column could be added to the probe from those. |

X-13's 6 to 8 minute match length is not an audio number; no change proposed from this area.

## Findings

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-AUDIO-01 | gap | On main five sound sets are off, so a build made plainly from main has no beam, knock-out, launch, struggle or transformation sound; Orb's build has three of them on only through build switches. | `audio/data/tug_cues.json:4`, `moment_cues.json:4`, `carry_cues.json:4`, `coop_cues.json:4`, `world_cues.json:4`; `docs/tools/runs/6a30b4c9/pck-verify.txt:93-95`; `tools/preview/switches.mjs:236-244` | X-13 | major | required | audio-music | S | no |
| F-AUDIO-02 | gap | No sound exists for a building being damaged or collapsing, bystanders scattering, the gravity well, or any menu action, and the fight has no ambience or music bed in any build. | `audio/audio_cues.gd:85-94`; `audio/audio_moments.gd:37-58`; `audio/audio_world.gd:106-124`; `audio/audio_brawl.gd:77-144`; `audio/audio_carry.gd:71-102`; `audio/data/world_cues.json:4`; `01-inventory/I-05-ui-audio-loc.md:31` | X-13 | major | required | audio-music | M | no |
| F-AUDIO-03 | gap | Nothing in the area is proved by ear: Audio's pages say nobody has listened, and Orb's latest word (2026-11-09) is that the crackles sounded bad, with no record of whether that was the fixed build. | `docs/audio/crackle.md:3`, `:55`; `docs/audio/first-play-sound.md:3`; `docs/ep/vision.md:1703` | none | major | required | audio-music | S | no |
| F-AUDIO-04 | gap | Sound on the Alpha's platforms (a Windows desktop build, Linux, the Steam Deck) is not evidenced: every proof is the browser build in Chrome, the only audio project setting is web-only, and no CI job runs an audio check. | `project.godot:12-14`; `docs/audio/crackle.md:57`; `01-inventory/I-05-ui-audio-loc.md:9`; `02-areas/PERF.md:81` | X-05, X-19 | major | required | audio-music | S | no |
| F-AUDIO-05 | gap | There is no music: no track has been handed back, the encoder install was not approved, and the pipeline has never run end to end. | `01-inventory/I-05-ui-audio-loc.md:31`; `docs/legal/asset-origins.md:54`; `docs/ep/vision.md:628`, `:698`; `audio/music/README.md:3` | none | minor | nice | orb | M | no |
| F-AUDIO-06 | gap | Stacked impacts overdrive the engine's limiter (peaks +1.1 to +9.3 dBFS before it, up to 2.3% of samples over its threshold) on the mixer path a desktop build uses, and the resulting distortion was never measured or heard. | `docs/audio/crackle.md:34`, `:36`; `audio/audio_voices.gd:19` | none | minor | nice | audio-music | S | no |
| F-AUDIO-07 | gap | The pad-only silent start in the browser is half fixed: the engine-side hook and the start-menu line that warns the player are parked, and the getter built for it is read by nothing. | `docs/audio/pad-start.md:26`, `:39`; `docs/audio/pending/audio-resume/README.md:3`; `docs/ui/pending/sound-line/README.md:3-9` (uncommitted); `audio/audio_voices.gd:281` | none | minor | nice | audio-music | S | no |
| F-AUDIO-08 | gap | Legal's ruling on the music tool rests on summaries of its terms read on 2026-10-04, and says so; no re-read is recorded before a track would ship to outside testers. | `docs/legal/suno-music.md:3`, `:15` | X-32 | minor | nice | legal-ip | S | no |
| F-AUDIO-09 | gap | No audio check runs in CI, and two sound data files (co-op and moments) have no schema rule, so a broken cue file would only warn. | `01-inventory/I-05-ui-audio-loc.md:9`, `:41`; `audio/data/moment_cues.json:3`; `audio/data/coop_cues.json:3` | none | minor | nice | audio-music | S | no |
| F-AUDIO-10 | gap | Leftovers: the caption "babble" voice is unreached by the game, a schema rule points at a music file that does not exist, and nine audio parks stay on disk although two are fully on main and one is withdrawn. | `01-inventory/I-05-ui-audio-loc.md:30`; `tools/schemas/map.json:163`; `01-inventory/I-09-pending-parks.md:29`, `:49` | none | minor | after | audio-music | S | no |
| F-AUDIO-11 | works | The sound pipeline is wired into the game: the host creates the cue reader and voice pool and warms the sound bank at start, and Orb reported "sound worked" on a browser build. | `render/core/sim_host.gd:26`; `render/core/main.gd:232-234`; `docs/ep/vision.md:1646` | X-13 | none | n/a | audio-music | n/a | no |
| F-AUDIO-12 | works | The browser crackle fix is on main and in Orb's build, with saved before-and-after measurements (holes of 66.7 and 106.7 ms gone at 100 and 150 ms stalls). | `commit:d4748ec3`; `docs/audio/crackle.md:13-18`; `docs/audio/img/crackle/ab-after.json` (file present, not opened) | none | none | n/a | audio-music | n/a | no |
| F-AUDIO-13 | works | Settings has Master, Effects and Voice volume and Mono sound. | `ui/data/settings.json:55`; `commit:9979146a` | X-20 | none | n/a | ui-ux | n/a | no |
| F-AUDIO-14 | works | The music paperwork is ahead of the music: a ruling, a notice file, an origin-log row and an About-page sentence held off by a flag until a track ships. | `docs/legal/suno-music.md:44-47`; `audio/music/NOTICE.txt:1`; `docs/legal/asset-origins.md:54`; `ui/data/features.json:8` | X-32 | none | n/a | legal-ip | n/a | no |

Cost basis: no recorded token cost for a past audio job was found in the files read; all are "estimate, no comparable". F-AUDIO-01 is a flag flip plus the look-free gate runs; F-AUDIO-02 is new cue rows on existing synths plus a menu hook that UI must call (needs ui-ux); F-AUDIO-04 is two desktop runs saving the status line (needs performance-platform and a Deck tester).

Notes on owners: `audio/` is audio-music by DIRECTORS.md (per `01-inventory/I-05-ui-audio-loc.md:8`). F-AUDIO-05 is owned by orb because the next step is Orb's track and install decision. F-AUDIO-13 sits in `ui/data`, ui-ux.

## Gaps the questions missed

1. **X-13 does not ask that a pillar be heard.** A match can pass the checklist with silent buildings, bystanders and gravity well. Either add "and each has a sound cue" to the probe, or record that silence is accepted for Alpha (F-AUDIO-02).
2. **Main and Orb's build differ in sound.** A tester build made from main without the switch list would be quieter than what Orb approved (F-AUDIO-01). This is the audio slice of the audit-wide "72 of 92 switches differ" fact (`01-inventory/inventory.md`, switch table summary).
3. **Limiter overdrive on the desktop path** (F-AUDIO-06): Audio measured it while fixing the browser crackle and fixed it only on the browser path.
4. **No listening record at all** (F-AUDIO-03): there is no `docs/audio/runs/` folder, so no audio gate has a saved record per commit, which X-02 would need if any sound gate joins the "before an outside tester plays" list.
5. **Captions:** each cue carries a caption string (`audio/data/cues.json:12`, `:17`); whether captions are shown to a player was not checked here (accessibility area).

## Not evidenced

| What | One measurement that would settle it |
| --- | --- |
| Whether Orb still hears crackle on 6a30b4c9 or later | Orb plays one match and answers one yes/no line; or plays the six saved recordings in `docs/audio/img/crackle/` |
| Whether a desktop build makes sound at all, and crackles at stalls, on Windows, Linux and the Deck | One run per platform that saves the audio status line (`audio/audio_voices.gd:258`), and one listen |
| Whether a real pad press starts sound in the browser | The `pad seen / asked / woke` counters from one pad-only start (`docs/audio/pad-start.md:26`) |
| Whether the re-tuned hits read as "chunky" to Orb | Orb's ear; the tone check is Audio's claim (`docs/audio/first-play-sound.md:7`), not re-run |
| Whether the signature has a sound distinct from a plain beam | The cue log of one scripted match that fires both signatures |
| Whether the ten audio checks in `audio/tools/` pass at the baseline | Run them (not allowed in this audit); none is in CI |
| The exact terms of the music tool today | Legal re-reads the terms page itself (F-AUDIO-08) |

## Decisions for Orb

1. **Does Alpha need music?** Recommendation: no. Ship Alpha with one quiet ambience bed from our own synths and say "music comes later" in the tester guide; run the music pipeline test after Alpha, when you have a track you like.
2. **The audio toolset: before or after Alpha?** Recommendation: after, as the first audio job of the polish period; before Alpha, only a simple listening page so you can judge sounds by ear and tick yes or no.
3. **Will you do one ten-minute listening pass on a desktop build before testers get it?** Recommendation: yes. It is the only way to close the crackle question, and nobody on the team can hear.

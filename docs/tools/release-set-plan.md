# The release flash set after Legal's addendum 6 (RL-128): what is built, the scenarios, the cost, how to afford it (2026-10-12)

Owner: Tools and Pipeline. For the EP, Legal and the directors whose scenes the set needs.

## 1. The rules, as built (tools/flash/release-pass.mjs and its self-test, 34 checks)

| Legal's rule | In the tool |
|---|---|
| combined rule: primary at most 2.5; area-15% and stricter memory at most 3 | `verdict.js` (unchanged): PASS, OVER GATE (primary over 2.5), FAIL (any reading over 3). A clip at exactly 3 on the primary reading is OVER GATE: not a pass. |
| a clip whose readings differ by more than 1.0 is **sensitive** and is re-captured at another seed or start | `spreadOf` (primary, area-15%, stricter memory). A sensitive row counts only with a `recapture` row (another `--seed` or `--skip`) that is PASS and not itself sensitive. `--record --recaptures <summary.json> --how "seed 7"` attaches them. |
| no counted change within 15% above the area threshold in the worst second unless the second totals 2.0 or less | `marginalCount` of the row (the analyser's own "marginal" count) against the primary reading. Refused at `--record` and at `--verify`. |
| the pass is on the commit being published, both modes | the four hashes of the record against the commit; every required clip is captured normal and reduced. |
| re-run the whole set when a change touches the camera, lighting, scenery contrast, an effect or the crowd | `node tools/flash/which-set.mjs <base>..<head>` says FULL (render/, art/, ui/, data/biomes/, data/anim/, shaders, input layouts), AI (sim/, data/director, combat, fight, fighters: the AI matches are different matches) or NONE (docs, tools, qa, research). |
| k06: the HUD's crown flicker is in the flash check's frame | the capture is the whole page: the HUD is in every frame already (UI's legend flicker read as the mash's 3 until their gate). What is missing is a scenario that makes the crown flicker (see section 3, `crown`). |

## 2. The required set, scenario by scenario

Today 28 clips: 14 scenarios by 2 modes: mash, mashcity, clash, signature, transform, collapse, and the AI matches at seeds 12345, 4, 7, 1, 3, 5, 38 and 39.

| Legal's list | Scenario (id) | State | What it needs | Ticks | Clips |
|---|---|---|---|---|---|
| the mash at the foot of the towers | `mashcity` | **in** | nothing | 1,800 | 2 |
| a beam clash | `clash` | **in** | nothing | 1,500 | 2 |
| the transformation | `transform` | **in** | nothing | 1,500 | 2 |
| a signature and an explosion in the city | `signature` and `collapse` exist; `signaturecity`: the signature scene started beside the tallest tower | small | `_to_the_city` start for the signature scene, mine, today | 1,500 | 2 |
| camera travel at maximum speed over high-contrast scenery | `rushcity`: P1 sprints (stick and dodge held) along the front street past the downtown towers and the crowd | small | pad script, mine, today | 1,500 | 2 |
| an open-floor building opening and closing in view | `openfloors`: the pair set down at a tower of five floors or more and walked past it and back | small | Rendering to say which building and what makes it open (the pane's cutaway request); the staging is mine | 1,500 | 2 |
| a zip chain and a launch across the city | `zipcity`: a zip chain from the manoeuvre stance, then B on a staggered rival (the launcher) along the street | medium | Controls' pad recipe for a zip chain; the sim's launch is real, not staged | 1,800 | 2 |
| the sky at its extremes with a town in view | `skyextremes`: the sky key driven to its darkest, brightest and the dawn and dusk blends while the pair fight in front of a town | medium | Rendering/Art: the name of `SkyDrive`'s switch (render/core/sky_drive.gd) so the staging can drive it; a scratch hook until then | 1,800 | 2 |
| a flyby of all three streets and the avenues, at depth | `flyby`: the camera and a pair flying along each street lane and across each avenue | **blocked** | fighters in depth on main (Simulation's parked depth core), and Camera's scripted path or a flight the director makes | 2,400 | 2 |
| fighters in depth in AI matches | `aidepth`: four of the AI seeds with the setup's `"depth": true` | **blocked** | depth on main (`S.depthOn` from the setup) and the hook passing the setup | 3,600 | 8 |
| the crown's flicker (k06) | `crown`: the state that makes the HUD's crown flicker, held for 10 seconds, in both modes | needs UI | UI to name the state (a tier, a low health, a pause) | 900 | 2 |
| 20 fixed AI seeds (every pairing and signature) | `ai`: 12 more seeds beyond today's 8, each shown to have both fighters' signature (`seed_scan.gd` lists them) | medium | the seed scan, mine; the roster has one pairing today | 3,600 | 24 |

Scenario ids are written to `tools/flash/sources.json`, the hook (`render/tools/flash_capture.gd`) and `flash_worst.gd` together, and the selftest's drift checks keep the two stagings the same lines.

## 3. What it costs on this PC

Measured today on a loaded machine, one capture at a time, the game's own web build in headless Chrome (it renders on the RTX 5070 Ti, not in software: the incident's browsers forced SwiftShader): the step is about 60 ms and the lossless screenshot about 140 ms, **about 5 frames a second**. With three clips at once under the set's 40% core budget the whole 28-clip run took about 2 hours: about 2.1 times the single-capture rate. (`optimizeForSpeed` on the PNG is 0 to 40% faster and 50% larger: not worth the noise.)

| | ticks | hours at 5 fps, one at a time |
|---|---|---|
| today's 28 clips (12 fixed at about 1,600, 16 AI at 3,600) | 76,800 | 4.3 |
| the new fixed scenarios (7, both modes) | about 22,000 | 1.2 |
| `aidepth` (4 seeds, both modes) | 28,800 | 1.6 |
| 12 more AI seeds, both modes | 86,400 | 4.8 |
| **the full release set** | about 214,000 | **about 12, plus analysis (a minute a clip)** |

At three jobs under the 40% cap: **about 5.5 hours**, a night. One at a time per session, as the rule says: half a day.

## 4. How to afford it: three tiers

1. **Per change (the fast subset): about 30 minutes.** The windows of the known worst moments: for each clip within 0.5 of the gate or over it, the 3 seconds around its worst second (180 frames), plus the three fixed city scenes at full length (mashcity, rushcity, collapse). `which-set.mjs` decides FULL, AI or NONE for the change; a FULL change queues the nightly set, it does not wait for the subset. It is a tripwire on known worst moments, not a gate: a change that moves the worst second elsewhere is not seen.
2. **Nightly: the full set, three jobs, about 5.5 hours,** on the newest commit, both modes, reported as a table with the margins (`margins.mjs`) and the sources (HUD, camera, world).
3. **Release: the nightly set on the commit being published,** with the sensitive clips re-captured at another seed or start (`--recaptures`), then `release-pass.mjs --record`. Orb's call, not written until then.

To make the windows cheap the hook needs one thing: **`skip`**, the ticks run without drawing before the clip starts (the contract exists in `capture-web.mjs`; the hook has not offered it). Running 600 ticks without a picture costs about 30 seconds against 120 for a drawn clip; with it an AI seed's three worst windows (1,800 drawn ticks) replace its 3,600-tick match in the subset, and a sensitive clip is re-captured from another start for the price of its window. That is a 6-line change in Rendering's hook (I will ship it as a patch).

## 5. What I need, by owner

- **Rendering:** `skip` in the hook (patch from me); the sky switch's name; which building opens its floors and how to make it open.
- **Simulation:** fighters in depth on main (the setup's `"depth": true`), for `flyby` and `aidepth`.
- **Camera:** a scripted path for the flyby, or the director's flight along a street.
- **Controls:** the pad recipe for a zip chain from the manoeuvre stance.
- **UI:** the state that makes the crown flicker (k06) and a measurement of it in the check's frame.
- **Legal:** whether the nightly window subset may stand in for a per-change check (never for the release), and whether 20 seeds means 20 per pairing or 20 in all; with one pairing today the two agree.
- **Me, now:** `signaturecity` and `rushcity` (small, no dependency), the 12 seeds, `skip`'s patch. I will do them when the running set is reported, unless you say otherwise.

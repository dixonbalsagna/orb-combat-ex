# docs/controls: Controls and Game Feel

Owner: Controls and Game Feel. Date: 2026-09-29. Design first; code in `sim/input/` follows when the EP hands over the tree (ADR 0006).

| File | What it is |
| :--- | :--- |
| [haptics.md](haptics.md) | **The pulse for a launch opening** (`SimHaptics`, pure; the host's one connect as a patch), device rules, proof |
| [brake-and-grapple.md](brake-and-grapple.md) | **Built, parked behind switches:** the air brake's bit on a Simple slot, `struggle_press`'s A only, `catch_read` and `brace_read`, `a_read`'s shove and clinch retired |
| [grapple-input.md](grapple-input.md) | **The grapple's inputs** (paper): the catch and the clinch on A, the carry and the brace, every layout, touch Simple's three options |
| [struggle-input.md](struggle-input.md) | **The beam struggle's inputs on every layout** (paper): the surge, the stray, the let-go, Simple and touch, the traps |
| [local-two-player.md](local-two-player.md) | **Local two-player:** the join rule, every pairing of devices, leaving, per-player layouts, what Rendering and UI wire, and Orb's manual checks |
| [remap.md](remap.md) | The Full touch preset and what UI's Remap screen calls (overrides, checks, persistence, shared names) |
| [i2c.md](i2c.md) | **I2c as built:** the layout layer produces intent v2 for keyboard, pad and touch; files, glue, proof, gaps |
| [input-gates.md](input-gates.md) | The input gates: every test in sim/input/test (with T1, the press-tick latency test) and the rest of a window's gate |
| [phone-feasibility.md](phone-feasibility.md) | **Is the phone scheme feasible?** What it does, the risks, what already helps, a five-minute test for Orb's phone, and the first two changes |
| [energy-input.md](energy-input.md) | **Energy attacks overhaul, input grammar (proposal):** one grammar for martial and energy, press-by-press per action, devices, beam vs blast, feedback, accessibility |
| [right-stick.md](right-stick.md) | **The right stick (Orb's brief), input side:** the deterministic flick / hold / pattern read, modelled misread rates, per-modifier modes, keyboard and touch parity, accessibility, cost |
| [right-stick-capture.md](right-stick-capture.md) | The real-thumb capture tool for the right stick: a one-page spec (a single HTML page on the Gamepad API, the protocol, the analysis, the bar a pattern must clear) |
| [right-thumb.md](right-thumb.md) | **No grip beats the standard grip:** the claw problem as four testable rules (gap-invariance, lockout, window, mirrors), the thumb-transfer model, Orb's five directions scored, what it changes in step 1 |
| [claw-bot-gate.md](claw-bot-gate.md) | The claw-bot gate spec over GD's step-1 rows (assertions A to F, the fight check, the stub proof) and the check of the dodge's left-stick direction read |
| [palm-turn-overtake-read.md](palm-turn-overtake-read.md) | The left stick's read at the 45-degree edge between the Palm Turn (across) and the overtake (back): confirmed, with the dead band held in reserve |
| [right-hand-attacks.md](right-hand-attacks.md) | **Right-hand attacks, pitch 4a (Orb's pick, 2026-10-30), built behind `switches.rightStick` (off):** directional-charge strikes on the right stick as their own class, the left hand's slip / brace / vanish, every shoulder combination kept or rejected, the maps, keyboard and D-pad mirror, the no-claw law K1 to K7 with its gate, the left-handed swap and remap, what is built and what each owner still needs (`right-hand-attacks-model.mjs` is the arithmetic model; the two outside patches are parked in `pending/right-hand/`) |
| [right-hand-interface.md](right-hand-interface.md) | **The right-hand attacks' interface for the other directors (2026-10-31):** the intent's second word field by field, what Simulation reads into the hash and replay, what the director and Combat do with `rsStart` / `rsRelease` / `rsDir` / `rsLevel` / `rsMask`, the hub settings UI calls, and the order a player needs to feel a stick strike |
| [responsiveness.md](responsiveness.md) | **Where the ticks go between a thumb and the screen (2026-11-01):** a face tap reacts on the press tick and lands in 3; a stick strike lands 15 ticks after the thumb moves (3 to 4 read, 12 the director's wind-up); the vanish waited 6 ticks; the no-claw law's cost; ranked fixes; the quick read (settle 1, the vanish on the second press, the stick's pre-read for the pose), built behind `switches.quickRead`; how to re-run the probes |
| [rule-of-cool-pitches.md](rule-of-cool-pitches.md) | **Ten controller pitches for right-hand 4a (2026-11-01), for Game Design to rule on:** feel the ladder, snap or push, feel it coming, trigger depth, catch the ground, crank the clash, sweep and cut, lean the world, the phrase chime, the lean (a bluff); each with the pad action, what happens, why, cost and test |
| [controls-audit.md](controls-audit.md) | **The audit of every input on the live pad map, run in real fights (2026-11-01):** what is working, what is wired but thin and what is not built (brace, vanish, the power specials and the Driver are not answered by the sim); the gaps, biggest first |
| [two-v-two-input.md](two-v-two-input.md) | **2v2 on the pad, on paper (2026-11-01):** the D-pad focus and the call (the swap and the mirror need no special case), the three extra bits of the second word, and the claw-grip check (model section 8; a hold-off law or a least gap) |
| [clips/hitstop-ab.md](clips/hitstop-ab.md) | **The hit-stop A/B clip (2026-11-01):** the same 760-tick fight's pad inputs as a script, its overlay for drawing the inputs, and a headless replay that shows the sim held 38 ticks off and 69 on with the same damage, for Tools' capture |
| [clips/thumbs.md](clips/thumbs.md) | **Synthetic thumbs for the moving reel (2026-11-01):** `thumbs.json` (the right-stick model's 720 traces, one sample a tick, with the 50% recentring overshoot and drift), how to feed a pad with it, and what the reader did: no phantom flick from a spring-back, no request from an idle thumb; a casual thumb's wandering aim re-crosses in 13% |
| [beam-answers-input.md](beam-answers-input.md) | **Beam answers on the pad, a fit check (2026-11-01, paper):** every idea in the pad packet against hand, collisions, the no-claw law, the mirror, the swapped layout and one hand alone; the free inputs; how the answer window can read the stick (flick = swat, RB + flick = fire back); press-to-result against the window |
| [orb-first-play-stick.md](orb-first-play-stick.md) | **Orb's raw stick on the path (first play, 1 Nov; counts only):** no flick lost, every hold reached the level its length earns, no hidden delay; the beam needs RB held first and two no-RB holds are why a beam was hard to find. Reader: `clips/read-stick-log.cjs` |
| [beam-aim-feel.md](beam-aim-feel.md) | **Beam aim and the charge, read off Orb's thumb (2026-11-01):** dead zone kept at 0.25; the throw lost its aim (38 of 53 release rows say 0 = right); a trailing 4 degree band and a rim-mean latch fix it (park `pending/beam-aim/`, off); how a stage is felt by pad and hands; the timed release |
| [stoke-and-chin.md](stoke-and-chin.md) | **Bolus's stoke, Loupe's On the Chin, the universal release (2026-11-01):** the stoke does not fight the claw law but needs a reversal counter (a rim-to-rim pump holds no faces today); a fresh RT edge fits at zero ticks; the release direction reads (41 of 43 holds in the right quarter-turn) only from the latched aim, 24 of 43 wrong on the throw tick |
| [hold-toggles.md](hold-toggles.md) | Hold or toggle for Guard, the manoeuvre and charging stances and Transform's half second: how a toggle is fed to the same held state, what ends one, the options, the check (Accessibility's audit item 2) |
| [params-cache.md](params-cache.md) | The kept `params()` of the press reader and the aim helper: when a copy is thrown away, the read-only rule, the check and the numbers (Encounter's tick-skip NEEDS 1) |
| [phone-test-checklist.md](phone-test-checklist.md) | A 15-minute real-phone test for Orb: landscape, several fingers, left-handed, portrait, latency, browser interference |
| [touch-bridge.md](touch-bridge.md) | The touch Simple bridge to today's intents: mapping, files, host patch, tests, what UI builds |
| [input-scheme.md](input-scheme.md) | **Current (ADR 0008):** actions, the three controller layouts, tap and hold rules, keyboard (solo and shared), touch Simple and Full, the intent record, stage plan, tests |
| [input-schema.md](input-schema.md) | **Current:** data model, presets and schemas for Tools (`actions`, `layouts`, `timing`, user file) |
| [rulings.md](rulings.md) | Rulings on Combat's proposals: parry, chain and wind-up widths in ticks, buffering, anti-mash, hit-stop table, finisher struggle, latency budget, draft data, ranked risks with tests |
| [input-map.md](input-map.md) | Keyboard (P1, P2) and gamepad maps, the intent record, special and transform holds per fighter, parity rules |
| [shake-pass.md](shake-pass.md) | Per-event shake for Camera, and the split's per-pane rule |
| [prompt-glyphs.md](prompt-glyphs.md) | Prompt glyphs per device family for UI |
| [stage-c-spec.md](stage-c-spec.md) | **Final Stage C spec:** sticky weight, the signature intent, the sim shape, tests, draft data, the final stage plan |
| [stage-a-proof.md](stage-a-proof.md) | Stage A proof checklist for QA (integer hit-stop, inert intent fields, bit-identical goldens) |
| [stage-c-tests.md](stage-c-tests.md) | Stage C test scripts and batch checks (weight, signature intent, holds) |
| [feel-schema.md](feel-schema.md) | JSON Schema and cross-reference rules for `data/input/feel.json`, for Tools |
| [intent-queue-plan.md](intent-queue-plan.md) | options considered before Game Design's answers (superseded by stage-c-spec.md) |
| [platform-plan.md](platform-plan.md) | Gamepad in the web build and on desktop (Godot input), rebinding, tests, and mobile's two schemes |

This folder replaces the wave-1 plan for `docs/feel/` (tuning table, input map, risks): its content is folded into `rulings.md` and `input-map.md`.

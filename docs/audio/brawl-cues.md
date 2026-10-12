# Brawl cues: the sounds the three strengths and the launcher need

Owner: Audio and Music. 2026-10-06. A plan on paper, as the EP asked; nothing is built. It answers `docs/design/brawl-second-pass.md` (the three strengths §2, the holds §3, the launcher §3, energy arts in reach §5b). Event names are my proposals, because Encounter's are not final; each row also names what can be used from today's fx stream.

**Density retune:** done on the real flurries (2026-10-11); see the measurement under "Built" below.

**The beat, the nine cells and depth (2026-10-12):** `docs/audio/brawl-beat.md`.

## Built (2026-10-06) and checked against the real C2 events (2026-10-11)

The EP ruled that the launcher's ping is **one sound, heard by both players** (local play shares speakers). Its partners are VFX's mark on the staggered rival, Controls' rumble on closes, and (for the full-charge tick) VFX's flash and UI's ring. It was first built against **staged events**; Encounter's C2 chain (2e0f3b2c, `docs/director/brawl-c2.md`) is the real thing, and the table below is as corrected against it. `audio/tools/brawl_check.gd` stages the real shapes; `audio/tools/host_check.gd` runs real seeded matches. Code: `audio/audio_brawl.gd`; data (every name and number): `audio/data/brawl_cues.json`; recipes: `audio/data/impacts.json`.

| Event (Encounter's name) | Sound | Notes |
| :--- | :--- | :--- |
| `damage` (kind light, medium, heavy: the strength; guard for a guarded blow) | `impact.light`, `impact.medium`, `impact.heavy`; a guarded hit is `impact.guard` (higher for a light blow, lower for a heavy) | The kind is the strength (`strength.kind_is_strength` on since C2). A guarded hit reads its strength from the attacker's `blow` cue (8-tick window, each cue used once), then the damage amount (26 and 60). The energy shot's own damage (kind `blast`) is left to `energy_land`: no impact on top of the bolt's crack |
| a run of lights, and a `stagger` cue with text `flurry` | **flurry mode**: from the third light in a second the light is 2 dB quieter and climbs a third of a semitone a blow (to 3); the closing blow is 3 dB louder | Voice caps by class: light 4, medium 3, heavy 3, guard 3 |
| `launcher_open` (actor may launch, target staggered, n the tick the opening ends; sent only when a launch is ready) | `ui.launcher`: one pitched dry ping, no random spread, at the staggered fighter, priority 95, one voice, on its own `Alert` bus | Ducks Sfx 3 dB for 150 ms and Music 4 dB for 250 ms; an opening under 12 ticks makes none (real openings are 12 or 20) |
| `launcher_close` (sent only after an open; text `used` or `lapsed`) | `used` (his B is thrown) fades the ping out in 40 ms, since the launch's own sound confirms; `lapsed` lets it ring out | |
| `windup` start (`dur` the wind-up alone in live ticks, `n` the landing tick, which also counts the ticks a press spends closing the gap) and end (k 1 thrown, 2 stopped by a blow, 3 lost, 4 a miss) | `windup.medium` (12) or `windup.heavy` (28) by `dur`, stretched by pitch so it peaks as the blow lands (the launcher's B, `dur` 14, is a stretched medium gather); the gather **waits** `n - tick - dur` live ticks for the gap to close, and never plays if a blow stops the wind-up first; k 2 and 3 fade it out | A `dur` under 6 (a light) has no gather. Live ticks come from the `tick` events, so a hit-stop shifts nothing |
| `miss` (actor the swinger; text gave_ground or reach; n the ticks he is open) | `impact.whiff` at the swinger | by text: lower and quieter for giving ground, higher for a reach |
| `double_hit` (8 ticks ahead, n the landing tick, x and y the centre), then the two damage events | `double.charge` now, one `impact.double` at the centre at the landing for the pair | The second hit of the pair is not sounded again |
| the held B, in order: `windup` start (source b, dur 28); `windup` text `charge` at tick 32; `charge_full` at 44; the `blow` cue text `release` (n 4 ticks on); `windup` end | **B's charge**: the `charge` windup starts `charge.hum` (a low drone with a tremolo that speeds up, 0.65 s, covers the longest hold of 38 ticks); `charge_full` is a fixed `charge.tick.heavy`: a lower click with a ring, exact to the tick, on the `Alert` bus, priority 92, no pitch or variant spread | The hum is cut (40 ms) at the release blow, 4 ticks before the landing, or by the `windup` end if a blow or a stagger stopped it. The Y's `charge_full` (source y) is ignored here |
| a light or medium on a heavy that is winding or charging (armour) | the hit as usual, plus a dull `impact.absorbed` under it | A light is always absorbed. A medium is absorbed only after 20 live ticks of the wind-up itself (inside the first 20 it ends the charge, so no armour tick); a heavy and a guarded hit are never absorbed. Armour is read from the `windup` start (`dur` over 20 is a heavy's), so it needs no new event |
| `energy_reach` (text bolt or blast; n the landing tick) and `energy_land` (text bolt or blast; source hit, guard, armour, miss; k 1 the full flash) | blast: `energy.gather` then `energy.blast`; bolt: one crack, `energy.bolt` | A guard is quieter and lower, armour in between, a miss is the air. A mashed bolt: from the sixth in a second 3 dB down and no zap (`energy.bolt.lite`), at most 2 voices. The blast's gather is sized by `n - tick` |
| the same run of lights, from the fifth in a second | `impact.light.lite`: the same click with half the body and tail, 2 dB down, still climbing; the closing blow is the full light again | Added with the C2 retune (below) |

**To hear it.** `audio/preview/brawl-demo.wav` (11.6 s) is the busiest 10 seconds of a real seeded match (`--match=12345`, tick 2105): a flurry with lights and lites, guards, eleven bolts, a heavy's wind-up, one charge (hum, then the full tick) with six lights absorbed, one launcher ping and its duck, over a loop of the 180 BPM metal reference clip. `audio/preview/brawl-demo-staged.wav` (10.2 s) is the staged sequence, kept because a real match rarely has a miss, a double hit or a blast in one window. Both come from `audio/tools/render_brawl_demo.gd` (`--match=SEED` for the real one) through the real mapper; mixed in a script, not a game recording.

**What the real events corrected (2026-10-11).** (1) The empty-name cues the EP saw in `host_check` were the mapper's **stop requests** (cut the hum, fade a stopped wind-up's gather, cut the ping): a cue with no sound and a `stop_group`. They were always legal; the check now accepts them and tallies them as `(stop)`, and still fails a cue with neither a sound nor a group. They had never appeared before because no `windup` or `launcher_close` cue existed in a real match. (2) `launcher_close` says `used` or `lapsed`, not `thrown`. (3) `n` on a `windup` start counts the closing ticks, so the gather is sized by `dur` and waits for the gap. (4) The hum starts on the `charge` windup (tick 32) and is cut by the release blow, not by the landing. (5) The damage kind is the strength now. (6) The energy shot's damage (kind `blast`) no longer gets a threshold impact on top of its own crack.

**Density, measured on real matches (3 seeds of 90 s, the `host_check` line "light knocks ringing together").** About 320 to 345 `impact.light` cues a match (220 a minute; 400 to 450 cues a minute in all). The mix is not crowded: on busy ticks a mean of 1.2 to 1.3 light knocks ring together, the most 3 or 4, and three or more ring on at most 0.3% of ticks. So the voice pool and the light class cap (4) are never the limit, and the count of cues alone is no problem. The retune is the lite knock from the fifth blow in a run (the plan's "loses its tail"): it takes the mean from 1.29 to 1.25 (three seeds) and changes nothing else you would measure, so it is a polish, not a fix. Guard hits are now the second most frequent cue (100 to 136 a match), which the plan did not expect; they are chips and sound as designed.

**Audibility estimate** for the ping against the metal reference clip (800 to 2800 Hz, music normalised to -16 LUFS on a -8 dB bus): the ping sits 5.8 dB above the music, and 9.8 dB with the duck. It is the synthetic reference, so redo it when Suno's files arrive; only the duck depth and the ping level would move.

**Not built:** the Y's full-charge tick (waits for C2b with `charge_release` and `just`), a sound for `burst` start and end (no ask yet), and the low-pass on the music during the duck (needs the music wired).

## 1. The cues (the plan)

| Cue | What the player must hear | From which event (proposed) | Today's stand-in |
| :--- | :--- | :--- | :--- |
| **The launcher ("B now")** | That a launch is open, and that now is the time. Learned in one fight, never a voice line, heard over a dense flurry | `launcher_open {attacker, victim, window_ticks, cause}` when the rival's stagger of 12 ticks or more begins (a flurry's close, a landed heavy, a broken guard, a perfect block, a punished taunt); `launcher_close {attacker, taken}` when the window ends | None (the sim has no stagger event; the `banner` text is not enough) |
| **Light, medium, heavy by ear** | Three sizes of the same world, told apart in a mixed string (X, Y, B in any order) | `hit {attacker, victim, strength: light/medium/heavy, region, guard}` (the `damage` event with `strength` and `kind`, which I already asked for) | `damage.amount` thresholds (26 and about 60), which are guesses |
| **The wind-up** (Y 12 ticks, B 28 ticks) | That a medium or heavy is coming, and which | `windup_start {actor, button: y or b, ticks}`, `windup_cancel {actor}` | None |
| **The full-charge tick** (Y at 24, B at 44) | The exact moment a held Y or B is full, so the just release (4 ticks after) can be timed by ear | `charge_full {actor, button}` and `charge_release {actor, button, just}` | None |
| **The point-blank bolt** (RB + X) | A shot fused to the fist: a flash and a crack, not a punch with a glow | `energy_close_bolt {actor, x, y}` | None |
| **The blast** (RB + Y) | A gathering, then the quickest knock-back in the game | `energy_close_windup {actor}` (or `windup_start` with a kind), `energy_close_blast {actor, x, y}` | None |
| **The flurry's close** | That the run has closed: the stagger has begun (the same moment as the launcher) | covered by `launcher_open`, `cause: flurry_close` | None |

## 2. How each should sound

**The launcher.** A single, **pitched, dry ping**, unlike anything else in a fight:
- **Not an impact.** Every impact is a low thump with a noise crack. The cue is a clean ring: two close partials (about 1.1 and 2.4 kHz) with a hard 3 ms tick at the start and a fall of about 0.25 s. It is the only tuned ring in the fight sounds, so it is learned fast.
- **Not a voice, and not an alert sting.** Same rules as the flash cues: one note, no repeats, no chirp, nothing above about 2.5 kHz.
- **Heard over a flurry** by three means: its register (the flurry is mostly noise below 1.5 kHz and low thumps, and the cue is tuned above that); a **duck**: for 150 ms the impact bus drops 3 dB and, once music is wired, the music bus drops 4 dB and is low-passed at 2 kHz (a sidechain from the cue, so it works over any music); and its **priority**: it sits in critical combat (above beams and impacts) and cannot be stolen.
- **The cue is the window.** It sounds at `launcher_open` and its tail ends about when the window does. If the launcher is thrown, the ring is cut by the launch's whoosh and heavy impact, which is the confirmation. If it is missed, it simply rings out.
- **The same sound for every fighter,** so it means one thing. Not the fighter's family timbre.
- **It also needs a non-sound channel:** the visual cue (Art and VFX) and, on a pad, a short rumble (Controls). I note it here because sound alone is not accessible (Accessibility).

**Light, medium, heavy.** Today there are two impact classes (`impact.light`, `impact.heavy`). The plan is three, told apart by length, body pitch and tail, which is how the ear separates them in a mixed string:

| | X, light | Y, medium | B, heavy |
| :--- | :--- | :--- | :--- |
| Length | about 0.12 s | about 0.3 s | about 0.8 s |
| Body | a quick knock, falling 230 to 85 Hz | a fuller thump, falling about 170 to 65 Hz | the deep boom, 125 to 40 Hz, and a swept shock |
| Tail | none | a short flat crack | debris patter; on the ground, a low slap (the hammer: "the ground answers") |
| Level, relative | about -9 dB | about -6 dB | about -3 dB |
| On a guard | a muffled tap | a dull thud, the guard creaks (chips double) | a glassy crack and a bass drop: a set guard breaks |

`impact.light` and `impact.heavy` exist; `impact.medium` is new and small. A **launch** adds the whoosh and the existing crater or building crash. **Armour** (a heavy's wind-up soaking lights) gets a short dull "absorbed" tick under the light hits, so the player can hear the lights are not working.

**Flurries (the density answer).** A flurry of X is 5 to 10 blows a second. At that rate the sound must read as one run, not a pile:
- the light impact gets a **flurry mode**: after the third blow in a second it drops 2 dB and loses its tail; the voice cap for light impacts is 4;
- a flurry's pace pitches the knock up a semitone over a run (a "climb" that tells the player the run is building toward the close);
- the **close** (the stagger) is the louder, longer hit and the launcher ping.
These numbers are in `cues.json` data, so retuning after a listen is data only.

**The wind-up and the charge.** A wind-up is a rising "gather": filtered noise and a low tone climbing over its length (0.2 s for Y, 0.47 s for B). It is **cut and replaced** by the blow when the blow lands, and stopped with a soft drop if the wind-up is cancelled (a shove, an interrupt). A held charge continues as a hum with a rising tremolo. The **full-charge tick** is the one sound that must be exact: a crisp click with a short ping, **light for Y** (higher, brighter) and **heavy for B** (lower, with a ring), so the two are told apart and the just release can be timed. It plays on the tick of the event, with no fade-in.

**The point-blank bolt and the blast.** They must sound like a second instrument beside the fist ("a mixed string reads as mixed"):
- **Bolt:** a flash and a sharp crack with a short bright zip, no body thump; played at every blow's contact. When mashed (up to 10 a second) the voice cap is 2, the level steps down after the fifth in a second and the zip is dropped, so it never strobes in sound as VFX will not in light.
- **Blast:** the same gathering as a wind-up over 12 ticks, then a heavy whump with a crack, a spill whoosh along the knock-back (about 6 body heights) and a scorch sizzle where it meets ground or sea.

## 3. What I can do with the synthesised set, and what waits

**Can be done now, with our own synthesis (no outside file):** everything above. The impact classes, the wind-up and charge sounds, the full-charge ticks, the launcher ping, the bolt and the blast are all layered recipes of the kind already in `audio/data/impacts.json`, so each is a data row and a short render. They would be stand-ins: good for timing, learning and mixing, not for final texture. The flurry mode and the ducking are mapper and mix rules.

**Waits for Encounter's events:** the launcher, the wind-up, the full-charge tick, the energy arts and the strength-tagged hits all need events the stream does not carry yet. Until then only the `damage` threshold stand-in works. The list above is what I would ask Encounter and Simulation for (names not final).

**Waits for Orb's Suno WAVs:** only what depends on the music. **The launcher's audibility has to be tuned against the real music.** Speed metal fills 500 Hz to 4 kHz, which is where the ping lives, so I cannot set the duck depth and the ping level for good until I can play the cue over the actual files. I can test it today against the 180 BPM reference clip, which has a similar spectrum, and I would set the duck conservatively until then. Nothing else waits for the music: Suno does not make our sound effects, and these cues stay synthesised (or Orb's own recordings if Orb wants more realism later).

**Not covered by sound alone:** accessibility. Every cue here has a visual or haptic partner or must get one.

## 4. Order I would build in

1. The mapper's flurry mode and the three-strength impact classes (with `impact.medium`), once Encounter's `hit` event has `strength`.
2. The launcher ping and its duck (it needs `launcher_open`), tested over the 180 BPM reference.
3. The wind-up and the full-charge ticks.
4. The energy bolt and blast.

## 5. What I need

- **Encounter and Simulation (through the EP):** the events in section 1, with the stagger length and cause on `launcher_open`, and `strength` and `guard` on `hit`.
- **Game Design:** is the launcher cue for the attacker only (a human player who can press B), or for both players in a local match? My default: the attacker, and quieter for the staggered fighter.
- **Controls and Accessibility:** a haptic or visual partner for the launcher and the full-charge tick.
- **Orb:** a listen to the launcher ping once it exists (it is the one cue whose whole job is to be learned by ear).

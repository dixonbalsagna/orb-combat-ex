# Brawl cues: the sounds the three strengths and the launcher need

Owner: Audio and Music. 2026-10-06. A plan on paper, as the EP asked; nothing is built. It answers `docs/design/brawl-second-pass.md` (the three strengths §2, the holds §3, the launcher §3, energy arts in reach §5b). Event names are my proposals, because Encounter's are not final; each row also names what can be used from today's fx stream.

**Held until the three-strength flurries are in:** the retune of today's cue density (about 290 to 345 cues a minute, almost all `impact.light`). The flurry rules below are the plan for it.

## 1. The cues

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

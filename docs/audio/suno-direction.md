# Suno direction: a tongue-in-cheek speed-metal soundtrack

Owner: Audio and Music. 2026-10-04. A short sound bible, the hand-back spec and the list of what I need from Orb. The paste-ready prompts are in `suno-prompts.md`. This replaces the three-direction pitch in `direction.md` section 3 (kept as history) and the 96 BPM time base in section 4.

**Orb, 2026-10-04 (`docs/ep/vision.md`):** the three sketches "were all a little bit too spooky or almost like a Halloween atmosphere"; `sketch-a-town-band` "had the most interesting hook"; Orb has a premium Suno account and wants "a tongue-in-cheek riff-heavy speed metal version of what you gave me already". Suno makes the final music; Orb feeds the files back.

## 1. What I verified about Suno, and what I assumed

I have no Suno account, so I could not open the live Create page. This is what I read on 2026-10-04.

**Read in Suno's own pages (official):**
- Suno's release notes: **v6 launched on 2026-09-09** as three models: **v6** (the flagship, paid users only), **v6-wild** (more varied and unpredictable, paid only) and **v6-mini** (faster, free for everyone). v6 can create from text, audio, images and video, and edit sections in plain language. The notes mention audio upload, cover, extend, replace, stem separation and Studio, but give **no field list**.
- Suno's blog on its terms update (**effective 2026-09-03**): "Songs downloaded from Suno on paid plans remain yours to use commercially or personally." Downloads: free 7 lifetime trial downloads, **not eligible for commercial use**; Pro 20 a month; Premier 60 a month (unlimited for Studio users).
- Suno's help centre, "Exporting from Studio": exports are "high-quality WAV files"; you can export the full song, a time range or the **multitrack (stems)**. It gives no bit depth or sample rate.

**Read in third-party guides (not official; reported, not verified):** the style field takes up to 1,000 characters, the lyrics field 5,000 and the exclude field 1,000 in v6; sliders for Weirdness and Style Influence (both default to 50%), an Audio Influence slider that appears when you upload audio, a new **Variety** slider (set it to 0 to stop v6 rewriting your style tags) and a **Max Mode** switch for songs over two minutes and for covers that must stay close to the source; uploaded audio up to 8 minutes, and generations up to 8 minutes; Studio 2.0 (August 2026) and **Get Stems** on Pro and Premier, up to 12 WAV stems time-aligned to the detected tempo (44.1 kHz in one guide, 32-bit 48 kHz Studio exports in another); section tags in square brackets are now read by v6; and BPM numbers in the style prompt help but are **not obeyed exactly** (no reliable tempo changes inside one generation).

**Assumed:**
- The labels on the Create page match the names above. If they differ, use the closest field.
- There may be a dedicated **Instrumental** switch. I could not confirm it, so every prompt also says "instrumental" and excludes vocals.
- A generation takes **one** uploaded audio at a time (so each block lists a first and a second reference to try separately).
- Orb's plan allows WAV downloads and has Studio or Get Stems. If it does not, we work from full-mix WAVs (section 5 says that is fine).
- Suno lets you upload audio you own the rights to. Our reference clips are our own, made by our own tool, with no outside audio.
- Songs come out as stereo 44.1 or 48 kHz.

**Format of the prompts** therefore follows the common structure: a Style of Music text (genre and mood, tempo, instruments, production, structure), an Exclude text, and the Lyrics box holding bracketed structure tags only. Treat my format as a first draft, and tell me what the page really has so I can fix it.

## 2. Why the three sketches read as Halloween

This is my reading of the files, not something Orb confirmed. Everything on the list is in the sketches' own data (`audio/data/sketch_*.json`, `audio/synth/music_sketch.gd`).

| What I did | Why it reads spooky |
| :--- | :--- |
| D minor (Dorian and Aeolian) with a plan to darken to Phrygian dominant | Minor with a flat second is the usual scale of a horror score |
| A low "edge" layer: a chromatic line that rocks a semitone either side of the bass note | A semitone wobble in the bass is the classic creeping-threat figure |
| A quiet overture of single high bell notes over a drone, and a snare roll into a one-bar silence | Sparse high bell notes (a glockenspiel, an FM bell, modelled pans) are a music-box sound, and the silence adds suspense |
| A held low drone and slow pad swells (the chord bed) | Sustained drones and slow swells make a haunted-house bed |
| Inharmonic metal and glass sounds (modelled pots, pans, glass in sketch C), a hummed "oo" voice and breathy textures | Inharmonic partials and a ghostly hum read as eerie |
| 96 BPM, with the drums in half time at the peak | A slow pulse feels ominous, not cheeky |
| Mono, 13 kHz, so no top end: no cymbal shimmer, no guitar bite | A dull, hollow sound is cold |

What I kept of what worked: **the hook**. It is two rising fourths that end open, played by a brass band, and it works because its shape is sunny (a rising fourth is a fanfare) even when the harmony around it was dark. So the plan is to **keep the hook and the brass band, and change everything around them**: a bright major sound, fast, loud and full, with the humour made on purpose.

## 3. The sound

### 3.1 Tempo
- **150 to 210 BPM**, the speed-metal range. The reference clips are at 150, 180 and 210 BPM.
- **One tempo for the fight ladder: 180 BPM**, so the four acts, the last stand and the finisher can crossfade on a bar line. The last stand is **half-time at 180** (a heavy beat that feels like 90) and the fold is **90 BPM**, so both share the same bar grid. A bar at 180 BPM is 1.33 s.
- Other cues have their own tempo: title 160, the Protagonist 170, the rival 150, victory 150, defeat 80 slowing to 60.
- Suno does not obey a BPM exactly, so pick takes within about **2 BPM** of the target. `music_check.mjs` measures it.

### 3.2 Key and mode
- **E**, because the low E string gives the loudest, most open power chord. Mode: **E major, played Mixolydian** (chords E, D, A, B: the flat seventh gives the swagger, and it is never dark). The hook is notes 5, 1, 4 of the key (B, E, A), then 1, 4, 5 (E, A, B).
- The rival has his own key, **A**, with a bluesy flat seventh. Still major, still bright, so he sounds cocky and not creepy.
- Victory modulates up two semitones, **once**, for the final chorus.
- **Never:** a flat second, a tritone, a chromatic creeping line, the harmonic minor, diminished chords, and minor keys as the home key.

### 3.3 Instrumentation
- Two **rhythm guitars**, double-tracked and wide, high gain, tight. **Bass guitar** doubling the riff. **Drums** with a double kick, a crisp snare on two and four, bright hats and crashes.
- **Twin harmony lead guitars** that play the hook in thirds.
- The **brass band** from the old sketch: **tuba**, trombones, cornets and trumpet. They double the hook and play oompah breaks and fanfare answers.
- Optional later: a short **gang shout** ("hey!") at the last chord. The first pass is instrumental.
- **Not here:** strings, choir, organ, synth pads, bells and glockenspiel, piano, a theremin, a hummed voice.

### 3.4 Riff language
- **The gallop:** long, short, short (an eighth and two sixteenths) on every beat, palm-muted, with the double kick in unison.
- **Pedal-point riffs** on the low E with the chord moving above them (E, D, A, B).
- **Call and response:** the riff states, the hook answers, the riff states again.
- **Tremolo-picked power chords** for the peak (acts 3 and 4).
- **Harmonised scale runs** as fills, in thirds, never chromatic.
- **A half-time breakdown** (a heavy slow chug) where the hook slows into an anthem.
- **Dotted stabs** for the rival, stiff and exact.
- **Unison hits** where the whole band and the brass land on the one together.

### 3.5 What tongue-in-cheek means in the arrangement
Humour here is musical. Commit fully to the sincere melody and the huge sound, and let the contrast do the joke. The same rule as the game's tone (`vision.md`): sincere, funny, a little graphic.
1. **The oompah break.** Once per cue, the metal stops dead and a tuba plays a polite march with a snare cadence for one or two bars, then the whole band crashes back in. This is the signature gag.
2. **Oversized brass.** A trumpet fanfare answers a guitar solo as if the two were equals.
3. **Deadpan stops.** A full bar of silence before the final chord. A sudden stop mid-riff.
4. **Mock-epic builds.** A snare cadence and rising chords that lead to an absurdly large hit and a crash.
5. **Cheerful heroism.** The melody is bright and open and the drums are brutal. Never a sneer at the tune.
6. **The one gear change.** A key lift of two semitones for the victory chorus. Once, and only there.
7. **Sagging.** The defeat cue slows and droops on purpose, a little pathetic and never scary.

Not tongue-in-cheek: sound effects, samples, spoken jokes, cartoon noises, quoting another tune, or any wink at a named act. The humour must work with the sound off a screen and without knowing any other music.

### 3.6 Production
Dry, tight and punchy modern metal production. Guitars wide and clear, drums natural and loud, a clear low end with the tuba in the low mids, bright cymbals, **little reverb**, no pads, no ambience. Plenty of dynamic range between sections, so the oompah break is a real drop. Instrumental. A full stop at the end, never a fade-out (we choose the loop points ourselves).

### 3.7 The do-not list
- No real **artist, band, song, game, show or franchise names** in any prompt, file name or tag. Describe the sound.
- No melody, riff or chord loop quoted from any existing music. The hook is ours.
- No spooky colour: minor keys, flat seconds, tritones, bells, choirs, organs, music boxes, whispers, drones, reverb washes.
- No vocals or lyrics in the first pass (one risk less: lyrics are text we would have to clear and translate).
- No sound effects or voice samples inside the music.
- No fade-outs.
- No tempo changes inside a loop.
- No upload of anything but our own reference files.

## 4. The cues (what the game needs and where each plays)

| Id | Slug | Plays | BPM | Loop |
| :--- | :--- | :--- | :--- | :--- |
| M01 | title | Title screen and menus | 160 | yes |
| M02 to M05 | fight-1 to fight-4 | The four acts of a fight (act 2 at about 1:30, act 3 at about 3:15, act 4 at about 5:00; see `spec-wounds.md` on the acts) | 180 | yes |
| M06 | last-stand | A fighter on the brink | 180 half-time | yes |
| M07 | fold | The proving ground after the fold | 90 | yes |
| M08 | finisher | A finisher's cinematic | 180 | no (a sting) |
| M09 | victory | The winner's result | 150, key lift | no |
| M10 | defeat | The loser's result | 80 slowing to 60 | no |
| M11 | theme-protagonist | His intro card and results | 170 | yes |
| M12 | theme-rival | The Anti-hero's intro card and results | 150, key A | yes |

The Empress and the Cyborg do not need themes until their slices exist. When they do, the same recipe applies: the hook in their own colours (a silky, theatrical parade; a bright, mechanical hold-music strut) and their own keys.

**What the game's music system needs from the files** (this is the simpler scheme that fits Suno's output, replacing the eight-stem 96 BPM plan):
- **Full mixes, as the main route.** The four fight acts share **180 BPM and the key of E**, so the game can crossfade between acts on a bar line (two bars) and switch to the last stand on the next bar. This is the intensity ladder: one cue per act, ordered by how much is going on.
- **Two takes per act if Orb can** (A and B), so that a long fight alternates between them and does not hear one 40-second loop all match.
- **Stems, as an upgrade** if Orb has Studio: drums, bass, rhythm guitars, lead and brass for the fight acts, so the game can drop and add layers (for example, the brass only from act 3, the lead only while a fighter leads). Stems must be time-aligned and the same length as the mix.
- **Stingers** (finisher, victory, defeat) as short files with a clean silence before the build and a clean stop at the end, so the big hit can be cued to land on the last blow.
- **Hit-stop and slow motion.** The mix rules in `direction.md` section 6.5 stand: audio follows the sim and never changes its timing. In the KO slow motion the music is low-passed and dropped in pitch by the player, so the files need no special version.

## 5. The reference clips

Four files, to upload as audio with a prompt (the blocks say which):

| File | What it is |
| :--- | :--- |
| `audio/preview/sketch-a-town-band.wav` | The original hook, as the old brass-band sketch played it. Dull (13 kHz mono) and in D minor, so it is the **tune**, not the sound. Use it when Suno loses the melody |
| `audio/preview/suno-reference/suno-ref-riff-150bpm-E.wav` | The hook as a speed-metal riff, 150 BPM, E, 12.8 s |
| `audio/preview/suno-reference/suno-ref-riff-180bpm-E.wav` | The same at 180 BPM, 10.7 s: **the main reference**, for the fight ladder |
| `audio/preview/suno-reference/suno-ref-riff-210bpm-E.wav` | The same at 210 BPM, 9.1 s: a feel reference for the fastest gallop |

Each riff reference is eight bars: two of gallop riff alone, two of the hook on twin harmony leads, two of the hook an octave up with brass doubling, one **tuba oompah bar** (the joke), and one huge chord with a crash. They are made by `audio/tools/render_suno_refs.gd` from `audio/data/metal_ref.json`.

**They are synthesised, so they are rough:** the guitars are distorted saw waves, not real amps, and the brass is a stand-in. Their job is to tell Suno the **rhythm, the harmony, the arrangement and the joke**, not the sound. Mono, 22.05 kHz, 16-bit, so they are small (0.4 to 0.6 MB). Not listened to by a person: I checked them by level per bar, a spectrogram and the tempo tool (it measured 150, 179 and 209.5 BPM).

**Using them.** Upload one reference per generation and set **Audio Influence** around 50 to 60 (low enough that Suno plays its own guitars, high enough that it keeps the shape). Once Orb likes a take, **upload that take instead of our reference** for the next cues in the same set, with the same style text, so the guitar tone, the drum sound and the brass stay coherent across the whole soundtrack (this is the coherence recipe: house style text, one reference, then your own best take as the reference).

## 6. The hand-back

**Where:** drop files into **`audio/music/incoming/`**. The folder has a `.gdignore`, so Godot does not import the raw WAVs. Audio then checks them and moves the chosen ones on (`audio/music/README.md`).

**What:**
- **Format:** WAV as Suno delivers it (PCM 16, 24 or 32-bit or 32-bit float, stereo, 44.1 or 48 kHz). Do not convert it, do not normalise it and do not export an MP3 (MP3 is lossy and Godot's web build would then re-compress it). If WAV is not available, tell me what is.
- **Naming:** `M02_fight-1_t01_180bpm_E.wav` is cue id, slug, take number, the tempo you were aiming for and the key. For stems add `_stem-drums`, `_stem-bass`, `_stem-guitars`, `_stem-lead`, `_stem-brass` and so on, and keep each stem the same length as the mix.
- **Sidecar:** a text file with the same name (`M02_fight-1_t01.txt`), made from `audio/music/sidecar-template.txt`, holding Legal's record (`docs/legal/suno-music.md`, RL-071): the model version, plan tier, download date, song link or id, the exact prompt (Style, Exclude and structure tags) and sliders, the names of the uploaded clips, who chose the take and what was edited, a checksum of the original, "metadata kept: yes", and the listen and music-recognition result. `node audio/tools/music_check.mjs FILE.wav --write-sidecar` writes the checksum, the chunk list, a copy of the original's metadata and the "metadata kept" line for you (it never writes to the audio).
- **Every original download stays untouched in `audio/music/incoming/`.** Nothing is ever edited in place, because Suno's terms forbid removing or altering metadata. Only a processed copy is shipped (a normalised, trimmed or encoded copy made from the original); the original and its checksum are the record.
- **Do not edit the audio** before handing it back. We choose loop points and store them as data, not by cutting the original.
- **The shipped copy.** Legal has cleared shipping a **processed copy** (gain, a loop cut, an OGG encode) on five conditions (`docs/legal/suno-music.md`, follow-up to RL-071). **The hold on wiring Suno files into the build is lifted** once the conditions below are in the pipeline:
  1. **No concealing purpose.** No watermark-removal or detection-evasion tool, plugin or setting is ever used on a Suno file.
  2. **Keep the untouched original and the origin record** (the sidecar) for every shipped file.
  3. **The notice and the store disclosures say the music is AI-made with Suno** (`audio/music/NOTICE.txt`; Steam and itch.io).
  4. **Processing stays ordinary:** gain, a cut, an encode. No re-synthesis, no pitch or time tricks, no "cleaning" or restoration tools.
  5. **The original's metadata is copied into the sidecar**, because the shipped copy may not carry it. `music_check --write-sidecar` does this (LIST/INFO tags, id3 and any other chunk, as text and base64).

**What I do on receipt:**
1. `node audio/tools/music_check.mjs FILE.wav --bars 32` reports the format, the integrated loudness, the approximate true peak, the tempo (and whether it drifts), and the best bar-aligned loop points.
2. **Loudness target: -16 LUFS integrated, true peak -1 dBTP or lower**, applied as a gain only. Suno files are usually louder, so the gain is usually negative; if a file would clip after gain I lower it, I do not limit it. Cues in one set stay within 1 LU of each other.
3. **Loop points** are chosen on the bar grid for the steadiest stretch of 30 to 60 s (stingers are cut, not looped) and written in `audio/music/loops.json` (cue, file, tempo, loop start and end in samples, bars, gain). A take whose tempo drifts by more than about 2% is not loopable.
4. **Encoding for the game:** OGG Vorbis at about quality 4 (roughly 128 kbps, about 2 MB for a 2-minute loop), so about **20 MB for the whole set** of 12 cues. That is a proposal for Performance to confirm for the web build. Godot cannot encode OGG, so the encode is an offline step (see NEEDS FROM EP).
5. The raw WAVs are **large** (a 3-minute stereo file is about 30 MB at 16 bits). They should **not** go into git; the repo keeps only the encoded OGGs and the loop data.

## 7. What I need Orb to decide

| # | Question | My default |
| :--- | :--- | :--- |
| 1 | Is E, 180 BPM for the fights, 90 for the fold and the last stand in half-time the right scheme? Or a different tempo, say 170? | E and 180 |
| 2 | Instrumental only, or gang shouts ("hey!") at the big chords too? | Instrumental now; shouts later if you want them |
| 3 | How loud should the jokes be? A single oompah break per cue is the dial's middle | One gag per cue |
| 4 | Which to generate first? | M01 title, M02 fight-1 and M05 fight-4, to hear the two ends of the ladder, then fill in M03 and M04 |
| 5 | Can you make two takes of each fight act (A and B)? | Yes if it is cheap: it halves the repetition |
| 6 | Which Suno plan do you have (Pro or Premier), and do you have Studio and Get Stems? | We work from full-mix WAVs either way |
| 7 | Is the rival's key (A) and his stiff, pompous strut right, or should he be closer to the Protagonist's sound? | A, pompous |
| 8 | Will you add something human to the music, for example hum, tap or sing a melody idea we can note down, or tell us your choice of takes and edits? (Legal's advice is that music themes need real human authorship; see NEEDS FROM EP.) | Your selection and direction count; a hummed idea would help |
| 9 | May Audio choose the loop points and do the loudness work, as above? | Yes |
| 10 | Do the Empress and the Cyborg get themes now or when their slices land? | When their slices land |

## 8. Risks

- **Suno may not obey tempo or key**, so a ladder at the same 180 and E may need extra takes. The check tool tells you fast.
- **The jokes may not survive.** If the oompah break keeps vanishing, we can generate the break as a separate short cue and cut it in, or keep the metal and add the tuba stinger in the game.
- **Spooky creep.** If a take sounds spooky, check the exclude text and the reference clips first: they are major and fast on purpose.
- **Coherence.** Twelve cues from twelve generations can sound like twelve bands. The house style text and the use of one best take as the next reference are the guard; I will check each file by ear with Orb.
- **Size.** Raw WAVs are large and must stay out of git.
- **Not heard.** The reference clips have not been listened to by a person.

## 9. Open questions for Legal (through the EP)

**Answered by Legal on 2026-10-04: `docs/legal/suno-music.md` (RL-071), conditional.** In short: generate and download on a paid plan within the monthly cap and keep each original untouched; the music is **not** under the project licence (see `audio/music/NOTICE.txt`) and is never described as human-made; do not register the tracks in Content ID; disclose AI-made music on Steam and itch.io; listen to each final and run a music-recognition check; Orb's direction and selection help and a human melody is optional. Still open with Legal: whether OGG encoding and a loop cut are compatible with the no-altering-metadata term. The original questions follow, for the record.

I do not decide any of these.
1. **Which plan and which downloads count.** The terms update says paid-plan downloads are yours to use commercially, with monthly download allotments (Pro 20, Premier 60, unlimited for Studio users per Suno's blog). Do the takes we do not use count, and does the cap limit how many cues we can ship?
2. **Ownership and copyright.** Suno says the user owns the output but does not guarantee that copyright arises in it. The licence advice (`licence-recommendation.md` section 8) says purely AI-made output is not protected in the US. What licence statement can we put on `audio/music/` (CC BY 4.0, CC0 or none), and what does Orb's choice of takes and edits add?
3. **Open source.** Do Suno's terms allow the outputs to sit in a public repository and in a game distributed under an open licence?
4. **Human authorship.** The licence advice says music themes need real human authorship. The hook and the references are made by Audio (an AI session) and Suno makes the final audio. Is Orb's direction and selection enough, or does Orb need to supply a melody?
5. **AI disclosure.** Steam asks about AI-made content that ships, and itch.io has a generative-AI tag with an audio sub-tag. Music from Suno must be disclosed.
6. **Training data.** Press reports say v6 is trained on licensed music. Legal may want Suno's own statement.
7. **Origin rows** for each file: tool, model (v6), date, prompt location, plan tier, song id. The sidecar file carries them.
8. **Uploads.** Our reference clips are procedural and our own. Confirm Suno's upload terms are satisfied by that.

## 10. Files

- `docs/audio/suno-direction.md` (this), `docs/audio/suno-prompts.md` (12 prompt blocks, generated with exact character counts).
- `audio/preview/suno-reference/suno-ref-riff-{150,180,210}bpm-E.wav`, from `audio/synth/metal_sketch.gd`, `audio/data/metal_ref.json` and `audio/tools/render_suno_refs.gd`.
- `audio/tools/music_check.mjs`: the hand-back checker (format, LUFS, true peak, tempo, loop points). A dev tool, Node standard library only.
- `audio/music/README.md` and `audio/music/incoming/` (the drop folder, with a `.gdignore`).

# Our babble voice and Gemini's mumble-speech suggestion (paper, 2026-10-16)

For Orb, in plain words. Written by Audio and Music. **Nothing has been rendered or changed**; this is the comparison and the plan, and the previews wait until the machine is free. I cannot listen, so every claim about how it would *sound* is a guess until you hear the A/B clips in section 5.

**Built and rendered 2026-10-17 (the EP's go):** the Cyborg's growl and blip, the Empress's booming laugh and baked shimmer, a lurching-rhythm option and a few small voice settings are in the babble code (all off for the current voices, whose plans are byte-identical); the A/B voices are in `audio/data/babble_ab.json`; the four reels and their answer sheet are in `audio/preview/ab/`; Orb's page is `homework/34-voices-ab.md`. One find on the way: **"Hahaha" was not parsed as a laugh** by the current voices (only forms like "Ha!", "Ohoho" and "Ahaha"), and now is.

**The short version.** Gemini's idea and ours are the same idea (a little burst of "mumble" for every few letters, the pitch following the punctuation, a different voice for each fighter, as in Animal Crossing and Banjo-Kazooie). Ours already does it, and does more: it follows the text exactly as it appears, has moods, knows laughs, and sounds the same on every replay. What Gemini adds that is worth taking is mostly **colour** (the Empress's doubled shimmer and booming laugh, the Cyborg's growl with a synthetic blip, snappier syllables for the Protagonist and the Rival), plus a trick for making the babble cut through a fight. The advice I would not take is to build the colour out of live sound effects on a bus for every fighter, because of what they cost on the browser build and old laptops, and because **we can bake the same colour into our sounds ahead of time for free.** That is the hybrid.

## 1. What we already do, and where Gemini's version differs

| | Gemini's suggestion | What we have | Which is better for us |
| :--- | :--- | :--- | :--- |
| **A burst every few letters** | One every 2 to 3 characters, at a set pace per fighter (0.055 to 0.085 s) | One every 2.4 to 3.2 letters of a word (up to four to a word), paced by the same clock that reveals the caption, so each burst lands as its words appear; a fighter's own minimum gap keeps it from chattering | **Ours.** A fixed pace drifts from the text. Theirs is a good *source of numbers* for how fast each fighter should feel |
| **Pauses at punctuation** | 0.15 s for a comma, 0.3 s for a full stop | 0.14 s for a comma, 0.26 s for a full stop, 0.3 s for an ellipsis | Same thing |
| **Pitch from punctuation** | The last one or two syllables: a question rises, an exclamation spikes, a full stop falls | A *contour*: a question rises over its last four syllables (up to 6 semitones), an exclamation punches its last word, an ellipsis trails off lower and quieter, a full stop falls, a comma lifts, an ALL-CAPS word is accented | Ours is the bigger idea; sizes are in the same range |
| **Replay-identical** | `AudioStreamRandomizer` picks at random each time it plays, using the engine's own random numbers, which we cannot tie to the match | Every choice is a pure function of the line, the mood and the match's seed (and our audio never touches the game's own random numbers), so a replay speaks the same babble, and a clip shared online sounds the same to everyone | **Ours, and not negotiable**: a replay that mumbles differently the second time is a bug, and the online rollback later needs it |
| **Sample pools against synthesis** | A pool of 6 to 8 recorded or made syllables per fighter, played at a random pitch | About 60 short syllables per fighter *made from a voice model* (breath, vowels with real formants, a nasal), so the voice has a vowel for each letter and a wide choice | **Ours has the wider choice** and needs no recording, no file and no licence; a pool of 6 to 8 repeats audibly. Theirs is easier to get a *character* from by recording, which is the one place a recording helps (section 4) |
| **Colour by live effects on a bus** | A bus for each fighter with a compressor and equaliser; chorus and reverb for the Empress; bitcrush and a slapback for the Cyborg | The colour is **baked into the syllables when they are made** (the Cyborg's 6-bit crush and stutter, the Empress's brighter vowels); one shared Voice bus, plus a muffled one for thoughts and for underwater | **Baked is cheaper and identical every time; live is easier to tweak by ear.** Hybrid, below |
| **Laughs** | Parses "Hahaha" and "Gahaha" and switches to a pool of deep booming laugh syllables | Parses laughs ("Ha!", "Ohoho") into a run of pulses made for that fighter, a grunt after an exclamation and a sigh after an ellipsis | Same idea. **Theirs has a better Empress laugh** (low and booming against her silky speech), and "Gahaha" is a spelling we should parse |
| **Mood** | One special case: the Rival's "!" widens his pitch | Eleven moods (neutral, smug, angry, hurt, desperate, laughing, playful, respectful, grim, thought, cracked), each changing pitch, tempo, lilt, accents and grunts, driven by Narrative's mood tags; the Anti-hero's cracked mask is a voice-specific mood | **Ours.** Nothing in theirs replaces it |
| **The character's numbers** | Pitch ranges, syllable lengths, tempo and pitch jitter per fighter | The same kinds of numbers, in data, per fighter | Theirs are a **good second opinion**; the differences are the list in section 2 |

## 2. What I recommend taking, and what to keep

**Take (all of these are data and baked sound, no live effects):**

1. **The Empress's colour, baked.** Her syllables are rendered as two voices a hair apart (the "chorus" Gemini asks for, so she sounds like "we") plus one faint early reflection (so she sounds larger than the room). Zero run-time cost, and it works on any machine. **And her booming laugh:** a second, low laugh ("Gahaha") next to her bright one, used when a line spells it that way or her mood is cruel.
2. **The Cyborg as a growl plus a blip.** He is now a ravenous bio-mech, a demon stomach bolted into a robot. His voice should be a low wet growl (85 to 115 Hz, a lip-smack and a swallow in it) with a short synthetic blip after some of the growls, a lurching rhythm (a quick pair, then a longer hitch), wide unsteady pitch, a baked metallic comb (a 12 to 18 ms echo) and a bit-crush. Today he is "bright and mechanical" with only four syllables, which is the old waiter robot. A stomach rumble and a chew would be new little sounds to punctuate his pauses (the sound plan names a munch, but none is built; he has the same four effort, pain and sigh sounds as everyone).
3. **Snappier syllables for the Protagonist and the Rival, to test by ear.** Gemini's syllables are much shorter (55 to 75 ms and 40 to 55 ms) than ours (110 ms and 85 ms), and the Rival's pitch is higher (125 to 155 Hz against our 95). Animal Crossing and Banjo-Kazooie both use *short* blips. I do not know which feels better in this game, so it is the first thing in the A/B.
4. **A little overlap for the Empress**: each syllable starts slightly before the last one has died away (legato), for her drawl.
5. **A shared compressor on the Voice bus, and the sound effects ducking under it.** Gemini's compressor is the useful idea in the bus plan: make speech cut through a fight. Rather than a compressor on each fighter, one compressor on the Voice bus, and a **side-chain** from the Voice bus to the Sfx and Music buses, so the effects dip about 3 dB while anyone is speaking and come back after. It is one effect on each of three buses, not eight.

**Keep:** the seeded plan (replay-identical), the caption clock, the moods and Narrative's mood tags, the laugh, grunt and sigh punctuation, the thought style (quiet, breathy, muffled), the shout style, no sample files, no licence questions, no engine randomiser.

**Do not take:**
- `AudioStreamRandomizer` (it breaks replay-identical babble);
- a **live reverb or pitch-shift** on the Empress's bus, or a live distortion on the Cyborg's (see the cost below; the baked versions do the same job);
- a bus with four or five effects *per fighter* (it is not cheaper than ours in any way, and the Voices volume slider needs one bus anyway).

One technical note: the suggestion's bitcrush uses a mode name (`MODE_DECIMATE`) I do not believe Godot has; its real bitcrush is the Distortion effect's lo-fi mode. It does not matter if we bake the crush, as we do now.

## 3. What it costs, on the browser and on an old laptop

I **have not measured** any of this; these are my estimates and the way I would check them.

| | Run-time cost | Memory and load |
| :--- | :--- | :--- |
| **Baked colour** (the hybrid) | None. The clips are rendered once, as the babble bank already is; a line is a few play calls | About twice the render time for the Empress's doubled syllables, a fraction of a second once at load, and the same bank size (about 150 KB a fighter at 12 kHz) |
| **One shared compressor, and the side-chain on Sfx and Music** | Small. A compressor is among the cheapest effects | None |
| **A live reverb, chorus, pitch shift or distortion per fighter** | Each runs on every block of audio, every frame, whether or not anyone is speaking, unless the engine switches an idle bus off; the browser build mixes on the main thread, where a heavy effect costs frames. A pitch shift is the heaviest (it works on the sound's spectrum) | Small |

**The check, for when the machine is free:** the web build under Tools' launcher on the weakest laptop, four fighters speaking at once with the live effects on and then off, and the frame time compared. If the live chain costs nothing measurable I could revisit it; I would still bake the colour so it is identical every time.

## 4. Orb's own recordings, as an optional warm layer (my route B)

Our babble is made from a voice model, and it can sound a little clean. The earlier plan (`grunts.md`, route C) was that a real recording could sit *underneath* the synthesis to warm it, and that is the only place a recording is worth its cost:

- **What:** about 30 minutes of Orb with a phone under a duvet or in a wardrobe (the take list is in `grunts.md` section B): a belly laugh, a short laugh, a cruel laugh, a cackle building, a wheeze, a growl, a sigh, a hum, a snort, lip smacks, swallowing, biting a cracker or a stick of celery.
- **How it would be used:** cut into short **grains** (20 to 40 ms; breath, a lip smack, a swallow, a bit of a laugh) and played *under* the made syllables at about 14 dB down, each fighter's grains processed to suit (pitched down and slowed for the Rival, doubled and brightened for the Empress, crushed and gurgled for the Cyborg). The Empress's booming laugh and the Cyborg's munch are the first beneficiaries.
- **Which grain plays** is chosen by our seeded plan, not by an engine randomiser, so a replay is still identical.
- **Size and cost:** about 40 grains a fighter, 30 ms each, is under 60 KB a fighter and costs one extra play call a syllable.
- **The price:** Orb's time, a quiet room, and **Orb's voice becomes public with the repository** (Orb is known by a pseudonym; heavy processing hides a voice but never fully). It would be logged as human-made, Orb as the author, with Orb's written OK to publish and a licence Orb chooses; Legal reviews it. Entirely optional, off unless Orb wants it. Nothing in the hybrid depends on it.

## 5. A/B previews to render later (when the machine is free)

**What gets compared.** The same five of Narrative's preview captions for each fighter, in the same moods, in this order:

| Letter | What it is |
| :--- | :--- |
| A | **Ours as it is now** |
| B | **Gemini's numbers**, played with the same seeded plan: the shorter syllables, the fighter's pitch ranges, their tempo and jitter, their profiles for the Empress and Cyborg (the live bus chain approximated *offline* by our own simple versions of a chorus, comb, bitcrush, EQ and reverb, because a headless run cannot run the engine's real effects) |
| C | **The hybrid in section 2**: our plan and moods with the baked colour, the new Empress laugh, the Cyborg growl and blip, and the snappier syllables |
| D | **C with Orb's grains underneath** (only if Orb records; until then it is left out) |

**How it is delivered.** One reel for each fighter, about 25 seconds, the variants in a **shuffled order** with a one-second gap and a short click between them, and a separate sheet that says which letter is which, so Orb can choose by ear without knowing. About 0.6 MB a reel at the babble's own 12 kHz, 2.4 MB in all, into `audio/preview/babble-ab/`.

**Checks that go with it:** the plan stays replay-identical (`babble_check` for A and C; B uses the same plan); the caption clock still matches UI's (`babble_check` compares them); and the Cyborg's new lurching rhythm is checked not to run faster than the caption it speaks with.

**The second step, after the ears:** the live chain on the web build (section 3), and Orb picks the winner per fighter, since one fighter's B may beat his A while another's C wins.

## 6. Which voices need re-tuning for the new characters

| Voice | Why | What changes (all data) |
| :--- | :--- | :--- |
| **Cyborg** (most) | The waiter robot is gone; he is a ravenous bio-mech | New growl syllables, a blip event, a lurching rhythm, lower and wider pitch, a baked comb, a laugh that is a wet gurgle with a blip; his lexicon grows from 4 syllables |
| **Empress** | "We", petitioners, a booming laugh | The doubled shimmer, a legato overlap, the second low laugh, slightly lower pitch (240 to 310 Hz against 280) |
| **Rival** (the Anti-hero's voice) | Clipped, cold, surgical | Test the faster, higher, staccato version (B) against ours; keep the cracked mood for when his mask slips |
| **Protagonist** | Warm and bouncy | Test shorter syllables; keep the open vowels and the chatty rhythm |

The voices are keyed by the fighters' roster ids (`PROTAGONIST` and `RIVAL` today, the others when they join), never by their display names, so a renamed fighter never changes a voice.

## 7. What I need from you, Orb

1. **Is the hybrid worth previewing?** If yes, I render the A/B reels when the EP says the machine is free.
2. **Do you want to record the grains (section 4)?** Not needed for the A/B. If yes I write you the exact take list and how to perform each one.
3. **Whose ears pick?** Yours, per fighter, from the shuffled reels.

## 8. Sources and licence

All of this stays synthesised by our own code from numbers in data: no sample, no recorded voice, no third-party file or code, no audio model, and nothing taken from Gemini except ideas and numbers, which are facts about sound and not a creative work. Orb's recordings, if any, are a separate, optional, human-made input with their own log row. Licence: the repo's, as it settles.

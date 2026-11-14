# A5: Audio & Music

Leads: A-AUDIO-02
Supports: none

Goal: A tester hears a quiet background under the fight, hears a building crack and come down, and hears the menu answer each move, on a Steam Deck's own speakers.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5; the A-AUDIO-02 line of "Rows proposed smaller for Alpha"; decision 21); `docs/audio/direction.md`; `docs/audio/biomes.md`; `audio/audio_cues.gd` lines 80 to 96; `audio/audio_moments.gd` lines 37 to 58; `audio/audio_world.gd` lines 104 to 124; `audio/data/world_cues.json` (the note and `enabled`); `audio/data/mix.json`; the record of Orb's listening pass from A2 (A-AUDIO-03), which the EP will send.
- A-AUDIO-02: no sound exists for a building being damaged or collapsing, bystanders scattering, the gravity well, or any menu action, and the fight has no ambience or music bed in any build. Evidence: `audio/audio_cues.gd:85-94` (the events consumed: damage, cue, crater, flash; none for a building); `audio/audio_moments.gd:37-58`; `audio/audio_world.gd:106-124`; `audio/data/world_cues.json:4` (the biome beds are parked: `"enabled": false`). Risk on the row: new cues may need sim events that do not exist for buildings, so check the event feed first.

You own: `audio/`, `docs/audio/`.
- The menu calls your sound from UI's code: tell the EP the one hook UI must call (name, when, arguments). Do not edit `ui/`.
- If the sim's event feed carries nothing for a building's damage or collapse, do not add an event: say so under NEEDS FROM EP. A new sim event would change the state fingerprint and cannot land in A5.

Acceptance criteria:
1. (A-AUDIO-02, the smaller version proposed for Alpha) One quiet background bed plays under every match and ducks under the fight; a building being damaged and a building collapsing each have a sound read from events the sim already emits; menu move, choose and back each have a sound. Bystanders, the gravity well and music are left out and listed in `docs/audio/` as after Alpha. Full version if Orb declines the proposal: all of the row at M, adding bystanders scattering, the gravity well and a music bed.
2. (A-AUDIO-02) Before any sound is made, a short page in `docs/audio/` lists which existing sim events will drive the building sounds, with the file and line where each is emitted, or says that none exists. Checked by: the EP reads it.
3. (A-AUDIO-02) The new sounds are data rows on the existing synths, with levels in the mix data, and each new or changed data file validates against its schema in `tools/schemas/`. Checked by: the data job in CI green on the commit.
4. (A-AUDIO-02) The audio checks pass headless with the new cues on, and a scripted match with a building collapse logs each new cue at the tick of its event. Checked by: the output saved as small text under `docs/audio/runs/<sha>/` (CD-22).
5. (A-AUDIO-02) Proved by ear, not only by a check: the sounds are heard on a Windows desktop build and on Linux (the proof from A-AUDIO-04 is re-used), and Orb listens to the bed, a collapse and the menu in the A5 build and says yes or names what to change. Checked by: Orb's words, recorded verbatim by the EP. Orb's last word on sound was that the crackles sounded bad, so nothing ships on a check alone.
6. (A-AUDIO-02) The bed adds no hitch: loading and the first second of a match are no slower than on the A4 build. Checked by: Performance's loading figure, pointed to by path.

Constraints:
- Tokens: about 1.2M at the register's class (M); about 0.25M (S) if Orb accepts the smaller version. Estimates.
- State hash: no change. Sound reads the sim's events and never writes the sim.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; any browser listening page is opened only through Tools' launcher; check nothing you started is still running before you end a turn.
- Determinism: cue choice uses the sim's seeded values or its own seeded stream, never the wall clock; numbers live in data; a change to a data file's shape updates its schema in `tools/schemas/` in the same commit.
- Originality: every sound is synthesised or recorded by us; no sample, melody or effect from an existing game or film; any AI-made audio needs Legal's clearance of the tool's terms first, and the AI disclosure covers it.
- Orb's rules: Orb found the brawl's sounds "a little too high pitched" and "tinny" (`docs/ep/vision.md:1334`), so new sounds sit lower and fuller; no music at Alpha (decision 21) unless Orb says otherwise; the unified sound toolset Orb asked for (`docs/ep/vision.md:1704`) is after Alpha.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Needs A-AUDIO-01 (the five sound sets on by default, A1) and A-AUDIO-03 and A-AUDIO-04 (the listening pass and desktop proof, A2). The building sounds wait on item 2 and on the A4 build, where the last rules that emit events landed. UI's menu hook (its item 8) waits on the hook you name. Nothing in A6 waits on this except Orb's ear.

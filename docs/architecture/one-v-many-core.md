# One versus many in the core: N bodies, and the training dummy in the roster

Owner: Simulation and Engine. Built 2026-10-15; **applied in 06b0200e (2026-10-16)** with one golden regeneration (`rosterHash` only). It is the core's part of stage 1 in Encounter's `docs/director/one-v-many.md`: N bodies in the roster, the hash and the replay. The director's part of stage 1 (`DirBrawl.partner`, the keyed draws given a namespace of their own) is Encounter's.

It was applied as two scripts, now deleted: `n_bodies.py` (stage 1 with Game Design's four rulings on a guard; no golden moved), then `dummy_roster.py` (the reference fighter into the roster as the training dummy, Orb's homework 3; the golden's `rosterHash` moved and nothing else in it).

## What a match of N bodies is

- A match holds 2 to 5 fighters (`SimRoster.MAX_BODIES`). The setup names them: `{"slots": ["PROTAGONIST", "RIVAL", "REFERENCE", ...]}`, from the roster or the bench, an id more than once if wanted, with `"names"` to tell them apart in the feed.
- **Slots 0 and 1 are the pair, exactly as in a 1v1,** and they are the principals, the two the match is between (`SimRoster.isPrincipal`): where they stand, which way they face, who they fight. Slot 0 is the one; slot 1 is the Empress, and her guards stand behind her.
- **A body past the pair** (a guard) stands beyond the second, `SimRoster.GUARD_SPACING` (150 units, 2 bh: "her guards stand 2 bh behind her, along the street") apart and as far again for the next, on the side away from the first. He faces the first, and the first is his opponent: `SimRoster.opp` already gives every fighter but the first the first.
- **He is idle unless the setup's `ai` names him** (`"p3"` to `"p5"`): no AI and no intent, so he stands. Stage 2 gives the ring its AI.
- **The step** controls the pair in today's order (one draw of the seeded stream a tick, as now) and the bodies past it after them, in slot order. A host that passes two intents gives the others none.
- **The intro** brings in the pair only. The others stand on the ground from tick 0, take no entrance and dig no crater.

## Game Design's rulings on a guard (docs/design/empress-guards.md), in the core

| Ruling | In the core |
| :--- | :--- |
| Only a principal's KO ends the match | `SimDamage.ko` returns at once for a guard: his fall is the director's (he leaves, and his place reopens after its cooldown). A principal felled by a guard's blow loses to the principal that guard fights for |
| A guard has no brink and no finisher | `SimWounds.updateStages` never puts a guard on the brink. The finisher is the director's |
| A guard's stance does not set the mood | The mood's AGGRESSIVE column is read from a principal's stance only; "both aggressive" and "both guarded" read the principals, as they did |
| A guard's landed blow feeds the mood at half | Every impulse of a damage event a guard caused is halved, rounded as the core rounds (`_impBlow`). A cue of his (a flurry's close, a guard break) is not halved: the ruling names blows |
| The acts count the principals only | The act's form steps read the principals' tiers; a guard's wounds make no act beat and his tier no form impulse |
| One hit-stop for the whole match | As it is: one `S.dirS.stop`, and freezes that overlap merge (the larger wins). An interjection's freeze is the director's |

With two fighters both are principals, so each rule is today's rule.

## The replay and the hash (Encounter's question)

- **A guard's input is a slot like any other.** An entry is `[tick, slot, low, high]`, written only when a slot's intent changes. A human-driven guard writes entries for his slot. An AI guard writes nothing: his intents come from the AI and the seed.
- **The header's `ai` names p3 to p5** when there are such bodies. A 1v1's header is as it was, so a 1v1 replay is the same file.
- **The hash grows by the list:** it walks every fighter in slot order, one block each, as it already did. Nothing in it was sized for two.
- A replay with an entry for a slot the match does not have is refused.

## Every place in sim/core that assumes two

**Changed by stage 1** (each is the same as before with two fighters):

| Where | What it assumed | Now |
| :--- | :--- | :--- |
| `sim.gd`, `newMatch` | Two slots; two fighters made, named, placed, faced | 2 to 5 slots; the rest placed beyond the second |
| `sim.gd`, `step` | Control order `[0, 1]` or `[1, 0]`; an intent for each of two | The same draw for the pair, then the rest in slot order; no intent past the host's list |
| `replay.gd`, the recorder and playback | `_last` and `cur` of two; `range(2)`; `ai` of p1 and p2 | Sized by the match; p3 to p5 in the header when present; a slot out of range refused |
| `mood.gd` line 443, the style counters | `fs[1 - k]`, "the other one" (with a third body it read the last fighter) | `SimRoster.opp(S, f)` |
| `intro.gd`, `setup` and `_order` | Every fighter falls in; with more than two, every fighter landed and dug a crater | The pair only |

**Already general** (checked, nothing to change):

| Where | Why it holds |
| :--- | :--- |
| `hash.gd` | Walks every fighter, building and shot; the clash's two by index |
| `wounds.gd` line 384, the battered mask at an exchange's start | Four bits a fighter: room for eight |
| `pause.gd`, the set pieces seen | Four bits a slot: room for eight |
| `act.gd`, `setup` | Every fighter; `v2` and the assists default past the setup's lists |
| `shots.gd` | A shot meets every fighter |
| `fx.gd` | Events carry slots as numbers |
| `roster.gd`, `opp`; its users in `fighter.gd`, `hiding.gd`, `act.gd`, `damage.gd` | Every fighter but the first has the first as his opponent |

**Questions for later stages, not plumbing** (the first three were ruled by Game Design and are in the core, section above):

| Where | The question | Whose |
| :--- | :--- | :--- |
| `damage.gd`, `ko` | Any fighter's KO ended the match. **Ruled:** only a principal's ends it. His coming back on a cooldown is the director's (stage 5) | Encounter |
| `mood.gd` lines 408 and 415 | "Both aggressive" and "both guarded" read the pair. **Ruled:** a guard's stance does not count | Done |
| `mood.gd`, the act | The act counted every fighter's form steps and wounds. **Ruled:** the principals' only | Done |
| The hit-stop and the pauses | One for the whole match: a hit anywhere stills everyone. It is what keeps a brawl's freeze share readable | Encounter, with the freeze-share row |
| `view/camera.gd` | It frames the pair; a guard can be off the frame | Camera |

**The director** (Encounter's count, for the record): `S.dirS.ex` read in 116 places, 26 calls of `opp`, 21 "the other one", 8 keyed draws built as `n * 2 + slot`. With the guards idle none of them reaches a guard in stage 1.

## The training dummy in the roster

- `data/fighters/roster.json` becomes `["PROTAGONIST", "RIVAL", "REFERENCE"]`: he is listed last, and the default pairing is still the first two. `data/fighters/bench.json` is emptied, since a fighter in both fails Tools' `xref:bench-id`; the Empress's guards will stand there. His aura becomes Art's best neutral, `#c6bade`.
- **A replay's data hash takes the fighters in its slots,** one hash each, in place of the whole roster's. So the dummy's data can change without turning away a replay of the other two; his own replays are refused when they do. (This was planned for the first window that regenerates anyway.)
- **His numbers are frozen** (Game Design's §8): the check holds him to base stats, no care, no meter and no wounds or ladder file of his own.
- **The golden:** only `rosterHash` moves. The golden's replays and matches are the same.

**What the others needed in the same commit** (found by running their checks with him in the roster):

| Who | What | Without it |
| :--- | :--- | :--- |
| **Art** | A colour row for him in `data/art/colour-vision.json` | The validator fails (`xref:colour-vision-fighters`), so CI's data job fails |
| **Tools** | `tools/flash/pick-seeds.mjs` run again, so he is in at least five of the picked AI matches; the two new pairings (the Protagonist and the dummy, the Anti-hero and the dummy) in `tools/flash/seed-history.json` and the pairing list in `sources.json` | The flash self-test fails (2 of 83), so CI's flash job fails |
| **Legal** | The pixel gate's pairing list grows by the same two pairings, and their clips are read | The release pass asks for clips that do not exist |
| **Encounter and Combat** | His moveset: an entry in `data/director/alchemy.json`, or a `reference` pool in `data/combat/recipes.json` (Game Design: he fights with the common pool) | A warning only: he gets no pieces of his own |
| UI, Audio | Nothing found: UI's two checks and Audio's two pass with him in the roster | |
| Animation, Rendering | Not run here: his rows for the select screen and the training mode are theirs to check | |

In 06b0200e: Art's colour row, Tools' pairings with its xref line (a fighter whose role is `reference` goes without `reach.bolt` and `reach.blast`) and its fixtures, and Combat's `reference` pool in `data/combat/recipes.json` (the common pieces only, frozen). Legal's pairing list and the select-screen and training-mode rows are their owners'.

## Proof

**As committed (06b0200e),** both scripts and Combat's `reference_recipes.py` on a9e8f9cd, one regeneration: the golden differs from the one before in `rosterHash` alone (`304fea69b386c745` to `1f127fcc32218996`; light digests, tick counts and checkpoints identical); parity **56 of 56** with no script error; the full gates passed on the tree (the sim's npm stages, determinism plain and with the intro, the seam sweep, the flash count, the validator and its self-test, QA's run-all, the director's loader check, the flash self-test). The EP verified the commit on a clean export.

**Stage 1 with the rulings,** on a clean export of 88d13195: parity against the committed golden, unregenerated, **56 of 56** with no script error, and the golden regenerated **byte-identical**. The new check, "one versus many: what the core counts of a guard": a guard's KO does not end the match, and a principal felled by a guard loses to slot 1; a guard's broken core puts him on no brink; a guard's landed light feeds the mood half the data's units, and his AGGRESSIVE stance changes nothing; a guard's tier and wounds move no act, while a principal's battered limb makes its beat.

**With the dummy in the roster** (and Art's neutral aura, `#c6bade`), on a clean export of f3e1a713, both scripts: the golden regenerated differs from HEAD's in `rosterHash` alone (golden_cmp: light digests, tick counts and checkpoints identical); parity on it, **56 of 56** with no script error. The new check, "the training dummy in the roster", replaces the bench's. Two earlier checks built their fixtures for a roster of two and now take the roster as it is.

**Stage 1 as first parked,** on a clean export of 63e3b9b4:

- **Parity against the committed golden, unregenerated: 55 of 55,** with no script error. **The golden regenerated is byte-identical** to HEAD's. So every 1v1 match, replay and checkpoint is the same to the bit.
- **The new check, "one versus many: a match of three to five bodies":**
  - five slots, flipped and not: each body in his slot with his keys, the guards where the spacing puts them, idle, facing the first, with the first as their opponent; the pair's opponents unchanged;
  - matches of 3, 4 and 5 bodies, the pair the AI's and the rest idle, 1,500 ticks each: every body stays in the world, and each replays to the same hash;
  - the hash sees the fifth body;
  - a recorded match of four bodies with a human guard (he walks) and an AI guard plays back; the header names p1 to p4; an entry for a slot the match does not have is refused; a 1v1's header still names p1 and p2 only;
  - an intro brings in the pair only: the guard stands on the ground and is not in the intro, and a skipped intro digs two craters;
  - six slots, or an unknown id among them, play the default pairing.
- The window 3 check ("a match's slots name two fighters the data has") now takes six slots as its case of too many.
- An AI guard ran 600 ticks against the one with no script error. What the director made of him is Encounter's to read in stage 2.

**The cost a tick, measured** (stage 1's last row in Encounter's table). The pair is the AI's and the rest stand idle; three matches of up to 6,000 ticks each, run twice, on Orb's PC while other sessions ran:

| Bodies | Mean, first and second run | 99th percentile |
| ---: | :--- | :--- |
| 2 | 322 and 317 µs | 935 and 979 µs |
| 3 | 379 and 354 µs | 1,046 and 1,026 µs |
| 4 | 439 and 404 µs | 1,193 and 1,137 µs |
| 5 | 468 and 443 µs | 1,235 and 1,223 µs |

An idle body costs about 35 to 60 µs a tick: his step, and the loops that walk every fighter. A guard who fights adds his AI and the director's work on top; that is stage 2's to measure.

## Size

Both scripts, against 4a3ecb74:

| File | Lines added | Lines removed |
| :--- | ---: | ---: |
| `sim/core/roster.gd` | 28 | 1 |
| `sim/core/sim.gd` | 24 | 14 |
| `sim/core/replay.gd` | 25 | 15 |
| `sim/core/mood.gd` | 21 | 10 |
| `sim/core/intro.gd` | 8 | 4 |
| `sim/core/damage.gd` | 7 | 0 |
| `sim/core/wounds.gd` | 2 | 0 |
| `sim/core/tools/parity.gd` | 251 | 37 |
| `data/fighters/roster.json`, `bench.json` | 2 | 2 |

No new class, no event, no data key. **The golden moves only by `rosterHash`, and only with the second script.**

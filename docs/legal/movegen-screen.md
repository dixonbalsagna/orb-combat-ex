# Generated movesets: originality screen

Owner: Legal and IP Compliance. 2026-10-05. Screens `docs/combat/pending/movegen/review-sheet.md` (92 rows), `parts.json`, `identity.json`, the stance layout and tells in `docs/design/melee-press-feel.md` sections 10 to 12, and Orb's identity split. From the written sheets. A screen, not legal advice.

**Goal:** generated moves never land on a recognisable signature move, now or as the generator grows. A generated string is a stack of ordinary parts, so the risk is in **combinations, repetition and what is held**, not in any single shape. The banned rows (`movegen-banned.json`) catch those automatically.

| # | Item | Verdict | Log |
|---|---|---|---|
| 1 | The 22 new and 14 derived shapes | **Clear**, with conditions on a few | RL-072 |
| 2 | Banned rows as data | **Delivered**: `movegen-banned.json` | RL-073 |
| 3 | The screening rule for later stances and signature slots | **Below** | RL-073 |
| 4 | The five stance tells and five stances on shoulder buttons | **Clear**, with two conditions | RL-074 |
| 5 | The identity split | **Clear** | RL-075 |

## 1. The shapes

All 36 new or derived shapes are ordinary martial-arts blows from the grammar's own parts. None is a signature on its own.

**Conditions on a few (they bite when held or strung):**
- **Rising palms and rising fists** (Protagonist martial.x 18, 19, 29, martial.y 01, 03; rival martial.x 18, 28, martial.y 01, 03): no leap and no spin, no held raise, no glow. Do not chain one rising blow into another while airborne (row s05).
- **Palm strikes** (Protagonist x.14, 25, y.07, 08, plus the rising palms above; rival x.29, derived from a jab): a melee strike only, with no light or beam leaving the hand, never at a hip, and never a clawed hand on the face (row b06). The rival's palm to the head (29) is a plain palm, not a grab.
- **Fist drops and plate drops** (Protagonist x.16, 17, 22, 28, y.04; rival x.16, 17, 22, 26, y.04, 14): one fist, blade or forearm plate, never clasped, no held raise (row b05). Rival y.04 (double hammer) is the two-handed one: hands apart the whole way, no clasp, and not as a charged overhead hold.
- **Straight fist and blade blows to the gut or chest** (rival x.11, 13, 15, 19, y.07; Protagonist x.13, 14): fine alone. Strung, a run of them at one place is a stomach-punch trade or a shouted barrage, so rows s01 to s03 apply.
- **Spinning kicks and elbows** (Protagonist y.14, 16; rival y.11): a single turn, never travelling (row b04).
- **Held heavies** (any piece with the held form): charged with one arm drawn back at shoulder height, never at a hip, never both hands together, no light (rows b02, b09, b12).
- **Crossed-arm rams** (Protagonist y.13; rival y.12): arms cross only for the strike itself, wrists apart, never a held cross (the sheet's ask stands).
- **Derived shapes** (a hand-state swap or a re-aim): a swap to palm or fist never changes the rules above. A re-aim to the jaw or head still never grips. The three hand-state swaps on the rival (x.29 palm, y.07 and y.10 fist) are plain; note that x.29 gives the rival a palm, which sits outside the identity split (a design point for Combat, not a Legal one).
- **Re-aims to the gut** (Protagonist x.10, 30, y.15): fine, within the "never two gut blows running" rule (s02).

## 2. Banned rows

`docs/legal/movegen-banned.json` holds 13 shape rows and 7 sequence rules, in the grammar's own fields (limb, tip, path, target, weight, form, arms, plus `flags` for how a piece is posed). They describe shapes, not sources. Combat merges them into `parts.json` as `strike.banned` and `strike.bannedSequences`. The generator refuses to emit a match, and a test fails the build if one appears.

## 3. The rule for later stances and the eight signature slots

**A person (Legal) screens, every time:**
1. **Each signature slot's frame and its hand-picked defining piece.** That covers the martial signature, the counter, the beam, the ultimate and the terrain art, and the three hybrid slots when they ship. A signature is a set piece, and set pieces are where a recognisable staging lives. The three or more variants of one frame are screened once as a set, and again only if the frame changes.
2. **Any new vocabulary:** a new limb, tip, path, target, hand state or energy kind, because the banned rows only know today's words.
3. **Each stance's tell** (pose and cue), and each hybrid's tell.
4. **Names, shouted names and lines,** by the usual search.
5. **Anything the generator flags** as matching a banned row and then gets overridden.

**The banned rows cover automatically:** every generated light and heavy built from today's vocabulary, and every string of them. For these, Legal samples the review sheet's "Legal asks" column and about one row in ten per generation, instead of reading every row. A new generation that adds no new vocabulary needs no new screen.

**Growing the banned rows:** when a screen finds a new signature stacking, Legal adds a row and Combat regenerates. Rows are only added, never removed, without Legal.

## 4. Stance tells and the shoulder-button layout

| Stance | Tell | Verdict |
|---|---|---|
| Martial arts | his own stance, no cue | Clear |
| Defensive | arms set, a rim of light on the guarding side | Clear (the guard arc, as screened) |
| Energy arts | lead hand raised and lit, a glow at the hand | **Conditional** |
| Charging | planted and drawn in, the rising aura "as now" | **Conditional** |
| Manoeuvre | leaning into flight, a short trail | Clear (the afterimage rules) |

- **Energy arts:** a lit hand raised is the stock charge image. Light the **forearm plates' edges**, not a ball in the palm. The hand is open or a blade, raised no higher than the shoulder, never palm-forward at a hip and never both hands.
- **Charging:** a rising aura is the franchise's flame aura if it streams upward as a body-wide flame. Keep it a **thin outline or short scattered streaks in the lane colour**, never a flame column, never gold, white or red. The pose is planted and drawn in with hands open and forward, never fists at the sides. No scream, and no rubble ring or lightning with it. With a thin aura and an open-hand pose it is **one mark**, inside the stacking rule.
- **Manoeuvre:** the trail follows the afterimage rules (thin outline, lane colour, no vanish, no ring of copies).
- **Five stances on LB, RB, RT and LT:** an input layout, with no originality issue. The stance names are plain words. Clear.

## 5. The identity split

Clear. The Protagonist on palms, blade hands and arcs, and the rival on fists behind plates and straight lines with blade hands on his lights, are two distinct, generic martial-arts voices, and they do not land on a known character. Conditions: (a) the Protagonist's palm strikes never emit light, and the rival's blade hands never pass through a body (rows b08, b09); (b) glasses always on is fine for the rival. Normal lenses are the dark violet tint and the glare stays at key moments only (`glasses-rules.md`). The "knocked off by a hit" state stays optional.

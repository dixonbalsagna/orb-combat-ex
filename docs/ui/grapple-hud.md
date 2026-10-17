# The grapple on the screen: the grip's five steps, the refused cue, and the labels (UI, paper, 2026-10-17)

Owner: UI & UX. **Paper only; nothing is built, and no picture was taken** (the quiet window). Against `docs/design/grapple.md` (Game Design: the catch, the clinch, the carry, the throws), `docs/controls/grapple-input.md` (Controls: the press on every layout), and the beam struggle's pieces already built (`UiTug`, `docs/ui/hud-spec.md` section 62), which this reuses. Words are plain and are Narrative's to own; Legal's g01 to g05 and s08 apply to everything drawn here (the held body is in view every tick, no cause is staged as punishment for its own sake, and no blow is dwelt on).

## 1. What the player has to be able to read

In a clinch there are three things to read at a glance, and the HUD already has a vocabulary for each:
1. **Whose grip is better, and how close the throw is.** The grip is "one meter between them, from two behind to two ahead" (Game Design section 2); the HUD draws it as **five steps between the two fighters**.
2. **The beat to press on.** Every 20 ticks, four times at most. This is the beam struggle's pulse, so it is drawn the same way and learned once.
3. **What the press did.** A pummel moved the grip, a stray did nothing, a brace is up.

## 2. The grip's five steps (the clinch)

**Where:** between the two fighters' hands, drawn the way the tug is (a short track between their screen anchors, inset into the fighters' space), so a clinch and a beam struggle look like cousins and share one set of shapes.

**What it is:**
- **Five steps on a short track,** drawn as five notches with a **diamond** on the current one. The two ends are the two fighters' ring colours (a thick quarter at each end, as the tug's comeback quarters are). **The leader is the one the diamond is nearer.** Even is the middle notch.
- **The throw's step is marked:** the notch at each end has a double bracket, because a pummel from there is the throw. A fighter at the end is one pummel from throwing and the other from being thrown: that is the whole tension, in a shape.
- **The pulse:** a thin ring round the diamond that closes over the 20 ticks between pulses and meets it on the next one (the tug's beat ring, the same code), so a player presses as it closes. Under Reduced motion or Reduce flashing: two steady rings and a short bar that fills for 0.12 s after each pulse (as the tug).
- **How long is left:** four small pips under the track, one for each pulse the clinch can still have; one drops at each pulse. No number and no timer, and the clinch ending is visible, not a hidden cap. If Orb does not want even this, the pips can go (then the clinch just ends at its 90 ticks).
- **A pummel:** the diamond steps one notch toward the presser, and rays in the presser's colour show for 0.45 s (three, five for a sharp one: the tug's marks). **A stray:** a small grey cross on the presser's side, and **a short slash through the presser's next pulse's mark** to say "your next press will not count", which clears at the next pulse. A masher sees the slash and learns why.
- **The brace** (A held): a bracket round the bracing fighter's end of the track, solid while the brace holds. When his grip tires (the 40-tick cap) the bracket goes hollow for the 20 ticks he cannot brace again, a steady two-state shape with no ring that fills (Orb's no-cooldown note: it tells him "not now", it does not count).
- **A pin** (the pair walked into a building that holds): a short wall bar at the pair's feet end, steady. The pinner's vicious blows wear half again as hard; the HUD only shows the pin.
- **The leader walks the pair:** a small arrow on the leader's end points the way the pair is moving along his stick.
- **Vicious blows:** the region the stick leans to is **named on the body figure** (the plate's body figure already highlights a region): "Going for: ARMS". It is a label near the track, small, in plain type, so a player who throws a blow knows where it will land.

**Sizes.** The track is as wide as the fighters' space allows between them (at least five 18 px notches: 90 px), the diamond the same size as the tug's point, the pips 8 px. On a phone on its side the leader arrow, the region label and the pips are dropped before the track and the diamond are (they are optional; the grip and the pulse are not).

**Photosensitivity.** The only moving part is the pulse's ring (three a second at most, thin strokes, no filled area changing): the same thing already ruled for the tug. A hit-stop never makes it faster.

## 3. The catch, the carry and the throw

- **The catch's tell** (a 10-tick reach): the existing wind-up ring on A's glyph (the legend's A row, Full touch's Context button) closes over the tell. **A held A past the landing is the carry:** the ring's arc fills as a hold does (the charge arc), and its second notch at 14 ticks is where a tap becomes a hold (Controls' number).
- **The carry:** the same track idea with two notches, the carrier's end and the carried's, and the carry's pulse (every 20 ticks) ring: the carried fighter's A on it breaks the carry into the clinch (the same press, so the same ring).
- **A throw:** a card-free moment: the camera and the beat do the work. The HUD shows the exit by one word in the banner slot for a second ("THROWN DOWN", "THROWN UP", "THROWN ACROSS", "REVERSED", "PUSHED OFF", "BROKEN FREE", "TIME"), plain, no colour.
- **The openings it hands the brawl** (a bury, an air throw, a wall slam) are openings like any other: OPEN brackets on the plate and the lit B, as already built. The HUD adds nothing special for a throw followed by a launch: the chain reads itself.

## 4. The refused cue

Game Design: "A press in the lockout shows the refused cue, and does nothing"; a masher gets one catch and then the refused cue.
- **It is the mark already built:** `press_ack` with kind `refused`: a short grey mark on the pressed button's glyph (Full touch: on the button) for about 0.4 s (`docs/ui/img/press-mark-refused-web.png`). Nothing new to draw.
- **No lockout timer.** The 90-tick grab lockout and the 120-tick no-regrab are never drawn as a countdown or a greyed button (Orb: no cooldowns drawn); the only sign is the refused mark when the player presses. A is not dimmed between presses.
- **The cue's name is Encounter's:** `press_ack` already carries `refused` for a blocked press; the lockout should send the same kind with `source` `a` (or `guard` for touch Simple's stand-in), so the HUD needs no change. If Encounter wants a different kind, the hub's `_on_press_ack` reads any text as the kind.
- **A second kind:** `voided` for a pummel the grip refuses (a press that counted as a stray), the grey cross on the track above, for one press.

## 5. Controls' labels

From Controls' paper, per layout, in plain words:

| Layout | When A is in reach in martial stance | In a clinch | In a carry |
| :--- | :--- | :--- | :--- |
| **Arena (pad), keyboards, Full touch** | The A row reads **Grab** (it reads Action out of reach, as built) | The A row reads **Pummel on the beat**, with "(hold: brace)" after it; the X, Y and B rows read **Hit his {region}** | A reads **Break free on the beat** |
| **Simple pad** (A is LB, "Context") | **LB: Grab** | LB reads **Pummel on the beat**; Attack (X) and Y read **Hit his {region}**; Guard says nothing (it is not an A and must not look like the beam's let-go) | LB reads **Break free** |
| **Simple touch** (no A button) | The Transform button's label reads **TAP: GRAB, HOLD: TRANSFORM** (Controls' option 1, which they recommend) | **Guard is relabelled PUMMEL / BRACE while the clinch lasts** (a press on the beat pummels, held braces); the Transform button reads nothing | The same Guard relabel: BREAK FREE |

- **The legend's rows are the surface** (`UiHints.rows`'s row notes, the same mechanism the beam struggle's LET GO uses): a model flag `in_clinch` (derived from the clinch's cues, like `in_struggle`) switches the notes. The touch buttons get a caption under the track for the same reason the tug's touch caption exists: there is no legend there. Words for the caption: "Tap on the beat" and "Hold to brace".
- **Teach a tap.** The caption never says swipe, as for the tug.
- **The word GRAB, not catch, clinch or grip,** is the player's: Combat's and Game Design's nouns stay in the data. The meter's own heading is **GRIP**.
- **A latched or charges-off player** (Controls' section): the latched A toggles its brace, so the bracket shows the toggle's state; a charges-off player has no brace: the bracket simply never appears for him.

## 6. Words (a first list for Narrative)

GRAB | Pummel on the beat | hold: brace | Hit his {region} | Break free on the beat | GRIP | BRACE | TAP: GRAB, HOLD: TRANSFORM | PUMMEL / BRACE | BREAK FREE | THROWN DOWN | THROWN UP | THROWN ACROSS | REVERSED | PUSHED OFF | BROKEN FREE | TIME | Going for: {region} | Tap on the beat | Hold to brace.

## 7. What the director would send (names proposed for Encounter, following the beam cues)

`clinch_start` (actor the leader, target, `k` the lead 0 to 2), `clinch_pulse` (`k`, `n` its tick), `clinch_move` (`k` the grip, -2 to 2 from the catcher's side, `text` pummel or sharp), `clinch_stray`, `clinch_brace` (actor, `text` start, end or tired, `dur`), `clinch_pin`, `clinch_end` (`text` throw_down, throw_up, throw_across, reversal, broken, push_off, time, tech or burst), and the lean as `region` on a vicious `blow`. The meter's step could also come as a field on the state (like `Clash.mid`), so the HUD never has to replay moves; either is fine.

## 8. Build order, when asked

1. A shared beat widget from the tug's ring and marks (`UiTug`'s pulse, rays and strays factored out: a refactor with the tug's tests as the guard).
2. `UiGrip`: the five steps, the diamond, the pips, the brace and pin marks. Behind a flag `grapple_hud` (off until Encounter's cues exist).
3. The legend notes and the touch captions (the `in_clinch` model flag).
4. The exit words.
Gates: `hud_check` with a case for each layout's notes, the track at the fifteen sizes (on screen, the pulse's steps, steady under Reduced motion), no state change faster than the pulse, the c08 and photosensitivity checks, `hud_words_check`, determinism plain and `--intro`.

## 9. Questions

1. **The four pips** that show how many pulses the clinch has left: keep, given Orb's note on caps, or let the clinch simply end?
2. **The brace's tired state** (hollow for 20 ticks): fine as a two-state shape, or too close to a cooldown?
3. **Touch Simple's Guard doing PUMMEL / BRACE** (Controls' recommendation): Orb's call, with the alternatives in Controls' paper.

## 10. Game Design's ruling (1e06319b, 2026-10-17): touch Simple's option 1

On touch Simple, a tap of the Transform button is the catch (a hold of 30 ticks stays Transform), **Guard is A in a clinch** (a press on the pulse is the pummel, a held Guard the brace), no carry is offered, and **UI labels Guard "PUMMEL / BRACE" during a clinch**: section 5's last table row stands as written. Also ruled: without a held A (charges off, or the latched A) the brace is automatic at two behind (two pulses at most, then a rest), and a latched A's presses are all pummels with no toggled brace, so the HUD's "toggled brace" bracket (section 5's last bullet) is **dropped**: a latched or charges-off player simply gets the bracket when the director braces him. Still paper: it waits for Encounter's clinch cues.

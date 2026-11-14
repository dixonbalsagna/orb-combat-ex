# The marks drawn on and round the fighters: the code read, and the re-price (A-RENDER-13; VFX, 2026-11-14)

**Orb's answer (docs/ep/vision.md, verbatim):** "LETS TREAT THESE SHAPES AS PLACEHOLDERS FOR DIEGETIC AURAS, GLOWS, FLARES ETC. THAT SHOWCASE GAME MECHANICS WHERE NECESSARY. UI/UX ELEMENTS MUST BE NON-INTRUSIVE, RULE-OF-COOL, PROTECT PLAYER AGENCY AND ENJOYMENT, RESPECT THE SPECTACLE."

So the row's fix is **replacement, not removal**: each mark becomes an effect that belongs to the fighter and the world (the fighter's own aura and limb heat, impact flare and sparks, dust and cracks on the ground), and a mechanic is still shown where it needs showing. This page is the proposal and its cost. Nothing is built, nothing is changed in the game, and the marks stay as they are until Orb has seen a clip of each replacement (look gate, ADR 0010).

## Are they live in the played build?
Yes. `render/core/main.gd:165` sets `host.vfx.press_enabled = RenderAnim.press_styles`, and `render/anim/render_anim.gd:68` has `press_styles = true` (on since 2026-10-08). That one flag (`render/vfx/vfx_hub.gd:445-454`) runs the press marks, the zip marks and the energy-in-reach marks (`inreach`). `VfxLook.PRESS_DEFAULT` (`render/vfx/vfx_look.gd:77`) is false, but it is overridden by Animation's switch, so the played build draws all of them.

## The marks, each with its file and line
"Mark" means a drawn shape that is not a thing in the world: a ring, diamond, bracket, chevron or crossed line placed on or round a body. Lines are in `render/vfx/` at the time of writing (main fcd6706c).

| # | Mark | Where drawn (file:line) | When it shows | What it tells the player | Kind |
|---|---|---|---|---|---|
| 1 | Charge ring that shrinks on the fighter | zip.gd:7 (heavy zip tell) | a heavy zip's wind-up | a heavy is coming, and when | mark |
| 2 | Counter marks: a diamond (tech) or a double ring (heavy) at the stop | zip.gd:12; `_mark` zip.gd:422-440 | a zip is stopped on arrival | the counter worked | mark |
| 3 | Squeezing ring and two brackets round the zipper | zip.gd:13; `_outcome` zip.gd:417 | a late counter catches him in reach | he is caught | mark |
| 4 | Small round contact ring | press.gd:6; `_blow` press.gd:421-521 | a mashed (speed) blow lands | a blow landed | mark |
| 5 | Hard diamond at the contact | press.gd:8, `diamond_r` 14, `diamond_life` 5 (press.gd:22) | a timed (tech) blow lands | a timed blow landed | mark |
| 6 | Charge ring that shrinks on the wind-up | press.gd:9 (cue `tell_heavy`) | a held (heavy) blow's wind-up | a heavy is winding up | mark |
| 7 | Double contact ring | press.gd:9 | a held (heavy) blow lands | a heavy landed | mark |
| 8 | Shield line and block flash ring | press.gd:11 | a block | the block held | mark (the arc itself is Rendering's) |
| 9 | Four corner brackets on the target | press.gd:484-495 (riposte, style `brackets`) | a riposte lands | a reversal worked | mark |
| 10 | Ring or glint on the striking limb | press.gd:499-514 (style `glint`; the beat option, off unless UI's beat option is on) | each blow, with the option | the beat to press on | mark, option |
| 11 | Small hollow ring on the lit palm | reach.gd:7, 926 | a point-blank bolt comes up | the bolt is ready | mark (the palm light is diegetic) |
| 12 | Thin ring closing onto the palm, with a committed line from hand to chest | reach.gd:8, 232, 413-452 (`windup`, `windup_end`) | a blast's or a heavy's wind-up | when it will land | mark |
| 13 | Hollow ring and two crossed crack lines at the contact | reach.gd:9, 268 (`land`) | a bolt or blast lands | it landed | mark (sparks and the soft flash are diegetic) |
| 14 | Two rising chevrons over the staggered rival | reach.gd:13, 368-399, 377 (`opening`, `stagger`) | a rival can be launched | press B now | mark |
| 15 | Ring leaving the hand, with three short ticks | reach.gd:476-505 (`chargeflash`) | the heavy's charge is full | release now | mark |
| 16 | Double ring at a double hit | reach.gd:506-527 (`double`) | two hits in one | a double | mark |
| 17 | Whiff marks | reach.gd:528-558 (`whiff`) | an energy art misses | it missed | to confirm by clip |
| 18 | The duel of perfects: a line and a ring between the two, a ground wave | reach.gd:624-712 (`duel`, `wave`, `amped`) | two perfect windows meet | the duel | partly mark (the ground wave is world) |
| 19 | Cash-in: hand-to-chest line, four corner brackets, double ring, crossed crack, one vertical cut | reach.gd:714-748 (`cash_tell`, `cash_hit`) | the instant heavy lands | the cash-in paid off | mark |
| 20 | Chase: four corner brackets and a flat ring on the rival's chest each blow | reach.gd:749-788 (`chase`, `arrive`) | a rushing chain | he is chased down | mark |
| 21 | Hand takes a small shine while a perfect window is open | reach.gd:789-816 (`shine`) | a window is open | press now | **already diegetic: keep** |
| 22 | Tech, return and edge lines and echoes | reach.gd:817-880 (`chase`, `edge`) | return and edge moves | the move's path | partly mark; to confirm by clip |
| 23 | Barrage hand and landing | reach.gd:857-919 (`rim`, `bring`) | a barrage | the volley | mostly diegetic (rim light, flash); confirm |
| 24 | Lit palm of a guard volley | reach.gd:920-937 (`lit`) | a guard volley | the volley is ready | **already diegetic: keep** |
| 25 | Chevrons over the guard's head, with a committed line | reach.gd:938-964 (`interject`) | an interject | a counter-interject is possible | mark |
| 26 | Rim edge (a thin edge line beside the body), carry (the shot's colour trails off him), spill, scorch, send-off trail | reach.gd:10-14, 295, 307, 323, 345, 581 | the shots' contacts and launches | what hit him, where it went | **already diegetic: keep** |
| 27 | Beam struggle pulses, surges, strays, opening | reach.gd:965-1090 | a beam clash | who is winning | on the beam, not the fighters: diegetic energy, not part of this row |

So: **19 marks to replace** (rows 1-16, 19, 20, 25; rows 17, 18 and 22 to settle from a clip, and the ground wave in 18 stays) and **4 rows that already are diegetic effects and stay** (21, 24, 26, 27; plus the parts of 13, 18 and 23 that are sparks, flash and ground).

## What replaces each: five effects that belong to the fighter and the world
Each is made from pieces the project already has (the pool's shards, embers, dust and smoke; the aura's glow; the energy head shapes; the clash air shader; the rim edge) and each is data-driven. No effect is drawn on or over a body as a shape: they are light and matter that the move itself throws off.

1. **Gather (replaces 1, 6, 11, 12, 15).** A wind-up shows as the fighter's own energy drawing in: motes and a few thin streaks stream into the striking hand or chest, the limb's aura brightens as the move nears its tick, and the ground at his feet lifts a little dust. How long is how full the glow is; "full" is a short bright crest of the aura (not a ring). Reads in the silhouette, in his colour.
2. **Impact (replaces 4, 5, 7, 13, 16, 19, 20).** Each landed blow is told by what it throws: a spark fan along the blow's direction (count and length by strength, tech sharp and few, speed many and short, heavy long and wide), a short bright flare at the contact in his colour, and dust and chips kicked off the target's feet. A heavy and a cash-in add a short ground crack and the air ripple the clash look already has (a thin local ripple, no ring line). A double hit is two bursts a beat apart.
3. **Counter and catch (replaces 2, 3, 8, 9).** A counter is a hard cutting arc of flare across the path at the stop, with a spark burst and the zipper's last after-image frozen in the air for a few ticks. A catch is a thin energy tether that snaps taut between the two bodies and a stagger shudder in his rim light. A block is the guard's arms catching a sheen and a short spark spray at the arms, not a line and a ring. A riposte is the reversal's flare along the sidestep.
4. **Opening (replaces 14, 25).** "He can be launched" is shown on the staggered rival's body: his rim edge glows in the attacker's colour and pulses with the stagger, and energy sheds up off him in short streaks. The attacker's own palm lights (the existing lit palm). An interject is the guard's hand flaring ahead of the blow it will counter.
5. **Beat (replaces 10).** Under UI's beat option, the striking limb's heat: a short bright streak along the fist's path at the beat, no ring.

What "where necessary" means here: the six mechanics a player reads from the marks today are **a heavy is coming, it landed, a counter or catch worked, a launch is available, a perfect window is open, the charge is full**. Each has a replacement above that carries it in light and matter. Where a replacement is weaker than its mark at telling the player (the launch opening is the one at risk: a glow is less clear than two chevrons in a busy scene), the clip is where Orb decides, and the fallback is to keep that one effect brighter before ever bringing a shape back.

## Cost (the re-price; "likely more than S")
It is an **L**: about **1.6M tokens** of VFX work, in four parks, plus a look-gate clip per effect.

| Park | What | Marks | Rough cost |
|---|---|---|---|
| W1 | Gather: the stream-in glow and motes, data and schema | 1, 6, 11, 12, 15 | 0.4M |
| W2 | Impact: spark fans, flare, kick-off dust, ground crack, the ripple at heavy and cash-in | 4, 5, 7, 13, 16, 19, 20 | 0.5M |
| W3 | Counter, catch, block, riposte; opening glow and shed | 2, 3, 8, 9, 14, 25 | 0.5M |
| W4 | Beat streak, remove the old marks (or leave them behind a flag, off), checks and the frame-rate read, clip set | 10 and cleanup | 0.2M |

- **Checks and the frame rate:** each park extends `effects_check`, runs `hash_check` (nothing changes the sim) and reads the pool and frame cost (`perf_bench.gd`); nothing here may cost frame rate (Orb's rule), so each effect is built from pooled pieces with a cap.
- **The look gate:** for every replacement, a side-by-side against the reference build and a short clip in both flash modes before it lands; the flash register counts the new flares (the soft flare asks the register as any flash does).
- **Animation:** none of this needs a new pose. If Orb wants the body to react (a flinch on the catch, a lean into the gather), that is Animation's and goes through the EP.
- **Clips for Orb's A1 page (the amendment):** one short clip per mark kind, shown as it is today. About 14 clips from one scratch scene that raises each mark's own cue in turn: about 0.15M tokens and one quiet capture window, through Tools' launcher, one at a time. Not made yet: the EP gives the window.
- **Re-entry heat trails** (nice-to-have for Alpha): the meteor trail already burns by launch speed; a re-entry trail would be that ribbon's heat when a fighter falls from altitude at speed. Not priced here; about 0.2M if wanted, after W4.

## What I need
- **From the EP:** Orb's yes on the plan's shape (five effects, four parks), a quiet capture window for the 14 clips, and which parks go before Alpha and which wait for A3 (the row closes in A3).
- **From Animation (through the EP):** nothing required; an optional body reaction.
- **From Game Design (through the EP):** a ruling that "launch available" may be shown as a rim glow plus shed streaks (no shape) if the clip reads well.

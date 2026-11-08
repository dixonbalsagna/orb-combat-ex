// The switches of the new planet and the scratch changes the private preview build makes (tools/preview/preview.mjs, docs/tools/preview.md). Pure: text in, text out; nothing here touches a file.
//
// A switch is one flag in a data file, flipped by editing the file's TEXT in a scratch copy (the key's value only, so the file keeps its layout and every comment key). The table says what each
// switch is, where it lives, what it was and what it becomes, and which switches it needs: a load error of the game's own (WorldFill.floorProblem) refuses a floor without both halves of the
// surfacing rule, so turning one off turns off what needs it, and the preview says so.
//
// Two scratch code changes ride along, both to render/core/main.gd of the scratch copy only (patchMain): a `?planet=N` entry (the shipped game builds a generated planet only when a match's setup
// names one, and no menu or URL does yet, so without it a gen 2 switch changes nothing a player sees) and a state probe `?preview=1` (window.__preview, read by the smoke check).

import { createHash } from 'node:crypto';
import { BB_FINGERPRINT } from './blackbox.mjs';

export const SWITCHES = [
  { id: 'gen2', file: 'data/biomes/climate.json', path: ['gen'], from: 1, to: 2, needs: [],
    what: 'planet generation 2 (climate, 15 fine biomes, lakes, sites) for every planet match instead of the stored planet' },
  { id: 'biome', file: 'data/combat/launch_biome.json', path: ['biome', 'enabled'], from: false, to: true, needs: [],
    what: 'the launch planner reads the ground (cliffs, ice, marsh, trees, vents) and its surface (biome.enabled)' },
  { id: 'water', file: 'data/biomes/water.json', path: ['enabled'], from: false, to: true, needs: [],
    what: 'water v2: holes fill from the sea, lakes and the water table; wading; the crater wave; the douse' },
  { id: 'surface', file: 'data/biomes/water.json', path: ['surface', 'enabled'], from: false, to: true, needs: [],
    what: 'surfacing, the world half: a launched body that lands in water is brought up to the surface' },
  { id: 'interrupts', file: 'data/director/interrupts.json', path: ['water', 'enabled'], from: false, to: true, needs: [],
    what: 'surfacing, the director half: a drop (the zip\'s knock-down) under water is brought up and counts as landed' },
  { id: 'floor', file: 'data/biomes/water.json', path: ['floor', 'enabled'], from: false, to: true, needs: ['surface', 'interrupts'],
    what: 'the lake floor: a free fighter\'s floor in the ring\'s own water is its surface less his feet (needs both halves of surfacing)' },
  { id: 'calmTurn', file: 'data/director/interrupts.json', path: ['calmTurn', 'enabled'], from: false, to: true, needs: [],
    what: 'the calm turn, the director\'s half (DirCalm.on): without it the director never asks and the turn never happens, whatever rings.json says. Found by QA, 2026-10-31: `turn` alone gave 0 turns in 200 matches' },
  { id: 'turn', file: 'data/biomes/rings.json', path: ['turn', 'on'], from: 0, to: 1, needs: ['calmTurn'],
    what: 'the arena\'s calm turn (World\'s half, rings.json turn.on; it needs calmTurn, the director\'s half): at a calm moment after a launch has landed, the ring swaps for a new one turned a few degrees (at most 4 a match, 60 s apart)' },
  { id: 'rightStick', file: 'data/input/timing.json', path: ['switches', 'rightStick'], from: false, to: true, needs: [], optional: true, host: 'right-hand-host',
    probe: '"rightStick": SimInputData.right_stick_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func right_stick_on' },
    what: 'the right-hand attacks (pitch 4a, Controls): the right stick throws directional-charge strikes, the left hand braces and slips; the pad\'s right stick is read. Waits until Controls\' code is in the tree you build (or overlaid)' },
  { id: 'quickRead', file: 'data/input/timing.json', path: ['switches', 'quickRead'], from: false, to: true, needs: [], optional: true,
    probe: '"quickRead": SimInputData.quick_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func quick_on' },
    what: 'the quick read (Controls, responsiveness): the strike and the brace read one tick sooner, the vanish resolves on the second press, and the layout publishes the stick\'s pre-read for the pose. timing.json switches.quickRead. Waits until Controls\' code and keys are in the tree (docs/controls/pending/quick-read)' },
  { id: 'hapticLadder', file: 'data/input/timing.json', path: ['switches', 'hapticLadder'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"hapticLadder": SimInputData.haptic_ladder_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func haptic_ladder_on' },
    what: 'the strike charge\'s ladder on the pad (Controls, pitch 1): a held stick strike pulses once as each rung is reached, 12 / 30 / 50 live ticks from the request; none for a quick flick. Needs the right hand. timing.json switches.hapticLadder. Waits for docs/controls/pending/stick-feel' },
  { id: 'specialsOff', file: 'data/input/timing.json', path: ['switches', 'specialsOff'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"specialsOff": SimInputData.specials_off()', probeIf: { file: 'sim/input/input_data.gd', text: 'func specials_off' },
    what: 'the first press (Game Design, docs/design/pad-first-press.md; Controls): the power specials are not built, so RT + X, Y, A are the plain blow and the charge drops. timing.json switches.specialsOff. Waits for docs/controls/pending/stick-feel (round 2)' },
  { id: 'signatureRtOnly', file: 'data/input/timing.json', path: ['switches', 'signatureRtOnly'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"signatureRtOnly": SimInputData.signature_rt_only()', probeIf: { file: 'sim/input/input_data.gd', text: 'func signature_rt_only' },
    what: 'the signature on RT + B only (Controls, round 4): B alone is the big blow, RT + B is the signature, and B with LB, RB or LT held is the heavy of that stance, so a guard or a dodge never fires a beam by accident. timing.json switches.signatureRtOnly. The pad sheet assumes it is on. Waits for docs/controls/pending/stick-feel (round 4)' },
  { id: 'beamAim', file: 'data/input/timing.json', path: ['switches', 'beamAim'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"beamAim": SimInputData.beam_aim_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func beam_aim_on' },
    what: 'the beam aim (Controls, docs/controls/pending/beam-aim, docs/controls/beam-aim-feel.md): the throw carries the aim the stick held at the rim, the shown aim trails the thumb by 4 degrees and at rest the aim is 0, so a beam goes where the thumb threw it. timing.json switches.beamAim. Needs the right hand. Waits for the park' },
  { id: 'hapticRefused', file: 'data/input/timing.json', path: ['switches', 'hapticRefused'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"hapticRefused": SimInputData.haptic_refused_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func haptic_refused_on' },
    what: 'a stick press the game did not answer tells its pad (two dull knocks, 30 live ticks after the request; the audit\'s gap 2). Needs the right hand. timing.json switches.hapticRefused. Waits for docs/controls/pending/stick-feel (round 2)' },
  { id: 'hapticIncoming', file: 'data/input/timing.json', path: ['switches', 'hapticIncoming'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"hapticIncoming": SimInputData.haptic_incoming_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func haptic_incoming_on' },
    what: 'the incoming cue on the defender\'s pad (Controls, pitch 3): one cue when a rival\'s stick strike starts, high for toward and up, low for away and down; the striker feels nothing. Needs the right hand. timing.json switches.hapticIncoming. Waits for docs/controls/pending/stick-feel' },
  { id: 'webRumble', file: 'data/input/timing.json', path: ['switches', 'webRumble'], from: false, to: true, needs: [], optional: true,
    probe: '"webRumble": bool(SimInputData.t(["switches", "webRumble"], false))', probeIf: { file: 'sim/input/input_data.gd', text: 'static func t(' },
    what: 'the pad rumble on the page (Controls, docs/controls/pending/stick-feel/web-rumble.patch): the page asks the vibrationActuator of the pad itself (dual-rumble; Chrome, Edge and Opera GX with an Xbox-type or DualSense pad), because the web runtime of Godot has no pad rumble. timing.json switches.webRumble. Waits for haptic-switches.patch and web-rumble.patch' },
  { id: 'settle', file: 'data/biomes/contact.json', path: ['settle', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"settle": int(WorldContact.K_MAXC)', probeIf: { file: 'sim/world/contact.gd', text: 'static var K_MAXC' },
    what: 'a body on the ground digs or stops (Encounter, docs/director/pending/ground-settle): a launched body meets the ground at most 3 times, and 0, 0, 1, 1 bounces by tier, instead of tumbling off it up to 8. data/biomes/contact.json settle.enabled. The read-back is the contact limit (3 on, 8 off). Waits for the patch and its key' },
  { id: 'splitShare', file: 'data/camera/swing.json', path: ['splitShare'], from: 0, to: 0.7, needs: [], optional: true,
    probe: '"splitShare": (split_rig.split_share if split_rig != null else -1.0), "leadAhead": (split_rig.lead_ahead if split_rig != null else false)', probeIf: { file: 'data/camera/swing.json', text: 'splitShare' },
    what: 'against a CPU the player pane takes 0.7 of the split (Camera swing-share, Orb first play asked for about 0.7), instead of 50/50; with tiles on. data/camera/swing.json splitShare. ?splitshare=0.5 on a local page sets it for a comparison. The probe also reads lead_ahead. Waits for swing-share.patch' },
  { id: 'chaseTap', file: 'data/director/interrupts.json', path: ['chase', 'tap', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"chaseTap": DirChaseTap.on()', probeIf: { file: 'sim/director/chase_tap.gd', text: 'static func on' },
    what: 'the chase after a launch by a plain tap (Encounter, docs/director/pending/chase-tap; Orb: the follow-up floats): while the one you sent is in the air, press X, Y or B and you rush him; the blow lands as you catch him and sends him on. The price is free, 20, 30, 45 for X. data/director/interrupts.json chase.tap.enabled. Waits for the park' },
  { id: 'chargeArmour', file: 'data/director/stick.json', path: ['armour', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"chargeArmour": DirStick.armourOn()', probeIf: { file: 'sim/director/stick.gd', text: 'static func armourOn' },
    what: 'a charged attack has the armour of B (Encounter, docs/director/pending/charge-armour; Orb: charged attacks should be much harder to interrupt, especially by light attacks): data/director/stick.json armour.enabled. Needs the right hand. Waits for the park' },
  { id: 'powerPace', file: 'data/fight/ladder.json', path: ['chargePerSec'], from: 0.5, to: 2, needs: [], optional: true,
    what: 'the power-up pace for the page (from the idle-match README of Encounter, until QA has read the tier pace): data/fight/ladder.json chargePerSec 0.5 to 2, so a fighter charges four times as fast. It moves the golden and every replay data hash: for the page only' },
  { id: 'waterWarm', file: 'data/biomes/water.json', path: ['flowWarm', 'cols'], from: 0, to: 48, needs: [], optional: true, presentIf: { file: 'sim/world/water.gd', text: 'warmCols' },
    what: 'a new flow window reads its span in chunks of 48 columns (World, docs/world/pending/water-window-warm): the first flow step comes 16 ticks later and no tick reads more than 48 columns of a window. data/biomes/water.json flowWarm.cols 0 to 48. IT MOVES EVERY HASH from the first water window: for the page only, and never for a replay proof against an older build (pass --off waterWarm there). Waits for the park' },
  { id: 'chargeClose', file: 'data/director/interrupts.json', path: ['brawl', 'chargeClose', 'enabled'], from: false, to: true, needs: [], optional: true,
    what: 'Encounters press-decides charge-close (docs/director/pending/charge-close; Game Design press-decides section 2): a B held and let go at a rival walking away. data/director/interrupts.json brawl.chargeClose.enabled. Waits for the park' },
  { id: 'pressWait', file: 'data/director/interrupts.json', path: ['brawl', 'pressWait', 'enabled'], from: false, to: true, needs: [], optional: true,
    what: 'Encounters press-decides press-wait (docs/director/pending/press-wait; Orbs second play: hard to charge an attack when every hit seems to interrupt). data/director/interrupts.json brawl.pressWait.enabled. Waits for the park' },
  { id: 'oneRuleB', file: 'data/director/interrupts.json', path: ['brawl', 'oneRuleB', 'enabled'], from: false, to: true, needs: [], optional: true,
    what: 'Encounters press-decides one rule for B (docs/director/pending/b-one-rule; replaces press-send). data/director/interrupts.json brawl.oneRuleB.enabled. Waits for the park' },
  { id: 'beamAim2', file: 'data/director/interrupts.json', path: ['beamPlays', 'front', 'aim', 'enabled'], from: false, to: true, needs: ['beamFront'], optional: true,
    what: 'Encounters beam aim cut (docs/director/pending/beam-aim): acts only with the beam fronts stationary, beside Controls beamAim. data/director/interrupts.json beamPlays.front.aim.enabled. Waits for the park' },
  { id: 'nodeWarm', file: 'data/biomes/field.json', path: ['warm', 'radius'], from: 0, to: 10000, needs: [], optional: true, presentIf: { file: 'sim/world/field.gd', text: 'warmNear' },
    what: 'the ground\'s nodes round the start are read at the match start (World, docs/world/pending/node-warm): data/biomes/field.json warm.radius 0 to 10,000; about 0.34 s more at match load on a native build (the web load time is in the smoke), the same state hash. Waits for the park' },
  { id: 'stickPend', file: 'data/director/stick.json', path: ['pendFollow', 'enabled'], from: false, to: true, needs: [], optional: true,
    what: 'a stick press waits with its request, up to 90 ticks, and is told at once when it is answered or refused (Encounter, docs/director/pending/stick-pend; Game Design stick-lands). data/director/stick.json pendFollow.enabled. The park\'s other switch, flickRun, stays OFF until Game Design sets its points (no row). Waits for the park' },
  { id: 'joltYield', file: 'data/director/swing.json', path: ['jolt', 'yieldToLaunch'], from: false, to: true, needs: [], optional: true,
    what: 'a jolt swing yields to a launch swing on the same tick (Encounter, docs/director/pending/swing-pair; QA kept-build row 4). data/director/swing.json jolt.yieldToLaunch. Waits for the park' },
  { id: 'brawlShareCap', file: 'data/director/swing.json', path: ['brawl', 'shareCap', 'enabled'], from: false, to: true, needs: [], optional: true,
    what: 'brawl swings are not offered while they would be over 0.4 of the match\'s big swings, once there have been 3 (Encounter, docs/director/pending/swing-pair). data/director/swing.json brawl.shareCap.enabled. Waits for the park' },
  { id: 'gen3', setup: { planetGen: 3 }, presentIf: { file: 'sim/world/field.gd' }, needs: [], optional: true,
    what: 'planet generation 3 (World\'s field world): the match\'s setup says planetGen 3 on a whole ring (no arena key), not a data flag. Waits until the tree has World\'s code (sim/world/field.gd)' },
  { id: 'blackbox', url: 'blackbox=1', presentIf: { file: 'sim/core/replay.gd' }, needs: [], optional: true,
    what: 'the black box for Orb\'s first play (the EP, 2026-11-01): records the presses, the seed and the setup on this PC in the project\'s own replay format, and after the match offers three optional questions and a file to save (a download to the player\'s Downloads folder). Read-only, no network, nothing leaves the PC; the sim is stepped by the same call with the same inputs. Local pages only. tools/preview/blackbox.mjs' },
  { id: 'go', url: 'go=1', presentIf: { file: 'ui/core/ui_prefs.gd' }, needs: [], optional: true,
    what: 'the private page for a person with a pad (the EP, 2026-11-01): ?go=1 on a local page sets, before the start menu loads, Player 1 = Controller and Intros off if the player has not chosen otherwise, and counts the How to play card as seen. The notice card and its "I understand, start" stay, a deliberate click. Nothing already chosen is overwritten.' },
  { id: 'meteor', url: 'meteor=loud', alt: { word: 'meteor=quiet', label: 'the quiet trail' }, presentIf: { file: 'data/vfx/meteor.json' }, needs: [], optional: true,
    probe: '"meteor": host.vfx.meteor_enabled', probeIf: { file: 'render/vfx/vfx_hub.gd', text: 'meteor_enabled' },
    what: 'VFX\'s meteor trail: a fighter\'s own burn laid along his path and cooling in the world. A page word on a local page (?meteor=loud, the default here, or ?meteor=quiet: two sets of numbers for Orb to pick between); no word, the trail is off and byte-identical off. The printed address carries the loud word and the quiet one is printed beside it. Waits until the tree has VFX\'s data/vfx/meteor.json' },
  { id: 'tiles', url: 'tiles=1', cmd: '--tiles', alt: { add: 'nofore=1', label: 'the fore tone OFF, to compare (Rendering\'s page word; on by default)' }, presentIf: { file: 'render/core/tile_ground.gd' }, needs: ['gen3'], optional: true,
    what: 'Rendering\'s tile ground (stage 4 of the ring-at-any-angle work): the fight on planet-keyed tiles on a true globe, through Simulation\'s frame. A page word for now (?tiles=1, local pages only): the printed address carries it. Needs gen3 and waits until the tree has render/core/tile_ground.gd' },
  { id: 'swing', file: 'data/director/swing.json', path: ['enabled'], from: false, to: true, needs: ['gen3'], optional: true,
    probe: '"swings": (st.swing.n if st.swing != null else -1), "swing": ({"on": st.swing.active, "rate": snappedf(st.swing.rate, 0.1), "left": snappedf(st.swing.left, 0.1), "cause": st.swing.cause, "kind": st.swing.kind} if st.swing != null else {}), "fst": [st.fighters[0].state, st.fighters[1].state], "ln": [st.fighters[0].launchN, st.fighters[1].launchN], "pz": [st.pause.left, snappedf(st.dirS.stop, 0.01)]',
    probeMore: [{ line: '"mv": SimSwing.movingNow(st)', probeIf: { file: 'sim/core/swing.gd', text: 'func movingNow' } },
      { line: '"swingOn": DirSwing.on(st)', probeIf: { file: 'sim/director/swing.gd', text: 'static func on(S: SimState)' } },
      { line: '"stickOn": DirStick.on()', probeIf: { file: 'sim/director/stick.gd', text: 'static func on() -> bool' } }], probeIf: { file: 'sim/core/state.gd', text: 'var swing = null' },
    what: 'DirSwing (Encounter): the choreographer\'s swing: a launch, a chase, a form\'s pause, an AI\'s flight and a brawl each offer the line a turn, which the core\'s SimSwing runs. data/director/swing.json `enabled`; it does nothing but on a field world, so it needs gen3 (setup planet, touch, planetGen 3). Waits until the tree has Encounter\'s code' },
  { id: 'everywhere', file: 'data/biomes/field.json', path: ['plans', 'everywhere'], from: false, to: true, needs: ['gen3'], optional: true,
    probe: '"everywhere": WorldPlan.everywhere()', probeIf: { file: 'sim/world/plan.gd', text: 'static func everywhere' },
    what: 'buildings at every place (World, docs/world/places-everywhere.md): each place the first ring does not hold is laid as the whole of its plan, planet-fixed, with no people, so a swing or a launch onto any town finds real buildings. data/biomes/field.json plans.everywhere. Gen 3 only. Waits until the tree has World\'s park (docs/world/pending/places-everywhere)' },
  { id: 'arc', file: 'data/director/launch.json', path: ['arc', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"arc": DirArc.on()', probeIf: { file: 'sim/director/arc.gd', text: 'static func on' },
    what: 'the meteor launch, one curve, with ignition (Encounter, docs/director/pending/meteor and meteor-2; row 5 of rule-of-cool-map.md): a heavy charged to full at tier 4 with two forms each goes up one authored curve, the meteor on a stunned or weak foe. data/director/launch.json arc.enabled. Try it from a training start: ?tier=4. Waits until the tree has Encounter\'s park' },
  { id: 'ending', file: 'data/director/interrupts.json', path: ['ending', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"ending": DirEnding.on()', probeIf: { file: 'sim/director/ending.gd', text: 'static func on' },
    what: 'the match ending (Encounter; Game Design\'s ladder, spec-wounds.md 1b-end): at the time limit the fighter with less wear gets his finisher with no contest, and level wear is a no-contest (a no_contest cue, no KO). data/director/interrupts.json ending.enabled. Waits until the tree has Encounter\'s park (docs/director/pending/match-ending)' },
  { id: 'follow', file: 'data/director/interrupts.json', path: ['bands', 'follow', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"follow": DirFollow.on()', probeIf: { file: 'sim/director/follow.gd', text: 'static func on' },
    what: 'a far press follows him (Encounter, docs/director/pending/far-follow; row 42): for 150 ticks after a send or knock-back he threw, a far tap flies him after the target instead of taunting. data/director/interrupts.json bands.follow.enabled. Waits until the tree has Encounter\'s park' },
  { id: 'lightStops', file: 'data/director/stick.json', path: ['lightStops'], from: true, to: false, needs: ['rightStick'], optional: true,
    probe: '"lightStops": DirStick.lightStops()', probeIf: { file: 'sim/director/stick.gd', text: 'static func lightStops' },
    what: 'a light on a quick flick still lands (Encounter, docs/director/pending/stick-directions): no stun, worth softWorth, so the direction shows; LB held through a flick holds the guard. data/director/stick.json lightStops, false here. True is today\'s rule. Waits for the stick-directions park' },
  { id: 'grapple', file: 'data/director/interrupts.json', path: ['grapple', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"grapple": DirGrapple.on()', probeIf: { file: 'sim/director/grapple.gd', text: 'static func on' },
    what: 'A in a brawl catches (the clinch and the throws) and a far A taunts: data/director/interrupts.json grapple.enabled. Off as shipped' },
  { id: 'driver', file: 'data/director/interrupts.json', path: ['blast', 'driver', 'enabled'], from: false, to: true, needs: ['signatureRtOnly'], optional: true,
    probe: '"driver": DirDriver.on()', probeIf: { file: 'sim/director/driver.gd', text: 'static func on' },
    what: 'RB + B is the Driver (Encounter, docs/director/pending/driver): hold B with RB to gather, let go to fire; a player\'s only. data/director/interrupts.json blast.driver.enabled. Needs driverOnRb with signatureRtOnly. Waits for the driver park' },
  { id: 'driverOnRb', file: 'data/input/timing.json', path: ['switches', 'driverOnRb'], from: false, to: true, needs: ['signatureRtOnly'], optional: true,
    probe: '"driverOnRb": SimInputData.driver_on_rb()', probeIf: { file: 'sim/input/input_data.gd', text: 'func driver_on_rb' },
    what: 'with signatureRtOnly, RB + B stays a B press for the Driver to read instead of being sent as Y\'s blast (Controls, signature-rt-only.patch). timing.json switches.driverOnRb. Waits for Controls\' stick-feel round 4' },
  { id: 'beamMove', file: 'data/director/interrupts.json', path: ['beamPlays', 'front', 'ownMove', 'enabled'], from: false, to: true, needs: ['rightStick', 'beamFront'], optional: true,
    what: 'the beam as its own move (Encounter, docs/director/pending/beam-move): beamPlays.front.ownMove.enabled. It needs the right stick, the beam front (beamFront: beamPlays.front.enabled) and the stationary front (front.stationary, on in the data). Waits for the park' },
  { id: 'stallKeep', file: 'data/input/timing.json', path: ['switches', 'stallKeep'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"stallKeep": SimInputData.stall_keep_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func stall_keep_on' },
    what: 'no input lost in a stall (Controls, docs/controls/pending/impact-haptics, refusals): when the page hitches and several game steps read one pad snapshot, every button press and the stick\'s furthest point since the last step are kept. timing.json switches.stallKeep. Waits for the park' },
  { id: 'hapticImpact', file: 'data/input/timing.json', path: ['switches', 'hapticImpact'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"hapticImpact": SimInputData.haptic_impact_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func haptic_impact_on' },
    what: 'the impact rumble (Controls, docs/controls/impact-haptics.md): landed blows, closes, launches and landings, building breaks on the pad (Orb\'s 2026-10-05 picks). timing.json switches.hapticImpact. Waits for the park' },
  { id: 'dodgeHeld', file: 'data/input/timing.json', path: ['switches', 'dodgeHeld'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"dodgeHeld": SimInputData.dodge_held_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func dodge_held_on' },
    what: 'LT held in the intent\'s second word (Controls, docs/controls/dodge-held.md): the flight strike\'s take-back reads whether LT is still down at the face press. timing.json switches.dodgeHeld. Waits for the park and for Encounter to read it' },
  { id: 'hapticStages', file: 'data/input/timing.json', path: ['switches', 'hapticStages'], from: false, to: true, needs: ['beamMove', 'hapticLadder'], optional: true,
    probe: '"hapticStages": SimInputData.haptic_stages_on()', probeIf: { file: 'sim/input/input_data.gd', text: 'func haptic_stages_on' },
    what: 'the stages of a charge on the pad (Controls, docs/controls/pending/stage-pulses): a pulse for each stick_stage cue of Encounter. timing.json switches.hapticStages. Needs beamMove, and the hapticLadder row too (SimInputData.haptic_stages_on() is the ladder AND the flag). With beamMove off a hold is silent. Waits for the park' },
  { id: 'refusedCue', file: 'data/director/interrupts.json', path: ['press', 'refusedCue'], from: false, to: true, needs: [], optional: true,
    what: 'every refused press says so with a cue (Encounter, the morning fixes, batch 3): the press refused word at the edge and the knock on the pad, so a press never vanishes in silence. interrupts.json press.refusedCue. Waits for the park' },
  { id: 'strikeStages', file: 'data/director/stick.json', path: ['strikeStages', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    what: 'strike charge stages by power (Encounter, docs/director/pending/strike-stages; beams-own-move-plan step 2): 2 to 6 stages, a held charge that never fires by itself. data/director/stick.json strikeStages.enabled. Waits for the park' },
  { id: 'beamMoveAi', file: 'data/director/interrupts.json', path: ['beamPlays', 'front', 'ownMove', 'ai'], from: false, to: true, needs: ['beamMove'], optional: true,
    what: 'the computer fires its beam through the same own move (Encounter, docs/director/pending/beam-ai). beamPlays.front.ownMove.ai. Needs beamMove. Waits for the park' },
  { id: 'pushMode', file: 'data/director/interrupts.json', path: ['beamStruggle', 'pushMode', 'enabled'], from: false, to: true, needs: ['struggle'], optional: true,
    alsoIn: { file: 'render/core/sim_host.gd', text: 'pushModeOf', why: 'the host line of Controls (docs/controls/pending/push-stick/host-push.patch): with pushMode on and no stick passed through, nothing pushes in a struggle' },
    what: 'what pushes in a beam struggle, chosen per player (Encounter, docs/director/pending/push-mode; Game Design: rhythm on the right stick by default, or on the face buttons). beamStruggle.pushMode.enabled; the choice rides in the match setup per slot. Waits for the park and Simulation\'s grant' },
  { id: 'pushUi', file: 'ui/data/options.json', path: ['options', 'struggle_push', 'default'], from: 'face', to: 'stick', needs: ['pushMode'], optional: true,
    what: 'the beam struggle push option of player 1 defaults to the right stick only when pushMode is on (UI, ui/data/options.json options.struggle_push.default; the shipped default is face, so a struggle panel never teaches a push the sim does not read). The row is on with pushMode and off without it' },
  { id: 'pushUi2', file: 'ui/data/options.json', path: ['options', 'struggle_push_p2', 'default'], from: 'face', to: 'stick', needs: ['pushMode'], optional: true,
    what: 'the same for player 2 (options.struggle_push_p2.default)' },
  { id: 'wallPush', file: 'data/director/launch.json', path: ['walk', 'enabled'], from: false, to: true, needs: [], optional: true, held: 'waiting on QA city read',
    what: 'the wall push (Encounter, docs/director/pending/city-push): a landed blow carries the pair toward the nearest standing building, so a slam can happen. launch.json walk.enabled (walk.reachWalked stays off: it is on Orb bystander hold, RL-247). Held off until QA city read' },
  { id: 'wallPushAi', file: 'data/director/launch.json', path: ['walk', 'ai', 'enabled'], from: false, to: true, needs: ['wallPush'], optional: true, held: 'waiting on QA city read',
    what: 'the computer leans for the wall push by its personality (Encounter, city-push). launch.json walk.ai.enabled. Needs wallPush. Held off until QA city read' },
  { id: 'slamTurn', file: 'data/director/swing.json', path: ['slam', 'enabled'], from: false, to: true, needs: ['swing'], optional: true, held: 'waiting on QA city read',
    what: 'a wall slam or a lodge turns the world: it can start a big swing, cause slam (Encounter, city-push). data/director/swing.json slam.enabled. Needs swing. Held off until QA city read' },
  { id: 'cityHold', file: 'data/biomes/brunt.json', path: ['lodgeHold'], from: 'world', to: 'body', needs: [], optional: true, held: 'waiting on QA city read',
    more: [{ path: ['wallRebound'], from: 0.25, to: 0 }, { path: ['wallStop'], from: 1, to: 0 }, { path: ['wallDepthHold'], from: 0, to: 1 }, { path: ['repeatMarks'], from: 0, to: 2 }],
    what: 'the wall hold of World (docs/design/playable-build.md section 4): a body that meets a wall is held by it, no rebound, no stop, held at its depth, and repeat marks 2. data/biomes/brunt.json lodgeHold body, wallRebound 0, wallStop 0, wallDepthHold 1, repeatMarks 2, as one row. Held off until QA city read' },
  { id: 'flightStrikes', file: 'data/director/interrupts.json', path: ['zip', 'flightStrikes', 'enabled'], from: false, to: true, needs: ['rightStick', 'signatureRtOnly'], optional: true,
    more: [{ file: 'data/input/timing.json', path: ['switches', 'flightStrikeB'], from: false, to: true }, { file: 'data/input/timing.json', path: ['switches', 'dodgeHeld'], from: false, to: true }],
    what: 'the flight strikes (Encounter): three keys as one row, across two files: interrupts.json zip.flightStrikes.enabled, timing.json switches.flightStrikeB and switches.dodgeHeld (the same key as the dodgeHeld row; either row turns it on). Needs rightStick and signatureRtOnly. ON in the next build (the EP, 2026-11-07); it waits, naming the key, until the park that adds it lands' },
  { id: 'aimCuts', file: 'data/director/launch.json', path: ['aimCuts', 'enabled'], from: false, to: true, needs: [], optional: true, held: 'held for the next batch\'s page (EP)',
    what: 'the aim cuts (Encounter): data/director/launch.json aimCuts.enabled. Held off in the morning build; for the next batch\'s page' },
  { id: 'stickLungeLight', file: 'data/director/stick.json', path: ['lungeLight', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    what: 'the light lunge on the stick (Encounter): data/director/stick.json lungeLight.enabled. Needs rightStick. ON in the next build (the EP, 2026-11-07); it waits, naming the key, until the park that adds it lands' },
  { id: 'flickKeep', file: 'data/director/stick.json', path: ['flickKeep', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    more: [{ path: ['pendFollow', 'enabled'], from: false, to: true }, { file: 'data/input/timing.json', path: ['switches', 'flickKept'], from: false, to: true, ifPresent: true }],
    what: 'a stick flick that cannot start now is kept (Encounter, docs/director/pending/refusal-reasons; Game Design ruling 1): held, the newest only, quietly, and his first blow out. data/director/stick.json flickKeep.enabled. ON in Sunday\'s build (the EP, 2026-11-07); it waits, naming the key, until the park lands. The new refusal knocks ride press.refusedCue, which stays held' },
  { id: 'flickRun', file: 'data/director/stick.json', path: ['flickRun', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    what: 'a landed quick flick counts in its striker\'s run, with the steal on top (Game Design, stick-lands.md; the refusal-reasons park sets its points to 1.5). data/director/stick.json flickRun.enabled. ON in Sunday\'s build (the EP, 2026-11-07)' },
  { id: 'fullSend', file: 'data/director/stick.json', path: ['fullSend', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    more: [{ file: 'ui/data/features.json', path: ['features', 'slam_hint'], from: false, to: true }],
    what: 'the stick\'s full send and the slam (Encounter, docs/director/pending/stick-slam; Game Design slam-and-pace section 1): a hold to the top stage sends, down on a foe in the air is the slam. data/director/stick.json fullSend.enabled, and in the same row UI\'s "Hold to slam" hint, ui/data/features.json features.slam_hint (UI: turn it on in the same commit as fullSend). ON in Sunday\'s build (the EP, 2026-11-07); it waits until both parks (stick-slam and slam-hint) have landed' },
  { id: 'chordPick', file: 'data/input/timing.json', path: ['switches', 'chordPick'], from: false, to: true, needs: ['hapticRefused'], optional: true,
    what: 'a chord is the biggest press (Controls, docs/controls/pending/chord-full-send; docs/controls/chord-pick.md): when two buttons come together the hub picks the biggest and says what it dropped, and the full send has its own haptic. timing.json switches.chordPick. Needs hapticRefused (the hub needs it to knock and list the drop). ON in Sunday\'s build (the EP, 2026-11-07); it waits, naming the key, until the park lands' },
  { id: 'airBrake', file: 'data/fight/brake.json', path: ['enabled'], from: false, to: true, needs: [], optional: true,
    what: 'the air brake (Game Design, buildings.md 7.2; sim/core/brake.gd): hold LT to brake while knocked back in the air. data/fight/brake.json enabled; SimCore.newMatch copies it into the match, and the file joins a replay\'s data hash only when on. After Simulation\'s determinism and rollback checks' },
  { id: 'stances', file: 'data/director/interrupts.json', path: ['stances', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"stances": DirStance.on()', probeIf: { file: 'sim/director/stance.gd', text: 'static func on' },
    what: 'LB and LT on a blow (Encounter, docs/director/pending/stances; pad-first-press.md): the check, the push and the rest differ. data/director/interrupts.json stances.enabled. Needs the stick. Waits for the stances park' },
  { id: 'phrases', file: 'data/combat/phrases.json', path: ['enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"phrases": DirPhrase.on()', probeIf: { file: 'sim/director/phrase.gd', text: 'static func on' },
    what: 'each fighter\'s phrases (Combat\'s lists, Encounter\'s hook; rule-of-cool-map.md row 1): a press inside a phrase takes its next piece, a mash counts as part of it. data/combat/phrases.json enabled. Waits for the phrases and hook parks' },
  { id: 'craterlook', url: 'craterlook=1', presentIf: { file: 'render/core/tile_ground.gd', text: 'crater_look' }, needs: ['tiles'], optional: true,
    what: 'Art\'s crater and scar looks (Rendering, 2026-11-01i; docs/art/crater-look.md): walls in two rings toned by their facing, a warm floor, a burn for the scar. A page word on a local page, on the tile ground only. Waits for the crater-scar-look park' },
  { id: 'vsHuman', file: 'data/director/ai.json', path: ['vsHuman', 'enabled'], from: false, to: true, needs: [], optional: true,
    what: 'the beams of the AI against a human (Encounter, docs/director/pending/clash-window): it fires its first by 25 to 45 s and paces the rest when the human could pay and answer. data/director/ai.json vsHuman.enabled. Waits for the clash-window park' },
  { id: 'firstMeteor', file: 'data/director/launch.json', path: ['arc', 'firstMeteor'], from: false, to: true, needs: ['arc'], optional: true,
    what: 'a stand-in rule for trying the meteor (Encounter, docs/director/pending/meteor-route): the first planet-scale launch of the match IS the meteor, whatever the rival is doing. Both at tier 4 (the full-power address), fly next to him, hold B until the flash, let go. data/director/launch.json arc.firstMeteor. Waits for the meteor-route park' },
  { id: 'beamFront', file: 'data/director/interrupts.json', path: ['beamPlays', 'front', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"beamFront": DirBeamPlay.frontOn()', probeIf: { file: 'sim/director/beamplay.gd', text: 'static func frontOn' },
    what: 'beams that travel, and the window to answer (Encounter, docs/director/pending/beam-front; row 40 of rule-of-cool-map.md): the beam takes ticks from hand to him, the hit is decided at arrival, and he can fire back, dodge in the last 14 ticks or block. data/director/interrupts.json beamPlays.front.enabled. Waits until the tree has Encounter\'s park' },
  { id: 'kick', file: 'data/fight/kick.json', path: ['enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"kick": SimKick.enabled()', probeIf: { file: 'sim/core/kick.gd', text: 'static func enabled' },
    what: 'the kick and the coin turn (Simulation, docs/architecture/kick.md; rule-of-cool-map.md row 23): flat out from under half of top speed leaves at `instant` of top speed on the first tick (default 0.8) and reaches top speed over `climbTicks` (default 8) (Orb: instant, or at least instant to about 80%); a stick flip above half of top speed brakes, plants and kicks the other way. The overspeed is its own switch and off. Page words to try values: ?instant=0.9&climbTicks=4 (the printed sample addresses). data/fight/kick.json enabled. A setup\'s "kick" overrides it for a match: the page word ?kick=1 puts true in the setup, ?kick=off puts false (to compare). Waits until the tree has Simulation\'s park (docs/architecture/pending/kick)' },
  { id: 'mixed', file: 'data/combat/mixed.json', path: ['enabled'], from: false, to: true, needs: ['rightStick'], optional: true,
    probe: '"mixed": DirMixed.on()', probeIf: { file: 'sim/director/mixed.gd', text: 'static func on' },
    what: 'the mixed string (Combat, Orb\'s clip C9; docs/design/energy-overhaul.md section 21): a send or a knock opens a string across any range, and in it a tapped far heavy is a lob aimed where he is going, timed to land as he does. data/combat/mixed.json enabled. Needs the right hand. A prototype nobody has played. Waits until the tree has Combat\'s park (docs/combat/pending/mixed-string)' },
  { id: 'struggle', file: 'data/director/interrupts.json', path: ['beamStruggle', 'enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"struggle": DirBeam.struggleOn()', probeIf: { file: 'sim/director/beam.gd', text: 'static func struggleOn' },
    alt: { add: 'struggle=off', label: 'the beam struggle OFF (Encounter\'s page word; on by default here)' },
    what: 'the beam struggle on the pulse: surges, strays and letting go (Encounter; Game Design\'s redesign after Orb\'s playtest of 2026-10-16: what you press during the clash moves the outcome). data/director/interrupts.json beamStruggle.enabled. On by default on the private page; ?struggle=off on a local page turns it off. Waits until the tree has Encounter\'s park (docs/director/pending/beam-struggle)' },
  { id: 'soundTug', file: 'audio/data/tug_cues.json', path: ['enabled'], from: false, to: true, needs: ['struggle'], optional: true,
    probe: '"soundTug": host.audio_cues.tug.enabled()', probeIf: { file: 'audio/audio_tug.gd', text: 'func enabled' },
    what: 'the beam struggle sound (Audio, docs/audio/first-play-sound.md): the two-drone bed, the pulse, surge, stray, lock and end, in the lower family. audio/data/tug_cues.json enabled. Needs the beam struggle (its events). Read back: host.audio_cues.tug.enabled()' },
  { id: 'soundMoments', file: 'audio/data/moment_cues.json', path: ['enabled'], from: false, to: true, needs: [], optional: true,
    probe: '"soundMoments": host.audio_cues.moments.enabled()', probeIf: { file: 'audio/audio_moments.gd', text: 'func enabled' },
    what: 'the moments a player would notice (Audio, docs/audio/pending/moments): a beam charging and firing, the KO, the biggest blows, a launch, the meteor landing, a parry, two bolts meeting; existing sounds only, low and chunky. audio/data/moment_cues.json enabled. Read back: host.audio_cues.moments.enabled()' },
  { id: 'soundCarry', file: 'audio/data/carry_cues.json', path: ['enabled'], from: false, to: true, needs: ['soundTug'], optional: true,
    probe: '"soundCarry": host.audio_cues.carry.enabled()', probeIf: { file: 'audio/audio_carry.gd', text: 'func enabled' },
    what: 'the carry sounds (Audio, docs/audio/first-play-sound.md): what the HUD no longer draws, said in sound. audio/data/carry_cues.json enabled. Needs the beam struggle sound. Read back: host.audio_cues.carry.enabled()' },
];

export const IDS = SWITCHES.map((s) => s.id);

/** The switches of a build: the table above, and the rows of tools/preview/switches-pending.json that name a file and a key (a row without them is a name waiting for its key and is never a switch). */
export function tableWith(pending = []) {
  const known = new Set(SWITCHES.map((s) => s.id));
  return [...SWITCHES, ...pending.filter((r) => r && r.file && Array.isArray(r.path) && !known.has(r.id)).map((r) => ({ needs: [], optional: true, ...r }))];
}

/** Checks the rows of switches-pending.json (text in). Returns { rows, problems }: every row needs an id and a line saying what it is and who lands it; a row with a file also needs a path, from and to. */
export function loadPending(text) {
  const problems = [];
  let doc = null;
  try { doc = JSON.parse(text); } catch (e) { return { rows: [], problems: [`switches-pending.json is not JSON: ${e.message}`] }; }
  const rows = Array.isArray(doc.rows) ? doc.rows : [];
  const seen = new Set(SWITCHES.map((s) => s.id));
  rows.forEach((r, i) => {
    const at = `row ${i}${r && r.id ? ` (${r.id})` : ''}`;
    if (!r || typeof r.id !== 'string' || !/^[a-zA-Z][a-zA-Z0-9]*$/.test(r.id)) { problems.push(`${at}: needs an id of letters and digits`); return; }
    if (seen.has(r.id)) problems.push(`${at}: the id is already a switch or a row`);
    seen.add(r.id);
    if (typeof r.what !== 'string' || !r.what.trim() || typeof r.owner !== 'string' || !r.owner.trim()) problems.push(`${at}: needs "what" and "owner"`);
    if (r.file !== undefined && !(typeof r.file === 'string' && Array.isArray(r.path) && r.path.length && 'from' in r && 'to' in r)) problems.push(`${at}: a row with a file needs path (an array), from and to`);
    if (r.needs !== undefined && !(Array.isArray(r.needs) && r.needs.every((n) => typeof n === 'string'))) problems.push(`${at}: needs is a list of ids`);
  });
  return { rows, problems };
}

/** Where a key's value is in a JSON text: { start, end } of the value, or null. Walks the text (strings, nesting) without parsing the whole file, so the edit keeps everything else as it was. */
export function locate(text, path) {
  let i = text.charCodeAt(0) === 0xfeff ? 1 : 0;
  const ws = () => { while (i < text.length && /\s/.test(text[i])) i++; };
  const str = () => { const s0 = i; i++; while (i < text.length && text[i] !== '"') { if (text[i] === '\\') i++; i++; } i++; return JSON.parse(text.slice(s0, i)); };
  const skip = () => {
    ws();
    const c = text[i];
    if (c === '"') { str(); return; }
    if (c === '{' || c === '[') {
      const close = c === '{' ? '}' : ']';
      i++; ws();
      if (text[i] === close) { i++; return; }
      for (;;) {
        ws();
        if (c === '{') { str(); ws(); i++; }
        skip(); ws();
        if (text[i] === ',') { i++; continue; }
        i++; return;
      }
    }
    while (i < text.length && !/[,}\]\s]/.test(text[i])) i++;
  };
  const walk = (depth) => {
    ws();
    if (text[i] !== '{') return null;
    i++;
    for (;;) {
      ws();
      if (i >= text.length) return null;
      if (text[i] === '}') { i++; return null; }
      const key = str(); ws(); i++; ws();
      if (key === path[depth]) {
        if (depth === path.length - 1) { const start = i; skip(); return { start, end: i }; }
        const at = i;
        const r = walk(depth + 1);
        if (r) return r;
        if (i === at) skip();   // the value was not an object: step over it
      } else skip();
      ws();
      if (text[i] === ',') i++;
    }
  };
  return walk(0);
}

/** Whether a switch's key is in a file's text: its path in JSON, or (a switch that is a constant in a script) its text, as it is off or on. */
export function present(text, sw) {
  if (sw.replace) return text.includes(sw.replace.from) || text.includes(sw.replace.to);
  return (sw.ifPresentPrimary || !!locate(text, sw.path)) && (sw.more || []).every((m) => m.ifPresent || !!locate(text, m.path));
}

/** The files a row touches, each with the row as it reads for that file: [{ file, sw }]. A row's `more` keys belong to the row's own file unless one names a `file` of its own (flightStrikes: one key in interrupts.json and two in timing.json), so one row can flip keys across files. Every caller loops over these, and a row is on only if every part is. */
export function parts(sw) {
  if (!sw.more || !sw.more.some((m) => m.file && m.file !== sw.file)) return [{ file: sw.file, sw }];
  const keys = [{ file: sw.file, path: sw.path, from: sw.from, to: sw.to }, ...sw.more.map((m) => ({ file: m.file || sw.file, path: m.path, from: m.from, to: m.to, ifPresent: !!m.ifPresent }))];
  const out = [];
  for (const f of [...new Set(keys.map((k) => k.file))]) {
    const ks = keys.filter((k) => k.file === f);
    out.push({ file: f, sw: { ...sw, file: f, path: ks[0].path, from: ks[0].from, to: ks[0].to, ifPresentPrimary: !!ks[0].ifPresent, more: ks.length > 1 ? ks.slice(1).map((k) => ({ path: k.path, from: k.from, to: k.to, ifPresent: !!k.ifPresent })) : undefined } });
  }
  return out;
}

/** The text with a switch turned on. Returns { text, was }: was is the old literal. Throws, naming the file and key, when the key is not there or holds neither the old nor the new value (the table is stale). */
export function flip(text, sw) {
  if (sw.ifPresentPrimary && !locate(text, sw.path)) return flipRest(text, sw, '(absent)');   // the file group's own first key is an ifPresent key the file does not have: only the rest of the group (none, or more ifPresent keys)
  if (!sw.more) return flipOne(text, sw);
  let out = flipOne(text, sw);   // a row of several keys of one file (cityHold): the first key is the row's own, the others follow it, each from its own old value to its own new one
  const was = out.was;
  let t = out.text;
  for (const m of sw.more) { if (m.ifPresent && !locate(t, m.path)) continue; t = flipOne(t, { ...sw, path: m.path, from: m.from, to: m.to, more: undefined, ifPresentPrimary: false }).text; }
  return { text: t, was };
}
function flipRest(text, sw, was) {
  let t = text;
  for (const m of sw.more || []) { if (m.ifPresent && !locate(t, m.path)) continue; t = flipOne(t, { ...sw, path: m.path, from: m.from, to: m.to, more: undefined, ifPresentPrimary: false }).text; }
  return { text: t, was };
}
function flipOne(text, sw) {
  if (sw.replace) {   // a constant in a script: its text appears exactly once, off or on
    const { from, to } = sw.replace;
    const nFrom = text.split(from).length - 1, nTo = text.split(to).length - 1;
    if (nFrom === 1 && nTo === 0) return { text: text.replace(from, () => to), was: from };
    if (nTo === 1 && nFrom === 0) return { text, was: to };
    throw new Error(`${sw.file}: the text "${from}" is there ${nFrom} times and "${to}" ${nTo} (exactly one of them once was expected: the switch table in tools/preview/switches.mjs is out of date)`);
  }
  const loc = locate(text, sw.path);
  if (!loc) throw new Error(`${sw.file}: no key ${sw.path.join('.')} (the switch table in tools/preview/switches.mjs is out of date)`);
  const was = text.slice(loc.start, loc.end);
  const from = JSON.stringify(sw.from), to = JSON.stringify(sw.to);
  const sameNum = typeof sw.from === "number" && (Number(was) === sw.from || Number(was) === sw.to);   // 0.0 in the file is the number 0
  if (was !== from && was !== to && !sameNum) throw new Error(`${sw.file}: ${sw.path.join('.')} is ${was}, not ${from} or ${to} (the switch table in tools/preview/switches.mjs is out of date)`);
  const out = text.slice(0, loc.start) + to + text.slice(loc.end);
  let v = JSON.parse(out.charCodeAt(0) === 0xfeff ? out.slice(1) : out);
  for (const k of sw.path) v = v == null ? undefined : v[k];
  if (v !== sw.to) throw new Error(`${sw.file}: after the edit ${sw.path.join('.')} reads ${JSON.stringify(v)}, not ${to}`);
  return { text: out, was };
}

/** Which switches are on, given the ids turned off ("all" turns every one off). Turning one off turns off what needs it. Returns { active, cascaded: [{ id, because }], unknown }. */
export function resolve(off = [], table = SWITCHES, on = []) {
  const IDS = table.map((s) => s.id);
  const want = new Set(off.flatMap((o) => String(o).split(',')).map((s) => s.trim()).filter(Boolean));
  const wantOn = new Set(on.flatMap((o) => String(o).split(',')).map((s) => s.trim()).filter(Boolean));
  const unknown = [...want, ...wantOn].filter((id) => id !== 'all' && !IDS.includes(id));
  // a row with `held` (a reason) is off in a build unless asked for with --on: it is on the list, off, with its reason (the city rows wait on QA's read)
  const held = table.filter((s) => s.held && !wantOn.has(s.id)).map((s) => ({ id: s.id, why: s.held }));
  const heldIds = new Set(held.map((h) => h.id));
  const active = new Set(want.has('all') ? [] : IDS.filter((id) => !want.has(id) && !heldIds.has(id)));
  const cascaded = [];
  for (let again = true; again;) {
    again = false;
    for (const sw of table) {
      if (!active.has(sw.id)) continue;
      const missing = sw.needs.filter((n) => !active.has(n));
      if (missing.length) { active.delete(sw.id); cascaded.push({ id: sw.id, because: missing }); again = true; }
    }
  }
  return { active: IDS.filter((id) => active.has(id)), cascaded, unknown, held };
}

/** Which switch a load error or console line is about, by the file or module it names. A hint for the report, not a proof. */
export function errorSwitch(line) {
  const t = String(line);
  if (/water\.json[^\n]*floor|floor needs/i.test(t)) return 'floor';
  if (/water\.json[^\n]*surface|surfacing/i.test(t)) return 'surface';
  if (/interrupts\.json|DirWater|DirInterrupt/i.test(t)) return 'interrupts';
  if (/water\.json|WorldFill|water v2/i.test(t)) return 'water';
  if (/rings\.json|WorldEpoch/i.test(t)) return 'turn';
  if (/right_stick|rightStick|strike_read|SimStrike|left_hand/i.test(t)) return 'rightStick';
  if (/meteor/i.test(t)) return 'meteor';
  if (/WorldField|SimField|field world|planetGen 3/i.test(t)) return 'gen3';
  if (/launch_biome|DirLaunch|biome\.enabled/i.test(t)) return 'biome';
  if (/climate\.json|WorldClimate|WorldPlanet|planet gen|lakes\.json|sites\.json/i.test(t)) return 'gen2';
  return null;
}

// ---- the scratch changes to render/core/main.gd ----

/** The probe and the planet entry, as GDScript (tab-indented). `planetFunc(extra)` adds probe fields (a switch's `probe` line) when the tree has what they read. */
export const PLANET_FUNC = [
  '',
  '',
  '## Scratch (tools/preview): what the own mixer of the engine says (read only): the mix rate, and for Master, Sfx and Voice the volume, the mute and the peak level of the last mix, so a silent page can be told apart: nothing mixed, or nothing reaching the browser.',
  'func _pv_aud() -> Array:',
  '\tvar out: Array = [AudioServer.get_mix_rate(), AudioServer.get_bus_count()]',
  '\tfor nm in ["Master", "Sfx", "Voice"]:',
  '\t\tvar i: int = AudioServer.get_bus_index(nm)',
  '\t\tif i < 0:',
  '\t\t\tout.append([nm, "no such bus"])',
  '\t\telse:',
  '\t\t\tout.append([nm, snappedf(AudioServer.get_bus_volume_db(i), 0.1), AudioServer.is_bus_mute(i), clampf(snappedf(AudioServer.get_bus_peak_volume_left_db(i, 0), 0.1), -200.0, 40.0), clampf(snappedf(AudioServer.get_bus_peak_volume_right_db(i, 0), 0.1), -200.0, 40.0)])',
  '\treturn out',
  '',
  '',
  '## Scratch (tools/preview): ?audiolog=1: after each frame, the highest peak of Master, Sfx and Voice so far, and the number of frames above -60 dB, told to the page (window.__audeng) twice a second. Read only.',
  'var _pv_ae_max: Array = [-200.0, -200.0, -200.0]',
  'var _pv_ae_loud: Array = [0, 0, 0]',
  'var _pv_ae_frames: int = 0',
  'var _pv_ae_voices: Dictionary = {"nodes": 0, "playingMax": 0, "withStream": 0, "longest": 0.0, "loudest": 0, "samples": 0}',
  'func _pv_aud_tick() -> void:',
  '\t_pv_ae_frames += 1',
  '\tvar names: Array = ["Master", "Sfx", "Voice"]',
  '\tfor k in range(3):',
  '\t\tvar i: int = AudioServer.get_bus_index(names[k])',
  '\t\tif i < 0:',
  '\t\t\tcontinue',
  '\t\tvar pk: float = maxf(AudioServer.get_bus_peak_volume_left_db(i, 0), AudioServer.get_bus_peak_volume_right_db(i, 0))',
  '\t\tpk = clampf(pk, -200.0, 40.0)',
  '\t\tif pk > float(_pv_ae_max[k]):',
  '\t\t\t_pv_ae_max[k] = pk',
  '\t\tif pk > -60.0:',
  '\t\t\t_pv_ae_loud[k] = int(_pv_ae_loud[k]) + 1',
  '\tif _pv_ae_frames % 30 == 0:',
  '\t\tvar ps: Array = get_tree().root.find_children("*", "AudioStreamPlayer2D", true, false)',
  '\t\tvar playing: int = 0',
  '\t\tvar withs: int = 0',
  '\t\tfor p in ps:',
  '\t\t\tif p.stream != null:',
  '\t\t\t\twiths += 1',
  '\t\t\t\t_pv_ae_voices["longest"] = maxf(float(_pv_ae_voices["longest"]), p.stream.get_length())',
  '\t\t\tif p.playing:',
  '\t\t\t\tplaying += 1',
  '\t\t\t\tif p.stream is AudioStreamWAV and int(_pv_ae_voices["samples"]) < 40:',
  '\t\t\t\t\tvar d: PackedByteArray = (p.stream as AudioStreamWAV).data',
  '\t\t\t\t\tvar m: int = 0',
  '\t\t\t\t\tfor q in range(0, mini(d.size() - 1, 40000), 2):',
  '\t\t\t\t\t\tm = maxi(m, absi(d.decode_s16(q)))',
  '\t\t\t\t\t_pv_ae_voices["loudest"] = maxi(int(_pv_ae_voices["loudest"]), m)',
  '\t\t\t\t\t_pv_ae_voices["samples"] = int(_pv_ae_voices["samples"]) + 1',
  '\t\t_pv_ae_voices["nodes"] = ps.size()',
  '\t\t_pv_ae_voices["withStream"] = withs',
  '\t\t_pv_ae_voices["playingMax"] = maxi(int(_pv_ae_voices["playingMax"]), playing)',
  '\tif _pv_ae_frames % 60 == 0 and OS.has_feature("web") and audio != null and audio.has_method("status_line"):',
  '\t\tJavaScriptBridge.eval("window.__audstatus && window.__audstatus(%s)" % JSON.stringify(audio.status_line()), true)',
  '\tif _pv_ae_frames % 30 == 0 and OS.has_feature("web"):',
  '\t\tJavaScriptBridge.eval("window.__audeng && window.__audeng(%s)" % JSON.stringify({"frames": _pv_ae_frames, "maxDb": {"master": snappedf(float(_pv_ae_max[0]), 0.1), "sfx": snappedf(float(_pv_ae_max[1]), 0.1), "voice": snappedf(float(_pv_ae_max[2]), 0.1)}, "voices": _pv_ae_voices, "framesAbove60": {"master": _pv_ae_loud[0], "sfx": _pv_ae_loud[1], "voice": _pv_ae_loud[2]}}), true)',
  '',
  '',
  '## Scratch (tools/preview): ?splitshare=N: the split share for a comparison (Camera swing-share, 0.5 to 1), set each frame on the split rig when the park is in the tree.',
  'func _pv_split_share() -> void:',
  '\tif split_rig != null and split_rig.get("split_share") != null:',
  '\t\tsplit_rig.split_share = float(str(args["splitshare"]))',
  '',
  '',
  '## Scratch (tools/preview): ?script=1 on a LOCAL page: the capture driver\'s script (window.__script: { scene: { distanceUnits }, events: [[tick, op, a, b], ...] }) is fed to a scripted pad before each tick it is due. Ops: b (a button by name, a bool), t (a trigger, 0 to 1), rs and ls (a stick, x and y). Player 1 is pad 0; player 2 is pad 1 and plays nothing. Publishes window.__ps = { t, hold, hp } each frame.',
  'var _ps_events: Array = []',
  'var _ps_dist: float = 80.0',
  'var _ps_loaded: bool = false',
  'var _ps_claimed: bool = false',
  'var _ps_t0: int = -1',
  'func _preview_script() -> void:',
  '\tif not args.has(\"script\") or host == null or host.S == null:',
  '\t\treturn',
  '\tif not (OS.has_feature(\"web\") and bool(JavaScriptBridge.eval(\"location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\'\", true))):',
  '\t\treturn',
  '\tif not _ps_loaded:',
  '\t\tvar txt: String = str(JavaScriptBridge.eval(\"window.__script || \'\'\", true))',
  '\t\tif txt == \"\":',
  '\t\t\treturn',
  '\t\tvar j = JSON.parse_string(txt)',
  '\t\tif not (j is Dictionary):',
  '\t\t\treturn',
  '\t\t_ps_events = j.get(\"events\", [])',
  '\t\t_ps_dist = float(j.get(\"scene\", {}).get(\"distanceUnits\", 80.0))',
  '\t\t_ps_loaded = true',
  '\tif not _ps_claimed:',
  '\t\t_ps_claimed = true',
  '\t\t# the capture hook starts its own match without the page words, so the scene is started again here with the hit-stop setting asked for (the hook has not ticked yet)',
  '\t\tvar hs_want: bool = str(args.get("hitstop", "off")) != "off" and str(args.get("hitstop", "off")) != "0"',
  '\t\tvar su_ps: Dictionary = call("_preview_planet")   # the page\'s own setup (the planet, its generation, the full-power word, hit-stop), as a match started from the page would have it',
  '\t\tsu_ps["hitstop"] = hs_want',
  '\t\tsu_ps["intro"] = false',
  '\t\thost.new_match(int(host.seed), {"p1": true, "p2": true}, su_ps)',
  '\t\thost.hub.pad_button(0, \"back\", true)',
  '\t\thost.hub.pad_button(0, \"back\", false)',
  '\t\thost.hub.pad_button(1, \"back\", true)',
  '\t\thost.hub.pad_button(1, \"back\", false)',
  '\t\thost.take_players()',
  '\t\tfor k in range(2):',
  '\t\t\tif host.S.fighters[k].ai != null:',
  '\t\t\t\thost.toggle_ai(k)',
  '\t\tvar a = host.S.fighters[0]',
  '\t\tvar b = host.S.fighters[1]',
  '\t\tb.x = SimWrap.wrap(a.x + _ps_dist)',
  '\t\tb.y = a.y',
  '\t\t_ps_t0 = host.ticks',
  '\tvar t: int = host.ticks - _ps_t0',
  '\tfor e in _ps_events:',
  '\t\tif int(e[0]) != t:',
  '\t\t\tcontinue',
  '\t\tmatch str(e[1]):',
  '\t\t\t\"b\":',
  '\t\t\t\thost.hub.pad_button(0, str(e[2]), bool(e[3]))',
  '\t\t\t\"t\":',
  '\t\t\t\thost.hub.pad_trigger(0, str(e[2]), float(e[3]))',
  '\t\t\t\"rs\":',
  '\t\t\t\thost.hub.pad_stick_right(0, float(e[2]), float(e[3]))',
  '\t\t\t\"ls\":',
  '\t\t\t\thost.hub.pad_stick(0, float(e[2]), float(e[3]))',
  '\tJavaScriptBridge.eval(\"window.__ps = {t: %d, hold: %s, hp: %f};\" % [t, \"true\" if host.S.dirS.stop > 0.0 else \"false\", float(host.S.fighters[1].hp)], true)',
  '',
  '',
  '## Scratch (tools/preview): ?replay=1 on a LOCAL page: window.__replay (a saved black box file\'s replay) starts the same match again and the host steps it with the recorded intents (SimReplay\'s own way).',
  'var _pr_done: bool = false',
  'func _preview_replay() -> void:',
  '\tif _pr_done or not args.has(\"replay\") or host == null or host.S == null:',
  '\t\treturn',
  '\tif not (OS.has_feature(\"web\") and bool(JavaScriptBridge.eval(\"location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\'\", true))):',
  '\t\treturn',
  '\tvar txt: String = str(JavaScriptBridge.eval(\"window.__replay || \'\'\", true))',
  '\tif txt == \"\":',
  '\t\treturn',
  '\t_pr_done = true',
  '\tvar rp = JSON.parse_string(txt)',
  '\tif rp is Dictionary and host.has_method(\"bb_play_start\"):',
  '\t\tvar ok: bool = host.bb_play_start(rp)',
  '\t\tJavaScriptBridge.eval(\"window.__pr = {ok: %s, ticks: %d};\" % [\"true\" if ok else \"false\", int(rp.get(\"ticks\", 0))], true)',
  '',
  '',
  '## Scratch (tools/preview): the wall check\'s second reading: does any building, at the height the view DRAWS it, stand across the sight line from this pane\'s camera to each fighter\'s chest? Rendering\'s band rule is in the shader (globe_tower, mode 3), so it is replayed here: at rest only (the swing\'s further lowering is left out, so this is the tallest it can be drawn). A building drawn down to its kept base (90 units or less) is not a wall.',
  'func _pv_occ_all() -> Array:',
  '\tif pane == null or host == null or host.S == null or pane.fighter_views.size() < 2:',
  '\t\treturn []',
  '\tvar S = host.S',
  '\tvar eye: Vector3 = pane.cam_rig.position',
  '\tvar pl = pane.planet',
  '\tvar has_band: bool = (load("res://render/core/look.gd") as GDScript).get_script_constant_map().has("TILE_BAND")   # only a build with Rendering park has the band: without it every building is drawn whole',
  '\tvar band: Vector3 = Vector3(-150.0, -30.0, 150.0)   # the band the tile ground has, written out so a tree without the band park still compiles',
  '\tvar out: Array = []',
  '\tfor i in range(2):',
  '\t\tvar v = pane.fighter_views[i]',
  '\t\tvar p: Vector3 = v.position + Vector3(0.0, FighterView.HEIGHT * 0.5, 0.0)',
  '\t\tvar span: float = eye.z - p.z',
  '\t\tvar hit: bool = false',
  '\t\tvar aim: int = int(S.fighters[i].aimB)',
  '\t\tif span >= 1.0:',
  '\t\t\tfor bi in range(S.buildings.size()):',
  '\t\t\t\tif bi == aim or pl._top[bi] == -INF:',
  '\t\t\t\t\tcontinue',
  '\t\t\t\tvar b = S.buildings[bi]',
  '\t\t\t\tvar zd: Vector2 = pl._depth(b)',
  '\t\t\t\tvar zf: float = zd.x + zd.y * 0.5',
  '\t\t\t\tvar zb: float = zd.x - zd.y * 0.5',
  '\t\t\t\tif zf <= p.z + 1.0 or zb >= eye.z or (has_band and zf > band.z):',
  '\t\t\t\t\tcontinue',
  '\t\t\t\tvar total: float = maxf(WorldStructures.curH(b), 1.0)',
  '\t\t\t\tvar foot: float = pl._top[bi] - total',
  '\t\t\t\tvar rest: float = smoothstep(band.x, band.y, zf) if has_band else 0.0',
  '\t\t\t\tvar kept: float = (minf(90.0, total) * (1.0 - smoothstep(band.y, band.z, zf))) if has_band else total',
  '\t\t\t\tvar drawn_h: float = total * (1.0 - minf(rest, 1.0 - kept / total))',
  '\t\t\t\tif drawn_h <= minf(90.0, total) + 1.0:',
  '\t\t\t\t\tcontinue',
  '\t\t\t\tvar drawn_top: float = foot + drawn_h',
  '\t\t\t\tvar t0: float = (maxf(zb, p.z) - p.z) / span',
  '\t\t\t\tvar t1: float = (minf(zf, eye.z) - p.z) / span',
  '\t\t\t\tvar x0: float = p.x + (eye.x - p.x) * t0',
  '\t\t\t\tvar x1: float = p.x + (eye.x - p.x) * t1',
  '\t\t\t\tvar bx: float = SimWrap.sdx(pane.view_cam_x, b.x)',
  '\t\t\t\tif maxf(x0, x1) < bx - b.w * 0.5 or minf(x0, x1) > bx + b.w * 0.5:',
  '\t\t\t\t\tcontinue',
  '\t\t\t\tif minf(p.y + (eye.y - p.y) * t0, p.y + (eye.y - p.y) * t1) > drawn_top:',
  '\t\t\t\t\tcontinue',
  '\t\t\t\thit = true',
  '\t\t\t\tbreak',
  '\t\tout.append(hit)',
  '\treturn out',
  '',
  '',
  '## Scratch (tools/preview): ?go=1 on a LOCAL page: before the HUD loads its start menu, Player 1 is a controller and Intros are off unless the player saved other choices, and the How to play card counts as seen.',
  'func _preview_go() -> void:',
  '\tif not (OS.has_feature("web") and bool(JavaScriptBridge.eval("location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\'", true))):',
  '\t\treturn',
  '\tif host != null and host.get("bb_on") != null and str(args.get("blackbox", "1")) != "off":   # the black box (tools/preview/blackbox.mjs): on for every local page of this build unless ?blackbox=off; reads, never writes the sim',
  '\t\thost.set("bb_on", true)',
  '\tif not args.has("go"):',
  '\t\treturn',
  '\tvar m = UiPrefs.get_value("menu", {})',
  '\tvar d: Dictionary = m if m is Dictionary else {}',
  '\tif not d.has("p1"):',
  '\t\td["p1"] = "pad"',
  '\tif not d.has("intros"):',
  '\t\td["intros"] = false',
  '\tUiPrefs.set_value("menu", d)',
  '\tUiPrefs.set_bool("howto_seen", true)',
  '\tprint("[preview] go: menu prefs now ", UiPrefs.get_value("menu", {}), " howto_seen ", UiPrefs.get_bool("howto_seen"))',
  '',
  '',
  '## Scratch (tools/preview): the planet part of a match\'s setup. The next menu-started match\'s own (planet_part) when it has one, else ?planet=N from the URL (a generated planet; touch 3 as the golden planet matches use).',
  'func _preview_planet() -> Dictionary:',
  '\tif not _planet_next.is_empty():',
  '\t\treturn _planet_next.duplicate()',
  '\tif args.has("planet"):',
  '\t\treturn {"planet": int(args["planet"]), "touch": int(args.get("touch", 3))}',
  '\treturn {}',
  '',
  '',
  '## Scratch (tools/preview): ?preview=1 publishes window.__preview twice a second (every frame with ?reel=1), for the smoke check: the tick, the planet\'s generation, what each switch reads as in the running game, and the fighters\' hit points.',
  'func _preview_probe() -> void:',
  '\tif frames % 20 != 0 and not args.has("reel"):',
  '\t\treturn',
  '\tvar st = host.S',
  '\tvar hp: Array = []',
  '\tfor f in st.fighters:',
  '\t\thp.append(snappedf(f.hp, 0.1))',
  '\tvar probe: Dictionary = {"tick": host.ticks, "planetGen": WorldClimate.genNow(), "fine": st.fineCols.size(), "planet": not st.planetRing.is_empty(), "dataGen": int(WorldClimate.data().get("gen", 1)),',
  '\t\t"biome": DirLaunch.biomeOn(), "water": WorldFill.on(), "surface": WorldFill.surfaceOn(), "floor": WorldFill.floorOn(), "interrupts": DirWater.on(st), "turn": (WorldEpoch.enabled({}) and bool(DirCalm.cfg().get("enabled", false))), "turns": (st.epoch.n if st.epoch != null else -1),',
  '\t\t"errors": WorldFill.dataErrors(), "hp": hp}',
  '\tJavaScriptBridge.eval("window.__preview = %s;" % JSON.stringify(probe), true)',
  '',
].join('\n');

export function planetFunc(extra = [], setup = {}, opts = {}) {
  const line = '\t\t"errors": WorldFill.dataErrors(), "hp": hp}';
  if (!PLANET_FUNC.includes(line)) throw new Error('tools/preview/switches.mjs: the probe line moved (planetFunc is out of date)');
  const swingsOff = [
    '## Scratch (tools/preview): ?swings=off on a LOCAL page turns DirSwing off before a match starts (Encounter\'s page word; DirSwing.setForce(0)).',
    'func _preview_swings_off() -> void:',
    '\tif OS.has_feature("web") and bool(JavaScriptBridge.eval("(location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\') && location.search.indexOf(\'swings=off\') >= 0", true)):',
    '\t\tDirSwing.setForce(0)',
    '',
    '',
  ].join('\n');
  const sticks = [
    '## Scratch (tools/preview): ?sticks=1 on a LOCAL page: player 1 is claimed by a scripted pad and its right stick is driven every tick: a quick flick at phase 30 and a held charge at 120 to 170 of every 240 ticks, the direction turning each 240; the stick cues are counted (stk).',
    'var _pv_claimed: bool = false',
    'var _pv_stick_n: int = 0',
    'var _pv_stick_kinds: Dictionary = {}',
    'var _pv_beam_kinds: Dictionary = {}',
    'var _pv_arc_kinds: Dictionary = {}',
    'var _pv_hit_t: int = -1',
    'var _pv_bhold: int = 0',
    'var _pv_bgap: int = 0',
    'var _pv_padtxt: String = ""',
    'var _pv_ns: int = 20251101',
    'var _pv_fl_state: int = 0',
    'var _pv_fl_t0: int = 0',
    'var _pv_next_flick: int = 90',
    'var _pv_fl_dir: Vector2 = Vector2.ZERO',
    'var _pv_fl_over: float = 0.0',
    'var _pv_drift: Vector2 = Vector2.ZERO',
    'var _pv_last_flick: int = -1000',
    'var _pv_intended: int = 0',
    'var _pv_real: int = 0',
    'var _pv_phantom: int = 0',
    'var _pv_nd: Array = []',
    'func _pv_rnd() -> float:',
    '\t_pv_ns = (_pv_ns * 1103515245 + 12345) & 0x7fffffff',
    '\treturn float((_pv_ns >> 8) % 10000) / 10000.0',
    'var _pv_conn: bool = false',
    'func _preview_sticks() -> void:',
    '\tif not args.has("sticks") or host == null or host.S == null:',
    '\t\treturn',
    '\tif not (OS.has_feature("web") and bool(JavaScriptBridge.eval("location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\'", true))):',
    '\t\treturn',
    '\tif not _pv_claimed:',
    '\t\t_pv_claimed = true',
    '\t\thost.hub.pad_button(0, "back", true)',
    '\t\thost.hub.pad_button(0, "back", false)',
    '\t\thost.take_players()',
    '\t\tif (str(args["sticks"]) == "2" or str(args["sticks"]) == "7"):   # ?sticks=2: player 2 is a second scripted pad too, firing its signature on the same ticks, so the two beams meet',
    '\t\t\thost.hub.pad_button(1, "back", true)',
    '\t\t\thost.hub.pad_button(1, "back", false)',
    '\t\t\thost.take_players()',
    '\tif host.S.fighters[0].ai != null:',
    '\t\thost.toggle_ai(0)',
    '\tif str(args["sticks"]) == "8" and host.S.fighters[1].ai != null:   # ?sticks=8: the rival stands idle',
    '\t\thost.toggle_ai(1)',
    '\tif (str(args["sticks"]) == "2" or str(args["sticks"]) == "7") and host.S.fighters[1].ai != null:',
    '\t\thost.toggle_ai(1)',
    '\tif str(args["sticks"]) == "6":',
    '\t\t# ?sticks=6: a moving player (as sticks=3) whose right stick is a synthetic thumb: a flick every 60 to 150 ticks in a random one of four directions with 8 degrees of angle noise, 3 ticks out, 6 held, 4 back, then in half the flicks an overshoot into the opposite side at 0.1 to 0.45 for 4 ticks; a constant drift of up to 0.08',
    '\t\tvar a6 = host.S.fighters[0]',
    '\t\tvar b6 = host.S.fighters[1]',
    '\t\tvar side6: float = 1.0 if SimWrap.sdx(a6.x, b6.x) >= 0.0 else -1.0',
    '\t\tvar p6: int = host.ticks % 360',
    '\t\tvar lx6: float = 0.0',
    '\t\tvar ly6: float = 0.0',
    '\t\tvar sprint6: bool = false',
    '\t\tif p6 < 100:',
    '\t\t\tlx6 = side6',
    '\t\t\tsprint6 = true',
    '\t\telif p6 < 160:',
    '\t\t\tlx6 = -side6 * 0.8',
    '\t\telif p6 < 230:',
    '\t\t\tlx6 = side6',
    '\t\t\tly6 = 0.7',
    '\t\t\tsprint6 = true',
    '\t\telse:',
    '\t\t\tlx6 = side6 * 0.5',
    '\t\t\tly6 = -0.6',
    '\t\thost.hub.pad_stick(0, lx6, ly6)',
    '\t\thost.hub.pad_trigger(0, "lt", 1.0 if sprint6 else 0.0)',
    '\t\thost.hub.pad_trigger(0, "rt", 0.0)',
    '\t\thost.hub.pad_button(0, "east", false)',
    '\t\tif _pv_drift == Vector2.ZERO:',
    '\t\t\t_pv_drift = Vector2(_pv_rnd() * 2.0 - 1.0, _pv_rnd() * 2.0 - 1.0).normalized() * (0.04 + 0.04 * _pv_rnd())',
    '\t\tvar out6: Vector2 = Vector2.ZERO',
    '\t\tif _pv_fl_state == 0:',
    '\t\t\tif host.ticks >= _pv_next_flick:',
    '\t\t\t\tvar dirs6: Array = [Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0), Vector2(0.0, -1.0)]',
    '\t\t\t\t_pv_fl_dir = (dirs6[int(_pv_rnd() * 4.0) % 4] as Vector2).rotated((_pv_rnd() * 2.0 - 1.0) * deg_to_rad(8.0))',
    '\t\t\t\t_pv_fl_over = (0.1 + 0.35 * _pv_rnd()) if _pv_rnd() < 0.5 else 0.0',
    '\t\t\t\t_pv_fl_t0 = host.ticks',
    '\t\t\t\t_pv_fl_state = 1',
    '\t\t\t\t_pv_intended += 1',
    '\t\t\t\t_pv_last_flick = host.ticks',
    '\t\tif _pv_fl_state == 1:',
    '\t\t\tvar k6: int = host.ticks - _pv_fl_t0',
    '\t\t\tvar m6: float = 0.0',
    '\t\t\tif k6 < 3:',
    '\t\t\t\tm6 = [0.4, 0.85, 1.0][k6]',
    '\t\t\telif k6 < 9:',
    '\t\t\t\tm6 = 1.0',
    '\t\t\telif k6 < 13:',
    '\t\t\t\tm6 = [0.6, 0.3, 0.1, 0.0][k6 - 9]',
    '\t\t\telif k6 < 17 and _pv_fl_over > 0.0:',
    '\t\t\t\tm6 = -_pv_fl_over * [0.5, 1.0, 0.7, 0.3][k6 - 13]',
    '\t\t\telse:',
    '\t\t\t\t_pv_fl_state = 0',
    '\t\t\t\t_pv_next_flick = host.ticks + 60 + int(_pv_rnd() * 90.0)',
    '\t\t\tout6 = _pv_fl_dir * m6',
    '\t\thost.hub.pad_stick_right(0, clampf(out6.x + _pv_drift.x, -1.0, 1.0), clampf(out6.y + _pv_drift.y, -1.0, 1.0))',
    '\tif str(args["sticks"]) == "9":   # ?sticks=9: player 1 is a pad that never presses anything (the black box KO check: the computer finishes him)',
    '\t\treturn',
    '\tif str(args["sticks"]) == "10":   # ?sticks=10: player 1 holds RB and flicks the right stick for 3 ticks at phase 100 of every 600 (the quick beam of the stick, the line Hold for a beam), and presses nothing else; the computer plays',
    '\t\tvar p10: int = host.ticks % 600',
    '\t\thost.hub.pad_button(0, "rb", p10 >= 96 and p10 < 112)',
    '\t\tif p10 >= 100 and p10 < 103:',
    '\t\t\thost.hub.pad_stick_right(0, 1.0, 0.0)',
    '\t\telse:',
    '\t\t\thost.hub.pad_stick_right(0, 0.0, 0.0)',
    '\t\treturn',
    '\tvar t: int = host.ticks',
    '\tvar ph: int = t % 240',
    '\tvar dirs: Array = [Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0), Vector2(0.0, -1.0)]',
    '\tvar d: Vector2 = dirs[(t / 240) % 4]',
    '\tif (ph >= 30 and ph < 34) or (ph >= 120 and ph < 170):',
    '\t\thost.hub.pad_stick_right(0, d.x, d.y)',
    '\telse:',
    '\t\thost.hub.pad_stick_right(0, 0.0, 0.0)',
    '\t# the signature (the arena pad\'s east button): a tap at phase 200 to 203 of every 240 ticks, so a beam goes out whenever there is the ki for it, and a clash can follow',
    '\thost.hub.pad_button(0, "east", ph >= 200 and ph < 204)',
    '\tif (str(args["sticks"]) == "2" or str(args["sticks"]) == "7"):',
    '\t\t# the signature is RT + B (the power layer): both players hold power (RT) from phase 10 to 234 and tap B (east) at 200 to 203, on the same ticks, so the two beams meet (found with a native probe: B alone does nothing)',
    '\t\thost.hub.pad_trigger(0, "rt", 1.0 if (ph >= 10 and ph < 235) else 0.0)',
    '\t\thost.hub.pad_trigger(1, "rt", 1.0 if (ph >= 10 and ph < 235) else 0.0)',
    '\t\thost.hub.pad_button(1, "east", ph >= 200 and ph < 204)',
    '\tif str(args["sticks"]) == "3":',
    '\t\t# ?sticks=3: a player who MOVES (the EP, 2026-11-01: Orb will move): the left stick closes in on him sprinting, backs off, climbs on him and drops; RT is held only around the B tap, so the beam goes out (the signature is RT + B) and the right stick still strikes the rest of the time',
    '\t\tvar a3 = host.S.fighters[0]',
    '\t\tvar b3 = host.S.fighters[1]',
    '\t\tvar side: float = 1.0 if SimWrap.sdx(a3.x, b3.x) >= 0.0 else -1.0',
    '\t\tvar p3: int = t % 360',
    '\t\tvar lx: float = 0.0',
    '\t\tvar ly: float = 0.0',
    '\t\tvar sprint: bool = false',
    '\t\tif p3 < 100:',
    '\t\t\tlx = side',
    '\t\t\tsprint = true',
    '\t\telif p3 < 160:',
    '\t\t\tlx = -side * 0.8',
    '\t\telif p3 < 230:',
    '\t\t\tlx = side',
    '\t\t\tly = 0.7',
    '\t\t\tsprint = true',
    '\t\telse:',
    '\t\t\tlx = side * 0.5',
    '\t\t\tly = -0.6',
    '\t\thost.hub.pad_stick(0, lx, ly)',
    '\t\thost.hub.pad_trigger(0, "lt", 1.0 if sprint else 0.0)',
    '\t\thost.hub.pad_trigger(0, "rt", 1.0 if (ph >= 195 and ph < 206) else 0.0)',
    '\tif str(args["sticks"]) == "5" or str(args["sticks"]) == "8":',
    '\t\t# ?sticks=5: the meteor by a person\'s hands (both at tier 4, &peak=1). Found natively: B alone held to the flash (charge_full at about 50 ticks) on a STUNNED foe at close range is the meteor. Close in sprinting, light blows to stagger him, and when he is stunned hold B for 70 ticks',
    '\t\tvar a5 = host.S.fighters[0]',
    '\t\tvar b5 = host.S.fighters[1]',
    '\t\tvar dx5: float = SimWrap.sdx(a5.x, b5.x)',
    '\t\tvar side5: float = 1.0 if dx5 >= 0.0 else -1.0',
    '\t\tvar close5: bool = absf(dx5) <= 150.0',
    '\t\thost.hub.pad_stick(0, side5 if absf(dx5) > 110.0 else 0.0, 0.0)',
    '\t\thost.hub.pad_trigger(0, "lt", 1.0 if absf(dx5) > 300.0 else 0.0)',
    '\t\thost.hub.pad_trigger(0, "rt", 0.0)',
    '\t\thost.hub.pad_stick_right(0, 0.0, 0.0)',
    '\t\tif _pv_bhold > 0:',
    '\t\t\t_pv_bhold -= 1',
    '\t\t\tif _pv_bhold == 0:',
    '\t\t\t\t_pv_bgap = 40   # let go, and wait before pressing again: a B that is never let go launches nothing',
    '\t\telif _pv_bgap > 0:',
    '\t\t\t_pv_bgap -= 1',
    '\t\telif close5:',
    '\t\t\t_pv_bhold = 60',
    '\t\t_pv_padtxt = ("B DOWN, held %d of 60 ticks (let go at the flash)" % (60 - _pv_bhold)) if _pv_bhold > 0 else ("LEFT STICK toward him + LT (sprint)" if absf(dx5) > 300.0 else ("LEFT STICK toward him" if absf(dx5) > 110.0 else "next to him, nothing pressed"))',
    '\t\thost.hub.pad_button(0, "east", _pv_bhold > 0)',
    '\t\thost.hub.pad_button(0, "west", close5 and _pv_bhold <= 0 and (host.ticks % 24) < 4)',
    '\tif str(args["sticks"]) == "4":',
    '\t\t# ?sticks=4: the meteor by a person\'s hands (the sheet: both at full power, &peak=1): close in sprinting, rest, the right stick UP held out to level 3, then B held; cycles of 600 ticks try the four ways (stick sign x keep the stick out or let it go before B)',
    '\t\tvar a4 = host.S.fighters[0]',
    '\t\tvar b4 = host.S.fighters[1]',
    '\t\tvar dx4: float = SimWrap.sdx(a4.x, b4.x)',
    '\t\tvar side4: float = 1.0 if dx4 >= 0.0 else -1.0',
    '\t\tvar cyc: int = (t / 600) % 4',
    '\t\tvar p4: int = t % 600',
    '\t\tvar ysign: float = -1.0 if cyc < 2 else 1.0',
    '\t\tvar keep_out: bool = (cyc % 2) == 0',
    '\t\tvar lx4: float = 0.0',
    '\t\tvar spr4: bool = false',
    '\t\tif p4 < 150 and absf(dx4) > 200.0:',
    '\t\t\tlx4 = side4',
    '\t\t\tspr4 = true',
    '\t\telif p4 >= 330:',
    '\t\t\tlx4 = side4 * 0.6',
    '\t\thost.hub.pad_stick(0, lx4, 0.0)',
    '\t\thost.hub.pad_trigger(0, "lt", 1.0 if spr4 else 0.0)',
    '\t\tvar rs_out: bool = p4 >= 170 and p4 < (290 if keep_out else 230)',
    '\t\thost.hub.pad_stick_right(0, 0.0, ysign if rs_out else 0.0)',
    '\t\thost.hub.pad_button(0, "east", p4 >= (230 if keep_out else 232) and p4 < 300)',
    '\t\thost.hub.pad_trigger(0, "rt", 0.0)',
    '\tif str(args["sticks"]) == "7":',
    '\t\t# ?sticks=7: sticks=2 (both pads hold RT, tap B at phase 200) with both fighters sprinting at each other (left stick + LT) until within 90 units, so the fire is at point blank',
    '\t\tvar a7 = host.S.fighters[0]',
    '\t\tvar b7 = host.S.fighters[1]',
    '\t\tvar dx7: float = SimWrap.sdx(a7.x, b7.x)',
    '\t\tvar far7: bool = absf(dx7) > 90.0',
    '\t\thost.hub.pad_stick(0, (1.0 if dx7 >= 0.0 else -1.0) if far7 else 0.0, 0.0)',
    '\t\thost.hub.pad_stick(1, (-1.0 if dx7 >= 0.0 else 1.0) if far7 else 0.0, 0.0)',
    '\t\thost.hub.pad_trigger(0, "lt", 1.0 if (far7 and ph < 190) else 0.0)',
    '\t\thost.hub.pad_trigger(1, "lt", 1.0 if (far7 and ph < 190) else 0.0)',
    '\tif not _pv_conn:',
    '\t\t_pv_conn = true',
    '\t\thost.drained.connect(_pv_on_drained)',
    '',
    '',
    '## The sim\'s events are cleared at the end of host.advance (S.out.fx.clear()), so they are counted where the host hands them out, on its drained signal.',
    'func _pv_on_drained(events: Array, _lines: Array) -> void:',
    '\tfor e in events:',
    '\t\tif str(e.type) == "beam_outcome":',
    '\t\t\t_pv_beam_kinds[str(e.kind)] = int(_pv_beam_kinds.get(str(e.kind), 0)) + 1',
    '\t\tif str(e.type) == "cue" and str(e.kind) == "stick_hit" and int(e.actor) == 0:',
    '\t\t\t_pv_hit_t = host.ticks',
    '\t\tif str(e.type) == "cue" and str(e.kind) == "arc_send":',
    '\t\t\t_pv_arc_kinds["%s_by_%d" % [str(e.text), int(e.actor)]] = int(_pv_arc_kinds.get("%s_by_%d" % [str(e.text), int(e.actor)], 0)) + 1',
    '\t\tif str(args.get("sticks", "")) == "6" and str(e.type) == "cue" and int(e.actor) == 0 and str(e.kind).begins_with("stick_") and _pv_nd.size() < 400:',
    '\t\t\t_pv_nd.append("%s:%d" % [str(e.kind), host.ticks - _pv_last_flick])',
    '\t\tif str(args.get("sticks", "")) == "6" and str(e.type) == "cue" and int(e.actor) == 0 and (str(e.kind) == "stick_start" or str(e.kind) == "stick_charge" or str(e.kind) == "stick_refused"):',
    '\t\t\tif host.ticks - _pv_last_flick <= 45:',
    '\t\t\t\t_pv_real += 1',
    '\t\t\telse:',
    '\t\t\t\t_pv_phantom += 1',
    '\t\tif str(e.type) == "cue" and str(e.kind).begins_with("stick_"):',
    '\t\t\t_pv_stick_n += 1',
    '\t\t\t_pv_stick_kinds[str(e.kind)] = int(_pv_stick_kinds.get(str(e.kind), 0)) + 1',
    '\t\t\tif str(e.kind) == "stick_refused" and int(e.actor) == 0:   # the reason of each refusal of player 1, counted apart (refused_ki, refused_late ...): the word UI says comes from it',
    '\t\t\t\t_pv_stick_kinds["refused_" + str(e.source)] = int(_pv_stick_kinds.get("refused_" + str(e.source), 0)) + 1',
    '',
    '',
  ].join('\n');
  const struggleOff = [
    '## Scratch (tools/preview): ?struggle=off on a LOCAL page turns the beam struggle off before a match starts (Encounter\'s page word): beamStruggle.enabled false in DirInterrupt\'s loaded data.',
    'func _preview_struggle_off() -> void:',
    '\tif OS.has_feature("web") and bool(JavaScriptBridge.eval("(location.hostname === \'127.0.0.1\' || location.hostname === \'localhost\') && location.search.indexOf(\'struggle=off\') >= 0", true)):',
    '\t\tvar bs = DirInterrupt.data().get("beamStruggle", {})',
    '\t\tbs["enabled"] = false',
    '',
    '',
  ].join('\n');
  const kickLines = [
    '\tif args.has("kick"):',
    '\t\td["kick"] = str(args["kick"]) != "off" and str(args["kick"]) != "0"',
    '\t# the takeoff, for Orb to try (Simulation\'s kick: the share of top speed on the first tick, and the ticks from there to top speed): the same names as the setup keys',
    '\tif args.has("instant"):',
    '\t\td["instant"] = clampf(float(args["instant"]), 0.0, 1.0)',
    '\tif args.has("climbTicks"):',
    '\t\td["climbTicks"] = clampi(int(args["climbTicks"]), 0, 120)',
  ];
  const tierLines = [
    '\t# a training start (Encounter\'s meteor-2: both fighters on the ladder\'s own start at this tier), e.g. ?tier=4',
    '\tif args.has("tier"):',
    '\t\td["startTier"] = clampi(int(args["tier"]), 1, 4)',
    '\t# ?peak=1: start at full power (tier 4; tier 4 takes about six minutes of AI fight to reach, Encounter\'s number), off by default',
    '\tif args.has("peak") and str(args["peak"]) != "0" and str(args["peak"]) != "off":',
    '\t\td["startTier"] = 4',
  ];
  const powerLines = [
    '\t# one energy model, on for the page whatever the data says (Simulation\'s setup key "power"; Game Design\'s slam-and-pace.md section 2, step 1): ?power=0 or ?power=off puts "power": false for this match (the web\'s parse_args drops a word valued 0, so the page reads its own address for it). While it is on, ?flatout=N or the page\'s slider (window.__flatout) tries another base for flat-out flight, 3,500 to 7,000, and ?travel=N or its slider (window.__travel) how far a launch carries along the line (Simulation\'s "travel"), 1.25 to 2.0',
    '\tvar pw_off: bool = args.has("power") and (str(args["power"]) == "0" or str(args["power"]) == "off")',
    '\tif OS.has_feature("web"):',
    '\t\tpw_off = pw_off or bool(JavaScriptBridge.eval("/[?&]power=(0|off)(&|$)/.test(location.search)", true))',
    '\td["power"] = not pw_off',
    '\tif not pw_off:',
    '\t\tvar fo: float = 0.0',
    '\t\tvar tv: float = 0.0',
    '\t\tif OS.has_feature("web"):',
    '\t\t\tfo = float(JavaScriptBridge.eval("window.__flatout || 0", true))',
    '\t\t\ttv = float(JavaScriptBridge.eval("window.__travel || 0", true))',
    '\t\tif fo <= 0.0 and args.has("flatout"):',
    '\t\t\tfo = float(str(args["flatout"]))',
    '\t\tif fo > 0.0:',
    '\t\t\td["flatOut"] = clampf(fo, 3500.0, 7000.0)',
    '\t\tif tv <= 0.0 and args.has("travel"):',
    '\t\t\ttv = float(str(args["travel"]))',
    '\t\tif tv > 0.0:',
    '\t\t\td["travel"] = clampf(tv, 1.25, 2.0)',
  ];
  const circleLines = [
    '## Scratch (tools/preview): ?circle=1 turns the stance circle (LT + Y in reach; Encounter, docs/director/pending/stance-circle) on for the match: data stances.circle.enabled, off as shipped. Local pages only.',
    'func _preview_circle() -> void:',
    '	if not args.has("circle") or str(args["circle"]) == "0" or str(args["circle"]) == "off":',
    '		return',
    "\tif OS.has_feature(\"web\") and not bool(JavaScriptBridge.eval(\"location.hostname === '127.0.0.1' || location.hostname === 'localhost'\", true)):",
    '		return',
    '	var c: Dictionary = DirStance.cfg()',
    '	if c.has("circle") and c["circle"] is Dictionary:',
    '		c["circle"]["enabled"] = true',
    '',
    '',
  ];
  const hitstopLines = [
    '\t# hit-stop by weight (data/fight/hitstop.json: a light 3 ticks, a medium 5, a heavy 8, a launch 12; off as shipped), for a match: ?hitstop=1, ?hitstop=off',
    '\tif args.has("hitstop"):',
    '\t\td["hitstop"] = str(args["hitstop"]) != "off" and str(args["hitstop"]) != "0"',
  ];
  const kickWord = [
    '## Scratch (tools/preview): page words that become setup keys on a LOCAL page: ?kick=1 puts "kick": true (Simulation\'s kick and coin turn on for the match whatever kick.json says; ?kick=off puts false), ?instant= and ?climbTicks= the kick\'s takeoff, ?tier=4 a training start (startTier), ?hitstop=1 hit-stop by weight (?hitstop=off puts false).',
    'func _preview_planet() -> Dictionary:',
    '\tvar d: Dictionary = _preview_planet_base()',
    ...(opts.kickWord ? kickLines : []),
    ...(opts.tierWord ? tierLines : []),
    ...(opts.hitstopWord ? hitstopLines : []),
    ...(opts.powerWord ? powerLines : []),
    '\treturn d',
    '',
    '',
  ].join('\n');
  let out = extra.length ? PLANET_FUNC.replace(line, () => `\t\t${extra.join(', ')},\n${line}`) : PLANET_FUNC;
  if (opts.sticks) {
    const callAt = "\tif frames % 20 != 0 and not args.has(\"reel\"):";
    if (!out.includes(callAt)) throw new Error('tools/preview/switches.mjs: the probe cadence line moved (planetFunc is out of date)');
    const head = 'func _preview_probe() -> void:\n';
    out = out.replace(head, () => sticks + head + '\t_preview_sticks()\n');
  }
  if (opts.struggleOff) {
    const head = "func _preview_planet() -> Dictionary:\n";
    if (!out.includes(head)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(head, () => struggleOff + head + '\t_preview_struggle_off()\n');
  }
  if (opts.swingsOff) {
    const head = "func _preview_planet() -> Dictionary:\n";
    if (!out.includes(head)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(head, () => swingsOff + head + '\t_preview_swings_off()\n');
  }
  if (opts.circleWord) {
    const head = 'func _preview_planet() -> Dictionary:\n';
    if (!out.includes(head)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(head, () => circleLines.join('\n') + head + '\t_preview_circle()\n');
  }
  if (opts.kickWord || opts.tierWord || opts.hitstopWord || opts.powerWord) {
    const head = 'func _preview_planet() -> Dictionary:\n';
    if (!out.includes(head)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(head, () => kickWord + 'func _preview_planet_base() -> Dictionary:\n');
  }
  const keys = Object.entries(setup);
  if (keys.length) {
    const ret = '\t\treturn {"planet": int(args["planet"]), "touch": int(args.get("touch", 3))}';
    if (!out.includes(ret)) throw new Error('tools/preview/switches.mjs: the planet entry moved (planetFunc is out of date)');
    out = out.replace(ret, () => ret.replace('}', () => `${keys.map(([k, v]) => `, "${k}": ${JSON.stringify(v)}`).join('')}}`));
  }
  return out;
}

const EDITS = [
  { name: 'the match setup\'s planet part (no-intro and hook starts)', from: '\t\treturn _planet_next.duplicate()\n', to: '\t\treturn _preview_planet()\n' },
  { name: 'the match setup\'s planet part (the intro start)', from: '\tsu.merge(_planet_next)\n', to: '\tsu.merge(_preview_planet())\n' },
  { name: 'the menu start without intros', from: '\t\tvar su: Dictionary = _planet_next.duplicate()\n', to: '\t\tvar su: Dictionary = _preview_planet()\n' },
  { name: 'the options the URL may set', from: 'const URL_ARGS: Array = [', to: 'const URL_ARGS: Array = ["planet", "touch", "preview", "reel", "sticks", "kick", "instant", "climbTicks", "go", "tier", "peak", "hitstop", "blackbox", "script", "replay", "audiolog", "splitshare", "power", "flatout", "travel", "circle", "nohud", ' },
  { name: 'the menu choices before the HUD loads them', from: '\tui_hud.menu_changed.connect(_on_menu_changed)\n', to: '\t_preview_go()\n\tui_hud.menu_changed.connect(_on_menu_changed)\n' },
  { name: 'the per-frame hook', from: '\tvar n: int = host.advance(delta, vp.x, vp.y)\n', to: '\tif args.has("splitshare"):\n\t\t_pv_split_share()\n\tif args.has("audiolog"):\n\t\t_pv_aud_tick()   # the engine\'s own mixer, read only\n\tif args.has("replay"):\n\t\t_preview_replay()   # a saved black box match played again\n\tif args.has("script"):\n\t\t_preview_script()   # the scripted pad: its events for the coming tick are set before it runs\n\tvar n: int = host.advance(delta, vp.x, vp.y)\n\tif args.has("preview"):\n\t\t_preview_probe()\n' },
];

/** A short fingerprint of the scratch patch and the switch table: a cached build is reused only for the same patch. */
export const EDITS_FINGERPRINT = createHash('sha1').update(JSON.stringify([EDITS, PLANET_FUNC, SWITCHES, BB_FINGERPRINT])).digest('hex').slice(0, 6);

/** main.gd with the planet entry and the probe. Each anchor must be there exactly once, or this throws and says which (Rendering's main.gd changed: update EDITS). Keeps the file's line endings. */
export function patchMain(text, extra = [], setup = {}, opts = {}) {
  const crlf = text.includes('\r\n');
  const nl = (s) => (crlf ? s.replace(/\n/g, '\r\n') : s);
  let out = text;
  for (const e of EDITS) {
    const from = nl(e.from);
    const n = out.split(from).length - 1;
    if (n !== 1) throw new Error(`render/core/main.gd: ${e.name}: expected the line once, found it ${n} times (tools/preview/switches.mjs EDITS is out of date)`);
    out = out.replace(from, () => nl(e.to));
  }
  return out.replace(/\s*$/, '') + nl(planetFunc(extra, setup, opts));
}

/** The kick's takeoff values for Orb to try (Simulation's data/fight/kick.json: the default is 0.8 and 8). Printed as addresses beside the page's own, each one the page's address plus these words. */
export const KICK_SAMPLES = [
  { id: 'kick', add: 'instant=0.9&climbTicks=4', label: 'the kick, quicker: 90% of top speed on the first tick, top speed in 4 more' },
  { id: 'kick', add: 'instant=0.8&climbTicks=12', label: 'the kick, a longer climb: 80% on the first tick, a fifth of a second to top speed' },
  { id: 'kick', add: 'instant=1&climbTicks=0', label: 'the kick, truly instant: top speed on the first tick' },
  { id: 'kick', add: 'kick=off', label: 'the kick OFF, to compare' },
];

/** The varied hit-stop, for Orb to try (data/fight/hitstop.json stays off as shipped): a sample address beside the page's own. */
export const HITSTOP_SAMPLES = [
  { id: 'hitstop', add: 'hitstop=1', label: 'hit-stop by weight ON (a light blow holds 3 ticks, a medium 5, a heavy 8, a launch 12; off as shipped), to try' },
];
/** Start at full power, for Orb (Encounter's meteor-2 startTier): a sample address beside the page's own. */
export const PEAK_SAMPLES = [
  { id: 'tier', add: 'peak=1', label: 'START AT FULL POWER (both fighters at tier 4 from the first tick: the meteor, the beams and the forms without six minutes of fighting first)' },
];

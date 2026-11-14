# Sunday build: pre-play review

Orb's stand-in, 2026-11-08, about 04:20 PST. Read-only. The build reviewed was main 4890bdd9, plus the press-answers and anchor-midpoint parks, plus Tools' page switches. Four lanes: Orb's notes, the pad press by press, launch speeds and the slam, and the LAN 2v2 round. Each lane's findings went to a skeptic, and only what survived is here. It cost about 2.0M tokens (9 agents).

## Ranked

1. FIX BY 07:00
- Power, transform, quick RB flicks and face presses dropped in exchanges give no word and no knock. Fix: build with --on refusedCue (Encounter confirms its held reason is stale) and add prompt.refuse_not_ready "Not ready" to ui/data/terms.json. Owners: EP, Tools, UI.
- The LAN round goes back to the old too-fast launches and flight. Fix: add "power": true to SETUP, SETUP2 and SETUP2X in net/lan.gd, then gate with lan_check, rollback and desync. Owner: Netcode.
- A held flick knocks and says "Didn't start", then fires anyway. Fix: raise strike.refuseTicks from 30 to 95 in data/input/timing.json. Owner: Controls.
- A flick that starts its own exchange plays again or says "Locked in". Fix: _followed keeps nothing when ex.A == f, plus a flick_keep_check row. Owner: Encounter.
- Flight-strike refusals knock with no word. Fix: swap text and source in DirZip._refused and update flight_strike_check. Owner: Encounter.
- LAN words: add lines on the look-alike screens and on MATCH OVER to lan_words.txt, and fix "the old PC the second" for together. Owner: Netcode.

2. TELL ORB ON THE PLAY PAGE
- Click or press a key once before using the pad, or the sound may stay off.
- Holding RT and moving the right stick does nothing. Let go of RT first.
- The slam is for a rival in the air. Early in a match it drives them into a skid, not a crater. A rival standing on the ground skids away.
- Flicking at a rival far away gives a taunt, then "Too late".
- The speed slider takes effect from the next match. Launches at top power still outrun the camera, so try 1.5.
- LAN: both screens show the same hero and the same rival, and each shows only its own fight. Hits from the pair you can't see read "Hit from the other fight".
- LAN: at MATCH OVER, which may show on one PC only, close both windows.
- LAN: say "pausing" out loud and touch nothing on the frozen PC. Once you're out, your pad rumbles with your partner's fight. The computers play Medium whatever the menu says.
- If the first two fixes miss: power and transform presses stay silent, and the LAN runs at yesterday's speed.

3. AFTER SUNDAY
- Air slam that craters, and the pound in place on the ground. Encounter, World.
- A quiet answer for a far flick. Encounter.
- A worded knock for RT plus the right stick. Controls.
- The start card's sound line. UI.
- The readable launch budget (power-on park). Simulation, Encounter.
- A worded reason for zip_refused. Encounter, UI.
- LAN end card, presses kept through the other PC's pause, rumble while watching. Netcode.
- A second look for the second pair. Art.

Couldn't tell
- Whether the build command passes --on refusedCue.
- Which tree the LAN folder comes from (a plain main copy loses the page rows), whether anchor-midpoint is in it, and whether the old PC still stutters.
- Whether a real pad press starts the sound, or rumbles, in Opera GX.
- Whether air holds reach the top stage, how long exchanges run, how far the slam skids with the model on, whether Orb reaches tier 4, and whether LT presses land inside the 4-tick window.
- Whether the page already explains RT plus the stick, the 40-energy fire back and the air-only slam.
- LAN: the pad's hub slot after a view change, rollback repeating sounds or rumble, the computer taking a seat after an 8 s freeze, and the push-mode setting.


## Every finding that survived

### refused-cue-held-silences-new-answers (notes, dead-press, fixable tonight)

- **Orb does:** Taps RT to power up, or presses transform when no form is ready or while he's held. In a close brawl he gives RB + right stick a quick flick (released before 12 ticks).
- **He expects:** Every press either happens or says why. The Sunday batch is billed as refusal reasons with words, and the press-answers park landing before the build exists to answer the power press and transform (Tools' ledger of his 1229 play: 7 of 8 power presses and 3 of 3 transforms got nothing).
- **What happens:** Nothing: no word, no knock. The page holds press.refusedCue off. With it off, DirRefuse.presses returns at once, so press-answers lands and does nothing. The quick RB flick's 'Too close' is gated the same way. The RB start has already sent stick_start, so the hub's 'Didn't start' never fires either. The director's own press_refused (a full queue, locked) is off too. Even with the cue on, the new code not_ready has no word, and UI drops a code with no word.
- **Owner:** EP + Tools (row), UI (not_ready word), Encounter (confirm the held reason)
- **Fix:** Build with --on refusedCue. Its held reason, 'knocks on landed hits', looks like the stun_limit knock on a landed flick, which the refusal-reasons park removed (docs/director/pending/refusal-reasons/README.md:28, :104); Encounter should confirm. Add prompt.refuse_not_ready 'Not ready' to ui/data/terms.json. Otherwise tell Orb that power, transform and quick RB flicks still say nothing.
- **Skeptic's corrected reading:** With press.refusedCue held off (switches.mjs:144), press-answers lands and does nothing (presses() returns at once). A power or transform press while he's held, a transform with no form ready, and a quick RB flick in a brawl (stick.gd:836-838) all stay silent: no word, no knock. The flick is silent because its stick_start has already cleared the hub's 'Didn't start' (main.gd:1002-1003). A power press that starts a charge may still show the charge on screen; the ledger counts only cues. Even with the cue on, not_ready has no word in terms.json and no entry in SimHaptics.REFUSALS. The held reason, 'knocks on landed hits', looks stale: refusal-reasons landed, and stun_limit is no longer sent.
- **Evidence:** tools/preview/switches.mjs:144 (refusedCue held: 'knocks on landed hits; Encounter'); docs/tools/sunday-build.md:8 (held today: refusedCue, the four city rows, aimCuts); data/director/interrupts.json:610 refusedCue false; docs/director/pending/press-answers/README.md:7 ('It rides press.refusedCue'); press-answers.diff refuse.gd hunk (presses(): 'if not refusedCue: return'); sim/director/stick.gd:837-838 (RB quick flick's 'close' gated on refusedCue), :468 (stick_start at the RB start); render/core/main.gd:1002-1003 (stick_start clears the hub's wait); sim/director/exchange.gd:114-116 and refuse.gd:30 (press_refused gated); ui/data/terms.json:94 (no refuse_not_ready); ui/core/ui_event_hub.gd:891-894 (a code with no term is dropped); press-answers README:49 (UI word still owed).

### lan-round-energy-model-off (notes, feel, fixable tonight)

- **Orb does:** Plays the LAN 2v2 round with Orb 2 right after the solo play.
- **He expects:** The launch and flight speeds he just tried on the page. Game Design: 'Most of too fast is a switch... Step 1: the energy model on in the next build.'
- **What happens:** Only the web page turns the energy model on, through its setup word. The data stays off. The LAN game starts from NetLan's own setups, which have no 'power' key, so S.powerOn is false. Every launch keeps the old x6 sideways boost and far flight keeps its x10: the same ~10,800/s median Orb called too fast. The travel slider doesn't exist there. This holds whichever tree the LAN folder is cut from, because power is a page word, not a page row.
- **Owner:** Netcode (EP to route)
- **Fix:** In the kit's copy, add "power": true (and "travel": 1.5 if the page's first value is lowered too) to SETUP, SETUP2 and SETUP2X in net/lan.gd. Both PCs read the same setup, so they stay in step. Alternatively, flip power.json enabled in the LAN tree. Run lan_check before handing over.
- **Evidence:** data/fight/power.json:4 'enabled': false; tools/preview/switches.mjs:884-889 (power set in _preview_planet, the page's menu start only); commit 4890bdd9 message ('the page turns the model on; data stays off'); net/lan.gd:22-25 (SETUP, SETUP2X, SETUP2: no power key), :107-108 setupFor; net/tools/lan_kit.mjs:54 (start_match(NetLan.SEED, ai, NetLan.setupFor(args))); sim/core/power.gd:100 (S.powerOn = su.get('power', on_)), :108 (trav = TRAV_LAUNCH when off); sim/core/constants.gd:16-17 (TRAV_FREE 10, TRAV_LAUNCH 6); docs/design/slam-and-pace.md section 2 ('median of about 10,800 a second').

### kept-flick-knocked-didnt-start (notes, confusing, fixable tonight)

- **Orb does:** Flicks the right stick while stunned, reeling or caught in the computer's planned exchange. He presses about every 45 ticks, and the director holds him often.
- **He expects:** Game Design ruling 1: the flick is held quietly, with no knock, and becomes his first blow out.
- **What happens:** flickKeep (row on) holds the flick for up to 90 ticks with no cue. The hub starts a 30-tick wait on every stick press. With no stick_start, stick_refused or press_refused inside 30 ticks, it knocks the pad and posts no_answer, which the HUD shows as 'Didn't start' the first 3 times a match. So any flick held 31 to 90 ticks gets a knock and 'Didn't start', and then the blow fires anyway. Nothing in sim/input knows about flickKeep.
- **Owner:** Controls + Encounter (Rendering grant if main.gd changes)
- **Fix:** Quickest, data only: raise strike.refuseTicks above pendFollow.maxTicks (95) while flickKeep is on. The director now tells real drops itself. Better: Encounter emits a quiet cue when it keeps a flick, and main.gd calls note_press_answered on it.
- **Evidence:** docs/design/gauntlet-plan.md:82 ('acknowledged quietly, with no knock'); sim/director/stick.gd:478 and :675 (kept quietly, no cue); data/director/stick.json:85 (pendFollow.maxTicks 90); sim/input/hub.gd:879-886 (wait starts on rsStart), :449-457 (no_answer knock and refusal after refuseTicks); data/input/timing.json:67 (refuseTicks 30); render/core/main.gd:1002-1003 (cleared only by stick_start, stick_refused, press_refused); ui/data/terms.json:94 refuse_no_answer 'Didn't start'; grep: no flickKeep or keepOn in sim/input.

### ground-slam-carries-not-pounds (notes, confusing)

- **Orb does:** Holds the right stick down to the top stage on a rival standing on the ground, then lets go.
- **He expects:** The 'mega slam' into the ground. Game Design ruled: 'Pounded in where he stands: the crater opens under him and he's down in it, with no journey.'
- **What happens:** fullSend is on, but a rival within 1 body height (75 units) of the ground gets the 'bury' family, which is the ordinary down send. DRIVE DOWN carries him down and forward about 2,000 units (about 27 body heights) in Encounter's check. CRATER SLAM only comes when the rival is directly below. So on the ground the rival skids away instead of being driven in. Only a rival in the air gets the real slam.
- **Owner:** Encounter (with Simulation and World for the pound)
- **Fix:** Tonight, tell Orb in plain words that the slam is for a rival in the air, and that on the ground the hold sends him skidding. The in-place pound (a planner candidate, a crater under him, World's embed) is Encounter's next step.
- **Skeptic's corrected reading:** Holding the right stick down to the top stage on a rival standing on the ground (within 75 units of it) gives the plain down send ('bury' is only the cue's label). It goes through the same DirBrawl._send as the air slam. On the ground he isn't pounded in: in Encounter's check, with the energy model off, he slid 1,790 units sideways in 20 ticks and rose 11. With the page's model on, the slide is shorter but unmeasured. Game Design's 'pounded in where he stands' (slam-and-pace.md:27) isn't built (stick-slam README:58). Only a rival more than 1 body height up gets driven into the ground.
- **Evidence:** docs/design/slam-and-pace.md:27; data/director/stick.json:74-75 (downOnGround 'bury', airBh 1.0); sim/director/interrupt.gd:86 (BH 75); sim/director/stick.gd:651-654 (bury goes through the same DirBrawl._send); docs/director/pending/stick-slam/README.md:22 ('it isn't the in-place pound yet'), :58 ('about 2,000 units'; CRATER SLAM only when directly below).

### pad-only-start-still-silent (notes, confusing, fixable tonight)

- **Orb does:** Opens the page from the shortcut and uses only the pad. go=1 makes him the controller, and the notice card can be passed with the D-pad and A.
- **He expects:** Sound from the start ('sound effects weren't audible until i paused the game the first time').
- **What happens:** Audio now asks both contexts to run on a pad press. But its own docs say a browser lets sound start only after a key, click or touch, and whether a real pad press counts in Opera GX is unproven. The fallback, UI's start-card line 'Sound starts when you press a key or click', isn't built: nothing reads web_blocked(). If the pad doesn't count, he's silent again until his first key or click.
- **Owner:** UI (start-card line); EP (tell Orb)
- **Fix:** Tonight, tell Orb to click the page or press a key once before picking up the pad. Next, UI's one line on the start card while audio.web_blocked() is true. Read the 'pad seen/asked/woke' counters in his next file.
- **Skeptic's corrected reading:** Audio now asks both contexts to run on a pad press, but its own files say a pad press is not a browser activation (audio-resume README:7). A scripted pad press with no earlier key or click left both contexts suspended (pad-start.md:20). A real pad is unproven (:26), and UI's 'Sound starts when you press a key or click' line isn't built (no caller of web_blocked()). If Orb passes the notice card with the pad, as in the 1229 play, the game is likely silent until his first key or click.
- **Evidence:** docs/audio/pad-start.md:26 (whether a real pad counts is unproven), :39 (UI's line 'I have not built it'); docs/audio/pending/audio-resume/README.md:7 ('a pad is never one'); audio/audio_voices.gd:278-281 (web_blocked, 'nothing else reads it'; no caller in ui/); tools/preview/make-shortcuts.mjs:15 (go=1 page); docs/tools/preview.md:135 (notice card passable with D-pad and A).

### launch-pace-starts-at-top (notes, feel, fixable tonight)

- **Orb does:** Plays a few matches on the plain shortcut (or the full-power one) and watches launches, now including every full stick hold that sends.
- **He expects:** Launches slow enough to follow ('high speed launches are cool but a little too fast'). Game Design's budget caps ordinary sends at 9,000/s on screen, with a held moment and slow-in/out, because the camera can't follow past 10,000.
- **What happens:** The model is on with travel x2: the slider starts at its top and the shortcut passes no travel word. The pace cap, held moment, eases and camera hold are only in the unlanded power-on park. A full send's sideways pace is 900 x sqrt(4.94 x 12.25^level) x 2: about 4,000/s at tier 1, about 7,800 at tier 3, about 10,000 at tier 3 with full power, about 10,900 at tier 4 (the full-power shortcut, from the first second) and 14,000 at the top. That's past the camera's 10,000. fullSend now makes full-share sends routine from every top-stage stick hold.
- **Owner:** Tools (page), Game Design (first value)
- **Fix:** Start the slider at Game Design's first lever, 1.5: &travel=1.5 in the shortcut, or tv0 in blackbox.mjs. Orb's hands can still move it. Tell Orb the slider only applies at the next match.
- **Skeptic's corrected reading:** The energy model is on with travel x2, Game Design's first value (slam-and-pace.md:62). But that ruling's 9,000/s cap, held moment, slow-in, slow-out and camera hold aren't in this build: the readable block is only in the unlanded power-on park. Full-share sends (a full B, or a top-stage stick hold that lands) reach about 10,000/s at tier 3 with full power, 10,900 at tier 4 and 14,000 at the top. On the full-power shortcut that is from the first second, past the camera's 10,000 flat-send line. At tiers 1 and 2 they stay at 4,000 to 5,600. The slider starts at 2.0 (blackbox.mjs:465), the top of its range.
- **Evidence:** data/fight/power.json:6-7, :110-112 (launchTravel 2.0, travel max 2.0); tools/preview/blackbox.mjs:465 (slider tv0 = 2); tools/preview/make-shortcuts.mjs:15 (no travel word); docs/director/pending/power-on/grant-simulation-readable.patch:9 (readable block, not landed); docs/director/pending/press-answers/README.md:10 (power-on waits until after Sunday); docs/design/slam-and-pace.md:62; sim/core/power.gd:117-133; render/camera/camera_params.gd:415 (FLAT_SPEED 10000); sim/director/stick.gd:654 (full send at share 1.0).

### 2v2-screens-look-alike (notes, confusing, fixable tonight)

- **Orb does:** In the 2v2 together round, Orb and Orb 2 each watch their own PC.
- **He expects:** Orb 2 sees his own fighter. Last time: 'the old PC player's camera would lock onto my player I think'.
- **What happens:** Netcode's reading is that neither PC switched views: both fights are the same two characters (one Protagonist, one Rival each), so the two screens look alike. This build changes nothing about the look (the second palette is unbuilt). The kit's words never say both screens will show the same pair, so the same 'camera locked onto me' impression is likely.
- **Owner:** Netcode (words), Art later (second palette)
- **Fix:** Add one plain line to lan_words.txt's 2v2 section: both fights use the same two fighters, so both screens look alike, and each PC always shows its own player's fight.
- **Skeptic's corrected reading:** Each PC now shows its own player's fight, through pauses too: Netcode's view fix is in 4890bdd9 (two-v-two-lan.md:34), which likely fixes the slip Orb saw. But both fights are one Protagonist against one Rival (co-op-2v2.md:84), so the two screens look alike. The kit's words never say so (lan_words.txt:23, :26), and Orb 2's screen will still look like it is following Orb's fighter.
- **Evidence:** docs/net/two-v-two-lan.md:34 ('the two pairs are the same two characters, so their screens look alike'); docs/ep/proposals/co-op-2v2.md:84 (A4 second palette, unbuilt); net/tools/lan_words.txt:23 ('the main PC plays the first, the old PC the second'), :26 ('Your partner's fight isn't shown').

### rt-stick-still-inert (notes, dead-press, fixable tonight)

- **Orb does:** Holds RT to power up and flicks the right stick to hit, or flicks while letting go of RT to meet a rush.
- **He expects:** A blow, or a knock and a word. This was yesterday's review item rt-plus-stick-inert-silent (knock it, and tell Orb).
- **What happens:** Unchanged. RT's layer is still inert, so the reader goes IGNORED: 'the stick does nothing, and holds nothing, until it rests'. The hub's knock only starts on a stick request. So there's no blow, no knock and no word, and the stick stays dead until it is back at rest.
- **Owner:** Controls
- **Fix:** Tonight, tell Orb that RT + right stick does nothing yet. Then Controls has the layout flag a crossing on an inert layer so the hub knocks it with a worded reason.
- **Skeptic's corrected reading:** A right-stick flick or hold that crosses the line while RT is still held (mask 4 is in inertMasks) goes IGNORED: no blow, no knock, no word. The stick stays dead until it is back at rest, even if RT is let go first. A flick made after RT is fully released works. This is yesterday's rt-plus-stick-inert-silent, still unfixed.
- **Evidence:** data/input/timing.json:85 (inertMasks [3, 4]); sim/input/layout.gd:1245; sim/input/strike_read.gd:28, :174; sim/input/hub.gd:879-886 (wait starts only on rsStart); docs/ep/proposals/morning-build-review.md:105-113.

### refusedcue-held-press-answers-inert (pad, dead-press, fixable tonight)

- **Orb does:** Presses RT (power) while locked in an exchange or flying from a hit. Squeezes both triggers (LT + RT) to transform with no form ready. Taps a quick RB + right-stick flick in a brawl. Presses X, Y or B while locked in an exchange.
- **He expects:** Tonight's batch is billed as 'refusal reasons with words', and the press-answers park was written to answer the power press and the transform. Game Design's ruling 3 says 'A press nobody is told about is a fault.'
- **What happens:** None of these presses gets a word or a knock. The page holds press.refusedCue off, and every one of these answers rides that switch. That covers the whole press-answers park (power_burst, power_start, not_ready), the face presses refused for queue_full, locked or queue_expired, the block lockout, a stick charge stopped by a blow ('Hit'), and the morning review's RB-flick fix ('Too close'). The transform with no form simply passes (exchange.gd:922). Only stick presses get words, because stick_refused isn't gated. Even with the switch on, the code not_ready has no word, so the UI drops it silently.
- **Owner:** EP (page flag), Tools (held reason), UI (not_ready word)
- **Fix:** Build with `--on refusedCue`. Its held reason was answered by tonight's refusal-reasons and refusal-knocks parks. UI adds prompt.refuse_not_ready ('Not ready') to ui/data/terms.json. If refusedCue stays held, tell Orb: RT while held, the trigger pair with no form, a quick RB flick in a brawl, and face presses in exchanges still say nothing.
- **Skeptic's corrected reading:** With press.refusedCue held off (switches.mjs:144, interrupts.json:610), none of these get a word or a knock: the whole press-answers park (power_start, power_burst, refused power presses, not_ready), the face-press drops for queue_full, locked and queue_expired, block_lockout, the stick's 'Hit', and the morning review's RB-flick 'Too close'. A face press made in a stun still shows 'Stunned'. Even with the switch on, not_ready would knock with no word, because terms.json has no prompt.refuse_not_ready.
- **Evidence:** tools/preview/switches.mjs:144 (refusedCue held: 'knocks on landed hits; Encounter') and :347-350 (held rows are OFF unless --on); tools/preview/preview-selftest.mjs:69 (HELD = refusedCue,wallPush,wallPushAi,slamTurn,cityHold,aimCuts); docs/tools/sunday-build.md:8; docs/tools/runs/ba87218e/g4-build.txt:9 ('HELD OFF: refusedCue'); data/director/interrupts.json:610 (refusedCue false); docs/director/pending/press-answers/press-answers.diff:29-30 (presses() returns when refusedCue is off; its check forces it on at :80); sim/director/exchange.gd:114-117, :94, :250; sim/director/refuse.gd:30; sim/director/interrupt.gd:281; sim/director/stick.gd:327 ('Hit' gated) and :836-838 (RB flick 'close' gated; stick_start at :468 has already cleared the hub's knock); ui/data/terms.json has no prompt.refuse_not_ready and ui/core/ui_event_hub.gd:891-894 silences an unknown code; docs/tools/orb-play-1229-counted.md:13-15 (powerPress 7 of 8 and transform 3 of 3 silent, 44 silent in locked exchanges). The held reason looks stale: docs/director/pending/refusal-reasons/README.md:28 (stun_limit on a landed flick is no longer sent) and docs/controls/pending/refusal-knocks/README.md:12-13 (audit run with refusedCue on: a landed flick never knocks).

### flickkeep-hub-didnt-start (pad, confusing, fixable tonight)

- **Orb does:** Flicks the right stick while stunned, while caught in the rival's planned exchange, or early in a knock-back flight (Orb presses about every 45 ticks).
- **He expects:** Ruling 1: the flick is held quietly with no knock, and the blow itself is the answer. Only a final refusal knocks.
- **What happens:** The director keeps the flick for up to 90 live ticks and sends no cue while it waits. The input hub's own timer gives up at 30 ticks: the pad knocks and the edge says 'Didn't start'. Then the flick fires anyway, as his first blow when he's free. A flick made early in a flight gets two answers: 'Didn't start' at 31 ticks, then 'Recovering' or 'In flight' later.
- **Owner:** Controls (hub), Encounter, Rendering (main.gd host line)
- **Fix:** Tonight, as data: raise timing.json strike.refuseTicks from 30 to 95, above pendFollow.maxTicks 90 (only the hub reads it, hub.gd:450). The proper fix: Encounter sends a quiet stick_kept cue when it keeps a flick, and main.gd:1002 clears the wait on it.
- **Evidence:** data/input/timing.json:67 (strike.refuseTicks 30); sim/input/hub.gd:883-886 (the wait starts on rsStart) and :449-457 (past refuseTicks: knock plus refusal no_answer); render/core/main.gd:1002-1003 (only stick_start, stick_refused and press_refused end the wait) and :809 (the hub's refusals are drawn); ui/data/terms.json prompt.refuse_no_answer 'Didn't start'; sim/director/stick.gd:477-482 (kept quietly, no cue) and :547, :606-607 (kept up to 90 live ticks with flickKeep); tools/preview/switches.mjs:173 (flickKeep ON); docs/design/gauntlet-plan.md:82.

### fold-own-exchange-repeats (pad, confusing, fixable tonight)

- **Orb does:** Flicks the right stick up close at a rival who is evading, escaping, charging or rushing, or after an approach that engages into a planned exchange. He's the attacker of the exchange his flick started.
- **He expects:** Ruling 2: when his own request starts the exchange, the flick is its first strike. It counts as honoured: no refusal, no knock, and nothing left over.
- **What happens:** _followed treats his own exchange like the rival's. It takes the flick out of the request and keeps it, so when the exchange ends the same flick asks for another attack. That one can start another planned exchange, which keeps the flick again (sweep resets its clock), so one flick can replay as a run of attacks. Each replay with a heavy costs 4 energy. If the exchange runs past 90 ticks, the flick is refused instead with 'Locked in' and a knock, on a press that did start the fight. No stick_start is sent for a planned exchange, so the hub's 'Didn't start' also fires at 31 ticks.
- **Owner:** Encounter
- **Fix:** In DirStick._followed, when ex.A == f, clear ST_PEND and keep nothing: the exchange is the flick's answer (ruling 2, row 1). Keep the hold or buffer only when ex.D == f. Add a flick_keep_check row for his own exchange.
- **Skeptic's corrected reading:** When his own stick request starts a planned exchange, _followed (stick.gd:666-675) still keeps the flick, and it fires again as a fresh request when the exchange ends (stick.gd:536-544). That can repeat while each request starts another planned exchange. If the exchange runs past 90 ticks, the flick is refused 'Locked in' instead. Either way the hub also says 'Didn't start' at 31 ticks, because a planned exchange sends no stick_start. (The energy cost of each replay is not verified.)
- **Evidence:** sim/director/stick.gd:664-677 (_followed: `ex.A == f or ex.D == f` alike; with keepOn the flick is swept or buffered, not dropped); :689-691 (sweep resets ST_BAT); :536-546 (when free, a swept flick that was let go goes again through _go); :547-550 (90 ticks inside: refused with cantWhy, 'locked'); :561-567 (_cant is true for any planned exchange); sim/director/brawl.gd:267-272 (a close request against stance >1, a rush, a non-free rival, an opening or a far charge is a planned exchange); sim/director/tools/flick_keep_check.gd:146 (tests only the rival's exchange: newEx(D, A, ...)); docs/design/gauntlet-plan.md:89.

### flight-strike-refusal-no-word (pad, dead-press, fixable tonight)

- **Orb does:** Holds LT and presses X, Y or B (a flight strike, ON tonight) with too little energy, especially the 1.5x links of a chain (10, 15 and 20 energy plus up to 10 for distance), or while stunned. Also presses LT + X right after knocking the rival down or burying him with the new slam.
- **He expects:** Game Design: if he can't pay, the pad knocks once, and the code comment promises 'No energy' at the edge. Ruling 3: every refusal has a word.
- **What happens:** No-energy, stunned and busy refusals put the reason in the cue's text and the button in its source. The UI reads the reason from source, so it looks up 'refuse_x' (or y, b), finds no word and says nothing: a knock with no word. When the rival is down, dropped, just out of his crater, zipping or hidden, the press becomes press_ack zip_refused. Nothing reads that cue (no word, no mark, no knock), and the press is spent, so not even the plain blow happens.
- **Owner:** Encounter (UI for any new code)
- **Fix:** In DirZip._refused, swap the fields: `_cue(S, A, "press_refused", DirBrawl._cell(kind), why)`, and update flight_strike_check.gd:337. Replace press_ack zip_refused at zip.gd:265 and :423 with press_refused carrying a worded code (down, launched, busy).
- **Skeptic's corrected reading:** A flight strike (LT pressed and held, then X, Y or B within 4 ticks, or a chain link) that can't be paid for, or that is made while stunned or busy, knocks the pad with no word. The reason sits in the cue's text and UI reads source ('x', 'y' or 'b'), which has no term (zip.gd:384-387). Prices are X 10, Y 15, B 20 plus up to 10 by distance, and each chain link costs 1.5x the one before. When the rival is down, dropped, buried-safe, zipping or hidden, the press becomes press_ack zip_refused, which nothing reads, and the press is spent (zip.gd:265, :423).
- **Evidence:** sim/director/zip.gd:384-387 (`_cue(S, A, "press_refused", why, DirBrawl._cell(kind))`) with callers at :262, :272, :306, :428; sim/director/tools/flight_strike_check.gd:337 (asserts text 'ki', src 'x'); ui/core/ui_event_hub.gd:481-482 (press_refused word read from source) and :891-894 (no term means silent); ui/data/terms.json has no refuse_x, refuse_y or refuse_b; zip.gd:264-266 and :421-424 (press_ack zip_refused, return true) with no handler in ui/core/ui_event_hub.gd:786-821 or sim/input/haptics.gd; data/director/interrupts.json zip.flightStrikes blows ki 10/15/20, chain.kiMul 1.5; docs/design/playable-build.md:53; tools/preview/switches.mjs:166 (flightStrikes ON).

### far-flick-taunt-too-late (pad, confusing, fixable tonight)

- **Orb does:** Flicks the right stick at a rival more than 12.5 body heights away (the far band). This is common after launches carry fighters apart, outside the 150 ticks when the far follow applies.
- **He expects:** Pillar 3 ('never out of range') and tonight's stick lunge: a flick closes the gap and lands, or says why not.
- **What happens:** The stick lunge only covers the middle band. From afar, the stick's heavy request becomes a far press, which opens a taunt (his fighter gestures). That leaves the stick's request waiting with no approach and nothing in the queue, so 9 ticks later it lapses: the pad knocks and the edge says 'Too late', right after the game answered with a taunt.
- **Owner:** Encounter
- **Fix:** In DirStick._go, when the request was taken by a far press (no queue entry and no approach, a taunt begun this tick), clear ST_PEND quietly: the taunt is its answer. Or send the far-band flick into the far lunge, as lungeLight does at mid range.
- **Evidence:** sim/director/stick.gd:517-520 (lungeLight only when the band is MID) and :504 (else 'heavy'); sim/director/exchange.gd:88-89 (the far press returns before the queue push at :92); sim/director/bands.gd:197-212 and :244-251 (farPress sets TAUNT_AGE, not APPR_LEFT) and :81-82 (pending means APPR_LEFT); sim/director/stick.gd:664-684 (_followed: no exchange and an empty queue give false) and :771-776 (past pendTicks: stick_refused late); data/director/stick.json:66 (pendTicks 9); data/director/interrupts.json:79 (midBh 12.5) and :108-110 (taunt enabled); terms prompt.refuse_late 'Too late'. No stick check covers a far-band press (sim/director/tools/stick*_check.gd).

### rt-stick-still-silent (pad, dead-press)

- **Orb does:** Holds RT to power up and flicks or holds the right stick, to hit a rival who closes in or to try the signature on the stick.
- **He expects:** Something happens, or a knock and a word say why. The morning review flagged this as a silent dead press.
- **What happens:** Nothing has changed since the morning review. While RT is held the stick is inert: no request, no knock, no word, and the stick stays dead until it returns to rest, even if RT is let go first.
- **Owner:** Controls (knock and word); EP (tell Orb)
- **Fix:** Tonight, tell Orb in plain words that RT plus the right stick does nothing in this build. Later, Controls makes an IGNORED crossing push a worded refusal through the hub's refusals list, with its knock.
- **Evidence:** data/input/timing.json:85 (strike.inertMasks [3, 4]; 4 is RT's charging layer, sim/input/layout.gd:1041); sim/input/layout.gd:1245 (inert passed on those masks); sim/input/strike_read.gd:172-174 (crossing on an inert layer: IGNORED, no request); sim/input/hub.gd:883-886 (the no-answer wait starts only on rsStart); docs/ep/proposals/morning-build-review.md:105-113 (rt-plus-stick-inert-silent).

### slam-air-is-a-skid (speed-slam, confusing, fixable tonight)

- **Orb does:** He gets the 'Hold to slam' hint, then holds the right stick down to the top stage on a foe in the air during a brawl. At base that means holding 0.47 s or more.
- **He expects:** The mega slam: the foe driven straight down into the ground below with a crater. GD rules a crater at every tier, with a short trench allowed only at base, and the hint promises a slam.
- **What happens:** At tier 1-2, which is every match's start, the full send goes through the planner's down family and comes out as DRIVE DOWN. That sends him down and forward at 25 degrees (2 bh up or lower) to 50 degrees (12 bh or higher). With the energy model on, the sideways part is also multiplied by 1.5-1.7. He lands shallower than 70 degrees, so he bounces or skids away along the ground in a furrow, with no crater. Only CRATER SLAM digs a crater. It's offered when the attacker is 3 bh directly above the foe (rare in a brawl), or at tier 3+ once per 30 s. So at tier 3-4 the first slam craters, and the next one inside 30 s skids again. The slam has no camera shot of its own yet.
- **Owner:** encounter
- **Fix:** Make the stick's down full send on an airborne foe offer CRATER SLAM no matter what the gates say: pass a flag in _fullSend's extra that chooseLaunch honours by skipping craterOffered. Then the tilt-5 cone picks it. Add a crater assertion to full_send_check. Otherwise, tell Orb on the play page that below tier 3 the slam drives them down and forward into a skid.
- **Skeptic's corrected reading:** At tier 1-2, which is every match's start, the down full send on a foe in the air is always DRIVE DOWN. CRATER SLAM is only offered with the attacker 3 bh directly above the foe (launch.gd:163-170), and SENDS 'down' (launch.gd:1117) leaves DRIVE DOWN alone, at 25 degrees (2 bh or lower) to 50 degrees (12 bh or higher). From ordinary brawl heights (the check's 8 bh) it lands at about sin2 0.66, under the slam band of 0.883 (contact.gd:713), so he bounces once and skids away with no crater. Only a foe about 20 bh or more up at base speed falls steep enough to crater. The sideways x1.5-1.7 lengthens the skid but doesn't change the landing class (contact.gd:685 divides it out). At tier 3-4 the first slam in 30 s is CRATER SLAM and digs a crater; the next one inside 30 s is DRIVE DOWN again, and at tier-4 speeds it skids. The slam has no camera shot of its own yet.
- **Evidence:** sim/director/stick.gd:636-654 (_fullSend: aim 3 into DirBrawl._send with sends 'down'; the family name 'slamDown' goes only to the cue); sim/director/brawl.gd:2766-2774 (aim 3 = tilt 5, straight down); sim/director/launch.gd:189-194 (DRIVE DOWN always offered, CRATER SLAM only if craterOffered); launch.gd:163-168 and data/director/launch.json:16-27 (below: sideBh 1, dropBh 3; setPiece minTier 3, everySec 30); launch.gd:248-262 (the stick's 45-degree cone holds nothing under 10 bh when CRATER SLAM is absent, so the full list stands and DRIVE DOWN wins); launch.gd:18-20 ('DRIVE DOWN ... down and forward at 25 to 50 degrees ... ploughs in and slides'); data/director/launch.json:4-5 (lowDeg 25); sim/world/contact.gd:713 with data/biomes/contact.json:10 (a slam/crater needs sin2 >= 0.883, about 70 degrees); sim/world/slide.gd:47-50 (sideways x travel 2); docs/director/pending/stick-slam/README.md:36 ('foe 8 bh up: the slam, DRIVE DOWN'); sim/director/tools/full_send_check.gd:36 (checks only that he fell 50 units: no crater, no direction check); docs/design/slam-and-pace.md:26 and :35; base top at stage 2 = 28 ticks (data/director/stick.json strikeStages.stageTicks; sim/director/beam_move.gd:71-72, 2 + round(4 x level))

### slam-ground-travels (speed-slam, confusing)

- **Orb does:** He holds the right stick down to the top stage on a foe standing on the ground.
- **He expects:** GD's ruling: 'pounded in where he stands: the crater opens under him and he's down in it, with no journey'.
- **What happens:** Only the cue changes to 'bury'. The send itself is the same DRIVE DOWN, at 25 degrees from ground level, so on first contact he skids away along the ground, with no crater and no embed. Encounter's own check measured it travelling about 2,000 units with the model off. Encounter lists the in-place pound as not built yet.
- **Owner:** encounter
- **Fix:** Not tonight: it needs its own in-place candidate plus World's embed (stick-slam README:58). Tonight, tell Orb on the play page that down on a grounded foe knocks them into a skid, not a pound in place.
- **Skeptic's corrected reading:** At tier 1-2, which is every match's start, a down hold to the top on a grounded foe is the same DRIVE DOWN send at 25 degrees. Only the cue changes to 'bury' (stick.gd:651-654). It lands as a skid (sin2 about 0.18, under 0.413), so he slides away along the ground with no crater and no embed. At tier 3-4 the first such hold in 30 s becomes CRATER SLAM and craters nearly in place, then later holds skid again until the 30 s pass. Encounter lists the true in-place pound as not built (stick-slam README:56-58).
- **Evidence:** sim/director/stick.gd:651-654 (only fam = 'bury' changes; the DirBrawl._send call is identical); sim/director/launch.gd:137-141 with data/director/launch.json:4-5 (driveDir at 0 bh = 25 degrees below level); data/biomes/contact.json:10 (skidSin2 0.413, slamSin2 0.883; sin2 of 25 degrees is about 0.18, which is a skid) and sim/world/contact.gd:713; docs/director/pending/stick-slam/README.md:56-58 ('What's left: the grounded pound ... Today the grounded case is a down send, which travels: DRIVE DOWN goes down and forward, about 2,000 units'); sim/director/tools/full_send_check.gd:37 (checks only the cue and the brawl ending); docs/design/slam-and-pace.md:27

### lan-energy-model-off (speed-slam, feel, fixable tonight)

- **Orb does:** He plays the LAN 2v2 round with Orb 2 straight after the solo page.
- **He expects:** The same launch speeds as the page he just played. The 'too fast' launches were his top note, and the energy model is the fix.
- **What happens:** The LAN match is started with Netcode's fixed setup, which has no 'power' key and skips the page's setup patch. power.json stays off, so every launch in the LAN round carries the old x6 sideways boost: the roughly 10,800/s median Orb called too fast. The slam's skid is x4.4 sideways. The LAN exe has no flight or travel sliders either. Both PCs agree, so it doesn't desync, but it plays visibly faster than the solo page.
- **Owner:** netcode
- **Fix:** Add "power": true to NetLan.SETUP, SETUP2 and SETUP2X (net/lan.gd:22-25). The match key already includes the setup, so the two PCs can't differ. Re-run lan_check, rollback (fights2, together) and desync with it.
- **Skeptic's corrected reading:** The LAN round starts from NetLan's fixed setups, which have no 'power' key, and skips the page's setup patch. The energy model stays off on both PCs, so every LAN launch carries the old x6 sideways factor (the ~10,800/s median Orb called too fast), the slam's skid is x3.3-4.4 sideways, and far flight gets its old x10 boost back. The LAN exe has no flat-out or travel sliders. Both PCs match, so there's no desync, but it plays visibly faster than the solo page he just played.
- **Evidence:** net/tools/lan_kit.mjs:54 (LAN main.gd patch: start_match(NetLan.SEED, ai, NetLan.setupFor(args))); render/core/main.gd:324-327 (a given setup skips _match_setup, so the page's _preview_planet with d['power'] = not pw_off, tools/preview/switches.mjs:884-904, never runs); net/lan.gd:22, 24, 25 (SETUP, SETUP2X, SETUP2 have no 'power'); data/fight/power.json:4 ('enabled': false; the commit says 'data stays off'); sim/core/power.gd:100 and :108 (powerOn false, so trav = SimConst.TRAV_LAUNCH); sim/core/constants.gd:17 (TRAV_LAUNCH 6.0); docs/director/pending/press-answers/README.md:10 (the power flip 'waits ... after Sunday'); docs/design/slam-and-pace.md:56

### tier4-sends-uncapped (speed-slam, feel, fixable tonight)

- **Orb does:** Late in a match, once a fighter is at tier 4 (the powerPace row makes charging x4 faster), he lands a full B, a struggle win or a stick full send toward the foe.
- **He expects:** Launches he can read: GD's 9,000/s on-screen cap, slow-in and slow-out, a held moment of 14-18 ticks, and a 30-tick camera hold on the impact (slam-and-pace section 2).
- **What happens:** Only step 1 is built (the model on, x2 along the line). None of the readability budget is in the build, and the flight curve is off. At the slider's default of x2, a full send along the line runs at about 3,350/s at base. That is about 9,120/s at tier 4 with no power and about 11,700/s at tier 4 with full power, past GD's 9,000 cap and past Camera's FLAT_SPEED of 10,000. At that speed the camera switches to its own flat-send shot (ride, release, pull wide).
- **Owner:** simulation
- **Fix:** Tonight: tell Orb on the play page that at tier 4 sends outrun the camera at x2, and that the slider at x1.5 brings a tier-4 full send to about 9,200/s. Next: land Simulation's readable block with Encounter's held moment (power-on park).
- **Skeptic's corrected reading:** Only step 1 is built (the model on, x2 along the line). The readability budget (9,000/s cap, slow-in, slow-out, held moment, 30-tick impact hold) isn't in the build, and the flight curve is off. At the slider's default x2, a full send along the line runs about 3,350/s at base, about 9,120/s at tier 4 with no power and about 11,700/s at tier 4 with full power: over GD's 9,000 cap and about Orb's 'too fast' figure. The camera's flat-send shot tests the speed with the travel factor divided out (split_rig.gd:5239-5241), which stays under 10,000 with the model on, so it never fires. The camera tries to follow these sends softly, past the ~7,000 it can track. At x1.5 a tier-4 full send drops to about 9,200/s.
- **Evidence:** data/fight/power.json:1-117 (no 'readable' block); no paceCap, slowIn, slowOut or cameraHoldTicks in any .gd or .json; docs/director/pending/power-on/README.md:9 ('The held moment waits for Simulation's readable block (off)'; grant-simulation-readable.patch parked there); data/fight/flight.json 'enabled': false with no switches.mjs row; maths from power.json (speedUnit 900, energy base 4.94, topOverBase 12.25, launchTravel 2), sim/core/power.gd:172 (fit, /1.05), sim/director/launch.gd:41 (SMASH ACROSS uy 0.32), sim/world/slide.gd:47-50 (x1.76 along the line), sim/core/forms.gd:342-343 (no tier multiplier with the model on); render/camera/camera_params.gd:415 (FLAT_SPEED 10000); render/core/main.gd:252 (flat_mode 'wide' with tiles); render/camera/split_rig.gd:5241; docs/design/slam-and-pace.md:62-66

### lan-power-off (lan, feel, fixable tonight)

- **Orb does:** Plays the 2v2 together round right after the 10:00 solo page play, launching and flying the same way he just did.
- **He expects:** The pace he just played on the page. Game Design's fix for 'too fast' turns the energy model on: launches x2 along the line, flat out 5,000 at base, and the travel slider he set.
- **What happens:** The LAN match starts from NetLan's fixed setup, which has no "power" key, and data/fight/power.json is off. So the energy model is off in every fight on both PCs. The old x6 sideways launch boost and x10 free flight come back, about 10,800 a second on screen, the speed Orb called too fast on 11-07. There is no travel or flat-out slider. The LAN round will feel faster than the page did minutes earlier, and Orb may think the fix went backwards.
- **Owner:** Netcode (net/lan.gd)
- **Fix:** Before the folder is built, add "power": true to SETUP, SETUP2 and SETUP2X in net/lan.gd, plus "travel" if Orb wants his slider value. Both PCs run one exe, so the handshake key still matches. Gate it with lan_check, transport_check, rollback_check and desync_check --setup=together with the model on, then the kit's --lan-loop rows. If it isn't done, tell Orb the LAN round runs the old speeds and has no slider.
- **Skeptic's corrected reading:** The LAN match starts from NetLan's fixed setups (net/lan.gd:22-25), which have no "power" key, and the kit's start (lan_kit.mjs:54) skips the page's _preview_planet. With data/fight/power.json "enabled": false, the energy model is off in both fights on both PCs. That means the old x6 sideways launch boost and x10 free flight (median about 10,800 a second, slam-and-pace.md:56), and no travel or flat-out setting. Minutes after the page, the LAN round will feel like yesterday's too-fast speed, and Orb may think the fix went backwards. Fix: add "power": true (and "travel" if wanted) to all three setups before the folder is built, and gate it with lan_check, rollback_check and desync_check. Otherwise, tell Orb and Orb 2 that the LAN runs the old speeds.
- **Evidence:** net/lan.gd:22, :24, :25 (SETUP, SETUP2X and SETUP2 have no "power" or "travel"); net/tools/lan_kit.mjs:54 (the LAN start calls start_match(NetLan.SEED, ai, NetLan.setupFor(args)) and so skips the page's _preview_planet); tools/preview/switches.mjs:884-889 (the page's "power": true lives only in _preview_planet); data/fight/power.json:4 "enabled": false; sim/core/power.gd:100 (S.powerOn = su.get("power", on_)); docs/design/slam-and-pace.md:56 (most of 'too fast' is this switch; step 1 is the model on).

### lan-end-card (lan, dead-press, fixable tonight)

- **Orb does:** At the end of the together match he presses Play again, or Main menu and then Start. Mid-match he picks New match from the pause menu.
- **He expects:** A rematch, or at least the window title 'The match is over', which the READ ME says to wait for before closing both windows.
- **What happens:** Three seconds after the last KO the MATCH OVER card opens with Play again highlighted, and it pauses that PC. The kit makes start_match and the menu start do nothing in LAN, so:
- Play again just closes the card over the finished match.
- Main menu then Start goes back to the finished match, and the card reopens 3 s later.
- New match from the pause menu just resumes the fight.
While the card is up the titles say 'Paused. The other PC waits for you' or 'Paused by the other player', because the pause check runs before the match-over check. The card only reacts to the last KO in the fight on that screen, so one PC may never show it. If one PC is closed first, the other shows THE OTHER PC HAS GONE / THE COMPUTER PLAYS ITS FIGHTER over the finished match for 15 s once its card closes.
- **Owner:** Netcode (net/lan.gd, net/tools/lan_kit.mjs)
- **Fix:** Tell both: 'At MATCH OVER (it may show on one PC only), close both windows. Play again, Main menu and New match don't start anything.' Tonight:
- In NetLan._report, check SimCore.ended first.
- Skip _checkDrop and _notice once the match has ended.
- Have lan_kit patch the copy's ui_pause.gd so ENTRIES_OVER is just ["feedback"] and ENTRIES leaves out "menu" and "new".
- **Skeptic's corrected reading:** When the last KO happens, only the PC showing that fight opens the MATCH OVER card, 3 s later, with Play again highlighted. Opening it pauses that PC, so its title says 'Paused. The other PC waits for you' and the other PC's title says 'Paused by the other player', not the 'The match is over' the READ ME tells them to wait for. Play again only closes the card. Main menu then Start returns to the finished match, and the card comes back 3 s later. New match mid-match just resumes. Tell them: 'At MATCH OVER, which may show on one PC only, close both windows.' Optionally, have _report check ended first and have the kit trim ENTRIES_OVER.
- **Evidence:** ui/hud/ui_hud.gd:505-509 (card after MATCH_OVER_DELAY, 3.0 at :533), :1758-1760 (Start sets _menu_last_cfg and resets the card), :2134-2148 (menu, again, new_yes); ui/widgets/ui_pause.gd:12 (ENTRIES_OVER: again, menu, feedback); net/tools/lan_kit.mjs:51-52 (start_match and _on_menu_started return in LAN), :46 (paused calls lan.idle); render/core/main.gd:1325-1326 (card open sets host.paused); net/host.gd:195-198; net/lan.gd:343-348 (paused and remotePaused checked before SimCore.ended), :416-433 (drop and banner never check ended); ui/core/ui_event_hub.gd:397-403 with render/core/main.gd:917 (match_over comes only from the shown fight's ko event); net/tools/lan_words.txt:38.

### lan-same-fight-look (lan, confusing, fixable tonight)

- **Orb does:** Looks at both monitors during the together round, as he did yesterday.
- **He expects:** After Netcode's fix, the old PC clearly shows Orb 2's own fight, not Orb's.
- **What happens:** lan-n4 fixes the one real cause: a pause's rollback could leave fight 0 on the old PC's screen. But what fooled Orb's eye is still there:
- Both pairs are the same two characters. The old PC's player is a second copy of the same hero against a second copy of the same rival, drawn with the same looks.
- Each screen draws only its own pair.
- After 60 s apart, every launch is scored toward the other fight, so the pairs end up in the same place.
- A computer rival whose partner is nearly beaten leaves its own fight and flies flat out at whoever is beating him; one whose fight is over flies to the other fight. The old PC's camera follows its own rival to Orb's spot, where that rival punches at nothing visible. On Orb's screen, blows land from nobody, with only the edge words 'Hit from the other fight' or 'BEAM FROM THE OTHER FIGHT'.
Orb will again think the old PC 'locked onto my player'. The words also say 'the old PC plays the second', which isn't true in together: both PCs play the first fighter.
- **Owner:** EP (words to Orb and Orb 2); later Art (a second look for the second pair)
- **Fix:** Tell them before the round: 'Each screen shows only its own pair. You both play the same hero against the same rival, so the screens look alike, and after a minute the fights drift to the same spot. Your partner and his rival are invisible to you, but they can hit you and you can hit them. When one rival is close to losing, the other leaves to rescue him: on the old PC the camera follows it to Orb's fight and it seems to punch the air; on Orb's screen hits come from nowhere with "Hit from the other fight".' Add a sentence like this to lan_words.txt (the kit only checks its fixed sentences) and fix 'the old PC the second' for together.
- **Skeptic's corrected reading:** Both pairs are the same two characters (stage.gd:65-67), and each screen shows only its own pair. After 60 s apart, launches get a bonus toward the other fight (outside.gd:105-127), and a computer rival whose partner is on the brink flies flat out to the other fight and strikes from outside (outside.gd:156-190). So the old PC's screen ends up showing its own look-alike pair at Orb's spot, and on Orb's screen blows land from an invisible fighter with only 'Hit from the other fight'. Orb is likely to think again that the old PC 'locked onto my player'. Step 7 of the READ ME (lan_words.txt:23) also says the old PC plays the second fighter, which is false in together, where both PCs play the first. Fix: words before the round, plus a line in lan_words.txt.
- **Evidence:** sim/core/stage.gd:65-67 (slotsFor: the roster's first two, twice), :70-75 (the second pair starts half a ring away); sim/director/outside.gd:105-108 (launches scored toward the other fight after join.afterSec; data/director/interrupts.json:631, join.afterSec 60), :156-190 (aiRescue: the flat-out rescue and the finished-fight chase); net/tools/lan_kit.mjs:147-156 (together shortcuts pass no --others), :85 (outside_words on); render/core/main.gd:242 (other fights drawn only with --others); docs/net/two-v-two-lan.md:34 (Netcode: same two characters, screens look alike, a second look is Art's); net/tools/lan_words.txt:7.

### lan-remote-pause (lan, confusing, fixable tonight)

- **Orb does:** One of them presses Start to pause, to talk or open Settings.
- **He expects:** Both games visibly paused, and nothing the other player presses while waiting counts.
- **What happens:** The paused PC shows its pause card. The other PC's fight runs on for about 8 ticks, then freezes mid-action with no word in the game; only the window title says 'Paused by the other player'. Presses made on the frozen PC are kept, because the input hub only clears presses when a tick runs and a pause on the other PC never runs the hub's resume. They all fire the moment play resumes: an attack, a dodge, or with chordPick the biggest of a chord.
- **Owner:** Netcode
- **Fix:** Tell them: say 'pausing' out loud, and on the frozen PC press nothing until it moves. Tonight: in NetLan.tick, call gameHost.hub.drop_edges() while net.remotePaused, and hub.resume() on the tick it clears. Optionally show a PAUSED BY THE OTHER PLAYER banner through SimFx.banner, as _notice does (that needs the look check).
- **Skeptic's corrected reading:** When one PC pauses, the other runs on for about 8 ticks, then freezes, with only the window title saying 'Paused by the other player' (lan.gd:345). Buttons pressed on the frozen PC are not dropped: the hub keeps their edges because no tick takes them (layout.gd:1314-1317), and they go in on the first tick after play resumes, so a blow or a dodge comes out unasked. Tell them to press nothing on the frozen PC. Fix: drop_edges while remotePaused, and resume on the tick it clears.
- **Evidence:** net/lan.gd:345-346 (window title only; no render or UI code reads remotePaused), :150 (tick returns false when no frame advanced); net/host.gd:195-198; net/session.gd:146-158; net/tools/lan_kit.mjs:45; render/core/sim_host.gd:448-458 (presses dropped only during a set piece or the intro), :228-232 (a PC's own pause runs hub.resume); sim/input/layout.gd:1314-1317 (presses cleared only when a tick is taken); net/tools/lan_words.txt:39.

### lan-out-rumble (lan, minor, fixable tonight)

- **Orb does:** Gets knocked out first and watches his partner's fight.
- **He expects:** A quiet pad, since he's out.
- **What happens:** About 6 s after his KO the screen switches to his partner's fight, but his pad stays on hub slot 0, and in that fight slot 0 is the partner. So his pad rumbles with every blow the partner lands and every hit he takes (hapticImpact is on), plus the partner's full sends, stage rumbles and stick refusals.
- **Owner:** Netcode (kit patch)
- **Fix:** Tell them. Or have lan_kit patch main.gd's _on_haptic to return while host.lan is showing the partner's fight (viewSlot differs from the player's own slot).
- **Skeptic's corrected reading:** Once a player is out and the screen has switched to the partner's fight (after the KO close-up, lan.gd:160-166, 191-203), their pad stays on hub slot 0, which in that fight is the partner. So their pad rumbles for every blow the partner lands or takes, and for the partner's launches, landings and building breaks (hapticImpact is on, timing.json:54; haptics.gd:301-325). Minor: tell them, or have the kit skip _on_haptic while the view is the partner's fight.
- **Evidence:** net/lan.gd:202-203 (while watching the partner the pad stays where it was); render/core/main.gd:917-920 and :991-1007 (rumble by the event's actor slot); sim/input/haptics.gd:295-312; sim/input/hub.gd:833-839 (rumble_target by slot); tools/preview/switches.mjs:135 (hapticImpact row, not held).

### lan-ai-level (lan, minor, fixable tonight)

- **Orb does:** Sets Computer to Easy on the start menu before pressing Start, as in his solo plays (11-06 was against an easy rival).
- **He expects:** Easy computer rivals.
- **What happens:** The LAN start ignores the menu's level. NetLan's setups carry no aiLevel and the host's _ai_part is skipped, so both computer rivals play at ai.json's default, Medium.
- **Owner:** Netcode / EP (which level)
- **Fix:** Tell them the computers are Medium whatever the menu says. Or add "aiLevel": "easy" (Orb's pick) to the LAN setups in net/lan.gd together with the power change and its gates.
- **Skeptic's corrected reading:** In the LAN build the start menu's Computer row does nothing: whatever level is picked, both computer rivals in 2v2 together play at ai.json's Medium, because NetLan's setups (lan.gd:22-25) carry no aiLevel and the kit's LAN start skips the menu's _ai_part. Tell Orb and Orb 2 the computers are Medium, or add "aiLevel" to the together setup along with the power change.
- **Evidence:** ui/widgets/ui_menu.gd:74-80 (the Computer row shows with 1 player); render/core/main.gd:437-438 and :1342 (_ai_level is used only through _ai_part); net/tools/lan_kit.mjs:53-54; net/lan.gd:22-25; sim/core/sim.gd:154; data/director/ai.json:52 ("level": "medium").

## Couldn't tell

- [notes] Whether tonight's build is made with --on refusedCue. The brief lists only the four city rows as held, but switches.mjs:144 and docs/tools/sunday-build.md:8 hold refusedCue too (and aimCuts).
- [notes] Which tree the LAN folder is cut from (main or Tools' kept tree), and whether it is rebuilt from 4890bdd9 plus anchor-midpoint at all. If it is cut from main, fullSend, flightStrikes, strikeStages, beamMove, airBrake and the struggle push rows are all off in the LAN round.
- [notes] Whether a real Xbox pad press counts as a browser activation in Opera GX. That decides whether the pad wake fixes the sound.
- [notes] Whether a stick slam leaves a crater at base tier (Game Design's QA row 'slams leave a crater at every tier'). The stick-slam README still lists the send's crater as owed by Simulation and World.
- [notes] Whether the 2v2 stutter is gone on the old PC. anchor-midpoint and the LAN tuning were measured native on the main PC (anchor-midpoint seed 2's worst tick rose from 12.6 to 19.2 ms).
- [notes] Whether a long match shows more than 16 store craters: TILE_BOWLS 16 (look.gd:596), and after crater-store, craters past the 16 nearest are not drawn.
- [notes] Whether Orb was told on the play page that RT + stick does nothing, that firing back costs 40 energy (answerKi 40, interrupts.json:284), and that the slam needs a rival in the air.
- [notes] Whether Opera GX rumbles the Xbox 360 pad (still open from yesterday's review).
- [pad] Whether the EP's build command passes `--on refusedCue`. By default the page holds it off (switches.mjs:144, docs/tools/sunday-build.md:8). With it on, the first finding shrinks to the missing not_ready word.
- [pad] How long planned exchanges actually run. That decides whether the fold bug shows as a replayed attack (exchange under 90 ticks) or as 'Locked in' (over 90). Not measured.
- [pad] Whether Orb's LT-then-button presses land inside takeBack.ticks 4 (playable-build.md:41-50). The hint 'Hold LT, then press' may lead to presses past the window, which give a plain blow plus LT's own slip or escape instead of a flight strike. Not measured on this build.
- [pad] In 2v2 LAN the hub's no-answer wait is cleared by the cue's actor index, and hub.gd:861-863 accepts only 0 and 1 (main.gd:1003). Not traced: whether fight-local actor indices always match the hub slot after a trade or view change (net/lan.gd:195-218).
- [pad] Presses made during a set-piece pause are dropped with no word (render/core/sim_host.gd:450-456). The 1229 ledger counted 16. Not checked how often a normal match pauses.
- [pad] Even with refusedCue on, a fresh RT press when free gets no answer. power_start needs i.charge, which comes holdStart (12) ticks after the press (press-answers.diff:37-38). Whether the charge aura reads as the answer is Orb's call.
- [pad] A quick RB flick while an approach is pending or while not free returns true from DirBlast.press with no cue (sim/director/blast.gd:51-54), so it stays silent even with refusedCue on.
- [pad] The anchor-midpoint park changes only the sim's re-anchor test (sim/core/swing.gd). Found nothing press-facing in it; not run.
- [speed-slam] Whether a real held stick strike in the air reaches its top stage. GD asked Encounter to check that a hold above airAbove charges (slam-and-pace.md section 3), but full_send_check calls DirStick.landed by hand with top=true (full_send_check.gd:73-79), and the 4890bdd9 gate ran with the switches off (docs/ep/runs/4890bdd9/gate.txt).
- [speed-slam] Which tree tonight's LAN folder is built from (lan_kit.mjs --tree: a copy of main or Tools' stack). From a plain main copy, no page rows (rightStick, strikeStages, fullSend, flickKeep) would be on in the LAN round at all.
- [speed-slam] Whether the shortcut passes ?travel=N. If it does, every page load resets the slider to it over the saved value (blackbox.mjs:466).
- [speed-slam] Camera's launch follow starts only at 4,000/s (camera_params.gd:181, split_rig.gd:1825). With the model on, base sends run about 2,400-3,350/s along the line. I didn't trace whether the live launch-director path uses this gate.
- [speed-slam] Encounter reported that knock_wall fails its World row with fullSend and flickKeep on (docs/director/pending/stick-slam/README.md:51). I didn't trace what Orb would see.
- [speed-slam] How often a tier-4 slam hold survives a fighting AI: stage 6 comes at 120 ticks (2.0 s), a medium stops it before 28 ticks, and a heavy, beam, grab or dodge can stop it at any time. Not measured.
- [speed-slam] The exact skid length of the DRIVE DOWN slam with the model on (not run). Encounter's check, with the model off, measured about 2,000 units for the grounded case.
- [speed-slam] Whether Orb reaches tier 4 in a 10-15 minute play, which decides whether the uncapped tier-4 speeds and the meteor crater come up at all.
- [lan] Whether the LAN folder's exe is built after the press-answers and anchor-midpoint parks land. The stutter relief needs anchor-midpoint inside the exe; both PCs share one exe, so there's no desync either way.
- [lan] How long the old PC's frames past 100 ms still are in this build, how much of that is drawing versus the sim, and so how long the main PC's freezes will be. Nothing was run.
- [lan] What caused yesterday's 'standing by the same hill' moment: the launches scored toward the other fight (join.afterSec 60), a computer rescue, or the pause-rollback bug lan-n4 fixes. Yesterday's lan-log files were not read.
- [lan] Whether the HUD plate for slot 0 shows the partner as knocked out after the switch. The UI model's ko and out flags carry over from the player's own KO (ui/core/ui_event_hub.gd:401, :410); how the plate draws them wasn't traced.
- [lan] A freeze of one PC longer than 8 s (for example holding the window's title bar on Windows): the other PC hands its seat to the computer (net/lan.gd:416-423), and the takeover record in its packets (net/host.gd:133-134) would probably hand the frozen PC's own fighter to the computer with no word on that PC. As far as read, lan_check doesn't cover it.
- [lan] Whether rollback re-runs repeat sounds or rumble on the main PC.
- [lan] The refusedCue row has a held reason in tools/preview/switches.mjs:144, and press-answers depends on press.refusedCue, so its answers may be inactive in this build (for the pad lane to confirm).
- [lan] Whether a together round at the old speeds reaches the 14:00 cap (all four nearly beaten) and the 15:00 last event within a 10 to 15 minute session; docs/design/two-v-two.md:144 estimates 12 to 14 minutes a match.
- [lan] The LAN setup has no pushMode, so the sim uses the default push for everyone. If either player changes the beam-struggle push option in Settings, the left panel would teach that PC's choice while the sim still reads the default.

class_name NetAiDriver
extends RefCounted
## A fighter AI as a network player (docs/net/rollback.md section 12): it answers for one slot of a peer the way NetBot
## does, but from the match itself. Each answer reads the peer's present state (the ticks it has run, predictions
## included, as a player's screen shows it) and runs the sim's own opponent AI (DirAI.aiInput) for its slot; the packed
## intent it writes is the slot's input for tick frame + delay, sent and confirmed like a player's.
##
## DirAI.aiInput is not a pure function of the state: it draws from S.rng (pickW, its timers), counts its timers down in
## f.ai, writes the slot's held charge into f.act.dirI[AI_HOLD], sets f.act.v2 and f.input, and can emit a "searching" fx.
## Run on the live state, those writes would reach one peer's sim and not the other's (the check's "impure" negative
## control). So the driver runs it on a copy (NetSnapshot.take): the state it reads is the peer's, and every write lands
## in the copy, which is dropped. What the AI keeps between ticks (its AiState, its own random stream and its held charge)
## is the driver's, outside the sim, as a player's memory is: a rollback does not touch it, and it needs nothing restored,
## because an input once sent is never taken back.
##
## The slot it drives must be a v2 slot (setup "v2"): the AI states its stance through held fields (SimAct), as a v2 pad
## does. The sim's AI paths that the director runs for an AI fighter (DirAI.react and the other `f.ai != null` hooks) do
## not run for a slot whose sim fighter is not the AI's: a networked AI plays only through its inputs, as a player would.

var session: NetSession = null   # the peer's session, whose S it reads; null for a straight run (then sim is read)
var sim: SimState = null
var slot: int = 0
var mem := SimState.AiState.new()
var rng: SimRng
var hold: int = 0                # DirInterrupt.AI_HOLD between ticks: the attack button it is holding for a charge
var pool := NetSnapshot.Pool.new()
var impure: bool = false         # tests only (the check's negative control): run the AI on the live state, writes and all
var answers: int = 0


func _init(slot_: int, seed: int, session_: NetSession = null, sim_: SimState = null) -> void:
	slot = slot_
	session = session_
	sim = sim_
	rng = SimRng.new(SimRng.deriveSeed(seed & 0xFFFFFFFF, "netai%d" % slot))


## The packed intent for the next tick it answers for, read from the present state.
func next() -> int:
	if session != null:
		session.sync()   # the inputs that arrived this frame first: the freshest present the peer can show
	answers += 1
	var S: SimState = session.S if session != null else sim
	return think(S)


## The AI's answer for the slot in state S. S is not changed (unless impure).
func think(S: SimState) -> int:
	if S.game.ko != null or S.fighters[slot].ai != null:
		return NetSession.NEUTRAL   # over, or the slot is the sim's own AI (it reads no input)
	if impure:
		return _run(S)
	var snap := NetSnapshot.take(S, pool)
	var p: int = _run(snap.root)
	pool.put(snap)
	return p


func _run(X: SimState) -> int:
	var f = X.fighters[slot]
	var keepRng: SimRng = X.rng
	var keepAi = f.ai
	var keepV2: bool = f.act.v2
	var keepHold: int = DirInterrupt.gi(f, DirInterrupt.AI_HOLD)
	if not impure:
		X.rng = rng   # its own stream: the copy's rng is the match's, and the match's would repeat while the sim draws nothing
	f.ai = mem
	DirInterrupt.si(f, DirInterrupt.AI_HOLD, hold)
	SimIntent.clearIntent(f.input)
	DirAI.aiInput(X, f)
	var p: int = SimIntent.pack(f.input)
	hold = DirInterrupt.gi(f, DirInterrupt.AI_HOLD)
	# Put back what the copy's objects held, so the pool never keeps the driver's own objects (its next take would write
	# a copy into them). On the live state (impure) the AI's rng draws and other writes stay: that is the bug planted.
	X.rng = keepRng
	f.ai = keepAi
	if not impure:
		f.act.v2 = keepV2
		DirInterrupt.si(f, DirInterrupt.AI_HOLD, keepHold)
	return p


func close() -> void:
	pool.clear()

class_name NetStraight
extends RefCounted
## The straight run the transport checks compare against (enet_check.gd, transport_check.gd): the bots' inputs at a
## given input delay, no network, with what a peer records at each confirmed tick (NetDesync.digest of the state after
## it, joined to the tick's feed and fx digest) and the gameplay SimHash every hashEvery ticks and at the end.

const SETUPS: Dictionary = {   # rollback_check.gd's
	"default": {},
	"features": {"v2": [true, true], "forms": true, "brake": true, "flight": true, "hitstop": true, "ricochet": true},
	"planet": {"planet": 7, "touch": 3},
}


## {digests: [tick - 1] -> "digest|out", hashes: {"tick": hash}, final}
static func run(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var digests: Array = []
	var hashes: Dictionary = {}
	for t in range(ticks):
		var ins: Array = []
		for k in range(2):
			ins.append(SimIntent.unpack(NetSession.NEUTRAL if t < delay else bots[k].next()))
		SimCore.step(S, ins)
		var out: String = NetSession.outDigest(S)
		S.out.feed.clear()
		S.out.fx.clear()
		digests.append(NetDesync.digest(S) + "|" + out)
		if (t + 1) % hashEvery == 0 or t + 1 == ticks:
			hashes[str(t + 1)] = SimHash.stateHash(S).gameplay
	var ref := {"digests": digests, "hashes": hashes, "final": SimHash.stateHash(S).gameplay}
	SimCore.dispose(S)
	return ref

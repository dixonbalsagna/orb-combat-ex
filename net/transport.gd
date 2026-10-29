class_name NetTransport
extends RefCounted
## The transport under a peer's host (docs/net/rollback.md section 11): one link to the other peer that carries the
## session's packets, Dictionaries of inputs, acknowledgements, checkpoint digests and the handshake's and time sync's
## fields. Delivery is unreliable and unordered, as UDP, ENet's unsequenced channel and a WebRTC data channel opened with
## ordered = false and maxRetransmits = 0 all are; the protocol above survives that, because every packet resends what
## the other side has not acknowledged and every field is idempotent.
## Implementations: NetLinkTransport (the loopback's simulated links, no sockets) and NetEnetTransport (native, ENet).
## WebRTC (the browser) is designed to plug in here too (rollback.md section 11). `now` is the host's clock in ms: the
## loopback's simulated time, or a real process's wall clock. The transport never reaches the sim.

## Bytes on the wire. A game packet (the session's: from, frame, ack, first, inputs, chk, and the host's ts, echo, age
## and adv) has a fixed binary layout, little-endian: kind byte 1, from u8, frame u32, ack u32, first u32, input count
## u8 and the packed intents as i64, checkpoint count u8 and each as boundary u32 plus its 16-byte digest, ts f64,
## echo f64, age f32, adv f32: 40 bytes, plus 8 per unacknowledged input and 20 per checkpoint digest. A packet that
## carries the AI's takeovers (its optional `ai` field, rollback.md section 13) adds a count u8 (at least 1) and each as
## slot u8 plus tick u32: 6 bytes for one. Anything
## else (the handshake's packets, a few a second for a moment) is kind byte 2 and Godot's Variant encoding, which never
## decodes objects (bytes_to_var, not bytes_to_var_with_objects), so a hostile packet cannot instantiate anything.
const GAME_KEYS: Array = ["from", "frame", "ack", "first", "inputs", "chk", "ts", "echo", "age", "adv"]


static func encode(pk: Dictionary) -> PackedByteArray:
	if not _isGame(pk):
		var v := PackedByteArray([2])
		v.append_array(var_to_bytes(pk))
		return v
	var b := StreamPeerBuffer.new()
	b.big_endian = false
	b.put_u8(1)
	b.put_u8(int(pk.from))
	b.put_u32(int(pk.frame))
	b.put_u32(int(pk.ack))
	b.put_u32(int(pk.first))
	var ins: PackedInt64Array = pk.inputs
	b.put_u8(ins.size())
	for p in ins:
		b.put_64(p)
	var chk: Array = pk.chk
	b.put_u8(chk.size())
	for c in chk:
		b.put_u32(int(c[0]))
		b.put_data(str(c[1]).hex_decode())
	b.put_double(float(pk.ts))
	b.put_double(float(pk.echo))
	b.put_float(float(pk.age))
	b.put_float(float(pk.adv))
	var ai: Array = pk.get("ai", [])
	if not ai.is_empty():
		b.put_u8(ai.size())
		for e in ai:
			b.put_u8(int(e[0]))
			b.put_u32(int(e[1]))
	return b.data_array


## A packet from bytes, or null for anything malformed.
static func decode(b: PackedByteArray) -> Variant:
	if b.is_empty():
		return null
	if b[0] == 2:
		if b.size() < 9:
			return null
		var v: Variant = bytes_to_var(b.slice(1))
		return v if v is Dictionary else null
	if b[0] != 1 or b.size() < 16:
		return null
	var r := StreamPeerBuffer.new()
	r.big_endian = false
	r.data_array = b
	r.seek(1)
	var pk := {"from": r.get_u8(), "frame": r.get_u32(), "ack": r.get_u32(), "first": r.get_u32()}
	var n: int = r.get_u8()
	if r.get_available_bytes() < n * 8 + 1:
		return null
	var ins := PackedInt64Array()
	for i in range(n):
		ins.append(r.get_64())
	pk["inputs"] = ins
	var m: int = r.get_u8()
	var tail: int = r.get_available_bytes() - (m * 20 + 24)   # past the digests and the clock fields: the takeovers, if any
	if tail < 0 or (tail > 0 and (tail - 1) % 5 != 0) or tail == 1:
		return null
	var chk: Array = []
	for i in range(m):
		var t: int = r.get_u32()
		var got: Array = r.get_data(16)
		chk.append([t, (got[1] as PackedByteArray).hex_encode()])
	pk["chk"] = chk
	pk["ts"] = r.get_double()
	pk["echo"] = r.get_double()
	pk["age"] = r.get_float()
	pk["adv"] = r.get_float()
	if tail > 0:
		var na: int = r.get_u8()
		if na < 1 or tail != 1 + na * 5:
			return null
		var ai: Array = []
		for i in range(na):
			var slot: int = r.get_u8()
			ai.append([slot, r.get_u32()])
		pk["ai"] = ai
	return pk


## A packet with exactly the game packet's fields, each in range for the binary layout.
static func _isGame(pk: Dictionary) -> bool:
	var extra: int = 1 if pk.has("ai") else 0
	if pk.size() != GAME_KEYS.size() + extra:
		return false
	for k in GAME_KEYS:
		if not pk.has(k):
			return false
	if extra == 1:
		if not (pk.ai is Array) or pk.ai.size() > 255:
			return false
		for e in pk.ai:
			if not (e is Array) or e.size() != 2 or int(e[0]) < 0 or int(e[0]) > 255 or int(e[1]) < 0 or int(e[1]) > 0xFFFFFFFF:
				return false
	if not (pk.inputs is PackedInt64Array) or pk.inputs.size() > 255 or not (pk.chk is Array) or pk.chk.size() > 255:
		return false
	for c in pk.chk:
		if str(c[1]).length() != 32:
			return false
	return int(pk.from) >= 0 and int(pk.from) < 256


var pktOut: int = 0
var pktIn: int = 0
var bytesOut: int = 0
var bytesIn: int = 0


## Queue one packet for the other peer. It may be lost, delayed or reordered.
func send(_now: float, _pk: Dictionary) -> void:
	pass


## The packets that have arrived by `now`.
func receive(_now: float) -> Array:
	return []


## False once the link is gone (a disconnect, a failed connect).
func isOpen() -> bool:
	return true


func close() -> void:
	pass

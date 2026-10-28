class_name NetEnetTransport
extends NetTransport
## The native transport: Godot's built-in ENet (ENetConnection), one peer, one channel, every packet unsequenced
## (unreliable, unordered: what NetTransport promises and no more). listen() waits for the other peer; dial() connects to
## it. receive() also services the connection, so the host calls it once a frame.
## For tests, impair() puts a NetLoopback.Link in front of the socket on the sending side: each outgoing packet waits
## its one-way delay (with jitter) on the host's clock, or is dropped, before ENet sends it.

var conn: ENetConnection = null
var peer: ENetPacketPeer = null
var listening: bool = false
var lag: NetLoopback.Link = null   # the injected impairment, or null
var failed: String = ""
var disconnected: bool = false


## Bind addr:port and wait for one peer.
static func listen(addr: String, port: int) -> NetEnetTransport:
	var t := NetEnetTransport.new()
	t.conn = ENetConnection.new()
	t.listening = true
	var e: int = t.conn.create_host_bound(addr, port, 1, 1)
	if e != OK:
		t.failed = "listen on %s:%d failed (error %d)" % [addr, port, e]
	return t


## Connect to a peer listening on addr:port.
static func dial(addr: String, port: int) -> NetEnetTransport:
	var t := NetEnetTransport.new()
	t.conn = ENetConnection.new()
	var e: int = t.conn.create_host(1, 1)
	if e != OK:
		t.failed = "create_host failed (error %d)" % e
		return t
	t.peer = t.conn.connect_to_host(addr, port, 1)
	if t.peer == null:
		t.failed = "connect to %s:%d failed" % [addr, port]
	return t


## Delay and drop outgoing packets like a loopback link: oneWay and jitter in ms, loss a share, seeded.
func impair(oneWay: float, jitter: float, loss: float, seed: int) -> void:
	lag = NetLoopback.Link.new(oneWay, jitter, loss, seed)


## True once the connection is up.
func connected() -> bool:
	return peer != null and peer.get_state() == ENetPacketPeer.STATE_CONNECTED


func send(now: float, pk: Dictionary) -> void:
	if lag != null:
		lag.send(now, pk)
		_flush(now)
	else:
		_put(pk)


func _flush(now: float) -> void:
	if lag != null:
		for pk in lag.receive(now):
			_put(pk)


func _put(pk: Dictionary) -> void:
	if not connected():
		return
	var b := NetTransport.encode(pk)
	if peer.send(0, b, ENetPacketPeer.FLAG_UNSEQUENCED) == OK:
		pktOut += 1
		bytesOut += b.size()
		conn.flush()   # ENet otherwise sends on the next service, a frame later


func receive(now: float) -> Array:
	_flush(now)
	var got: Array = []
	if conn == null or failed != "":
		return got
	while true:
		var ev: Array = conn.service(0)
		var kind: int = ev[0]
		if kind == ENetConnection.EVENT_NONE:
			break
		if kind == ENetConnection.EVENT_ERROR:
			failed = "ENet service error"
			break
		if kind == ENetConnection.EVENT_CONNECT:
			if listening and peer == null:
				peer = ev[1]
		elif kind == ENetConnection.EVENT_DISCONNECT:
			if ev[1] == peer:
				disconnected = true
		elif kind == ENetConnection.EVENT_RECEIVE:
			var from: ENetPacketPeer = ev[1]
			while from.get_available_packet_count() > 0:
				var b: PackedByteArray = from.get_packet()
				if from != peer:
					continue
				bytesIn += b.size()
				var pk: Variant = NetTransport.decode(b)
				if pk != null:
					pktIn += 1
					got.append(pk)
	return got


func isOpen() -> bool:
	return failed == "" and not disconnected


func close() -> void:
	if conn == null:
		return
	if connected():
		peer.peer_disconnect_now()
	conn.flush()
	conn.destroy()
	conn = null
	peer = null

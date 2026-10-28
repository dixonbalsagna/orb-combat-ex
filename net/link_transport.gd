class_name NetLinkTransport
extends NetTransport
## The loopback's transport: one NetLoopback.Link out and the other peer's link in, on simulated time (no sockets).
## With `wire`, every packet goes through NetTransport.encode and decode on its way, so the loopback's checks also
## exercise the bytes a real transport sends.

var out: NetLoopback.Link
var into: NetLoopback.Link
var wire: bool = false


func _init(out_: NetLoopback.Link, into_: NetLoopback.Link, wire_: bool = false) -> void:
	out = out_
	into = into_
	wire = wire_


func send(now: float, pk: Dictionary) -> void:
	pktOut += 1
	if wire:
		var b := NetTransport.encode(pk)
		bytesOut += b.size()
		pk = NetTransport.decode(b)
	out.send(now, pk)


func receive(now: float) -> Array:
	var got: Array = into.receive(now)
	pktIn += got.size()
	return got

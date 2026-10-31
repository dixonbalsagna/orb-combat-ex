extends SceneTree
func old_exp(x: float) -> float:
	var k: float = floor(x * SimDetMath.INVLN2 + 0.5)
	var r: float = (x - k * SimDetMath.LN2_HI) - k * SimDetMath.LN2_LO
	var p: float = SimDetMath.EXP_C[17]
	for i in range(16, -1, -1):
		p = SimDetMath.EXP_C[i] + r * p
	var y: float = 1.0 + r * p
	var j: float = 0.0
	while j < k:
		y = y * 2.0
		j += 1.0
	j = 0.0
	while j > k:
		y = y / 2.0
		j -= 1.0
	return y
func _init() -> void:
	var bad: int = 0
	var n: int = 0
	var x: float = -3000.0
	while x < 800.0:
		n += 1
		var a: float = old_exp(x)
		var b: float = SimDetMath.exp(x)
		if var_to_bytes(a) != var_to_bytes(b):
			bad += 1
			print("DIFF ", x, " ", a, " ", b)
		x += 3.37
	var t0: int = Time.get_ticks_usec()
	var v: float = SimDetMath.exp(-1.0e9 / 40.0)
	print("exp checked at %d points over -3000..800: %d differ. exp(-1e9/40) = %s in %d us" % [n, bad, str(v), Time.get_ticks_usec() - t0])
	quit(0)

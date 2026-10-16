extends SceneTree
# People per building and per street length, per settlement and district (scratch, World).
#   godot --headless --path . --script res://sim/world/tools/crowd_probe.gd

func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var tot: float = 0.0
	var all: Array = []
	for b in S.buildings:
		tot += b.pop
		all.append(b)
	print("buildings %d, people %d (pop0 %d)" % [S.buildings.size(), int(tot), int(S.world.pop0)])
	# by row and kind
	var byrow := {}
	for b in all:
		var k: String = "row%d %s" % [b.row, b.kind]
		if not byrow.has(k):
			byrow[k] = [0, 0.0, 0.0]
		byrow[k][0] += 1
		byrow[k][1] += b.pop
		byrow[k][2] = maxf(byrow[k][2], b.pop)
	for k in byrow:
		print("  %-14s n %3d people %5d mean %5.1f max %4d" % [k, byrow[k][0], int(byrow[k][1]), byrow[k][1] / float(byrow[k][0]), int(byrow[k][2])])
	# top shares
	var pops: Array = []
	for b in all:
		pops.append(b.pop)
	pops.sort()
	pops.reverse()
	var top10: float = 0.0
	var top25: float = 0.0
	for i in range(mini(25, pops.size())):
		if i < 10:
			top10 += pops[i]
		top25 += pops[i]
	print("top 10 buildings hold %.1f%% of the people, top 25 hold %.1f%%; the biggest %d, the median %d" % [100.0 * top10 / tot, 100.0 * top25 / tot, int(pops[0]), int(pops[pops.size() / 2])])
	# people per 1000 units of the front street, in a 3000-unit window, the densest and the median
	var fs: Array = []
	for b in all:
		if b.row == 1:
			fs.append(b)
	fs.sort_custom(func(a, c): return a.x < c.x)
	var win: float = 3000.0
	var dens: Array = []
	var j: int = 0
	for i in range(fs.size()):
		var x0: float = fs[i].x
		var sum: float = 0.0
		var k: int = i
		while k < fs.size() and fs[k].x < x0 + win:
			sum += fs[k].pop
			k += 1
		dens.append(sum)
	dens.sort()
	dens.reverse()
	print("front street (row 1), people in a 3000-unit window: densest %d, 10th densest %d, median %d (%d buildings in row 1)" % [int(dens[0]), int(dens[mini(9, dens.size() - 1)]), int(dens[dens.size() / 2]), fs.size()])
	# nearest-neighbour: the share of people whose building has a neighbour with pop >= 40 within 600 units
	var close: float = 0.0
	for b in fs:
		var n: float = 0.0
		for c in fs:
			if c != b and absf(c.x - b.x) < 300.0:
				n += c.pop
		close += b.pop * (1.0 if n > 40.0 else 0.0)
	print("share of front-street people with more than 40 others within 300 units: %.0f%%" % (100.0 * close / maxf(1.0, tot)))
	quit()

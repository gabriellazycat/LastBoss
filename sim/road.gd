class_name SimRoad
extends RefCounted
## Estrada gerada por semente: trechos simples e bifurcações (dois ramos que se reencontram).
## Coordenadas no plano (x, y); o herói anda no sentido -y.

const LOC_TYPES := ["village", "tavern", "fountain", "ritual", "shrine", "bridge"]
enum LocState { ACTIVE, USED, DESTROYED, WON }

var legs: Array = []        # {"kind", "pts": [PackedVector2Array], "len": [float], "chosen", "closed", "forced"}
var locations: Array = []   # {"type", "pos", "leg", "branch", "state", "r", "t", "hp", "max_hp"}
var route := PackedVector2Array()
var cum := PackedFloat32Array()
var next_leg := 0
var complete := false
var lair := Vector2.ZERO
var lair_dir := Vector2(0, -1)


func generate(rng: RandomNumberGenerator, rules: Dictionary) -> void:
	var R: Dictionary = rules["road"]
	var nforks := rng.randi_range(int(R["forks"][0]), int(R["forks"][1]))
	var L: float = R["target_length"]
	var nsingle := nforks + 1
	var single_len := L * 0.55 / nsingle
	var fork_len := L * 0.45 / nforks
	var p := Vector2.ZERO
	var ang := 0.0
	for i in nsingle + nforks:
		if i % 2 == 0:
			var pts := PackedVector2Array()
			var step: float = R["point_step"]
			var n := int(ceil(single_len / step))
			pts.append(p)
			var wig: float = R["wiggle"] / 100.0
			for k in n:
				ang = clampf(ang + rng.randf_range(-wig, wig), -0.6, 0.6)
				p += Vector2(sin(ang), -cos(ang)) * step
				pts.append(p)
			legs.append({"kind": "single", "pts": [pts], "len": [_length(pts)], "chosen": 0, "closed": -1, "forced": -1})
		else:
			var dir := Vector2(sin(ang), -cos(ang))
			var b := p + dir * fork_len
			var perp := Vector2(-dir.y, dir.x)
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var extra := rng.randf_range(float(R["long_branch_extra"][0]), float(R["long_branch_extra"][1]))
			var short := _bezier(p, b, (p + b) * 0.5 + perp * side * rng.randf_range(6.0, 12.0), R["point_step"])
			var h: float = R["fork_spread"] * 0.5
			var long := PackedVector2Array()
			for it in 16:
				long = _bezier(p, b, (p + b) * 0.5 - perp * side * h, R["point_step"])
				if _length(long) >= _length(short) * (1.0 + extra):
					break
				h *= 1.18
			var br := [short, long]
			if rng.randf() < 0.5:
				br = [long, short]
			legs.append({"kind": "fork", "pts": br, "len": [_length(br[0]), _length(br[1])], "chosen": -1, "closed": -1, "forced": -1})
			p = b
	var last: PackedVector2Array = legs[-1]["pts"][0]
	lair = last[last.size() - 1]
	lair_dir = (lair - last[last.size() - 2]).normalized()
	_place_locations(rng, rules)
	_append(legs[0]["pts"][0])
	next_leg = 1


func _bezier(a: Vector2, b: Vector2, c: Vector2, step: float) -> PackedVector2Array:
	var approx := a.distance_to(c) + c.distance_to(b)
	var n := maxi(2, int(ceil(approx / step)))
	var out := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		out.append(a.lerp(c, t).lerp(c.lerp(b, t), t))
	return out


static func _length(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in pts.size() - 1:
		s += pts[i].distance_to(pts[i + 1])
	return s


static func _point_on(pts: PackedVector2Array, d: float) -> Vector2:
	var s := 0.0
	for i in pts.size() - 1:
		var l := pts[i].distance_to(pts[i + 1])
		if s + l >= d:
			return pts[i].lerp(pts[i + 1], (d - s) / maxf(l, 0.001))
		s += l
	return pts[pts.size() - 1]


func _place_locations(rng: RandomNumberGenerator, rules: Dictionary) -> void:
	var R: Dictionary = rules["road"]
	var spacing: float = R["target_length"] / rng.randi_range(int(R["route_locations"][0]), int(R["route_locations"][1]))
	var slots: Array = []
	for li in legs.size():
		for bi in legs[li]["pts"].size():
			var pts: PackedVector2Array = legs[li]["pts"][bi]
			var length: float = legs[li]["len"][bi]
			var d := spacing * rng.randf_range(0.45, 0.8)
			if li == 0:
				d = maxf(d, 70.0)
			while d < length - 25.0:
				slots.append({"leg": li, "branch": bi, "pos": _point_on(pts, d), "d": d})
				d += spacing * rng.randf_range(0.85, 1.2)
	# Embaralha de forma determinística.
	var order: Array = range(slots.size())
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	var types: Array = []
	var nshr := rng.randi_range(int(R["shrines"][0]), int(R["shrines"][1]))
	for i in nshr:
		types.append("shrine")
	for t in ["village", "tavern", "fountain", "ritual", "bridge"]:
		types.append(t)
	var w: Dictionary = R["location_weights"]
	var wsum := 0.0
	for k in w:
		wsum += float(w[k])
	while types.size() < slots.size():
		var r := rng.randf() * wsum
		for k in w:
			r -= float(w[k])
			if r <= 0.0:
				types.append(k)
				break
	var L: Dictionary = rules["locations"]
	for oi in mini(types.size(), order.size()):
		var s: Dictionary = slots[order[oi]]
		var t: String = types[oi]
		var hp := float(L[t].get("hp", 0))
		locations.append({"type": t, "pos": s["pos"], "leg": s["leg"], "branch": s["branch"], "d": s["d"],
			"state": LocState.ACTIVE, "r": float(L[t]["radius"]), "t": 0.0, "hp": hp, "max_hp": hp, "entered": false})


# ---- rota do herói ----

func _append(pts: PackedVector2Array) -> void:
	var start := 0
	if route.size() > 0:
		start = 1
	for i in range(start, pts.size()):
		var p := pts[i]
		if route.size() == 0:
			cum.append(0.0)
		else:
			cum.append(cum[cum.size() - 1] + route[route.size() - 1].distance_to(p))
		route.append(p)


func length() -> float:
	return cum[cum.size() - 1]


## Acrescenta o próximo trecho. branch é ignorado em trechos simples.
func advance(branch: int) -> void:
	if complete:
		return
	var leg: Dictionary = legs[next_leg]
	var b := 0 if leg["kind"] == "single" else branch
	leg["chosen"] = b
	_append(leg["pts"][b])
	next_leg += 1
	if next_leg >= legs.size():
		complete = true


func pending_leg() -> Dictionary:
	if complete:
		return {}
	return legs[next_leg]


## Próxima bifurcação ainda não decidida (para cartas de rota).
func next_fork_index() -> int:
	for i in range(next_leg, legs.size()):
		if legs[i]["kind"] == "fork" and legs[i]["chosen"] < 0:
			return i
	return -1


func point_at(s: float) -> Vector2:
	if s <= 0.0:
		return route[0]
	var n := cum.size()
	if s >= cum[n - 1]:
		return route[n - 1]
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if cum[mid] <= s:
			lo = mid
		else:
			hi = mid
	var l := cum[hi] - cum[lo]
	return route[lo].lerp(route[hi], (s - cum[lo]) / maxf(l, 0.0001))


## Projeta pos na rota perto do segmento hint. Devolve Vector3(s, seg, dist).
func project(pos: Vector2, hint: int) -> Vector3:
	var best_d := INF
	var best_s := 0.0
	var best_seg := hint
	var a := maxi(0, hint - 3)
	var b := mini(route.size() - 2, hint + 10)
	for i in range(a, b + 1):
		var p0 := route[i]
		var p1 := route[i + 1]
		var seg := p1 - p0
		var l2 := seg.length_squared()
		var t := 0.0
		if l2 > 0.0:
			t = clampf((pos - p0).dot(seg) / l2, 0.0, 1.0)
		var q := p0 + seg * t
		var d := pos.distance_squared_to(q)
		if d < best_d:
			best_d = d
			best_seg = i
			best_s = cum[i] + sqrt(l2) * t
	return Vector3(best_s, best_seg, sqrt(best_d))


func branch_has(leg_i: int, branch: int, types: Array) -> bool:
	for loc in locations:
		if loc["leg"] == leg_i and loc["branch"] == branch and loc["state"] == LocState.ACTIVE and types.has(loc["type"]):
			return true
	return false


## Locais no caminho já escolhido do herói, ativos e ainda à frente.
func is_on_route(loc: Dictionary) -> bool:
	var leg: Dictionary = legs[loc["leg"]]
	return leg["chosen"] == loc["branch"] or (leg["chosen"] < 0 and leg["closed"] != loc["branch"])

class_name PlayerBot
extends RefCounted
## Bot do jogador. A personalidade vem de data/bots/<id>.json. Só emite comandos ao Sim.

var P: Dictionary
var kind := "random"
var rng := RandomNumberGenerator.new()
var next_t := 0.0


static func load_bot(id: String, seed_: int, dir := "res://data/bots") -> PlayerBot:
	var b := PlayerBot.new()
	b.P = GameData._read(dir + "/" + id + ".json")
	b.kind = str(b.P.get("kind", "random"))
	b.rng.seed = seed_ * 7919 + 13
	return b


func think(sim: Sim) -> void:
	if sim.offers.size() > 0:
		sim.choose(_pick_offer(sim))
		return
	if sim.t < next_t:
		return
	next_t = sim.t + float(P.get("think_interval", 0.5))
	if kind == "greedy":
		_greedy(sim)
	else:
		_random(sim)


func _random(sim: Sim) -> void:
	if sim.hand.is_empty():
		return
	var i := rng.randi_range(0, sim.hand.size() - 1)
	var b := sim.can_play(i)
	if b == K.Block.WRONG_PHASE or b == K.Block.CONDITION or b == K.Block.STACK_LIMIT:
		if rng.randf() < float(P.get("sacrifice_unusable", 0.3)):
			sim.sacrifice(i)
		return
	if b != K.Block.OK or rng.randf() > float(P.get("play_chance", 0.6)):
		return
	var c: Sim.CardInst = sim.hand[i]
	var pos := _target(sim, c, true)
	sim.play(i, pos.x, pos.y)
	if sim.phase == K.Phase.ARENA and rng.randf() < 0.1:
		sim.teleport(rng.randi_range(0, sim.arena.altar_pos.size() - 1))


func _greedy(sim: Sim) -> void:
	for _n in 3:
		var best := -1
		var best_v := -1.0
		for i in sim.hand.size():
			var b := sim.can_play(i)
			if b == K.Block.WRONG_PHASE or b == K.Block.STACK_LIMIT:
				if rng.randf() < float(P.get("sacrifice_unusable", 1.0)):
					sim.sacrifice(i)
					return
				continue
			if b != K.Block.OK:
				continue
			var c: Sim.CardInst = sim.hand[i]
			if c.def.id == "soul_feast" and not _feast_ok(sim):
				if sim.elixir >= sim.elixir_max - 1.0:
					sim.sacrifice(i)
					return
				continue
			var v := float(sim.card_cost(c)) + c.def.rarity * 0.5 + c.def.hp * c.def.count * 0.0001
			if v > best_v:
				best_v = v
				best = i
		if best < 0:
			break
		var c2: Sim.CardInst = sim.hand[best]
		var pos := _target(sim, c2, false)
		if sim.play(best, pos.x, pos.y) != K.Block.OK:
			break
	if sim.phase == K.Phase.ARENA:
		var h := Vector2(sim.hero.x, sim.hero.y)
		if h.distance_to(Vector2(sim.arena.bx, sim.arena.by)) < float(P.get("teleport_distance", 4.0)):
			var far := -1
			var fd := 0.0
			for k in sim.arena.altar_pos.size():
				if sim.arena.can_teleport(k):
					var d := h.distance_to(sim.arena.altar_pos[k])
					if d > fd:
						fd = d
						far = k
			if far >= 0:
				sim.teleport(far)


func _feast_ok(sim: Sim) -> bool:
	var U := sim.units
	var n := 0
	for i in U.hi:
		if U.alive[i] == 1 and U.arch[i] != K.Arch.STRUCTURE and U.hp[i] < U.max_hp[i] * 0.5:
			if Vector2(U.px[i] - sim.hero.x, U.py[i] - sim.hero.y).length() < 4.0:
				n += 1
	return n >= 4


func _forward(sim: Sim) -> Vector2:
	var h := Vector2(sim.hero.x, sim.hero.y)
	if sim.phase == K.Phase.ROAD:
		var f := sim.road.point_at(sim.hero.s + 12.0) - h
		if f.length() > 0.1:
			return f.normalized()
	elif sim.phase == K.Phase.ARENA:
		return (Vector2(sim.arena.bx, sim.arena.by) - h).normalized()
	return Vector2(sim.hero.face_x, sim.hero.face_y)


func _target(sim: Sim, c: Sim.CardInst, randomize: bool) -> Vector2:
	var h := Vector2(sim.hero.x, sim.hero.y)
	var d := c.def
	var ring: Dictionary = sim.R["ring"]
	if d.category == "field":
		if d.is_spell:
			if d.id == "shadow_bolt":
				return h - _forward(sim) * 3.0
			return h
		if randomize:
			var a := rng.randf() * TAU
			return h + Vector2(cos(a), sin(a)) * rng.randf_range(float(ring["min"]) + 0.1, float(ring["max"]) - 0.1)
		if sim.phase == K.Phase.ARENA:
			var b := Vector2(sim.arena.bx, sim.arena.by)
			return b + (h - b).normalized() * 3.0
		var dist := float(P.get("place_distance", 6.0))
		return h + _forward(sim).rotated(rng.randf_range(-0.6, 0.6)) * dist
	match d.id:
		"broken_bridge", "false_sign":
			var li := sim.road.next_fork_index()
			if li >= 0:
				var leg: Dictionary = sim.road.legs[li]
				var long := 0 if leg["len"][0] > leg["len"][1] else 1
				var b := (1 - long) if d.id == "broken_bridge" else long
				var pts: PackedVector2Array = leg["pts"][b]
				return pts[pts.size() / 2]
		"gold_bait":
			var U := sim.units
			for i in U.hi:
				if U.alive[i] == 1 and U.def[i] == U.d_mimic:
					return Vector2(U.px[i], U.py[i])
			return sim.road.point_at(sim.hero.s + 15.0)
		"burn_village":
			for loc in sim.road.locations:
				if loc["type"] == "village" and loc["state"] == SimRoad.LocState.ACTIVE and not loc["entered"] and sim.road.is_on_route(loc):
					return loc["pos"]
	return h


func _pick_offer(sim: Sim) -> int:
	var opts: Array = sim.offers[0]["options"]
	if kind != "greedy":
		return rng.randi_range(0, opts.size() - 1)
	var best := 0
	var bv := -INF
	for k in opts.size():
		var o: Dictionary = opts[k]
		var v := 1.0
		match str(o["kind"]):
			"card":
				var c: CardDef = sim.data.card(o["id"])
				v = c.cost + c.rarity * 2.0
				if c.category == "finisher":
					v -= 2.0
			"mod":
				v = 3.0
		if v > bv:
			bv = v
			best = k
	return best

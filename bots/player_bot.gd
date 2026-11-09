class_name PlayerBot
extends RefCounted
## Bot do jogador. A personalidade vem de data/bots/<id>.json. Só emite comandos ao Sim.

## O jogo não tem mais alcance máximo; o bot aleatório continua soltando perto do herói (o antigo anel de 12 m) para não mudar o balanceamento.
const RANDOM_PLACE_MAX := 11.9

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
		if not sim.choose(_pick_offer(sim)):
			sim.choose(Sim.SKIP)
		return
	if sim.route_wait:
		sim.choose_route(_pick_route(sim))
		return
	if sim.t < next_t:
		return
	next_t = sim.t + float(P.get("think_interval", 0.5))
	if kind == "greedy":
		_greedy(sim)
	elif kind == "smart":
		_smart(sim)
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
				if sim.elixir >= sim.elixir_max - 1.0 and sim.sacrifice_ready():
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


# ---------------------------------------------------------------- perfil "smart" (Heurístico, Economista, Enxame)

func _shrine_ahead(sim: Sim) -> Dictionary:
	var look := float(P.get("shrine_lookahead", 0.0))
	if look <= 0.0:
		return {}
	var h := Vector2(sim.hero.x, sim.hero.y)
	for loc in sim.road.locations:
		if loc["type"] == "shrine" and loc["state"] == SimRoad.LocState.ACTIVE and sim.road.is_on_route(loc):
			if loc["entered"] or h.distance_to(loc["pos"]) < look:
				return loc
	return {}


func _smart_value(sim: Sim, c: Sim.CardInst) -> float:
	var d := c.def
	var cost := sim.card_cost(c)
	if d.category == "field" and cost > int(P.get("max_cost", 10)):
		return -1.0
	var v := float(cost) + d.rarity * 0.5
	var h := sim.hero
	match d.category:
		"lair":
			if sim.t < float(P.get("lair_until", 0)):
				v += float(P.get("lair_bonus", 0.0))
			else:
				v -= 2.0
		"route":
			v -= 1.0
		"finisher":
			v += 6.0
	var combo := float(P.get("combo", 0.0))
	if d.id == "goblin_dynamiter" and (h.slow_t > 0.0 or h.soaked_t > 0.0 or h.root_t > 0.0):
		v += combo
	if (d.id == "web" or d.id == "boiling_oil") and sim.elixir >= cost + 3:
		for o in sim.hand:
			if o and o.def.id == "goblin_dynamiter":
				v += combo * 0.7
	if d.id == "shadow_bolt" and h.shield_hp > 0.0:
		v += 1.0
	if d.id == "soul_feast" and not _feast_ok(sim):
		return -1.0
	if d.id == "gold_bait":
		var mimic := false
		for i in sim.units.hi:
			if sim.units.alive[i] == 1 and sim.units.def[i] == sim.units.d_mimic:
				mimic = true
		if not mimic:
			return -1.0
		v += combo
	return v


func _smart(sim: Sim) -> void:
	var shrine := _shrine_ahead(sim)
	var counting: bool = shrine.size() > 0 and shrine["entered"]
	if shrine.size() > 0 and not counting and sim.elixir < float(P.get("shrine_reserve", 0)):
		return
	# Disputas de dano (Taverna, Ponte, Loja): guarda elixir até o herói entrar, depois gasta tudo ali.
	# Fonte e Ritual: monstros de guarda perto do local.
	var contest := _contest_ahead(sim)
	var ctype := str(contest.get("type", ""))
	var guard := {}
	# Ponte e Fonte (rodada 09/11/2026): dano ou controle numa janela curta; guarda elixir até ela abrir.
	if ctype in ["bridge", "fountain"] and not contest["entered"] and sim.elixir < float(P.get("contest_reserve", 6)):
		return
	# Ritual (mortes no círculo), Santuário (monstros no círculo) e Taverna (casas): monstros no local.
	if ctype in ["ritual", "tavern"]:
		var gd := Vector2(sim.hero.x, sim.hero.y).distance_to(contest["pos"])
		if gd <= 18.0 or contest["entered"]:
			guard = contest
	if not counting and shrine.is_empty() and guard.size() > 0:
		shrine = guard
		counting = true
	for _n in 3:
		var best := -1
		var best_v := 0.0
		for i in sim.hand.size():
			var b := sim.can_play(i)
			if b == K.Block.WRONG_PHASE or b == K.Block.STACK_LIMIT:
				if sim.elixir < sim.elixir_max - 0.5 or sim.phase == K.Phase.ARENA:
					sim.sacrifice(i)
					return
				continue
			# Carta que este perfil nunca joga (cara demais) só trava a mão: vira elixir.
			var hc: Sim.CardInst = sim.hand[i]
			if hc.def.category == "field" and sim.card_cost(hc) > int(P.get("max_cost", 10)):
				if sim.elixir < sim.elixir_max - 0.5 and sim.sacrifice_ready():
					sim.sacrifice(i)
					return
				continue
			if b != K.Block.OK:
				continue
			var v := _smart_value(sim, sim.hand[i])
			if v > best_v:
				best_v = v
				best = i
		if best < 0:
			break
		var c: Sim.CardInst = sim.hand[best]
		var pos := _smart_target(sim, c, shrine if counting else {})
		if sim.play(best, pos.x, pos.y) != K.Block.OK:
			break
	if sim.phase == K.Phase.ARENA:
		_smart_arena(sim)


func _smart_target(sim: Sim, c: Sim.CardInst, shrine: Dictionary) -> Vector2:
	var d := c.def
	var h := Vector2(sim.hero.x, sim.hero.y)
	if d.category != "field" or d.is_spell:
		return _target(sim, c, false)
	if sim.phase == K.Phase.ARENA:
		var b := Vector2(sim.arena.bx, sim.arena.by)
		return b + (h - b).normalized() * 3.5
	if shrine.size() > 0:
		var sp: Vector2 = shrine["pos"]
		var v := sp - h
		if v.length() < 3.5:
			v = (v if v.length() > 0.1 else Vector2(1, 0)).normalized() * 4.0
		return h + v
	var face := Vector2(sim.hero.face_x, sim.hero.face_y)
	var fwd := _forward(sim)
	var behind := float(P.get("behind", 0.0))
	match d.arch:
		K.Arch.TANK:
			return h + fwd * 5.0
		K.Arch.STRUCTURE:
			return h + fwd.rotated(rng.randf_range(-0.5, 0.5)) * 9.0
		K.Arch.SHOOTER:
			return h + (-face).rotated(rng.randf_range(-1.0, 1.0)) * 8.0
	# Corpo a corpo: atrás do escudo frontal.
	var dir := fwd.lerp(-face, behind).normalized()
	if dir.length() < 0.1:
		dir = -face
	return h + dir.rotated(rng.randf_range(-0.6, 0.6)) * 4.5


func _smart_arena(sim: Sim) -> void:
	var A := sim.arena
	var h := Vector2(sim.hero.x, sim.hero.y)
	if h.distance_to(Vector2(A.bx, A.by)) < float(P.get("teleport_distance", 3.5)):
		var far := -1
		var fd := 0.0
		for k in A.altar_pos.size():
			if A.can_teleport(k):
				var d := h.distance_to(A.altar_pos[k])
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
			return h + Vector2(cos(a), sin(a)) * rng.randf_range(float(ring["min"]) + 0.1, RANDOM_PLACE_MAX)
		if sim.phase == K.Phase.ARENA:
			var b := Vector2(sim.arena.bx, sim.arena.by)
			return b + (h - b).normalized() * 3.0
		var dist := float(P.get("place_distance", 6.0))
		return h + _forward(sim).rotated(rng.randf_range(-0.6, 0.6)) * dist
	match d.id:
		"gold_bait":
			var U := sim.units
			for i in U.hi:
				if U.alive[i] == 1 and U.def[i] == U.d_mimic:
					return Vector2(U.px[i], U.py[i])
			return sim.road.point_at(sim.hero.s + 15.0)
		"burn_village":
			# O local à frente mais próximo do herói (o fogo pega quando ele chega).
			var best := -1
			var bd := INF
			for li in sim._burn_targets():
				var dd := h.distance_to(sim.road.locations[li]["pos"])
				if dd < bd:
					bd = dd
					best = li
			if best >= 0:
				return sim.road.locations[best]["pos"]
	return h


# ---------------------------------------------------------------- rota

## Ramo na bifurcação: o aleatório e o guloso sorteiam; o "smart" soma o valor dos locais do melhor caminho.
func _pick_route(sim: Sim) -> int:
	var road := sim.road
	var outs: Array = road.nodes[road.head]["out"]
	if outs.is_empty():
		return -1
	if kind != "smart":
		return road.legs[outs[rng.randi_range(0, outs.size() - 1)]]["b"]
	var memo := {}
	var best := -1
	var bv := -INF
	for e in outs:
		var b: int = road.legs[e]["b"]
		var v := _path_value(sim, b, memo) + rng.randf() * 0.01
		if v > bv:
			bv = v
			best = b
	return best


## Valor do melhor caminho a partir do nó n até o covil (memorizado).
func _path_value(sim: Sim, n: int, memo: Dictionary) -> float:
	if memo.has(n):
		return memo[n]
	var road := sim.road
	var v := 0.0
	var li: int = road.nodes[n]["loc"]
	if li >= 0:
		v = _loc_value(sim, str(road.locations[li]["type"]))
	var nxt := 0.0
	var first := true
	for e in road.nodes[n]["out"]:
		var x := _path_value(sim, road.legs[e]["b"], memo)
		if first or x > nxt:
			nxt = x
			first = false
	memo[n] = v + nxt
	return v + nxt


func _loc_value(sim: Sim, ty: String) -> float:
	match ty:
		"shrine":
			return float(P.get("route_shrine", 5.0))
		"ritual":
			return float(P.get("route_ritual", 4.0))
		"shop":
			return float(P.get("route_shop", 3.5)) + sim.gold / 150.0
		"fountain":
			# Remover carta vale mais com o deck grande.
			return 2.5 + maxf(0.0, sim.cards.size() - float(P.get("deck_target", 12))) * 0.5
	return 3.0


## Próximo local de disputa à frente no caminho do herói, a até `contest_lookahead` m (ou {}).
func _contest_ahead(sim: Sim) -> Dictionary:
	var look := float(P.get("contest_lookahead", 30.0))
	if look <= 0.0 or sim.phase != K.Phase.ROAD:
		return {}
	var h := Vector2(sim.hero.x, sim.hero.y)
	var best := {}
	var bd := look
	for loc in sim.road.locations:
		if loc["state"] != SimRoad.LocState.ACTIVE or loc["type"] in ["shrine", "shop", "event"] or not sim.road.is_on_route(loc):
			continue
		var d := h.distance_to(loc["pos"]) - float(loc["r"])
		if loc["entered"]:
			d = 0.0
		if d < bd:
			bd = d
			best = loc
	return best


func _pick_offer(sim: Sim) -> int:
	var of: Dictionary = sim.offers[0]
	var opts: Array = of["options"]
	if of["source"] == "shop":
		return _pick_buy(sim, opts)
	if of["source"] == "event" and opts.size() > 0 and opts[0]["kind"] == "event_opt":
		return _pick_event(sim, opts)
	if kind == "random":
		return rng.randi_range(0, opts.size() - 1)
	var best := 0
	var bv := -INF
	for k in opts.size():
		var v := _opt_value(sim, opts[k])
		if v > bv:
			bv = v
			best = k
	# A escolha da carta de um item já comprado nunca é recusada (senão a loja oferece o item de novo).
	if bv < float(P.get("skip_below", 2.5)) and not of["source"] in ["shop_pick", "relic"]:
		return Sim.SKIP
	return best


## Loja: compra o item que mais vale pelo preço (o ouro tem valor de reserva); nada que valha → sai.
func _pick_buy(sim: Sim, opts: Array) -> int:
	var can: Array = []
	for k in opts.size():
		if sim.can_afford(opts[k]):
			can.append(k)
	if can.is_empty():
		return Sim.SKIP
	if kind == "random":
		return can[rng.randi_range(0, can.size() - 1)] if rng.randf() < 0.7 else Sim.SKIP
	var best := Sim.SKIP
	var bv := float(P.get("skip_below", 2.5))
	for k in can:
		var o: Dictionary = opts[k]
		var item: Dictionary = o["item"]
		var v := _opt_value(sim, item) - float(o["price"]) / float(P.get("gold_value", 30.0))
		if v > bv:
			bv = v
			best = k
	return best


## Valor de uma opção de oferta para este perfil.
func _opt_value(sim: Sim, o: Dictionary) -> float:
	# Deck grande dilui a mão: acima do alvo, carta nova vale menos (e uma oferta fraca é recusada).
	var excess := maxf(0.0, sim.cards.size() - float(P.get("deck_target", 12)))
	var v := 1.0
	match str(o["kind"]):
		"card":
			var c: CardDef = sim.data.card(o["id"])
			v = c.cost + c.rarity * 2.0
			if c.category == "finisher":
				v -= 2.0 if kind == "greedy" else 2.0 - 3.0 * float(P.get("finisher_pick", 0.0)) * (1.0 if _count(sim, "finisher") < 2 else -1.0)
			if c.category == "lair":
				v += float(P.get("lair_bonus", 0.0)) * 0.5
			if c.category == "field" and sim.card_cost(_tmp_inst(c)) > int(P.get("max_cost", 10)):
				v -= 10.0
			v -= excess
		"mod":
			v = 3.0
		"upgrade":
			# Sobe a carta que mais pesa; o especial do N3 vale um pouco mais.
			var c: CardDef = sim.data.card(o["card"])
			v = 4.0 + c.cost * 0.5 + c.rarity
			if int(o["level"]) + 1 >= 3 and c.n3.size() > 0:
				v += 1.5
		"remove":
			# Tira a carta que menos vale (barata, comum, sem nível).
			var c: CardDef = sim.data.card(o["card"])
			v = 9.0 - c.cost - c.rarity * 2.0 - int(o.get("level", 1)) * 2.0
		"pick":
			v = {"upgrade": 6.0, "card": 5.0 - excess, "remove": 4.0 + excess}.get(str(o["what"]), 1.0)
		"relic":
			v = 3.0 + float(sim.data.relics[o["id"]].get("bot_value", 2.0)) * float(P.get("relic_weight", 1.0))
		"transform":
			var c: CardDef = sim.data.card(o["card"])
			v = 8.0 - c.cost - c.rarity * 2.0
		"copy":
			var c: CardDef = sim.data.card(o["card"])
			v = c.cost + c.rarity * 2.0 - excess
	return v


## Evento de texto: soma um valor grosseiro das ações de cada opção; a que pede ouro que falta não conta.
func _pick_event(sim: Sim, opts: Array) -> int:
	if kind == "random":
		var ok: Array = []
		for k in opts.size():
			if sim.event_option_ok(opts[k]):
				ok.append(k)
		return ok[rng.randi_range(0, ok.size() - 1)] if ok.size() > 0 else Sim.SKIP
	var best := Sim.SKIP
	var bv := -INF
	for k in opts.size():
		if not sim.event_option_ok(opts[k]):
			continue
		var o: Dictionary = sim.data.events_def[opts[k]["event"]]["options"][int(opts[k]["opt"])]
		var v := _acts_value(sim, o["do"]) * (1.0 + float(P.get("event_risk", 0.0)) * rng.randf_range(-0.3, 0.3))
		if v > bv:
			bv = v
			best = k
	return best


func _acts_value(sim: Sim, acts: Array) -> float:
	var v := 0.0
	for a in acts:
		match str(a["kind"]):
			"gold":
				v += float(a["amount"]) / float(P.get("gold_value", 30.0))
			"card":
				v += 4.0 + (1.5 if a.has("min_rarity") else 0.0)
			"upgrade":
				v += 5.0 * maxf(1.0, float(a.get("n", 1)) if a.get("give", false) else 1.0)
			"relic":
				v += 6.0
			"remove", "mod", "transform":
				v += 3.0
			"copy":
				v += 2.0
			"boss_hp":
				v += (1.0 - float(a["mult"])) * 20.0
			"hero_curse":
				v += float(a["n"])
			"hero_heal":
				v -= float(a["frac"]) * 15.0
			"next_hero_hp":
				v += (1.0 - float(a["mult"])) * 25.0
			"next_hero_ability":
				v -= 3.0
			"chance":
				v += float(a["p"]) * _acts_value(sim, a.get("then", [])) + (1.0 - float(a["p"])) * _acts_value(sim, a.get("else", []))
	return v


func _count(sim: Sim, cat: String) -> int:
	var n := 0
	for ci in sim.cards:
		if ci.def.category == cat:
			n += 1
	return n


func _tmp_inst(c: CardDef) -> Sim.CardInst:
	var ci := Sim.CardInst.new()
	ci.def = c
	return ci

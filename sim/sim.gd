class_name Sim
extends RefCounted
## Simulação completa de uma run. Lógica pura, passo fixo, determinística pela semente.
## Entrada só por comandos (play, sacrifice, choose, teleport); saída: estado + eventos + stats.

class CardInst:
	var def: CardDef
	var mods := 0
	var uid := 0

	func has_mod(m: int) -> bool:
		return (mods & m) != 0


var data: GameData
var R: Dictionary
var rng := RandomNumberGenerator.new()
var run_seed := 0
var dt := 0.05
var tick := 0
var t := 0.0
var ai_period := 4
var phase: int = K.Phase.ROAD
var result: int = K.Result.NONE
var units := SimUnits.new()
var hero := SimHero.new()
var road := SimRoad.new()
var arena := SimArena.new()
var zones: Array = []
var events: Array = []
var record_events := false
var pause_on_offer := true

var deck_id := ""
var deck_rules: Dictionary = {}
var elixir := 0.0
var elixir_max := 10.0
var hand: Array = []
var queue: Array = []
var cards: Array = []
var card_of_uid: Dictionary = {}
var hand_size := 5
var next_uid := 1
var player_level := 1
var player_xp := 0.0
var offers: Array = []
var lair: Dictionary = {}
var contract: Dictionary = {}
var contract_next := 0.0
var last_teleport_t := -100.0
var ritual_mult := 1.0
var bridge_active := false
var dead_by_def := PackedInt32Array()
var stats: Dictionary = {}
var tmp := PackedInt32Array()


func setup(d: GameData, seed_: int, deck: String) -> void:
	data = d
	R = d.rules
	run_seed = seed_
	rng.seed = seed_
	dt = R["sim"]["dt"]
	ai_period = maxi(1, int(round(1.0 / dt / float(R["sim"]["danger_hz"]))))
	road.generate(rng, R)
	units.setup(self, int(R["sim"]["max_units"]))
	hero.setup(self)
	var dk := d.deck(deck)
	deck_id = dk["id"]
	deck_rules = dk["rules"]
	hand_size = int(deck_rules.get("hand_size", R["hand_size"]))
	elixir = float(deck_rules.get("elixir_start", R["elixir"]["start"]))
	elixir_max = R["elixir"]["max"]
	dead_by_def.resize(d.cards.size())
	stats = {"seed": run_seed, "deck": deck_id, "result": "none", "t_end": 0.0, "arena_t": -1.0,
		"hero_level_arena": 0, "player_level_arena": 0, "hero_level": 1, "player_level": 1,
		"waste_s": 0.0, "offered": {}, "picked": {}, "played": {}, "dmg_by_card": {}, "deck_final": [],
		"upgrades": [], "shrines_won": 0, "shrines_lost": 0, "contracts_ok": 0, "contracts_fail": 0,
		"parts_lost": 0, "kills": 0, "units_peak": 0, "teleports": 0, "sacrifices": 0, "shield_breaks": 0,
		"route_len": 0.0, "hero_hp_arena": 0.0}
	var list: Array = dk["cards"].duplicate()
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmpc = list[i]
		list[i] = list[j]
		list[j] = tmpc
	for id in list:
		queue.append(_new_inst(d.card(id)))
	for i in hand_size:
		hand.append(queue.pop_front() if queue.size() > 0 else null)
	var fa: Array = R["contracts"]["first_at"]
	contract_next = rng.randf_range(fa[0], fa[1])


func _new_inst(c: CardDef) -> CardInst:
	var ci := CardInst.new()
	ci.def = c
	ci.uid = next_uid
	next_uid += 1
	cards.append(ci)
	card_of_uid[ci.uid] = c.id
	return ci


func emit(k: int, x: float, y: float, v: float, e: int) -> void:
	if record_events:
		events.append([k, x, y, v, e])


# ================================================================ passo

func step() -> void:
	if phase == K.Phase.OVER:
		return
	if pause_on_offer and offers.size() > 0:
		return
	tick += 1
	t += dt
	_elixir()
	hero.update(dt)
	if tick % 4 == 0:
		units.apply_auras()
	units.update(dt)
	if tick % 2 == 0:
		units.separate()
	if units.count > stats["units_peak"]:
		stats["units_peak"] = units.count
	_zones()
	if phase == K.Phase.ROAD:
		_road()
	elif phase == K.Phase.ARENA:
		arena.update(dt)
	_contract()
	_check_end()


func _elixir() -> void:
	var rate := 1.0 / float(R["elixir"]["seconds_per_point"])
	var col: CardDef = data.card("soul_collector")
	rate *= 1.0 + float(col.fx["elixir_regen"]) * int(lair.get("soul_collector", 0))
	rate *= ritual_mult
	if phase == K.Phase.ARENA and arena.part_alive("head"):
		rate *= float(R["arena"]["elixir_mult_head"])
	elixir += rate * dt
	if elixir >= elixir_max:
		elixir = elixir_max
		stats["waste_s"] += dt


func _road() -> void:
	var dd: float = R["road"]["fork_decision_distance"]
	if not road.complete and hero.s >= road.length() - dd:
		var leg := road.pending_leg()
		var b := 0
		if leg["kind"] == "fork":
			b = hero.choose_branch(road.next_leg)
		road.advance(b)
	if road.complete and hero.s >= road.length() - 1.5:
		enter_arena()
		return
	ritual_mult = 1.0
	bridge_active = false
	hero.leash_mult = 1.0
	var L: Dictionary = R["locations"]
	var hp_ := Vector2(hero.x, hero.y)
	for li in road.locations.size():
		var loc: Dictionary = road.locations[li]
		if loc["state"] != SimRoad.LocState.ACTIVE:
			continue
		var ty: String = loc["type"]
		var inside: bool = hp_.distance_to(loc["pos"]) <= loc["r"] and road.is_on_route(loc)
		if ty == "shrine" and loc["entered"]:
			loc["t"] -= dt
			if loc["t"] <= 0.0:
				var p: Vector2 = loc["pos"]
				if _own_units_near(p.x, p.y, loc["r"]):
					loc["state"] = SimRoad.LocState.WON
					stats["shrines_won"] += 1
					_offer_shrine()
					emit(K.Ev.SHRINE, p.x, p.y, 1, li)
				else:
					loc["state"] = SimRoad.LocState.DESTROYED
					stats["shrines_lost"] += 1
					hero_gain_xp(float(L["shrine"]["hero_xp"]))
					emit(K.Ev.SHRINE, p.x, p.y, 0, li)
			continue
		if not inside:
			if loc["entered"] and ty in ["village", "bridge"]:
				loc["state"] = SimRoad.LocState.USED
			continue
		var first: bool = not loc["entered"]
		loc["entered"] = true
		if first:
			emit(K.Ev.LOCATION, hero.x, hero.y, li, 0)
		match ty:
			"village":
				var V: Dictionary = L["village"]
				if hero.hp < hero.max_hp() and loc["t"] < float(V["heal_seconds"]):
					if not units.any_within(hero.x, hero.y, V["interrupt_radius"]):
						hero.stay_t = 0.2
						loc["t"] += dt
						hero.heal(hero.max_hp() * float(V["heal_per_s"]) * dt)
				else:
					loc["state"] = SimRoad.LocState.USED
			"tavern":
				hero.tavern_t = L["tavern"]["duration"]
				loc["state"] = SimRoad.LocState.USED
			"fountain":
				hero.heal(hero.max_hp() * float(L["fountain"]["heal"]))
				loc["state"] = SimRoad.LocState.USED
			"ritual":
				ritual_mult = L["ritual"]["elixir_mult"]
				if contract.size() > 0 and contract["goal"]["kind"] == "ritual_time":
					contract["progress"] += dt
			"shrine":
				loc["t"] = L["shrine"]["countdown"]
			"bridge":
				bridge_active = true
				hero.leash_mult = float(L["bridge"]["leash"]) / float(R["road"]["leash"])


func _own_units_near(x: float, y: float, r: float) -> bool:
	return units.any_within(x, y, r)


func location_destroyed(li: int) -> void:
	var loc: Dictionary = road.locations[li]
	loc["state"] = SimRoad.LocState.DESTROYED
	var p: Vector2 = loc["pos"]
	emit(K.Ev.PART_DESTROYED, p.x, p.y, -2, li)


func enter_arena() -> void:
	phase = K.Phase.ARENA
	stats["arena_t"] = t
	stats["hero_level_arena"] = hero.level
	stats["player_level_arena"] = player_level
	stats["route_len"] = road.length()
	var A: Dictionary = R["arena"]
	var dir := road.lair_dir
	var gate := Vector2(hero.x, hero.y)
	var center := gate + dir * (float(A["radius"]) - 1.5)
	arena.setup(self, center, dir)
	# Monstros vivos perto do herói entram junto; o resto fica para trás.
	for i in units.hi:
		if units.alive[i] == 0:
			continue
		var v := Vector2(units.px[i] - gate.x, units.py[i] - gate.y)
		if v.length() > 25.0 or units.arch[i] == K.Arch.STRUCTURE:
			kill_unit(i, K.Death.EXPIRE)
			continue
		var p := gate + dir * 3.0 + v.limit_length(10.0)
		units.px[i] = p.x
		units.py[i] = p.y
		units.ox[i] = p.x
		units.oy[i] = p.y
	zones.clear()
	var walls: CardDef = data.card("lair_walls")
	var n := int(lair.get("lair_walls", 0))
	if n > 0:
		hero.hp = maxf(1.0, hero.hp - hero.max_hp() * float(walls.fx["hero_hp_loss"]) * n)
	hero.target_kind = SimHero.TGT_NONE
	stats["hero_hp_arena"] = hero.hp_frac()
	emit(K.Ev.ARENA, center.x, center.y, 0, 0)


func core_destroyed() -> void:
	_finish(K.Result.LOSS)


func _check_end() -> void:
	if phase == K.Phase.OVER:
		return
	if hero.hp <= 0.0:
		_finish(K.Result.WIN_EARLY if phase == K.Phase.ROAD else K.Result.WIN)
	elif t >= float(R["sim"]["max_run_seconds"]):
		_finish(K.Result.TIMEOUT)


func _finish(r: int) -> void:
	if phase == K.Phase.OVER:
		return
	result = r
	phase = K.Phase.OVER
	stats["result"] = K.RESULT_NAMES[r]
	stats["t_end"] = t
	stats["hero_level"] = hero.level
	stats["player_level"] = player_level
	stats["upgrades"] = hero.upgrade_order.duplicate()
	stats["waste_frac"] = stats["waste_s"] / maxf(t, 1.0)
	var fin: Array = []
	for c in cards:
		fin.append(c.def.id)
	stats["deck_final"] = fin
	stats["ticks"] = tick


# ================================================================ dano e mortes

func damage_hero(amount: float, sx: float, sy: float, tags: int, kind: int, card_id: String) -> float:
	var real := hero.take_damage(amount, sx, sy, tags, kind)
	if real <= 0.0:
		return 0.0
	emit(K.Ev.DAMAGE_HERO, hero.x, hero.y, real, tags)
	var dbc: Dictionary = stats["dmg_by_card"]
	dbc[card_id] = float(dbc.get(card_id, 0.0)) + real
	player_xp += real
	var P: Dictionary = R["player_xp"]
	while player_xp >= _player_next():
		player_xp -= _player_next()
		player_level += 1
		emit(K.Ev.PLAYER_LEVEL, hero.x, hero.y, player_level, 0)
		_offer_level()
	if contract.size() > 0:
		var g: Dictionary = contract["goal"]
		match str(g["kind"]):
			"tag_damage":
				if tags & int(K.TAG_BY_NAME[g["tag"]]):
					contract["progress"] += real
			"damage_no_xp":
				contract["progress"] += real
			"burst":
				contract["window"].append([t, real])
	return real


func _player_next() -> float:
	var P: Dictionary = R["player_xp"]
	return float(P["first_level"]) * pow(1.0 + float(P["growth"]), player_level - 1)


func unit_hits_hero(i: int) -> void:
	var di := units.def[i]
	var c: CardDef = data.cards[di]
	var amount := units.dmg[i] * (1.0 + units.buff[i])
	if bridge_active and (units.tags[i] & K.TAG_PACK):
		amount *= 1.0 + float(R["locations"]["bridge"]["pack_damage"])
	var kind := 0
	if units.flags[i] & K.F_PROJECTILE:
		kind = SimHero.DMG_PROJECTILE
		emit(K.Ev.SHOT, units.px[i], units.py[i], hero.x, int(hero.y * 100.0))
	damage_hero(amount, units.px[i], units.py[i], units.tags[i], kind, str(card_of_uid.get(units.uid[i], c.id)))
	if di == units.d_ogre:
		hero.knockback(units.px[i], units.py[i], float(c.fx.get("knockback", 4.0)))
	if (units.flags[i] & K.F_CURSED) and units.curse_t[i] <= 0.0:
		hero.add_curse(1)
		units.curse_t[i] = R["curse"]["cursed_mod_cooldown"]


func hero_hits_unit(i: int, dmg: float) -> void:
	if units.alive[i] == 0 or (units.flags[i] & K.F_STONE):
		return
	units.hp[i] -= dmg
	emit(K.Ev.DAMAGE_UNIT, units.px[i], units.py[i], dmg, i)
	if units.hp[i] <= 0.0:
		kill_unit(i, K.Death.HERO)


func kill_unit(i: int, cause: int) -> void:
	if units.alive[i] == 0:
		return
	var di := units.def[i]
	var c: CardDef = data.cards[di]
	var x := units.px[i]
	var y := units.py[i]
	var f := units.flags[i]
	if cause == K.Death.HERO or cause == K.Death.SELF:
		if cause == K.Death.HERO:
			stats["kills"] += 1
		if not (f & K.F_NO_XP):
			hero_gain_xp(units.xp[i])
		if hero.has("soul_absorb"):
			hero.heal(hero.max_hp() * float(hero.upgrades["soul_absorb"]["heal"]))
		if not (f & K.F_REVIVED) and c.id != "spectre":
			dead_by_def[di] += 1
	if cause == K.Death.HERO or cause == K.Death.SELF:
		if f & K.F_EXPLOSIVE:
			var M: Dictionary = data.modifiers["explosive"]["p"]
			if Vector2(hero.x - x, hero.y - y).length() <= float(M["radius"]) + hero.radius:
				damage_hero(M["damage"], x, y, 0, 0, str(card_of_uid.get(units.uid[i], c.id)))
			emit(K.Ev.EXPLOSION, x, y, M["radius"], 0)
	if cause == K.Death.HERO:
		var split: Array = c.fx.get("split", [])
		var g := int(units.gen[i])
		if g < split.size():
			var s: Dictionary = split[g]
			for k in int(s["n"]):
				var a := units.slot[i] + k * PI
				var j := spawn_child(c, x + cos(a) * 0.6, y + sin(a) * 0.6, i)
				if j >= 0:
					units.gen[j] = g + 1
					units.hp[j] = float(s["hp"]) * _forge()
					units.max_hp[j] = units.hp[j]
					units.dmg[j] = float(s["dps"]) * units.atk_int[j]
					units.rad[j] = c.radius * (0.75 if g == 0 else 0.55)
		if c.fx.has("death_spawn"):
			var sd: CardDef = data.card(str(c.fx["death_spawn"]))
			for k in int(c.fx.get("death_spawn_n", 0)):
				var a := TAU * k / float(c.fx["death_spawn_n"])
				spawn_child(sd, x + cos(a) * 1.0, y + sin(a) * 1.0, i)
		if c.arch != K.Arch.STRUCTURE and not (f & K.F_REVIVED):
			if not _golem_absorb(i, x, y):
				_totem_revive(i, x, y)
	emit(K.Ev.DEATH, x, y, di, i)
	units.release(i)


func _golem_absorb(i: int, x: float, y: float) -> bool:
	if units.d_golem < 0:
		return false
	var fx: Dictionary = data.cards[units.d_golem].fx
	var r2: float = pow(float(fx["absorb_radius"]), 2)
	for j in units.hi:
		if units.alive[j] == 1 and j != i and units.def[j] == units.d_golem:
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= r2:
				var cap: float = fx["hp_cap"]
				units.max_hp[j] = minf(cap, units.max_hp[j] + float(fx["absorb_hp"]))
				units.hp[j] = minf(units.max_hp[j], units.hp[j] + float(fx["absorb_hp"]))
				return true
	return false


func _totem_revive(i: int, x: float, y: float) -> void:
	if units.d_totem < 0:
		return
	var fx: Dictionary = data.cards[units.d_totem].fx
	var r2: float = pow(float(fx["radius"]), 2)
	for j in units.hi:
		if units.alive[j] == 1 and units.def[j] == units.d_totem:
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= r2:
				var sk: CardDef = data.card(str(fx["revive"]))
				units.spawn(sk, x, y, 0.0, 0.0, K.F_NO_XP | K.F_REVIVED, units.uid[i], _forge())
				return


func spawn_child(c: CardDef, x: float, y: float, parent: int) -> int:
	var inherit := units.flags[parent] & (K.F_NO_XP | K.F_CURSED | K.F_DEFEND)
	return units.spawn(c, x, y, units.xp[parent], units.cost_share[parent], inherit, units.uid[parent], _forge())


func kamikaze(i: int) -> void:
	var c: CardDef = data.cards[units.def[i]]
	var r: float = c.fx.get("explode_radius", 2.5)
	var x := units.px[i]
	var y := units.py[i]
	if Vector2(hero.x - x, hero.y - y).length() <= r + hero.radius:
		damage_hero(float(c.fx.get("explode_damage", 0)), x, y, units.tags[i], 0, str(card_of_uid.get(units.uid[i], c.id)))
	emit(K.Ev.EXPLOSION, x, y, r, 1)
	kill_unit(i, K.Death.SELF)


func mimic_bite(i: int) -> void:
	var c: CardDef = data.cards[units.def[i]]
	damage_hero(float(c.fx.get("bite", 0)), units.px[i], units.py[i], units.tags[i], SimHero.DMG_PIERCE, c.id)
	hero.add_curse(int(c.fx.get("curses", 0)))
	hero.note("mimic", 120.0)


func hero_fear(x: float, y: float) -> void:
	hero.fear(x, y)
	_cc()
	emit(K.Ev.FEAR, hero.x, hero.y, 0, 0)


func _cc() -> void:
	if contract.size() > 0 and contract["goal"]["kind"] == "cc":
		contract["progress"] += 1


func on_shield_break() -> void:
	stats["shield_breaks"] += 1
	emit(K.Ev.SHIELD_BREAK, hero.x, hero.y, 0, 0)


func hero_gain_xp(v: float) -> void:
	if v <= 0.0:
		return
	hero.xp += v
	if contract.size() > 0 and contract["goal"]["kind"] == "damage_no_xp":
		contract["progress"] = 0.0
	while hero.xp >= hero.xp_needed():
		hero.xp -= hero.xp_needed()
		hero.level_up()
		var opts := _upgrade_options(3)
		if opts.size() > 0:
			hero.apply_upgrade(hero.choose_upgrade(opts))
		emit(K.Ev.HERO_LEVEL, hero.x, hero.y, hero.level, 0)


func _upgrade_options(n: int) -> Array:
	var pool: Array = []
	for u in data.hero["upgrades"]:
		if not hero.has(u["id"]):
			pool.append(u)
	var out: Array = []
	while out.size() < n and pool.size() > 0:
		var tot := 0.0
		for u in pool:
			tot += float(u["weight"])
		var r := rng.randf() * tot
		for k in pool.size():
			r -= float(pool[k]["weight"])
			if r <= 0.0 or k == pool.size() - 1:
				out.append(pool[k]["id"])
				pool.remove_at(k)
				break
	return out


func _forge() -> float:
	var n := int(lair.get("dark_forge", 0))
	if n == 0:
		return 1.0
	return 1.0 + float(data.card("dark_forge").fx["monster_hp"]) * n


# ================================================================ zonas

func _zones() -> void:
	var h := Vector2(hero.x, hero.y)
	var i := zones.size() - 1
	while i >= 0:
		var z: Dictionary = zones[i]
		z["t"] -= dt
		var inside: bool = h.distance_to(Vector2(z["x"], z["y"])) <= float(z["r"]) + hero.radius
		match str(z["kind"]):
			"web":
				if inside:
					hero.slow_t = maxf(hero.slow_t, 0.15)
					hero.note("slow", 2.0)
					if not z["applied"]:
						z["applied"] = true
						_cc()
			"oil":
				if inside:
					hero.soaked_t = z["soaked"]
					damage_hero(float(z["dps"]) * dt, z["x"], z["y"], K.TAG_FIRE, SimHero.DMG_AREA, "boiling_oil")
			"bait":
				if hero.has("treasure_nose"):
					z["t"] = 0.0
				elif h.distance_to(Vector2(z["x"], z["y"])) <= 1.5:
					hero_gain_xp(z["xp"])
					hero.note("bait", 60.0)
					z["t"] = 0.0
			"army":
				if z["t"] <= 0.0:
					for j in z["ids"]:
						if units.alive[j] == 1 and data.cards[units.def[j]].id == "spectre":
							kill_unit(j, K.Death.EXPIRE)
		if z["t"] <= 0.0:
			zones.remove_at(i)
		i -= 1


# ================================================================ cartas

func card_cost(c: CardInst) -> int:
	var d := c.def
	var cost := d.cost
	if c.has_mod(K.M_CHEAP):
		cost = maxi(mini(cost, 1), cost - 1)
	if d.category == "field" and (d.type == "monster" or d.type == "swarm"):
		cost += int(deck_rules.get("monster_cost_add", 0))
	if d.is_spell:
		if units.n_cultists > 0:
			var cf: Dictionary = data.card("cultists").fx
			cost = maxi(int(cf["spell_min_cost"]), cost - int(cf["spell_discount"]))
		if phase == K.Phase.ARENA and not arena.part_alive("left_arm"):
			cost += int(R["arena"]["spell_extra_cost_no_left_arm"])
	return cost


func can_play(hi_: int) -> int:
	if phase == K.Phase.OVER:
		return K.Block.OVER
	if offers.size() > 0:
		return K.Block.OFFER_PENDING
	if hi_ < 0 or hi_ >= hand.size() or hand[hi_] == null:
		return K.Block.BAD_TARGET
	var c: CardInst = hand[hi_]
	var d := c.def
	match d.category:
		"route", "lair":
			if phase != K.Phase.ROAD:
				return K.Block.WRONG_PHASE
			if d.category == "lair" and int(lair.get(d.id, 0)) >= int(d.fx.get("stack", 1)):
				return K.Block.STACK_LIMIT
			if d.id in ["broken_bridge", "false_sign"] and road.next_fork_index() < 0:
				return K.Block.CONDITION
		"finisher":
			if phase != K.Phase.ARENA:
				return K.Block.WRONG_PHASE
			if not finisher_ready(d):
				return K.Block.CONDITION
	if elixir + 0.0001 < card_cost(c):
		return K.Block.NO_ELIXIR
	return K.Block.OK


func finisher_ready(d: CardDef) -> bool:
	var fx := d.fx
	match str(fx.get("cond", "none")):
		"front":
			return arena.hero_in_front(fx["cone"], fx["range"])
		"after_teleport":
			return t - last_teleport_t <= float(fx["window"])
		"hero_low":
			return hero.hp_frac() < float(fx["threshold"])
		"part_destroyed":
			return arena.destroyed >= 1
	return true


## Onde a carta pode ser solta. Devolve true se (x, y) é válido.
func valid_target(c: CardInst, x: float, y: float) -> bool:
	var d := c.def
	if d.category == "field":
		var dist := Vector2(x - hero.x, y - hero.y).length()
		var ring: Dictionary = R["ring"]
		if dist > float(ring["max"]):
			return false
		if d.is_spell and ring["spells_ignore_min"]:
			return true
		if dist >= float(ring["min"]):
			return true
		return phase == K.Phase.ARENA and Vector2(x - arena.bx, y - arena.by).length() <= 6.0
	if d.id == "gold_bait":
		return Vector2(x - hero.x, y - hero.y).length() <= float(d.fx["max_detour"]) + 10.0
	if d.id == "burn_village":
		return _village_near(x, y) >= 0
	return true


func play(hi_: int, x: float, y: float) -> int:
	var b := can_play(hi_)
	if b != K.Block.OK:
		return b
	var c: CardInst = hand[hi_]
	if not valid_target(c, x, y):
		return K.Block.BAD_TARGET
	elixir -= card_cost(c)
	_cycle(hi_)
	var pl: Dictionary = stats["played"]
	pl[c.def.id] = int(pl.get(c.def.id, 0)) + 1
	_apply(c, x, y)
	return K.Block.OK


func _cycle(hi_: int) -> void:
	var c: CardInst = hand[hi_]
	queue.push_back(c)
	if hand.size() > hand_size:
		hand.remove_at(hi_)
	else:
		hand[hi_] = queue.pop_front()


func sacrifice(hi_: int) -> bool:
	if phase == K.Phase.OVER or offers.size() > 0 or hi_ < 0 or hi_ >= hand.size() or hand[hi_] == null:
		return false
	elixir = minf(elixir_max, elixir + float(R["sacrifice_elixir"]))
	_cycle(hi_)
	stats["sacrifices"] += 1
	if contract.size() > 0 and contract["goal"]["kind"] == "sacrifice":
		contract["progress"] += 1
	emit(K.Ev.SPELL, hero.x, hero.y, -1, 0)
	return true


func _apply(c: CardInst, x: float, y: float) -> void:
	var d := c.def
	var fx := d.fx
	var smult := float(deck_rules.get("spell_damage_mult", 1.0))
	emit(K.Ev.SPELL, x, y, d.idx, 0)
	if d.is_unit:
		var n := d.count + (1 if c.has_mod(K.M_VETERAN) else 0)
		var xpv := float(d.cost) * float(R["hero_xp"]["per_elixir"]) / d.xp_parts * float(deck_rules.get("hero_xp_mult", 1.0))
		var f := 0
		if c.has_mod(K.M_SHADOWY):
			f |= K.F_NO_XP
		if c.has_mod(K.M_EXPLOSIVE):
			f |= K.F_EXPLOSIVE
		if c.has_mod(K.M_CURSED):
			f |= K.F_CURSED
		if phase == K.Phase.ARENA and Vector2(x - arena.bx, y - arena.by).length() <= 6.0:
			f |= K.F_DEFEND
		for k in n:
			var r := 0.55 * sqrt(float(k))
			var a := k * 2.399963
			units.spawn(d, x + cos(a) * r, y + sin(a) * r, xpv, float(d.cost) / n, f, c.uid, _forge())
		return
	match d.id:
		"shadow_bolt":
			var dir := Vector2(hero.x - x, hero.y - y)
			if dir.length() < 0.1:
				dir = Vector2(hero.face_x, hero.face_y)
			dir = dir.normalized()
			var rel := Vector2(hero.x - x, hero.y - y)
			var along := rel.dot(dir)
			var side := absf(rel.dot(Vector2(-dir.y, dir.x)))
			if along >= -0.5 and along <= float(fx["length"]) and side <= float(fx["width"]) * 0.5 + hero.radius:
				damage_hero(float(fx["damage"]) * smult, x, y, d.tags, SimHero.DMG_PIERCE | SimHero.DMG_SPELL, d.id)
		"web":
			zones.append({"kind": "web", "x": x, "y": y, "r": fx["radius"], "t": fx["duration"], "applied": false})
		"boiling_oil":
			zones.append({"kind": "oil", "x": x, "y": y, "r": fx["radius"], "t": fx["duration"],
				"dps": float(fx["dps"]) * smult, "soaked": fx["soaked"]})
		"soul_feast":
			units.within(x, y, fx["radius"], tmp)
			var refund := 0.0
			var seen := {}
			for j in tmp.duplicate():
				if units.alive[j] == 0 or units.arch[j] == K.Arch.STRUCTURE:
					continue
				refund += units.cost_share[j]
				seen[units.uid[j]] = true
				kill_unit(j, K.Death.SACRIFICE)
			refund += seen.size() * float(fx["bonus_per_card"])
			elixir = minf(elixir_max, elixir + refund)
		"broken_bridge", "false_sign":
			var li := road.next_fork_index()
			if li >= 0:
				var leg: Dictionary = road.legs[li]
				var br := _nearest_branch(leg, x, y)
				if d.id == "broken_bridge":
					leg["closed"] = br
					if leg["forced"] == br:
						leg["forced"] = -1
				else:
					leg["forced"] = br
					if leg["closed"] == br:
						leg["closed"] = -1
		"gold_bait":
			zones.append({"kind": "bait", "x": x, "y": y, "r": 1.0, "t": 40.0, "xp": fx["xp"]})
		"burn_village":
			var vi := _village_near(x, y)
			if vi >= 0:
				road.locations[vi]["state"] = SimRoad.LocState.DESTROYED
		"soul_collector", "dark_forge", "lair_walls":
			lair[d.id] = int(lair.get(d.id, 0)) + 1
		"forbidden_library":
			lair[d.id] = int(lair.get(d.id, 0)) + 1
			hand_size += int(fx["hand"])
			if queue.size() > 0:
				hand.append(queue.pop_front())
		"cosmic_ray":
			if arena.hero_in_front(fx["cone"], float(fx["range"]) + 2.0):
				damage_hero(fx["damage"], arena.bx, arena.by, 0, SimHero.DMG_PIERCE, d.id)
		"bone_prison":
			hero.root_t = fx["root"]
		"petrifying_gaze":
			hero.petrify_t = fx["petrify"]
			hero.shield_hp = 0.0
			hero.shield_t = hero.H["shield"]["regen_seconds"]
			hero.tavern_t = 0.0
		"damned_army":
			_army(fx)
		"dark_fury":
			arena.fury(fx["heal"], fx["duration"])
		"dark_pact":
			if arena.sacrifice_part():
				elixir = elixir_max
				for k in int(fx["draw"]):
					if queue.size() > 0:
						hand.append(queue.pop_front())


func _army(fx: Dictionary) -> void:
	var order: Array = []
	for di in dead_by_def.size():
		if dead_by_def[di] > 0:
			order.append(di)
	order.sort_custom(func(a, b): return data.cards[a].cost > data.cards[b].cost or (data.cards[a].cost == data.cards[b].cost and a < b))
	var sp: CardDef = data.card("spectre")
	var n := 0
	var ids: Array = []
	var mx := int(fx["max"])
	for di in order:
		for k in dead_by_def[di]:
			if n >= mx:
				break
			var a := n * 2.399963
			var r := 4.0 + fmod(n * 0.7, 2.0)
			var j := units.spawn(sp, hero.x + cos(a) * r, hero.y + sin(a) * r, 0.0, 0.0, K.F_NO_XP, 0)
			if j >= 0:
				units.hp[j] = fx["hp"]
				units.max_hp[j] = fx["hp"]
				units.dmg[j] = float(fx["dps"]) * units.atk_int[j]
				ids.append(j)
			n += 1
	zones.append({"kind": "army", "x": hero.x, "y": hero.y, "r": 0.0, "t": fx["duration"], "ids": ids})


func _nearest_branch(leg: Dictionary, x: float, y: float) -> int:
	var best := 0
	var bd := INF
	for b in leg["pts"].size():
		for p in leg["pts"][b]:
			var dd := Vector2(x, y).distance_squared_to(p)
			if dd < bd:
				bd = dd
				best = b
	return best


func _village_near(x: float, y: float) -> int:
	var best := -1
	var bd := 1600.0
	for li in road.locations.size():
		var loc: Dictionary = road.locations[li]
		if loc["type"] == "village" and loc["state"] == SimRoad.LocState.ACTIVE and not loc["entered"]:
			var dd := Vector2(x, y).distance_squared_to(loc["pos"])
			if dd < bd:
				bd = dd
				best = li
	return best


func teleport(k: int) -> bool:
	if phase != K.Phase.ARENA:
		return false
	return arena.teleport(k)


# ================================================================ ofertas

func _roll_rarity() -> int:
	var RT: Dictionary = R["rarity_by_time"]
	var row := 0
	for b in RT["breaks_s"]:
		if t >= float(b):
			row += 1
	var w: Array = RT["weights"][row]
	var r := rng.randf()
	for k in w.size():
		r -= float(w[k])
		if r <= 0.0:
			return k
	return w.size() - 1


func _card_ok(c: CardDef) -> bool:
	if c.category == "lair" and int(lair.get(c.id, 0)) + _deck_count(c.id) >= int(c.fx.get("stack", 1)):
		return false
	return true


func _deck_count(id: String) -> int:
	var n := 0
	for ci in cards:
		if ci.def.id == id:
			n += 1
	return n


func _pick_card(filter: Callable, exclude: Array) -> CardDef:
	var cand: Array = []
	for c in data.pool:
		if filter.call(c) and _card_ok(c) and not exclude.has(c.id):
			cand.append(c)
	if cand.is_empty():
		return null
	return cand[rng.randi_range(0, cand.size() - 1)]


func _mod_option(exclude: Array) -> Dictionary:
	var cand: Array = []
	for ci in cards:
		if ci.def.category != "field":
			continue
		for mid in K.MOD_IDS:
			var m: Dictionary = data.modifiers[mid]
			var ok: bool = m["applies"].has("any") or m["applies"].has(ci.def.type)
			if ok and not ci.has_mod(K.MOD_BY_ID[mid]) and not exclude.has(str(ci.uid) + mid):
				cand.append([ci, mid])
	if cand.is_empty():
		return {}
	var p: Array = cand[rng.randi_range(0, cand.size() - 1)]
	return {"kind": "mod", "uid": p[0].uid, "card": p[0].def.id, "mod": p[1]}


func _push_offer(source: String, opts: Array, extra := {}) -> void:
	if opts.is_empty():
		return
	var of: Dictionary = stats["offered"]
	for o in opts:
		var key := _opt_key(o)
		of[key] = int(of.get(key, 0)) + 1
	var o := {"source": source, "options": opts}
	o.merge(extra)
	offers.append(o)


func _opt_key(o: Dictionary) -> String:
	match str(o["kind"]):
		"card":
			return o["id"]
		"mod":
			return "mod:" + str(o["mod"])
	return "remove"


func _offer_level() -> void:
	var n := int(deck_rules.get("offer_options", R["offers"]["options"]))
	var opts: Array = []
	var ex: Array = []
	var tries := 0
	while opts.size() < n and tries < 20:
		tries += 1
		if rng.randf() < float(R["offers"]["new_card_weight"]):
			var r := _roll_rarity()
			var c: CardDef = null
			for dr in [0, -1, 1, -2, 2, -3, 3]:
				var rr: int = r + dr
				if rr < 0 or rr > 3:
					continue
				c = _pick_card(func(cd: CardDef): return cd.rarity == rr, ex)
				if c:
					break
			if c:
				ex.append(c.id)
				opts.append({"kind": "card", "id": c.id})
		else:
			var m := _mod_option(ex)
			if m.size() > 0:
				ex.append(str(m["uid"]) + str(m["mod"]))
				opts.append(m)
	_push_offer("level", opts)


func _offer_shrine() -> void:
	var opts: Array = []
	var ex: Array = []
	var minr := K.RARITIES.find(str(R["offers"]["shrine_min_rarity"]))
	for k in int(R["offers"]["shrine_options"]):
		var c := _pick_card(func(cd: CardDef): return cd.rarity >= minr, ex)
		if c:
			ex.append(c.id)
			opts.append({"kind": "card", "id": c.id})
	_push_offer("shrine", opts)


func _offer_contract(rw: Dictionary) -> void:
	var n := int(R["offers"]["contract_options"])
	var opts: Array = []
	var ex: Array = []
	var extra := {}
	match str(rw["kind"]):
		"card":
			var minr := K.RARITIES.find(str(rw.get("min_rarity", "common")))
			var tag := int(K.TAG_BY_NAME.get(str(rw.get("tag", "")), 0))
			var cat := str(rw.get("category", ""))
			var f1 := func(cd: CardDef): return (tag == 0 or (cd.tags & tag)) and (cat == "" or cd.category == cat) and cd.rarity >= minr
			var f2 := func(cd: CardDef): return (tag == 0 or (cd.tags & tag)) and (cat == "" or cd.category == cat)
			for k in n:
				var c := _pick_card(f1, ex)
				if c == null:
					c = _pick_card(f2, ex)
				if c:
					ex.append(c.id)
					opts.append({"kind": "card", "id": c.id})
		"modifier":
			for k in n:
				var m := _mod_option(ex)
				if m.size() > 0:
					ex.append(str(m["uid"]) + str(m["mod"]))
					opts.append(m)
		"remove":
			var pool := cards.duplicate()
			for k in n:
				if pool.size() <= 1:
					break
				var ci: CardInst = pool[rng.randi_range(0, pool.size() - 1)]
				pool.erase(ci)
				opts.append({"kind": "remove", "uid": ci.uid, "card": ci.def.id})
			extra = {"elixir": rw.get("elixir", 0)}
	_push_offer("contract", opts, extra)


func choose(k: int) -> bool:
	if offers.is_empty():
		return false
	var o: Dictionary = offers[0]
	var opts: Array = o["options"]
	if k < 0 or k >= opts.size():
		return false
	var op: Dictionary = opts[k]
	var pk: Dictionary = stats["picked"]
	var key := _opt_key(op)
	pk[key] = int(pk.get(key, 0)) + 1
	match str(op["kind"]):
		"card":
			var ci := _new_inst(data.card(op["id"]))
			queue.push_front(ci)
			_refill()
		"mod":
			for ci in cards:
				if ci.uid == op["uid"]:
					ci.mods |= int(K.MOD_BY_ID[op["mod"]])
		"remove":
			_remove_uid(op["uid"])
	if o.has("elixir"):
		elixir = minf(elixir_max, elixir + float(o["elixir"]))
	offers.pop_front()
	return true


func _refill() -> void:
	for i in hand.size():
		if hand[i] == null and queue.size() > 0:
			hand[i] = queue.pop_front()


func _remove_uid(u: int) -> void:
	for ci in cards.duplicate():
		if ci.uid == u:
			cards.erase(ci)
			queue.erase(ci)
			var hi_ := hand.find(ci)
			if hi_ >= 0:
				hand[hi_] = queue.pop_front() if queue.size() > 0 else null


# ================================================================ contratos

func _contract() -> void:
	if contract.is_empty():
		if t >= contract_next and phase == K.Phase.ROAD:
			var cand: Array = []
			var ritual_ahead := false
			for loc in road.locations:
				if loc["type"] == "ritual" and loc["state"] == SimRoad.LocState.ACTIVE and road.is_on_route(loc) and not loc["entered"]:
					ritual_ahead = true
			for c in data.contracts:
				if c["goal"]["kind"] != "ritual_time" or ritual_ahead:
					cand.append(c)
			var c: Dictionary = cand[rng.randi_range(0, cand.size() - 1)]
			var dl := float(c["deadline"])
			if dl < 0.0:
				dl = 120.0
			contract = {"id": c["id"], "goal": c["goal"], "reward": c["reward"], "t": dl, "deadline": dl,
				"progress": 0.0, "window": []}
			emit(K.Ev.CONTRACT, hero.x, hero.y, 0, 0)
		return
	var g: Dictionary = contract["goal"]
	match str(g["kind"]):
		"alive_tag":
			contract["progress"] = maxf(contract["progress"], units.n_pack)
		"structures":
			contract["progress"] = maxf(contract["progress"], units.n_struct)
		"burst":
			var w: Array = contract["window"]
			while w.size() > 0 and t - float(w[0][0]) > float(g["window"]):
				w.pop_front()
			var s := 0.0
			for e in w:
				s += float(e[1])
			contract["progress"] = maxf(contract["progress"], s)
	if float(contract["progress"]) >= float(g["amount"]):
		stats["contracts_ok"] += 1
		emit(K.Ev.CONTRACT, hero.x, hero.y, 1, 0)
		var rw: Dictionary = contract["reward"]
		contract = {}
		_schedule_contract()
		_offer_contract(rw)
		return
	contract["t"] -= dt
	if contract["t"] <= 0.0 or phase != K.Phase.ROAD:
		stats["contracts_fail"] += 1
		emit(K.Ev.CONTRACT, hero.x, hero.y, -1, 0)
		contract = {}
		_schedule_contract()


func _schedule_contract() -> void:
	var iv: Array = R["contracts"]["interval"]
	contract_next = t + rng.randf_range(iv[0], iv[1])


# ================================================================ consultas

func hand_card(i: int) -> CardInst:
	if i < 0 or i >= hand.size():
		return null
	return hand[i]


## Hash do estado, para o teste de determinismo.
func state_hash() -> int:
	var h := hash([tick, hero.x, hero.y, hero.hp, hero.level, elixir, player_level, units.count])
	for i in units.hi:
		if units.alive[i] == 1:
			h = hash([h, units.px[i], units.py[i], units.hp[i]])
	return h

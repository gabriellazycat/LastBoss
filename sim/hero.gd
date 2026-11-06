class_name SimHero
extends RefCounted
## O Escudeiro: atributos, IA por pontuação (rota, movimento, perigo, alvo, upgrades) e escudo frontal.

const DMG_PIERCE := 1     # ignora o escudo
const DMG_SPELL := 2
const DMG_PROJECTILE := 4
const DMG_AREA := 8       # vem de cima / do chão: o escudo não cobre
const TGT_NONE := 0
const TGT_UNIT := 1
const TGT_LOC := 2
const TGT_PART := 3
const TGT_ALTAR := 4
const TGT_PILLAR := 5

var sim: Sim
var H: Dictionary
var AI: Dictionary
var x := 0.0
var y := 0.0
var ox := 0.0
var oy := 0.0
var face_x := 0.0
var face_y := -1.0
var radius := 0.6
var level := 1
var xp := 0.0
var hp := 0.0
var base_hp := 0.0
var curses := 0
var shield_hp := 0.0
var shield_max := 0.0
var shield_cos := 0.0
var shield_t := 0.0
var atk_t := 0.0
var upgrades: Dictionary = {}
var upgrade_order: Array = []
var slow_t := 0.0
var fear_t := 0.0
var fear_x := 0.0
var fear_y := 0.0
var root_t := 0.0
var petrify_t := 0.0
var soaked_t := 0.0
var tavern_t := 0.0
var stay_t := 0.0
var kb_x := 0.0
var kb_y := 0.0
var kb_t := 0.0
var s := 0.0
var seg := 0
var road_dist := 0.0
var target := -1
var target_kind := TGT_NONE
var attacking := false
var near_count := 0
var lure_on := false
var lure_x := 0.0
var lure_y := 0.0
var spin_t := 0.0
var dash_t := 0.0
var dash_left := 0.0
var dash_x := 0.0
var dash_y := 0.0
var cry_t := 0.0
var strike_t := 0.0
var reflect_t := 0.0
var second_used := false
var taken: Dictionary = {}
var taken_total := 0.0
var leash_mult := 1.0
var last_hit_t := -100.0
var last_absorbed := 0.0
var danger := PackedFloat32Array()
var dn := 16
var dcell := 2.0
var d_x0 := 0.0
var d_y0 := 0.0
var tmp := PackedInt32Array()


func setup(s_: Sim) -> void:
	sim = s_
	H = sim.data.hero
	AI = H["ai"]
	base_hp = H["hp"]
	hp = base_hp
	radius = H["radius"]
	shield_max = H["shield"]["hp"]
	shield_hp = shield_max
	shield_cos = cos(deg_to_rad(float(H["shield"]["cone"]) * 0.5))
	dn = int(AI["danger_size"])
	dcell = AI["danger_cell"]
	danger.resize(dn * dn)
	var p: Vector2 = sim.road.route[0]
	x = p.x
	y = p.y
	ox = x
	oy = y


func has(id: String) -> bool:
	return upgrades.has(id)


func max_hp() -> float:
	var R: Dictionary = sim.data.rules["curse"]
	return base_hp * (1.0 - curses * float(R["hp_per_stack"]))


func damage() -> float:
	return float(H["damage"]) * pow(1.0 + float(H["damage_growth"]), level - 1)


func xp_needed() -> float:
	var X: Dictionary = sim.data.rules["hero_xp"]
	return float(X["level2"]) * pow(1.0 + float(X["growth"]), level - 1)


func hp_frac() -> float:
	return hp / max_hp()


# ---------------------------------------------------------------- tick

func update(dt: float) -> void:
	ox = x
	oy = y
	slow_t = maxf(0.0, slow_t - dt)
	fear_t = maxf(0.0, fear_t - dt)
	root_t = maxf(0.0, root_t - dt)
	petrify_t = maxf(0.0, petrify_t - dt)
	soaked_t = maxf(0.0, soaked_t - dt)
	tavern_t = maxf(0.0, tavern_t - dt)
	stay_t = maxf(0.0, stay_t - dt)
	spin_t -= dt
	dash_t -= dt
	cry_t -= dt
	strike_t -= dt
	reflect_t -= dt
	if shield_hp <= 0.0:
		shield_t -= dt
		if shield_t <= 0.0:
			shield_hp = shield_max
	if sim.tick % sim.ai_period == 0:
		_rebuild_danger()
		_choose_target()
	_validate_target()
	_move(dt)
	if sim.phase == K.Phase.ROAD:
		var pr := sim.road.project(Vector2(x, y), seg)
		s = pr.x
		seg = int(pr.y)
		road_dist = pr.z
		var leash: float = float(sim.data.rules["road"]["leash"]) * leash_mult
		if target_kind == TGT_UNIT and leash_mult >= 1.0:
			var tp := _target_pos()
			var tr := sim.road.project(tp, seg)
			leash = clampf(tr.z + 2.0, leash, 18.0)
		if road_dist > leash:
			var q := sim.road.point_at(s)
			var k := (road_dist - leash) / road_dist
			x += (q.x - x) * k
			y += (q.y - y) * k
	else:
		var ar := sim.arena
		var v := Vector2(x - ar.cx, y - ar.cy)
		var lim: float = float(sim.data.rules["arena"]["radius"]) - radius
		if v.length() > lim:
			v = v.normalized() * lim
			x = ar.cx + v.x
			y = ar.cy + v.y
	_attack(dt)
	_abilities()


func _move(dt: float) -> void:
	attacking = false
	if petrify_t > 0.0 or root_t > 0.0:
		return
	var speed: float = H["speed"]
	if slow_t > 0.0:
		var sl: float = sim.data.rules["status"]["slow"]
		if has("steady_boots"):
			sl *= float(upgrades["steady_boots"]["slow_mult"])
		speed *= 1.0 - sl
	var mv := Vector2.ZERO
	if kb_t > 0.0:
		kb_t -= dt
		x += kb_x * dt
		y += kb_y * dt
		return
	if dash_left > 0.0:
		var st := minf(dash_left, 25.0 * dt)
		dash_left -= st
		x += dash_x * st
		y += dash_y * st
		return
	if fear_t > 0.0:
		mv = Vector2(fear_x, fear_y)
		x += mv.x * speed * dt
		y += mv.y * speed * dt
		return
	var tpos := _target_pos()
	var reach := attack_reach()
	var tdist := INF
	if target_kind != TGT_NONE:
		tdist = Vector2(x, y).distance_to(tpos)
		if tdist <= reach:
			attacking = true
	# Seguir a estrada (ou, na arena, ir até o chefe).
	var road_dir := Vector2.ZERO
	if sim.phase == K.Phase.ROAD:
		if stay_t <= 0.0:
			road_dir = (sim.road.point_at(s + 5.0) - Vector2(x, y)).normalized()
	else:
		road_dir = (Vector2(sim.arena.bx, sim.arena.by) - Vector2(x, y)).normalized()
	mv += road_dir * float(AI["road_weight"]) * (0.25 if attacking else 1.0)
	if target_kind != TGT_NONE and not attacking:
		mv += (tpos - Vector2(x, y)).normalized() * float(AI["target_weight"])
	if lure_on:
		mv += (Vector2(lure_x, lure_y) - Vector2(x, y)).normalized() * 2.2
	# Fugir do perigo: gradiente do mapa.
	var cx := int((x - d_x0) / dcell)
	var cy := int((y - d_y0) / dcell)
	if cx > 0 and cy > 0 and cx < dn - 1 and cy < dn - 1:
		var here := danger[cy * dn + cx]
		if here > 0.5:
			var g := Vector2(danger[cy * dn + cx + 1] - danger[cy * dn + cx - 1], danger[(cy + 1) * dn + cx] - danger[(cy - 1) * dn + cx])
			if g.length() > 0.01:
				var k := clampf(here / 60.0, 0.0, 1.0) * (1.5 if hp_frac() < float(AI["low_hp"]) else 0.5) / float(AI["aggression"])
				mv -= g.normalized() * float(AI["flee_weight"]) * k
	if mv.length() > 0.01:
		mv = mv.normalized()
		var sp := speed * (float(H["attack_move_mult"]) if attacking else 1.0)
		x += mv.x * sp * dt
		y += mv.y * sp * dt
	# Encarar o alvo (o escudo fica na frente) ou a direção do movimento.
	var f := Vector2.ZERO
	if target_kind != TGT_NONE and tdist < 6.0:
		f = tpos - Vector2(x, y)
	elif mv.length() > 0.01:
		f = mv
	if f.length() > 0.01:
		f = Vector2(face_x, face_y).lerp(f.normalized(), 0.35).normalized()
		face_x = f.x
		face_y = f.y


func attack_reach() -> float:
	var r: float = H["attack_range"] + radius * 0.5
	match target_kind:
		TGT_UNIT:
			if target >= 0:
				r += sim.units.rad[target]
		TGT_LOC:
			r += 1.5
		TGT_PART:
			r += 0.9
		TGT_ALTAR:
			r += 0.8
		TGT_PILLAR:
			r += sim.arena.pillar_r
	return r


func _target_pos() -> Vector2:
	match target_kind:
		TGT_UNIT:
			return Vector2(sim.units.px[target], sim.units.py[target])
		TGT_LOC:
			return sim.road.locations[target]["pos"]
		TGT_PART:
			return sim.arena.part_pos(target)
		TGT_ALTAR:
			return sim.arena.altar_pos[target]
		TGT_PILLAR:
			return sim.arena.pillar_pos[target]
	return Vector2(x, y)


func _validate_target() -> void:
	match target_kind:
		TGT_UNIT:
			if target < 0 or sim.units.alive[target] == 0 or (sim.units.flags[target] & K.F_STONE):
				target_kind = TGT_NONE
		TGT_LOC:
			if sim.road.locations[target]["state"] != SimRoad.LocState.ACTIVE:
				target_kind = TGT_NONE
		TGT_PART:
			if not sim.arena.part_attackable(target):
				target_kind = TGT_NONE
		TGT_ALTAR:
			if not sim.arena.altar_alive[target]:
				target_kind = TGT_NONE
		TGT_PILLAR:
			if not sim.arena.pillar_alive(target):
				target_kind = TGT_NONE


func _attack(dt: float) -> void:
	if petrify_t > 0.0 or target_kind == TGT_NONE:
		return
	var m := 1.0
	if tavern_t > 0.0:
		m += float(sim.data.rules["locations"]["tavern"]["attack_speed"])
	if slow_t > 0.0:
		var sl: float = sim.data.rules["status"]["slow"]
		if has("steady_boots"):
			sl *= float(upgrades["steady_boots"]["slow_mult"])
		m *= 1.0 - sl
	if has("hero_fury"):
		var u: Dictionary = upgrades["hero_fury"]
		m *= 1.0 + minf(float(u["cap"]), near_count * float(u["per_unit"]))
	atk_t -= dt * m
	if atk_t > 0.0:
		return
	if Vector2(x, y).distance_to(_target_pos()) > attack_reach():
		atk_t = 0.0
		return
	atk_t = H["attack_interval"]
	var dmg := damage()
	if has("purifying_blade") and curses > 0:
		curses -= 1
	match target_kind:
		TGT_UNIT:
			var tx := sim.units.px[target]
			var ty := sim.units.py[target]
			sim.hero_hits_unit(target, _unit_mult(target, dmg, true))
			_cleave(tx, ty, dmg)
		TGT_LOC:
			var loc: Dictionary = sim.road.locations[target]
			loc["hp"] -= dmg
			if loc["hp"] <= 0.0:
				sim.location_destroyed(target)
		TGT_PART:
			sim.arena.damage_part(target, dmg * _strike(true))
		TGT_ALTAR:
			var m2 := 2.0 if has("stone_hammer") else 1.0
			sim.arena.damage_altar(target, dmg * m2)
		TGT_PILLAR:
			var m3 := 2.0 if has("stone_hammer") else 1.0
			sim.arena.damage_pillar(target, dmg * m3)


## Golpe em arco: atinge também quem está à frente, no alcance.
func _cleave(tx: float, ty: float, dmg: float) -> void:
	var arc: float = H.get("cleave_arc", 0.0)
	if arc <= 0.0:
		return
	var dir := Vector2(tx - x, ty - y).normalized()
	var c := cos(deg_to_rad(arc * 0.5))
	var r: float = H["attack_range"] + radius
	var U := sim.units
	U.within(x, y, r + 0.4, tmp)
	for i in tmp.duplicate():
		if i == target or U.alive[i] == 0 or (U.flags[i] & K.F_STONE):
			continue
		var v := Vector2(U.px[i] - x, U.py[i] - y)
		if v.length() < 0.01 or v.normalized().dot(dir) >= c:
			sim.hero_hits_unit(i, _unit_mult(i, dmg, false))


func _strike(big: bool) -> float:
	if has("heroic_strike") and big and strike_t <= 0.0:
		strike_t = upgrades["heroic_strike"]["interval"]
		return float(upgrades["heroic_strike"]["mult"])
	return 1.0


func _unit_mult(i: int, dmg: float, main_hit: bool) -> float:
	var t := sim.units.tags[i]
	if has("holy_water") and (t & (K.TAG_UNDEAD | K.TAG_SHADOW)):
		dmg *= float(upgrades["holy_water"]["mult"])
	if has("stone_hammer") and (t & K.TAG_CONSTRUCT):
		dmg *= float(upgrades["stone_hammer"]["mult"])
	if main_hit and has("heroic_strike"):
		dmg *= _strike(sim.units.max_hp[i] >= float(upgrades["heroic_strike"]["big_hp"]))
	return dmg


func _abilities() -> void:
	if petrify_t > 0.0:
		return
	var U := sim.units
	if has("sword_spin") and spin_t <= 0.0:
		var p: Dictionary = upgrades["sword_spin"]
		U.within(x, y, float(p["radius"]) + 0.5, tmp)
		if tmp.size() > 0:
			spin_t = p["interval"]
			sim.emit(K.Ev.SPIN, x, y, float(p["radius"]), 0)
			var hit := tmp.duplicate()
			for i in hit:
				if U.alive[i] == 1 and not (U.flags[i] & K.F_STONE):
					sim.hero_hits_unit(i, _unit_mult(i, damage() * float(p["mult"]), false))
	if has("war_cry") and cry_t <= 0.0:
		var p: Dictionary = upgrades["war_cry"]
		U.within(x, y, p["radius"], tmp)
		var small := 0
		for i in tmp:
			if U.max_hp[i] < float(p["max_hp"]) and U.arch[i] != K.Arch.STRUCTURE:
				small += 1
		if small >= 3:
			cry_t = p["cooldown"]
			for i in tmp:
				if U.max_hp[i] < float(p["max_hp"]) and U.arch[i] != K.Arch.STRUCTURE:
					U.fear_t[i] = sim.data.rules["status"]["fear"]
			sim.emit(K.Ev.FEAR, x, y, float(p["radius"]), 1)
	if has("dash") and dash_t <= 0.0 and sim.phase == K.Phase.ROAD:
		var p: Dictionary = upgrades["dash"]
		if near_count >= int(p["surround"]) or slow_t > 0.0:
			dash_t = p["cooldown"]
			var dir := (sim.road.point_at(s + 8.0) - Vector2(x, y)).normalized()
			dash_x = dir.x
			dash_y = dir.y
			dash_left = p["distance"]
			slow_t = 0.0
	if hp > 0.0 and hp < max_hp() and (sim.phase == K.Phase.ROAD or H.get("regen_in_arena", true)):
		var rg: float = H.get("regen_combat", 0.0)
		if near_count == 0 and sim.t - last_hit_t > float(H.get("regen_delay", 3.0)):
			rg = H.get("regen_per_s", 0.0)
		if rg > 0.0:
			hp = minf(max_hp(), hp + max_hp() * rg * sim.dt)
	if has("second_wind") and not second_used:
		var p: Dictionary = upgrades["second_wind"]
		if hp_frac() < float(p["below"]):
			second_used = true
			heal(max_hp() * float(p["heal"]))


# ---------------------------------------------------------------- IA

func _rebuild_danger() -> void:
	danger.fill(0.0)
	d_x0 = x - dn * dcell * 0.5
	d_y0 = y - dn * dcell * 0.5
	var U := sim.units
	near_count = 0
	for i in U.hi:
		if U.alive[i] == 0:
			continue
		var dx := U.px[i] - x
		var dy := U.py[i] - y
		if dx * dx + dy * dy < 16.0:
			near_count += 1
		var cx := int((U.px[i] - d_x0) / dcell)
		var cy := int((U.py[i] - d_y0) / dcell)
		if cx < 1 or cy < 1 or cx >= dn - 1 or cy >= dn - 1:
			continue
		var th := U.dmg[i] / maxf(U.atk_int[i], 0.1)
		if U.arch[i] == K.Arch.KAMIKAZE:
			th += 60.0
		_splat(cx, cy, th)
	for z in sim.zones:
		if z["kind"] == "web" or z["kind"] == "oil":
			var cx := int((z["x"] - d_x0) / dcell)
			var cy := int((z["y"] - d_y0) / dcell)
			if cx >= 1 and cy >= 1 and cx < dn - 1 and cy < dn - 1:
				_splat(cx, cy, 25.0)


func _splat(cx: int, cy: int, v: float) -> void:
	var c := cy * dn + cx
	danger[c] += v
	danger[c - 1] += v * 0.5
	danger[c + 1] += v * 0.5
	danger[c - dn] += v * 0.5
	danger[c + dn] += v * 0.5


func _choose_target() -> void:
	var U := sim.units
	var engage: float = AI["engage_radius"]
	var strat: Dictionary = AI["strategic"]
	var best := -1
	var best_kind := TGT_NONE
	var best_score := -INF
	var arena := sim.phase == K.Phase.ARENA
	var unit_r := 3.0 if arena else engage
	lure_on = false
	var nose := has("treasure_nose")
	var lure_d := INF
	for i in U.hi:
		if U.alive[i] == 0:
			continue
		var dx := U.px[i] - x
		var dy := U.py[i] - y
		var d := sqrt(dx * dx + dy * dy)
		var di := U.def[i]
		if di == U.d_mimic and not nose and not (U.flags[i] & K.F_BITTEN):
			var lr: float = sim.data.cards[di].fx.get("lure_radius", 10.0)
			if d < lr and d < lure_d:
				lure_d = d
				lure_on = true
				lure_x = U.px[i]
				lure_y = U.py[i]
			continue
		if d > unit_r or (U.flags[i] & K.F_STONE) or di == U.d_tower:
			continue
		var th := U.dmg[i] / maxf(U.atk_int[i], 0.1)
		var sc := th * 0.05 + (1.0 - U.hp[i] / U.max_hp[i]) + float(strat.get(sim.data.cards[di].id, 0.0)) - d * 0.35
		if arena:
			sc += 2.0
		if sc > best_score:
			best_score = sc
			best = i
			best_kind = TGT_UNIT
	if not nose:
		for z in sim.zones:
			if z["kind"] == "bait":
				var d := Vector2(x, y).distance_to(Vector2(z["x"], z["y"]))
				if d < lure_d:
					lure_d = d
					lure_on = true
					lure_x = z["x"]
					lure_y = z["y"]
	if not arena:
		for li in sim.road.locations.size():
			var loc: Dictionary = sim.road.locations[li]
			if loc["type"] != "ritual" or loc["state"] != SimRoad.LocState.ACTIVE:
				continue
			var d := Vector2(x, y).distance_to(loc["pos"])
			if d < engage * 1.5:
				var sc := float(strat.get("ritual", 3.0)) - d * 0.2
				if sc > best_score:
					best_score = sc
					best = li
					best_kind = TGT_LOC
	else:
		var ar := sim.arena
		if best_kind == TGT_NONE:
			for k in ar.part_hp.size():
				if not ar.part_attackable(k):
					continue
				var d := Vector2(x, y).distance_to(ar.part_pos(k))
				var sc := float(ar.part_value[k]) * 2.0 + (1.0 - ar.part_hp[k] / ar.part_max[k]) - d * 0.05
				if sc > best_score:
					best_score = sc
					best = k
					best_kind = TGT_PART
			# Pilar no caminho até o chefe: quebrar.
			var to_boss := Vector2(ar.bx - x, ar.by - y).normalized()
			for k in ar.pillar_pos.size():
				if not ar.pillar_alive(k):
					continue
				var pv: Vector2 = ar.pillar_pos[k] - Vector2(x, y)
				if pv.length() < 2.6 and pv.normalized().dot(to_boss) > 0.75:
					var sc := 4.0 - pv.length()
					if sc > best_score:
						best_score = sc
						best = k
						best_kind = TGT_PILLAR
			for k in ar.altar_pos.size():
				if not ar.altar_alive[k] or k == ar.altar:
					continue
				var d := Vector2(x, y).distance_to(ar.altar_pos[k])
				if d < 5.0:
					var sc := float(strat.get("altar", 1.0)) * 3.0 - d * 0.1
					if sc > best_score:
						best_score = sc
						best = k
						best_kind = TGT_ALTAR
	target = best
	target_kind = best_kind


## Ramo numa bifurcação: regra visível (vida baixa → cura; senão → mais curto).
func choose_branch(leg_i: int) -> int:
	var leg: Dictionary = sim.road.legs[leg_i]
	if leg["forced"] >= 0:
		return leg["forced"]
	if leg["closed"] >= 0:
		return 1 - int(leg["closed"])
	if hp_frac() < float(AI["low_hp"]):
		for b in 2:
			if sim.road.branch_has(leg_i, b, ["village", "fountain"]):
				return b
	return 0 if leg["len"][0] <= leg["len"][1] else 1


func choose_upgrade(options: Array) -> String:
	var best := ""
	var best_w := -1.0
	for id in options:
		var w := upgrade_weight(id)
		if w > best_w:
			best_w = w
			best = id
	return best


## Peso do upgrade: peso da classe × resposta ao que mais machucou o herói.
func upgrade_weight(id: String) -> float:
	var u: Dictionary = sim.data.upgrades[id]
	var share := 0.0
	if taken_total > 0.0:
		for c in u["counters"]:
			share += float(taken.get(c, 0.0)) / taken_total
	return float(u["weight"]) * (1.0 + float(AI["upgrade_counter_gain"]) * share)


func apply_upgrade(id: String) -> void:
	var u: Dictionary = sim.data.upgrades[id]
	upgrades[id] = u["p"]
	upgrade_order.append(id)
	if id == "tower_shield":
		shield_max *= float(u["p"]["hp_mult"])
		shield_hp = shield_max
		shield_cos = cos(deg_to_rad(float(u["p"]["cone"]) * 0.5))


func level_up() -> void:
	var before := max_hp()
	level += 1
	base_hp *= 1.0 + float(H["hp_growth"])
	hp += max_hp() - before


# ---------------------------------------------------------------- dano

func note(key: String, v: float) -> void:
	taken[key] = float(taken.get(key, 0.0)) + v
	taken_total += v


## Aplica dano vindo de (sx, sy). Devolve o dano que chegou à vida.
func take_damage(amount: float, sx: float, sy: float, src_tags: int, kind: int) -> float:
	last_absorbed = 0.0
	if amount <= 0.0 or hp <= 0.0:
		return 0.0
	if src_tags & K.TAG_FIRE:
		if soaked_t > 0.0:
			amount *= float(sim.data.rules["fire_vs_soaked"])
		if has("fireproof"):
			amount *= float(upgrades["fireproof"]["fire_mult"])
	if (kind & DMG_SPELL) and has("reflect_shield") and reflect_t <= 0.0:
		reflect_t = upgrades["reflect_shield"]["cooldown"]
		sim.emit(K.Ev.SHIELD_BREAK, x, y, 0.0, 1)
		return 0.0
	var pierce := (kind & (DMG_PIERCE | DMG_AREA)) != 0 or (src_tags & K.TAG_SHADOW) != 0
	if not pierce and shield_hp > 0.0:
		var to := Vector2(sx - x, sy - y)
		if to.length() > 0.01:
			to = to.normalized()
			if to.x * face_x + to.y * face_y >= shield_cos:
				var ab := minf(shield_hp, amount)
				last_absorbed = ab
				shield_hp -= ab
				amount -= ab
				if shield_hp <= 0.0:
					shield_hp = 0.0
					shield_t = H["shield"]["regen_seconds"]
					sim.on_shield_break()
	if amount <= 0.0:
		return 0.0
	amount = minf(amount, hp)
	hp -= amount
	last_hit_t = sim.t
	if src_tags & K.TAG_PACK: note("pack", amount)
	if src_tags & K.TAG_UNDEAD: note("undead", amount)
	if src_tags & K.TAG_SHADOW: note("shadow", amount)
	if src_tags & K.TAG_FIRE: note("fire", amount)
	if src_tags & K.TAG_CONSTRUCT: note("construct", amount)
	if kind & DMG_PROJECTILE: note("projectile", amount)
	if kind & DMG_SPELL: note("spell", amount)
	if amount >= 100.0: note("burst", amount)
	return amount


func heal(v: float) -> void:
	if v <= 0.0:
		return
	var m := max_hp()
	var real := minf(v, m - hp)
	if real > 0.0:
		hp += real
		sim.emit(K.Ev.HEAL, x, y, real, 0)


func add_curse(n: int) -> void:
	var cap: int = sim.data.rules["curse"]["max_stacks"]
	var before := curses
	curses = mini(cap, curses + n)
	if curses > before:
		note("curse", 60.0 * (curses - before))
		hp = minf(hp, max_hp())
		sim.emit(K.Ev.CURSE, x, y, curses, 0)


func knockback(from_x: float, from_y: float, dist: float) -> void:
	if has("steady_boots"):
		return
	var v := Vector2(x - from_x, y - from_y)
	if v.length() < 0.01:
		v = Vector2(-face_x, -face_y)
	v = v.normalized() * dist / 0.25
	kb_x = v.x
	kb_y = v.y
	kb_t = 0.25
	note("knockback", 40.0)


func fear(from_x: float, from_y: float) -> void:
	var v := Vector2(x - from_x, y - from_y)
	if v.length() < 0.01:
		v = Vector2(0, 1)
	v = v.normalized()
	fear_x = v.x
	fear_y = v.y
	fear_t = sim.data.rules["status"]["fear"]

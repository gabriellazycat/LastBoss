class_name CardsDragon
extends RefCounted
## Efeitos das cartas do Dragão (owner "dragon" em data/cards.json) que não cabem nas ops de CardFxLib.
## O Pedágio é declarado em "ops" (pay_gold + elixir).


## Aplica a carta pelo id. Devolve true se tratou.
static func apply(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> bool:
	var d := k.d
	var fx := d.fx
	var lv := k.lv
	var smult := k.smult
	var vet := k.vet
	var curse := k.curse
	match d.id:
		"boiling_oil":
			sim.zones.append({"kind": "oil", "x": x, "y": y, "r": fx["radius"], "t": fx["duration"],
				"dps": d.fxv("dps", lv) * smult * vet, "soaked": fx["soaked"], "curse": curse})
		"gold_bait":
			sim.zones.append({"kind": "bait", "x": x, "y": y, "r": 1.0, "t": 40.0, "xp": 0.0})
		"oil_splash":
			# Sozinho: encharca o herói. Em grupo (10/11/2026): só o herói mais perto do ponto (a até 3 m; nenhum
			# perto = o da vez). Encharcar o grupo todo e incendiar com a Tocha dava 96% de vitória na fase 4.
			var near_w: Array = sim.heroes_near(x, y, float(fx.get("radius", 3.0))) if sim.multi_heroes() else []
			var wet: Array = [near_w[0]] if near_w.size() > 0 else [sim.hero]
			for hh in wet:
				hh.soaked_t = maxf(hh.soaked_t, d.fxv("soaked", lv) * vet)
				hh.add_curse(curse)
		"torch":
			var dmg := d.fxv("damage", lv) * smult * vet
			var near_t := sim.heroes_near(x, y, float(fx["radius"]))
			for i in near_t.size():
				var hh: SimHero = near_t[i]
				var was_soaked: bool = hh.soaked_t > 0.0
				# Em grupo, só o mais perto leva o golpe seco; os outros só pegam fogo se estiverem encharcados
				# (10/11/2026: a Tocha fazia 65% do dano da Ruína na fase 4 como dano de área grátis).
				if i > 0 and not was_soaked:
					continue
				sim.hit_hero = hh if hh != sim.hero else null
				sim.damage_hero(dmg * sim.splash_mult(i), x, y, d.tags, SimHero.DMG_AREA | SimHero.DMG_SPELL, d.id)
				if was_soaked and hh == sim.hero:
					sim.burn_t = maxf(sim.burn_t, float(fx["burn_s"]))
					sim.burn_dps = d.fxv("burn_dps", lv) * smult
					sim.burn_src = d.id
				elif was_soaked:
					# Seguidor encharcado também pega fogo (10/11/2026).
					hh.burn_t = maxf(hh.burn_t, float(fx["burn_s"]))
					hh.burn_dps = d.fxv("burn_dps", lv) * smult * sim.splash_mult(1)
				hh.add_curse(curse)
			sim.hit_hero = null
		"tar_net":
			sim.zones.append({"kind": "web", "x": x, "y": y, "r": fx["radius"], "t": d.fxv("duration", lv) * vet, "applied": false,
				"root": d.fxv("root", lv), "curse": curse, "soak": fx["soaked"]})
		"cursed_coins":
			sim.zones.append({"kind": "coins", "x": x, "y": y, "r": fx["radius"], "t": 30.0, "applied": false,
				"stop": d.fxv("stop", lv) * vet, "curses": int(fx["curses"]) + curse, "gold": d.fxv("gold", lv)})
		"burn_village":
			# Incêndio: marca um local da rota; quando o herói chega, o local pega fogo.
			var bi := burn_near(sim, x, y)
			if bi >= 0:
				var bl: Dictionary = sim.road.locations[bi]
				bl["burn"] = true
				bl["burn_dps"] = d.fxv("dps", lv) * smult * vet
				bl["burn_s"] = float(fx["duration"])
		"spark":
			_spark(sim, k, x, y)
		"molten_gold":
			_molten_gold(sim, k, x, y)
		"blood_tax":
			# O pagamento está em "ops" (pay_gold); aqui só o desconto da próxima carta (card_cost_add / on_card_played).
			_st(sim)["tax"] = int(d.fxv("discount", lv))
		"gold_avalanche":
			_avalanche(sim, k, x, y)
		"eruption":
			_eruption(sim, k, x, y)
		"ember_rain":
			# A zona de fogo vem de "ops"; o óleo no chão dentro do raio também pega fogo.
			_oil_to_fire(sim, x, y, d.fxv("radius", lv), d.fxv("oil_fire_dps", lv) * smult * vet, d.fxv("oil_fire_s", lv), d.id, false)
		_:
			return false
	return true


## Locais que o Incêndio pode marcar: ativos, ainda à frente no caminho do herói e sem fogo marcado.
static func burn_targets(sim: Sim) -> Array:
	var out: Array = []
	for li in sim.road.locations.size():
		var loc: Dictionary = sim.road.locations[li]
		if loc["state"] == SimRoad.LocState.ACTIVE and not loc["entered"] and not loc.get("burn", false) and sim.road.is_on_route(loc):
			out.append(li)
	return out


## Local marcável mais perto do ponto (até 40 m), ou -1.
static func burn_near(sim: Sim, x: float, y: float) -> int:
	var best := -1
	var bd := 1600.0
	for li in burn_targets(sim):
		var dd := Vector2(x, y).distance_squared_to(sim.road.locations[li]["pos"])
		if dd < bd:
			bd = dd
			best = li
	return best


# ================================================================ cartas do C6

static func _st(sim: Sim) -> Dictionary:
	if not sim.cstate.has("dragon"):
		sim.cstate["dragon"] = {"tax": 0, "furn": []}
	return sim.cstate["dragon"]


## Faísca: fogo no herói mais perto; encharcado, pega fogo e o fogo salta para os que estão a até `radius` dele.
static func _spark(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> void:
	var d := k.d
	var dmg := d.fxv("damage", k.lv) * k.smult * k.vet
	var near := sim.heroes_near(x, y, 3.0) if sim.multi_heroes() else []
	var first: SimHero = near[0] if near.size() > 0 else sim.hero
	var wet := first.soaked_t > 0.0
	var targets: Array = [first]
	if wet:
		for hh in sim.heroes_near(first.x, first.y, d.fxv("radius", k.lv)):
			if hh != first:
				targets.append(hh)
	for i in targets.size():
		var hh: SimHero = targets[i]
		sim.hit_hero = hh if hh != sim.hero else null
		sim.damage_hero(dmg * sim.splash_mult(i), x, y, d.tags, SimHero.DMG_AREA | SimHero.DMG_SPELL, d.id)
		if wet:
			var bd := d.fxv("burn_dps", k.lv) * k.smult
			var bs := d.fxv("burn_s", k.lv)
			if hh == sim.hero:
				sim.burn_t = maxf(sim.burn_t, bs)
				sim.burn_dps = bd
				sim.burn_src = d.id
			else:
				hh.burn_t = maxf(hh.burn_t, bs)
				hh.burn_dps = bd * sim.splash_mult(1)
		hh.add_curse(k.curse)
	sim.hit_hero = null


## Ouro Derretido: gasta até `gold_max` de ouro; cada um vira `fire_per_gold` de fogo em área e o herói fica lento.
static func _molten_gold(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> void:
	var d := k.d
	var spend := minf(float(d.fx["gold_max"]), maxf(0.0, sim.gold))
	sim.gold -= spend
	sim.stats["gold_spent"] += int(spend)
	var dmg := spend * d.fxv("fire_per_gold", k.lv) * k.smult * k.vet
	var hs := sim.heroes_near(x, y, float(d.fx["radius"]))
	for i in hs.size():
		var hh: SimHero = hs[i]
		sim.hit_hero = hh if hh != sim.hero else null
		sim.damage_hero(dmg * sim.splash_mult(i), x, y, d.tags, SimHero.DMG_AREA | SimHero.DMG_SPELL, d.id)
		hh.slow_t = maxf(hh.slow_t, float(d.fx["slow"]) * k.vet)
		hh.note("slow", 2.0)
		hh.add_curse(k.curse)
	sim.hit_hero = null
	sim.emit(K.Ev.EXPLOSION, x, y, float(d.fx["radius"]), 0)


## Avalanche de Ouro: dano = mult x ouro (até o teto), sem gastar; os atingidos ficam presos (atordoados).
static func _avalanche(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> void:
	var d := k.d
	var dmg := minf(float(d.fx["cap"]), d.fxv("gold_mult", k.lv) * maxf(0.0, sim.gold)) * k.smult * k.vet
	var hs := sim.heroes_near(x, y, float(d.fx["radius"]))
	for i in hs.size():
		var hh: SimHero = hs[i]
		sim.hit_hero = hh if hh != sim.hero else null
		sim.damage_hero(dmg * sim.splash_mult(i), x, y, d.tags, SimHero.DMG_AREA | SimHero.DMG_SPELL, d.id)
		hh.root_t = maxf(hh.root_t, d.fxv("stun", k.lv) * sim.cc_mult())
		if hh == sim.hero:
			sim._cc()
		hh.add_curse(k.curse)
	sim.hit_hero = null
	sim.emit(K.Ev.EXPLOSION, x, y, float(d.fx["radius"]), 1)


## Óleo no chão dentro do raio vira fogo (dps por s segundos). remove: o óleo some (Erupção).
static func _oil_to_fire(sim: Sim, x: float, y: float, r: float, dps: float, s: float, src: String, remove: bool) -> void:
	var i := sim.zones.size() - 1
	while i >= 0:
		var z: Dictionary = sim.zones[i]
		if z["kind"] == "oil" and Vector2(float(z["x"]) - x, float(z["y"]) - y).length() <= r + float(z["r"]):
			sim.zones.append({"kind": "fire", "x": z["x"], "y": z["y"], "r": z["r"], "t": s, "dps": dps, "src": src, "curse": 0})
			if remove:
				sim.zones.remove_at(i)
		i -= 1


## Erupção: quem está encharcado ou em poça de óleo explode (fogo); o chão queima por fire_s.
static func _eruption(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> void:
	var d := k.d
	var dmg := d.fxv("damage", k.lv) * k.smult * k.vet
	var fdps := d.fxv("fire_dps", k.lv) * k.smult * k.vet
	var fs := d.fxv("fire_s", k.lv) * k.vet
	var hit: Array = []
	for hh in sim.all_heroes():
		var on_oil := false
		for z in sim.zones:
			if z["kind"] == "oil" and Vector2(hh.x - float(z["x"]), hh.y - float(z["y"])).length() <= float(z["r"]) + hh.radius:
				on_oil = true
				break
		if hh.soaked_t > 0.0 or on_oil:
			hit.append(hh)
	for i in hit.size():
		var hh: SimHero = hit[i]
		sim.hit_hero = hh if hh != sim.hero else null
		sim.damage_hero(dmg * sim.splash_mult(i), hh.x, hh.y, d.tags, SimHero.DMG_AREA | SimHero.DMG_SPELL, d.id)
		hh.soaked_t = 0.0
		sim.zones.append({"kind": "fire", "x": hh.x, "y": hh.y, "r": float(d.fx["radius"]), "t": fs, "dps": fdps, "src": d.id, "curse": 0})
		sim.emit(K.Ev.EXPLOSION, hh.x, hh.y, float(d.fx["radius"]), 1)
		hh.add_curse(k.curse)
	sim.hit_hero = null
	_oil_to_fire(sim, x, y, 1.0e6, fdps, fs, d.id, true)


## Maior bônus de fogo das Fornalhas que cobrem o herói.
static func _furnace_bonus(furn: Array, hh: SimHero) -> float:
	var b := 0.0
	for f in furn:
		if Vector2(hh.x - float(f[0]), hh.y - float(f[1])).length() <= float(f[2]) + hh.radius:
			b = maxf(b, float(f[3]))
	return b

# ================================================================ ganchos (C6)
# Chamados pelo Sim para os 4 donos, sempre. Só reaja às suas cartas/unidades (data.cards[sim.units.def[i]].owner) ou
# ao seu vilão (sim.deck_id). Estado próprio em sim.cstate["<dono>"]. Mantenha baratos: rodam a cada passo/golpe.

## A cada passo da simulação (dt = sim.dt).
static func on_tick(sim: Sim) -> void:
	# Fornalha: expira em `duration`; de pé, o herói a até `radius` não seca (e o fogo causa mais, ver
	# hero_damage_bonus). A lista de posições fica em cstate para o gancho de dano não varrer as unidades.
	var fi: int = sim.data.card("furnace").idx
	var furn: Array = []
	var u := sim.units
	for j in u.hi:
		if u.alive[j] == 1 and u.def[j] == fi:
			var c: CardDef = sim.data.cards[fi]
			if u.timer[j] > c.fxv("duration", u.lvl[j], 15.0) * (1.0 + sim.rv("structure")):
				sim.kill_unit(j, K.Death.EXPIRE)
				continue
			furn.append([u.px[j], u.py[j], c.fxv("radius", u.lvl[j], 5.0), c.fxv("fire_bonus", u.lvl[j], 0.3)])
	if furn.is_empty() and not sim.cstate.has("dragon"):
		return
	_st(sim)["furn"] = furn
	for hh in sim.all_heroes():
		if hh.soaked_t > 0.0 and not furn.is_empty() and _furnace_bonus(furn, hh) > 0.0:
			hh.soaked_t += sim.dt


## Multiplicador do golpe da unidade i no herói, antes do dano (1.0 = nada).
static func unit_hit_mult(sim: Sim, i: int) -> float:
	return 1.0


## Depois do golpe da unidade i no herói (real = dano que entrou).
static func on_unit_hit(sim: Sim, i: int, real: float) -> void:
	# Kobolds Catadores: cada golpe que entra rende ouro.
	var c: CardDef = sim.data.cards[sim.units.def[i]]
	if real > 0.0 and c.id == "kobold_scavengers":
		sim._earn_gold(c.fxv("gold_per_hit", sim.units.lvl[i], 1.0) * minf(1.0, sim.units.atk_int[i]))   # golpe rápido rende fração: o ouro por segundo é o de antes


## Bônus somado ao dano que o herói `hh` recebe de qualquer fonte (0.0 = nada; 0.15 = +15%).
static func hero_damage_bonus(sim: Sim, hh: SimHero, tags: int, kind: int) -> float:
	if (tags & K.TAG_FIRE) != 0 and sim.cstate.has("dragon"):
		var furn: Array = sim.cstate["dragon"]["furn"]
		if not furn.is_empty():
			return _furnace_bonus(furn, hh)
	return 0.0


## Unidade i vai morrer (cause = K.Death.*); os dados dela ainda estão em sim.units.
static func on_unit_death(sim: Sim, i: int, cause: int) -> void:
	pass


## Depois de uma carta jogada (já aplicada).
static func on_card_played(sim: Sim, c: Sim.CardInst, x: float, y: float) -> void:
	var st := _st(sim)
	if c.def.id != "blood_tax" and int(st["tax"]) > 0:
		st["tax"] = 0   # o desconto do Imposto de Sangue vale para uma carta só
	match c.def.id:
		"treasure_guard":
			# +hp_per_gold de vida por ouro guardado (até hp_cap), nas unidades que a carta acabou de invocar.
			var add := minf(c.def.fxv("hp_cap", c.level), c.def.fxv("hp_per_gold", c.level) * maxf(0.0, sim.gold))
			for j in sim.units.hi:
				if sim.units.alive[j] == 1 and sim.units.uid[j] == c.uid:
					sim.units.max_hp[j] += add
					sim.units.hp[j] += add
		"elder_dragon":
			# Ao entrar, solta uma Chuva de Brasas no ponto.
			var d := c.def
			sim.zones.append({"kind": "fire", "x": x, "y": y, "r": d.fxv("rain_radius", c.level), "t": d.fxv("rain_s", c.level),
				"dps": d.fxv("rain_dps", c.level), "src": d.id, "curse": 0})


## Multiplicador do golpe do herói nas suas unidades (1.0 = nada; 0.7 = herói causa 30% menos).
static func hero_out_mult(sim: Sim) -> float:
	return 1.0


## Soma ao custo da carta c agora (negativo = desconto). O custo final nunca fica abaixo de 0.
static func card_cost_add(sim: Sim, c: Sim.CardInst) -> int:
	# Imposto de Sangue: a próxima carta (qualquer uma, menos ele mesmo) custa `discount` a menos.
	if c.def.id != "blood_tax" and sim.cstate.has("dragon"):
		return -int(sim.cstate["dragon"]["tax"])
	return 0

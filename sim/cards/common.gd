class_name CardsCommon
extends RefCounted
## Efeitos das cartas comuns a todos os vilões (owner "common" em data/cards.json) que não cabem nas ops de
## CardFxLib. Ogro e Torre de Gárgulas são só unidades (CardFxLib.spawn_card_units).


## Aplica a carta pelo id. Devolve true se tratou.
static func apply(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> bool:
	var d := k.d
	var fx := d.fx
	var lv := k.lv
	var vet := k.vet
	var curse := k.curse
	match d.id:
		"web":
			sim.zones.append({"kind": "web", "x": x, "y": y, "r": fx["radius"], "t": d.fxv("duration", lv) * vet, "applied": false,
				"root": d.fxv("root", lv), "curse": curse})
		"weakness_curse":
			# O herói causa menos dano às suas unidades por um tempo (hero_out_mult).
			var st := _st(sim)
			st["weak_until"] = maxf(float(st["weak_until"]), sim.t + d.fxv("duration", lv) * vet)
			st["weak"] = d.fxv("weak", lv)
			sim.hero.add_curse(curse)
		"dark_sacrifice":
			# Sacrifica o monstro seu (do ponto) que mais devolve; ganha metade do custo dele em elixir.
			var U := sim.units
			var pick := -1
			var best := -1.0
			var pr2 := pow(float(fx["pick_radius"]), 2)
			var bd := 1.0e9
			for j in U.hi:
				if U.alive[j] == 0 or U.arch[j] == K.Arch.STRUCTURE:
					continue
				var d2 := Vector2(U.px[j] - x, U.py[j] - y).length_squared()
				if d2 > pr2:
					continue
				if U.cost_share[j] > best + 0.001 or (absf(U.cost_share[j] - best) <= 0.001 and d2 < bd):
					best = U.cost_share[j]
					bd = d2
					pick = j
			if pick >= 0:
				var refund := minf(d.fxv("refund_cap", lv), U.cost_share[pick] * float(fx["refund_frac"]))
				sim.kill_unit(pick, K.Death.SACRIFICE)
				sim.elixir = minf(sim.elixir_max, sim.elixir + refund)
				sim.hero.add_curse(curse)
		_:
			return false
	return true


# ================================================================ estado das comuns (C6)

## sim.cstate["common"]: weak_until/weak = Maldição da Fraqueza; bn = estandartes vivos [x, y, raio²].
static func _st(sim: Sim) -> Dictionary:
	if not sim.cstate.has("common"):
		sim.cstate["common"] = {"weak_until": -1.0, "weak": 0.0, "bn": [], "stomp": {}}
	return sim.cstate["common"]


## Marca no `flags` da unidade: já recebeu a vida do Estandarte de Guerra.
const F_BANNER := 1 << 24

# ================================================================ ganchos (C6)
# Chamados pelo Sim para os 4 donos, sempre. Só reaja às suas cartas/unidades (data.cards[sim.units.def[i]].owner) ou
# ao seu vilão (sim.deck_id). Estado próprio em sim.cstate["<dono>"]. Mantenha baratos: rodam a cada passo/golpe.

## A cada passo da simulação (dt = sim.dt).
static func on_tick(sim: Sim) -> void:
	var U := sim.units
	var bd: CardDef = sim.data.card("war_banner")
	var td: CardDef = sim.data.card("cave_troll")
	var hld: CardDef = sim.data.card("fallen_healer")
	var spd: CardDef = sim.data.card("spike_trap")
	var has_banner := false
	var has_troll := false
	var has_heal := false
	var has_spike := false
	for i in U.hi:
		if U.alive[i] == 1:
			if U.def[i] == bd.idx:
				has_banner = true
			elif U.def[i] == td.idx:
				has_troll = true
			elif U.def[i] == hld.idx:
				has_heal = true
			elif U.def[i] == spd.idx:
				has_spike = true
	if has_heal:
		_healers(sim, hld)
	if has_spike:
		_spikes(sim, spd)
	if not has_banner and not has_troll and not (sim.cstate.has("common") and sim.cstate["common"]["bn"].size() > 0):
		return
	var st := _st(sim)
	var bn: Array = st["bn"]
	bn.clear()
	if has_banner:
		for i in U.hi:
			if U.alive[i] == 1 and U.def[i] == bd.idx:
				if U.timer[i] > bd.fxv("duration", int(U.lvl[i])):
					sim.kill_unit(i, K.Death.EXPIRE)
				else:
					bn.append([U.px[i], U.py[i], pow(bd.fxv("radius", int(U.lvl[i])), 2), bd.fxv("dmg", int(U.lvl[i]))])
		if bn.size() > 0:
			var hpm := float(bd.fx["hp"])
			for i in U.hi:
				if U.alive[i] == 0 or U.arch[i] == K.Arch.STRUCTURE or (U.flags[i] & F_BANNER):
					continue
				for b in bn:
					if Vector2(U.px[i] - float(b[0]), U.py[i] - float(b[1])).length_squared() <= float(b[2]):
						U.flags[i] |= F_BANNER
						U.max_hp[i] *= 1.0 + hpm
						U.hp[i] *= 1.0 + hpm
						break
	if has_troll:
		for i in U.hi:
			if U.alive[i] == 1 and U.def[i] == td.idx:
				U.hp[i] = minf(U.max_hp[i], U.hp[i] + U.max_hp[i] * float(td.fx["regen"]) * sim.dt)


## Curandeiro Caído: cura por segundo (fração da vida máxima) os aliados a até aura_radius m (não cura estruturas).
static func _healers(sim: Sim, hd: CardDef) -> void:
	var U := sim.units
	for i in U.hi:
		if U.alive[i] == 0 or U.def[i] != hd.idx:
			continue
		var lv := int(U.lvl[i])
		var r2 := pow(hd.fxv("aura_radius", lv, 6.0), 2)
		var rate := hd.fxv("heal", lv) * sim.dt
		for j in U.hi:
			if U.alive[j] == 0 or U.arch[j] == K.Arch.STRUCTURE or U.hp[j] >= U.max_hp[j]:
				continue
			if Vector2(U.px[j] - U.px[i], U.py[j] - U.py[i]).length_squared() <= r2:
				U.hp[j] = minf(U.max_hp[j], U.hp[j] + U.max_hp[j] * rate)


## Armadilha de Espinhos: o herói que pisa leva dano e fica Preso; a armadilha some.
static func _spikes(sim: Sim, sd: CardDef) -> void:
	var U := sim.units
	for i in U.hi:
		if U.alive[i] == 0 or U.def[i] != sd.idx:
			continue
		var lv := int(U.lvl[i])
		for hh: SimHero in sim.all_heroes():
			if hh.hp <= 0.0:
				continue
			if Vector2(hh.x - U.px[i], hh.y - U.py[i]).length() <= hh.radius + U.rad[i] + float(sd.fx.get("trigger", 1.0)):
				sim.hit_hero = hh if hh != sim.hero else null
				sim.damage_hero(sd.fxv("damage", lv), U.px[i], U.py[i], 0, SimHero.DMG_AREA, sd.id)
				sim.hit_hero = null
				hh.root_t = maxf(hh.root_t, sd.fxv("root", lv) * sim.cc_mult())
				if hh == sim.hero:
					sim._cc()
				sim.kill_unit(i, K.Death.EXPIRE)
				break


## Multiplicador do golpe da unidade i no herói, antes do dano (1.0 = nada).
static func unit_hit_mult(sim: Sim, i: int) -> float:
	# Estandarte de Guerra: monstros perto dele causam mais.
	if sim.cstate.has("common"):
		var bn: Array = sim.cstate["common"]["bn"]
		if bn.size() > 0 and sim.units.arch[i] != K.Arch.STRUCTURE:
			for b in bn:
				if Vector2(sim.units.px[i] - float(b[0]), sim.units.py[i] - float(b[1])).length_squared() <= float(b[2]):
					return 1.0 + float(b[3])
	return 1.0


## Depois do golpe da unidade i no herói (real = dano que entrou).
static func on_unit_hit(sim: Sim, i: int, real: float) -> void:
	# Titã da Ruína: o golpe vira um pisão que atordoa os heróis em volta (com recarga).
	var c: CardDef = sim.data.cards[sim.units.def[i]]
	if not c.fx.has("stomp_radius"):
		return
	var U := sim.units
	var stomp: Dictionary = _st(sim)["stomp"]
	var key := str(i)
	var last := float(stomp.get(key, -1000.0))
	if last > U.timer[i]:
		last = -1000.0   # índice reaproveitado por outra unidade
	if U.timer[i] - last < float(c.fx["stomp_cd"]):
		return
	stomp[key] = U.timer[i]
	var stun := c.fxv("stomp_stun", int(U.lvl[i])) * sim.cc_mult()
	for hh in sim.heroes_near(U.px[i], U.py[i], float(c.fx["stomp_radius"])):
		hh.petrify_t = maxf(hh.petrify_t, stun)
	sim.emit(K.Ev.EXPLOSION, U.px[i], U.py[i], float(c.fx["stomp_radius"]), 0)


## Bônus somado ao dano que o herói `hh` recebe de qualquer fonte (0.0 = nada; 0.15 = +15%).
static func hero_damage_bonus(sim: Sim, hh: SimHero, tags: int, kind: int) -> float:
	return 0.0


## Unidade i vai morrer (cause = K.Death.*); os dados dela ainda estão em sim.units.
static func on_unit_death(sim: Sim, i: int, cause: int) -> void:
	pass


## Depois de uma carta jogada (já aplicada).
static func on_card_played(sim: Sim, c: Sim.CardInst, x: float, y: float) -> void:
	pass


## Multiplicador do golpe do herói nas suas unidades (1.0 = nada; 0.7 = herói causa 30% menos).
static func hero_out_mult(sim: Sim) -> float:
	# Maldição da Fraqueza: o herói causa menos dano.
	if sim.cstate.has("common"):
		var st: Dictionary = sim.cstate["common"]
		if sim.t < float(st["weak_until"]):
			return 1.0 - float(st["weak"])
	return 1.0


## Soma ao custo da carta c agora (negativo = desconto). O custo final nunca fica abaixo de 0.
static func card_cost_add(sim: Sim, c: Sim.CardInst) -> int:
	return 0

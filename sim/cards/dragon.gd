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
			var near_w: Array = sim.heroes_near(x, y, float(fx.get("radius", 3.0))) if sim.group_mode() else []
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

# ================================================================ ganchos (C6)
# Chamados pelo Sim para os 4 donos, sempre. Só reaja às suas cartas/unidades (data.cards[sim.units.def[i]].owner) ou
# ao seu vilão (sim.deck_id). Estado próprio em sim.cstate["<dono>"]. Mantenha baratos: rodam a cada passo/golpe.

## A cada passo da simulação (dt = sim.dt).
static func on_tick(sim: Sim) -> void:
	pass


## Multiplicador do golpe da unidade i no herói, antes do dano (1.0 = nada).
static func unit_hit_mult(sim: Sim, i: int) -> float:
	return 1.0


## Depois do golpe da unidade i no herói (real = dano que entrou).
static func on_unit_hit(sim: Sim, i: int, real: float) -> void:
	pass


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
	return 1.0


## Soma ao custo da carta c agora (negativo = desconto). O custo final nunca fica abaixo de 0.
static func card_cost_add(sim: Sim, c: Sim.CardInst) -> int:
	return 0

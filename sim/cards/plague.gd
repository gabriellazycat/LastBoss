class_name CardsPlague
extends RefCounted
## Efeitos das cartas da Praga (owner "plague" em data/cards.json e data/cards_plague.json) que não cabem nas ops de
## CardFxLib. Ratos, Ninho de Morcegos, Rei dos Ratos, Lobisomem, Gosma, Horda, Maré de Ratos, Nuvem de Morcegos,
## Matilha, Javali e Besta Alfa são só unidades (CardFxLib.spawn_card_units); o Chamado do Bando e a Besta Alfa
## (Chamado ao entrar) são declarados em "ops" (buff "rally").
##
## Estado (sim.cstate["plague"], só tipos simples; criado quando a primeira carta da Praga é jogada):
##   peste     {pidx do herói (texto): [acúmulos, segundo da última mordida]}
##   cfg       [máximo de acúmulos, dano a mais por acúmulo, segundos até sumir]   (lidos da Ratazana, em fx)
##   bite_*    Mordida Infectada: até quando, onde, raio, acúmulos a mais
##   bubo_*    Praga Bubônica: até quando e dano por acúmulo no fim
##   hunt_*    Instinto de Caça: até quando, velocidade e roubo de vida das Feras
##   nest_*    Ninho-Mãe: até quando, onde e raio; seen = timer2 visto de cada ninho (para dobrar a produção)
##   endless_t Enxame Sem Fim: até quando o Bando renasce

## Feras que já existiam em data/cards.json (sem o campo fx.beast).
const OLD_BEASTS := []   # Lobisomem e Gosma já têm fx.beast em cards.json


static func is_beast(c: CardDef) -> bool:
	return bool(c.fx.get("beast", false)) or OLD_BEASTS.has(c.id)


static func _st(sim: Sim) -> Dictionary:
	if not sim.cstate.has("plague"):
		var cf: Dictionary = sim.data.card("rat_brute").fx
		sim.cstate["plague"] = {"peste": {}, "seen": {},
			"cfg": [float(cf.get("peste_max", 15.0)), float(cf.get("peste_taken", 0.03)), float(cf.get("peste_secs", 8.0))]}
	return sim.cstate["plague"]


# ================================================================ Peste

## Acúmulos de Peste no herói hh.
static func peste_of(sim: Sim, hh: SimHero) -> int:
	return int(floorf(peste_f(sim, hh) + 0.001))


## Acúmulos fracionados: golpes rápidos (intervalo < 1 s) rendem fração de acúmulo, para o ritmo por segundo não mudar.
static func peste_f(sim: Sim, hh: SimHero) -> float:
	if not sim.cstate.has("plague"):
		return 0.0
	var pe: Dictionary = sim.cstate["plague"]["peste"]
	if not pe.has(str(hh.pidx)):
		return 0.0
	return float(pe[str(hh.pidx)][0])


static func add_peste(sim: Sim, hh: SimHero, n: float) -> void:
	var st := _st(sim)
	var key := str(hh.pidx)
	var e: Array = st["peste"].get(key, [0.0, 0.0])
	e[0] = minf(float(st["cfg"][0]), float(e[0]) + n)
	e[1] = sim.t
	st["peste"][key] = e


## Aplica a carta pelo id. Devolve true se tratou.
static func apply(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> bool:
	var d := k.d
	var lv := k.lv
	match d.id:
		"infected_bite":
			var st := _st(sim)
			st["bite_t"] = sim.t + d.fxv("duration", lv) * k.vet
			st["bite_x"] = x
			st["bite_y"] = y
			st["bite_r"] = d.fxv("radius", lv)
			st["bite_n"] = int(d.fxv("extra", lv))
		"hunt_instinct":
			var st := _st(sim)
			st["hunt_t"] = sim.t + d.fxv("duration", lv) * k.vet
			st["hunt_speed"] = d.fxv("speed", lv)
			st["hunt_steal"] = d.fxv("steal", lv)
		"bubonic_plague":
			var st := _st(sim)
			st["bubo_t"] = sim.t + d.fxv("duration", lv) * k.vet
			st["bubo_dmg"] = d.fxv("per_stack", lv) * k.smult * k.vet
		"mother_nest":
			var st := _st(sim)
			st["nest_t"] = sim.t + d.fxv("duration", lv) * k.vet
			st["nest_x"] = x
			st["nest_y"] = y
			st["nest_r"] = d.fxv("radius", lv)
		"endless_swarm":
			var st := _st(sim)
			st["endless_t"] = sim.t + d.fxv("duration", lv) * k.vet   # os 12 ratos vêm das ops
		"devour":
			_devour(sim, k, x, y)
		_:
			return false
	return true


## Devorar: sacrifica ratos seus (os mais perto da fera); a fera mais próxima cura e bate mais forte até morrer.
## Com menos ratos que o pedido, o efeito é proporcional; sem rato ou sem fera, nada acontece.
static func _devour(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> void:
	var U := sim.units
	var beast := -1
	var bd := INF
	for i in U.hi:
		if U.alive[i] == 1 and is_beast(sim.data.cards[U.def[i]]):
			var dd := Vector2(U.px[i] - x, U.py[i] - y).length_squared()
			if dd < bd:
				bd = dd
				beast = i
	if beast < 0:
		return
	var rats: Array = []
	for i in U.hi:
		if U.alive[i] == 1 and (U.tags[i] & K.TAG_PACK) and U.arch[i] == K.Arch.SWARM and not (U.flags[i] & K.F_FLY):
			rats.append([Vector2(U.px[i] - U.px[beast], U.py[i] - U.py[beast]).length_squared(), i])
	rats.sort()
	var need := maxi(1, int(k.d.fxv("sacrifice", k.lv)))
	var n := mini(need, rats.size())
	for r in n:
		sim.kill_unit(int(rats[r][1]), K.Death.SACRIFICE)
	if n == 0:
		return
	var frac := float(n) / float(need)
	U.hp[beast] = minf(U.max_hp[beast], U.hp[beast] + k.d.fxv("heal", k.lv) * frac)
	U.dmg[beast] *= 1.0 + k.d.fxv("dmg_bonus", k.lv) * frac
	U.flags[beast] |= K.F_DEVOURED

# ================================================================ ganchos (C6)
# Chamados pelo Sim para os 4 donos, sempre. Só reaja às suas cartas/unidades (data.cards[sim.units.def[i]].owner) ou
# ao seu vilão (sim.deck_id). Estado próprio em sim.cstate["<dono>"]. Mantenha baratos: rodam a cada passo/golpe.

## A cada passo da simulação (dt = sim.dt).
static func on_tick(sim: Sim) -> void:
	if not sim.cstate.has("plague"):
		return
	var st: Dictionary = sim.cstate["plague"]
	var pe: Dictionary = st["peste"]
	if not pe.is_empty():
		var secs: float = st["cfg"][2]
		for key in pe.keys():
			if sim.t - float(pe[key][1]) >= secs:
				pe.erase(key)
	if st.has("bubo_t") and sim.t >= float(st["bubo_t"]):
		st.erase("bubo_t")
		_bubo_end(sim, float(st["bubo_dmg"]))
	if sim.tick % 2 != 0 or sim.units.count == 0:
		return
	_units_pass(sim, st, 2.0 * sim.dt)


## Praga Bubônica: no fim, dano por acúmulo de Peste em cada herói.
static func _bubo_end(sim: Sim, per: float) -> void:
	for hh: SimHero in sim.all_heroes():
		var s := peste_of(sim, hh)
		if s > 0:
			sim.hit_hero = hh if hh != sim.hero else null
			sim.damage_hero(per * s, hh.x, hh.y, 0, SimHero.DMG_AREA | SimHero.DMG_SPELL, "bubonic_plague")
	sim.hit_hero = null


## A cada 2 passos: produção da Mãe da Ninhada, ninhos dobrados, Ratoeira, Flautista e velocidade das Feras.
static func _units_pass(sim: Sim, st: Dictionary, dt2: float) -> void:
	var U := sim.units
	var D := sim.data
	var heroes: Array = sim.all_heroes()
	var rat: CardDef = D.card("rat")
	var hunting: bool = sim.t < float(st.get("hunt_t", -1.0))
	var beast_mult := 1.0 + (float(st["hunt_speed"]) if hunting else 0.0)
	var nest_on: bool = sim.t < float(st.get("nest_t", -1.0))
	if not nest_on and not st["seen"].is_empty():
		st["seen"].clear()
	var pipers: Array = []
	for i in U.hi:
		if U.alive[i] == 0:
			continue
		var c: CardDef = D.cards[U.def[i]]
		if U.arch[i] == K.Arch.STRUCTURE and nest_on and c.fx.has("spawn"):
			_double_nest(sim, st, i, c)
		if c.owner != "plague":
			continue
		if c.fx.has("beast") or OLD_BEASTS.has(c.id):
			var want := c.speed * beast_mult
			if absf(U.spd[i] - want) > 0.001:
				U.spd[i] = want
		match c.id:
			"brood_mother":
				if U.timer[i] >= U.timer2[i]:
					U.timer2[i] += float(c.fx["spawn_interval"])
					var n := int(c.fx["spawn_n"])
					var sd: CardDef = D.card(str(c.fx["spawn_unit"]))
					for q in n:
						var a := U.slot[i] + U.timer[i] + q * TAU / float(n)
						sim.spawn_child(sd, U.px[i] + cos(a) * 1.0, U.py[i] + sin(a) * 1.0, i)
			"corrupt_piper":
				var r := float(c.fx["aura_radius"])
				pipers.append([U.px[i], U.py[i], r * r, c.fxv("atk_speed", int(U.lvl[i]))])
			"rat_trap":
				for hh: SimHero in heroes:
					if Vector2(hh.x - U.px[i], hh.y - U.py[i]).length() <= hh.radius + U.rad[i] + float(c.fx["trigger"]):
						hh.root_t = maxf(hh.root_t, c.fxv("root", int(U.lvl[i])) * sim.cc_mult())
						if hh == sim.hero:
							sim._cc()
						var n2 := int(c.fx["rats"])
						for q in n2:
							var a2 := q * TAU / float(n2)
							sim.spawn_child(rat, U.px[i] + cos(a2) * 1.0, U.py[i] + sin(a2) * 1.0, i)
						sim.kill_unit(i, K.Death.EXPIRE)
						break
	if pipers.is_empty():
		return
	# Flautista: o Bando perto dele (e perto de um herói, onde ele de fato ataca) ataca mais rápido.
	for j in U.hi:
		if U.alive[j] == 0 or not (U.tags[j] & K.TAG_PACK) or U.arch[j] == K.Arch.STRUCTURE or U.atk_t[j] <= 0.0:
			continue
		var sp := 0.0
		for p: Array in pipers:
			var dx: float = U.px[j] - float(p[0])
			var dy: float = U.py[j] - float(p[1])
			if dx * dx + dy * dy <= float(p[2]):
				sp = maxf(sp, float(p[3]))
		if sp <= 0.0:
			continue
		for hh: SimHero in heroes:
			if Vector2(hh.x - U.px[j], hh.y - U.py[j]).length() <= 3.0:
				U.atk_t[j] = maxf(0.0, U.atk_t[j] - dt2 * sp)
				break


## Ninho-Mãe: o ninho a até nest_r do ponto solta uma criatura a mais cada vez que o timer de produção avança.
static func _double_nest(sim: Sim, st: Dictionary, i: int, c: CardDef) -> void:
	var U := sim.units
	if Vector2(U.px[i] - float(st["nest_x"]), U.py[i] - float(st["nest_y"])).length() > float(st["nest_r"]):
		return
	var key := str(i)
	var seen: Dictionary = st["seen"]
	var cur: float = U.timer2[i]
	if seen.has(key) and cur > float(seen[key]) + 0.001:
		var a := U.slot[i] + U.timer[i] + 1.7
		sim.spawn_child(sim.data.card(str(c.fx["spawn"])), U.px[i] + cos(a) * 1.2, U.py[i] + sin(a) * 1.2, i)
	seen[key] = cur


## Multiplicador do golpe da unidade i no herói, antes do dano (1.0 = nada).
static func unit_hit_mult(sim: Sim, i: int) -> float:
	if not sim.cstate.has("plague"):
		return 1.0
	var c: CardDef = sim.data.cards[sim.units.def[i]]
	if not c.fx.has("peste_dmg"):
		return 1.0
	var hh: SimHero = sim.hit_hero if sim.hit_hero else sim.hero
	return 1.0 + c.fxv("peste_dmg", int(sim.units.lvl[i])) * peste_f(sim, hh)


## Depois do golpe da unidade i no herói (real = dano que entrou).
static func on_unit_hit(sim: Sim, i: int, real: float) -> void:
	if not sim.cstate.has("plague"):
		return
	var st: Dictionary = sim.cstate["plague"]
	var U := sim.units
	var c: CardDef = sim.data.cards[U.def[i]]
	var hh: SimHero = sim.hit_hero if sim.hit_hero else sim.hero
	if real > 0.0:
		var n := float(int(c.fxv("peste", int(U.lvl[i]))))
		if sim.t < float(st.get("bubo_t", -1.0)):
			n += 1.0
		if (U.tags[i] & K.TAG_PACK) and sim.t < float(st.get("bite_t", -1.0)):
			var dx: float = U.px[i] - float(st["bite_x"])
			var dy: float = U.py[i] - float(st["bite_y"])
			if dx * dx + dy * dy <= pow(float(st["bite_r"]), 2):
				n += float(int(st["bite_n"]))
		if n > 0.0:
			# Golpe rápido = fração de acúmulo (a taxa por segundo é a do golpe de 1 s).
			add_peste(sim, hh, n * minf(1.0, U.atk_int[i]))
		if sim.t < float(st.get("hunt_t", -1.0)) and is_beast(c):
			U.hp[i] = minf(U.max_hp[i], U.hp[i] + real * float(st["hunt_steal"]))
	if c.id == "war_boar" and U.timer2[i] <= 0.0:
		# Investida: empurra o herói e o atordoa; recarga em timer2 (o Chaser já a desconta a cada passo).
		U.timer2[i] = float(c.fx["cd"])
		hh.knockback(U.px[i], U.py[i], float(c.fx["push"]))
		hh.petrify_t = maxf(hh.petrify_t, c.fxv("stun", int(U.lvl[i])) * sim.cc_mult())
		if hh == sim.hero:
			sim._cc()


## Bônus somado ao dano que o herói `hh` recebe de qualquer fonte (0.0 = nada; 0.15 = +15%).
static func hero_damage_bonus(sim: Sim, hh: SimHero, tags: int, kind: int) -> float:
	if not sim.cstate.has("plague"):
		return 0.0
	var st: Dictionary = sim.cstate["plague"]
	var pe: Dictionary = st["peste"]
	if pe.is_empty():
		return 0.0
	var key := str(hh.pidx)
	if not pe.has(key):
		return 0.0
	return float(pe[key][0]) * float(st["cfg"][1])


## Unidade i vai morrer (cause = K.Death.*); os dados dela ainda estão em sim.units.
static func on_unit_death(sim: Sim, i: int, cause: int) -> void:
	if cause != K.Death.HERO or not sim.cstate.has("plague"):
		return
	var st: Dictionary = sim.cstate["plague"]
	var U := sim.units
	# Enxame Sem Fim: o Bando que morre pelo herói renasce uma vez.
	if sim.t < float(st.get("endless_t", -1.0)) and (U.tags[i] & K.TAG_PACK) and U.arch[i] != K.Arch.STRUCTURE \
			and not (U.flags[i] & K.F_REVIVED):
		var c: CardDef = sim.data.cards[U.def[i]]
		var j := U.spawn(c, U.px[i], U.py[i], 0.0, 0.0, (U.flags[i] & (K.F_CURSED | K.F_DEFEND)) | K.F_REVIVED | K.F_NO_XP, U.uid[i])
		if j >= 0:
			U.lvl[j] = U.lvl[i]
			U.hp[j] = U.max_hp[i]
			U.max_hp[j] = U.max_hp[i]
			U.dmg[j] = U.dmg[i]


## Depois de uma carta jogada (já aplicada).
static func on_card_played(sim: Sim, c: Sim.CardInst, x: float, y: float) -> void:
	if c.def.owner == "plague":
		_st(sim)   # daqui em diante os ganchos rodam


## Multiplicador do golpe do herói nas suas unidades (1.0 = nada; 0.7 = herói causa 30% menos).
static func hero_out_mult(sim: Sim) -> float:
	return 1.0


## Soma ao custo da carta c agora (negativo = desconto). O custo final nunca fica abaixo de 0.
static func card_cost_add(sim: Sim, c: Sim.CardInst) -> int:
	return 0

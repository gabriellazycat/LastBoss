class_name CardsLich
extends RefCounted
## Efeitos das cartas do Lich (owner "lich" em data/cards.json) que não cabem nas ops de CardFxLib.
## Colheita de Almas (buff "harvest") e Marca Sombria (buff "spell_mark" + curse) são declaradas em "ops".


## Aplica a carta pelo id. Devolve true se tratou.
static func apply(sim: Sim, k: CardFxLib.Ctx, x: float, y: float) -> bool:
	var d := k.d
	var fx := d.fx
	var lv := k.lv
	var smult := k.smult
	var vet := k.vet
	var curse := k.curse
	var U := sim.units
	match d.id:
		"shadow_bolt":
			# A linha sai do ponto solto até o herói mais perto dele (não mais o líder).
			var bh := sim.hero_nearest(Vector2(x, y))
			var dir := Vector2(bh.x - x, bh.y - y)
			if dir.length() < 0.1:
				dir = Vector2(bh.face_x, bh.face_y)
			dir = dir.normalized()
			# Fase de grupo (10/11/2026): o raio atravessa a linha e pega todo herói nela (cheio no primeiro,
			# metade nos outros, como os feitiços de área).
			var hit_line: Array = []
			for hh in sim.all_heroes():
				var rel := Vector2(hh.x - x, hh.y - y)
				var along := rel.dot(dir)
				var side := absf(rel.dot(Vector2(-dir.y, dir.x)))
				if along >= -0.5 and along <= float(fx["length"]) and side <= float(fx["width"]) * 0.5 + hh.radius:
					hit_line.append([along, hh])
			hit_line.sort_custom(func(a, b): return a[0] < b[0])
			for k2 in hit_line.size():
				var hh: SimHero = hit_line[k2][1]
				sim.hit_hero = hh if hh != sim.hero else null
				# N3: o raio volta pelo mesmo caminho e acerta de novo.
				for i in int(d.fxv("hits", lv, 1.0)):
					sim.damage_hero(d.fxv("damage", lv) * smult * vet * sim.splash_mult(k2), x, y, d.tags, SimHero.DMG_PIERCE | SimHero.DMG_SPELL, d.id)
				hh.add_curse(curse)
			sim.hit_hero = null
		"soul_feast":
			U.within(x, y, d.fxv("radius", lv), sim.tmp)
			var refund := 0.0
			var seen := {}
			for j in sim.tmp.duplicate():
				if U.alive[j] == 0 or U.arch[j] == K.Arch.STRUCTURE:
					continue
				refund += U.cost_share[j]
				seen[U.uid[j]] = true
				sim.kill_unit(j, K.Death.SACRIFICE)
			refund += seen.size() * d.fxv("bonus_per_card", lv)
			sim.elixir = minf(sim.elixir_max, sim.elixir + refund)
		"corpse_blast":
			var best := -1
			var bd := pow(float(fx["pick_radius"]), 2)
			for j in U.hi:
				if U.alive[j] == 0 or U.arch[j] == K.Arch.STRUCTURE:
					continue
				var dd := Vector2(U.px[j] - x, U.py[j] - y).length_squared()
				if dd <= bd:
					bd = dd
					best = j
			if best >= 0:
				var bx_ := U.px[best]
				var by_ := U.py[best]
				var boom := maxf(float(fx["min_damage"]), U.max_hp[best] * d.fxv("hp_mult", lv)) * smult * vet
				sim.kill_unit(best, K.Death.SACRIFICE)
				var near_b := sim.heroes_near(bx_, by_, float(fx["radius"]))
				for i in near_b.size():
					sim.hit_hero = near_b[i] if near_b[i] != sim.hero else null
					# Respingo menor que o dos outros feitiços (10/11/2026: era 65% do dano da Cripta na fase 4).
					sim.damage_hero(boom * (1.0 if i == 0 else float(sim.R.get("corpse_blast_splash", 0.15))), bx_, by_, d.tags, SimHero.DMG_AREA | SimHero.DMG_SPELL, d.id)
				sim.hit_hero = null
				sim.emit(K.Ev.EXPLOSION, bx_, by_, float(fx["radius"]), 0)
				sim.hero_nearest(Vector2(bx_, by_)).add_curse(curse)
			else:
				# Nenhum monstro seu perto: levanta esqueletos no ponto (sempre há o que fazer com a carta).
				CardFxLib.summon(sim, k, "skeleton", int(fx.get("raise", 3)), 0.8, x, y)
		"arcane_spark":
			var n_prev := sim.recent_spells(float(fx["window"]))
			var sp := (d.fxv("damage", lv) + n_prev * d.fxv("per_spell", lv)) * smult * vet
			var near_s := sim.heroes_near(x, y, float(fx["radius"]))
			for i in near_s.size():
				var hh: SimHero = near_s[i]
				sim.hit_hero = hh if hh != sim.hero else null
				sim.damage_hero(sp * sim.splash_mult(i), x, y, d.tags, SimHero.DMG_PIERCE | SimHero.DMG_SPELL, d.id)
				hh.add_curse(curse)
			sim.hit_hero = null
		"shadow_echo":
			var ld: CardDef = sim.data.card(sim.last_spell_id)
			if ld:
				var echo := Sim.CardInst.new()
				echo.def = ld
				echo.uid = k.c.uid
				echo.level = maxi(sim.last_spell_lv, lv)
				sim._apply(echo, x, y)
		"life_drain":
			# O dano vem das ops; aqui a cura nos mortos-vivos seus perto do alvo.
			U.within(x, y, d.fxv("heal_radius", lv), sim.tmp)
			var heal := d.fxv("heal", lv)
			for j in sim.tmp.duplicate():
				if U.alive[j] == 1 and U.arch[j] != K.Arch.STRUCTURE and (U.tags[j] & K.TAG_UNDEAD):
					U.hp[j] = minf(U.max_hp[j], U.hp[j] + heal)
		"profane_ritual":
			# Sacrifica o monstro seu mais perto do ponto; os próximos feitiços ficam mais baratos e mais fortes.
			var pick := -1
			var pd := pow(float(fx["pick_radius"]), 2)
			for j in U.hi:
				if U.alive[j] == 0 or U.arch[j] == K.Arch.STRUCTURE:
					continue
				var d2 := Vector2(U.px[j] - x, U.py[j] - y).length_squared()
				if d2 <= pd:
					pd = d2
					pick = j
			if pick >= 0:
				sim.kill_unit(pick, K.Death.SACRIFICE)
				var st := _st(sim)
				st["rit"] = int(fx["charges"])
				st["rit_b"] = d.fxv("bonus", lv)
				st["rit_d"] = int(fx["discount"])
				sim.hero_nearest(Vector2(x, y)).add_curse(curse)
		"open_grave":
			if recent_deaths(sim, float(fx["window"])) >= int(fx["deaths"]):
				CardFxLib.summon(sim, k, "skeleton", int(round(d.fxv("raise", lv))), 0.8, x, y)
		"soul_storm":
			var n_d := mini(int(fx["cap"]), recent_deaths(sim, float(fx["window"])))
			var storm := d.fxv("damage", lv) * n_d * smult * vet
			var near_t := sim.heroes_near(x, y, float(fx["radius"]))
			for i in near_t.size():
				var hh: SimHero = near_t[i]
				sim.hit_hero = hh if hh != sim.hero else null
				sim.damage_hero(storm * sim.splash_mult(i), x, y, d.tags, SimHero.DMG_AREA | SimHero.DMG_SPELL, d.id)
				hh.add_curse(curse)
			sim.hit_hero = null
			sim.emit(K.Ev.EXPLOSION, x, y, float(fx["radius"]), 0)
		"arcane_apocalypse":
			# Repete os feitiços dos últimos `window` s (até `max_spells`), no ponto jogado. O registro só guarda
			# feitiços jogados de verdade: nem esta carta, nem o Eco, nem os que sacrificam monstros entram nele,
			# então a repetição nunca vira laço.
			var log: Array = _st(sim)["sp"]
			var picked: Array = []
			for e in log:
				if sim.t - float(e[0]) <= float(fx["window"]):
					picked.append(e)
			var first := maxi(0, picked.size() - int(round(d.fxv("max_spells", lv))))
			for ix in range(first, picked.size()):
				var rd: CardDef = sim.data.card(str(picked[ix][1]))
				if rd == null:
					continue
				var rep := Sim.CardInst.new()
				rep.def = rd
				rep.uid = k.c.uid
				rep.level = int(picked[ix][2])
				sim._apply(rep, x, y)
		"eternal_army":
			# Exército Eterno: os 12 esqueletos vêm das ops; por "duration" s cada morte sua levanta mais 1 (até "raises").
			var st := _st(sim)
			st["army_until"] = sim.t + d.fxv("duration", lv) * vet
			st["army_left"] = int(d.fxv("raises", lv))
		_:
			return false
	return true

# ================================================================ estado do Lich (C6)

## Estado do Lich em sim.cstate["lich"]: dt = instantes das mortes de monstros seus; sp = [instante, id, nível] dos
## feitiços jogados; dk = instantes dos feitiços (Cavaleiro da Morte); rit = feitiços que o Ritual ainda favorece.
static func _st(sim: Sim) -> Dictionary:
	if not sim.cstate.has("lich"):
		sim.cstate["lich"] = {"dt": [], "sp": [], "dk": [], "rit": 0, "rit_b": 0.0, "rit_d": 0}
	return sim.cstate["lich"]


## Mortes de monstros seus (Servo Reanimado conta 2) nos últimos `window` segundos.
static func recent_deaths(sim: Sim, window: float) -> int:
	var n := 0
	for ts in _st(sim)["dt"]:
		if sim.t - float(ts) <= window:
			n += 1
	return n


static func _prune(list: Array, now: float, window: float) -> void:
	while list.size() > 0:
		var head = list[0]
		var ts := float(head[0]) if head is Array else float(head)
		if now - ts > window:
			list.pop_front()
		else:
			break


## Feitiços que o Apocalipse não repete: ele mesmo, o Eco e os que sacrificam um monstro seu.
const NO_REPLAY := ["arcane_apocalypse", "shadow_echo", "profane_ritual", "dark_sacrifice"]

# ================================================================ ganchos (C6)
# Chamados pelo Sim para os 4 donos, sempre. Só reaja às suas cartas/unidades (data.cards[sim.units.def[i]].owner) ou
# ao seu vilão (sim.deck_id). Estado próprio em sim.cstate["<dono>"]. Mantenha baratos: rodam a cada passo/golpe.

## A cada passo da simulação (dt = sim.dt).
static func on_tick(sim: Sim) -> void:
	pass


## Multiplicador do golpe da unidade i no herói, antes do dano (1.0 = nada).
static func unit_hit_mult(sim: Sim, i: int) -> float:
	# Cavaleiro da Morte: +10% de dano por feitiço jogado nos últimos 10 s (até 10).
	var c: CardDef = sim.data.cards[sim.units.def[i]]
	if c.fx.has("spell_dmg"):
		var n := 0
		for ts in _st(sim)["dk"]:
			if sim.t - float(ts) <= float(c.fx["spell_dmg_s"]):
				n += 1
		return 1.0 + minf(float(c.fx["spell_dmg_max"]), n) * float(c.fx["spell_dmg"])
	return 1.0


## Depois do golpe da unidade i no herói (real = dano que entrou).
static func on_unit_hit(sim: Sim, i: int, real: float) -> void:
	pass


## Bônus somado ao dano que o herói `hh` recebe de qualquer fonte (0.0 = nada; 0.15 = +15%).
static func hero_damage_bonus(sim: Sim, hh: SimHero, tags: int, kind: int) -> float:
	# Ritual Profano: os próximos feitiços causam mais.
	if (kind & SimHero.DMG_SPELL) and sim.cstate.has("lich"):
		var st: Dictionary = sim.cstate["lich"]
		if int(st["rit"]) > 0:
			return float(st["rit_b"])
	return 0.0


## Unidade i vai morrer (cause = K.Death.*); os dados dela ainda estão em sim.units.
static func on_unit_death(sim: Sim, i: int, cause: int) -> void:
	var U := sim.units
	if cause == K.Death.EXPIRE or U.arch[i] == K.Arch.STRUCTURE:
		return
	var di := U.def[i]
	var c: CardDef = sim.data.cards[di]
	var x := U.px[i]
	var y := U.py[i]
	var st := _st(sim)
	var n := int(c.fx.get("death_count", 1))
	for k in n:
		st["dt"].append(sim.t)
	_prune(st["dt"], sim.t, 35.0)
	# Servo Reanimado: a morte extra também vale para Colheita, Carniçal, Colheita de Almas e contagem do herói.
	for k in n - 1:
		sim._death_payoffs(i, x, y)
		sim._villain_on_death(c, x, y)
		if (cause == K.Death.HERO or cause == K.Death.SELF) and not (U.flags[i] & K.F_REVIVED):
			sim.dead_by_def[di] += 1
	# Exército Eterno: cada morte sua levanta um esqueleto enquanto durar (e restarem levantes).
	if cause == K.Death.HERO and st.has("army_until") and sim.t < float(st["army_until"]) and int(st["army_left"]) > 0:
		var sk: CardDef = sim.data.card("skeleton")
		var jn := U.spawn(sk, x, y, 0.0, 0.0, K.F_NO_XP, 0, sim._forge())
		if jn >= 0:
			st["army_left"] = int(st["army_left"]) - 1
	# Dragão de Ossos: cada morte sua por perto cura o dragão (fração da vida máxima).
	var bd: CardDef = sim.data.card("bone_dragon")
	for j in U.hi:
		if U.alive[j] == 1 and j != i and U.def[j] == bd.idx:
			if Vector2(U.px[j] - x, U.py[j] - y).length() <= bd.fxv("heal_radius", int(U.lvl[j]), 8.0):
				U.hp[j] = minf(U.max_hp[j], U.hp[j] + U.max_hp[j] * bd.fxv("heal_death", int(U.lvl[j])))
	# Colosso de Ossos: absorve os mortos por perto como o Golem de Sucata (+vida máxima).
	if cause == K.Death.HERO and not (U.flags[i] & K.F_REVIVED):
		var cd: CardDef = sim.data.card("bone_colossus")
		var r2 := pow(float(cd.fx["absorb_radius"]), 2)
		for j in U.hi:
			if U.alive[j] == 1 and j != i and U.def[j] == cd.idx:
				if Vector2(U.px[j] - x, U.py[j] - y).length_squared() <= r2:
					var cap := cd.fxv("hp_cap", int(U.lvl[j]))
					U.max_hp[j] = minf(cap, U.max_hp[j] + float(cd.fx["absorb_hp"]))
					U.hp[j] = minf(U.max_hp[j], U.hp[j] + float(cd.fx["absorb_hp"]))
					break


## Depois de uma carta jogada (já aplicada).
static func on_card_played(sim: Sim, c: Sim.CardInst, x: float, y: float) -> void:
	var d := c.def
	if not d.is_spell:
		return
	var st := _st(sim)
	# Cavaleiro da Morte: cada feitiço cura e aumenta o dano.
	st["dk"].append(sim.t)
	_prune(st["dk"], sim.t, 12.0)
	var dk: CardDef = sim.data.card("death_knight")
	for j in sim.units.hi:
		if sim.units.alive[j] == 1 and sim.units.def[j] == dk.idx:
			sim.units.hp[j] = minf(sim.units.max_hp[j], sim.units.hp[j] + dk.fxv("spell_heal", int(sim.units.lvl[j])))
	# Ritual Profano: gasta uma carga (a carta do próprio Ritual não gasta).
	if d.id != "profane_ritual" and int(st["rit"]) > 0:
		st["rit"] = int(st["rit"]) - 1
	# Registro para o Apocalipse Arcano.
	if not NO_REPLAY.has(d.id) and not d.fx.has("gold_cost"):
		st["sp"].append([sim.t, d.id, c.level])
		_prune(st["sp"], sim.t, 15.0)
		while st["sp"].size() > 12:
			st["sp"].pop_front()
	elif d.id == "arcane_apocalypse":
		# O Eco não pode repetir o Apocalipse: o "último feitiço" volta a ser o último registrado.
		var log: Array = st["sp"]
		sim.last_spell_id = str(log[-1][1]) if log.size() > 0 else ""
		sim.last_spell_lv = int(log[-1][2]) if log.size() > 0 else 1


## Multiplicador do golpe do herói nas suas unidades (1.0 = nada; 0.7 = herói causa 30% menos).
static func hero_out_mult(sim: Sim) -> float:
	return 1.0


## Soma ao custo da carta c agora (negativo = desconto). O custo final nunca fica abaixo de 0.
static func card_cost_add(sim: Sim, c: Sim.CardInst) -> int:
	var add := 0
	# Ciclo de feitiço (passiva): feitiço e criatura se barateiam um ao outro.
	if sim.cycle_applies(c):
		add -= 1
	# Ritual Profano: os próximos feitiços custam menos.
	if c.def.is_spell and sim.cstate.has("lich"):
		var st: Dictionary = sim.cstate["lich"]
		if int(st["rit"]) > 0:
			return add - int(st["rit_d"])
	return add

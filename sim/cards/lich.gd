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
			var dir := Vector2(sim.hero.x - x, sim.hero.y - y)
			if dir.length() < 0.1:
				dir = Vector2(sim.hero.face_x, sim.hero.face_y)
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
				sim.hero.add_curse(curse)
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
		"forbidden_library":
			sim.lair[d.id] = int(sim.lair.get(d.id, 0)) + 1
			sim.hand_size = mini(Sim.HAND_MAX, sim.hand_size + int(fx["hand"]))
			sim._refill_hand()
		_:
			return false
	return true

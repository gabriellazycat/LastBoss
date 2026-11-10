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
		"soul_collector":
			_lair_stack(sim, k, "elixir_regen")
		"dark_forge":
			_lair_stack(sim, k, "monster_hp")
		_:
			return _apply_removed(sim, k, x, y)
	return true


## Covil empilhável: conta a cópia e soma o efeito dela (já com o nível).
static func _lair_stack(sim: Sim, k: CardFxLib.Ctx, key: String) -> void:
	var id := k.d.id
	sim.lair[id] = int(sim.lair.get(id, 0)) + 1
	sim.lair_val[id] = float(sim.lair_val.get(id, 0.0)) + k.d.fxv(key, k.lv)


# ==================================================================================================
# BLOCO A REMOVER no passo C1: Muralhas do Covil e as 6 Finalizações (com o Exército dos Condenados).
# ==================================================================================================

static func _apply_removed(sim: Sim, k: CardFxLib.Ctx, _x: float, _y: float) -> bool:
	var d := k.d
	var fx := d.fx
	var lv := k.lv
	match d.id:
		"lair_walls":
			_lair_stack(sim, k, "hero_hp_loss")
		"cosmic_ray":
			if sim.arena.hero_in_front(d.fxv("cone", lv), float(fx["range"]) + 2.0):
				sim.damage_hero(fx["damage"], sim.arena.bx, sim.arena.by, 0, SimHero.DMG_PIERCE, d.id)
		"bone_prison":
			# Prende o grupo todo (10/11/2026); sozinho, all_heroes() é só o herói.
			for hh in sim.all_heroes():
				hh.root_t = d.fxv("root", lv) * sim.cc_mult()
		"petrifying_gaze":
			sim.hero.petrify_t = d.fxv("petrify", lv)
			sim.hero.shield_hp = 0.0
			sim.hero.shield_t = sim.hero.H["shield"]["regen_seconds"]
			sim.hero.tavern_t = 0.0
		"damned_army":
			_army(sim, fx, d.fxv("hp", lv), d.fxv("dps", lv))
		"dark_fury":
			sim.arena.fury(fx["heal"], fx["duration"], d.fxv("damage", lv))
		"dark_pact":
			# Paga com vida de uma parte do corpo (a mais cheia), sem destruí-la de saída.
			if sim.arena.drain_part(float(fx["drain"])):
				sim.elixir = sim.elixir_max
				for i in int(d.fxv("draw", lv)):
					if sim.queue.size() > 0 and sim.hand.size() < Sim.HAND_MAX:
						sim.hand.append(sim.queue.pop_front())
		_:
			return false
	return true


## Exército dos Condenados: um espectro por monstro seu morto (os mais caros primeiro), por `duration` s.
static func _army(sim: Sim, fx: Dictionary, hp_: float, dps_: float) -> void:
	var data := sim.data
	var order: Array = []
	for di in sim.dead_by_def.size():
		if sim.dead_by_def[di] > 0:
			order.append(di)
	order.sort_custom(func(a, b): return data.cards[a].cost > data.cards[b].cost or (data.cards[a].cost == data.cards[b].cost and a < b))
	var sp: CardDef = data.card("spectre")
	var n := 0
	var ids: Array = []
	var mx := int(fx["max"])
	var U := sim.units
	var hero := sim.hero
	for di in order:
		for i in sim.dead_by_def[di]:
			if n >= mx:
				break
			var a := n * 2.399963
			var r := 4.0 + fmod(n * 0.7, 2.0)
			var j := U.spawn(sp, hero.x + cos(a) * r, hero.y + sin(a) * r, 0.0, 0.0, K.F_NO_XP, 0)
			if j >= 0:
				U.hp[j] = hp_
				U.max_hp[j] = hp_
				U.dmg[j] = dps_ * U.atk_int[j] * U.dmg_mult
				ids.append(j)
			n += 1
	sim.zones.append({"kind": "army", "x": hero.x, "y": hero.y, "r": 0.0, "t": fx["duration"], "ids": ids})

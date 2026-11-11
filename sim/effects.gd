class_name Effects
extends RefCounted
## Ações dos eventos de texto do local "?" (data/events.json). Cada ação é um dicionário com "kind".
## As que pedem escolha abrem ofertas comuns, na fila, depois da escolha do evento.
## Todo sorteio usa sim.rng (determinístico pela semente).


static func run(sim: Sim, acts: Array) -> void:
	for a in acts:
		_one(sim, a)


static func _one(sim: Sim, a: Dictionary) -> void:
	match str(a["kind"]):
		"gold":
			var v := float(a["amount"])
			if v > 0.0:
				sim._earn_gold(v)
			else:
				sim.gold = maxf(0.0, sim.gold + v)
				sim.stats["gold_spent"] += -v
		"elixir":
			sim.elixir = clampf(sim.elixir + float(a["amount"]), 0.0, sim.elixir_max)
		"card":
			var f := _card_filter(a)
			var n := int(a.get("n", 1))
			var opts := sim._card_options(n, f)
			if a.get("give", false):
				if opts.size() > 0:
					sim._apply_option(opts[0])
			else:
				sim._push_offer("event", opts, {"event_step": "card"})
		"upgrade":
			var n := int(a.get("n", 1))
			if a.get("give", false):
				for k in n:
					var o := sim._level_up_options(1)
					if o.size() > 0:
						sim._apply_option(o[0])
			else:
				sim._push_offer("event", sim._level_up_options(n), {"event_step": "upgrade"})
		"remove":
			if a.get("give", false):
				var o := sim._remove_options(1)
				if o.size() > 0:
					sim._apply_option(o[0])
			else:
				sim._push_offer("event", sim._remove_options(-1), {"event_step": "remove"})
		"mod":
			var opts: Array = []
			var ex: Array = []
			for k in int(a.get("n", 3)):
				var m := sim._mod_option(ex)
				if m.size() > 0:
					ex.append(str(m["uid"]) + str(m["mod"]))
					opts.append(m)
			sim._push_offer("event", opts, {"event_step": "mod"})
		"relic":
			sim.random_relic()
		"elixir_max_act":
			sim.act_elixir_bonus += float(a["amount"])
			sim.recalc_elixir_max()
		"card_tax":
			sim.tax_cards = int(a["n"])
			sim.tax_add = int(a.get("add", 1))
		"boss_hp":
			sim.boss_hp_mult *= float(a["mult"])
		"hero_curse":
			sim.hero.add_curse(int(a["n"]))
		"hero_heal":
			sim.hero.heal(sim.hero.max_hp() * float(a["frac"]))
		"next_hero_hp":
			sim.next_hp_mult *= float(a["mult"])
		"next_hero_ability":
			sim.next_extra_ability = true
		"chance":
			if sim.rng.randf() < float(a["p"]):
				run(sim, a.get("then", []))
			else:
				run(sim, a.get("else", []))
		"transform":
			sim._push_offer("event", sim._pick_insts(sim.cards.duplicate(), -1, "transform"), {"event_step": "transform"})
		"copy":
			var pool: Array = []
			var mx := int(sim.R["deck"].get("max_copies", 2))
			for ci in sim.cards:
				if sim._deck_count(ci.def.id) < mx:
					pool.append(ci)
			sim._push_offer("event", sim._pick_insts(pool, -1, "copy"), {"event_step": "copy"})


static func _card_filter(a: Dictionary) -> Callable:
	if a.has("min_rarity"):
		var minr := K.RARITIES.find(str(a["min_rarity"]))
		return func(cd: CardDef): return cd.rarity >= minr
	if a.has("rarity"):
		var r := K.RARITIES.find(str(a["rarity"]))
		return func(cd: CardDef): return cd.rarity == r
	return func(cd: CardDef): return true

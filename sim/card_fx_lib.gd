class_name CardFxLib
extends RefCounted
## Primitivas de efeito de carta declaradas em dados (campo "ops" em data/cards.json). Esquema em docs/CARD_FX.md.
##
## Cada op é um dicionário {"op": nome, ...parâmetros}. Parâmetro numérico pode ser um número literal ou o nome de
## uma chave do "fx" da carta (string): aí vale d.fxv(chave, nível), que já aplica "lvl" e o especial do "n3".
## As primitivas só chamam o que o Sim já tem (heroes_near, damage_hero, zones, hero_fear...): nada de regra nova.


## Contexto de uma carta sendo aplicada: nível e multiplicadores do Pacto e dos modificadores.
class Ctx:
	var c: Sim.CardInst
	var d: CardDef
	var lv := 1
	var smult := 1.0   # Pacto: spell_damage_mult
	var vet := 1.0     # multiplicador de efeito de feitiço (fixo em 1.0 desde que o Veterano saiu dos feitiços)
	var curse := 0     # Amaldiçoado em feitiço: 1 maldição nos heróis atingidos


static func ctx(sim: Sim, c: Sim.CardInst) -> Ctx:
	var k := Ctx.new()
	k.c = c
	k.d = c.def
	k.lv = c.level
	k.smult = float(sim.deck_rules.get("spell_damage_mult", 1.0))
	k.curse = 1 if c.def.is_spell and c.has_mod(K.M_CURSED) else 0
	return k


## Contexto de uma unidade que morreu (gatilho "on_death"): nível da unidade, sem Pacto nem modificador de feitiço.
static func unit_ctx(d: CardDef, lv: int, uid: int) -> Ctx:
	var k := Ctx.new()
	var c := Sim.CardInst.new()
	c.def = d
	c.uid = uid
	c.level = lv
	k.c = c
	k.d = d
	k.lv = lv
	return k


## Valor de um parâmetro: número literal, ou chave do fx da carta (com nível).
static func val(k: Ctx, p: Variant, default := 0.0) -> float:
	if p == null:
		return default
	if p is String:
		return k.d.fxv(p, k.lv, default)
	return float(p)


# ================================================================ invocar

## Unidades da própria carta (toda carta com "archetype"): quantidade e números do nível, modificadores, Cobiça,
## Forja Sombria, defesa do chefe na arena. É o caminho de toda carta de monstro e estrutura.
static func spawn_card_units(sim: Sim, k: Ctx, x: float, y: float) -> void:
	var d := k.d
	var c := k.c
	var lv := k.lv
	var n := d.count_at(lv) + (1 if c.has_mod(K.M_VETERAN) else 0)
	if d.tags & K.TAG_PACK:
		n += int(sim.rv("pack_extra"))   # Ninhada Dobrada (relíquia)
	var hpm := d.mult(lv) if d.scales("hp") else 1.0
	if d.type == "structure":
		hpm *= 1.0 + sim.rv("structure")
	var dpm := d.mult(lv) if d.scales("dps") else 1.0
	if d.fx.has("gold_step"):
		# Cobiça: cada `gold_step` de ouro guardado dá +gold_bonus de vida e dano (até gold_cap).
		var gm := 1.0 + minf(float(d.fx.get("gold_cap", 1.0)), floorf(sim.gold / float(d.fx["gold_step"])) * float(d.fx["gold_bonus"]))
		hpm *= gm
		dpm *= gm
	var xpv := 0.0   # sem XP (09/11/2026)
	var f := 0
	if c.has_mod(K.M_SHADOWY):
		f |= K.F_NO_XP
	if c.has_mod(K.M_EXPLOSIVE):
		f |= K.F_EXPLOSIVE
	if c.has_mod(K.M_CURSED):
		f |= K.F_CURSED
	if sim.phase == K.Phase.ARENA and Vector2(x - sim.arena.bx, y - sim.arena.by).length() <= 6.0:
		f |= K.F_DEFEND
	for i in n:
		var r := 0.55 * sqrt(float(i))
		var a := i * 2.399963
		var j := sim.units.spawn(d, x + cos(a) * r, y + sin(a) * r, xpv, float(d.cost) / n, f, c.uid, sim._forge() * hpm)
		if j >= 0:
			sim.units.lvl[j] = lv
			sim.units.dmg[j] *= dpm


## Unidades auxiliares (ou de outra carta) em anel no ponto, sem XP nem elixir de volta (como os esqueletos da
## Explosão de Cadáver).
static func summon(sim: Sim, k: Ctx, unit_id: String, n: int, ring: float, x: float, y: float) -> void:
	var u: CardDef = sim.data.card(unit_id)
	if u == null:
		push_error("CardFxLib.summon: unidade desconhecida " + unit_id)
		return
	for i in n:
		var a := i * TAU / maxf(1.0, float(n))
		sim.units.spawn(u, x + cos(a) * ring, y + sin(a) * ring, 0.0, 0.0, 0, k.c.uid, sim._forge())


# ================================================================ alvos

## Heróis atingidos: "hero" (o da vez), "group" (todos de pé), "area" (no raio, do mais perto ao mais longe) ou
## "nearest" (o mais perto no raio; ninguém perto = o da vez, como a Poça de Óleo).
static func targets(sim: Sim, target: String, x: float, y: float, r: float) -> Array:
	match target:
		"group":
			return sim.all_heroes()
		"area":
			return sim.heroes_near(x, y, r)
		"nearest":
			var near: Array = sim.heroes_near(x, y, r) if sim.multi_heroes() else []
			return [near[0]] if near.size() > 0 else [sim.hero]
	return [sim.hero]


# ================================================================ execução

static func run(sim: Sim, k: Ctx, ops: Array, x: float, y: float) -> void:
	for o in ops:
		run_op(sim, k, o, x, y)


static func run_op(sim: Sim, k: Ctx, o: Dictionary, x: float, y: float) -> void:
	var d := k.d
	var spell := d.is_spell
	var mul := k.smult * k.vet if spell else 1.0   # dano de feitiço: Pacto e Veterano
	var dur_mul := k.vet                           # duração de feitiço: Veterano
	match str(o.get("op", "")):
		"summon":
			summon(sim, k, str(o["unit"]), int(val(k, o.get("n"), 1.0)), val(k, o.get("ring"), 0.8), x, y)
		"damage":
			# Dano nos heróis do raio: cheio no mais perto, group_spell_splash nos outros.
			var r := val(k, o.get("radius"), 2.5)
			var dmg := val(k, o.get("damage")) * mul
			var kind := SimHero.DMG_PIERCE if str(o.get("kind", "area")) == "pierce" else SimHero.DMG_AREA
			if spell:
				kind |= SimHero.DMG_SPELL
			var hs: Array = targets(sim, str(o.get("target", "area")), x, y, r)
			for i in hs.size():
				var hh: SimHero = hs[i]
				sim.hit_hero = hh if hh != sim.hero else null
				sim.damage_hero(dmg * sim.splash_mult(i), x, y, d.tags, kind, d.id)
				hh.add_curse(k.curse)
			sim.hit_hero = null
			if o.get("boom", false):
				sim.emit(K.Ev.EXPLOSION, x, y, r, 0)
		"status":
			_status(sim, k, o, x, y)
		"curse":
			# Maldições extras ("n") mais a do modificador Amaldiçoado.
			for hh in targets(sim, str(o.get("target", "hero")), x, y, val(k, o.get("radius"), 2.5)):
				hh.add_curse(int(val(k, o.get("n"), 0.0)) + k.curse)
		"zone":
			_zone(sim, k, o, x, y, mul, dur_mul)
		"buff":
			var until := sim.t + val(k, o.get("duration")) * dur_mul
			match str(o["slot"]):
				"rally":       # monstros de bando (tag pack): +dano e +velocidade
					sim.rally_until = until
					sim.rally_dmg = val(k, o.get("damage"))
					sim.rally_spd = val(k, o.get("speed"))
				"harvest":     # cada monstro seu que morre devolve elixir
					sim.harvest_until = until
					sim.harvest_elixir = val(k, o.get("elixir"))
				"warcry":      # Grito de Guerra: todos os seus monstros (não só o Bando) correm e batem mais
					sim.warcry_until = until
					sim.warcry_dmg = val(k, o.get("damage"))
					sim.warcry_spd = val(k, o.get("speed"))
				"spell_mark":  # feitiços machucam mais o herói
					sim.mark_until = until
					sim.mark_bonus = val(k, o.get("bonus"))
				_:
					push_error("CardFxLib: buff sem slot conhecido: " + str(o["slot"]))
		"elixir":
			sim.elixir = minf(sim.elixir_max, sim.elixir + val(k, o.get("amount")))
		"temp":
			# Temporário (C4): efeito com duração que soma entre cópias (Sim.add_temp).
			sim.add_temp(str(o["kind"]), val(k, o.get("value")), val(k, o.get("duration")) * k.vet, d.id)
		"gold":
			sim._earn_gold(val(k, o.get("amount")))
		"pay_gold":
			var g := val(k, o.get("amount"))
			sim.gold -= g
			sim.stats["gold_spent"] += int(g)
		"draw":
			for i in int(val(k, o.get("n"), 1.0)):
				if sim.hand.size() < Sim.HAND_MAX:
					var dc := sim.draw_card()
					if dc and sim.hand.size() < Sim.HAND_MAX:
						sim.hand.append(dc)
					elif dc:
						sim.queue.push_front(dc)   # "compra ao embaralhar" encheu a mão no meio da compra
		_:
			push_error("CardFxLib: op desconhecida %s na carta %s" % [str(o.get("op", "")), d.id])


static func _status(sim: Sim, k: Ctx, o: Dictionary, x: float, y: float) -> void:
	var st := str(o["status"])
	var dur := val(k, o.get("duration")) * k.vet
	var hs: Array = targets(sim, str(o.get("target", "hero")), x, y, val(k, o.get("radius"), 3.0))
	for hh: SimHero in hs:
		match st:
			"soaked":
				hh.soaked_t = maxf(hh.soaked_t, dur)
			"slow":
				hh.slow_t = maxf(hh.slow_t, dur)
				hh.note("slow", 2.0)
			"root":
				hh.root_t = maxf(hh.root_t, dur * sim.cc_mult())
				if hh == sim.hero:
					sim._cc()
			"petrify":
				hh.petrify_t = maxf(hh.petrify_t, dur)
			"fear":
				if hh == sim.hero:   # o medo só existe no herói da vez
					sim.hero_fear(x, y, dur)
			"burn":
				var dps := val(k, o.get("dps")) * (k.smult if k.d.is_spell else 1.0)
				if hh == sim.hero:
					sim.burn_t = maxf(sim.burn_t, dur)
					sim.burn_dps = dps
					sim.burn_src = k.d.id
				else:
					hh.burn_t = maxf(hh.burn_t, dur)
					hh.burn_dps = dps * sim.splash_mult(1)
			_:
				push_error("CardFxLib: estado desconhecido " + st)
		hh.add_curse(k.curse)


## Zona no chão, tratada por Sim._zones(): "web" (lentidão; prende uma vez por herói), "oil" (encharca e queima
## por segundo), "fire" (queima por segundo), "coins" (o primeiro que pisa para, ganha maldição e você ganha ouro).
static func _zone(sim: Sim, k: Ctx, o: Dictionary, x: float, y: float, mul: float, dur_mul: float) -> void:
	var kind := str(o["kind"])
	var z := {"kind": kind, "x": x, "y": y, "r": val(k, o.get("radius"), 3.0), "t": val(k, o.get("duration"), 5.0) * dur_mul,
		"curse": k.curse, "src": k.d.id}
	match kind:
		"web":
			z["applied"] = false
			z["root"] = val(k, o.get("root"))
			if o.has("soak"):
				z["soak"] = val(k, o.get("soak"))
		"oil":
			z["dps"] = val(k, o.get("dps")) * mul
			z["soaked"] = val(k, o.get("soaked"))
		"fire":
			z["dps"] = val(k, o.get("dps")) * mul
		"coins":
			z["applied"] = false
			z["stop"] = val(k, o.get("stop")) * dur_mul
			z["curses"] = int(val(k, o.get("curses"))) + k.curse
			z["gold"] = val(k, o.get("gold"))
		_:
			push_error("CardFxLib: zona desconhecida " + kind)
			return
	sim.zones.append(z)

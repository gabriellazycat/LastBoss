class_name HeroPowers
extends RefCounted
## Motor dos poderes de party (plano 21/11/2026, frente B). Dados em data/hero_powers.json (conta dos numeros no _doc).
##
## ESTADO
##  sim.powers: Array de {"id": String, "level": int (1-3), "cd_left": float (s), "gap_left": float (s)}, na ordem em
##   que foram ganhos (acumulam na run toda, sem teto). Salvo no save v8 (sim/save_game.gd).
##  sim.power_state: Dictionary interno do motor (dano recebido pela party, timers de efeito, aliados, aviso pendente).
##   A HUD NAO precisa le-lo, exceto `power_state["allies"]` (ver ALIADOS).
##
## EVENTOS (K.Ev): POWER_GAINED [x, y, indice em party_powers(), nivel]; POWER_TRIGGER [x, y, indice, 0];
##  POWER_READY [x, y, indice, 0] (a recarga acabou; so poderes de gatilho, nao os de intervalo).
##
## LISTA PARA A HUD: Sim.party_powers() -> HeroPowers.list(sim): Array de {"id","level","cd_left","cd_total","ready",
##  "trigger"} na mesma ordem de sim.powers. Textos: describe(id, level) -> {"id","level","name","desc","cooldown",
##  "trigger"} (name = POWER_<id>, desc = POWER_<id>_d ja com os numeros do nivel; "cooldown" em segundos).
##  Icone: assets/ui/powers/<id>.svg.
##
## OFERTA-AVISO (fila de ofertas, DEPOIS da oferta de carta; duas telas):
##   sim.offers[k] = {"source": "power",
##       "options": [ {"kind": "power", "id": String, "level": int (nivel depois do sorteio),
##                     "prev_level": int (0 = poder novo), "new": bool, "cooldown": float (recarga no nivel novo, s)} ],
##       "powers": list(sim)}      # foto da lista da party JA com o poder novo (o painel mostra os que a party tem)
##  Normalmente 1 opcao (2 se um evento deu "proximo heroi com habilidade a mais"). E so um aviso, como o "give":
##  Sim.choose(qualquer k ou SKIP) fecha sem efeito. A HUD mostra o painel (nome, efeito = describe(id, level).desc,
##  recarga, e a lista `powers`) pausando o jogo (Sim.step ja pausa enquanto offers nao esta vazia).
##
## ALIADOS (ratos/caes de guerra): sim.power_state["allies"] = Array de {"id": "ally_rat"|"war_hound", "x","y","hp",
##  "max","dps","t","tg"}; a HUD/mundo pode desenhar. Nao existe lado aliado no motor de unidades: eles andam e batem aqui.
##
## GATILHOS: 1 poder dispara por vez e, depois de qualquer disparo, todos esperam rules.gap (1,5 s) antes do proximo
## (gap_left). Os de contato (first_enemy, next_creature, next_structure) olham a 5 Hz. Intervalo nao gasta o gap.

const _KEYS_PCT := ["ward_frac", "heal_frac", "hp_frac", "dmg_bonus", "below"]
static var _buf := PackedInt32Array()


static func _st(sim) -> Dictionary:
	var st: Dictionary = sim.power_state
	if st.is_empty():
		st["taken"] = {}        # dano recebido pela party por tipo (Hero.note), desde a ultima queda de party
		st["seen"] = {}         # copia das chaves de reacao ja vistas (fire, projectile, burst)
		st["allies"] = []
		st["gained"] = []       # poderes sorteados na ultima queda de party (viram a oferta-aviso)
		st["bless"] = 0.0       # bencao da Clériga que caiu nesta party
		st["nullify_until"] = -1.0
		st["immune_until"] = -1.0
		st["fire_until"] = -1.0
		st["fire_mult"] = 1.0
		st["buff_until"] = -1.0
		st["buff"] = 0.0
	return st


static func _rules(sim) -> Dictionary:
	return sim.data.power_rules


static func _lv(d: Dictionary, level: int) -> Dictionary:
	var l: Array = d["lv"]
	return l[clampi(level, 1, l.size()) - 1]


static func _cd(d: Dictionary, level: int) -> float:
	var c: Array = d["cooldown"]
	return float(c[clampi(level, 1, c.size()) - 1])


## Dano de referencia da party: golpe do heroi da classe na party atual, sem dividir pelos membros (ver _doc).
static func ref_damage(sim) -> float:
	return float(sim.hero.H["damage"]) * pow(float(sim.data.rules["party"]["step"]), sim.hero.level - 1)


static func _party(sim) -> Array:
	var out: Array = []
	if sim.hero.hp > 0.0:
		out.append(sim.hero)
	for f in sim.followers:
		if f.hp > 0.0:
			out.append(f)
	return out


# ================================================================ ganchos do Sim

## Um membro da party caiu e ainda sobra gente: so guarda a bencao da Clériga (vale na queda da party inteira).
static func on_member_down(sim, pidx: int) -> void:
	var b := float(sim.data.hero_classes.get(sim.party_class(pidx), {}).get("bless_next", 0.0))
	var st := _st(sim)
	st["bless"] = maxf(float(st["bless"]), b)


## Bencao pendente da party que caiu (maior entre os membros, `own` = a do heroi da vez); zera.
static func take_bless(sim, own: float) -> float:
	var st := _st(sim)
	var b := maxf(own, float(st["bless"]))
	st["bless"] = 0.0
	return b


## A party inteira caiu: os poderes recarregam para a party nova, aliados e efeitos somem e o dano da party zera
## (o sorteio do poder novo e feito em learn(), chamado por Sim._learn_ability logo depois).
static func on_party_down(sim) -> void:
	var st := _st(sim)
	st["allies"] = []
	st["nullify_until"] = -1.0
	st["immune_until"] = -1.0
	st["fire_until"] = -1.0
	st["buff_until"] = -1.0
	for p in sim.powers:
		var d: Dictionary = sim.data.hero_powers.get(p["id"], {})
		p["cd_left"] = _cd(d, int(p["level"])) if str(d.get("trigger", "")) == "interval" else 0.0
		p["gap_left"] = 0.0


## Hero.note: soma o dano recebido por tipo na party toda (estilo do jogador, peso do sorteio).
static func note(sim, key: String, v: float) -> void:
	var t: Dictionary = _st(sim)["taken"]
	t[key] = float(t.get(key, 0.0)) + v


## Sorteia o poder da party que chega (novo ou evolucao) e guarda o aviso. Chamado na queda da party (1 vez; 2 se um
## evento deu "proximo heroi com habilidade a mais"). Zera o dano contado da party que caiu.
static func learn(sim) -> void:
	var st := _st(sim)
	var n := 2 if sim.next_extra_ability else 1
	sim.next_extra_ability = false
	for k in n:
		var r := roll(sim)
		if r.is_empty():
			continue
		var idx := -1
		if bool(r["new"]):
			sim.powers.append({"id": r["id"], "level": 1, "cd_left": 0.0, "gap_left": 0.0})
			idx = sim.powers.size() - 1
			var d: Dictionary = sim.data.hero_powers[r["id"]]
			if str(d["trigger"]) == "interval":
				sim.powers[idx]["cd_left"] = _cd(d, 1)
		else:
			for j in sim.powers.size():
				if sim.powers[j]["id"] == r["id"]:
					sim.powers[j]["level"] = int(r["level"])
					idx = j
		var dd: Dictionary = sim.data.hero_powers[r["id"]]
		r["cooldown"] = _cd(dd, int(r["level"]))
		(st["gained"] as Array).append(r)
		sim.emit(K.Ev.POWER_GAINED, sim.hero.x, sim.hero.y, idx, int(r["level"]))
	st["taken"] = {}
	st["seen"] = {}
	var names: Array = []
	for p in sim.powers:
		names.append("%s:%d" % [p["id"], int(p["level"])])
	sim.stats["powers"] = names


## Empilha a oferta-aviso dos poderes sorteados (chamar DEPOIS da oferta de carta).
static func push_offer(sim) -> void:
	var st := _st(sim)
	var g: Array = st["gained"]
	if g.is_empty():
		return
	sim._push_offer("power", g.duplicate(true), {"powers": list(sim)})
	st["gained"] = []


## Novo ou evolucao: {"id","level","prev_level","new","kind":"power"} (vazio se nao ha o que sortear).
static func roll(sim) -> Dictionary:
	var owned := {}
	for p in sim.powers:
		owned[p["id"]] = int(p["level"])
	var max_lv := int(_rules(sim).get("max_level", 3))
	var fresh: Array = []
	var evo: Array = []
	for id in sim.data.power_ids:
		if not owned.has(id):
			fresh.append(id)
		elif int(owned[id]) < max_lv:
			evo.append(id)
	var do_evo := false
	if fresh.is_empty():
		do_evo = true
	elif not evo.is_empty():
		do_evo = sim.rng_offer.randf() < float(_rules(sim).get("evolution_chance", 0.34))
	var pool: Array = evo if do_evo else fresh
	if pool.is_empty():
		return {}
	var id := _pick(sim, pool)
	var prev := int(owned.get(id, 0))
	return {"kind": "power", "id": id, "level": prev + 1, "prev_level": prev, "new": prev == 0}


## Candidatos para previa (Sim._upgrade_options): `n` ids distintos sorteados pelo mesmo peso (novos e evolucoes juntos).
static func options(sim, n: int) -> Array:
	var owned := {}
	for p in sim.powers:
		owned[p["id"]] = int(p["level"])
	var max_lv := int(_rules(sim).get("max_level", 3))
	var pool: Array = []
	for id in sim.data.power_ids:
		if int(owned.get(id, 0)) < max_lv:
			pool.append(id)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var id := _pick(sim, pool)
		out.append(id)
		pool.erase(id)
	return out


static func _weight(sim, d: Dictionary) -> float:
	var tt: Dictionary = _st(sim)["taken"]
	var total := 0.0
	for k in tt:
		total += float(tt[k])
	var share := 0.0
	if total > 0.0:
		for c in d.get("counters", []):
			share += float(tt.get(c, 0.0)) / total
	return float(d.get("weight", 1.0)) * (1.0 + float(_rules(sim).get("counter_gain", 3.0)) * share)


static func _pick(sim, pool: Array) -> String:
	var tot := 0.0
	var ws: Array = []
	for id in pool:
		var w := _weight(sim, sim.data.hero_powers[id])
		ws.append(w)
		tot += w
	var r: float = sim.rng_offer.randf() * tot
	for k in pool.size():
		r -= float(ws[k])
		if r <= 0.0 or k == pool.size() - 1:
			return str(pool[k])
	return str(pool[0])


# ================================================================ ganchos do heroi

## Hero.take_damage: um feitico vai acertar a party. true = anulado pelo poder `spell_ward` (janela de `window` s).
static func spell_hit(sim) -> bool:
	var st := _st(sim)
	if sim.t < float(st["nullify_until"]):
		return true
	for i in sim.powers.size():
		var p: Dictionary = sim.powers[i]
		var d: Dictionary = sim.data.hero_powers.get(p["id"], {})
		if str(d.get("trigger", "")) != "next_spell" or float(p["cd_left"]) > 0.0 or float(p["gap_left"]) > 0.0:
			continue
		var l := _lv(d, int(p["level"]))
		st["nullify_until"] = sim.t + float(l["window"])
		if float(l["heal_frac"]) > 0.0:
			for h in _party(sim):
				h.heal(h.max_hp() * float(l["heal_frac"]))
		_fired(sim, i, sim.hero.x, sim.hero.y)
		return true
	return false


## Multiplicador do dano de fogo que a party recebe (fire_ward).
static func fire_mult(sim) -> float:
	if sim.power_state.is_empty():
		return 1.0
	var st: Dictionary = sim.power_state
	return float(st["fire_mult"]) if sim.t < float(st["fire_until"]) else 1.0


## Multiplicador do dano da party (war_cry).
static func dmg_mult(sim) -> float:
	if sim.power_state.is_empty():
		return 1.0
	var st: Dictionary = sim.power_state
	return 1.0 + float(st["buff"]) if sim.t < float(st["buff_until"]) else 1.0


# ================================================================ passo

static func tick(sim) -> void:
	if sim.powers.is_empty():
		return
	var st := _st(sim)
	var dt: float = sim.dt
	var party := _party(sim)
	if party.is_empty():
		return
	for i in sim.powers.size():
		var p: Dictionary = sim.powers[i]
		var was := float(p["cd_left"])
		p["cd_left"] = maxf(0.0, was - dt)
		p["gap_left"] = maxf(0.0, float(p["gap_left"]) - dt)
		if was > 0.0 and float(p["cd_left"]) <= 0.0:
			var d0: Dictionary = sim.data.hero_powers.get(p["id"], {})
			if str(d0.get("trigger", "")) != "interval":
				sim.emit(K.Ev.POWER_READY, sim.hero.x, sim.hero.y, i, 0)
	# Imunidade a controle (iron_will): limpa o que a party sofreria neste passo.
	if sim.t < float(st["immune_until"]):
		for h in party:
			h.slow_t = 0.0
			h.root_t = 0.0
			h.fear_t = 0.0
			h.petrify_t = 0.0
			h.kb_t = 0.0
	# Reacoes lidas do dano recebido neste passo.
	var react := {}
	var tk: Dictionary = st["taken"]
	var seen: Dictionary = st["seen"]
	for k in ["fire", "projectile", "burst"]:
		react[k] = float(tk.get(k, 0.0)) - float(seen.get(k, 0.0))
		seen[k] = float(tk.get(k, 0.0))
	var scan: bool = sim.tick % 4 == 0
	var ctx := {}
	var interval_ready: Array = []
	for i in sim.powers.size():
		var p: Dictionary = sim.powers[i]
		var d: Dictionary = sim.data.hero_powers.get(p["id"], {})
		if d.is_empty() or float(p["cd_left"]) > 0.0:
			continue
		var trig := str(d["trigger"])
		if trig == "interval":
			interval_ready.append(i)
			continue
		if float(p["gap_left"]) > 0.0 or trig == "next_spell":
			continue
		var l := _lv(d, int(p["level"]))
		var did := false
		match trig:
			"first_enemy", "next_creature", "next_structure":
				if not scan:
					continue
				did = _fire_contact(sim, i, d, l, ctx, trig, party)
			"on_hit_taken":
				did = _fire_reaction(sim, i, d, l, react, party)
		if did:
			break   # 1 poder por vez; _fired ja armou o gap de todos
	for i in interval_ready:
		_fire_interval(sim, i, party)
	_allies(sim, st, party)


## Poder disparou: recarga dele, gap de todos, evento.
static func _fired(sim, i: int, x: float, y: float) -> void:
	var p: Dictionary = sim.powers[i]
	var d: Dictionary = sim.data.hero_powers[p["id"]]
	p["cd_left"] = _cd(d, int(p["level"]))
	var gap := float(_rules(sim).get("gap", 1.5))
	for q in sim.powers:
		q["gap_left"] = gap
	sim.emit(K.Ev.POWER_TRIGGER, x, y, i, 0)


# ---------------------------------------------------------------- contato

## Unidade seu mais perto de um heroi da party, ao alcance do golpe (estrutura ou criatura, vida maxima minima).
static func _contact(sim, structure: bool, min_hp: float, party: Array) -> Dictionary:
	var U = sim.units
	var reach := float(_rules(sim).get("contact_reach", 1.0))
	var best := {}
	var bd := 1.0e9
	for h in party:
		var r: float = float(h.H["attack_range"]) + h.radius + reach
		U.within(h.x, h.y, r + 1.0, _buf)
		for i in _buf:
			if (sim.data.cards[U.def[i]].is_structure) != structure or (U.flags[i] & K.F_STONE) != 0:
				continue
			if U.max_hp[i] < min_hp or U.hp[i] <= 0.0:
				continue
			var dd: float = Vector2(U.px[i] - h.x, U.py[i] - h.y).length() - U.rad[i]
			if dd <= r and dd < bd:
				bd = dd
				best = {"i": int(i), "h": h}
	return best


static func _fire_contact(sim, pi: int, d: Dictionary, l: Dictionary, ctx: Dictionary, trig: String, party: Array) -> bool:
	var id := str(d["id"])
	var key := trig
	var min_hp := 0.0
	if id == "titan_blow":
		min_hp = float(l["big_hp"])
		key = "titan"
	if not ctx.has(key):
		ctx[key] = _contact(sim, trig == "next_structure", min_hp, party)
	var c: Dictionary = ctx[key]
	if c.is_empty():
		return false
	var U = sim.units
	var ti: int = c["i"]
	var h = c["h"]
	var D := ref_damage(sim)
	var tx: float = U.px[ti]
	var ty: float = U.py[ti]
	match id:
		"fire_burst":
			_aoe(sim, tx, ty, float(l["radius"]), float(l["dmg_mult"]) * D)
		"whirlwind":
			_aoe(sim, h.x, h.y, float(l["radius"]), float(l["dmg_mult"]) * D)
			sim.emit(K.Ev.SPIN, h.x, h.y, float(l["radius"]), 0)
		"holy_nova":
			_aoe(sim, h.x, h.y, float(l["radius"]), float(l["dmg_mult"]) * D, float(l["holy_mult"]), 1.0)
		"shockwave":
			_aoe(sim, h.x, h.y, float(l["radius"]), float(l["dmg_mult"]) * D, 1.0, float(l["struct_mult"]))
		"war_cry":
			for m in party:
				m.ward += m.max_hp() * float(l["ward_frac"])
			var st := _st(sim)
			st["buff"] = float(l["dmg_bonus"])
			st["buff_until"] = sim.t + float(l["dur"])
			sim.emit(K.Ev.ABILITY, h.x, h.y, 0, 0)
		"chain_lightning":
			_chain(sim, h, int(l["targets"]), float(l["range"]), float(l["dmg_mult"]) * D)
		"smite":
			sim.hero_hits_unit(ti, float(l["dmg_mult"]) * D)
			sim.emit(K.Ev.EXPLOSION, tx, ty, 1.5, 2)
		"slay_next":
			_slay(sim, ti, l, D)
		"titan_blow":
			var dmg := minf(U.max_hp[ti] * float(l["hp_frac"]), float(l["cap_mult"]) * D)
			sim.hero_hits_unit(ti, dmg)
			sim.emit(K.Ev.EXPLOSION, tx, ty, 1.5, 2)
		"soul_drain":
			sim.hero_hits_unit(ti, float(l["dmg_mult"]) * D)
			for m in party:
				m.heal(m.max_hp() * float(l["heal_frac"]))
		"structure_breaker":
			if U.max_hp[ti] <= float(l["kill_hp"]):
				sim.kill_unit(ti, K.Death.HERO)
			else:
				sim.hero_hits_unit(ti, U.max_hp[ti] * float(l["hp_frac"]))
			sim.emit(K.Ev.EXPLOSION, tx, ty, 1.5, 2)
		_:
			return false
	_fired(sim, pi, h.x, h.y)
	return true


## Dano em area ao redor de (x, y); `holy` multiplica em morto-vivo/sombrio, `structure` em construto/estrutura.
static func _aoe(sim, x: float, y: float, r: float, dmg: float, holy := 1.0, structure := 1.0) -> void:
	var U = sim.units
	var ids: PackedInt32Array = U.within(x, y, r, PackedInt32Array()).duplicate()
	for i in ids:
		if U.alive[i] == 0:
			continue
		var m := 1.0
		if holy > 1.0 and (U.tags[i] & (K.TAG_UNDEAD | K.TAG_SHADOW)) != 0:
			m = holy
		if structure > 1.0 and ((U.tags[i] & K.TAG_CONSTRUCT) != 0 or sim.data.cards[U.def[i]].is_structure):
			m = structure
		sim.hero_hits_unit(i, dmg * m)
	sim.emit(K.Ev.EXPLOSION, x, y, r, 2)


## Raio: acerta as `n` criaturas mais proximas do heroi dentro de `rng`.
static func _chain(sim, h, n: int, rng: float, dmg: float) -> void:
	var U = sim.units
	var ids: PackedInt32Array = U.within(h.x, h.y, rng, PackedInt32Array()).duplicate()
	var cand: Array = []
	for i in ids:
		if not sim.data.cards[U.def[i]].is_structure and (U.flags[i] & K.F_STONE) == 0:
			cand.append([Vector2(U.px[i] - h.x, U.py[i] - h.y).length(), int(i)])
	cand.sort_custom(func(a, b): return a[0] < b[0])
	for k in mini(n, cand.size()):
		var i: int = cand[k][1]
		if U.alive[i] == 1:
			sim.emit(K.Ev.EXPLOSION, U.px[i], U.py[i], 1.2, 2)
			sim.hero_hits_unit(i, dmg)


## Execucao: mata a criatura de ate kill_hp_mult x D de vida maxima; as maiores levam hp_frac da vida. `chain` repete
## na criatura mais proxima ainda viva (raio 8).
static func _slay(sim, ti: int, l: Dictionary, D: float) -> void:
	var U = sim.units
	var done: Array = []
	var cur := ti
	for step in 1 + int(l["chain"]):
		if cur < 0 or U.alive[cur] == 0:
			break
		done.append(cur)
		var cx: float = U.px[cur]
		var cy: float = U.py[cur]
		if U.max_hp[cur] <= float(l["kill_hp_mult"]) * D:
			sim.kill_unit(cur, K.Death.HERO)
		else:
			sim.hero_hits_unit(cur, U.max_hp[cur] * float(l["hp_frac"]))
		sim.emit(K.Ev.EXPLOSION, cx, cy, 1.5, 2)
		var nxt := -1
		var bd := 8.0
		for j in U.within(cx, cy, 8.0, PackedInt32Array()).duplicate():
			if done.has(int(j)) or U.alive[j] == 0 or sim.data.cards[U.def[j]].is_structure or (U.flags[j] & K.F_STONE) != 0:
				continue
			var dj := Vector2(U.px[j] - cx, U.py[j] - cy).length()
			if dj < bd:
				bd = dj
				nxt = int(j)
		cur = nxt


# ---------------------------------------------------------------- reacoes e intervalo

static func _fire_reaction(sim, pi: int, d: Dictionary, l: Dictionary, react: Dictionary, party: Array) -> bool:
	var id := str(d["id"])
	var st := _st(sim)
	var h = sim.hero
	match str(d.get("cond", "")):
		"curse":
			var any := false
			for m in party:
				if m.curses > 0:
					any = true
			if not any:
				return false
			for m in party:
				m.curses = 0
				if float(l["heal_frac"]) > 0.0:
					m.heal(m.max_hp() * float(l["heal_frac"]))
		"low_hp":
			var did := false
			for m in party:
				if m.hp / maxf(1.0, m.max_hp()) < float(l["below"]):
					m.heal(m.max_hp() * float(l["heal_frac"]))
					h = m
					did = true
			if not did:
				return false
		"control":
			var any2 := false
			for m in party:
				if m.slow_t > 0.0 or m.root_t > 0.0 or m.fear_t > 0.0 or m.petrify_t > 0.0 or m.kb_t > 0.0:
					any2 = true
			if not any2:
				return false
			st["immune_until"] = sim.t + float(l["immune_s"])
			for m in party:
				m.slow_t = 0.0
				m.root_t = 0.0
				m.fear_t = 0.0
				m.petrify_t = 0.0
				m.kb_t = 0.0
		"fire":
			if float(react["fire"]) <= 0.0:
				return false
			st["fire_until"] = sim.t + float(l["dur"])
			st["fire_mult"] = float(l["taken_mult"])
		"projectile":
			if float(react["projectile"]) <= 0.0:
				return false
			for m in party:
				m.ward += m.max_hp() * float(l["ward_frac"])
		"burst":
			if float(react["burst"]) <= 0.0:
				return false
			_aoe(sim, h.x, h.y, float(l["radius"]), float(l["dmg_mult"]) * ref_damage(sim))
		_:
			return false
	_fired(sim, pi, h.x, h.y)
	return true


static func _fire_interval(sim, pi: int, party: Array) -> void:
	var p: Dictionary = sim.powers[pi]
	var d: Dictionary = sim.data.hero_powers[p["id"]]
	var l := _lv(d, int(p["level"]))
	var id := str(d["id"])
	var st := _st(sim)
	if id == "field_medic":
		var hurt := false
		for m in party:
			if m.hp < m.max_hp():
				hurt = true
		if not hurt:
			return
		for m in party:
			m.heal(m.max_hp() * float(l["heal_frac"]))
		sim.emit(K.Ev.POWER_TRIGGER, sim.hero.x, sim.hero.y, pi, 0)
	elif id == "ally_rat" or id == "war_hound":
		var n := 0
		for a in st["allies"]:
			if a["id"] == id:
				n += 1
		if n >= int(l["max"]):
			return   # cheio: fica pronto, nasce outro quando um cair
		var ang := float(sim.tick) * 0.7
		(st["allies"] as Array).append({"id": id, "x": sim.hero.x + cos(ang) * 1.5, "y": sim.hero.y + sin(ang) * 1.5,
			"hp": float(l["hp"]), "max": float(l["hp"]), "dps": float(l["dps_mult"]) * ref_damage(sim), "t": 0.0, "tg": -1})
		sim.emit(K.Ev.POWER_TRIGGER, sim.hero.x, sim.hero.y, pi, 1)
	p["cd_left"] = _cd(d, int(p["level"]))


## Aliados: seguem o heroi da vez, vao na criatura mais proxima (ate 10), batem 1x/s e levam metade do dano por segundo
## dos inimigos colados neles (5 Hz).
static func _allies(sim, st: Dictionary, party: Array) -> void:
	var list: Array = st["allies"]
	if list.is_empty():
		return
	var U = sim.units
	var dt: float = sim.dt
	var slow: bool = sim.tick % 4 == 0
	var lead = sim.hero
	var k := list.size() - 1
	while k >= 0:
		var a: Dictionary = list[k]
		var spd := 6.0 if a["id"] == "war_hound" else 4.5
		if slow:
			# alvo: criatura viva mais proxima
			var tg := int(a["tg"])
			if tg < 0 or tg >= U.hi or U.alive[tg] == 0:
				tg = -1
				var bd := 100.0
				for j in U.within(a["x"], a["y"], 10.0, PackedInt32Array()):
					if sim.data.cards[U.def[j]].is_structure or (U.flags[j] & K.F_STONE) != 0:
						continue
					var dj := Vector2(U.px[j] - a["x"], U.py[j] - a["y"]).length()
					if dj < bd:
						bd = dj
						tg = int(j)
			a["tg"] = tg
			# dano sofrido: inimigos colados (metade do dano por segundo deles)
			var dps_in := 0.0
			for j in U.within(a["x"], a["y"], 1.6, PackedInt32Array()):
				if not sim.data.cards[U.def[j]].is_structure and U.dmg[j] > 0.0:
					dps_in += U.dmg[j] / maxf(0.1, U.atk_int[j])
			a["hp"] = float(a["hp"]) - dps_in * 0.5 * dt * 4.0
			if float(a["hp"]) <= 0.0:
				list.remove_at(k)
				k -= 1
				continue
			# golpe
			a["t"] = float(a["t"]) - dt * 4.0
			var ti := int(a["tg"])
			if ti >= 0 and float(a["t"]) <= 0.0:
				if Vector2(U.px[ti] - a["x"], U.py[ti] - a["y"]).length() <= 1.3 + U.rad[ti]:
					a["t"] = 1.0
					sim.hero_hits_unit(ti, float(a["dps"]))
		# movimento
		var goal := Vector2(lead.x, lead.y)
		var stop := 2.5
		var ti2 := int(a["tg"])
		if ti2 >= 0 and U.alive[ti2] == 1:
			goal = Vector2(U.px[ti2], U.py[ti2])
			stop = 1.0
		var to := goal - Vector2(a["x"], a["y"])
		var dist := to.length()
		if dist > 40.0:
			a["x"] = lead.x
			a["y"] = lead.y
		elif dist > stop:
			var stepv := minf(dist - stop, spd * dt)
			a["x"] = float(a["x"]) + to.x / dist * stepv
			a["y"] = float(a["y"]) + to.y / dist * stepv
		k -= 1


# ================================================================ HUD

## Lista para a HUD (formato no topo).
static func list(sim) -> Array:
	var out: Array = []
	for p in sim.powers:
		var d: Dictionary = sim.data.hero_powers.get(p["id"], {})
		var cd_total := _cd(d, int(p["level"])) if not d.is_empty() else 1.0
		out.append({"id": p["id"], "level": p["level"], "cd_left": float(p["cd_left"]), "cd_total": cd_total,
			"ready": float(p["cd_left"]) <= 0.0, "trigger": str(d.get("trigger", ""))})
	return out


## Parametros do nivel para o texto (`{chave}` em POWER_<id>_d): os do lv, `*_pct` das fracoes, `cd` e `taken_pct`.
static func params(d: Dictionary, level: int) -> Dictionary:
	var out: Dictionary = _lv(d, level).duplicate()
	for k in _KEYS_PCT:
		if out.has(k):
			out[k + "_pct"] = int(round(float(out[k]) * 100.0))
	if out.has("taken_mult"):
		out["taken_pct"] = int(round((1.0 - float(out["taken_mult"])) * 100.0))
	out["cd"] = int(_cd(d, level))
	return out


static func describe(sim, id: String, level: int) -> Dictionary:
	var d: Dictionary = sim.data.hero_powers.get(id, {})
	if d.is_empty():
		return {}
	return {"id": id, "level": level, "name": TranslationServer.translate("POWER_" + id),
		"desc": TranslationServer.translate("POWER_" + id + "_d").format(params(d, level)),
		"cooldown": _cd(d, level), "trigger": str(d["trigger"])}

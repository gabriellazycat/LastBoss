class_name Sim
extends RefCounted
## Simulação completa de uma run. Lógica pura, passo fixo, determinística pela semente.
## Entrada só por comandos (play, sacrifice, choose, teleport); saída: estado + eventos + stats.

class CardInst:
	var def: CardDef
	var mods := 0
	var first_mod := 0      # bit do primeiro modificador ganho (dono do papel da carta)
	var uid := 0
	var level := 1

	func has_mod(m: int) -> bool:
		return (mods & m) != 0


var data: GameData
var R: Dictionary
var rng := RandomNumberGenerator.new()
var run_seed := 0
var dt := 0.05
var tick := 0
var t := 0.0
var ai_period := 4
var phase: int = K.Phase.ROAD
var result: int = K.Result.NONE
var units := SimUnits.new()
var hero := SimHero.new()
var followers: Array = []          # fase de grupo: heróis que andam junto do da vez
var revived: Array = []            # índices da fila já levantados uma vez
var hit_hero: SimHero = null       # herói que a unidade da vez acerta (null = o da vez)
var group_falls := 0
var road := SimRoad.new()
var arena := SimArena.new()
var zones: Array = []
var events: Array = []
var record_events := false
var pause_on_offer := true

var deck_id := ""
var deck_rules: Dictionary = {}
var elixir := 0.0
var elixir_max := 10.0
var hand: Array = []
var queue: Array = []
var cards: Array = []
var card_of_uid: Dictionary = {}
var hand_size := 5
## Teto da mão (as teclas vão de 1 a 9): compras extras (Pacto Sombrio, Biblioteca) param aqui (rodada 09/11/2026).
const HAND_MAX := 9
var next_uid := 1
var party_idx := 0                 # herói da fila (0 a size-1); o nível dele é party_idx + 1
var campaign_phase := 1            # fase da campanha (data/campaign.json); 1 = a run clássica de 7 Escudeiros
var phase_cfg: Dictionary = {}
var party: Array = []              # classe de cada herói da fila
var phase_hp_mult := 1.0
var phase_dmg_mult := 1.0
var gate_pos := Vector2.ZERO       # portão da arena, onde o herói seguinte entra
var player_level := 1
var player_xp := 0.0
var offers: Array = []
var lair: Dictionary = {}       # id -> cópias jogadas (limite de stack)
var lair_val: Dictionary = {}   # id -> soma do efeito das cópias, já com o nível de cada uma
var unlocked: Array = []        # cartas que as ofertas podem sortear (vazio = todas)
var burn_t := 0.0               # Arqueiros N3: herói em chamas
var burn_dps := 0.0
var burn_src := "skeleton_archers"
# Famílias de cartas (rodada autônoma de 09/11/2026): estados dos combos.
var rally_until := -100.0       # Chamado do Bando: até quando o bando corre e bate mais
var rally_dmg := 0.0
var rally_spd := 0.0
var harvest_until := -100.0     # Colheita de Almas: até quando cada morte sua devolve elixir
var harvest_elixir := 0.0
var mark_until := -100.0        # Marca Sombria: até quando feitiços machucam mais o herói
var mark_bonus := 0.0
var spell_times: Array = []     # instantes dos últimos feitiços jogados (Sequência)
var last_spell_id := ""         # Eco Sombrio repete este feitiço
var last_spell_lv := 1
## Disputa do local em andamento (rodada 09/11/2026): o herói para no local até ela acabar.
## {"li", "type", "t", "window", "progress", "goal"}; vazio = nenhuma.
var contest: Dictionary = {}
var act := 0                    # ato atual (0 a acts-1); a arena vem depois do último
var act_pending := false        # fim de ato: espera a escolha da relíquia para começar o próximo
var relics: Array = []          # relíquias do covil (ids)
var rfx: Dictionary = {}        # soma dos fx das relíquias (refeita ao ganhar e ao carregar)
var relic_deaths := 0           # mortes contadas para a Coroa de Ossos
var free_card_t := -100.0       # Olho Vigilante: até quando a próxima carta sai de graça
var next_hp_mult := 1.0         # eventos: vida do próximo herói
var next_extra_ability := false # eventos: o próximo herói chega com uma habilidade a mais
var boss_hp_mult := 1.0         # eventos: vida das partes do chefe na arena
var events_seen: Array = []     # eventos de texto já sorteados nesta run
var gold := 0.0                 # ouro da run (dano no herói e disputas vencidas); gasto nas lojas
var shop_removes := 0           # remoções compradas na run (cada uma encarece a próxima)
var route_wait := false         # o herói chegou a uma bifurcação sem ramo escolhido: o jogo espera a escolha
var auto_route := false         # sem escolha, segue o primeiro ramo em vez de esperar (testes que não jogam a rota)
var sac_elixir_t := -100.0      # último sacrifício que rendeu elixir
var contract: Dictionary = {}
var contract_next := 0.0
var last_teleport_t := -100.0
var ritual_mult := 1.0
var act_elixir_bonus := 0.0     # eventos: elixir máximo a mais até o fim do ato (Altar Profano)
var tax_cards := 0              # eventos: quantas das próximas cartas custam `tax_add` a mais
var tax_add := 0
var dead_by_def := PackedInt32Array()
var stats: Dictionary = {}
var tmp := PackedInt32Array()


## `deck` é o Pacto (regras); `card_list` é o deck montado na coleção (vazio = deck pronto do Pacto);
## `unlocked_` limita as ofertas às cartas desbloqueadas (vazio = todas).
func setup(d: GameData, seed_: int, deck: String, card_list: Array = [], unlocked_: Array = [], phase_n := 1) -> void:
	data = d
	R = d.rules
	campaign_phase = phase_n
	phase_cfg = d.phase(phase_n)
	party = phase_cfg.get("party", []).duplicate()
	if party.is_empty():
		for k in int(R["party"]["size"]):
			party.append("escudeiro")
	phase_hp_mult = float(phase_cfg.get("hp_mult", 1.0))
	# Ajuste fino por pacto dentro da fase (10/11/2026): cada pacto tem contras diferentes em cada fase.
	phase_hp_mult *= float(phase_cfg.get("pact_hp", {}).get(deck, 1.0))
	phase_dmg_mult = float(phase_cfg.get("damage_mult", 1.0))
	run_seed = seed_
	rng.seed = seed_
	dt = R["sim"]["dt"]
	ai_period = maxi(1, int(round(1.0 / dt / float(R["sim"]["danger_hz"]))))
	road.generate(rng, R, _act_cfg(0))
	units.setup(self, int(R["sim"]["max_units"]))
	var dk := d.deck(deck)
	deck_id = dk["id"]
	deck_rules = dk["rules"]
	hero.setup(self)
	hand_size = int(deck_rules.get("hand_size", R["hand_size"]))
	elixir = float(deck_rules.get("elixir_start", R["elixir"]["start"]))
	elixir_max = R["elixir"]["max"]
	dead_by_def.resize(d.cards.size())
	stats = {"seed": run_seed, "deck": deck_id, "result": "none", "t_end": 0.0, "arena_t": -1.0,
		"heroes_fallen": 0, "hero_level_arena": 0, "player_level_arena": 0, "hero_level": 1, "player_level": 1,
		"waste_s": 0.0, "offered": {}, "picked": {}, "played": {}, "dmg_by_card": {}, "deck_final": [],
		"upgrades": [], "shrines_won": 0, "shrines_lost": 0, "contracts_ok": 0, "contracts_fail": 0,
		"parts_lost": 0, "kills": 0, "units_peak": 0, "teleports": 0, "sacrifices": 0, "shield_breaks": 0,
		"route_len": 0.0, "hero_hp_arena": 0.0, "locs_visited": 0, "locs_won": 0, "locs_lost": 0,
		"skipped": 0, "card_levels": 0, "gold_earned": 0.0, "gold_spent": 0, "shop_buys": 0, "route": {},
		"act_t": [], "relics": [], "event_picks": {}, "contests": {}}
	unlocked = unlocked_.duplicate()
	var list: Array = (card_list if card_list.size() > 0 else dk["cards"]).duplicate()
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmpc = list[i]
		list[i] = list[j]
		list[j] = tmpc
	for id in list:
		queue.append(_new_inst(d.card(id)))
	for i in hand_size:
		hand.append(queue.pop_front() if queue.size() > 0 else null)
	var fa: Array = R["contracts"]["first_at"]
	contract_next = rng.randf_range(fa[0], fa[1])


func acts() -> int:
	return int(phase_cfg.get("acts", R.get("run", {}).get("acts", 1)))


func party_size() -> int:
	return party.size()


func party_class(i: int) -> String:
	return str(party[clampi(i, 0, party.size() - 1)]) if party.size() > 0 else "escudeiro"


func _act_cfg(k: int) -> Dictionary:
	var A: Array = R.get("acts", [])
	return A[mini(k, A.size() - 1)].get("road", {}) if A.size() > 0 else {}


func _new_inst(c: CardDef) -> CardInst:
	var ci := CardInst.new()
	ci.def = c
	ci.uid = next_uid
	next_uid += 1
	cards.append(ci)
	card_of_uid[ci.uid] = c.id
	return ci


func emit(k: int, x: float, y: float, v: float, e: int) -> void:
	if record_events:
		events.append([k, x, y, v, e])


# ================================================================ passo

func step() -> void:
	_refill_hand()
	if phase == K.Phase.OVER:
		return
	if act_pending:
		# Fim de ato: o mundo para até a relíquia ser escolhida (também sem pausa, para os bots).
		if offers.is_empty():
			_next_act()
		return
	if pause_on_offer and (offers.size() > 0 or route_wait):
		return
	tick += 1
	t += dt
	_elixir()
	hero.update(dt)
	for f in followers:
		f.update(dt)
		_follow(f)
	if tick % 4 == 0:
		units.apply_auras()
	units.update(dt)
	if tick % 2 == 0:
		units.separate()
	if units.count > stats["units_peak"]:
		stats["units_peak"] = units.count
	_zones()
	_burn()
	if phase == K.Phase.ROAD:
		_road()
	elif phase == K.Phase.ARENA:
		arena.update(dt)
	_contract()
	_check_end()


func _elixir() -> void:
	var rate := 1.0 / float(R["elixir"]["seconds_per_point"])
	rate *= 1.0 + float(lair_val.get("soul_collector", 0.0))
	rate *= ritual_mult
	rate *= float(deck_rules.get("elixir_mult", 1.0))
	if phase == K.Phase.ARENA and arena.part_alive("head"):
		rate *= float(R["arena"]["elixir_mult_head"])
	rate *= 1.0 + overtime() * float(R["arena"].get("overtime_elixir", 0.0))
	elixir += rate * dt
	if elixir >= elixir_max:
		elixir = elixir_max
		stats["waste_s"] += dt


func _road() -> void:
	ritual_mult = 1.0
	if not road.complete and hero.s >= road.length() - float(R["road"]["fork_decision_distance"]):
		var e := road.next_edge()
		if e < 0:
			# Bifurcação sem plano: a escolha vem depois do local do nó. Enquanto ele não acaba, o herói
			# anda até o fim da rota decidida (o próprio nó) e espera lá.
			if _head_busy():
				pass
			elif pause_on_offer and not auto_route:
				route_wait = true
				return
			else:
				e = road.nodes[road.head]["out"][0]
		if e >= 0:
			route_wait = false
			road.advance(e)
	if road.complete and hero.s >= road.length() - 1.5 and contest.is_empty():
		_end_act()
		return
	var hp_ := Vector2(hero.x, hero.y)
	if contest.is_empty():
		for li in road.locations.size():
			var loc: Dictionary = road.locations[li]
			if loc["state"] != SimRoad.LocState.ACTIVE or loc["entered"]:
				continue
			if hp_.distance_to(loc["pos"]) <= loc["r"] and road.is_on_route(loc):
				_arrive(li)
				break
	_contest_tick()


## O nó no fim da rota decidida ainda tem algo a resolver: o local, a disputa ou uma oferta aberta.
func _head_busy() -> bool:
	if contest.size() > 0 or offers.size() > 0:
		return true
	var li: int = road.nodes[road.head]["loc"]
	return li >= 0 and road.locations[li]["state"] == SimRoad.LocState.ACTIVE and road.is_on_route(road.locations[li])


## O herói chegou ao local li. Loja e evento abrem na hora; os outros começam uma disputa sustentada.
func _arrive(li: int) -> void:
	var loc: Dictionary = road.locations[li]
	var ty: String = loc["type"]
	loc["entered"] = true
	stats["locs_visited"] += 1
	var rt: Dictionary = stats["route"]
	rt[ty] = int(rt.get(ty, 0)) + 1
	emit(K.Ev.LOCATION, hero.x, hero.y, li, 0)
	var p: Vector2 = loc["pos"]
	# Incêndio: o local marcado pega fogo quando o herói chega.
	if loc.get("burn", false):
		var bf: Dictionary = data.card("burn_village").fx
		zones.append({"kind": "fire", "x": p.x, "y": p.y, "r": loc["r"] + 1.0, "t": float(loc["burn_s"]),
			"dps": float(loc["burn_dps"]), "src": "burn_village"})
		emit(K.Ev.EXPLOSION, p.x, p.y, float(bf.get("radius_fx", 4.0)), 1)
	var L: Dictionary = R["locations"]
	match ty:
		"shop":
			loc["state"] = SimRoad.LocState.USED
			_open_shop()
			return
		"event":
			loc["state"] = SimRoad.LocState.USED
			_offer_event()
			return
	var P: Dictionary = L[ty]
	var wmult := 1.0 + rv("contest_window")
	contest = {"li": li, "type": ty, "t": 0.0, "progress": 0.0, "goal": 1.0, "window": float(P.get("window", 15.0)) * wmult}
	match ty:
		"ritual":
			contest["goal"] = float(P["kills"])
		"shrine":
			contest["goal"] = float(P["hold_s"])
		"tavern":
			var n := int(P["houses"])
			var houses: Array = []
			var a0 := rng.randf() * TAU
			for k in n:
				var a := a0 + TAU * k / n
				var hp0 := float(P["house_hp"])
				houses.append({"x": p.x + cos(a) * float(P["house_ring"]), "y": p.y + sin(a) * float(P["house_ring"]), "hp": hp0, "max_hp": hp0})
			loc["houses"] = houses
			contest["goal"] = float(n)
		"bridge":
			contest["window"] = float(P["duration"]) * wmult
			contest["goal"] = float(P["win_damage"])
			hero.tavern_t = contest["window"]
		"fountain":
			contest["window"] = float(P["drink_s"]) * wmult
			contest["goal"] = float(P["interrupt_damage"])
			hero.drink_t = contest["window"]
	hero.hold = true
	hero.hold_x = p.x
	hero.hold_y = p.y
	emit(K.Ev.CONTEST, p.x, p.y, li, 0)


func _contest_tick() -> void:
	if contest.is_empty():
		return
	var loc: Dictionary = road.locations[int(contest["li"])]
	var p: Vector2 = loc["pos"]
	contest["t"] += dt
	match str(contest["type"]):
		"ritual":
			ritual_mult = float(R["locations"]["ritual"]["elixir_mult"])
			if contract.size() > 0 and contract["goal"]["kind"] == "ritual_time":
				contract["progress"] += dt
		"shrine":
			if units.any_fighter_within(p.x, p.y, loc["r"]):
				contest["progress"] += dt
		"tavern":
			var down := 0
			for h in loc["houses"]:
				if float(h["hp"]) <= 0.0:
					down += 1
			contest["progress"] = float(down)
		"fountain":
			# Medo, raiz, empurrão ou petrificação durante o gole interrompem na hora.
			if hero.fear_t > 0.0 or hero.root_t > 0.0 or hero.kb_t > 0.0 or hero.petrify_t > 0.0:
				contest["progress"] = contest["goal"]
	if float(contest["progress"]) >= float(contest["goal"]):
		_resolve_contest(true)
	elif float(contest["t"]) >= float(contest["window"]):
		_resolve_contest(false)


## Fim da disputa: vencer dá a recompensa do local (1 entre 3); perder não dá nada.
func _resolve_contest(won: bool) -> void:
	var c := contest
	contest = {}
	var li := int(c["li"])
	var loc: Dictionary = road.locations[li]
	var ty: String = c["type"]
	var p: Vector2 = loc["pos"]
	loc["state"] = SimRoad.LocState.WON if won else SimRoad.LocState.USED
	hero.hold = false
	hero.drink_t = 0.0
	hero.tavern_t = 0.0
	var cs: Dictionary = stats["contests"]
	var row: Array = cs.get(ty, [0, 0])
	row[0 if won else 1] += 1
	cs[ty] = row
	if ty == "shrine":
		stats["shrines_won" if won else "shrines_lost"] += 1
		emit(K.Ev.SHRINE, p.x, p.y, 1 if won else 0, li)
	emit(K.Ev.CONTEST, p.x, p.y, li, 1 if won else -1)
	if not won:
		stats["locs_lost"] += 1
		if ty == "fountain":
			hero.heal(hero.max_hp() * float(R["locations"]["fountain"]["heal"]))
		return
	elixir = minf(elixir_max, elixir + rv("contest_elixir"))
	_offer_location(ty, true)


func _burn() -> void:
	for f in followers:
		if f.burn_t > 0.0:
			f.burn_t -= dt
			hit_hero = f
			damage_hero(f.burn_dps * dt, f.x, f.y, K.TAG_FIRE, SimHero.DMG_AREA, "torch")
			hit_hero = null
	if burn_t <= 0.0:
		return
	burn_t -= dt
	damage_hero(burn_dps * dt, hero.x, hero.y, K.TAG_FIRE, SimHero.DMG_AREA, burn_src)


func _own_units_near(x: float, y: float, r: float) -> bool:
	return units.any_within(x, y, r)


## Monstro seu acertou a casa k da Taverna em disputa.
func damage_house(k: int, dmg: float) -> void:
	if contest.is_empty() or contest["type"] != "tavern":
		return
	var loc: Dictionary = road.locations[int(contest["li"])]
	var h: Dictionary = loc["houses"][k]
	if float(h["hp"]) <= 0.0:
		return
	h["hp"] = float(h["hp"]) - dmg
	if float(h["hp"]) <= 0.0:
		h["hp"] = 0.0
		emit(K.Ev.EXPLOSION, h["x"], h["y"], 3.0, 2)


## Casas vivas da Taverna em disputa (para as unidades e o herói); vazio fora dela.
func live_houses() -> Array:
	if contest.is_empty() or contest["type"] != "tavern":
		return []
	var out: Array = []
	var hs: Array = road.locations[int(contest["li"])]["houses"]
	for k in hs.size():
		if float(hs[k]["hp"]) > 0.0:
			out.append(k)
	return out


func house_pos(k: int) -> Vector2:
	var h: Dictionary = road.locations[int(contest["li"])]["houses"][k]
	return Vector2(h["x"], h["y"])


# ================================================================ atos

## O herói chegou ao fim do ato: escolha de relíquia e, depois dela, o próximo ato (ou a arena).
func _end_act() -> void:
	act_pending = true
	route_wait = false
	stats["act_t"].append(t)
	hero.hold = false
	hero.target_kind = SimHero.TGT_NONE
	if act + 1 < acts():
		for i in units.hi:
			if units.alive[i] == 1:
				kill_unit(i, K.Death.EXPIRE)
		zones.clear()
		if contract.size() > 0:
			stats["contracts_fail"] += 1
			emit(K.Ev.CONTRACT, hero.x, hero.y, -1, 0)
			contract = {}
	emit(K.Ev.ACT_END, hero.x, hero.y, act, 0)
	_offer_relics()


func _next_act() -> void:
	act_pending = false
	if rv("act_full_elixir") > 0.0:
		elixir = elixir_max
	if act + 1 >= acts():
		enter_arena()
		return
	act += 1
	elixir_max -= act_elixir_bonus
	act_elixir_bonus = 0.0
	elixir = minf(elixir, elixir_max)
	stats["route_len"] = float(stats.get("route_len", 0.0)) + road.length()
	road = SimRoad.new()
	road.generate(rng, R, _act_cfg(act))
	var p0: Vector2 = road.route[0]
	hero.x = p0.x
	hero.y = p0.y
	hero.ox = p0.x
	hero.oy = p0.y
	hero.s = 0.0
	hero.s_max = 0.0
	hero.seg = 0
	hero.face_x = 0.0
	hero.face_y = -1.0
	regroup()
	var fa: Array = R["contracts"]["first_at"]
	contract_next = t + rng.randf_range(fa[0], fa[1])
	emit(K.Ev.ACT_START, p0.x, p0.y, act, 0)


# ================================================================ relíquias

func rv(key: String) -> float:
	return float(rfx.get(key, 0.0))


func rebuild_rfx() -> void:
	rfx = {}
	for id in relics:
		var r: Dictionary = data.relics.get(id, {})
		for k in r.get("fx", {}):
			rfx[k] = float(rfx.get(k, 0.0)) + float(r["fx"][k])


func gain_relic(id: String) -> void:
	if relics.has(id) or not data.relics.has(id):
		return
	relics.append(id)
	stats["relics"].append(id)
	var fx: Dictionary = data.relics[id].get("fx", {})
	hand_size = clampi(hand_size + int(fx.get("hand", 0)), 1, HAND_MAX)
	elixir_max = maxf(3.0, elixir_max + float(fx.get("elixir_max", 0)))
	elixir = minf(elixir, elixir_max)
	while hand.size() < hand_size and queue.size() > 0:
		hand.append(queue.pop_front())
	rebuild_rfx()
	emit(K.Ev.RELIC, hero.x, hero.y, data.relic_ids.find(id), 0)


func _relic_pool() -> Array:
	var pool: Array = []
	for id in data.relic_ids:
		if not relics.has(id):
			pool.append(id)
	return pool


func _offer_relics() -> void:
	var pool := _relic_pool()
	var opts: Array = []
	var want := int(R.get("relics", {}).get("options", 3))
	# Raridade única por oferta (10/11/2026): a raridade vem de uma relíquia sorteada do que resta; se ela não
	# tem opções suficientes, a oferta inteira vai para a raridade com mais opções (a mais próxima no empate).
	if pool.size() > 0:
		var by := {}
		for id in pool:
			var rr := K.RARITIES.find(str(data.relics[id].get("rarity", "common")))
			if not by.has(rr):
				by[rr] = []
			by[rr].append(id)
		var r0 := K.RARITIES.find(str(data.relics[pool[rng.randi_range(0, pool.size() - 1)]].get("rarity", "common")))
		var best: int = r0
		if by[r0].size() < want:
			for dr in [-1, 1, -2, 2, -3, 3]:
				var r2: int = r0 + dr
				if by.has(r2) and by[r2].size() > by[best].size():
					best = r2
		pool = by[best]
	for k in want:
		if pool.is_empty():
			break
		var id: String = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(id)
		opts.append({"kind": "relic", "id": id})
	_push_offer("relic", opts, {"act": act})


## Uma relíquia sorteada direto (eventos de texto).
func random_relic() -> void:
	var pool := _relic_pool()
	if pool.size() > 0:
		gain_relic(pool[rng.randi_range(0, pool.size() - 1)])


func teleport_cost() -> float:
	return maxf(0.0, float(R["arena"]["teleport_cost"]) + rv("teleport_cost"))


func cc_mult() -> float:
	return 1.0 + rv("cc")


## Uma habilidade do herói disparou (aviso no visual); Olho Vigilante: a próxima carta em até N s sai de graça.
func ability_fired(id: String) -> void:
	emit(K.Ev.ABILITY, hero.x, hero.y, float(hero.ability_index(id)), 0)
	if rv("free_after_ability") > 0.0:
		free_card_t = t + rv("free_after_ability")


func free_card_active() -> bool:
	return t <= free_card_t


# ================================================================ eventos de texto

func _offer_event() -> void:
	var pool: Array = []
	for id in data.event_ids:
		if not events_seen.has(id):
			pool.append(id)
	if pool.is_empty():
		pool = data.event_ids.duplicate()
	if pool.is_empty():
		return
	var id: String = pool[rng.randi_range(0, pool.size() - 1)]
	events_seen.append(id)
	var opts: Array = []
	var ev: Dictionary = data.events_def[id]
	for k in ev["options"].size():
		opts.append({"kind": "event_opt", "event": id, "opt": k})
	_push_offer("event", opts, {"event": id})


func event_option_ok(op: Dictionary) -> bool:
	var o: Dictionary = data.events_def[op["event"]]["options"][int(op["opt"])]
	return gold + 0.0001 >= float(o.get("requires", {}).get("gold", 0))


func enter_arena() -> void:
	phase = K.Phase.ARENA
	stats["arena_t"] = t
	stats["hero_level_arena"] = hero.level
	stats["player_level_arena"] = player_level
	stats["route_len"] = float(stats.get("route_len", 0.0)) + road.length()
	var A: Dictionary = R["arena"]
	var dir := road.lair_dir
	var gate := Vector2(hero.x, hero.y)
	gate_pos = gate
	var center := gate + dir * (float(A["radius"]) - 1.5)
	arena.setup(self, center, dir)
	if boss_hp_mult != 1.0:
		for k in arena.part_hp.size():
			arena.part_max[k] *= boss_hp_mult
			arena.part_hp[k] = arena.part_max[k]
	# Monstros vivos perto do herói entram junto; o resto fica para trás.
	for i in units.hi:
		if units.alive[i] == 0:
			continue
		var v := Vector2(units.px[i] - gate.x, units.py[i] - gate.y)
		if v.length() > 25.0 or units.arch[i] == K.Arch.STRUCTURE:
			kill_unit(i, K.Death.EXPIRE)
			continue
		var p := gate + dir * 3.0 + v.limit_length(10.0)
		units.px[i] = p.x
		units.py[i] = p.y
		units.ox[i] = p.x
		units.oy[i] = p.y
	zones.clear()
	hero.target_kind = SimHero.TGT_NONE
	stats["hero_hp_arena"] = hero.hp_frac()
	emit(K.Ev.ARENA, center.x, center.y, 0, 0)


## Prorrogação da arena (10/11/2026): minutos passados de overtime_s na arena (0 antes). Na prorrogação a
## cura do herói para, o golpe dele cresce e o elixir do covil vem mais rápido: um empate na arena acaba.
func overtime() -> float:
	if phase != K.Phase.ARENA or float(stats.get("arena_t", -1.0)) < 0.0:
		return 0.0
	return maxf(0.0, (t - float(stats["arena_t"]) - float(R["arena"].get("overtime_s", 1e9))) / 60.0)


func core_destroyed() -> void:
	_finish(K.Result.LOSS)


func _check_end() -> void:
	if phase == K.Phase.OVER:
		return
	if group_mode():
		_group_check()
		return
	if hero.hp <= 0.0:
		if party_idx < party_size() - 1:
			_hero_fell()
		else:
			stats["heroes_fallen"] = party_idx + 1
			_finish(K.Result.WIN_EARLY if phase == K.Phase.ROAD else K.Result.WIN)
	elif t >= float(R["sim"]["max_run_seconds"]):
		_finish(K.Result.TIMEOUT)


func group_mode() -> bool:
	return bool(phase_cfg.get("group", false))


## Fase de grupo: cada queda traz o próximo da fila, que levanta o caído (uma vez por herói, com revive_hp da vida).
func _group_check() -> void:
	var k := followers.size() - 1
	while k >= 0:
		var f: SimHero = followers[k]
		if f.hp <= 0.0:
			followers.remove_at(k)
			group_falls += 1
			stats["heroes_fallen"] = group_falls
			emit(K.Ev.HERO_FALL, f.x, f.y, f.pidx + 1, 1)
			if party_idx < party_size() - 1:
				party_idx += 1
				var nf := SimHero.new()
				nf.init_follower(self, party_idx, hero, 1.0)
				followers.append(nf)
				_revive(f)
				emit(K.Ev.HERO_LEVEL, nf.x, nf.y, nf.level, 1)
				_offer_level()
		k -= 1
	if hero.hp > 0.0:
		if t >= float(R["sim"]["max_run_seconds"]):
			_finish(K.Result.TIMEOUT)
		return
	var fallen := SimHero.new()
	fallen.init_follower(self, hero.pidx, hero, 0.0)
	fallen.x = hero.x
	fallen.y = hero.y
	group_falls += 1
	if party_idx < party_size() - 1:
		_hero_fell()
		stats["heroes_fallen"] = group_falls
		_revive(fallen)
	elif followers.size() > 0:
		stats["heroes_fallen"] = group_falls
		emit(K.Ev.HERO_FALL, hero.x, hero.y, hero.pidx + 1, 0)
		var f: SimHero = followers.pop_front()
		hero.take_over(f)
		emit(K.Ev.HERO_LEVEL, hero.x, hero.y, hero.level, 0)
	else:
		stats["heroes_fallen"] = group_falls
		_finish(K.Result.WIN_EARLY if phase == K.Phase.ROAD else K.Result.WIN)


func _revive(fallen: SimHero) -> void:
	if revived.has(fallen.pidx):
		return
	revived.append(fallen.pidx)
	var r := SimHero.new()
	r.init_follower(self, fallen.pidx, hero, float(phase_cfg.get("revive_hp", 0.5)))
	r.x = fallen.x
	r.y = fallen.y
	r.ox = r.x
	r.oy = r.y
	followers.append(r)
	emit(K.Ev.HEAL, r.x, r.y, r.hp, 1)


## Seguidor fica perto do herói da vez: pode sair para bater num monstro, mas volta para o lugar dele no grupo.
func _follow(f: SimHero) -> void:
	var a := float(f.pidx) * 2.4
	var goal := Vector2(hero.x + cos(a) * 3.6, hero.y + sin(a) * 3.6)
	var p := Vector2(f.x, f.y)
	var d := p.distance_to(goal)
	var free_r := 7.0 if f.target_kind == SimHero.TGT_UNIT else 2.5
	# Preso (teia, piche, prisão, petrificado) não anda; na teia anda devagar (10/11/2026).
	var stuck := f.root_t > 0.0 or f.petrify_t > 0.0
	if d > free_r and (not stuck or d > 25.0):
		var step_ := minf(d - free_r * 0.5, float(f.H["speed"]) * 1.6 * dt * (0.5 if f.slow_t > 0.0 else 1.0))
		if d > 25.0:
			step_ = d - 2.0   # muito longe (troca de ato, portão da arena): reaparece junto do grupo
		var v := (goal - p).normalized() * step_
		f.x += v.x
		f.y += v.y
		f.face_x = v.normalized().x
		f.face_y = v.normalized().y
	f.s = hero.s
	f.s_max = hero.s_max
	f.seg = hero.seg


## Põe os seguidores em volta do herói da vez (ato novo, arena).
func regroup() -> void:
	for f in followers:
		var a := float(f.pidx) * 2.4
		f.x = hero.x + cos(a) * 3.6
		f.y = hero.y + sin(a) * 3.6
		f.ox = f.x
		f.oy = f.y


## Heróis de pé a até r m de (x, y), contando o raio do corpo, do mais perto ao mais longe.
func heroes_near(x: float, y: float, r: float) -> Array:
	var out: Array = []
	for hh in all_heroes():
		if Vector2(hh.x - x, hh.y - y).length() <= r + hh.radius:
			out.append(hh)
	out.sort_custom(func(a, b): return Vector2(a.x - x, a.y - y).length_squared() < Vector2(b.x - x, b.y - y).length_squared())
	return out


## Feitiço de área no grupo: dano inteiro no herói mais perto, metade nos outros.
func splash_mult(k: int) -> float:
	return 1.0 if k == 0 else float(R.get("group_spell_splash", 0.5))


## Todos os heróis de pé (o da vez primeiro).
func all_heroes() -> Array:
	return [hero] + followers


func _finish(r: int) -> void:
	if phase == K.Phase.OVER:
		return
	result = r
	phase = K.Phase.OVER
	stats["result"] = K.RESULT_NAMES[r]
	stats["t_end"] = t
	stats["hero_level"] = hero.level
	stats["player_level"] = player_level
	stats["upgrades"] = hero.upgrade_order.duplicate()
	stats["waste_frac"] = stats["waste_s"] / maxf(t, 1.0)
	var fin: Array = []
	var lv := 0
	for c in cards:
		fin.append(c.def.id)
		lv += c.level - 1
	stats["deck_final"] = fin
	stats["card_levels"] = lv
	stats["ticks"] = tick


# ================================================================ dano e mortes

func damage_hero(amount: float, sx: float, sy: float, tags: int, kind: int, card_id: String) -> float:
	if (kind & SimHero.DMG_SPELL) and t < mark_until:
		amount *= 1.0 + mark_bonus
	var hh: SimHero = hit_hero if hit_hero else hero
	var real := hh.take_damage(amount, sx, sy, tags, kind)
	var gain := real
	gain += hh.last_absorbed
	if gain <= 0.0:
		return 0.0
	if real > 0.0:
		emit(K.Ev.DAMAGE_HERO, hh.x, hh.y, real, tags)
	if contest.size() > 0 and contest["type"] in ["bridge", "fountain"]:
		contest["progress"] += real
	_earn_gold(gain / float(R["gold"]["damage_per_gold"]) * (1.0 + rv("gold")))
	var dbc: Dictionary = stats["dmg_by_card"]
	dbc[card_id] = float(dbc.get(card_id, 0.0)) + gain
	if contract.size() > 0:
		var g: Dictionary = contract["goal"]
		match str(g["kind"]):
			"tag_damage":
				if tags & int(K.TAG_BY_NAME[g["tag"]]):
					contract["progress"] += real
			"damage_no_xp":
				contract["progress"] += real
			"burst":
				contract["window"].append([t, real])
	return real


func _player_next() -> float:
	return 1.0   # sem XP do jogador (09/11/2026); resto de compatibilidade com a HUD antiga


func unit_hits_hero(i: int) -> void:
	var di := units.def[i]
	var c: CardDef = data.cards[di]
	var amount := units.dmg[i] * (1.0 + units.buff[i])
	if (units.tags[i] & K.TAG_PACK) and rv("pack_min") > 0.0 and units.n_pack >= int(rv("pack_min")):
		amount *= 1.0 + rv("pack_dmg")
	if c.fx.has("pack_bonus"):
		# Bando: mais forte quanto mais bicho de bando seu há em campo.
		amount *= 1.0 + minf(float(c.fx.get("pack_cap", 1.0)), float(c.fx["pack_bonus"]) * units.n_pack)
	if (units.tags[i] & K.TAG_PACK) and t < rally_until:
		amount *= 1.0 + rally_dmg
	if c.fx.has("death_stack"):
		amount *= 1.0 + float(c.fx["death_stack"]) * units.gen[i]
	var kind := 0
	var lv := int(units.lvl[i])
	var tg := units.tags[i]
	if units.flags[i] & K.F_PROJECTILE:
		kind = SimHero.DMG_PROJECTILE
		emit(K.Ev.SHOT, units.px[i], units.py[i], hero.x, int(hero.y * 100.0))
	if c.has_n3(lv, "pierce"):
		kind |= SimHero.DMG_PIERCE
	if c.has_n3(lv, "burn_dps"):
		tg |= K.TAG_FIRE
		burn_t = float(c.n3["burn_s"])
		burn_dps = float(c.n3["burn_dps"])
		burn_src = "skeleton_archers"
	var src := str(card_of_uid.get(units.uid[i], c.id))
	var real := damage_hero(amount, units.px[i], units.py[i], tg, kind, src)
	# Contadores das habilidades do herói: Enxame (unidade de uma carta de enxame) e alvos grandes.
	var oc: CardDef = data.card(src)
	if (oc if oc else c).type == "swarm":
		hero.note("swarm", real)
	if units.max_hp[i] >= float(data.upgrades["heroic_strike"]["p"]["big_hp"]):
		hero.note("big", real)
	if di == units.d_ogre:
		hero.knockback(units.px[i], units.py[i], float(c.fx.get("knockback", 4.0)))
		if c.has_n3(lv, "root"):
			hero.root_t = maxf(hero.root_t, float(c.n3["root"]) * cc_mult())
	if (units.flags[i] & K.F_CURSED) and units.curse_t[i] <= 0.0:
		hero.add_curse(1)
		units.curse_t[i] = R["curse"]["cursed_mod_cooldown"]


func hero_hits_unit(i: int, dmg: float) -> void:
	if units.alive[i] == 0:
		return
	if units.flags[i] & K.F_STONE:
		# Gárgula N3: em pedra, devolve parte do golpe.
		var gc: CardDef = data.cards[units.def[i]]
		if gc.has_n3(int(units.lvl[i]), "reflect"):
			damage_hero(dmg * float(gc.n3["reflect"]), units.px[i], units.py[i], gc.tags, SimHero.DMG_AREA, gc.id)
		return
	units.hp[i] -= dmg
	emit(K.Ev.DAMAGE_UNIT, units.px[i], units.py[i], dmg, i)
	if units.hp[i] <= 0.0:
		kill_unit(i, K.Death.HERO)


func kill_unit(i: int, cause: int) -> void:
	if units.alive[i] == 0:
		return
	var di := units.def[i]
	var c: CardDef = data.cards[di]
	var x := units.px[i]
	var y := units.py[i]
	var f := units.flags[i]
	if cause == K.Death.HERO and contract.size() > 0 and contract["goal"]["kind"] == "damage_no_xp":
		contract["progress"] = 0.0   # "Sem Testemunhas": causar dano sem perder nenhum monstro
	if cause == K.Death.HERO or cause == K.Death.SELF:
		if cause == K.Death.HERO:
			stats["kills"] += 1
		if not (f & K.F_NO_XP):
			hero_gain_xp(units.xp[i])
		if hero.has("soul_absorb"):
			hero.heal(hero.max_hp() * float(hero.upgrades["soul_absorb"]["heal"]))
		if not (f & K.F_REVIVED) and c.id != "spectre":
			dead_by_def[di] += 1
		_death_in_contest(x, y, c, f)
	if cause != K.Death.EXPIRE and c.arch != K.Arch.STRUCTURE:
		_death_payoffs(i, x, y)
	if cause == K.Death.HERO or cause == K.Death.SELF:
		if f & K.F_EXPLOSIVE:
			var M: Dictionary = data.modifiers["explosive"]["p"]
			if Vector2(hero.x - x, hero.y - y).length() <= float(M["radius"]) + hero.radius:
				damage_hero(M["damage"], x, y, 0, 0, str(card_of_uid.get(units.uid[i], c.id)))
			emit(K.Ev.EXPLOSION, x, y, M["radius"], 0)
	if cause == K.Death.HERO:
		var split: Array = c.fx.get("split", [])
		var g := int(units.gen[i])
		if g < split.size():
			var s: Dictionary = split[g]
			var lv := int(units.lvl[i])
			var n := int(s["n"])
			if g == 0 and c.has_n3(lv, "first_split"):
				n = int(c.n3["first_split"])
			for k in n:
				var a := units.slot[i] + k * TAU / n
				var j := spawn_child(c, x + cos(a) * 0.6, y + sin(a) * 0.6, i)
				if j >= 0:
					units.gen[j] = g + 1
					units.hp[j] = float(s["hp"]) * _forge() * (c.mult(lv) if c.scales("hp") else 1.0)
					units.max_hp[j] = units.hp[j]
					units.dmg[j] = float(s["dps"]) * units.atk_int[j] * units.dmg_mult * (c.mult(lv) if c.scales("dps") else 1.0)
					units.rad[j] = c.radius * (0.75 if g == 0 else 0.55)
		if c.fx.has("death_spawn"):
			var sd: CardDef = data.card(str(c.fx["death_spawn"]))
			for k in int(c.fx.get("death_spawn_n", 0)):
				var a := TAU * k / float(c.fx["death_spawn_n"])
				spawn_child(sd, x + cos(a) * 1.0, y + sin(a) * 1.0, i)
		if c.arch != K.Arch.STRUCTURE and not (f & K.F_REVIVED):
			if not _golem_absorb(i, x, y):
				_totem_revive(i, x, y)
	# Gatilho "ao morrer" declarado em dados (data/cards.json "on_death"; docs/CARD_FX.md).
	if not c.on_death.is_empty() and (cause == K.Death.HERO or cause == K.Death.SELF):
		CardFxLib.run(self, CardFxLib.unit_ctx(c, int(units.lvl[i]), units.uid[i]), c.on_death, x, y)
	emit(K.Ev.DEATH, x, y, di, i)
	units.release(i)


## Família Morte: Colheita de Almas devolve elixir; Carniçais por perto ficam mais fortes.
func _death_payoffs(i: int, x: float, y: float) -> void:
	if t < harvest_until:
		elixir = minf(elixir_max, elixir + harvest_elixir)
	for j in units.hi:
		if j == i or units.alive[j] == 0:
			continue
		var gc: CardDef = data.cards[units.def[j]]
		if gc.fx.has("death_stack") and units.gen[j] < int(gc.fx.get("stack_max", 10)):
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= pow(float(gc.fx.get("stack_radius", 6.0)), 2):
				units.gen[j] += 1


## Morte de um monstro seu (pelo herói ou explodindo): Ritual, Terra Profana e Coroa de Ossos.
func _death_in_contest(x: float, y: float, c: CardDef, f: int) -> void:
	if c.arch == K.Arch.STRUCTURE:
		return
	relic_deaths += 1
	var every := int(rv("death_elixir_every"))
	if every > 0 and relic_deaths % every == 0:
		elixir = minf(elixir_max, elixir + 1.0)
	if contest.is_empty():
		return
	var loc: Dictionary = road.locations[int(contest["li"])]
	var p: Vector2 = loc["pos"]
	if Vector2(x - p.x, y - p.y).length() > float(loc["r"]):
		return
	if contest["type"] == "ritual":
		contest["progress"] += 1.0
	if rv("loc_raise") > 0.0 and not (f & K.F_REVIVED) and rng.randf() < rv("loc_raise"):
		var sk: CardDef = data.card("skeleton_archers")
		units.spawn(sk, x, y, 0.0, 0.0, K.F_NO_XP | K.F_REVIVED, 0, _forge())


func _golem_absorb(i: int, x: float, y: float) -> bool:
	if units.d_golem < 0:
		return false
	var gd: CardDef = data.cards[units.d_golem]
	var fx: Dictionary = gd.fx
	var r2: float = pow(float(fx["absorb_radius"]), 2)
	for j in units.hi:
		if units.alive[j] == 1 and j != i and units.def[j] == units.d_golem:
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= r2:
				var cap := gd.fxv("hp_cap", int(units.lvl[j]))
				units.max_hp[j] = minf(cap, units.max_hp[j] + float(fx["absorb_hp"]))
				units.hp[j] = minf(units.max_hp[j], units.hp[j] + float(fx["absorb_hp"]))
				return true
	return false


func _totem_revive(i: int, x: float, y: float) -> void:
	if units.d_totem < 0:
		return
	var fx: Dictionary = data.cards[units.d_totem].fx
	var r2: float = pow(float(fx["radius"]), 2)
	for j in units.hi:
		if units.alive[j] == 1 and units.def[j] == units.d_totem:
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= r2:
				var sk: CardDef = data.card(str(fx["revive"]))
				units.spawn(sk, x, y, 0.0, 0.0, K.F_NO_XP | K.F_REVIVED, units.uid[i], _forge())
				return


func spawn_child(c: CardDef, x: float, y: float, parent: int) -> int:
	var inherit := units.flags[parent] & (K.F_NO_XP | K.F_CURSED | K.F_DEFEND)
	var j := units.spawn(c, x, y, units.xp[parent], units.cost_share[parent], inherit, units.uid[parent], _forge())
	if j >= 0:
		units.lvl[j] = units.lvl[parent]
	return j


func kamikaze(i: int) -> void:
	var c: CardDef = data.cards[units.def[i]]
	var lv := int(units.lvl[i])
	var r: float = c.fx.get("explode_radius", 2.5)
	var x := units.px[i]
	var y := units.py[i]
	var src := str(card_of_uid.get(units.uid[i], c.id))
	var near_k := heroes_near(x, y, r)
	for k in near_k.size():
		hit_hero = near_k[k]
		damage_hero(c.fxv("explode_damage", lv) * splash_mult(k), x, y, units.tags[i], 0, src)
	hit_hero = null
	# Goblin N3: a explosão deixa fogo no chão.
	if c.has_n3(lv, "fire_dps"):
		zones.append({"kind": "fire", "x": x, "y": y, "r": c.n3["fire_r"], "t": c.n3["fire_s"], "dps": c.n3["fire_dps"], "src": src})
	emit(K.Ev.EXPLOSION, x, y, r, 1)
	kill_unit(i, K.Death.SELF)


func mimic_bite(i: int) -> void:
	var c: CardDef = data.cards[units.def[i]]
	var lv := int(units.lvl[i])
	var bite := c.fxv("bite", lv)
	for z in zones:
		if z["kind"] == "bait" and Vector2(units.px[i] - z["x"], units.py[i] - z["y"]).length() <= float(c.fx.get("bait_r", 5.0)):
			bite *= float(c.fx.get("bait_mult", 2.0))
			break
	damage_hero(bite, units.px[i], units.py[i], units.tags[i], SimHero.DMG_PIERCE, c.id)
	hero.add_curse(int(c.fx.get("curses", 0)))
	hero.note("mimic", 120.0)
	# Mímico N3: morde de novo depois de uma pausa (gen conta as mordidas).
	units.gen[i] += 1
	if c.has_n3(lv, "bites") and units.gen[i] < int(c.n3["bites"]):
		units.flags[i] &= ~K.F_BITTEN
		units.timer2[i] = units.timer[i] + 3.0


func hero_fear(x: float, y: float, dur := -1.0) -> void:
	if dur <= 0.0:
		dur = float(R["status"]["fear"])
	hero.fear(x, y, dur * cc_mult())
	_cc()
	emit(K.Ev.FEAR, hero.x, hero.y, 0, 0)


func _cc() -> void:
	if contract.size() > 0 and contract["goal"]["kind"] == "cc":
		contract["progress"] += 1


func on_shield_break() -> void:
	stats["shield_breaks"] += 1
	emit(K.Ev.SHIELD_BREAK, hero.x, hero.y, 0, 0)


## Sem XP (09/11/2026): o herói só evolui quando um herói cai (`_hero_fell`). Mantida vazia para as chamadas antigas.
func hero_gain_xp(_v: float) -> void:
	pass


## O herói da vez caiu: vem o próximo, um nível acima e com uma habilidade a mais, andando de trás.
func _hero_fell() -> void:
	var fell := party_idx + 1
	stats["heroes_fallen"] = fell
	var bless: float = hero.H.get("bless_next", 0.0)
	if bless > 0.0:
		# Clériga: a bênção dela fica para o próximo herói.
		next_hp_mult *= 1.0 + bless
	emit(K.Ev.HERO_FALL, hero.x, hero.y, fell, 0)
	party_idx += 1
	var back := float(R["party"]["arrive_s"]) * float(hero.H["speed"])
	hero.next_hero(party_idx)
	if next_hp_mult != 1.0:
		hero.base_hp *= next_hp_mult
		hero.hp = hero.base_hp
		next_hp_mult = 1.0
	# Caiu no meio da disputa: o local fica perdido (sem recompensa).
	if contest.size() > 0:
		road.locations[int(contest["li"])]["state"] = SimRoad.LocState.USED
		stats["locs_lost"] += 1
	contest = {}
	hero.hold = false
	if phase == K.Phase.ROAD:
		var s0 := maxf(0.0, hero.s_max - back)
		var p := road.point_at(s0)
		hero.x = p.x
		hero.y = p.y
		hero.s = s0
		hero.s_max = s0
		hero.seg = road.seg_at(s0)
	else:
		hero.x = gate_pos.x
		hero.y = gate_pos.y
	hero.ox = hero.x
	hero.oy = hero.y
	for extra in (2 if next_extra_ability else 1):
		var opts := _upgrade_options(3)
		if opts.size() > 0:
			hero.apply_upgrade(hero.choose_upgrade(opts))
	next_extra_ability = false
	emit(K.Ev.HERO_LEVEL, hero.x, hero.y, hero.level, 0)
	_offer_level()
	if rv("fall_mod_offer") > 0.0:
		var mo: Array = []
		var ex: Array = []
		for k in int(R["offers"]["options"]):
			var m := _mod_option(ex)
			if m.size() > 0:
				ex.append(str(m["uid"]) + str(m["mod"]))
				mo.append(m)
		_push_offer("level", mo)


## O herói aprende uma habilidade a cada `upgrade_every` níveis, até `upgrade_max` (poucas, para o jogador acompanhar).
func _hero_learns() -> bool:
	var X: Dictionary = R["hero_xp"]
	var every := int(X.get("upgrade_every", 1))
	return hero.level % every == 0 and hero.upgrade_order.size() < int(X.get("upgrade_max", 99))


func _upgrade_options(n: int) -> Array:
	var pool: Array = []
	for u in data.hero["upgrades"]:
		if not hero.has(u["id"]):
			pool.append(u)
	var out: Array = []
	while out.size() < n and pool.size() > 0:
		var tot := 0.0
		for u in pool:
			tot += float(u["weight"])
		var r := rng.randf() * tot
		for k in pool.size():
			r -= float(pool[k]["weight"])
			if r <= 0.0 or k == pool.size() - 1:
				out.append(pool[k]["id"])
				pool.remove_at(k)
				break
	return out


func _forge() -> float:
	return 1.0 + float(lair_val.get("dark_forge", 0.0))


# ================================================================ zonas

## Heróis de pé dentro da zona z (o da vez primeiro). Fase de grupo (10/11/2026): zonas pegam o grupo todo.
func _in_zone(z: Dictionary) -> Array:
	var out: Array = []
	for hh in all_heroes():
		if Vector2(hh.x - float(z["x"]), hh.y - float(z["y"])).length() <= float(z["r"]) + hh.radius:
			out.append(hh)
	return out


func _zones() -> void:
	var h := Vector2(hero.x, hero.y)
	var i := zones.size() - 1
	while i >= 0:
		var z: Dictionary = zones[i]
		z["t"] -= dt
		var inside: bool = h.distance_to(Vector2(z["x"], z["y"])) <= float(z["r"]) + hero.radius
		match str(z["kind"]):
			"web":
				# "applied" guarda os heróis (pidx) já presos por esta teia: cada um prende uma vez.
				if not (z["applied"] is Array):
					z["applied"] = [hero.pidx] if z["applied"] else []
				for hh in _in_zone(z):
					hh.slow_t = maxf(hh.slow_t, 0.15)
					hh.note("slow", 2.0)
					if not z["applied"].has(hh.pidx):
						z["applied"].append(hh.pidx)
						if hh == hero:
							_cc()
						hh.root_t = maxf(hh.root_t, float(z.get("root", 0.0)) * cc_mult())
						hh.add_curse(int(z.get("curse", 0)))
						if float(z.get("soak", 0.0)) > 0.0:
							hh.soaked_t = maxf(hh.soaked_t, float(z["soak"]))
			"oil":
				var ins: Array = _in_zone(z)
				for k in ins.size():
					var hh: SimHero = ins[k]
					hh.soaked_t = z["soaked"]
					hit_hero = hh if hh != hero else null
					damage_hero(float(z["dps"]) * dt, z["x"], z["y"], K.TAG_FIRE, SimHero.DMG_AREA, str(z.get("src", "boiling_oil")))
					if z.get("curse", 0) > 0:
						hh.add_curse(int(z["curse"]))
						z["curse"] = 0
				hit_hero = null
			"fire":
				for hh in _in_zone(z):
					hit_hero = hh if hh != hero else null
					damage_hero(float(z["dps"]) * dt, z["x"], z["y"], K.TAG_FIRE, SimHero.DMG_AREA, z["src"])
				hit_hero = null
			"spring":
				# Fonte: cura as suas unidades no raio (estruturas também).
				if tick % 4 == 0:
					for j in units.within(z["x"], z["y"], z["r"], tmp):
						if units.alive[j] == 1:
							units.hp[j] = minf(units.max_hp[j], units.hp[j] + units.max_hp[j] * float(z["heal"]) * dt * 4.0)
			"bait":
				if hero.has("treasure_nose"):
					z["t"] = 0.0
				elif h.distance_to(Vector2(z["x"], z["y"])) <= 1.5:
					hero_gain_xp(z["xp"])
					hero.note("bait", 60.0)
					z["t"] = 0.0
			"coins":
				# Quem pisar primeiro (o da vez ou um seguidor) para para catar as moedas.
				var ins_c: Array = _in_zone(z)
				if ins_c.size() > 0 and not z["applied"]:
					var hc: SimHero = ins_c[0]
					z["applied"] = true
					hc.root_t = maxf(hc.root_t, float(z["stop"]))
					hc.add_curse(int(z["curses"]))
					_earn_gold(float(z["gold"]))
					if hc == hero:
						_cc()
					z["t"] = 0.0
			"army":
				if z["t"] <= 0.0:
					for j in z["ids"]:
						if units.alive[j] == 1 and data.cards[units.def[j]].id == "spectre":
							kill_unit(j, K.Death.EXPIRE)
		if z["t"] <= 0.0:
			zones.remove_at(i)
		i -= 1


# ================================================================ cartas

func card_cost(c: CardInst) -> int:
	if free_card_active():
		return 0
	var d := c.def
	var cost := d.cost_at(c.level)
	if c.has_mod(K.M_CHEAP):
		cost = maxi(mini(cost, 1), cost - 1)
	if d.category == "field" and (d.type == "monster" or d.type == "swarm"):
		cost += int(deck_rules.get("monster_cost_add", 0))
	if d.is_spell:
		if units.n_cultists > 0:
			var cf: Dictionary = data.card("cultists").fx
			cost = maxi(int(cf["spell_min_cost"]), cost - int(cf["spell_discount"]))
		if phase == K.Phase.ARENA and not arena.part_alive("left_arm"):
			cost += int(R["arena"]["spell_extra_cost_no_left_arm"])
	if tax_cards > 0:
		cost += tax_add
	# Pedra do Atalho: a primeira carta de cada disputa sai mais barata.
	if contest.size() > 0 and not contest.get("first", false):
		cost = maxi(0, cost - int(rv("contest_first_discount")))
	return cost


func can_play(hi_: int) -> int:
	if phase == K.Phase.OVER:
		return K.Block.OVER
	if offers.size() > 0:
		return K.Block.OFFER_PENDING
	if hi_ < 0 or hi_ >= hand.size() or hand[hi_] == null:
		return K.Block.BAD_TARGET
	var c: CardInst = hand[hi_]
	var d := c.def
	match d.category:
		"route", "lair":
			if phase != K.Phase.ROAD:
				return K.Block.WRONG_PHASE
			if d.category == "lair" and int(lair.get(d.id, 0)) >= int(d.fx.get("stack", 1)):
				return K.Block.STACK_LIMIT
			if d.id == "burn_village" and _burn_targets().is_empty():
				return K.Block.CONDITION
	if d.fx.has("gold_cost") and gold + 0.0001 < float(d.fx["gold_cost"]):
		return K.Block.CONDITION
	if d.id == "shadow_echo" and last_spell_id == "":
		return K.Block.CONDITION
	if elixir + 0.0001 < card_cost(c):
		return K.Block.NO_ELIXIR
	return K.Block.OK


## Onde a carta pode ser solta. Devolve true se (x, y) é válido.
func valid_target(c: CardInst, x: float, y: float) -> bool:
	var d := c.def
	if d.category == "field":
		var dist := Vector2(x - hero.x, y - hero.y).length()
		var ring: Dictionary = R["ring"]
		# Sem alcance máximo: vale qualquer ponto que o jogador enxerga na tela.
		if d.is_spell and ring["spells_ignore_min"]:
			return true
		if dist >= float(ring["min"]):
			return true
		return phase == K.Phase.ARENA and Vector2(x - arena.bx, y - arena.by).length() <= 6.0
	if d.id == "gold_bait":
		return Vector2(x - hero.x, y - hero.y).length() <= float(d.fx["max_detour"]) + 10.0
	if d.id == "burn_village":
		return _burn_near(x, y) >= 0
	return true


func play(hi_: int, x: float, y: float) -> int:
	var b := can_play(hi_)
	if b != K.Block.OK:
		return b
	var c: CardInst = hand[hi_]
	if not valid_target(c, x, y):
		return K.Block.BAD_TARGET
	elixir -= card_cost(c)
	free_card_t = -100.0
	if tax_cards > 0:
		tax_cards -= 1
	if contest.size() > 0:
		contest["first"] = true
	_cycle(hi_)
	var pl: Dictionary = stats["played"]
	pl[c.def.id] = int(pl.get(c.def.id, 0)) + 1
	_apply(c, x, y)
	if c.def.is_spell:
		_after_spell(c)
	return K.Block.OK


## Família Sequência: guarda o feitiço (Eco Sombrio, Faísca Arcana) e faz os Acólitos atirarem junto.
func _after_spell(c: CardInst) -> void:
	spell_times.append(t)
	if c.def.id != "shadow_echo" and not c.def.fx.has("gold_cost"):
		last_spell_id = c.def.id
		last_spell_lv = c.level
	for j in units.hi:
		if units.alive[j] == 1 and data.cards[units.def[j]].fx.has("echo_shot"):
			if Vector2(units.px[j] - hero.x, units.py[j] - hero.y).length() <= units.rng[j] + hero.radius + 2.0:
				unit_hits_hero(j)


## Feitiços jogados nos últimos `window` segundos (sem contar o atual).
func recent_spells(window: float) -> int:
	while spell_times.size() > 0 and t - float(spell_times[0]) > window:
		spell_times.pop_front()
	return spell_times.size()


func _cycle(hi_: int) -> void:
	var c: CardInst = hand[hi_]
	queue.push_back(c)
	if hand.size() > hand_size:
		hand.remove_at(hi_)
	else:
		hand[hi_] = queue.pop_front()
	_refill_hand()


## Mão menor que o tamanho (Biblioteca Proibida com o baralho vazio na hora, carta removida da mão): completa
## assim que houver carta no baralho.
func _refill_hand() -> void:
	while hand.size() < mini(hand_size, HAND_MAX) and queue.size() > 0:
		hand.append(queue.pop_front())


func sacrifice(hi_: int) -> bool:
	if phase == K.Phase.OVER or offers.size() > 0 or hi_ < 0 or hi_ >= hand.size() or hand[hi_] == null:
		return false
	# O elixir vem no máximo uma vez a cada `sacrifice_cooldown` s (sem isso, sacrificar sem parar era
	# elixir infinito). Durante a recarga só gira carta morta (fora de fase, condição, limite): girar de
	# graça qualquer carta deixava cavar o deck sem parar atrás da melhor (rodada de 09/11/2026).
	if not sacrifice_ready() and not sacrifice_free(hi_):
		return false
	if sacrifice_ready():
		elixir = minf(elixir_max, elixir + float(R["sacrifice_elixir"]))
		sac_elixir_t = t
	_cycle(hi_)
	stats["sacrifices"] += 1
	if contract.size() > 0 and contract["goal"]["kind"] == "sacrifice":
		contract["progress"] += 1
	emit(K.Ev.SPELL, hero.x, hero.y, -1, 0)
	return true


func sacrifice_ready() -> bool:
	return t - sac_elixir_t >= float(R.get("sacrifice_cooldown", 0.0)) * maxf(0.1, 1.0 + rv("sacrifice_cd"))


## Carta que não dá para jogar agora por outro motivo que não o elixir: gira mesmo durante a recarga.
func sacrifice_free(hi_: int) -> bool:
	return can_play(hi_) in [K.Block.WRONG_PHASE, K.Block.CONDITION, K.Block.STACK_LIMIT]


## Aplica o efeito de uma carta jogada. Unidades: CardFxLib.spawn_card_units. Depois as "ops" declaradas em
## data/cards.json (CardFxLib) e, por fim, o código por id no arquivo do dono (sim/cards/<owner>.gd).
func _apply(c: CardInst, x: float, y: float) -> void:
	var d := c.def
	var k := CardFxLib.ctx(self, c)
	emit(K.Ev.SPELL, x, y, d.idx, 0)
	if d.is_unit:
		CardFxLib.spawn_card_units(self, k, x, y)
		if not d.ops.is_empty():
			CardFxLib.run(self, k, d.ops, x, y)
		return
	if not d.ops.is_empty():
		CardFxLib.run(self, k, d.ops, x, y)
	match d.owner:
		"plague":
			if CardsPlague.apply(self, k, x, y):
				return
		"dragon":
			if CardsDragon.apply(self, k, x, y):
				return
		"lich":
			if CardsLich.apply(self, k, x, y):
				return
		_:
			if CardsCommon.apply(self, k, x, y):
				return
	if d.ops.is_empty():
		push_error("carta sem efeito: %s (owner %s)" % [d.id, d.owner])


## Locais que o Incêndio pode marcar (sim/cards/dragon.gd).
func _burn_targets() -> Array:
	return CardsDragon.burn_targets(self)


func _burn_near(x: float, y: float) -> int:
	return CardsDragon.burn_near(self, x, y)


func teleport(k: int) -> bool:
	if phase != K.Phase.ARENA:
		return false
	return arena.teleport(k)


# ================================================================ ofertas

func _roll_rarity() -> int:
	var w: Array
	var A: Array = R.get("acts", [])
	if A.size() > 0:
		w = A[mini(act, A.size() - 1)]["rarity"]
	else:
		var RT: Dictionary = R["rarity_by_time"]
		var row := 0
		for b in RT["breaks_s"]:
			if t >= float(b):
				row += 1
		w = RT["weights"][row]
	var r := rng.randf()
	for k in w.size():
		r -= float(w[k])
		if r <= 0.0:
			return k
	return w.size() - 1


func _card_ok(c: CardDef) -> bool:
	if unlocked.size() > 0 and not unlocked.has(c.id):
		return false
	if c.category == "lair" and int(lair.get(c.id, 0)) + _deck_count(c.id) >= int(c.fx.get("stack", 1)):
		return false
	return true


func _deck_count(id: String) -> int:
	var n := 0
	for ci in cards:
		if ci.def.id == id:
			n += 1
	return n


func _pick_card(filter: Callable, exclude: Array) -> CardDef:
	var cand: Array = []
	for c in data.pool:
		if filter.call(c) and _card_ok(c) and not exclude.has(c.id):
			cand.append(c)
	if cand.is_empty():
		return null
	return cand[rng.randi_range(0, cand.size() - 1)]


func _mod_option(exclude: Array) -> Dictionary:
	var cand: Array = []
	for ci in cards:
		if ci.def.category != "field":
			continue
		for mid in K.MOD_IDS:
			var m: Dictionary = data.modifiers[mid]
			var ok: bool = (m["applies"].has("any") or m["applies"].has(ci.def.type)) and not m.get("exclude", []).has(ci.def.id)
			if ok and not ci.has_mod(K.MOD_BY_ID[mid]) and not exclude.has(str(ci.uid) + mid):
				cand.append([ci, mid])
	if cand.is_empty():
		return {}
	var p: Array = cand[rng.randi_range(0, cand.size() - 1)]
	return {"kind": "mod", "uid": p[0].uid, "card": p[0].def.id, "mod": p[1]}


func _push_offer(source: String, opts: Array, extra := {}) -> void:
	if opts.is_empty():
		return
	var of: Dictionary = stats["offered"]
	for o in opts:
		var key := _opt_key(o)
		of[key] = int(of.get(key, 0)) + 1
	var o := {"source": source, "options": opts}
	o.merge(extra)
	offers.append(o)


func _opt_key(o: Dictionary) -> String:
	match str(o["kind"]):
		"card":
			return o["id"]
		"mod":
			return "mod:" + str(o["mod"])
		"upgrade":
			return "up:" + str(o["card"])
		"pick":
			return "pick:" + str(o["what"])
		"buy":
			return "buy:" + _opt_key(o["item"])
		"relic":
			return "relic:" + str(o["id"])
		"event_opt":
			return "ev:%s:%d" % [o["event"], int(o["opt"])]
		"transform", "copy":
			return str(o["kind"]) + ":" + str(o["card"])
	return "remove"


## Recompensa de um local: o tipo do local decide o que vem; vencer a disputa dá mais opções.
func _offer_location(ty: String, won: bool) -> void:
	var LR: Dictionary = R["location_rewards"][ty]
	var O: Dictionary = R["offers"]
	var n := int(O["location_win"] if won else O["location_lose"])
	stats["locs_won" if won else "locs_lost"] += 1
	if won:
		_earn_gold(float(R["gold"]["per_contest"]))
	if n <= 0:
		return
	var opts: Array = []
	match str(LR["reward"]):
		"card":
			if LR.has("min_rarity"):
				var minr := K.RARITIES.find(str(LR["min_rarity"]))
				opts = _card_options(n, func(cd: CardDef): return cd.rarity >= minr)
			else:
				opts = _card_options(n, _rarity_filter(LR["rarities"]))
		"upgrade":
			opts = _level_up_options(n)
		"mod":
			var ex: Array = []
			for k in n:
				var m := _mod_option(ex)
				if m.size() > 0:
					ex.append(str(m["uid"]) + str(m["mod"]))
					opts.append(m)
		"remove":
			opts = _remove_options(-1)
		"choice":
			opts = [{"kind": "pick", "what": "card"}, {"kind": "pick", "what": "upgrade"}]
			if _can_remove():
				opts.append({"kind": "pick", "what": "remove"})
	_push_offer("location", opts, {"loc": ty, "won": won})


func _earn_gold(v: float) -> void:
	gold += v
	stats["gold_earned"] += v


## Loja: abre quando o herói chega; sem disputa e sem desconto (rodada 09/11/2026).
## Cada item é {"kind": "buy", "item": opção de oferta (ou um "pick" que abre a escolha da carta), "price"}.
func _open_shop() -> void:
	var S: Dictionary = R["shop"]
	var disc := -rv("shop_price")
	var price := func(v: float) -> int: return int(round(v * (1.0 - disc)))
	var items: Array = []
	var ex: Array = []
	for k in int(S["cards"]) + int(rv("shop_cards")):
		var r := _roll_rarity()
		var c: CardDef = null
		for dr in [0, -1, 1, -2, 2, -3, 3]:
			var rr: int = r + dr
			if rr < 0 or rr > 3:
				continue
			c = _pick_card(func(cd: CardDef): return cd.rarity == rr, ex)
			if c:
				break
		if c:
			ex.append(c.id)
			items.append({"kind": "buy", "item": {"kind": "card", "id": c.id}, "price": price.call(float(S["prices"][K.RARITIES[c.rarity]]))})
	if not _level_up_options(1).is_empty():
		items.append({"kind": "buy", "item": {"kind": "pick", "what": "upgrade"}, "price": price.call(float(S["upgrade"]))})
	var m := _mod_option([])
	if m.size() > 0:
		items.append({"kind": "buy", "item": m, "price": price.call(float(S["mod"]))})
	if _can_remove():
		items.append({"kind": "buy", "item": {"kind": "pick", "what": "remove"},
			"price": price.call(float(S["remove"]) + float(S["remove_step"]) * shop_removes)})
	_push_offer("shop", items, {"won": true})


## Escolha do ramo pelo jogador: o herói vai passar pelo nó n (precisa estar à frente, no caminho).
func choose_route(n: int) -> bool:
	if phase != K.Phase.ROAD or not road.plan_to(n):
		return false
	if route_wait and road.next_edge() >= 0:
		route_wait = false
	return true


func _rarity_filter(names: Array) -> Callable:
	var rs: Array = names.map(func(r): return K.RARITIES.find(str(r)))
	return func(cd: CardDef): return rs.has(cd.rarity)


## Raridade única por oferta (10/11/2026): sorteia a raridade uma vez (peso do ato) e devolve a mais próxima que
## tem `n` cartas possíveis pelo filtro; sem nenhuma com `n`, aceita menos opções em vez de misturar raridades.
## -1 = o filtro não deixa carta nenhuma.
func _single_rarity(f: Callable, n: int, exclude: Array = []) -> int:
	var cnt := [0, 0, 0, 0]
	for c in data.pool:
		if f.call(c) and _card_ok(c) and not exclude.has(c.id):
			cnt[c.rarity] += 1
	var r := _roll_rarity()
	for need in range(maxi(n, 1), 0, -1):
		for dr in [0, -1, 1, -2, 2, -3, 3]:
			var rr: int = r + dr
			if rr >= 0 and rr <= 3 and cnt[rr] >= need:
				return rr
	return -1


func _card_options(n: int, f: Callable) -> Array:
	var opts: Array = []
	var ex: Array = []
	var one := _single_rarity(f, n)
	var f1 := func(cd: CardDef): return cd.rarity == one and f.call(cd)
	for k in n:
		var c := _pick_card(f1, ex)
		if c:
			ex.append(c.id)
			opts.append({"kind": "card", "id": c.id})
	return opts


## Até n cartas diferentes do deck que ainda podem subir de nível (-1 = todas).
func _level_up_options(n: int) -> Array:
	var pool: Array = []
	for ci in cards:
		if ci.level < int(R["card_levels"]["max"]):
			pool.append(ci)
	return _pick_insts(pool, n, "upgrade")


func _can_remove() -> bool:
	return cards.size() > int(R["deck"]["min_in_run"])


## Opções de remoção (n = -1: o deck inteiro, para escolher qualquer carta). Nunca abaixo do deck mínimo.
func _remove_options(n: int) -> Array:
	if not _can_remove():
		return []
	return _pick_insts(cards.duplicate(), n, "remove")


## Cópias iguais (mesma carta, nível e modificadores) aparecem uma vez só.
func _pick_insts(all: Array, n: int, kind: String) -> Array:
	var pool: Array = []
	var seen := {}
	for ci in all:
		var key := "%s/%d/%d" % [ci.def.id, ci.level, ci.mods]
		if not seen.has(key):
			seen[key] = true
			pool.append(ci)
	var opts: Array = []
	if n < 0:
		for ci in pool:
			opts.append({"kind": kind, "uid": ci.uid, "card": ci.def.id, "level": ci.level})
		return opts
	for k in n:
		if pool.is_empty():
			break
		var ci: CardInst = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(ci)
		opts.append({"kind": kind, "uid": ci.uid, "card": ci.def.id, "level": ci.level})
	return opts


func _offer_level() -> void:
	var n := int(deck_rules.get("offer_options", R["offers"]["options"]))
	var opts: Array = []
	var ex: Array = []
	var tries := 0
	# Uma oferta nunca mistura tipos (rodada 09/11/2026): sorteia o tipo uma vez.
	var cards_first := rng.randf() < float(R["offers"]["new_card_weight"])
	var want_cards := cards_first
	var one := -2   # raridade única da oferta, sorteada na primeira carta
	while opts.size() < n and tries < 20:
		tries += 1
		if tries == 11 and opts.is_empty():
			want_cards = not cards_first   # o tipo sorteado não tem opção: tenta o outro
		if want_cards:
			if one == -2:
				one = _single_rarity(func(_cd: CardDef): return true, n)
			var c := _pick_card(func(cd: CardDef): return cd.rarity == one, ex)
			if c:
				ex.append(c.id)
				opts.append({"kind": "card", "id": c.id})
		else:
			var m := _mod_option(ex)
			if m.size() > 0:
				ex.append(str(m["uid"]) + str(m["mod"]))
				opts.append(m)
	_push_offer("level", opts)


func _offer_contract(rw: Dictionary) -> void:
	var n := int(R["offers"]["contract_options"])
	var opts: Array = []
	var ex: Array = []
	var extra := {}
	match str(rw["kind"]):
		"card":
			var minr := K.RARITIES.find(str(rw.get("min_rarity", "common")))
			var tag := int(K.TAG_BY_NAME.get(str(rw.get("tag", "")), 0))
			var cat := str(rw.get("category", ""))
			var f1 := func(cd: CardDef): return (tag == 0 or (cd.tags & tag)) and (cat == "" or cd.category == cat) and cd.rarity >= minr
			var f2 := func(cd: CardDef): return (tag == 0 or (cd.tags & tag)) and (cat == "" or cd.category == cat)
			# Raridade única: primeiro dentro da raridade mínima do contrato; sem carta assim, sem o mínimo.
			var fsel: Callable = f1
			var one := _single_rarity(f1, n)
			if one < 0:
				fsel = f2
				one = _single_rarity(f2, n)
			for k in n:
				var c := _pick_card(func(cd: CardDef): return cd.rarity == one and fsel.call(cd), ex)
				if c:
					ex.append(c.id)
					opts.append({"kind": "card", "id": c.id})
		"modifier":
			for k in n:
				var m := _mod_option(ex)
				if m.size() > 0:
					ex.append(str(m["uid"]) + str(m["mod"]))
					opts.append(m)
		"remove":
			opts = _remove_options(n)
			extra = {"elixir": rw.get("elixir", 0)}
	_push_offer("contract", opts, extra)


const SKIP := -1


## Escolhe a opção k da oferta atual; SKIP (-1) recusa (toda recompensa pode ser recusada).
func choose(k: int) -> bool:
	if offers.is_empty():
		return false
	var o: Dictionary = offers[0]
	var opts: Array = o["options"]
	if k == SKIP:
		# Na loja, recusar é sair (ou voltar da escolha da carta para a loja).
		if o["source"] != "shop" and o["source"] != "shop_pick":
			stats["skipped"] += 1
		offers.pop_front()
		return true
	if k < 0 or k >= opts.size():
		return false
	var op: Dictionary = opts[k]
	if o["source"] == "shop":
		return _buy(k)
	if op["kind"] == "event_opt":
		if not event_option_ok(op):
			return false
		var ep: Dictionary = stats["event_picks"]
		var ek := _opt_key(op)
		ep[ek] = int(ep.get(ek, 0)) + 1
		offers.pop_front()
		Effects.run(self, data.events_def[op["event"]]["options"][int(op["opt"])]["do"])
		return true
	var pk: Dictionary = stats["picked"]
	var key := _opt_key(op)
	pk[key] = int(pk.get(key, 0)) + 1
	if o["source"] == "shop_pick":
		# Escolheu a carta do item comprado: paga e tira o item da loja (que está logo atrás).
		_pay(int(o["price"]))
		_apply_option(op)
		offers.pop_front()
		if offers.size() > 0 and offers[0]["source"] == "shop":
			offers[0]["options"].remove_at(int(o["shop_k"]))
			if op["kind"] == "remove":
				shop_removes += 1
			if offers[0]["options"].is_empty():
				offers.pop_front()
		return true
	var follow := _apply_option(op)
	if o.has("elixir"):
		elixir = minf(elixir_max, elixir + float(o["elixir"]))
	offers.pop_front()
	if follow.size() > 0:
		_push_offer("location", follow, {"loc": "bridge", "won": true})
		offers.push_front(offers.pop_back())
	return true


## Compra o item k da loja aberta. Carta e modificador saem na hora; nível e remoção abrem a escolha da carta.
func _buy(k: int) -> bool:
	var o: Dictionary = offers[0]
	var op: Dictionary = o["options"][k]
	if gold + 0.0001 < float(op["price"]):
		return false
	var item: Dictionary = op["item"]
	if item["kind"] == "pick":
		var pickopts := _level_up_options(-1) if item["what"] == "upgrade" else _remove_options(-1)
		if pickopts.is_empty():
			return false
		_push_offer("shop_pick", pickopts, {"price": op["price"], "shop_k": k, "what": item["what"]})
		offers.push_front(offers.pop_back())
		return true
	var pk: Dictionary = stats["picked"]
	var key := _opt_key(op)
	pk[key] = int(pk.get(key, 0)) + 1
	_pay(int(op["price"]))
	_apply_option(item)
	o["options"].remove_at(k)
	if o["options"].is_empty():
		offers.pop_front()
	return true


func _pay(p: int) -> void:
	gold = maxf(0.0, gold - p)
	stats["gold_spent"] += p
	stats["shop_buys"] += 1


func can_afford(op: Dictionary) -> bool:
	return gold + 0.0001 >= float(op.get("price", 0))


## Aplica uma opção de oferta ao deck. Devolve a escolha seguinte (Ponte vencida: o tipo escolhido abre as opções).
func _apply_option(op: Dictionary) -> Array:
	var follow: Array = []
	match str(op["kind"]):
		"card":
			var ci := _new_inst(data.card(op["id"]))
			queue.push_front(ci)
			_refill()
		"mod":
			for ci in cards:
				if ci.uid == op["uid"]:
					if ci.mods == 0:
						ci.first_mod = int(K.MOD_BY_ID[op["mod"]])
					ci.mods |= int(K.MOD_BY_ID[op["mod"]])
		"upgrade":
			for ci in cards:
				if ci.uid == op["uid"]:
					ci.level = mini(ci.level + 1, int(R["card_levels"]["max"]))
		"remove":
			_remove_uid(op["uid"])
		"pick":
			# Ponte vencida: escolheu o tipo, agora escolhe a recompensa (como num local vencido).
			var n := int(R["offers"]["location_win"])
			match str(op["what"]):
				"card":
					follow = _card_options(n, _rarity_filter(R["location_rewards"]["bridge"]["rarities"]))
				"upgrade":
					follow = _level_up_options(n)
				"remove":
					follow = _remove_options(-1)
		"relic":
			gain_relic(str(op["id"]))
		"transform":
			# Bibliotecário: a carta vira outra sorteada de raridade acima (ou igual, se já é lendária).
			for ci in cards:
				if ci.uid == op["uid"]:
					var want := mini(ci.def.rarity + 1, 3)
					var nc := _pick_card(func(cd: CardDef): return cd.rarity == want and cd.id != ci.def.id, [])
					if nc == null:
						nc = _pick_card(func(cd: CardDef): return cd.rarity >= ci.def.rarity and cd.id != ci.def.id, [])
					if nc:
						ci.def = nc
						card_of_uid[ci.uid] = nc.id
		"copy":
			for ci in cards.duplicate():
				if ci.uid == op["uid"]:
					var cp := _new_inst(ci.def)
					cp.level = ci.level
					cp.mods = ci.mods
					cp.first_mod = ci.first_mod
					queue.push_front(cp)
					_refill()
	return follow


func _refill() -> void:
	for i in hand.size():
		if hand[i] == null and queue.size() > 0:
			hand[i] = queue.pop_front()


func _remove_uid(u: int) -> void:
	for ci in cards.duplicate():
		if ci.uid == u:
			cards.erase(ci)
			queue.erase(ci)
			var hi_ := hand.find(ci)
			if hi_ >= 0:
				hand[hi_] = queue.pop_front() if queue.size() > 0 else null


# ================================================================ contratos

func _contract() -> void:
	if contract.is_empty():
		if t >= contract_next and phase == K.Phase.ROAD:
			var cand: Array = []
			var ritual_ahead := false
			for loc in road.locations:
				if loc["type"] == "ritual" and loc["state"] == SimRoad.LocState.ACTIVE and road.is_on_route(loc) and not loc["entered"]:
					ritual_ahead = true
			for c in data.contracts:
				if c["goal"]["kind"] != "ritual_time" or ritual_ahead:
					cand.append(c)
			var c: Dictionary = cand[rng.randi_range(0, cand.size() - 1)]
			var dl := float(c["deadline"])
			if dl < 0.0:
				dl = 120.0
			contract = {"id": c["id"], "goal": c["goal"], "reward": c["reward"], "t": dl, "deadline": dl,
				"progress": 0.0, "window": []}
			emit(K.Ev.CONTRACT, hero.x, hero.y, 0, 0)
		return
	var g: Dictionary = contract["goal"]
	match str(g["kind"]):
		"alive_tag":
			contract["progress"] = maxf(contract["progress"], units.n_pack)
		"structures":
			contract["progress"] = maxf(contract["progress"], units.n_struct)
		"burst":
			var w: Array = contract["window"]
			while w.size() > 0 and t - float(w[0][0]) > float(g["window"]):
				w.pop_front()
			var s := 0.0
			for e in w:
				s += float(e[1])
			contract["progress"] = maxf(contract["progress"], s)
	if float(contract["progress"]) >= float(g["amount"]):
		stats["contracts_ok"] += 1
		emit(K.Ev.CONTRACT, hero.x, hero.y, 1, 0)
		var rw: Dictionary = contract["reward"]
		contract = {}
		_schedule_contract()
		_offer_contract(rw)
		return
	contract["t"] -= dt
	if contract["t"] <= 0.0 or phase != K.Phase.ROAD:
		stats["contracts_fail"] += 1
		emit(K.Ev.CONTRACT, hero.x, hero.y, -1, 0)
		contract = {}
		_schedule_contract()


func _schedule_contract() -> void:
	var iv: Array = R["contracts"]["interval"]
	contract_next = t + rng.randf_range(iv[0], iv[1])


# ================================================================ consultas

func hand_card(i: int) -> CardInst:
	if i < 0 or i >= hand.size():
		return null
	return hand[i]


## Hash do estado, para o teste de determinismo.
func state_hash() -> int:
	var h := hash([tick, hero.x, hero.y, hero.hp, hero.level, elixir, player_level, units.count])
	for i in units.hi:
		if units.alive[i] == 1:
			h = hash([h, units.px[i], units.py[i], units.hp[i]])
	return h

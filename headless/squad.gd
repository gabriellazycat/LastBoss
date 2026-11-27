extends SceneTree
## Esquadrão de balanço (27/11/2026): mede Feitiços e Temporários pelo ganho sobre um esquadrão de referência.
## A party Escudeiro + Clériga + Mago (fase 1, nível 1, vida sempre cheia, sem poderes) fica parada no ponto do
## encontro por --secs segundos. O elixir recarrega como no jogo e um bot joga o esquadrão fixo (SQUAD, monstros que
## ficaram no ponto no duelo, em rodízio) sempre que o elixir dá. A carta testada entra uma vez, de graça (o elixir dela
## é posto antes): Temporário no começo; feitiço no encontro, no meio dos heróis (alvo único: no líder); feitiço de
## cadáver/sacrifício (CORPSE) CORPSE_DELAY s depois do encontro, no meio dos seus monstros perto dos heróis.
## Combos (COMBO): a carta entra numa sequência fixa com parceiros ("*" = a carta), 1,5 s entre cada uma; os
## parceiros são pagos pelo elixir do esquadrão (o desconto do Ritual Profano aparece) e a linha de base é a mesma
## sequência sem a carta.
## Mede: dano (stats.dmg_by_card, vida + escudo) e vida em campo (soma da vida máxima das suas unidades vivas × s).
## godot --headless --path . -s res://headless/squad.gd -- --seeds=5 --secs=60 --out=capturas/esquadrao.json
##   [--cards=a,b]  [--set=web.fx.duration=5;web.cost=1]  (como headless/duel.gd)

var SQUAD: Array = ["ghoul", "rat_horde", "bone_legion"]   # --squad=a,b,c troca (conferir cartas de morte)
const PARTY := ["escudeiro", "cleriga", "mago"]
const COMBO := {
	"shadow_echo": ["spark", "spark", "*"], "arcane_spark": ["spark", "spark", "*"],
	"arcane_apocalypse": ["spark", "spark", "*"], "profane_ritual": ["*", "spark", "spark"],
	"shadow_mark": ["*", "spark", "spark"],
	"eruption": ["oil_splash", "*"], "oil_splash": ["*", "torch"],
	"hunt_instinct": ["wolf_pack", "*"], "mother_nest": ["rat_burrow", "*"],
}
const GAP := 1.5
## Segundos depois do encontro: cadáver/sacrifício (precisa de mortos ou de monstros perto) e contagem de mortes.
const DELAY := {"devour": 8.0, "soul_feast": 8.0, "open_grave": 8.0, "corpse_blast": 8.0, "dark_sacrifice": 8.0,
	"soul_storm": 20.0}
## Miram nos seus monstros perto da party (sacrificam ou usam cadáveres).
const OWN_AIM := ["devour", "soul_feast", "open_grave", "corpse_blast", "dark_sacrifice", "profane_ritual"]
## Miram no último monstro/estrutura de parceiro posto (o Ninho-Mãe dobra o ninho em volta do ponto).
const PARTNER_AIM := ["mother_nest"]
## Fora (REVISAR): ouro (Chuva de Meteoros: o número de meteoros cresce com o ouro) (ignorado por decisão de 27/11) e mão/compra (o bot não tem escolha de carta).
const SKIP := ["dragon_vault", "forbidden_library", "cursed_coins", "gold_dart", "gold_rain", "molten_gold",
	"gold_avalanche", "toll", "blood_tax", "dragon_exchange", "dark_messenger", "meteor_storm"]
const DECK_OF := {"plague": "horde", "dragon": "treasure", "lich": "cult"}

var data: GameData
var secs := 60.0


func _init() -> void:
	var a := {"seeds": "5", "secs": "60", "out": "capturas/esquadrao.json", "cards": "", "set": "", "squad": ""}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and s.contains("="):
			var kv := s.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	secs = float(a["secs"])
	if str(a["squad"]) != "":
		SQUAD = Array(str(a["squad"]).split(","))
	data = GameData.load_dir("res://data")
	data.phase(1)["parties"] = [PARTY]
	_overrides(str(a["set"]))
	var ids: Array = []
	if str(a["cards"]) != "":
		ids = Array(str(a["cards"]).split(","))
	else:
		for d: CardDef in data.cards:
			if (d.type in ["spell", "lair"]) and not SKIP.has(d.id):
				ids.append(d.id)
	ids.sort()
	var seeds := int(a["seeds"])
	var out := {"secs": secs, "seeds": seeds, "squad": SQUAD, "party": PARTY, "set": a["set"], "cases": []}
	# Linhas de base: uma por baralho (o baralho muda regras, ex. o ciclo do Lich) e por sequência de parceiros.
	var bases := {}
	var cases: Array = []
	for id in ids:
		var seq: Array = COMBO.get(id, ["*"])
		var partners: Array = seq.filter(func(x): return x != "*")
		var key := _deck(id) + "|" + ",".join(partners)
		if not bases.has(key):
			bases[key] = true
			cases.append({"card": "", "deck": _deck(id), "seq": partners, "base": key})
		cases.append({"card": id, "deck": _deck(id), "seq": seq, "base": key})
	cases.sort_custom(func(x, y): return x["card"] == "" and y["card"] != "")
	for cs in cases:
		var rs: Array = []
		for sd in seeds:
			rs.append(_run(cs, 100 + sd))
		var row: Dictionary = cs.duplicate()
		for k in ["dmg", "life", "spent", "card_dmg"]:
			var v: Array = rs.map(func(r): return float(r[k]))
			row[k + "_s"] = v
			row[k] = v.reduce(func(x, y): return x + y, 0.0) / seeds
			row[k + "_min"] = v.min()
			row[k + "_max"] = v.max()
		row["road"] = rs.filter(func(r): return str(r["road"]) != "").size()
		row["failed"] = rs.filter(func(r): return bool(r["failed"])).size()
		row["road_why"] = ",".join(rs.map(func(r): return r["road"]).filter(func(x): return x != ""))
		row["cost"] = data.card(cs["card"]).cost if cs["card"] != "" else 0
		out["cases"].append(row)
		print("%-20s %-28s dano %7.0f  vida %8.0f  esquadrão %5.1f elixir%s%s" % [cs["card"] if cs["card"] != "" else "(base)",
			cs["base"], row["dmg"], row["life"], row["spent"],
			"  ESTRADA " + row["road_why"] if row["road"] else "", "  NÃO JOGOU" if row["failed"] else ""])
	var f := FileAccess.open(str(a["out"]), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	quit()


func _deck(id: String) -> String:
	return DECK_OF.get(data.card(id).owner, "horde")


func _overrides(spec: String) -> void:
	for part in spec.split(";", false):
		var kv := part.split("=")
		var path := kv[0].split(".")
		var d := data.card(path[0])
		if d == null:
			push_error("carta não existe: " + path[0])
			continue
		if path[1] == "fx":
			d.fx[path[2]] = float(kv[1])
		elif path[1] == "cost" or path[1] == "count":
			d.set(path[1], int(kv[1]))
		else:
			d.set(path[1], float(kv[1]))


func _run(cs: Dictionary, seed_: int) -> Dictionary:
	_card_paid = 0.0
	var s := Sim.new()
	s.setup(data, seed_, cs["deck"], [], [], 1)
	s.auto_route = true
	s.gold = 999.0
	# Sem disputas de local: a party parada não entra em nenhum (escudo extra e Herói Ajudante mudariam a luta).
	for loc in s.road.locations:
		loc["entered"] = true
	for i in 20:   # a party começa a andar
		_pin(s, false)
		s.step()
	_pin(s, true)   # daqui em diante fica parada aqui
	var d0 := _dealt(s)
	var t0 := s.t
	var spent0 := _spent(s)
	var life := 0.0
	var road := ""
	var failed := false
	var k := 0
	var met := -1.0
	var card: String = cs["card"]
	var seq: Array = (cs["seq"] as Array).duplicate()
	var lair := card != "" and data.card(card).type == "lair" and not COMBO.has(card)
	if lair:
		failed = not _cast(s, card, _center(s))
		seq.erase("*")
	var next_cast := 0.0
	while s.t - t0 < secs and s.phase != K.Phase.OVER:
		# Bot: o próximo do rodízio sai assim que o elixir dá (custo com descontos, como o jogo cobra).
		var partner_due: bool = met >= 0.0 and seq.size() > 0 and s.t >= next_cast and seq[0] != "*"
		var ci := _inst(s, SQUAD[k % SQUAD.size()])
		if not partner_due and s.elixir + 0.0001 >= s.card_cost(ci):
			var sp := _spot(s)
			s.hand[0] = ci
			if s.play(0, sp.x, sp.y) == K.Block.OK:
				k += 1
		if met < 0.0 and _met(s):
			met = s.t
			next_cast = s.t + float(DELAY.get(card, 0.0))
		if met >= 0.0 and seq.size() > 0 and s.t >= next_cast:
			var id: String = seq[0]
			if id == "*":
				var p := _aim(s, card)
				if OWN_AIM.has(card):
					p = _own_center(s)
				elif PARTNER_AIM.has(card):
					p = _last_spot
				failed = not _cast(s, card, p) or failed
				seq.pop_front()
				next_cast = s.t + GAP
			elif s.elixir + 0.0001 >= s.card_cost(_inst(s, id)):
				# Parceiro: pago pelo elixir do esquadrão; monstro/estrutura no ponto do bot, feitiço mirado.
				var pc := _inst(s, id)
				var pp := _spot(s) if pc.def.is_unit else _aim(s, id)
				_last_spot = pp
				s.hand[0] = pc
				s.play(0, pp.x, pp.y)
				seq.pop_front()
				next_cast = s.t + GAP
		_pin(s, true)
		s.step()
		for i in s.units.hi:
			if s.units.alive[i]:
				life += s.units.max_hp[i] * s.dt
		var why := ("contest " if s.contest.size() > 0 else "") + ("offer " if s.offers.size() > 0 else "") 			+ ("route " if s.route_wait else "") + ("act" if s.act_pending else "")
		if why != "":
			if road == "":
				road = why.strip_edges()
			s.offers.clear()
			s.route_wait = false
	if seq.has("*"):
		failed = true
	return {"dmg": _dealt(s) - d0, "life": life, "spent": _spent(s) - spent0 - _card_paid, "road": road,
		"failed": failed, "card_dmg": float(s.stats["dmg_by_card"].get(card, 0.0)) if card != "" else 0.0}


var _card_paid := 0.0
var _last_spot := Vector2.ZERO


## Joga a carta de graça: põe o elixir dela antes (o esquadrão não paga por ela).
func _cast(s: Sim, id: String, p: Vector2) -> bool:
	var ci := _inst(s, id)
	var c := float(s.card_cost(ci))
	s.elixir += c
	s.gold = maxf(s.gold, 999.0)
	s.hand[0] = ci
	var r := s.play(0, p.x, p.y)
	if r != K.Block.OK:
		s.elixir -= c
		push_warning("%s não jogou (%d)" % [id, r])
		return false
	_card_paid += c
	return true


func _inst(s: Sim, id: String) -> Sim.CardInst:
	var ci := Sim.CardInst.new()
	ci.def = data.card(id)
	ci.level = 1
	ci.uid = s.next_uid
	s.next_uid += 1
	s.cards.append(ci)
	s.card_of_uid[ci.uid] = id
	return ci


func _spent(s: Sim) -> float:
	var t := 0.0
	for v in s.stats["spent_act"]:
		t += float(v)
	return t


func _dealt(s: Sim) -> float:
	var t := 0.0
	for v in s.stats["dmg_by_card"].values():
		t += float(v)
	return t


## Meio da party.
func _center(s: Sim) -> Vector2:
	var c := Vector2.ZERO
	var hs := s.all_heroes()
	for h in hs:
		c += Vector2(h.x, h.y)
	return c / float(hs.size())


## Feitiço de alvo único no líder (o herói mais perto do ponto é ele); de área no ponto que pega mais heróis
## (candidatos: cada herói, o meio de cada par e o meio da party; empate fica com o mais perto do líder).
func _aim(s: Sim, id: String) -> Vector2:
	var r := float(data.card(id).fx.get("radius", 0.0))
	var lead := Vector2(s.hero.x, s.hero.y)
	if r <= 0.0:
		return lead
	var hs := s.all_heroes()
	var cand: Array = [_center(s)]
	for i in hs.size():
		cand.append(Vector2(hs[i].x, hs[i].y))
		for j in range(i + 1, hs.size()):
			cand.append((Vector2(hs[i].x, hs[i].y) + Vector2(hs[j].x, hs[j].y)) * 0.5)
	var best: Vector2 = cand[0]
	var bn := -1
	for c: Vector2 in cand:
		var n := 0
		for h in hs:
			if c.distance_to(Vector2(h.x, h.y)) <= r + h.radius:
				n += 1
		if n > bn or (n == bn and c.distance_to(lead) < best.distance_to(lead)):
			bn = n
			best = c
	return best


## Meio dos seus monstros a até 8 m da party (cadáveres e sacrifícios estão ali).
func _own_center(s: Sim) -> Vector2:
	var c := _center(s)
	var sum := Vector2.ZERO
	var n := 0
	for i in s.units.hi:
		if s.units.alive[i] and Vector2(s.units.px[i], s.units.py[i]).distance_to(c) < 8.0:
			sum += Vector2(s.units.px[i], s.units.py[i])
			n += 1
	return sum / float(n) if n > 0 else c


## Onde o bot solta os monstros: na estrada à frente, no primeiro ponto fora dos anéis dos heróis.
func _spot(s: Sim) -> Vector2:
	var d := 4.0
	while d < 30.0:
		var p := s.road.point_at(s.hero.s + d)
		if not s.in_any_ring(p.x, p.y):
			return p
		d += 0.5
	return s.road.point_at(s.hero.s + 30.0)


func _met(s: Sim) -> bool:
	for h in s.all_heroes():
		for i in s.units.hi:
			if s.units.alive[i] and Vector2(s.units.px[i] - h.x, s.units.py[i] - h.y).length() < 3.0:
				return true
	return false


## Party com a vida sempre cheia e sem poderes; com hold, parada onde está.
func _pin(s: Sim, hold: bool) -> void:
	s.powers.clear()
	for h: SimHero in s.all_heroes():
		h.hp = h.max_hp()
	if hold:
		if not s.hero.hold:
			s.hero.hold_x = s.hero.x
			s.hero.hold_y = s.hero.y
		s.hero.hold = true

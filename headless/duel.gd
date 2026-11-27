extends SceneTree
## Duelo de balanço (27/11/2026): cada carta luta sozinha contra o Escudeiro da fase 1 (dano da fase, vida sempre
## cheia, sem poderes de party). A carta (nível I) é posta 6 m à frente dele no começo da estrada; a luta acaba quando a
## carta e tudo o que ela gerou somem, ou em --cap segundos. Mede o dano causado (vida + escudo frontal quebrado, como
## stats.dmg_by_card) e os segundos de vida. Cartas de apoio lutam em dupla com um parceiro fixo (PARTNERS).
## godot --headless --path . -s res://headless/duel.gd -- --seeds=5 --cap=300 --out=capturas/duelo.json
##   [--budget=12]  elixir por teste: a carta entra com round(budget/custo) cópias juntas (custo 0 conta 0,5); a de
##                  apoio entra com 1 cópia ao lado do parceiro no orçamento cheio
##   [--party=1]    golpe do herói da party k da campanha (× rules.party.step^(k−1)); 1 = fase 1 de início
##   [--cards=a,b]  só essas cartas
##   [--set=ogre.hp=1400;ogre.dps=33;rat_burrow.fx.spawn_interval=1.2]  muda números antes (re-simular propostas)

## Cartas que dão bônus a outras: carta -> parceiro (o valor dela é dupla − parceiro sozinho).
const PARTNERS := {
	"rat_king": "rat_horde", "corrupt_piper": "rat_horde", "rabid_rats": "rat_horde",
	"fallen_healer": "ogre", "alpha_beast": "wolf_pack",
	"war_banner": "ogre", "bone_totem": "bone_legion", "furnace": "hell_hound",
}
const SKIP := ["gold_mine"]
const DECK_OF := {"plague": "horde", "dragon": "treasure", "lich": "cult"}

var data: GameData
var cap := 300.0
var budget := 12.0
var party := 1


func _init() -> void:
	var a := {"seeds": "5", "cap": "300", "out": "capturas/duelo.json", "cards": "", "set": "", "budget": "12", "party": "1"}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and s.contains("="):
			var kv := s.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	cap = float(a["cap"])
	budget = float(a["budget"])
	party = int(a["party"])
	data = GameData.load_dir("res://data")
	_overrides(str(a["set"]))
	var ids: Array = []
	if str(a["cards"]) != "":
		ids = Array(str(a["cards"]).split(","))
	else:
		for d: CardDef in data.cards:
			if (d.type in ["monster", "swarm", "structure"]) and not SKIP.has(d.id):
				ids.append(d.id)
	ids.sort()
	var cases: Array = []
	for id in ids:
		cases.append([id])
		if PARTNERS.has(id):
			cases.append([id, PARTNERS[id]])
			if not ids.has(PARTNERS[id]) and not cases.has([PARTNERS[id]]):
				cases.append([PARTNERS[id]])
	var seeds := int(a["seeds"])
	var out := {"cap": cap, "seeds": seeds, "budget": budget, "party": party, "hero_dmg": 0.0, "set": a["set"], "cases": []}
	for cs in cases:
		var rs: Array = []
		for sd in seeds:
			rs.append(_duel(cs, 100 + sd))
		out["hero_dmg"] = rs[0]["hero_hit"]
		var row := {"cards": cs, "copies": _plan(cs).map(func(x): return x[1]), "spent": _spent(cs)}
		for k in ["dmg", "life", "walk"]:
			var v: Array = rs.map(func(r): return float(r[k]))
			row[k] = v.reduce(func(x, y): return x + y, 0.0) / seeds
			row[k + "_min"] = v.min()
			row[k + "_max"] = v.max()
		for k in ["capped", "road", "hung"]:
			row[k] = rs.filter(func(r): return r[k]).size()
		out["cases"].append(row)
		print("%-30s dano %8.1f (%6.0f-%6.0f)  vida %6.1f s (%5.1f-%5.1f)  andou %5.1f m%s%s" % ["+".join(cs),
			row["dmg"], row["dmg_min"], row["dmg_max"], row["life"], row["life_min"], row["life_max"], row["walk"],
			"  TETO" if row["capped"] else "", "  ESTRADA" if row["road"] or row["hung"] else ""])
	var f := FileAccess.open(str(a["out"]), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	quit()


## "id.campo=valor;id.fx.chave=valor": muda o CardDef carregado (só nesta execução, nada é gravado).
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


func _duel(cs: Array, seed_: int) -> Dictionary:
	var s := Sim.new()
	s.setup(data, seed_, DECK_OF.get(data.card(cs[0]).owner, "horde"), [], [], 1)
	s.auto_route = true
	s.hero.level = party   # o golpe sobe rules.party.step por nível (SimHero.damage)
	for i in 20:   # o herói começa a andar
		_pin(s)
		s.step()
	var n0 := s.units.count
	var p := s.road.point_at(s.hero.s + 6.0)
	var k := 0
	for e in _plan(cs):
		for j in int(e[1]):
			# Cópias em volta do ponto (1,2 m entre elas), como um jogador que solta várias juntas.
			var a := float(k) * 2.399963
			var r := 1.2 * sqrt(float(k))
			var ci := Sim.CardInst.new()
			ci.def = data.card(e[0])
			ci.level = 1
			s._apply(ci, p.x + cos(a) * r, p.y + sin(a) * r)
			k += 1
	var d0 := _dealt(s)
	var t0 := s.t
	var s0 := s.hero.s
	var capped := true
	var road := false
	var steps := 0
	var max_steps := int(cap / s.dt) + 600
	while s.t - t0 < cap and s.phase != K.Phase.OVER and steps < max_steps:
		_pin(s)
		s.step()
		steps += 1
		# Algo da estrada entrou no duelo (disputa de local, oferta, bifurcação): a linha fica marcada.
		if s.contest.size() > 0 or s.offers.size() > 0 or s.route_wait or s.act_pending:
			road = true
			s.offers.clear()
			s.route_wait = false
		if s.units.count <= n0:
			capped = false
			break
	return {"dmg": _dealt(s) - d0, "life": s.t - t0, "capped": capped, "road": road, "hung": steps >= max_steps,
		"walk": s.hero.s - s0, "hero_hit": s.hero.damage()}


func _ecost(id: String) -> float:
	return maxf(0.5, float(data.card(id).cost))


## [[id, cópias], ...]: sozinha = orçamento cheio; dupla = apoio com 1 cópia + parceiro no orçamento cheio.
func _plan(cs: Array) -> Array:
	if cs.size() == 1:
		return [[cs[0], maxi(1, roundi(budget / _ecost(cs[0])))]]
	return [[cs[0], 1], [cs[1], maxi(1, roundi(budget / _ecost(cs[1])))]]


## Elixir gasto pela carta medida (na dupla, só o do apoio: o parceiro é descontado no relatório).
func _spent(cs: Array) -> float:
	var e: Array = _plan(cs)[0]
	return _ecost(e[0]) * float(e[1])


## Dano causado = vida tirada + escudo frontal quebrado (o mesmo que a sim soma em stats.dmg_by_card).
func _dealt(s: Sim) -> float:
	var t := 0.0
	for v in s.stats["dmg_by_card"].values():
		t += float(v)
	return t


## Herói com a vida sempre cheia (a vida máxima é a da fase: efeitos em % da vida máxima ficam certos) e sem poderes.
func _pin(s: Sim) -> void:
	s.hero.hp = s.hero.max_hp()
	s.powers.clear()

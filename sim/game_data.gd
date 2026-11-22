class_name GameData
extends RefCounted
## Carrega data/*.json. Nada de número no código: tudo vem daqui.

var rules: Dictionary
var hero: Dictionary
var boss: Dictionary
var modifiers: Dictionary   # id -> dict
var cards: Array[CardDef] = []
var by_id: Dictionary = {}  # id -> CardDef
var pool: Array[CardDef] = []  # cartas que podem ser oferecidas (as 32)
var upgrades: Dictionary = {}  # id -> dict
var meta: Dictionary = {}      # notas da coleção (data/meta.json); as Almas e os custos saíram em 16/11/2026
var relics: Dictionary = {}    # id -> dict (data/relics.json): passivas ganhas no fim de cada ato
var relic_ids: Array = []      # na ordem do arquivo (sorteio determinístico)
var events_def: Dictionary = {}  # id -> dict (data/events.json): eventos de texto do local "?"
var event_ids: Array = []
var hero_classes: Dictionary = {}  # id -> overlay (data/hero_classes.json)
var phases: Array = []             # fases da campanha (data/campaign.json)
var unlock_villain_at: Dictionary = {}   # vilão -> party que, ao ser derrotada, o libera (fase 1 de data/campaign.json)
# SHIMS (plano 21/11/2026: sem Horda sem fim nem mapa da campanha): vazios para game/ seguir compilando; a frente G apaga.
var endless: Dictionary = {}
var campaign_map: Dictionary = {}
var villains: Dictionary = {}      # id -> dict (data/villains.json): os 3 vilões (C3, 10/11/2026)
var villain_ids: Array = []
var free_cards: Array = []         # liberadas desde o início (data/unlocks.json)
var unlock_challenges: Dictionary = {}  # id da carta -> desafio que a libera
var meta_tree: Dictionary = {}     # arvore radial do Covil (data/meta_tree.json, plano 21/11/2026)
var meta_nodes: Dictionary = {}    # id -> no da arvore
var hero_powers: Dictionary = {}   # id -> poder de party (data/hero_powers.json)
var power_ids: Array = []          # na ordem do arquivo
var power_rules: Dictionary = {}   # hero_powers.json "rules" (gap, chance de evolucao...)
var _alias: Dictionary = {}        # id antigo de Pacto -> vilão


static func load_dir(dir := "res://data") -> GameData:
	var g := GameData.new()
	g.rules = _read(dir + "/rules.json")
	g.hero = _read(dir + "/hero_escudeiro.json")
	g.boss = _read(dir + "/boss_lorde.json")
	for m in _read(dir + "/modifiers.json")["modifiers"]:
		g.modifiers[m["id"]] = m
	g.meta = _read(dir + "/meta.json")
	for r in _read(dir + "/relics.json").get("relics", []):
		g.relics[r["id"]] = r
		g.relic_ids.append(r["id"])
	for e in _read(dir + "/events.json").get("events", []):
		g.events_def[e["id"]] = e
		g.event_ids.append(e["id"])
	var growth := float(g.rules["card_levels"]["growth"])
	var cj := _read(dir + "/cards.json")
	var defs: Array = cj["cards"].duplicate()
	# Cartas novas do C6: um arquivo por dono (data/cards_<dono>.json), cada agente dono do seu.
	for own in ["common", "plague", "dragon", "lich"]:
		var extra: String = dir + "/cards_" + own + ".json"
		if FileAccess.file_exists(extra):
			for d in _read(extra).get("cards", []):
				if not d.has("owner"):
					d["owner"] = own
				defs.append(d)
	for d in defs:
		var c := CardDef.from_dict(d, g.cards.size())
		c.growth = growth
		g.cards.append(c)
		g.by_id[c.id] = c
		g.pool.append(c)
	for d in cj["aux_units"]:
		var c := CardDef.from_dict(d, g.cards.size(), "aux")
		g.cards.append(c)
		g.by_id[c.id] = c
	for u in g.hero["upgrades"]:
		g.upgrades[u["id"]] = u
	g.hero_classes = _read(dir + "/hero_classes.json").get("classes", {})
	var camp := _read(dir + "/campaign.json")
	g.phases = camp.get("phases", [])
	g.unlock_villain_at = {}
	for ph in g.phases:
		for vid in ph.get("unlock_villain_at", {}):
			g.unlock_villain_at[str(vid)] = int(ph["unlock_villain_at"][vid])
	# "parties" (fila de parties) é a fonte; "party" (lista plana de classes) e "party_of" (número da party de cada
	# herói) saem dela para o menu e os testes.
	for ph in g.phases:
		if ph.has("parties"):
			var flat: Array = []
			var of: Array = []
			for gi in ph["parties"].size():
				for c in ph["parties"][gi]:
					flat.append(str(c))
					of.append(gi)
			ph["party"] = flat
			ph["party_of"] = of
	for v in _read(dir + "/villains.json").get("villains", []):
		g.villains[v["id"]] = v
		g.villain_ids.append(v["id"])
		for a in v.get("aliases", []):
			g._alias[a] = v["id"]
	var uj := _read(dir + "/unlocks.json")
	g.free_cards = uj.get("free", [])
	g.unlock_challenges = uj.get("challenges", {})
	g.meta_tree = _read(dir + "/meta_tree.json")
	for n in g.meta_tree.get("nodes", []):
		g.meta_nodes[n["id"]] = n
	var hp := _read(dir + "/hero_powers.json")
	g.power_rules = hp.get("rules", {})
	for p in hp.get("powers", []):
		g.hero_powers[p["id"]] = p
		g.power_ids.append(p["id"])
	return g


## Atributos do herói de uma classe: o Escudeiro com a sobreposição da classe (e os multiplicadores da fase).
func hero_of(cls: String, hp_mult := 1.0, dmg_mult := 1.0) -> Dictionary:
	var H: Dictionary = hero.duplicate(true)
	var o: Dictionary = hero_classes.get(cls, {})
	for k in o:
		if k == "hp_mult" or k == "damage_mult":
			continue
		H[k] = o[k]
	H["class"] = cls if hero_classes.has(cls) else "escudeiro"
	H["hp"] = float(hero["hp"]) * float(o.get("hp_mult", 1.0)) * hp_mult
	H["damage"] = float(hero["damage"]) * float(o.get("damage_mult", 1.0)) * dmg_mult
	return H


func phase(n: int) -> Dictionary:
	for p in phases:
		if int(p["id"]) == n:
			return p
	return {}


static func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameData: não abriu " + path)
		return {}
	var v = JSON.parse_string(f.get_as_text())
	if typeof(v) != TYPE_DICTIONARY:
		push_error("GameData: JSON inválido em " + path)
		return {}
	return v


func card(id: String) -> CardDef:
	return by_id.get(id)


## Vilão pelo id (aceita os ids antigos de Pacto: horde, ruin, treasure, crypt, cult). Desconhecido = o primeiro.
func villain_id(id: String) -> String:
	if villains.has(id):
		return id
	return str(_alias.get(id, villain_ids[0] if villain_ids.size() > 0 else ""))


func villain(id: String) -> Dictionary:
	return villains.get(villain_id(id), {})


## Compatível com o código dos Pactos: {"id", "cards" (baralho inicial), "rules"} do vilão.
func deck(deck_id: String) -> Dictionary:
	var v := villain(deck_id)
	return {"id": v.get("id", ""), "cards": v.get("start_deck", []), "rules": v.get("rules", {})}


func has_deck(deck_id: String) -> bool:
	return villains.has(deck_id) or _alias.has(deck_id)


## A carta pode aparecer numa run deste vilão (dele ou comum)?
func in_pool(c: CardDef, vid: String) -> bool:
	return c.owner == "common" or c.owner == vid


## Carta que já vem liberada: está no baralho inicial de algum vilão ou na lista "free" (data/unlocks.json).
func is_start_card(id: String) -> bool:
	if free_cards.has(id):
		return true
	for vid in villain_ids:
		if villains[vid].get("start_deck", []).has(id):
			return true
	return false


## Coleção que liberar o vilão entrega: as cartas dele que já vêm liberadas (baralho inicial e "free").
func villain_cards(vid: String) -> Array:
	var out: Array = []
	for c in pool:
		if c.owner == vid and is_start_card(c.id):
			out.append(c.id)
	return out


## Comuns (owner common) que já vêm liberadas: o resto das comuns só sai por desafio.
func common_cards() -> Array:
	var out: Array = []
	for c in pool:
		if c.owner == "common" and is_start_card(c.id):
			out.append(c.id)
	return out

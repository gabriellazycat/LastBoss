class_name GameData
extends RefCounted
## Carrega data/*.json. Nada de número no código: tudo vem daqui.

var rules: Dictionary
var hero: Dictionary
var boss: Dictionary
var contracts: Array
var modifiers: Dictionary   # id -> dict
var cards: Array[CardDef] = []
var by_id: Dictionary = {}  # id -> CardDef
var pool: Array[CardDef] = []  # cartas que podem ser oferecidas (as 32)
var upgrades: Dictionary = {}  # id -> dict
var meta: Dictionary = {}      # coleção, custos de desbloqueio e Almas (data/meta.json)
var relics: Dictionary = {}    # id -> dict (data/relics.json): passivas ganhas no fim de cada ato
var relic_ids: Array = []      # na ordem do arquivo (sorteio determinístico)
var events_def: Dictionary = {}  # id -> dict (data/events.json): eventos de texto do local "?"
var event_ids: Array = []
var hero_classes: Dictionary = {}  # id -> overlay (data/hero_classes.json)
var phases: Array = []             # fases da campanha (data/campaign.json)


static func load_dir(dir := "res://data") -> GameData:
	var g := GameData.new()
	g.rules = _read(dir + "/rules.json")
	g.hero = _read(dir + "/hero_escudeiro.json")
	g.boss = _read(dir + "/boss_lorde.json")
	g.contracts = _read(dir + "/contracts.json")["contracts"]
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
	for d in cj["cards"]:
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
	g.phases = _read(dir + "/campaign.json").get("phases", [])
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


func deck(deck_id: String) -> Dictionary:
	for d in boss["decks"]:
		if d["id"] == deck_id:
			return d
	return boss["decks"][0]


func has_deck(deck_id: String) -> bool:
	for d in boss["decks"]:
		if d["id"] == deck_id:
			return true
	return false

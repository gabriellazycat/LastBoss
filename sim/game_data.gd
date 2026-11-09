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


static func load_dir(dir := "res://data") -> GameData:
	var g := GameData.new()
	g.rules = _read(dir + "/rules.json")
	g.hero = _read(dir + "/hero_escudeiro.json")
	g.boss = _read(dir + "/boss_lorde.json")
	g.contracts = _read(dir + "/contracts.json")["contracts"]
	for m in _read(dir + "/modifiers.json")["modifiers"]:
		g.modifiers[m["id"]] = m
	g.meta = _read(dir + "/meta.json")
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
	return g


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

class_name CardModel
extends RefCounted
## Cartas sem modelo próprio usam o de outra (campo "model" em data/cards.json): Ratos Raivosos → rato,
## Tocha → ícone do Incêndio etc. (rodada autônoma de 09/11/2026).

static var _alias: Dictionary = {}
static var _art: Dictionary = {}


static func of(id: String) -> String:
	if _alias.is_empty():
		_alias["_"] = "_"
		# cards.json e as cartas novas por dono (C6): data/cards_<dono>.json.
		for path in ["res://data/cards.json", "res://data/cards_common.json", "res://data/cards_plague.json",
				"res://data/cards_dragon.json", "res://data/cards_lich.json"]:
			if not FileAccess.file_exists(path):
				continue
			var j = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(j) != TYPE_DICTIONARY:
				continue
			for c in j.get("cards", []):
				if c.has("model"):
					_alias[str(c["id"])] = str(c["model"])
				if c.has("art"):
					_art[str(c["id"])] = str(c["art"])
	return str(_alias.get(id, id))


## Desenho 2D (interface Diário) de uma carta sem desenho próprio.
static func art_of(id: String) -> String:
	of(id)
	return str(_art.get(id, _alias.get(id, id)))

class_name CardModel
extends RefCounted
## Cartas sem modelo próprio usam o de outra (campo "model" em data/cards.json): Ratos Raivosos → rato,
## Tocha → ícone do Incêndio etc. (rodada autônoma de 09/11/2026).

static var _alias: Dictionary = {}
static var _art: Dictionary = {}


static func of(id: String) -> String:
	if _alias.is_empty():
		_alias["_"] = "_"
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
		if typeof(j) == TYPE_DICTIONARY:
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

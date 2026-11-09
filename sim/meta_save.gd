class_name MetaSave
extends RefCounted
## Progresso entre runs: Almas, cartas desbloqueadas, deck montado e Pacto. Nunca é apagado no fim da run.
## Regras de montagem em rules.deck; custos e fórmula das Almas em data/meta.json.

const PATH := "user://meta.save"

var data: GameData
var souls := 0
var unlocked: Array = []
var deck: Array = []
var pact := "horde"
var runs := 0


static func load_or_new(d: GameData, path := PATH) -> MetaSave:
	var m := MetaSave.new()
	m.data = d
	m.unlocked = d.meta["start_collection"].duplicate()
	m.deck = d.deck("horde")["cards"].duplicate()
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		var v = f.get_var()
		if typeof(v) == TYPE_DICTIONARY:
			m.souls = int(v.get("souls", 0))
			m.runs = int(v.get("runs", 0))
			m.pact = str(v.get("pact", "horde"))
			for id in v.get("unlocked", []):
				if d.card(id) and not m.unlocked.has(id):
					m.unlocked.append(id)
			var dk: Array = v.get("deck", []).filter(func(id): return d.card(id) != null)
			if m.deck_errors(dk).is_empty():
				m.deck = dk
	return m


func save(path := PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"souls": souls, "unlocked": unlocked, "deck": deck, "pact": pact, "runs": runs})
	return true


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func unlock_cost(id: String) -> int:
	return int(data.meta["unlock_cost"][K.RARITIES[data.card(id).rarity]])


func unlock(id: String) -> bool:
	if is_unlocked(id) or souls < unlock_cost(id):
		return false
	souls -= unlock_cost(id)
	unlocked.append(id)
	return true


## Problemas do deck como chaves de texto (vazio = pode jogar).
func deck_errors(list: Array) -> Array:
	var D: Dictionary = data.rules["deck"]
	var errs: Array = []
	if list.size() != int(D["size"]):
		errs.append("DECKERR_size")
	var fin := 0
	for id in list:
		if list.count(id) > int(D["max_copies"]) and not errs.has("DECKERR_copies"):
			errs.append("DECKERR_copies")
		if not unlocked.has(id) and not errs.has("DECKERR_locked"):
			errs.append("DECKERR_locked")
		if data.card(id).category == "finisher":
			fin += 1
	if fin > int(D["max_finishers"]):
		errs.append("DECKERR_finishers")
	return errs


## A carta pode entrar no deck agora (sem passar do tamanho, das cópias nem das finalizações)?
func can_add(id: String) -> bool:
	var D: Dictionary = data.rules["deck"]
	if not is_unlocked(id) or deck.size() >= int(D["size"]) or deck.count(id) >= int(D["max_copies"]):
		return false
	if data.card(id).category == "finisher":
		return deck.filter(func(x): return data.card(x).category == "finisher").size() < int(D["max_finishers"])
	return true


## Almas de uma run: dano no herói, locais por onde ele passou e bônus de vitória.
static func souls_for(d: GameData, stats: Dictionary) -> int:
	var S: Dictionary = d.meta["souls"]
	var dmg := 0.0
	for k in stats["dmg_by_card"]:
		dmg += float(stats["dmg_by_card"][k])
	var n := dmg / float(S["damage_per_soul"]) + int(stats["locs_visited"]) * float(S["per_location"])
	if stats["result"] in ["win", "win_early"]:
		n += float(S["win"])
	if stats["result"] == "win_early":
		n += float(S["win_early_extra"])
	return int(round(n))


## Credita a run terminada e grava.
func add_run(stats: Dictionary, path := PATH) -> int:
	var n := souls_for(data, stats)
	souls += n
	runs += 1
	save(path)
	return n

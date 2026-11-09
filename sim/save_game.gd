class_name SaveGame
extends RefCounted
## Salvamento da run em andamento: copia as variáveis de script de cada parte do Sim.
## A retomada é idêntica: o estado do gerador aleatório vai junto.

const PATH := "user://run.save"
const VERSION := 2                  # 2: estrada em rede de nós (09/11/2026); salvamentos antigos não carregam
const SKIP := ["sim", "data", "R", "H", "AI", "A", "tmp", "events", "script"]
const PARTS := ["units", "hero", "road", "arena"]


static func _dump(obj: Object) -> Dictionary:
	var d := {}
	for p in obj.get_property_list():
		if not (p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var n: String = p["name"]
		# O gerador do Sim vai à parte (seed/state); o `rng` das unidades é o alcance e precisa ir junto.
		if n in SKIP or n in PARTS or obj.get(n) is RandomNumberGenerator:
			continue
		d[n] = obj.get(n)
	return d


static func _ci(c) -> Variant:
	if c == null:
		return null
	return {"uid": c.uid, "id": c.def.id, "mods": c.mods, "level": c.level}


static func save(sim: Sim, path := PATH) -> bool:
	var d := _dump(sim)
	d["hand"] = sim.hand.map(_ci)
	d["queue"] = sim.queue.map(_ci)
	d["cards"] = sim.cards.map(_ci)
	d["__ver"] = VERSION
	d["__rng_seed"] = sim.rng.seed
	d["__rng_state"] = sim.rng.state
	for part in PARTS:
		d["__" + part] = _dump(sim.get(part))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(d)
	return true


static func exists(path := PATH) -> bool:
	return FileAccess.file_exists(path)


static func erase(path := PATH) -> void:
	if exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func load_run(data: GameData, path := PATH) -> Sim:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d = f.get_var()
	if typeof(d) != TYPE_DICTIONARY or int(d.get("__ver", 1)) < VERSION:
		return null
	var sim := Sim.new()
	sim.setup(data, int(d["run_seed"]), str(d["deck_id"]))
	if d["phase"] != K.Phase.ROAD:
		sim.arena.setup(sim, Vector2.ZERO, Vector2(0, -1))
	for part in PARTS:
		var obj: Object = sim.get(part)
		var pd: Dictionary = d["__" + part]
		for k in pd:
			obj.set(k, pd[k])
	var by_uid := {}
	var cards: Array = []
	for c in d["cards"]:
		var ci := Sim.CardInst.new()
		ci.def = data.card(c["id"])
		ci.uid = c["uid"]
		ci.mods = c["mods"]
		ci.level = int(c.get("level", 1))
		by_uid[ci.uid] = ci
		cards.append(ci)
	for k in d:
		if str(k).begins_with("__") or k in ["hand", "queue", "cards"]:
			continue
		sim.set(k, d[k])
	sim.cards = cards
	sim.hand = d["hand"].map(func(c): return by_uid.get(c["uid"]) if c != null else null)
	sim.queue = d["queue"].map(func(c): return by_uid.get(c["uid"]))
	sim.rng.seed = d["__rng_seed"]
	sim.rng.state = d["__rng_state"]
	return sim

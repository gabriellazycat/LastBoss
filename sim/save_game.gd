class_name SaveGame
extends RefCounted
## Salvamento da run em andamento: copia as variáveis de script de cada parte do Sim.
## A retomada é idêntica: o estado do gerador aleatório vai junto.

const PATH := "user://run.save"
## Arquivo em uso. Os modos de teste e de captura da janela (main.gd com argumentos) trocam para outro
## arquivo: antes, o salvamento automático deles sobrescrevia a run salva do jogador (rodada 09/11/2026).
static var current := PATH
const VERSION := 5                  # 5: vilões no lugar dos Pactos; 4: baralho com descarte (10/11/2026)
const _V3 := 3                  # 3: run em 3 atos, disputas e relíquias (09/11/2026); 2: estrada em rede de nós
const SKIP := ["sim", "data", "R", "H", "AI", "A", "tmp", "events", "script", "followers", "hit_hero", "helper"]
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


static func _p(path: String) -> String:
	return current if path == "" else path


static func _ci(c) -> Variant:
	if c == null:
		return null
	return {"uid": c.uid, "id": c.def.id, "mods": c.mods, "first_mod": c.first_mod, "level": c.level, "discount": c.discount}


static func save(sim: Sim, path := "") -> bool:
	path = _p(path)
	var d := _dump(sim)
	d["hand"] = sim.hand.map(_ci)
	d["queue"] = sim.queue.map(_ci)
	d["discard"] = sim.discard.map(_ci)
	d["benched"] = sim.benched.map(_ci)
	d["cards"] = sim.cards.map(_ci)
	d["__ver"] = VERSION
	d["__rng_seed"] = sim.rng.seed
	d["__rng_state"] = sim.rng.state
	for part in PARTS:
		d["__" + part] = _dump(sim.get(part))
	d["__followers"] = sim.followers.map(func(h): return _dump(h))
	if sim.helper != null:
		d["__helper"] = _dump(sim.helper)   # Herói Ajudante em disputa (11/11/2026): volta igual na retomada
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(d)
	return true


static func exists(path := "") -> bool:
	return FileAccess.file_exists(_p(path))


static func erase(path := "") -> void:
	path = _p(path)
	if exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func load_run(data: GameData, path := "") -> Sim:
	path = _p(path)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d = f.get_var()
	if typeof(d) != TYPE_DICTIONARY or int(d.get("__ver", 1)) < VERSION:
		return null
	var sim := Sim.new()
	sim.setup(data, int(d["run_seed"]), str(d["deck_id"]), [], [], int(d.get("campaign_phase", 1)))
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
		ci.first_mod = int(c.get("first_mod", 0))
		ci.level = int(c.get("level", 1))
		ci.discount = int(c.get("discount", 0))
		by_uid[ci.uid] = ci
		cards.append(ci)
	for k in d:
		if str(k).begins_with("__") or k in ["hand", "queue", "discard", "benched", "cards"]:
			continue
		sim.set(k, d[k])
	sim.cards = cards
	sim.hand = d["hand"].map(func(c): return by_uid.get(c["uid"]) if c != null else null)
	sim.queue = d["queue"].map(func(c): return by_uid.get(c["uid"]))
	sim.discard = d.get("discard", []).map(func(c): return by_uid.get(c["uid"]))
	sim.benched = d.get("benched", []).map(func(c): return by_uid.get(c["uid"]))
	sim.rng.seed = d["__rng_seed"]
	sim.rng.state = d["__rng_state"]
	sim.hero.H = data.hero_of(sim.party_class(sim.hero.pidx), sim.phase_hp_mult, sim.phase_dmg_mult)
	for fd in d.get("__followers", []):
		var fh := SimHero.new()
		fh.setup(sim)
		for k in fd:
			fh.set(k, fd[k])
		fh.H = data.hero_of(sim.party_class(fh.pidx), sim.phase_hp_mult, sim.phase_dmg_mult)
		sim.followers.append(fh)
	# Herói Ajudante: refeito com a classe da disputa. Sem ele (save antigo), a disputa termina como falha.
	if d.has("__helper") and str(sim.contest.get("type", "")) == "helper":
		var ah := SimHero.new()
		ah.setup(sim)
		for k in d["__helper"]:
			ah.set(k, d["__helper"][k])
		ah.H = data.hero_of(str(sim.contest.get("cls", "escudeiro")), sim.phase_hp_mult, sim.phase_dmg_mult)
		ah.AI = ah.H["ai"]
		sim.helper = ah
	sim.rebuild_rfx()
	return sim

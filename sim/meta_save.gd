class_name MetaSave
extends RefCounted
## Progresso entre runs: Almas, cartas liberadas, vilões liberados e fases vencidas. Nunca é apagado no fim da run.
## Vilões (C3, 10/11/2026): liberar um vilão entrega as comuns e incomuns dele e as raras iniciais
## (data/villains.json); as comuns (owner common) comuns e incomuns vêm de início; Almas compram só raras e
## lendárias. Custos e fórmula das Almas em data/meta.json.

const PATH := "user://meta.save"
const VERSION := 3                 # 2: vilões no lugar dos Pactos (10/11/2026); 3: cartas liberadas por desafio (13/11/2026)

var data: GameData
var souls := 0
var unlocked: Array = []
var villain := "plague"            # vilão escolhido para a próxima run
var villains: Array = ["plague"]   # vilões liberados
var runs := 0
var phases_won: Array = []
## Fases 3 e 4 pagam uma rara à escolha: quantas escolhas o jogador ainda tem para fazer no menu.
var rare_choices := 0
## Desafios de desbloqueio (data/unlocks.json): fases vencidas por vilão, heróis derrotados no total e o melhor
## progresso de cada carta ainda bloqueada ({id: {"v", "g"}}), para a coleção mostrar "11/15".
var wins_by_villain: Dictionary = {}
var heroes_total := 0
var progress: Dictionary = {}
## Para onde salvar. Os modos de teste da janela trocam para outro arquivo: o --menutest gravava o vilão
## escolhido no meta do jogador (rodada 09/11/2026).
var file := PATH

## Compatibilidade com a interface dos Pactos (até o menu de vilões substituir as telas antigas).
var pact: String:
	get:
		return villain
	set(v):
		villain = data.villain_id(v) if data else v
var pacts: Array:
	get:
		return villains
var deck: Array:
	get:
		return data.deck(villain)["cards"] if data else []


static func load_or_new(d: GameData, path := PATH) -> MetaSave:
	var m := MetaSave.new()
	m.data = d
	m.file = path
	m.unlocked = d.common_cards()
	m.villains = []
	m.unlock_villain(d.villain_ids[0])
	m.villain = d.villain_ids[0]
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		var v = f.get_var()
		if typeof(v) == TYPE_DICTIONARY:
			m.souls = int(v.get("souls", 0))
			m.runs = int(v.get("runs", 0))
			m.rare_choices = int(v.get("rare_choices", 0))
			# Save antigo (Pactos): horde → Praga, ruin/treasure → Dragão, crypt/cult → Lich; Almas ficam.
			for pid in v.get("villains", v.get("pacts", [])):
				m.unlock_villain(d.villain_id(str(pid)))
			for ph in v.get("phases_won", []):
				if not m.phases_won.has(int(ph)):
					m.phases_won.append(int(ph))
			m.villain = d.villain_id(str(v.get("villain", v.get("pact", m.villain))))
			if not m.villains.has(m.villain):
				m.villain = d.villain_ids[0]
			m.heroes_total = int(v.get("heroes_total", 0))
			m.wins_by_villain = v.get("wins_by_villain", {})
			m.progress = v.get("progress", {})
			# Saves antigos (até a versão 2) tinham cartas compradas com Almas: o sistema de desafios recomeça da coleção inicial.
			if int(v.get("ver", 1)) >= 3:
				for id in v.get("unlocked", []):
					if d.card(id) and not m.unlocked.has(id):
						m.unlocked.append(id)
	return m


func save(path := "") -> bool:
	var f := FileAccess.open(file if path == "" else path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"ver": VERSION, "souls": souls, "unlocked": unlocked, "villain": villain, "villains": villains,
		"runs": runs, "phases_won": phases_won, "rare_choices": rare_choices,
		"wins_by_villain": wins_by_villain, "heroes_total": heroes_total, "progress": progress})
	return true


## Libera um vilão e a coleção dele (comuns, incomuns e raras iniciais).
func unlock_villain(id: String) -> void:
	if not data.villains.has(id):
		return
	if not villains.has(id):
		villains.append(id)
	for cid in data.villain_cards(id):
		if not unlocked.has(cid):
			unlocked.append(cid)


func unlock_pact(id: String) -> void:
	unlock_villain(data.villain_id(id))


## Fase vencida: guarda, libera o vilão que ela dá e paga Almas/rara à escolha (data/campaign.json).
## Devolve o vilão liberado ("" se nenhum novo).
func win_phase(n: int) -> String:
	var first := not phases_won.has(n)
	if first:
		phases_won.append(n)
	var ph: Dictionary = data.phase(n)
	if first:
		souls += int(ph.get("reward_souls", 0))
		# A rara à escolha saiu (13/11/2026): cartas bloqueadas só se liberam por desafio.
	var vid := str(ph.get("unlock_villain", ""))
	if vid != "" and not villains.has(vid):
		unlock_villain(vid)
		return vid
	return ""


## Até n raras ainda bloqueadas dos vilões liberados (e comuns), para a recompensa "rara à escolha".
func rare_choice_options(n := 3, seed_ := 0) -> Array:
	var cand: Array = []
	for c in data.pool:
		if c.rarity == 2 and not unlocked.has(c.id) and (c.owner == "common" or villains.has(c.owner)):
			cand.append(c.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ if seed_ != 0 else runs * 7919 + souls
	var out: Array = []
	while out.size() < n and cand.size() > 0:
		out.append(cand.pop_at(rng.randi_range(0, cand.size() - 1)))
	return out


func choose_rare(id: String) -> bool:
	if rare_choices <= 0 or unlocked.has(id) or data.card(id) == null:
		return false
	rare_choices -= 1
	unlocked.append(id)
	return true


func phase_open(n: int) -> bool:
	return n <= 0 or phases_won.has(n - 1)


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func unlock_cost(id: String) -> int:
	return int(data.meta["unlock_cost"][K.RARITIES[data.card(id).rarity]])


## Almas compram só raras e lendárias de vilões liberados (ou comuns).
func can_buy(_id: String) -> bool:
	return false   # 13/11/2026: nada se compra mais com Almas; as cartas se liberam por desafio


func unlock(_id: String) -> bool:
	return false


## Fim de uma fase da campanha (vitória ou derrota): confere os desafios das cartas ainda bloqueadas do vilão
## jogado (e das comuns), libera as cumpridas e guarda o melhor progresso das outras.
## Devolve {"done": [{id, v, g}], "near": [...]}; chamar antes de win_phase (que registra a fase vencida).
func apply_unlocks(sim: Sim, won: bool, path := "") -> Dictionary:
	if sim.campaign_phase <= 0:
		return {"done": [], "near": []}   # a fase de tutorial não libera nada
	var vid := sim.deck_id
	var locked: Array = []
	for c in data.pool:
		if data.in_pool(c, vid) and not unlocked.has(c.id) and data.unlock_challenges.has(c.id):
			locked.append(c.id)
	var ctx := {"won": won, "villain": vid, "phase": sim.campaign_phase, "wins_by_villain": wins_by_villain,
		"phases_won": phases_won, "heroes_total": heroes_total}
	var res: Dictionary = sim.track.check(sim.stats, ctx, locked)
	for p in res["done"]:
		if not unlocked.has(p["id"]):
			unlocked.append(p["id"])
		progress.erase(p["id"])
	for p in res["near"]:
		var old: Dictionary = progress.get(p["id"], {})
		if float(p["v"]) / maxf(float(p["g"]), 0.001) >= float(old.get("v", 0.0)) / maxf(float(old.get("g", 1.0)), 0.001):
			progress[p["id"]] = {"v": p["v"], "g": p["g"]}
	if won:
		wins_by_villain[vid] = int(wins_by_villain.get(vid, 0)) + 1
	heroes_total += int(sim.stats.get("heroes_fallen", 0))
	save(path)
	return res


## Cartas que as ofertas da run deste vilão podem sortear (coleção dele e comuns).
func run_pool(vid := "") -> Array:
	var v := data.villain_id(vid if vid != "" else villain)
	return unlocked.filter(func(id): return data.in_pool(data.card(id), v))


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
func add_run(stats: Dictionary, path := "") -> int:
	var n := souls_for(data, stats)
	souls += n
	runs += 1
	save(path)
	return n

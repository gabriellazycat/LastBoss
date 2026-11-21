class_name MetaSave
extends RefCounted
## Progresso entre runs: cartas liberadas, vilões liberados e fases vencidas. Nunca é apagado no fim da run.
## Vilões (C3, 10/11/2026): liberar um vilão entrega as comuns e incomuns dele e as raras iniciais
## (data/villains.json); as comuns (owner common) comuns e incomuns vêm de início. As outras cartas se liberam
## por desafio (data/unlocks.json). As Almas saíram do jogo em 16/11/2026: o campo "souls" de saves antigos é ignorado.

const PATH := "user://meta.save"
const VERSION := 4                 # 2: vilões no lugar dos Pactos (10/11/2026); 3: cartas liberadas por desafio (13/11/2026); 4: campanha em 7 fases e heróis vistos (16/11/2026)

var data: GameData
var unlocked: Array = []
var villain := "plague"            # vilão escolhido para a próxima run
var villains: Array = ["plague"]   # vilões liberados
var runs := 0
var phases_won: Array = []
## Classes de herói que o jogador já enfrentou numa run (16/11/2026): o mapa da campanha só revela essas; as
## outras aparecem como "?". Saves de antes da versão 4 começam com as classes das fases que já venceram.
var heroes_seen: Array = []
## Fases 3 e 4 pagam uma rara à escolha: quantas escolhas o jogador ainda tem para fazer no menu.
var rare_choices := 0
## Desafios de desbloqueio (data/unlocks.json): fases vencidas por vilão, heróis derrotados no total e o melhor
## progresso de cada carta ainda bloqueada ({id: {"v", "g"}}), para a coleção mostrar "11/15".
var wins_by_villain: Dictionary = {}
var endless_best: Dictionary = {}   # Horda sem fim (19/11/2026): vilão -> mais parties derrubadas numa run
var heroes_total := 0
var progress: Dictionary = {}
## Desafios entre fases (15/11/2026): contadores somados por vilão ({vid: {"plays|spell": 412.0}}; a chave "_old"
## guarda os heróis derrotados de antes, que só contam para cartas comuns) e, por carta, em quantas fases o feito
## de um desafio "em N fases diferentes" já aconteceu. Runs perdidas também somam.
var totals: Dictionary = {}
var runs_done: Dictionary = {}
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
			m.runs = int(v.get("runs", 0))
			m.rare_choices = int(v.get("rare_choices", 0))
			# Save antigo (Pactos): horde → Praga, ruin/treasure → Dragão, crypt/cult → Lich.
			for pid in v.get("villains", v.get("pacts", [])):
				m.unlock_villain(d.villain_id(str(pid)))
			for ph in v.get("phases_won", []):
				if not m.phases_won.has(int(ph)):
					m.phases_won.append(int(ph))
			for cls in v.get("heroes_seen", []):
				m.see_hero(str(cls))
			# Campanha de 16/11/2026: a fase 4 antiga (Companhia) virou a Capital (6) e a 4 é o Forte; quem tinha a 4
			# vencida fica com o Forte vencido. Heróis vistos: os das fases já vencidas.
			if int(v.get("ver", 1)) < 4:
				for ph in m.phases_won:
					for cls in d.phase(int(ph)).get("party", []):
						m.see_hero(str(cls))
			m.villain = d.villain_id(str(v.get("villain", v.get("pact", m.villain))))
			if not m.villains.has(m.villain):
				m.villain = d.villain_ids[0]
			m.heroes_total = int(v.get("heroes_total", 0))
			m.wins_by_villain = v.get("wins_by_villain", {})
			m.endless_best = v.get("endless_best", {})
			m.progress = v.get("progress", {})
			m.runs_done = v.get("runs_done", {})
			if v.has("totals"):
				m.totals = v["totals"]
			elif m.heroes_total > 0:
				m.totals = {"_old": {"heroes|": float(m.heroes_total)}}
			# Saves antigos (até a versão 2) tinham cartas compradas: o sistema de desafios recomeça da coleção inicial.
			if int(v.get("ver", 1)) >= 3:
				for id in v.get("unlocked", []):
					if d.card(id) and not m.unlocked.has(id):
						m.unlocked.append(id)
	return m


func save(path := "") -> bool:
	var f := FileAccess.open(file if path == "" else path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"ver": VERSION, "unlocked": unlocked, "villain": villain, "villains": villains,
		"runs": runs, "phases_won": phases_won, "heroes_seen": heroes_seen, "rare_choices": rare_choices,
		"wins_by_villain": wins_by_villain, "heroes_total": heroes_total, "progress": progress,
		"totals": totals, "runs_done": runs_done, "endless_best": endless_best})
	return true


## Horda sem fim: guarda `n` parties derrubadas com o vilão `vid` se for o recorde dele. Devolve se bateu o recorde.
func record_endless(vid: String, n: int) -> bool:
	vid = data.villain_id(vid)
	if n <= int(endless_best.get(vid, 0)):
		return false
	endless_best[vid] = n
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


## Fase vencida: guarda e libera o vilão que ela dá (data/campaign.json).
## Devolve o vilão liberado ("" se nenhum novo).
func win_phase(n: int) -> String:
	if not phases_won.has(n):
		phases_won.append(n)
	var ph: Dictionary = data.phase(n)
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
	rng.seed = seed_ if seed_ != 0 else runs * 7919 + 1
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


## Marca a classe como enfrentada (o mapa da campanha passa a mostrá-la). Devolve true se é nova.
func see_hero(cls: String) -> bool:
	if cls == "" or heroes_seen.has(cls):
		return false
	heroes_seen.append(cls)
	return true


func phase_open(n: int) -> bool:
	return n <= 0 or phases_won.has(n - 1)


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


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
		"phases_won": phases_won, "heroes_total": heroes_total, "runs_done": runs_done,
		"totals_villain": totals_of(vid), "totals_all": totals_all()}
	var res: Dictionary = sim.track.check(sim.stats, ctx, locked)
	for p in res["done"]:
		if not unlocked.has(p["id"]):
			unlocked.append(p["id"])
		progress.erase(p["id"])
		runs_done.erase(p["id"])
	for p in res["near"]:
		var old: Dictionary = progress.get(p["id"], {})
		if p.get("acc", false) or float(p["v"]) / maxf(float(p["g"]), 0.001) >= float(old.get("v", 0.0)) / maxf(float(old.get("g", 1.0)), 0.001):
			progress[p["id"]] = {"v": p["v"], "g": p["g"]}
		if p.get("hit", false):
			runs_done[p["id"]] = int(runs_done.get(p["id"], 0)) + 1
	var mine: Dictionary = totals.get(vid, {})
	var add: Dictionary = sim.track.phase_totals(sim.stats, ctx)
	for k in add:
		mine[k] = float(mine.get(k, 0.0)) + float(add[k])
	totals[vid] = mine
	if won:
		wins_by_villain[vid] = int(wins_by_villain.get(vid, 0)) + 1
	heroes_total += int(sim.stats.get("heroes_fallen", 0))
	save(path)
	return res


## Contadores acumulados de um vilão (mais os heróis derrotados antes de 15/11/2026, que valem para todos).
func totals_of(vid: String) -> Dictionary:
	var out: Dictionary = totals.get(vid, {}).duplicate()
	var old: Dictionary = totals.get("_old", {})
	for k in old:
		out[k] = float(out.get(k, 0.0)) + float(old[k])
	return out


## Contadores acumulados de todos os vilões somados (cartas comuns contam as fases de qualquer vilão).
func totals_all() -> Dictionary:
	var out := {}
	for vid in totals:
		for k in totals[vid]:
			out[k] = float(out.get(k, 0.0)) + float(totals[vid][k])
	return out


## Cartas que as ofertas da run deste vilão podem sortear (coleção dele e comuns).
func run_pool(vid := "") -> Array:
	var v := data.villain_id(vid if vid != "" else villain)
	return unlocked.filter(func(id): return data.in_pool(data.card(id), v))


## Conta a run terminada e grava.
func add_run(path := "") -> void:
	runs += 1
	save(path)

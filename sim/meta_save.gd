class_name MetaSave
extends RefCounted
## Progresso entre runs (v5, plano 21/11/2026): Almas, arvore do Covil, niveis de carta e de reliquia, decks de 19,
## cartas e reliquias liberadas por desafio, vilões liberados e recordes. Nunca é apagado no fim da run.
## As Almas vêm do dano nos heróis e dos heróis mortos (apply_run) e são mantidas ao perder; o reembolso total
## é grátis e conserva (depois de refund_all, almas == almas_earned).
## Vilões: liberar um vilão entrega as comuns e incomuns dele e as raras iniciais (data/villains.json); as comuns
## (owner common) comuns e incomuns vêm de início. As outras cartas e as reliquias não livres se liberam por
## desafio (data/unlocks.json, data/relics.json "free"/"challenge").

const PATH := "user://meta.save"
const VERSION := 5                 # 5: Almas, arvore do Covil e 15 parties (21/11/2026); save de versao menor zera
const DECK_SIZE := 19              # cartas do deck montado
const DECK_COPIES := 3             # copias maximas de uma carta no deck

var data: GameData
var unlocked: Array = []
var villain := "plague"            # vilão escolhido para a próxima run
var villains: Array = ["plague"]   # vilões liberados
var runs := 0
## Classes de herói que o jogador já enfrentou numa run (o compêndio só revela essas).
var heroes_seen: Array = []
## Desafios de desbloqueio (data/unlocks.json): runs vencidas por vilão, heróis derrotados no total e o melhor
## progresso de cada carta/reliquia ainda bloqueada ({id: {"v", "g"}}; reliquias com o prefixo "r:").
var wins_by_villain: Dictionary = {}
var heroes_total := 0
var progress: Dictionary = {}
## Contadores somados por vilão ({vid: {"plays|spell": 412.0}}; a chave "_old" soma para todos) e, por carta/reliquia,
## em quantas runs o feito de um desafio "em N runs" já aconteceu. Runs perdidas também somam.
var totals: Dictionary = {}
var runs_done: Dictionary = {}
## Para onde salvar. Os modos de teste da janela trocam para outro arquivo.
var file := PATH

var almas := 0                     # saldo de Almas (moeda da meta; o ouro e da run)
var almas_earned := 0              # total ganho na vida do save: o reembolso total devolve exatamente isto
var upgrades: Dictionary = {}      # id do no da arvore (data/meta_tree.json) -> nivel comprado (1..custos.size())
var card_levels: Dictionary = {}   # id da carta -> nivel I..VI (1 = sem melhoria)
var decks: Dictionary = {}         # id do vilao -> deck montado (19 ids)
var relic_levels: Dictionary = {}  # id da reliquia -> nivel 1..3
var relics_unlocked: Array = []    # reliquias liberadas (as livres entram na criacao; o resto por desafio)
var best_party := 0                # mais parties derrubadas numa run
var best_by_villain: Dictionary = {}   # vilao -> mais parties derrubadas com ele
var act2_reached := false          # o jogador ja chegou ao ato 2 (abre o setor "Troca de ato" do Covil)

## ---- SHIMS (frente G apaga junto com as chamadas em game/ e nos testes antigos). Nao sao salvos nem fazem nada.
var phases_won: Array = []
var endless_best: Dictionary = {}
var rare_choices := 0

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
		return deck_for(villain) if data else []


static func load_or_new(d: GameData, path := PATH) -> MetaSave:
	var m := MetaSave.new()
	m.data = d
	m.file = path
	m.unlocked = d.common_cards()
	m.relics_unlocked = m.free_relics()
	m.villains = []
	m.unlock_villain(d.villain_ids[0])
	m.villain = d.villain_ids[0]
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		var v = f.get_var()
		# Save de versao menor que a 5 zera (decisao do plano 21/11/2026): nada e lido.
		if typeof(v) == TYPE_DICTIONARY and int(v.get("ver", 1)) >= VERSION:
			m.runs = int(v.get("runs", 0))
			m.almas = int(v.get("almas", 0))
			m.almas_earned = int(v.get("almas_earned", 0))
			m.upgrades = v.get("upgrades", {})
			m.card_levels = v.get("card_levels", {})
			m.decks = v.get("decks", {})
			m.relic_levels = v.get("relic_levels", {})
			for rid in v.get("relics_unlocked", []):
				if d.relics.has(rid) and not m.relics_unlocked.has(rid):
					m.relics_unlocked.append(rid)
			m.best_party = int(v.get("best_party", 0))
			m.best_by_villain = v.get("best_by_villain", {})
			m.act2_reached = bool(v.get("act2_reached", false))
			for pid in v.get("villains", []):
				m.unlock_villain(d.villain_id(str(pid)))
			for cls in v.get("heroes_seen", []):
				m.see_hero(str(cls))
			m.villain = d.villain_id(str(v.get("villain", m.villain)))
			if not m.villains.has(m.villain):
				m.villain = d.villain_ids[0]
			m.heroes_total = int(v.get("heroes_total", 0))
			m.wins_by_villain = v.get("wins_by_villain", {})
			m.progress = v.get("progress", {})
			m.runs_done = v.get("runs_done", {})
			m.totals = v.get("totals", {})
			for id in v.get("unlocked", []):
				if d.card(id) and not m.unlocked.has(id):
					m.unlocked.append(id)
	return m


func save(path := "") -> bool:
	var f := FileAccess.open(file if path == "" else path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"ver": VERSION, "almas": almas, "almas_earned": almas_earned, "upgrades": upgrades,
		"card_levels": card_levels, "decks": decks, "relic_levels": relic_levels, "relics_unlocked": relics_unlocked,
		"best_party": best_party, "best_by_villain": best_by_villain, "act2_reached": act2_reached,
		"unlocked": unlocked, "villain": villain, "villains": villains, "runs": runs, "heroes_seen": heroes_seen,
		"wins_by_villain": wins_by_villain, "heroes_total": heroes_total, "progress": progress,
		"totals": totals, "runs_done": runs_done})
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


## Marca a classe como enfrentada. Devolve true se é nova.
func see_hero(cls: String) -> bool:
	if cls == "" or heroes_seen.has(cls):
		return false
	heroes_seen.append(cls)
	return true


## Chegou ao ato 2 numa run: abre o setor "Troca de ato" do Covil. Devolve true na primeira vez.
func see_act2() -> bool:
	if act2_reached:
		return false
	act2_reached = true
	return true


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func is_relic_unlocked(id: String) -> bool:
	return relics_unlocked.has(id)


## Reliquias liberadas desde o inicio (data/relics.json "free", gerado por tools/gerar_unlocks.py).
func free_relics() -> Array:
	var out: Array = []
	for id in data.relic_ids:
		if data.relics[id].get("free", false):
			out.append(id)
	return out


# ---------------------------------------------------------------- desafios de carta e de reliquia

## Fim de uma run: confere os desafios das cartas (e comuns) ainda bloqueadas do vilão jogado e das reliquias
## ainda bloqueadas, libera as cumpridas e guarda o melhor progresso das outras.
## Devolve {"done": [{id, v, g}], "near": [...]}; reliquias vêm com o id "r:<id>". Não grava (apply_run grava).
func _check_unlocks(sim: Sim, won: bool) -> Dictionary:
	var vid := sim.deck_id
	var locked: Array = []
	for c in data.pool:
		if data.in_pool(c, vid) and not unlocked.has(c.id) and data.unlock_challenges.has(c.id):
			locked.append(c.id)
	for rid in data.relic_ids:
		var r: Dictionary = data.relics[rid]
		var o := str(r.get("owner", "common"))
		if not relics_unlocked.has(rid) and r.has("challenge") and (o == "common" or o == vid):
			locked.append("r:" + rid)
	var ctx := {"won": won, "villain": vid, "phase": sim.campaign_phase, "wins_by_villain": wins_by_villain,
		"heroes_total": heroes_total, "runs_done": runs_done, "best_party": best_party, "best_by_villain": best_by_villain,
		"totals_villain": totals_of(vid), "totals_all": totals_all()}
	var res: Dictionary = sim.track.check(sim.stats, ctx, locked)
	for p in res["done"]:
		var id := str(p["id"])
		if id.begins_with("r:"):
			if not relics_unlocked.has(id.substr(2)):
				relics_unlocked.append(id.substr(2))
		elif not unlocked.has(id):
			unlocked.append(id)
		progress.erase(id)
		runs_done.erase(id)
	for p in res["near"]:
		var id := str(p["id"])
		var old: Dictionary = progress.get(id, {})
		if p.get("acc", false) or float(p["v"]) / maxf(float(p["g"]), 0.001) >= float(old.get("v", 0.0)) / maxf(float(old.get("g", 1.0)), 0.001):
			progress[id] = {"v": p["v"], "g": p["g"]}
		if p.get("hit", false):
			runs_done[id] = int(runs_done.get(id, 0)) + 1
	var mine: Dictionary = totals.get(vid, {})
	var add: Dictionary = sim.track.phase_totals(sim.stats, ctx)
	for k in add:
		mine[k] = float(mine.get(k, 0.0)) + float(add[k])
	totals[vid] = mine
	if won:
		wins_by_villain[vid] = int(wins_by_villain.get(vid, 0)) + 1
	heroes_total += int(sim.stats.get("heroes_fallen", 0))
	return res


## Só os desafios (sem Almas): mantido para as telas antigas. Grava em `path`. O tutorial não libera nada.
func apply_unlocks(sim: Sim, won: bool, path := "") -> Dictionary:
	if sim.campaign_phase <= 0:
		return {"done": [], "near": []}
	var res := _check_unlocks(sim, won)
	save(path)
	return res


## Parties que liberam cada vilão ({"dragon": 3, "lich": 6}): GameData.unlock_villain_at (fase 1 de data/campaign.json,
## "unlock_villain_at") ou, se estiver vazio, o fallback "villain_unlock_at" de data/meta_tree.json.
func villain_unlock_at(sim: Sim = null) -> Dictionary:
	if sim != null and sim.phase_cfg is Dictionary and sim.phase_cfg.has("unlock_villain_at"):
		return sim.phase_cfg["unlock_villain_at"]
	if not data.unlock_villain_at.is_empty():
		return data.unlock_villain_at
	return data.meta_tree.get("villain_unlock_at", {})


## Almas de uma run: dano nos heróis (so ate a vida maxima de cada um, ver Sim.damage_hero) / "per_hp" + heróis mortos
## x "per_hero" (data/meta_tree.json "almas"), mais o bonus % de geral.almas_mult. Tudo em inteiros.
func almas_for(dmg: float, heroes: int) -> Dictionary:
	var cfg: Dictionary = data.meta_tree.get("almas", {})
	var a_dmg := int(floor(maxf(dmg, 0.0) / maxf(float(cfg.get("per_hp", 200.0)), 1.0)))
	var a_heroes := maxi(heroes, 0) * int(cfg.get("per_hero", 5))
	var base := a_dmg + a_heroes
	var bonus := int(round(float(base) * maxf(MetaApply.fx_total(self, "geral.almas_mult"), 0.0)))
	return {"dmg": a_dmg, "heroes": a_heroes, "bonus": bonus, "total": base + bonus}


## Fim da run (vitória ou derrota; o tutorial não conta): soma as Almas (dano com teto + heróis mortos, mantidas ao
## perder), o recorde de parties, a run, os desafios e os vilões liberados, e grava. Devolve para a tela de fim:
## {"almas": {dmg, heroes, bonus, total}, "dmg_raw", "heroes", "party", "best", "new_best", "done"/"near" (desafios),
## "villains" (liberados agora), "balance" (saldo), "runs"}.
func apply_run(sim: Sim, path := "") -> Dictionary:
	var won: bool = sim.result in [K.Result.WIN, K.Result.WIN_EARLY]
	if sim.campaign_phase <= 0:
		return {"tutorial": true, "almas": {"dmg": 0, "heroes": 0, "bonus": 0, "total": 0}, "done": [], "near": [],
			"villains": [], "new_best": false, "party": 0, "best": best_party, "heroes": 0, "dmg_raw": 0.0,
			"balance": almas, "runs": runs, "won": won}
	var heroes := int(sim.stats.get("heroes_fallen", 0))
	var dmg := float(sim.stats.get("almas_dmg", 0.0))
	var gain := almas_for(dmg, heroes)
	add_almas(int(gain["total"]))
	var party := int(sim.stats.get("parties_beaten", sim.parties_beaten()))
	var vid := sim.deck_id
	var new_best := reach_party(party)
	if party > int(best_by_villain.get(vid, 0)):
		best_by_villain[vid] = party
	runs += 1
	var res := _check_unlocks(sim, won)
	var freed: Array = []
	var at: Dictionary = villain_unlock_at(sim)
	for v in at:
		if best_party >= int(at[v]) and data.villains.has(v) and not villains.has(v):
			unlock_villain(v)
			freed.append(v)
	save(path)
	return {"almas": gain, "dmg_raw": dmg, "heroes": heroes, "party": party, "best": best_party, "new_best": new_best,
		"done": res["done"], "near": res["near"], "villains": freed, "balance": almas, "runs": runs, "won": won}


## Contadores acumulados de um vilão (mais os heróis derrotados antes de 15/11/2026, que valem para todos).
func totals_of(vid: String) -> Dictionary:
	var out: Dictionary = totals.get(vid, {}).duplicate()
	var old: Dictionary = totals.get("_old", {})
	for k in old:
		out[k] = float(out.get(k, 0.0)) + float(old[k])
	return out


## Contadores acumulados de todos os vilões somados (cartas comuns contam as runs de qualquer vilão).
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


## Conta a run terminada e grava (telas antigas; apply_run já conta).
func add_run(path := "") -> void:
	runs += 1
	save(path)


# ---------------------------------------------------------------- Almas e arvore do Covil

## Soma Almas ganhas (entra no saldo e no total que o reembolso devolve).
func add_almas(n: int) -> void:
	if n <= 0:
		return
	almas += n
	almas_earned += n


func node_level(id: String) -> int:
	return int(upgrades.get(id, 0))


## Preco do proximo nivel do no (-1 = no no maximo ou inexistente).
func node_cost(id: String) -> int:
	var node: Dictionary = data.meta_nodes.get(id, {})
	var costs: Array = node.get("costs", [])
	var lv := node_level(id)
	return int(costs[lv]) if not node.is_empty() and lv < costs.size() else -1


## Um no so compra depois do pai (nivel >= 1) e se houver Almas.
func can_buy(id: String) -> bool:
	var node: Dictionary = data.meta_nodes.get(id, {})
	var c := node_cost(id)
	if node.is_empty() or c < 0 or almas < c:
		return false
	var parent := str(node.get("parent", ""))
	return parent == "" or node_level(parent) >= 1


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	almas -= node_cost(id)
	upgrades[id] = node_level(id) + 1
	return true


## Reembolsa o ultimo nivel de um no (so se nenhum filho depende dele). Devolve as Almas devolvidas.
func refund(id: String) -> int:
	var lv := node_level(id)
	if lv <= 0:
		return 0
	if lv == 1:
		for k in upgrades:
			if str(data.meta_nodes.get(k, {}).get("parent", "")) == id and int(upgrades[k]) > 0:
				return 0
	var back := int(data.meta_nodes[id]["costs"][lv - 1])
	almas += back
	if lv == 1:
		upgrades.erase(id)
	else:
		upgrades[id] = lv - 1
	return back


## Reembolso total e gratis: zera nos, cartas e reliquias; o saldo volta a ser tudo que ja foi ganho (conserva,
## mesmo com os descontos que os nos davam). Decks montados e cartas/reliquias liberadas ficam.
func refund_all() -> int:
	upgrades = {}
	card_levels = {}
	relic_levels = {}
	var back := almas_earned - almas
	almas = almas_earned
	return back


## Fim de run: guarda o recorde de parties derrubadas.
func reach_party(n: int) -> bool:
	if n <= best_party:
		return false
	best_party = n
	return true


# ---------------------------------------------------------------- niveis de carta e de reliquia

func card_level(id: String) -> int:
	return maxi(1, int(card_levels.get(id, 1)))


## Nivel maximo das cartas (I a VI): a tabela de precos tem um degrau por nivel acima do I.
func card_max_level() -> int:
	return data.meta_tree.get("card_level_costs", []).size() + 1


## Preco em Almas do proximo nivel da carta (-1 = indisponivel: bloqueada, no teto ou sem tabela).
func card_cost(id: String) -> int:
	var lv := card_level(id)
	if not unlocked.has(id) or lv >= card_max_level():
		return -1
	var base := MetaApply.card_upgrade_cost(data, id, lv + 1)
	if base <= 0:
		return -1   # fora da tabela: nunca de graca
	var disc := clampf(MetaApply.fx_total(self, "geral.card_discount"), 0.0, 0.9)
	return maxi(1, int(round(float(base) * (1.0 - disc))))


func buy_card_level(id: String) -> bool:
	var c := card_cost(id)
	if c < 0 or almas < c:
		return false
	almas -= c
	card_levels[id] = card_level(id) + 1
	return true


func relic_level(id: String) -> int:
	return clampi(int(relic_levels.get(id, 1)), 1, 3)


## Preco do proximo nivel da reliquia (-1 = bloqueada, no nivel 3 ou sem tabela): tabela x multiplicador da raridade.
func relic_cost(id: String) -> int:
	var costs: Array = data.meta_tree.get("relic_level_costs", [])
	var lv := relic_level(id)
	if not relics_unlocked.has(id) or not data.relics.has(id) or lv > costs.size():
		return -1
	var rm: Array = data.meta_tree.get("card_rarity_mult", [1.0])
	var ri := K.RARITIES.find(str(data.relics[id].get("rarity", "common")))
	var base := float(costs[lv - 1]) * float(rm[clampi(ri, 0, rm.size() - 1)])
	var disc := clampf(MetaApply.fx_total(self, "reliquias.level_discount"), 0.0, 0.9)
	return maxi(1, int(round(base * (1.0 - disc))))


func buy_relic_level(id: String) -> bool:
	var c := relic_cost(id)
	if c < 0 or almas < c:
		return false
	almas -= c
	relic_levels[id] = relic_level(id) + 1
	return true


# ---------------------------------------------------------------- deck de 19

## Deck montado do vilao, ou o deck inicial dele se nao houver um valido.
func deck_for(vid: String) -> Array:
	vid = data.villain_id(vid)
	var d: Array = decks.get(vid, [])
	if d.size() == DECK_SIZE and deck_ok(vid, d):
		return d.duplicate()
	return data.deck(vid)["cards"].duplicate()


## 19 cartas, do vilao ou comuns, todas liberadas, ate 3 copias de cada.
func deck_ok(vid: String, ids: Array) -> bool:
	vid = data.villain_id(vid)
	if ids.size() != DECK_SIZE or not villains.has(vid):
		return false
	var cnt := {}
	for id in ids:
		var c := data.card(str(id))
		if c == null or not unlocked.has(str(id)) or not data.in_pool(c, vid):
			return false
		cnt[id] = int(cnt.get(id, 0)) + 1
		if int(cnt[id]) > DECK_COPIES:
			return false
	return true


func set_deck(vid: String, ids: Array) -> bool:
	vid = data.villain_id(vid)
	if not deck_ok(vid, ids):
		return false
	decks[vid] = ids.duplicate()
	return true


# ---------------------------------------------------------------- SHIMS da campanha de 7 fases (frente G apaga)

func win_phase(_n: int) -> String:
	return ""


func phase_open(_n: int) -> bool:
	return true


func record_endless(_vid: String, n: int) -> bool:
	return reach_party(n)


func rare_choice_options(_n := 3, _seed := 0) -> Array:
	return []


func choose_rare(_id: String) -> bool:
	return false

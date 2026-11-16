class_name UnlockTrack
extends RefCounted
## Desafios que liberam cartas (data/unlocks.json, gerado por tools/gerar_unlocks.py).
## Durante a fase o Sim chama os ganchos abaixo e o rastreador só conta (nenhuma regra muda). No fim da fase
## `check()` compara os números com cada desafio e devolve o que foi cumprido e o quanto faltou.
## Fase = uma run inteira: os contadores "numa mesma fase" zeram a cada fase. Desafios entre fases ("total" e
## "runs", 15/11/2026) somam o que o MetaSave guardou; ver check().

const SAMPLE_EVERY := 8   # amostra o campo a cada N passos (não precisa de todo passo)

## Famílias de unidades (por id da carta ou da unidade auxiliar).
const RAT_IDS := ["rat", "rat_horde", "rabid_rats", "rat_brute", "rat_tide"]
const BAT_IDS := ["bat", "bat_cloud"]
const SKEL_IDS := ["skeleton", "bone_legion", "skeleton_archers"]

var data: GameData
var fam_mask := PackedInt32Array()     # índice da carta -> bits das famílias de campo
var windows: Array = []                # [fam, segundos] que os desafios pedem
var burst_s := 0.0                     # janela do desafio de dano em rajada (0 = nenhum)
var t := {}                            # contadores da fase


const FAMS := ["monster", "rat", "bat", "skeleton", "undead", "fire_monster", "pack", "beast", "structure"]


func setup(d: GameData) -> void:
	data = d
	fam_mask.resize(d.cards.size())
	for i in d.cards.size():
		var c: CardDef = d.cards[i]
		var m := 0
		var unit := c.is_unit and c.arch != K.Arch.STRUCTURE
		if unit and c.id != "spectre":
			m |= 1 << 0
		if unit and (RAT_IDS.has(c.id)):
			m |= 1 << 1
		if unit and BAT_IDS.has(c.id):
			m |= 1 << 2
		if unit and SKEL_IDS.has(c.id):
			m |= 1 << 3
		if unit and (c.tags & K.TAG_UNDEAD):
			m |= 1 << 4
		if unit and (c.tags & K.TAG_FIRE):
			m |= 1 << 5
		if unit and (c.tags & K.TAG_PACK):
			m |= 1 << 6
		if unit and c.beast:
			m |= 1 << 7
		if c.arch == K.Arch.STRUCTURE:
			m |= 1 << 8
		fam_mask[i] = m
	for k in d.unlock_challenges:
		var ch: Dictionary = d.unlock_challenges[k]
		if str(ch["kind"]) == "burst":
			burst_s = maxf(burst_s, float(ch["s"]))
		if str(ch["kind"]) == "plays_window":
			var w := [str(ch["fam"]), float(ch["s"])]
			if not windows.has(w):
				windows.append(w)
	t = {
		"peak": {},          # família -> máximo de unidades de uma vez
		"multi": {},         # "beast+rat" -> melhor valor mínimo; ver _sample
		"peak_spell": 0,     # bichos de Bando em campo quando um feitiço foi jogado
		"plays": {},         # família de carta -> jogadas
		"by_card": {},       # id -> jogadas (cartas de monstro)
		"spells": {},        # feitiços diferentes jogados
		"win_peak": {},      # [fam|s] -> máximo de jogadas na janela
		"times": {},         # [fam|s] -> instantes das jogadas na janela
		"died": {}, "deaths_since_fall": 0, "no_loss": false, "min_loss": 1000,
		"dmg": [], "burst": 0.0,
		"soak_t": -1000.0, "soak_ignite": 1000.0, "prev_soak": 0.0, "prev_burn": 0.0,
		"soaked_time": 0.0, "burn_time": 0.0,
		"peste": 0.0, "curses": 0, "elixir_max": 0.0, "coins": 0,
	}


# ------------------------------------------------------------------ ganchos do Sim

func on_tick(sim: Sim) -> void:
	var h := sim.hero
	var dt := sim.dt
	if h.soaked_t > 0.0:
		t["soaked_time"] += dt
		if h.soaked_t > float(t["prev_soak"]) - dt * 0.5:
			t["soak_t"] = sim.t                 # encharcou (ou renovou) agora
	if sim.burn_t > 0.0:
		t["burn_time"] += dt
		if float(t["prev_burn"]) <= 0.0 and h.soaked_t > 0.0:
			t["soak_ignite"] = minf(float(t["soak_ignite"]), sim.t - float(t["soak_t"]))
	t["prev_soak"] = h.soaked_t
	t["prev_burn"] = sim.burn_t
	if h.curses > int(t["curses"]):
		t["curses"] = h.curses
	if sim.elixir_max > float(t["elixir_max"]):
		t["elixir_max"] = sim.elixir_max
	if sim.tick % 4 == 0 and sim.cstate.has("plague"):
		var e: Array = sim.cstate["plague"].get("peste", {}).get(str(h.pidx), [0.0, 0.0])
		if float(e[0]) > float(t["peste"]):
			t["peste"] = float(e[0])
	if sim.tick % SAMPLE_EVERY == 0:
		_sample(sim)


func _counts(sim: Sim) -> Array:
	var cnt := [0, 0, 0, 0, 0, 0, 0, 0, 0]
	var U := sim.units
	for j in U.hi:
		if U.alive[j] == 1:
			var m := fam_mask[U.def[j]]
			if m != 0:
				for b in 9:
					if m & (1 << b):
						cnt[b] += 1
	return cnt


func _sample(sim: Sim) -> void:
	var cnt := _counts(sim)
	var pk: Dictionary = t["peak"]
	for b in 9:
		if cnt[b] > int(pk.get(FAMS[b], 0)):
			pk[FAMS[b]] = cnt[b]
	# Combinações (ex.: 2 Feras e 8 ratos ao mesmo tempo): guarda o instante em que cada exigência bateu.
	for k in data.unlock_challenges:
		var ch: Dictionary = data.unlock_challenges[k]
		if str(ch["kind"]) == "peak_multi":
			var ok := true
			for fam in ch["reqs"]:
				if cnt[FAMS.find(str(fam))] < int(ch["reqs"][fam]):
					ok = false
			if ok:
				t["multi"][k] = true


func on_play(sim: Sim, c: Sim.CardInst) -> void:
	var d := c.def
	var pl: Dictionary = t["plays"]
	pl["any"] = int(pl.get("any", 0)) + 1
	var fams: Array = []
	if d.is_unit and d.arch != K.Arch.STRUCTURE:
		fams.append("monster")
		t["by_card"][d.id] = int(t["by_card"].get(d.id, 0)) + 1
	if d.tags & K.TAG_PACK:
		fams.append("pack_card")
	if d.beast:
		fams.append("beast")
	if d.is_structure or d.arch == K.Arch.STRUCTURE:
		fams.append("structure")
	if d.is_spell:
		fams.append("spell")
		t["spells"][d.id] = true
		if d.tags & K.TAG_FIRE:
			fams.append("fire_spell")
		if d.tags & K.TAG_SHADOW:
			fams.append("shadow_spell")
		var cnt := _counts(sim)
		if cnt[6] > int(t["peak_spell"]):
			t["peak_spell"] = cnt[6]
	if d.category == "lair":
		fams.append("lair")
	for f in fams:
		pl[f] = int(pl.get(f, 0)) + 1
	# Janelas deslizantes (N jogadas em S segundos).
	for w in windows:
		var fam: String = w[0]
		if fam != "any" and not fams.has(fam):
			continue
		var key := "%s|%s" % [fam, w[1]]
		var arr: Array = t["times"].get(key, [])
		arr.append(sim.t)
		while arr.size() > 0 and sim.t - float(arr[0]) > float(w[1]):
			arr.pop_front()
		t["times"][key] = arr
		if arr.size() > int(t["win_peak"].get(key, 0)):
			t["win_peak"][key] = arr.size()


func on_unit_death(sim: Sim, i: int, cause: int) -> void:
	if cause == K.Death.EXPIRE:
		return
	var m := fam_mask[sim.units.def[i]]
	if m & 1:
		t["deaths_since_fall"] += 1
		t["died"]["monster"] = int(t["died"].get("monster", 0)) + 1
		if m & 2:
			t["died"]["rat"] = int(t["died"].get("rat", 0)) + 1


func on_hero_damage(sim: Sim, real: float) -> void:
	if burst_s <= 0.0:
		return
	var arr: Array = t["dmg"]
	arr.append([sim.t, real])
	while arr.size() > 0 and sim.t - float(arr[0][0]) > burst_s:
		arr.pop_front()
	var sum := 0.0
	for e in arr:
		sum += float(e[1])
	if sum > float(t["burst"]):
		t["burst"] = sum


func on_hero_fall(_sim: Sim) -> void:
	if int(t["deaths_since_fall"]) == 0:
		t["no_loss"] = true
	t["min_loss"] = mini(int(t["min_loss"]), int(t["deaths_since_fall"]))
	t["deaths_since_fall"] = 0


func on_coins() -> void:
	t["coins"] += 1


# ------------------------------------------------------------------ conferência no fim da fase

## Valor atingido e meta de um desafio. `ctx`: {"won", "villain", "wins_by_villain", "phases_won", "heroes_total"} (os
## acumulados de antes desta fase); `stats` é o stats da run.
func progress(ch: Dictionary, stats: Dictionary, ctx: Dictionary) -> Dictionary:
	var kind := str(ch["kind"])
	var v := 0.0
	var g := float(ch.get("n", 1))
	var won: bool = ctx.get("won", false)
	match kind:
		"peak":
			v = float(t["peak"].get(str(ch["fam"]), 0))
		"peak_multi":
			v = 1.0 if t["multi"].has(str(ch.get("_id", ""))) else 0.0
			g = 1.0
		"peak_on_spell":
			v = float(t["peak_spell"])
		"plays":
			v = float(t["plays"].get(str(ch["fam"]), 0))
		"plays_same":
			for id in t["by_card"]:
				v = maxf(v, float(t["by_card"][id]))
		"plays_window":
			v = float(t["win_peak"].get("%s|%s" % [ch["fam"], ch["s"]], 0))
		"burst":
			v = float(t["burst"])
		"soak_ignite":
			v = 1.0 if float(t["soak_ignite"]) <= float(ch["s"]) else 0.0
			g = 1.0
		"win_phase":
			v = 1.0 if (ctx.get("phases_won", []).has(int(ch["phase"])) or (won and int(ctx.get("phase", -1)) == int(ch["phase"]))) else 0.0
			g = 1.0
		"wins":
			v = float(int(ctx.get("wins_by_villain", {}).get(str(ctx.get("villain", "")), 0)) + (1 if won else 0))
		"heroes_total":
			v = float(int(ctx.get("heroes_total", 0)) + int(stats.get("heroes_fallen", 0)))
		"heroes":
			v = float(stats.get("heroes_fallen", 0))   # desta fase; "total" soma o acumulado em check()
		"win_without":
			v = 1.0 if won and int(t["plays"].get(str(ch["fam"]), 0)) == 0 else 0.0
			g = 1.0
		"win_max":
			v = 1.0 if won and int(t["plays"].get(str(ch["fam"]), 0)) <= int(ch["n"]) else 0.0
			g = 1.0
		"no_loss":
			v = 1.0 if bool(t["no_loss"]) else 0.0
			g = 1.0
		"loss_max":
			v = 1.0 if int(t["min_loss"]) <= int(ch["n"]) else 0.0
			g = 1.0
		"died":
			v = float(t["died"].get(str(ch["fam"]), 0))
		"peste":
			v = float(t["peste"])
		"curses":
			v = float(t["curses"])
		"gold_end":
			v = float(stats.get("gold_end", 0.0))
		"gold_spent":
			v = float(stats.get("gold_spent", 0))
		"gold_earned":
			v = float(stats.get("gold_earned", 0.0))
		"elixir_spent":
			for x in stats.get("spent_act", []):
				v += float(x)
		"elixir_max":
			v = float(t["elixir_max"])
		"soaked_time":
			v = float(t["soaked_time"]); g = float(ch["s"])
		"burn_time":
			v = float(t["burn_time"]); g = float(ch["s"])
		"coins":
			v = float(t["coins"])
		"spells_distinct":
			v = float(t["spells"].size())
	return {"v": v, "g": g, "done": v >= g - 0.0001}


## Chave do contador acumulado de um desafio "total" (ex.: "plays|spell", "heroes|").
static func total_key(ch: Dictionary) -> String:
	return "%s|%s" % [ch["kind"], ch.get("fam", "")]


## Valor desta fase de cada contador acumulado que algum desafio "total" usa (para o MetaSave somar).
func phase_totals(stats: Dictionary, ctx: Dictionary) -> Dictionary:
	var out := {}
	for k in data.unlock_challenges:
		var ch: Dictionary = data.unlock_challenges[k]
		if ch.get("total", false):
			out[total_key(ch)] = float(progress(ch, stats, ctx)["v"])
	return out


## Cartas desta fase cujo desafio foi cumprido: lista de {"id", "v", "g"}, e o progresso de todas as outras
## do pool deste vilão ("near": para a tela de resultado). `locked` = ids ainda bloqueados.
## Entre fases (15/11/2026): "total" soma o acumulado de antes (ctx "totals_villain" para carta de vilão,
## "totals_all" para carta comum); "runs" conta as fases em que o feito aconteceu (ctx "runs_done" por carta).
## Esses dois marcam "acc" (o progresso salvo é sempre o mais recente) e "runs" marca "hit" (cumpriu nesta fase).
func check(stats: Dictionary, ctx: Dictionary, locked: Array) -> Dictionary:
	var done: Array = []
	var near: Array = []
	for id in locked:
		if not data.unlock_challenges.has(id):
			continue
		var ch: Dictionary = data.unlock_challenges[id].duplicate()
		ch["_id"] = id
		var p := progress(ch, stats, ctx)
		p["id"] = id
		if ch.get("total", false):
			var cd := data.card(id)
			var common := cd != null and cd.owner == "common"
			var tot: Dictionary = ctx.get("totals_all" if common else "totals_villain", {})
			p["v"] = float(tot.get(total_key(ch), 0.0)) + float(p["v"])
			p["done"] = float(p["v"]) >= float(p["g"]) - 0.0001
			p["acc"] = true
		elif ch.has("runs"):
			p["hit"] = p["done"]
			var n := int(ctx.get("runs_done", {}).get(id, 0)) + (1 if p["done"] else 0)
			p["v"] = float(n)
			p["g"] = float(ch["runs"])
			p["done"] = n >= int(ch["runs"])
			p["acc"] = true
		if p["done"]:
			done.append(p)
		else:
			near.append(p)
	return {"done": done, "near": near}


## Balanceamento (15/11/2026): o que ESTA run alcançou em TODO desafio de carta (não só os bloqueados), para o lote
## headless gravar a média por fase/deck/perfil e calibrar as metas. {id_da_carta: {"v", "g", "total", "runs"}}.
## Usa o contexto neutro de uma fase (sem acumulados): "wins"/"heroes_total" valem só esta run.
func snapshot(stats: Dictionary, won: bool) -> Dictionary:
	var out := {}
	var ctx := {"won": won, "villain": "", "phase": int(stats.get("phase", 1))}
	for id in data.unlock_challenges:
		var ch: Dictionary = data.unlock_challenges[id].duplicate()
		ch["_id"] = id
		var p := progress(ch, stats, ctx)
		out[id] = {"v": snappedf(float(p["v"]), 0.01), "g": float(p["g"]), "kind": str(ch["kind"]),
			"total": bool(ch.get("total", false)), "runs": bool(ch.get("runs", false))}
	return out

class_name MetaApply
extends RefCounted
## CONTRATO (plano 21/11/2026): traduz o progresso do MetaSave (arvore do Covil, niveis de carta, deck, reliquias) nos
## "mods" de uma run. `Sim.setup(..., mods)` recebe o resultado de run_mods(); mods vazio = sem meta (testes).
## Os caminhos de fx de data/meta_tree.json ("elixir.max", "locais.ritual.elixir_mult"...) sao DELTAS somados aos
## DEFAULTS abaixo (multiplicadores partem de 1.0). Quem consome cada chave: A (oferta_por_heroi, geral, arena, locais,
## recarga, ato), C (card_levels), D (reliquias, deck), E/F so leem. Chaves novas: acrescentar em DEFAULTS e documentar aqui.

## Valores neutros de cada chave. Dicionarios de local/ato/arena acrescentam chaves conforme os nos.
const DEFAULTS := {
	"elixir": {"max": 0.0, "regen_mult": 0.0, "start": 0.0},      # +elixir maximo, +fracao do ganho, +elixir inicial
	"mao": {"inicial": 0.0},                                      # + cartas na mao inicial
	"recarga": {"carta": 0.0},                                    # fracao a menos no DRAW_DELAY da vaga
	"locais": {},                                                 # {id_do_local: {chave: delta}}, ex.: ritual.elixir_mult, ritual.dur_mult
	"arena": {"boss_hp_mult": 1.0, "arm_dmg_mult": 1.0, "struct_mult": 1.0},   # o "covil": vida das partes, dano do braco, estruturas
	"ato": {"elixir_refill": 0.0},                                # troca de ato (setor so abre depois do ato 2)
	"reliquias": {"unlocked": [], "levels": {}, "extra_options": 0.0},   # unlocked vazio = sem filtro (testes/tutorial)
	"card_levels": {},                                            # {id_da_carta: nivel I..VI} (1 = sem melhoria)
	"deck": [],                                                   # deck montado (19 ids); vazio = o deck do vilao
	"oferta_por_heroi": false,                                    # oferta de carta a cada heroi morto, nao so por party
	"geral": {"ouro_inicial": 0.0, "almas_mult": 0.0},            # +ouro inicial, +fracao de Almas
}


static func defaults() -> Dictionary:
	return DEFAULTS.duplicate(true)


## DEFAULTS + o que `mods` trouxer (uniao rasa por secao). Sim.setup usa isto: mods parcial/vazio e valido.
static func merge(mods: Dictionary) -> Dictionary:
	var out := defaults()
	for k in mods:
		if out.get(k) is Dictionary and mods[k] is Dictionary and k != "card_levels":
			for kk in mods[k]:
				out[k][kk] = mods[k][kk]
		else:
			out[k] = mods[k]
	return out


## Soma o delta `v` no caminho "a.b.c" de `mods`, criando os niveis que faltarem (bool: OU).
static func add_path(mods: Dictionary, path: String, v) -> void:
	var parts := path.split(".")
	var d: Dictionary = mods
	for i in parts.size() - 1:
		if not d.has(parts[i]) or not (d[parts[i]] is Dictionary):
			d[parts[i]] = {}
		d = d[parts[i]]
	var key: String = parts[parts.size() - 1]
	if typeof(d.get(key)) == TYPE_BOOL:
		d[key] = bool(d[key]) or float(v) != 0.0
	elif d.has(key):
		d[key] = float(d[key]) + float(v)
	else:
		d[key] = float(v)


## Mods da run a partir do MetaSave (null = sem meta). Percorre os nos comprados de data/meta_tree.json.
static func run_mods(meta: MetaSave) -> Dictionary:
	var mods := defaults()
	if meta == null:
		return mods
	for id in meta.upgrades:
		var lv := int(meta.upgrades[id])
		var node: Dictionary = meta.data.meta_nodes.get(id, {})
		if lv <= 0 or node.is_empty():
			continue
		var fx: Dictionary = node.get("fx", {})
		for path in fx:
			var arr: Array = fx[path]
			var v = arr[mini(lv, arr.size()) - 1]
			if path == "oferta_por_heroi":
				mods["oferta_por_heroi"] = mods["oferta_por_heroi"] or float(v) != 0.0
			else:
				add_path(mods, path, v)
	mods["card_levels"] = meta.card_levels.duplicate()
	mods["reliquias"]["unlocked"] = meta.relics_unlocked.duplicate()
	mods["reliquias"]["levels"] = meta.relic_levels.duplicate()
	mods["deck"] = meta.decks.get(meta.villain, []).duplicate()
	return mods


## GANCHO de Sim.setup (uma linha): aplica no sim o que e so numero de partida (elixir, mao, ouro). Corpo minimo
## do contrato; a frente A completa (recarga da vaga, arena, locais, oferta_por_heroi) lendo sim.mods.
static func apply_to_sim(sim) -> void:
	var m: Dictionary = sim.mods
	sim.hand_size += int(m["mao"]["inicial"])
	sim.elixir += float(m["elixir"]["start"])
	sim.gold += float(m["geral"]["ouro_inicial"])


## Filtro de reliquia (gancho de Sim._relic_pool): lista vazia = tudo liberado.
static func relic_ok(sim, id: String) -> bool:
	var u: Array = sim.mods["reliquias"]["unlocked"]
	return u.is_empty() or u.has(id)


## Nivel inicial de uma carta nesta run (gancho de Sim._new_inst), 1 a rules.card_levels.max.
static func card_level(sim, id: String) -> int:
	return clampi(int(sim.mods["card_levels"].get(id, 1)), 1, int(sim.R["card_levels"]["max"]))


## Preco em Almas de subir a carta `id` ao nivel `to_level` (2..6): tabela x multiplicador da raridade.
static func card_upgrade_cost(d: GameData, id: String, to_level: int) -> int:
	var costs: Array = d.meta_tree.get("card_level_costs", [])
	var rm: Array = d.meta_tree.get("card_rarity_mult", [1.0])
	var c: CardDef = d.card(id)
	if c == null or to_level < 2 or to_level - 2 >= costs.size():
		return 0
	return int(round(float(costs[to_level - 2]) * float(rm[mini(c.rarity, rm.size() - 1)])))

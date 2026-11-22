class_name BotRun
extends RefCounted
## Frente J (21/11/2026): infraestrutura de run completa com o bot, sem varredura de balanço.
## BotRun.run simula uma run inteira (as 15 parties) headless; BotRun.maxed_mods monta os mods de uma meta "no máximo".

const TMP_META := "user://bots_meta_maxed.save"   # nunca o user://meta.save do jogador


## Run completa. `deck` vazio = o deck de mods["deck"] (ou o inicial do vilão). opts: bot (id, padrão "heuristic"),
## villain (padrão "plague"), unlocked (cartas das ofertas; vazio = todas), max_t (s simulados; 0 = sem limite),
## max_ticks (trava de segurança). Devolve {result, parties_beaten, t, stats, ticks}; result "timeout" se estourou o limite.
static func run(data: GameData, seed_: int, mods: Dictionary = {}, deck: Array = [], opts: Dictionary = {}) -> Dictionary:
	var s := Sim.new()
	s.setup(data, seed_, str(opts.get("villain", "plague")), deck, opts.get("unlocked", []), 1, mods)
	s.auto_route = true
	var bot := PlayerBot.load_bot(str(opts.get("bot", "heuristic")), seed_)
	var max_t := float(opts.get("max_t", 0.0))
	var max_ticks := int(opts.get("max_ticks", 400000))
	var n := 0
	while s.phase != K.Phase.OVER and n < max_ticks and (max_t <= 0.0 or s.t < max_t):
		bot.think(s)
		s.step()
		n += 1
	var res := str(s.stats.get("result", ""))
	if s.phase != K.Phase.OVER:
		res = "timeout"
	return {"result": res, "parties_beaten": s.parties_beaten(), "t": s.t, "stats": s.stats, "ticks": n}


## Mods de uma meta no máximo: todos os nós da árvore no último nível, todas as cartas do jogo no nível máximo, todas as
## relíquias liberadas (nível 3). Usa um MetaSave com caminho em user:// próprio (nada é gravado).
static func maxed_mods(data: GameData, villain := "plague") -> Dictionary:
	var m := MetaSave.load_or_new(data, TMP_META)
	for id in data.meta_nodes:
		m.upgrades[id] = (data.meta_nodes[id].get("costs", []) as Array).size()
	m.unlocked = []
	for c in data.cards:
		m.unlocked.append(c.id)
	var top := m.card_max_level()
	for id in m.unlocked:
		m.card_levels[id] = top
	m.relics_unlocked = data.relics.keys()
	for rid in m.relics_unlocked:
		m.relic_levels[rid] = 3
	m.villain = data.villain_id(villain)
	var mods := MetaApply.run_mods(m)
	return mods

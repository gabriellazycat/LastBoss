extends Node
## Lote headless: godot --headless --path . res://headless/batch.tscn -- --bot=greedy --deck=horde --seeds=1-20 --out=reports/x.json


func _ready() -> void:
	# Experimentos: --force_relic=id[,id] (ganha no início), --force_event=evento[:opção], --draw_delay=<multiplicador da recarga>.
	var args := {"bot": "greedy", "deck": "horde", "seeds": "1-10", "out": "user://batch.json", "data": "res://data", "phase": "1", "pool": "full",
		"force_relic": "", "force_event": "", "draw_delay": "1.0", "swap_card": "", "ban_card": ""}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var data := GameData.load_dir(args["data"])
	var seeds: Array = []
	for part in str(args["seeds"]).split(","):
		if part.contains("-"):
			var ab := part.split("-")
			for s in range(int(ab[0]), int(ab[1]) + 1):
				seeds.append(s)
		elif part != "":
			seeds.append(int(part))
	var runs: Array = []
	for s in seeds:
		runs.append(run_one(data, int(s), args["deck"], args["bot"], int(args["phase"]), str(args["data"]) + "/bots", str(args["pool"]),
			{"force_relic": str(args["force_relic"]), "force_event": str(args["force_event"]), "draw_delay": float(args["draw_delay"]), "swap_card": str(args["swap_card"]), "ban_card": str(args["ban_card"])}))
	var f := FileAccess.open(args["out"], FileAccess.WRITE)
	if f == null:
		push_error("batch: não gravou " + str(args["out"]))
		get_tree().quit(2)
		return
	f.store_string(JSON.stringify({"runs": runs}))
	f.close()
	print("batch ok: %d runs -> %s" % [runs.size(), args["out"]])
	get_tree().quit(0)


## `pool`: "full" = ofertas com o pool inteiro do vilão; "start" = só a coleção inicial (cartas do vilão + comuns
## de raridade até 1, mais as raras iniciais), como um jogador que acabou de começar.
static func run_one(data: GameData, s: int, deck: String, bot_id: String, phase := 1, bot_dir := "res://data/bots", pool := "full", opts := {}) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var sim := Sim.new()
	sim.draw_delay_mult = float(opts.get("draw_delay", 1.0))
	var fe := str(opts.get("force_event", ""))
	if fe != "":
		var parts := fe.split(":")
		sim.force_event = parts[0]
		sim.force_event_opt = int(parts[1]) if parts.size() > 1 else -1
	var unlocked: Array = []
	if pool == "start":
		var vid := data.villain_id(deck)
		unlocked = data.villain_cards(vid) + data.common_cards()
	var card_list: Array = []
	var sw := str(opts.get("swap_card", ""))
	if sw != "":
		# Troca (id:ref): a carta entra no baralho inicial no lugar de uma carta de referência (a 1ª cópia de `ref`).
		card_list = data.deck(deck)["cards"].duplicate()
		var sp := sw.split(":")
		var at := card_list.find(sp[1])
		if at < 0:
			push_error("batch: swap_card ref %s não está no baralho %s" % [sp[1], deck])
		else:
			card_list[at] = sp[0]
	sim.banned_cards = Array(str(opts.get("ban_card", "")).split(",", false))
	sim.setup(data, s, deck, card_list, unlocked, phase)
	for rid in str(opts.get("force_relic", "")).split(",", false):
		sim.gain_relic(rid)
	var bot := PlayerBot.load_bot(bot_id, s, bot_dir)
	while sim.phase != K.Phase.OVER:
		bot.think(sim)
		sim.step()
	var st: Dictionary = sim.stats.duplicate(true)
	st["track"] = sim.track.snapshot(st, str(st.get("result", "")) in ["win", "win_early"])
	st["force"] = {"relic": str(opts.get("force_relic", "")), "event": fe, "draw_delay": sim.draw_delay_mult}
	st["bot"] = bot_id
	var tot_hp := 0.0
	for hi in sim.party.size():
		tot_hp += float(data.hero_of(sim.party_class(hi), sim.phase_hp_mult)["hp"]) * pow(float(data.rules["party"]["step"]), sim.party_number(hi)) * float(data.rules.get("hero_hp_mult", 1.0))
	st["hero_hp_total"] = tot_hp
	st["hp_frac"] = clampf(float(st.get("hero_dmg", 0.0)) / maxf(tot_hp, 1.0), 0.0, 1.5)
	st["swap"] = sw
	if bot is HumanBot:
		st["bot_stats"] = bot.stats.duplicate()
	st["phase"] = phase
	st["pool"] = pool
	if phase != 1:
		st["deck"] = "%s@%d" % [deck, phase]
	st["wall_ms"] = (Time.get_ticks_usec() - t0) / 1000.0
	return st

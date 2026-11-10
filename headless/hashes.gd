extends Node
## Tabela de impressões digitais de runs (refatoração sem mudança de comportamento: a tabela tem de sair igual).
## godot --headless --path . res://headless/hashes.tscn -- --out=hashes.txt [--seeds=1-2]
##   [--bots=random,greedy,heuristic,swarm,economist,human] [--decks=horde,ruin,treasure,crypt,cult] [--phases=1,2,3,4]
## Uma linha por run: bot deck fase semente resultado tick state_hash rastro stats [contadores do bot humano].
## "rastro" encadeia o state_hash a cada 100 ticks (pega divergência no meio da run); "stats" é o hash do
## sim.stats inteiro (cartas jogadas, dano por carta, ofertas...).


func _ready() -> void:
	var a := {"out": "", "seeds": "1-2", "bots": "random,greedy,heuristic,swarm,economist,human",
		"decks": "horde,ruin,treasure,crypt,cult", "phases": "1,2,3,4"}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and s.contains("="):
			var kv := s.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	var seeds: Array = []
	for part in str(a["seeds"]).split(","):
		if part.contains("-"):
			var ab := part.split("-")
			for x in range(int(ab[0]), int(ab[1]) + 1):
				seeds.append(x)
		elif part != "":
			seeds.append(int(part))
	var data := GameData.load_dir("res://data")
	var lines: PackedStringArray = []
	for bot_id in str(a["bots"]).split(","):
		for deck in str(a["decks"]).split(","):
			for ph in str(a["phases"]).split(","):
				for s in seeds:
					lines.append(run_line(data, bot_id, deck, int(ph), int(s)))
					print(lines[lines.size() - 1])
	if str(a["out"]) != "":
		var f := FileAccess.open(str(a["out"]), FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
		f.close()
	print("hashes ok: %d runs" % lines.size())
	get_tree().quit(0)


static func run_line(data: GameData, bot_id: String, deck: String, ph: int, s: int) -> String:
	var sim := Sim.new()
	sim.setup(data, s, deck, [], [], ph)
	var bot := PlayerBot.load_bot(bot_id, s)
	var trail := 0
	while sim.phase != K.Phase.OVER:
		bot.think(sim)
		sim.step()
		if sim.tick % 100 == 0:
			trail = hash([trail, sim.state_hash(), sim.hand.size(), sim.elixir, sim.gold])
	var st: Dictionary = sim.stats.duplicate(true)
	var extra := ""
	if bot is HumanBot:
		extra = JSON.stringify((bot as HumanBot).stats)
	return "%s %s %d %d %s %d %d %d %d %s" % [bot_id, deck, ph, s, str(sim.stats["result"]), sim.tick, sim.state_hash(),
		trail, hash(JSON.stringify(st)), extra]

extends Node
## Lote headless: godot --headless --path . res://headless/batch.tscn -- --bot=greedy --deck=horde --seeds=1-20 --out=reports/x.json


func _ready() -> void:
	var args := {"bot": "greedy", "deck": "horde", "seeds": "1-10", "out": "user://batch.json", "data": "res://data"}
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
		runs.append(run_one(data, int(s), args["deck"], args["bot"]))
	var f := FileAccess.open(args["out"], FileAccess.WRITE)
	if f == null:
		push_error("batch: não gravou " + str(args["out"]))
		get_tree().quit(2)
		return
	f.store_string(JSON.stringify({"runs": runs}))
	f.close()
	print("batch ok: %d runs -> %s" % [runs.size(), args["out"]])
	get_tree().quit(0)


static func run_one(data: GameData, s: int, deck: String, bot_id: String) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var sim := Sim.new()
	sim.setup(data, s, deck)
	var bot := PlayerBot.load_bot(bot_id, s)
	while sim.phase != K.Phase.OVER:
		bot.think(sim)
		sim.step()
	var st: Dictionary = sim.stats.duplicate(true)
	st["bot"] = bot_id
	st["wall_ms"] = (Time.get_ticks_usec() - t0) / 1000.0
	return st

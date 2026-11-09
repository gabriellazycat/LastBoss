extends Node
## Replay de uma run de bot com rastro do herói (diagnóstico de runs travadas):
## godot --headless --path . res://headless/replay.tscn -- --bot=swarm --deck=treasure --seed=5010 --every=30


func _ready() -> void:
	var args := {"bot": "heuristic", "deck": "horde", "seed": "1", "every": "30"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var data := GameData.load_dir()
	var sim := Sim.new()
	sim.setup(data, int(args["seed"]), args["deck"])
	var bot := PlayerBot.load_bot(args["bot"], int(args["seed"]))
	var every := float(args["every"])
	var next := 0.0
	while sim.phase != K.Phase.OVER:
		bot.think(sim)
		sim.step()
		if sim.t >= next:
			next += every
			var h := sim.hero
			print("t=%5.0f fase=%d herói %d s=%6.1f/%6.1f pos=(%.0f,%.0f) vida=%.0f/%.0f alvo=%d:%d unidades=%d zonas=%d espera=%s ofertas=%d" % [
				sim.t, sim.phase, sim.party_idx + 1, h.s, sim.road.length(), h.x, h.y, h.hp, h.max_hp(), h.target_kind, h.target,
				sim.units.count, sim.zones.size(), sim.route_wait, sim.offers.size()])
	print("fim: ", sim.stats["result"], " t=", sim.t)
	get_tree().quit(0)

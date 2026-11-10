extends SceneTree
## Rastreio de uma run (diagnóstico): godot --headless --path . -s res://headless/trace.gd -- --bot=random --deck=treasure --phase=3 --seed=15


func _init() -> void:
	var a := {"bot": "random", "deck": "treasure", "phase": "3", "seed": "15", "every": "100"}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and s.contains("="):
			var kv := s.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	var data := GameData.load_dir("res://data")
	var sim := Sim.new()
	sim.setup(data, int(a["seed"]), a["deck"], [], [], int(a["phase"]))
	var bot := PlayerBot.load_bot(a["bot"], int(a["seed"]))
	var nxt := 0.0
	while sim.phase != K.Phase.OVER:
		bot.think(sim)
		sim.step()
		if sim.t >= nxt:
			nxt += float(a["every"])
			var h := sim.hero
			print("rw=%s off=%d ap=%s comp=%s lu=%d lt=%.1f pos=%.0f,%.0f lure=%.0f,%.0f " % [sim.route_wait, sim.offers.size(), sim.act_pending, sim.road.complete, sim.hero.lure_unit, sim.hero.lure_time, sim.hero.x, sim.hero.y, sim.hero.lure_x, sim.hero.lure_y], "t=%d ph=%d act=%d s=%.0f/%.0f hp=%.0f/%.0f cls=%s tgt=%d hold=%s lure=%s units=%d contest=%s el=%.1f gold=%.0f fol=%d" % [sim.t, sim.phase, sim.act, h.s, sim.road.length(), h.hp, h.max_hp(), h.cls(), h.target_kind, h.hold, h.lure_on, sim.units.count, sim.contest.get("type", "-"), sim.elixir, sim.gold, sim.followers.size()])
	print("fim: ", sim.stats["result"], " t=", sim.t)
	quit()

extends SceneTree
## Verificação final da metaprogressão (21/11/2026): 15 parties com o bot, sem meta e com meta no máximo, mais a ida e
## volta do save v5 e a conservação do reembolso. Não é balanço: só confere que a run fecha e que os números não são absurdos.
## godot --headless --path . --script res://tools/final_check.gd -- [--seeds=1,2,3] [--cap=9000]

func _initialize() -> void:
	var seeds: Array = [1, 2, 3]
	var cap := 9000.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = []
			for s in a.substr(8).split(","):
				seeds.append(int(s))
		elif a.begins_with("--cap="):
			cap = float(a.substr(6))
	var data := GameData.load_dir()
	data.rules["sim"]["max_run_seconds"] = cap   # só neste script: o jogo segue com o limite de rules.json
	var fails := 0
	# --- save v5 ida e volta e reembolso
	var path := "user://final_check.save"
	var m := MetaSave.load_or_new(data, path)
	m.add_almas(5000)
	var bought := 0
	for id in data.meta_nodes:
		while m.buy(id):
			bought += 1
	m.save()
	var m2 := MetaSave.load_or_new(data, path)
	var ok_rt := m2.almas == m.almas and m2.upgrades == m.upgrades
	print("save v5 ida e volta: ", "OK" if ok_rt else "FALHOU", " (", bought, " compras, saldo ", m2.almas, ")")
	fails += 0 if ok_rt else 1
	m2.refund_all()
	var ok_rf := m2.almas == m2.almas_earned and m2.upgrades.is_empty()
	print("reembolso conserva: ", "OK" if ok_rf else "FALHOU", " (", m2.almas, " de ", m2.almas_earned, ")")
	fails += 0 if ok_rf else 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# --- runs de 15 parties
	var maxed := BotRun.maxed_mods(data, "plague")
	for sd in seeds:
		for label in ["sem meta", "meta no maximo"]:
			var r := BotRun.run(data, sd, {} if label == "sem meta" else maxed, [], {"max_t": cap})
			print("seed %d %-14s -> %s | parties %d de 15 | %.0f s simulados | %d ticks" % [sd, label, r["result"], r["parties_beaten"], r["t"], r["ticks"]])
	print("final_check falhas: ", fails)
	quit(fails)
